# install oc CLI
# Windows
$download = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-windows.zip"
Invoke-WebRequest $download -Out oc.zip
Expand-Archive oc.zip -Force
Move-Item .\oc\oc.exe "$env:USERPROFILE\.azure-kubectl"
Remove-Item oc.zip -Force
Remove-Item .\oc -Force -confirm:$false -Recurse

# Linux (Ubuntu 22.04)
download="https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz"
curl -L $download -o oc.tar.gz
tar -xvf oc.tar.gz
sudo mv oc /usr/local/bin
# test
oc version

# connect to ARO
$rg = 'rg-auea-dev-ncis'
$clusterName = 'aro-auea-dev-ncis-ws04'
$kubeadminPassword = $(az aro list-credentials --name $clusterName --resource-group $rg --query "kubeadminPassword" -o tsv)
# $consoleUrl = $(az aro show --name $clusterName --resource-group $rg --query "consoleProfile.url" -o tsv)
$apiServer=$(az aro show -g $rg -n $clusterName --query apiserverProfile.url -o tsv)
oc login $apiServer -u kubeadmin -p $kubeadminPassword

rg='rg-auea-dev-ncis'
clusterName='aro-auea-dev-ncis-ws04'
kubeadminPassword=$(az aro list-credentials --name $clusterName --resource-group $rg --query "kubeadminPassword" -o tsv)
apiServer=$(az aro show -g $rg -n $clusterName --query apiserverProfile.url -o tsv)


# check 
oc whoami

echo "oc login $apiServer -u kubeadmin -p $kubeadminPassword"

# connect to ACR, requires Admin enabled
$acrName = 'acraueadevncisws01'
# az acr update -n $acrName --admin-enabled true
$acrPassword = $(az acr credential show -n $acrName --query "passwords[0].value" -o tsv)

# append the ACR secret to existing secret (typically existing secret is for registry.redhat.io)
$pullSecretLocation = "C:\Data\ARO\aro-pull-secret.json"
# oc get secret/pull-secret -n openshift-config --template='{{index .data ".dockerconfigjson" | base64decode}}' > $pullSecretLocation
# oc registry login --registry="$($acrName).azurecr.io" --auth-basic="$($acrName):$($acrPassword)" --to=$pullSecretLocation 
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=$pullSecretLocation 

# test image
az acr import -n $acrName --source=docker.io/library/hello-world:latest --image=hello-world:latest
oc new-project test
oc create deployment hello-world --image=$acrName.azurecr.io/hello-world:latest
oc delete project test

# check the image policy for ARO upgrades
oc get imagecontentsourcepolicy
oc get imagecontentsourcepolicy image-policy-2 -o yaml > image-policy-2.yaml


