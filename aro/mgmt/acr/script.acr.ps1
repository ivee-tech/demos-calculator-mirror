# import image into ACR
$acrName = 'acraueadevncisws01'
$source = 'quay.io/openshift-release-dev/ocp-release@sha256:86ee723d4dc2a83f836232d1d03f8b4193940c50a2636ee86924acb5d14b0b64'
$image = 'openshift-release-dev/ocp-release:4.12.30-x86_64'
az acr import -n $acrName --source $source --image $image

docker login https://registry.redhat.io


$source = 'registry.redhat.io/cert-manager/cert-manager-operator-rhel9@sha256:c8b4151d0a12d1ded3b8ba02e591a446ced3c0934715c4b2f80902889d05edf8'
$image = 'cert-manager/cert-manager-operator-rhel9:1.12.1'

# 
$source = 'registry.redhat.io/cert-manager/cert-manager-operator-rhel9@sha256:7c91fe72e3e920667838d402f64717e4c78024a7cb04a97b0ba939077864f0d5'
$image = 'cert-manager/cert-manager-operator-rhel9:v1.13.1-1'
# az acr import -n $acrName --source $source --image $image
docker pull $source
$destImg = "$($acrName).azurecr.io/$($image)"
docker tag $source $destImg
docker push $destImg

# import olm image into ACR
$source = 'quay.io/operator-framework/olm@sha256:40d0363f4aa684319cd721c2fcf3321785380fdc74de8ef821317cd25a10782a'
$image = 'operator-framework/olm:0.28.0'
az acr import -n $acrName --source $source --image $image
# import catalog image into ACR
$source = 'quay.io/operatorhubio/catalog:latest'
$image = 'operatorhubio/catalog:latest'
az acr import -n $acrName --source $source --image $image
# import cert-manager-cainjector image into ACR
$source = 'quay.io/jetstack/cert-manager-cainjector:v1.14.5'
$image = 'jetstack/cert-manager-cainjector:v1.14.5'
az acr import -n $acrName --source $source --image $image
# import cert-manager-controller image into ACR
$source = 'quay.io/jetstack/cert-manager-controller:v1.14.5'
$image = 'jetstack/controller:v1.14.5'
az acr import -n $acrName --source $source --image $image
# import cert-manager-acmesolver image into ACR
$source = 'quay.io/jetstack/cert-manager-acmesolver:v1.14.5'
$image = 'acraueadevncisws01.io/jetstack/cert-manager-acmesolver:v1.14.5'
az acr import -n $acrName --source $source --image $image
