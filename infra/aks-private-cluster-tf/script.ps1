# 02-state-storage
$REGION='AustraliaEast'
$STORAGEACCOUNTNAME='stgauaeadevtfstate'
$CONTAINERNAME='akscs'
$TFSTATE_RG='rg-auea-dev-tfstate'
$tf = "C:\tools\terraform\terraform.exe"
az group create --name $TFSTATE_RG --location $REGION

az storage account create -n $STORAGEACCOUNTNAME -g $TFSTATE_RG -l $REGION --sku Standard_LRS 

az storage container-rm create --storage-account $STORAGEACCOUNTNAME --name $CONTAINERNAME

$TFSTATE_ACCOUNT_KEY = $(az storage account keys list -g $TFSTATE_RG -n $STORAGEACCOUNTNAME --query "[0].value" -o tsv)
$TFSTATE_ACCOUNT_KEY

Set-Alias -Name tf -Value $tf

# 03-eid
cd .\03-EID-create


tf init -backend-config="resource_group_name=$TFSTATE_RG" `
    -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME" -reconfigure

tf plan

tf apply

# N/A, fails with 400 BadRequest
<#
╷
│ Error: Creating group "AKS App Admin Team 01357"
│
│   with azuread_group.appdevs,
│   on ad_groups.tf line 5, in resource "azuread_group" "appdevs":
│    5: resource "azuread_group" "appdevs" {
│
│ GroupsClient.BaseClient.Post(): unexpected status 400 with OData error: Request_BadRequest: Request contains a property with duplicate values.
╵
╷
│ Error: Creating group "AKS App Dev Team 01357"
│
│   with azuread_group.aksops,
│   on ad_groups.tf line 10, in resource "azuread_group" "aksops":
│   10: resource "azuread_group" "aksops" {
│
│ GroupsClient.BaseClient.Post(): unexpected status 400 with OData error: Request_BadRequest: Request contains a property with duplicate values.
╵
#>
cd ..

# 04-Network-Hub
cd .\04-Network-Hub

tf init -backend-config="resource_group_name=$TFSTATE_RG" `
    -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"

tf plan

tf apply -var admin_password="***"

cd ..

# 05-Network-Spoke
cd ./05-Network-LZ

tf init -backend-config="resource_group_name=$TFSTATE_RG" `
    -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"

tf plan -var access_key=$TFSTATE_ACCOUNT_KEY

tf apply -var access_key=$TFSTATE_ACCOUNT_KEY

cd..

# 06-AKS-supporting
cd ./06-AKS-supporting

tf init -backend-config="resource_group_name=$TFSTATE_RG" `
    -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"

tf plan -var access_key=$TFSTATE_ACCOUNT_KEY

tf apply -var access_key=$TFSTATE_ACCOUNT_KEY

cd ..

# 07-AKS-Cluster
cd ./07-AKS-Cluster
# cd ./07-AKS-Cluster-existing-infra

tf init -backend-config="resource_group_name=$TFSTATE_RG" `
    -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"

tf plan -var access_key=$TFSTATE_ACCOUNT_KEY

tf apply -var access_key=$TFSTATE_ACCOUNT_KEY

cd ..

# 08-workload

# configure App Gateway to accept HTTP traffic
$SPOKERG = 'escs-lz01-SPOKE'
$APPGWSUBNSG = 'vnet-escs-lz01-appgwSubnet-nsg'
az network nsg rule create -g $SPOKERG --nsg-name $APPGWSUBNSG -n AllowHTTPInbound --priority 200 `
   --source-address-prefixes '*' --source-port-ranges '*' `
   --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow `
   --protocol Tcp --description "Allow Inbound traffic through the Application Gateway on port 80"


# connect to the AKS cluster
$rg = 'escs-lz01-SPOKE'
$aksName = 'aks-akscs-blue'
az aks get-credentials --resource-group $rg --name $aksName

<#
bash
rg='escs-lz01-SPOKE'
aksName='aks-akscs-blue'
az aks get-credentials --resource-group $rg --name $aksName
#>

# connect using MI
<#
bash
export KUBECONFIG=~/.kube/config
kubelogin convert-kubeconfig -l msi

kubectl get nodes
#>

# if you already have existing privte DNS zones, you may want to delete the private DNS zones created in the SPOKE RG
$rg = 'escs-lz01-SPOKE'
# $rg = 'escs-hub-HUB'
$linkName = 'aks-akscs-blue-b0wu5wfc'
$dnsZoneName = 'privatelink.australiaeast.azmk8s.io'
az network private-dns link vnet delete -g $rg -n $linkName -z $dnsZoneName
az network private-dns zone delete -g $rg -n $dnsZoneName


# start / stop the cluster

$rg="escs-lz01-SPOKE"
$aksName="aks-akscs-blue"
$action='start' # 'start' # or 'stop'
az aks $action -n $aksName -g $rg
#reconcile the cluster back to its current state
az aks update -g $rg -n $aksName
# update nodepool
$nodePool = 'defaultpool'
az aks nodepool update -g $rg --cluster-name $aksName --name $nodePool
$adminGroupObjectId = '00309fe7-36ff-4283-a695-711c5cf1fd19'
az aks update -g $rg -n $aksName --aad-admin-group-object-ids $adminGroupObjectId --aad-tenant-id $env:FDPO_TENANT_ID


# assign VM identity AcrPush role
$rg = 'escs-hub-hub'
$vmName = 'server-dev-linux'
$acrName = 'acr85618'
$identity = $(az vm show --resource-group $rg --name $vmName --query "identity.principalId" --output tsv)
az role assignment create --assignee $identity --role AcrPush --scope $(az acr show --name $acrName --query id --output tsv)

# assign VM identity roles
$rgHub='escs-hub-hub'
$rgSpoke="escs-lz01-SPOKE"
$vmName='server-dev-linux'
$identity = $(az vm show --resource-group $rgHub --name $vmName --query "identity.principalId" --output tsv)
# assign VM identity AKS role
$aksName="aks-akscs-blue"
$role='Azure Kubernetes Service RBAC Cluster Admin'
$aksId = $(az aks show --resource-group $rgSpoke --name $aksName --query id --output tsv)
az role assignment create --role $role --assignee $identity --scope $aksId 
# assign VM identity KV role
$role='Key Vault Secrets Officer'
$kvName='kv85618-akscs'
$kvId=$(az keyvault show --name $kvName --query id --output tsv)
az role assignment create --role $role --assignee $identity --scope $kvId 

# delete the cluster
$rg="escs-lz01-SPOKE"
$aksName="aks-akscs-blue"
# az aks delete -n $aksName -g $rg


$subscriptionId = $(az account show --query id -o tsv)
$rg = 'escs-hub-hub'
$vnetName = 'vnet-escs-hub'
$subnetName = 'AzureFirewallSubnet'
# az vm list --query "[?virtualNetwork.subnet.id=='/subscriptions/${subscriptionId}/resourceGroups/${rg}/providers/Microsoft.Network/virtualNetworks/${vnetName}/subnets/${subnetName}'].{Name:name}" -o table
$ipAddress='10.0.1.4'
az network nic list --query "[?ipConfigurations[].privateIpAddress=='${ipAddress}']" -o table

# delete the load balancer(s)
$rg='MC_escs-lz01-SPOKE_aks-akscs-blue_australiaeast'
$lbName='kubernetes'
$lbName='kubernetes-internal'
# az network lb delete --name $lbName --resource-group $rg


# GPU
$location = 'AustraliaSoutheast'
az vm list-usage `
  --location ${location} `
  --query "[? contains(localName, 'Standard NCSv3')]" `
  -o table

# check workload identity
$rg="escs-lz01-SPOKE"
$idName="${aksName}-user-id"
$userIdClientId=$(az identity show --resource-group "$rg" --name "$idName" --query 'clientId' -o tsv)
$userIdClientId

az identity list --query "[?name=='${idName}']" -o table

$saName = 'sample-django-app-sa'
az identity federated-credential list -g $rg --identity-name $idName -o table

# troubleshoot
$rg="escs-lz01-SPOKE"
$aksName="aks-akscs-blue"
$cmd="kubectl get pods -A"
$cmd="kubectl get nodes -o wide"
$cmd="ns='itp' && kubectl get svc -n `$ns -o wide"
$cmd="ns='itp' && kubectl get pods -n `$ns -o wide"
$cmd="kubectl get svc -A"
az aks command invoke -g $rg -n $aksName -c $cmd