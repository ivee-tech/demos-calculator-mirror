# App Connect (IBM)
$acrName = 'acraueadevncisws01'
$source = "icr.io/cpopen/appconnect-operator@sha256:9a6d6aa93de33d99e66ecfc1f71fb76aa24b0904fbc479ce82c49e49d542f920"
$image = "cpopen/appconnect-operator:11.5.1-20240510-151448"
# az acr login -n $acrName
az acr import -n $acrName --source $source --image $image
# create NS
$ns = 'ibm-ace-dev'
oc new-project $ns
# get manifests to check operators available
oc get packagemanifests -n openshift-marketplace
# describe imb-appconnect
oc describe packagemanifests ibm-appconnect -n openshift-marketplace

# set variables for mirroring icr.io
$CASE_NAME='ibm-appconnect'
$CASE_VERSION='11.5.1'
$ARCH='amd64'
# get ibm-pak (download from https://github.com/IBM/ibm-pak)
# curl https://github.com/IBM/ibm-pak/releases/download/v1.15.0/oc-ibm_pak-windows-amd64.tar.gz -o oc-ibm_pak-windows-amd64.tar.gz
# curl https://github.com/IBM/ibm-pak/releases/download/v1.15.0/oc-ibm_pak-windows-amd64.tar.gz.sig -o oc-ibm_pak-windows-amd64.tar.gz.sig
# Copy-Item C:\tools\oc\oc-ibm_pak-windows-amd64 $HOME\AppData\Local\Microsoft\WindowsApps\oc-ibm_pak.exe
# oc ibm-pak --help
oc ibm-pak get ${CASE_NAME} --version ${CASE_VERSION}
# generate the catalog source files for IBM App Connect
oc ibm-pak generate mirror-manifests ${CASE_NAME} icr.io --version ${CASE_VERSION}

docker login -u $acrName -p $acrPassword $acrName.azurecr.io
az acr login -n $acrName

$REGISTRY_AUTH_FILE='C:\Users\daradu\.docker\config.json'
oc image mirror -f C:\Users\daradu/.ibm-pak/data/mirror/${CASE_NAME}/${CASE_VERSION}/images-mapping.txt --filter-by-os '.*' -a $REGISTRY_AUTH_FILE --insecure --skip-multiple-scopes --max-per-registry=1
$REGISTRY_AUTH_FILE

oc get catalogsource -n openshift-marketplace




# IBM Cloud Pak
# several steps for pre-requisites
# ...
# check images - NOT WORKING
$url = 'https://cp.icr.io/v2/_catalog'
$token = "***"
# $headers = @{ Authorization = "Bearer $token" }
$headers = @{ Authorization = "Basic cp:$($token)" }
$result = Invoke-WebRequest -Uri $url -Headers $headers
$result

# get the IBM Cloud Pak for Integration image
$id=$(docker create cp.icr.io/cpopen/cpfs/ibm-pak:v1.15.0 - )
$path = "$($id):/ibm-pak-plugin"
docker cp $path plugin-dir
docker rm -v $id
cd plugin-dir

# set AIRGAP environment variables
# check https://ibm.github.io/cloud-pak/
$env:CASE_NAME = 'ibm-appconnect'
$env:CASE_VERSION = '11.5.1'
$env:OFFLINEDIR="$($env:HOME)/offline"
$env:CASE_REPO_PATH="https://github.com/IBM/cloud-pak/raw/master/repo/case"
$env:CASE_ARCHIVE="$($env:CASE_NAME)-$($env:CASE_VERSION).tgz"
$env:CASE_LOCAL_PATH="$($env:OFFLINEDIR)/$($env:CASE_ARCHIVE)"
# locale
$LOCALE = 'en_US'
oc ibm-pak config locale -l $LOCALE
# config plugin to download CASE as OCI artifacts
oc ibm-pak config repo 'IBM Cloud-Pak OCI registry' -r oci:cp.icr.io/cpopen --enable
# configure colors
oc ibm-pak config color --enable true
# download the CASE
oc ibm-pak get $env:CASE_NAME --version $env:CASE_VERSION
# generate the mirror manifests for IBM App Connect
$acrName = 'acraueadevncisws01'
$env:TARGET_REGISTRY="$($acrName).azurecr.io"
oc ibm-pak generate mirror-manifests $env:CASE_NAME $env:TARGET_REGISTRY --version $env:CASE_VERSION
# check the images to be mirrored
oc ibm-pak describe $env:CASE_NAME --version $env:CASE_VERSION --list-mirror-images
# mirror ACE-related images, failing with authentication errors
# (error: unable to retrieve source image cp.icr.io/cp/appc/acecc-designer-ui-prod manifest)
# $env:REGISTRY_AUTH_FILE="$($HOME)/.docker/config.json"
$env:REGISTRY_AUTH_FILE = "C:\Data\ARO\aro-pull-secret.json"
oc image mirror `
   -f "$($HOME)/.ibm-pak/data/mirror/$env:CASE_NAME/$env:CASE_VERSION/images-mapping.txt" `
   --filter-by-os '.*' `
   -a $env:REGISTRY_AUTH_FILE `
   --insecure `
   --skip-multiple-scopes `
   --max-per-registry=1

# pull / push images 
$filePath = "$HOME/.ibm-pak/data/mirror/$env:CASE_NAME/$env:CASE_VERSION/images-mapping.txt"
$content = Get-Content -Path $filePath -Raw
$lines = $content -split "`n"
$lines | Where-Object { ![string]::IsNullOrEmpty($_) } | ForEach-Object {
    $line = $_ -split "="
    $src = $line[0]
    docker pull $src
}

az acr login -n $acrName
$lines | Where-Object { ![string]::IsNullOrEmpty($_) } | ForEach-Object {
    $line = $_ -split "="
    $src = $line[0]
    $dest = $line[1]
    docker tag $src $dest
    docker push $dest
}


# create the CatalogSource for IBM App Connect
$ns = 'openshift-marketplace'
oc apply -f ./catalog-sources.yaml -n $ns
oc get catalogsource -n $ns
oc get catalogsource appconnect-operator-catalogsource -o yaml -n $ns 
# oc delete catalogsource appconnect-operator-catalogsource -n $ns

# install the IBM App Connect Operator
$ns = 'ibm-ace-dev'
oc new-project $ns
# check the existing operators package manifests
oc get packagemanifests -n openshift-marketplace | findstr ibm
# check ibm-appconnect operator package manifest
oc describe packagemanifests ibm-appconnect -n openshift-marketplace
# updating the ibm-connect operator manually is not working, getting error: 
# Resource: "packages.operators.coreos.com/v1, Resource=packagemanifests", GroupVersionKind: "packages.operators.coreos.com/v1, Kind=PackageManifest"
# Name: "ibm-appconnect", Namespace: "openshift-marketplace"
# for: "./ibm-appconnect.yaml": the server does not allow this method on the requested resource
oc apply -f ./ibm-appconnect.yaml -n openshift-marketplace


oc -n ibm-ace-dev get operatorgroup ibm-ace-dev-n9hl6 -o yaml > .\ibm-appconnect-operator-group.yaml
oc -n ibm-ace-dev get subscription ibm-appconnect -o yaml > .\ibm-appconnect-sub.yaml
oc get namespace ibm-ace-dev -o yaml > ibm-appconnect-ns.yaml


# IBM Catalg Source & Image Content Source Policy
oc apply -f .\catalog-sources.yaml
oc apply -f .\image-content-source-policy.yaml

# IBM App Connect
oc apply -f .\ibm-appconnect-ns.yaml
oc apply -f .\ibm-appconnect-operator-group.yaml
oc apply -f .\ibm-appconnect-sub.yaml

echo -n "cp:<entitlement key>" | base64 -w0

oc get installplans -n ibm-ace-dev
oc get csv -n ibm-ace-dev

oc get sub -n ibm-ace-dev
oc describe sub ibm-appconnect-sub -n ibm-ace-dev

