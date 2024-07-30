# login into and set subscription
# ZZ / VCE-MCT
$tenantId = '6e424d97-163d-46e9-a079-e66d12f36c6e'
$subscriptionId = 'e1a9409c-6d10-4b6b-9c0f-a5c73eb1319f' # VSE-MCT
# FDPO / MCAPS
$tenantId = '16b3c013-d300-468d-ac64-7eda0820b6d3'
$subscriptionId = '2ef01a24-f9c4-4a9f-bca8-7d0ca8fe11fa'
az login --tenant $tenantId
az account set --subscription $subscriptionId

# register RedHatOpenShift provider
az provider register --namespace Microsoft.RedHatOpenShift --wait
az provider show --name Microsoft.RedHatOpenShift

# identify the resource provider ID for ARO
$ARO_RP_OBJECT_ID = az ad sp list --display-name "Azure Red Hat OpenShift RP" --query "[0].id" -o tsv
Write-Output $ARO_RP_OBJECT_ID

# create the storage account for state management
$REGION="AustraliaEast"
$STORAGEACCOUNTNAME="staueadevarolzastate2"
$CONTAINERNAME="arolza"
$TFSTATE_RG="rg-auea-dev-aro-lza-state"
$tf = "C:\tools\terraform\terraform.exe"

# create the state resource group
az group create --name $TFSTATE_RG --location $REGION

# create the storage account
az storage account create --name $STORAGEACCOUNTNAME --resource-group $TFSTATE_RG --location $REGION --sku Standard_GRS

# create the storage container
az storage container create --name $CONTAINERNAME --account-name $STORAGEACCOUNTNAME --resource-group $TFSTATE_RG

# deployment steps

# init TF
Set-Alias -Name terraform -Value $tf
terraform init -backend-config="resource_group_name=$TFSTATE_RG" `
    -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME" `
    -reconfigure -upgrade

# set variables
$TENANT_ID = $tenantId # OR $(az account show --query tenantId -o tsv)
$SUBSCRIPTION_ID = $subscriptionId # OR $(az account show --query id -o tsv)
$LOCATION="AustraliaEast"
$ARO_BASE_NAME="aro-auea-dev-lza"
$ARO_DOMAIN="aro-auea-dev-lza"
<# 
the LZA uses the following sizes:
- master profile: Standard_D8s_v3 8 vCPUs, 32 GB)
- worker profile: 3 x Standard_D4s_v3 (4 vCPUs, 16 GB)
- jumpbox: Standard_D2s_v3 (2 vCPUs, 8 GB)
#>
# validate config
terraform plan `
    -var tenant_id=$TENANT_ID `
    -var subscription_id=$SUBSCRIPTION_ID `
    -var location=$LOCATION `
    -var aro_rp_object_id=$ARO_RP_OBJECT_ID `
    -var aro_base_name=$ARO_BASE_NAME `
    -var aro_domain=$ARO_DOMAIN


# deploy LZ
terraform apply `
    --auto-approve `
    -var tenant_id=$TENANT_ID `
    -var subscription_id=$SUBSCRIPTION_ID `
    -var location=$LOCATION `
    -var aro_rp_object_id=$ARO_RP_OBJECT_ID `
    -var aro_base_name=$ARO_BASE_NAME `
    -var aro_domain=$ARO_DOMAIN


# post deployment tasks

#retrieve Jumpbox and ARO creds
$kvName = ''
az keyvault secret show --name "vmadminusername" --vault-name "$kvName" --query "value"
az keyvault secret show --name "vmadminpassword" --vault-name "$kvName" --query "value"


# clean-up
$hubRG = 'hub-aro'
$spokeRG = 'spoke-aro'
$aroClusterName = ''
# delete cluster
# az aro delete --resource-group $spokeRG --name $aroClusterName -y
# delete RGs
# az group delete -n $spokeRG -y
# az group delete -n $hubRG -y
<#
$r = 'jumbpbox'
$rt = 'virtualmachine'
az monitor diagnostic-settings list --resource $r $image = 'quay.io/openshift-release-dev/ocp-release@sha256:86ee723d4dc2a83f836232d1d03f8b4193940c50a2636ee86924acb5d14b0b64'--resource-group $hubRG --resource-type $rt
#>


# cleanup
$rg = 'rg-auea-dev-ncis'
$clusterName = 'aro-auea-dev-ncis-ws01'
az aro delete -g $rg -n $clusterName

