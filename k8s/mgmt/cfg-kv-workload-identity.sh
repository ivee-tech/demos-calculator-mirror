#!/bin/bash

# Parameters
# subscriptionId="2ef01a24-f9c4-4a9f-bca8-7d0ca8fe11fa"
# location="AustraliaEast"
# rg="escs-lz01-SPOKE"
# aksName="aks-akscs-blue"
# kvName="kv85618-akscs"
# ns="itp"
# saName="default"

# Set OIDC Issuer Url
oidcIssuer=$(az aks show -n $aksName -g $rg --query "oidcIssuerProfile.issuerUrl" -o tsv)
echo $oidcIssuer
echo "$oidcIssuer/.well-known/openid-configuration"

# Create MI and give KV permission
idName="${aksName}-user-id"
az identity create --name "$idName" --resource-group "$rg" --location "$location" --subscription "$subscriptionId"

userIdClientId=$(az identity show --resource-group "$rg" --name "$idName" --query 'clientId' -o tsv)

# Create Access Policy in KV (if Access is based on policy)
# az keyvault set-policy --name "$kvName" --secret-permissions get --spn "$userIdClientId" --resource-group "$rg"
# OR
# Create role assignment in KV (if Access is based on RBAC)
role="Key Vault Secrets User"
kvId=$(az keyvault show --name $kvName --query id --output tsv)
az role assignment create --role "$role" --assignee $userIdClientId --scope $kvId 

# Establish Federated Identity
az identity federated-credential create --name $saName --identity-name "$idName" --resource-group "$rg" --issuer "$oidcIssuer" --subject system:serviceaccount:"$ns":"$saName"
# az identity federated-credential delete --name $saName --identity-name "$idName" --resource-group "$rg"