#!/bin/bash

ns='calculator'

tenantId='16b3c013-d300-468d-ac64-7eda0820b6d3' # FDPO
subscriptionId='2ef01a24-f9c4-4a9f-bca8-7d0ca8fe11fa'
kvWorkloadId='d3d816a1-d038-46d9-b144-feeef0601a00' # Workload Managed Identity ID (ApplicationID) for Azure Key Vault
rg='escs-lz01-SPOKE'
location='AustraliaEast'
aksName="aks-akscs-blue"
kvName="kv85618-akscs"
saName='calculator-sa'

# create namespace (once-off)
# kubectl create ns $ns

# SecretProviderClass
c=$(cat ./calculator-spc.yaml)
c=${c//"{{ .Values.workloadIdentityId }}"/$kvWorkloadId}
c=${c//"{{ .Values.tenantId }}"/$tenantId}
c=${c//"{{ .Values.kvName }}"/$kvName}
echo $c | kubectl apply -n $ns -f -