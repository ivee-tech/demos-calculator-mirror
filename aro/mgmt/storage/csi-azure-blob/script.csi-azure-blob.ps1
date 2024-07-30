# based on script located here:
# https://cloud.redhat.com/experts/aro/blob-storage-csi/

# Prerequisites
$LOCATION='australiaeast'
$CLUSTER_NAME='aro-auea-dev-ncis-ws04'
$RG_NAME='rg-auea-dev-ncis' 
$TENANT_ID=$(az account show --query tenantId -o tsv)
$SUB_ID=$(az account show --query id)
$MANAGED_RG=$(az aro show -n $CLUSTER_NAME -g $RG_NAME --query 'clusterProfile.resourceGroupId' -o tsv)
$MANAGED_RG_NAME = $MANAGED_RG -split '/' | Select-Object -Index 4

$CSI_BLOB_PROJECT='csi-azure-blob'
$CSI_BLOB_SECRET='csi-azure-blob-secret'


# Create an identity for the CSI Driver to access the Blob Storage

$APP=$(az ad sp create-for-rbac --display-name aro-blob-csi)
$oApp = $APP | ConvertFrom-Json
$AAD_CLIENT_ID = $oApp.appId
$AAD_CLIENT_SECRET = $oApp.password

$AAD_OBJECT_ID = $(az ad app list --app-id $AAD_CLIENT_ID) | ConvertFrom-Json | Select-Object -ExpandProperty id -First 1

$content = Get-Content -Path "cloud.conf" -Raw
$content = $content -replace '\${TENANT_ID}', $TENANT_ID
$content = $content -replace '\${SUB_ID}', $SUB_ID
$content = $content -replace '\${MANAGED_RG_NAME}', $MANAGED_RG_NAME
$content = $content -replace '\${LOCATION}', $LOCATION
$content = $content -replace '\${AAD_CLIENT_ID}', $AAD_CLIENT_ID
$content = $content -replace '\${AAD_CLIENT_SECRET}', $AAD_CLIENT_SECRET
Set-Content -Path "cloud.temp.conf" -Value $content


oc new-project ${CSI_BLOB_PROJECT}

# oc delete secret ${CSI_BLOB_SECRET}
oc create secret generic ${CSI_BLOB_SECRET} --from-file=cloud-config=cloud.temp.conf

Remove-Item cloud.temp.conf

$content = Get-Content -Path "csi-azureblob-scc.yaml" -Raw
$content = $content -replace '\${CSI_BLOB_PROJECT}', $CSI_BLOB_PROJECT

$content | oc apply -f -

# install driver

helm repo add blob-csi-driver https://raw.githubusercontent.com/kubernetes-sigs/blob-csi-driver/master/charts
helm repo update
helm install blob-csi-driver blob-csi-driver/blob-csi-driver `
  --namespace ${CSI_BLOB_PROJECT} `
  --set linux.distro=fedora `
  --set node.enableBlobfuseProxy=false `
  --set node.cloudConfigSecretNamespace=${CSI_BLOB_PROJECT} `
  --set node.cloudConfigSecretName=${CSI_BLOB_SECRET} `
  --set controller.cloudConfigSecretNamespace=${CSI_BLOB_PROJECT} `
  --set controller.cloudConfigSecretName=${CSI_BLOB_SECRET}

  