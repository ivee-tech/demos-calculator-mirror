<#
.SYNOPSIS
    This script configures the workload identity for an AKS cluster.

.DESCRIPTION
    A detailed description of the script.

.PARAMETER subscriptionId
    The subscription ID.

.PARAMETER location
    The location.

.PARAMETER rg
    The resource group.

.PARAMETER aksName
    The Azure Kubernetes Service name.

.PARAMETER kvName
    The Key Vault name.

.PARAMETER ns
    The K8S namespace.

.PARAMETER saName
    The K8S service account name (typically SA associated to the namespace).

.EXAMPLE
$ns = 'secaas001'
$rg = 'k8s-tech-brief-rg'
$aksName = 'ktb-aks'
$location = 'AustraliaEast'
$subscriptionId = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
$kvName = 'ktb-kv2'
.\cfg-kv-workload-identity.ps1 -subscriptionId $subscriptionId -location $location -rg $rg -aksName $aksName -kvName $kvName -ns $ns -saName $saName

.NOTES
    Additional information about the script.
#>

param(

    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,

    [Parameter(Mandatory=$true)]
    [string]$location,

    [Parameter(Mandatory=$true)]
    [string]$rg,

    [Parameter(Mandatory=$true)]
    [string]$aksName,

    [Parameter(Mandatory=$true)]
    [string]$kvName,

    [Parameter(Mandatory=$true)]
    [string]$ns,

    [Parameter(Mandatory=$true)]
    [string]$saName
)

# set OIDC Issuer Url
$oidcIssuer = "$(az aks show -n $aksName -g $rg --query "oidcIssuerProfile.issuerUrl" -otsv)"
echo $oidcIssuer
echo "$oidcIssuer/.well-known/openid-configuration"

# create MI and give KV permission
$idName = "$($aksName)-user-id"
az identity create --name "$idName" --resource-group "$rg" --location "$location" --subscription "$subscriptionId"

# create Access Policy in KV
$userIdClientId = "$(az identity show --resource-group "$rg" --name "$idName" --query 'clientId' -o tsv)"
# az keyvault set-policy --name "$kvName" --secret-permissions get --spn "$userIdClientId" --resource-group "$rg"
# OR
# Create role assignment in KV (if Access is based on RBAC)
$role="Key Vault Secrets User"
$kvId=$(az keyvault show --name $kvName --query id --output tsv)
az role assignment create --role "$role" --assignee $userIdClientId --scope $kvId 

# establish Federated Identity
az identity federated-credential create --name $saName --identity-name "$idName" --resource-group "$rg" --issuer "$oidcIssuer" --subject system:serviceaccount:"$ns":"$saName"
# az identity federated-credential delete --name $saName --identity-name "$idName" --resource-group "$rg"
