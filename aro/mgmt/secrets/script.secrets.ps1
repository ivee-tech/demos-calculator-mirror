# this script can be used as a base for manual backup of secrets
# get all secrets from all namespaces in Yaml format
oc get secret -A -o yaml > C:\Data\ARO\secrets.yaml

# get all secrets per namsepace
$ns = 'test-storage'
oc get secret -n $ns -o yaml > C:\Data\ARO\secrets.$ns.yaml
$secrets = $(oc get secret -n $ns -o json) | ConvertFrom-Json

. ..\..\..\utils\base64.ps1
$secret = $(oc get secret azure-files-secret -n $ns -o json) | ConvertFrom-Json
$saName = $secret.data.azurestorageaccountname | base64 -d
$saKey = $secret.data.azurestorageaccountkey | base64 -d


# encode to BASE64
. ..\..\..\utils\base64.ps1
$test = 'ABC'
$testBase64 = $test | base64
$testBase64

# store file content in KV
$ns = 'test-storage'
$kvName = 'kv-auea-dev-ncis-ws01'
az keyvault secret set --vault-name $kvName --name "secrets-$ns-saname" --value $saName
az keyvault secret set --vault-name $kvName --name "secrets-$ns-sakey" --value $saKey



# configmap manually for backup
<#
oc create cm test-cm --from-literal=key1=value1 --from-literal=key2=value2

$cm = $(oc get cm kube-root-ca.crt -o json) | ConvertFrom-Json
$cm.data.'ca.crt'

$ns = 'test-storage'
$kvName = 'kv-auea-dev-ncis-ws01'
az keyvault secret set --vault-name $kvName --name "cm-$ns-ca.crt" --value $cm.data.'ca.crt'
#>
