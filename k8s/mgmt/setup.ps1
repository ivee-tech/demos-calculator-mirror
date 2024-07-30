# $tenantId =  $(az account show --query tenantId -o tsv) # FDPO
$subscriptionId = $(az account show --query id -o tsv)
$rg = 'escs-lz01-SPOKE'
$location = 'AustraliaEast'
$kvName = 'kv85618-akscs'
$aksName = 'aks-akscs-blue'
$ns = 'itp'
$saName = 'sample-django-app-sa'

# get KV url
$kvUrl = "$(az keyvault show -g $rg -n $kvName --query properties.vaultUri -o tsv)"
$kvUrl

# run config workload identity script
.\cfg-kv-workload-identity.ps1 -subscriptionId $subscriptionId -location $location -rg $rg -aksName $aksName -kvName $kvName -ns $ns -saName $saName

# check identity
$idName="${aksName}-user-id"
$userIdClientId=$(az identity show --resource-group "$rg" --name "$idName" --query 'clientId' -o tsv)
$userIdClientId

