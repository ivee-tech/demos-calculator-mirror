$source = 'quay.io/argoprojlabs/argocd-operator@sha256:82fc1fefd981bf96a1411cde9c8998db956b918b18221727797c2d7c5dffe6f3'
$acrName = 'acraueadevncisws01'
$image = 'argocd/argocd-operator:0.10.1'
az acr login -n $acrName
az acr import -n $acrName --source $source --image $image

oc mirror list operators --catalogs --version=4.12
<#
Available OpenShift OperatorHub catalogs:
OpenShift 4.12:
registry.redhat.io/redhat/redhat-operator-index:v4.12
registry.redhat.io/redhat/certified-operator-index:v4.12
registry.redhat.io/redhat/community-operator-index:v4.12
registry.redhat.io/redhat/redhat-marketplace-index:v4.12
#>
oc mirror list operators --catalog=registry.redhat.io/redhat/community-operator-index:v4.12


$packageName = 'argocd-operator'
$channel = 'alpha'

# edit the imageset-config.yaml file to include the catalog and the corresponding package(s)

oc mirror --config=./imageset-config.yaml docker://acraueadevncisws01.azurecr.io

oc apply -f oc-mirror-workspace/results-XYZ/catalogSource-community-operator-index.yaml
oc apply -f oc-mirror-workspace/results-XYZ/imageContentSourcePolicy.yaml


oc apply -f .\argocd-ns.yaml
oc apply -f .\argocd-operator-group.yaml
oc apply -f .\argocd-sub.yaml

oc get catalogsource -n openshift-marketplace

# delete the catalog source argocd-operator-catalogsource was causing issues with the operators installation
# oc delete -n openshift-marketplace  catalogsource argocd-operator-catalogsource


# RedHat GitOps Operator (upstream ArgoCD)
oc mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.12

<#
edit imageset-config.yaml
openshift-gitops-operator                     
Red Hat OpenShift GitOps                                 
latest
#>

oc mirror --config=./imageset-config.yaml docker://acraueadevncisws01.azurecr.io

oc apply -f oc-mirror-workspace/results-XYZ/catalogSource-community-operator-index.yaml
oc apply -f oc-mirror-workspace/results-XYZ/imageContentSourcePolicy.yaml

oc get ns openshift-gitops -o yaml > openshift-gitops-ns.yaml
oc get operatorgroup -n openshift-gitops-operator openshift-gitops-operator-vxwc7 -o yaml > openshift-gitops-operator-group.yaml
oc get sub -n openshift-gitops-operator openshift-gitops-operator - o yaml > openshift-gitops-operator-sub.yaml

oc apply -f .\openshift-gitops-ns.yaml
oc apply -f .\openshift-gitops-operator-group.yaml
oc apply -f .\openshift-gitops-sub.yaml

