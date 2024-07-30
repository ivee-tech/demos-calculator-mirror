$repo = 'daradu'
$tag = '0.0.1'
$ns = 'calculator'

$tenantId =  $(az account show --query tenantId -o tsv) # FDPO
$subscriptionId = $(az account show --query id -o tsv)
# $kvWorkloadId = '513e8c96-1937-416d-bcf4-3f2b1c215bf3' # Workload Managed Identity ID (ApplicationID) for Azure Key Vault
# 3bafe832-774d-481f-9d6a-2491243e89ab (ObjectID)
# $kvWorkloadId = 'fd41ebe2-c36d-4db0-9693-12dbf8eb8b05' # use kubelet identity
$rg = 'escs-lz01-SPOKE'
$location = 'AustraliaEast'
$kvName = 'kv85618-akscs'
$aksName = 'aks-akscs-blue'
$saName = 'sample-djangoa-app-sa'

# get KV url
$kvUrl = "$(az keyvault show -g $rg -n $kvName --query properties.vaultUri -o tsv)"
$kvUrl

# run config workload identity script
# $kvWorkloadIdName = 'ktb-aks-user-id'
..\..\scripts\cfg-kv-workload-identity.ps1 -subscriptionId $subscriptionId -location $location -rg $rg -aksName $aksName -kvName $kvName -ns $ns -saName $saName


# create namespace (once-off)
kubectl create ns $ns

# SecretProviderClass
$c = $(Get-Content .\calculator-spc.yaml)
$c = $c.Replace("{{ .Values.workloadIdentityId }}", $kvWorkloadId)
$c = $c.Replace("{{ .Values.tenantId }}", $tenantId)
$c = $c.Replace("{{ .Values.kvName }}", $kvName)
# $c | kubectl delete -n $ns -f -
$c | kubectl apply -n $ns -f -

# ServiceAccount
$c = $(Get-Content .\calculator-sa.yaml)
$c = $c.Replace("{{ .Values.workloadIdentityId }}", $kvWorkloadId)
$c = $c.Replace("{{ .Values.tenantId }}", $tenantId)
$c | kubectl apply -n $ns -f -

# secrets role - NOT USED
$c = $(Get-Content .\calculator-secrets-role.yaml)
$c = $c.Replace("{{ .Values.namespace }}", $ns)
$c | kubectl apply -n $ns -f -

# secrets role binding - NOT USED
$c = $(Get-Content .\calculator-secrets-rb.yaml)
$c = $c.Replace("{{ .Values.namespace }}", $ns)
$c = $c.Replace("{{ .Values.saName }}", $saName)
$c = $c.Replace("{{ .Values.roleName }}", 'calculator-secrets-role')
$c | kubectl apply -n $ns -f -

# api deployment
$c = $(Get-Content .\calculator-api-dep.yaml)
$c = $c.Replace("{{ .Values.namespace }}", $ns)
$c = $c.Replace("{{ .Values.repo }}", $repo)
$c = $c.Replace("{{ .Values.api.tag }}", $tag)
# $c | kubectl delete -n $ns -f -
# kubectl delete deployment calculator-api-dep -n $ns
$c | kubectl apply -n $ns -f -

# api service
$apiServicePort = 80
$apiServiceType = 'LoadBalancer'
$c = $(Get-Content .\calculator-api-svc.yaml)
$c = $c.Replace("{{ .Values.namespace }}", $ns)
$c = $c.Replace("{{ .Values.api.servicePort }}", $apiServicePort)
$c = $c.Replace("{{ .Values.api.serviceType }}", $apiServiceType)
# $c | kubectl delete -n $ns -f -
# kubectl delete svc calculator-api-svc -n $ns
$c | kubectl apply -n $ns -f -

# ui deployment
$c = $(Get-Content .\calculator-ui-dep.yaml)
$c = $c.Replace("{{ .Values.namespace }}", $ns)
$c = $c.Replace("{{ .Values.repo }}", $repo)
$c = $c.Replace("{{ .Values.ui.tag }}", $tag)
# $c | kubectl delete -n $ns -f -
# kubectl delete deployment calculator-api-dep -n $ns
$c | kubectl apply -n $ns -f -

# ui service
$uiServicePort = 80
$uiServiceType = 'LoadBalancer'
$c = $(Get-Content .\calculator-ui-svc.yaml)
$c = $c.Replace("{{ .Values.namespace }}", $ns)
$c = $c.Replace("{{ .Values.ui.servicePort }}", $uiServicePort)
$c = $c.Replace("{{ .Values.ui.serviceType }}", $uiServiceType)
# $c | kubectl delete -n $ns -f -
# kubectl delete svc calculator-api-svc -n $ns
$c | kubectl apply -n $ns -f -

# troubleshooting
$pods = $(kubectl get pods --selector 'app in (csi-secrets-store-provider-azure, secrets-store-provider-azure)' `
    --all-namespaces `
    --output custom-columns=NAME:.metadata.name) # jsonpath='{.items[*].metadata.name}') # wide
$pods
$pods[0]
$tns = 'kube-system'
$pods | Select-Object -Skip 1 | Foreach-Object {
    kubectl logs $_ -n $tns # --since=1h | findstr /I error
}

$rg = 'k8s-tech-brief-rg'
$aksName = 'ktb-aks'
$saName = 'calculator-sa'
$idName = "$aksName-user-id"
$ns = 'calculator'

az aks show --resource-group $rg --name $aksName --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId --output tsv

az identity federated-credential show --name $saName --identity-name $idName -g $rg

# kubectl auth can-i create secret --as="system:serviceaccount:$($ns):$($saName)" -n $ns

$KUBELET_OBJID=$(az aks show -g $rg -n $aksName --query identityProfile.kubeletidentity.objectId -o tsv)
$KUBELET_OBJID
$AKV_ID=$(az keyvault show -g $rg -n $kvName --query id -o tsv)
az role assignment create --assignee $KUBELET_OBJID --role "Key Vault Secrets User" --scope $AKV_ID

$KUBELET_ID=$(az aks show -g $rg -n $aksName --query identityProfile.kubeletidentity.clientId -o tsv)
$KUBELET_ID

# kubectl delete ns $ns
