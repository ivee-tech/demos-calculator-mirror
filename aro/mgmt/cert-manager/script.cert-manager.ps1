<#
# install cert-manager without OLM, not working

# download manifests
# https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.28.0/crds.yaml
# https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.28.0/olm.yaml
# https://github.com/jetstack/cert-manager/releases/download/v1.14.5/cert-manager.yaml

oc new-project cert-manager
$ns = 'cert-manager'
oc apply -f ./operators/cert-manager/crds.yaml -n $ns
oc apply -f ./operators/cert-manager/olm.yaml

oc apply -f ./operators/cert-manager/cert-manager.yaml

oc get pods --namespace cert-manager

#>

<# manual import, not recommended
$acrName = 'acraueadevncisws01'
$source = 'quay.io/jetstack/cert-manager-controller:v1.14.2'
az acr login -n $acrName
az acr import -n $acrName --source $source

$source = 'quay.io/jetstack/cert-manager-acmesolver:v1.14.2'
az acr import -n $acrName --source $source

$source = 'quay.io/jetstack/cert-manager-cainjector:v1.14.2'
az acr import -n $acrName --source $source

$source = 'quay.io/jetstack/cert-manager-webhook:v1.14.2'
az acr import -n $acrName --source $source

$regServer = "$acrName.azurecr.io"
$regServer
# the following command work properly, it installs the operator, but it's not running, 
# as the catalog source doesn't exist
$ns = 'openshift-operators'
oc apply -f clusterserviceversion-cert-manager.v1.14.2.yaml -n $ns

#>


# # use opm tool, download from
# # https://github.com/operator-framework/operator-registry
# # pull the bundle image
# docker pull <bundle-image>
# # tag & push the bundle image to your acr
# docker tag <bundle-image> <your-acr-name>.azurecr.io/<your-image-path>:<your-tag>
# docker push <your-acr-name>.azurecr.io/<your-image-path>:<your-tag>
# # generate index image using opm tool
# opm index add --bundles $acrName.azurecr.io/<your-image-path>:<your-tag> --tag <your-acr-name>.azurecr.io/<your-image-path>/index:<your-tag>
# # push the index image to ACR
# docker push <your-acr-name>.azurecr.io/<your-image-path>/index:<your-tag>


# install oc-mirror plugin (only works in RHEL)
# https://docs.openshift.com/container-platform/4.15/installing/disconnected_install/installing-mirroring-disconnected.html
cd /c/tools/oc
tar xvzf oc-mirror.rhel9.tar.gz

chmod +x oc-mirror

mv oc-mirror /usr/local/bin/.

oc mirror help

which oc

# create a mirror workspace
oc mirror init --registry acraueadevncisws01.azurecr.io/mirror/oc-mirror-metadata > imageset-config.yaml 

# make sure .docker/config.json contains all required auths

# mirror the images using the imageset-config file
oc mirror --config=./imageset-config.yaml docker://acraueadevncisws01.azurecr.io

# if you get an out of space error for tmp, extend the volume
# helper commands
df -h
lsblk
sudo vgdisplay

# extend tmp
sudo lvextend -L +10G /dev/mapper/rootvg-tmplv -r


# check operator index and content policy, post oc mirror 
cat oc-mirror-workspace/results-XYZ/catalogSource-redhat-operator-index.yaml
cat oc-mirror-workspace/results-XYZ/imageContentSourcePolicy.yaml

# disable all default operator sources
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": true}]'
# enable the default operator sources
oc patch OperatorHub cluster --type json -p '[{"op": "add", "path": "/spec/disableAllDefaultSources", "value": false}]'

# verify cluser operators
oc get co

# install operator
oc apply -f ./cert-manager-ns.yaml
oc apply -f ./cert-manager-operator-group.yaml
oc apply -f ./cert-manager-sub.yaml

