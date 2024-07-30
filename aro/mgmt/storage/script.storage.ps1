$ns = 'test-storage'
oc new-project $ns

# check SC
oc get storageclass

# Dynamic Disk
oc apply -f .\azure-disk-dyn-pvc.yaml
oc apply -f .\pod-disk-dyn.yaml

oc get pvc -n $ns
oc get pods -n $ns

oc describe pvc azure-disk-dyn-pvc -n $ns

# delete
# oc delete -f .\pod-disk-dyn.yaml
# oc delete -f .\azure-disk-dyn-pvc.yaml


# Static Disk
# create pv
oc apply -f .\azure-disk-pv.yaml
oc get pv -n $ns

oc apply -f .\azure-disk-static-pvc.yaml
oc apply -f .\pod-disk-static.yaml

# delete
# oc delete -f .\pod-disk-static.yaml
# oc delete -f .\azure-disk-static-pvc.yaml

# ensure for static provisioning:
# - the ARO SP has read permissions on the disk
# - the disk is in the same region as the ARO cluster
# - the disk is in the same zone as the node (can be controlled via the pod scheduling, by specifying the node name)

# delete ns
# oc delete ns $ns


# Dynamic Files
oc apply -f .\azure-files-dyn-pvc.yaml
oc apply -f .\pod-files-dyn.yaml

oc get pvc -n $ns
oc get pods -n $ns

oc describe pvc azure-files-dyn-pvc -n $ns

# check files
oc exec -it pod-files-dyn -- sh
<#
cd /mnt/azure
ls
echo Test > f.txt
ls
cat f.txt 
#>
oc apply -f .\pod-files-dyn2.yaml

# delete
# oc delete -f .\pod-files-dyn2.yaml
# oc delete -f .\pod-files-dyn.yaml
# oc delete -f .\azure-files-dyn-pvc.yaml


# Static Files

# create secret containing existing storage account name and key
. ..\..\..\utils\base64.ps1
$rg = 'rg-auea-dev-ncis'
$saName = 'stgaueadevdemox01'
$saKey=$(az storage account keys list --account-name $saName -g $rg --query "[0].value" -o tsv)
$saNameBase64 = $saName | base64
$saKeyBase64 = $saKey | base64

$content = Get-Content -Path "azure-files-secret.yaml" -Raw
$content = $content -replace '\${AZURE_SA_NAME}', $saNameBase64
$content = $content -replace '\${AZURE_SA_KEY}', $saKeyBase64
$content | oc apply -f -

# oc apply -f .\azure-files-pv.yaml
# oc apply -f .\azure-files-static-pvc.yaml
oc apply -f .\azurefile-pv.yaml
oc apply -f .\azurefile-pvc.yaml
oc apply -f .\pod-files-static.yaml

oc get pv
oc get pvc -n $ns
oc get pods -n $ns

oc describe pv azurefile-pv
oc describe pvc azurefile-pvc
oc describe pod pod-files-static
oc get secret
oc exec -it pod-files-static -- sh
<#
cd /mnt/azure
ls
echo Test > f.txt
cat f.txt
#>

# delete
# oc delete -f .\pod-files-static.yaml
# oc delete -f .\azure-files-static-pvc.yaml
# oc delete -f .\azure-files-pv.yaml
# oc delete -f .\azurefile-pvc.yaml
# oc delete -f .\azurefile-pv.yaml
