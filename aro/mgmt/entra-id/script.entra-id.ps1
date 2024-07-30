# check domain
$tenantId = '16b3c013-d300-468d-ac64-7eda0820b6d3' # '6e424d97-163d-46e9-a079-e66d12f36c6e' # change to the correct Tenant ID
$rg = 'rg-auea-dev-ncis'
$clusterName = 'aro-auea-dev-ncis-ws04'
$domain=$(az aro show -g $rg -n $clusterName --query clusterProfile.domain -o tsv)
$location=$(az aro show -g $rg -n $clusterName --query location -o tsv)
$redirectUri = "https://oauth-openshift.apps.$domain.$location.aroapp.io/oauth2callback/AzureAD"
$appName = "EntraID-ARO-Integration"

# register app
$appId = az ad app create --display-name $appName --web-redirect-uris $redirectUri --query appId -o tsv
$appId = '0c8f55e2-ae09-4624-9089-e93298a15e8b'
# create the client secret
$endDate = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")
$secret = az ad app credential reset --id $appId --end-date $endDate --query password -o tsv
$secret = '***'
# grant API permissions
# az ad app permission add --id $app --api 00000003-0000-0000-c000-000000000000 --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
# az ad app permission grant --id $app --api 00000003-0000-0000-c000-000000000000
# add email and upn claims to the token configuration - NOT WORKING
<#
$claims = @{
    "idToken"=@(
        @{
            "name"="email";
            "essential" = $false
        },
        @{
            "name"="upn";
            "essential" = $false
        }
    );
    "accessToken"=@(
        @{
            "name"="email";
            "essential" = $false
        },
        @{
            "name"="upn";
            "essential" = $false
        }
    )
} | ConvertTo-Json -Compress

az ad app update --id $appId --set optionalClaims=$claims
#>
# configure OpenID in ARO
oc create secret generic entraid-client-secret --from-literal=clientSecret=$secret -n openshift-config 
# oc delete secret entraid-client-secret -n openshift-config 
# create OAuth
$content = Get-Content -Path "oauth.yaml" -Raw
$content = $content -replace '\${CLIENT_ID}', $appId
$content = $content -replace '\${TENANT_ID}', $tenantId
$content | oc apply -f -


# create ns-role
$ns = 'ibm-ace-dev'
oc apply -f ns-role.yaml -n $ns
# create role binding
# TODO: check get user based on full name
<#
$userFullName = '0bde0597-55d5-448b-bb0e-5caba79437ec 1b1a6e76-30c9-4085-b591-54eded7b9c3a'
oc get user -o jsonpath="?(@.metadata.name=='$userFullName')"
#>
$subject = 'WRRqf0p6-12Ceye2U3sNnyezAsWzx97F8E36YRxYz6Y'
$role = 'ns-role'
$bindingName = 'ns-rolebinding'
oc create rolebinding $bindingName --role=$role --user=$subject -n $ns
# OR 
$content = Get-Content -Path "ns-rolebinding.yaml" -Raw
$content = $content -replace '\${SUBJECT}', $subject
$content | oc apply -f -


# create ibm-ace-test
$ns = 'ibm-ace-test'
oc new-project $ns
$content = Get-Content -Path "ns-role.yaml" -Raw
$content = $content -replace '\${NS}', $ns
$content | oc apply -f -
$subject = 'WRRqf0p6-12Ceye2U3sNnyezAsWzx97F8E36YRxYz6Y'
$content = Get-Content -Path "ns-rolebinding.yaml" -Raw
$content = $content -replace '\${NS}', $ns
$content = $content -replace '\${SUBJECT}', $subject
$content | oc apply -f -

