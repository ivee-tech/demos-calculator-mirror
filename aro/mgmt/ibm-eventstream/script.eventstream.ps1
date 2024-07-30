# set AIRGAP environment variables
# check https://ibm.github.io/cloud-pak/
# check https://www.ibm.com/docs/en/cloud-paks/cp-integration/2023.4?topic=cluster-mirroring-images-bastion-host
$env:CASE_NAME = 'ibm-eventstreams'
$env:CASE_VERSION = '3.3.2'
$env:OFFLINEDIR="$($env:HOME)/offline"
$env:CASE_REPO_PATH="https://github.com/IBM/cloud-pak/raw/master/repo/case"
$env:CASE_ARCHIVE="$($env:CASE_NAME)-$($env:CASE_VERSION).tgz"
$env:CASE_LOCAL_PATH="$($env:OFFLINEDIR)/$($env:CASE_ARCHIVE)"

$env:OPERATOR_PACKAGE_NAME='ibm-eventstreams'
$env:OPERATOR_VERSION='3.3.2'

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

# ensure logged in
# oc login $apiServer -u kubeadmin -p $kubeadminPassword

# IBM Catalog Source & Image Content Source Policy
oc apply -f .\catalog-sources.yaml
oc apply -f .\image-content-source-policy.yaml

oc get CatalogSource -A
oc get ImageContentSourcePolicy -A

# IBM Event Stream
oc apply -f .\ibm-eventstream-ns.yaml
oc apply -f .\ibm-eventstream-operator-group.yaml
oc apply -f .\ibm-eventstream-sub.yaml

