# check target.workload.openshift.io/management
oc get deployment -n openshift-cloud-credential-operator
# oc describe deployment pod-identity-webhook -n openshift-cloud-credential-operator | findstr 'target.workload.openshift.io/management'
oc describe deployment cloud-credential-operator -n openshift-cloud-credential-operator | findstr 'target.workload.openshift.io/management'

# set vars
$KEYVAULT_NAME="kv-auea-dev-ncis-ws01"
$KEYVAULT_SECRET_NAME="secret001"
$RESOURCE_GROUP="rg-auea-dev-ncis"
$LOCATION="australiaeast"
$USER_ASSIGNED_IDENTITY_NAME="aro-wid-ncis-ws01"
$SERVICE_ACCOUNT_NAMESPACE="test-kv"
$SERVICE_ACCOUNT_NAME="test-kv-wid-sa"
$CLUSTER_NAME = 'aro-auea-dev-ncis-ws04'
$TENANT_ID = '6e424d97-163d-46e9-a079-e66d12f36c6e' # change to the correct Tenant ID
$OIDC_ISSUER_URL = "https://login.microsoftonline.com/$TENANT_ID/v2.0"

# set SA issues
# NOT WORKING?
# WHY PATCH NOT WORKING?
oc patch authentication cluster --type=merge -p '{"spec":{"serviceAccountIssuer":"' + ${OIDC_ISSUER_URL} + '"}}'
oc get authentication cluster -o yaml > cluster.yaml

$SERVICE_ACCOUNT_ISSUER=oc get authentication cluster -o jsonpath --template='{ .spec.serviceAccountIssuer }'
$SERVICE_ACCOUNT_ISSUER

oc describe authentication.config.openshift.io cluster -o jsonpath --template='{ .spec.serviceAccountIssuer }'

$SERVICE_ACCOUNT_ISSUER=oc get oauth cluster -o jsonpath --template='{ .spec.identityProviders[0].openID.issuer }'
$SERVICE_ACCOUNT_ISSUER

# create KV
# If necessary, create the Resource Group (this may not be necessary) 
# az group create --name "${RESOURCE_GROUP}" --location "${LOCATION}"
# Create the Keyvault and set a secret value
az keyvault create --resource-group "${RESOURCE_GROUP}" --location "${LOCATION}" --name "${KEYVAULT_NAME}"
az keyvault secret set --vault-name "${KEYVAULT_NAME}" --name "${KEYVAULT_SECRET_NAME}" --value "Hello world"

# Create the identity
az identity create --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" 

# Set policy access for user-assigned managed identity
$USER_ASSIGNED_IDENTITY_CLIENT_ID="$(az identity show --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --query 'clientId' -otsv)"
$USER_ASSIGNED_IDENTITY_OBJECT_ID="$(az identity show --name "${USER_ASSIGNED_IDENTITY_NAME}" --resource-group "${RESOURCE_GROUP}" --query 'principalId' -otsv)"
# if using access policies:
az keyvault set-policy --name "${KEYVAULT_NAME}" --secret-permissions get --object-id "${USER_ASSIGNED_IDENTITY_OBJECT_ID}" 
# if using Azure RBAC:
$KVID = $(az keyvault show -n $KEYVAULT_NAME -g $RESOURCE_GROUP --query id)
az role assignment create --assignee $USER_ASSIGNED_IDENTITY_OBJECT_ID --role "Key Vault Secrets User" --scope $KVID

# create project / ns
oc new-project "$SERVICE_ACCOUNT_NAMESPACE"

# Create the Service Account
# Get the content of the YAML file and replace placeholders with variable values
$content = Get-Content -Path "kv-sa.yaml" -Raw
$content = $content -replace '\${USER_ASSIGNED_IDENTITY_CLIENT_ID}', $USER_ASSIGNED_IDENTITY_CLIENT_ID
$content = $content -replace '\${SERVICE_ACCOUNT_NAME}', $SERVICE_ACCOUNT_NAME
$content = $content -replace '\${SERVICE_ACCOUNT_NAMESPACE}', $SERVICE_ACCOUNT_NAMESPACE
# Run oc apply
$content | oc apply -f -

# create the federated identity
az identity federated-credential create `
    --name "kubernetes-federated-credential" `
    --identity-name "${USER_ASSIGNED_IDENTITY_NAME}" `
    --resource-group "${RESOURCE_GROUP}" `
    --issuer "${SERVICE_ACCOUNT_ISSUER}" `
    --subject "system:serviceaccount:${SERVICE_ACCOUNT_NAMESPACE}:${SERVICE_ACCOUNT_NAME}"

# get KV url
$KEYVAULT_URL="$(az keyvault show -g ${RESOURCE_GROUP} -n ${KEYVAULT_NAME} --query properties.vaultUri -o tsv)"

# create KV pod
# Get the content of the YAML file and replace placeholders with variable values
$content = Get-Content -Path "kv-pod.yaml" -Raw
$content = $content -replace '\${SERVICE_ACCOUNT_NAMESPACE}', $SERVICE_ACCOUNT_NAMESPACE
$content = $content -replace '\${SERVICE_ACCOUNT_NAME}', $SERVICE_ACCOUNT_NAME
$content = $content -replace '\${KEYVAULT_URL}', $KEYVAULT_URL
$content = $content -replace '\${KEYVAULT_SECRET_NAME}', $KEYVAULT_SECRET_NAME
# Run oc apply
$content | oc apply -f -

# check pod
oc describe pod quick-start
oc logs quick-start

# delete pod
# oc delete pod quick-start