# Test the CSI driver is working

$RG_NAME='rg-auea-dev-ncis' 
$CSI_TESTING_PROJECT='test-storage'
$AAD_CLIENT_ID = '247cf285-2110-4a2f-91b8-fd4e8473bf4c'
$STORAGE_ACCOUNT_NAME='stgaueadevdemox01'
$BLOB_CONTAINER_NAME='aroblob'


$AZURE_STORAGE_ACCOUNT_ID=$(az storage account show --name $STORAGE_ACCOUNT_NAME -g $RG_NAME --query 'id' -o tsv)
# $AZURE_STORAGE_ACCESS_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT_NAME -g $RG_NAME --query "[0].value" | tr -d '"')

az role assignment create --assignee $AAD_CLIENT_ID `
  --role "Storage Account Contributor" `
  --scope ${AZURE_STORAGE_ACCOUNT_ID}


oc new-project ${CSI_TESTING_PROJECT}
# OR
oc project ${CSI_TESTING_PROJECT}

$content = Get-Content -Path "blob-sc.yaml" -Raw
$content = $content -replace '\${RG_NAME}', $RG_NAME
$content = $content -replace '\${STORAGE_ACCOUNT_NAME}', $STORAGE_ACCOUNT_NAME
$content = $content -replace '\${BLOB_CONTAINER_NAME}', $BLOB_CONTAINER_NAME
$content | oc apply -f -

oc apply -f .\blob-pvc.yaml
oc apply -f .\pod-blob.yaml

# test blob

oc get po nginx-blob
oc describe po nginx-blob

oc get pvc blob-pvc
# oc delete pvc blob-pvc -n 
oc describe pvc blob-pvc

oc get sc


oc get pods
# oc delete pod nginx-blob -n csi-azure-blob
# oc delete pvc blob-pvc -n csi-azure-blob

oc exec -it nginx-blob -- sh
<#
df -h
ls -al /mnt/blob/outfile
cat /mnt/blob/outfile
#>


