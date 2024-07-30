#!/bin/bash

# start / stop cluster
rg="escs-lz01-SPOKE"
aksName="aks-akscs-blue"
action='start' # start / stop
az aks $action -n $aksName -g $rg

# install NGINX & certificate manager
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add jetstack https://charts.jetstack.io

helm repo update

helm install ingress-nginx ingress-nginx \
  --create-namespace \
  --namespace ingress-nginx \
  --set controller.replicaCount=3 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true
#   --set controller.metrics.enabled=true \
#   --set controller.metrics.serviceMonitor.enabled=true \
#   --set controller.metrics.serviceMonitor.additionalLabels.release="prometheus" \

repo='https://kubernetes.github.io/ingress-nginx' 
helm repo add ingress-nginx $repo
helm repo update
helm upgrade --install ingress-nginx ingress-nginx \
  --repo $repo \
  --namespace ingress-nginx --create-namespace \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.externalTrafficPolicy=Local \
  --set defaultBackend.image.image=defaultbackend-amd64:1.5 \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-internal"=true

# check the status
    
# check ingress controller
kubectl get svc -n ingress-nginx \
    -o=custom-columns=NAME:.metadata.name,TYPE:.spec.type,IP:.status.loadBalancer.ingress[0].ip
kubectl describe deploy ingress-nginx-controller -n ingress-nginx

# uninstall
ins='ingress-nginx'
helm uninstall $ins -n $ins
kubectl delete ns $ins
# kubectl delete ns $ins --grace-period=0 --force
# kubectl get ns $ins -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$ins/finalize" -f -

# Get all resource types supported by your cluster
for resource in $(kubectl api-resources --verbs=list --namespaced=true -o name); do
  # Attempt to list resources of this type in the specified namespace
  echo "Listing $resource in $ins namespace:"
  kubectl get $resource --namespace $ins
done
# OR using get all
kubectl -n $ins get all -A -o wide

# Install certificate manager
helm install cert-manager jetstack/cert-manager \
  --create-namespace \
  --namespace cert-manager \
  --set crds.enabled=true \
  --set nodeSelector."kubernetes\.io/os"=linux
#  --set installCRDs=true \



# deploy manifests

tenantId=$(az account show --query tenantId -o tsv) # FDPO
subscriptionId=$(az account show --query id -o tsv)
rg='escs-lz01-SPOKE'
aksName="aks-akscs-blue"
kvName="kv85618-akscs"
saName='sample-django-app-sa'
idName="${aksName}-user-id"
kvWorkloadId=$(az identity show --resource-group "$rg" --name "$idName" --query 'clientId' -o tsv)
ns='itp'

# create namespace (once-off)
# kubectl create ns $ns

# Service account
c=$(<./sample-django-app-sa.yaml)
c=${c//"{{ .Values.workloadIdentityId }}"/$kvWorkloadId}
printf "%s\n" "$c" | kubectl apply -n $ns -f -


# SecretProviderClass
c=$(cat ./sample-django-app-spc.yaml)
c=${c//"{{ .Values.workloadIdentityId }}"/$kvWorkloadId}
c=${c//"{{ .Values.tenantId }}"/$tenantId}
c=${c//"{{ .Values.kvName }}"/$kvName}
printf "%s\n" "$c" | kubectl apply -n $ns -f -

# default ing
# kubectl apply -f default-dep.yaml -f default-svc.yaml -f default-ing.yaml
# kubectl create ns $ns

ns='itp'
tag='0.0.4'
cd k8s/sample-django-app
c=$(<./sample-django-app-dep.yaml)
c=${c//"{{ .Values.tag }}"/$tag}
printf "%s\n" "$c" | kubectl apply -n $ns -f -

kubectl apply -f ./sample-django-app-svc-cip.yaml -f ./sample-django-app-ing.yaml -n $NS

kubectl apply -f sample-django-app-dep.yaml -f sample-django-app-svc-cip.yaml -f sample-django-app-ing.yaml -n $ns
kubectl apply -f sample-django-app-test-dep.yaml -n $ns
# delete 
# svcName='sample-django-app-svc'
# kubectl patch svc $svcName -n $ns -p '{"metadata":{"finalizers":[]}}' --type=merge
# kubectl delete -f sample-django-app-dep.yaml -f sample-django-app-svc-cip.yaml -f sample-django-app-ing.yaml -n $ns

# test the secret integration
kubectl get secret sampledjangoapp--adminpassword -n $ns
kubectl get pods -n $ns
podName='sample-django-app-dep-test-XYZ'
kubectl exec -it $podName -n $ns -- sh
#
# printenv | grep -i ADMIN_PASSWORD
# curl -u admin:${ADMIN_PASSWORD} -H 'Accept: application/json; indent=4' http://sample-django-app-svc/users/
#

kubectl run -it test --rm --image=curlimages/curl -n $ns -- sh
#
# curl -u admin:${ADMIN_PASSWORD} -H 'Accept: application/json; indent=4' http://sample-django-app-svc/users/
# curl -u admin:${ADMIN_PASSWORD} -H 'Accept: application/json; indent=4' http://sample-django-app-svc.itp.svc.cluster.local/users/
#
