# Variables
resourceGroup="escs-lz01-SPOKE"  # replace with your resource group name
aksClusterName="aks-akscs-blue"   # replace with your AKS cluster name
nodePoolName="userpool1"       # replace with your desired node pool name

# Create a new node pool
az aks nodepool add \
    --resource-group $resourceGroup \
    --cluster-name $aksClusterName \
    --name $nodePoolName \
    --node-count 3 \
    --node-vm-size Standard_D2s_v3 \
    --os-type Linux


# enable workload identity for KV integration
az aks update --resource-group $resourceGroup --name $aksClusterName --enable-oidc-issuer --enable-workload-identity


# create the calculator DB connection string secret in KV
# Variables
kvName="kv85618-akscs"  # replace with your Key Vault name
secretName="Settings--CalcDbConnectionString"  # replace with your secret name
remoteUser='sqlusr001'
remotePassword='***'
remoteSvr='demos-auea-dev-sql-calc2'
remoteDb='demos-auea-dev-db-calc'
connectionString="Server=tcp:$remoteSvr.database.windows.net,1433;Initial Catalog=$remoteDb;Persist Security Info=False;User ID=$remoteUser;Password='$remotePassword';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
secretValue=$connectionString  # replace with your secret value

# Create a new secret
az keyvault secret set \
    --name $secretName \
    --value "$secretValue" \
    --vault-name $kvName

# allow HTTP traffic to the Application Gateway
SPOKERG='escs-lz01-SPOKE'
APPGWSUBNSG='vnet-escs-lz01-appgwSubnet-nsg'
az network nsg rule create -g $SPOKERG --nsg-name $APPGWSUBNSG -n AllowHTTPInbound --priority 200 \
    --source-address-prefixes '*' --source-port-ranges '*' \
    --destination-address-prefixes '*' --destination-port-ranges 80 --access Allow \
    --protocol Tcp --description "Allow Inbound traffic through the Application Gateway on port 80"

# start / stop AppGateway
rg='escs-lz01-SPOKE'
appGWName='lzappgw-blue'
az network application-gateway start -g $rg -n $appGWName
az network application-gateway show -g $rg -n $appGWName

# check add-ons
rg='escs-lz01-SPOKE'
aksName='aks-akscs-blue'
az aks addon list -g $rg -n $aksName -o table

# sample django app secrets
kvName='kv85618-akscs'
secretName='SampleDjangoApp--AdminPassword'
secretValue='***'
az keyvault secret set \
    --name $secretName \
    --value "$secretValue" \
    --vault-name $kvName


# from k8s/mgmt
export subscriptionId=$(az account show --query id -o tsv)
export rg=escs-lz01-SPOKE
export location=AustraliaEast
export aksName=aks-akscs-blue
export kvName=kv85618-akscs
export ns=itp
export saName=sample-django-app-sa
sh ./cfg-kv-workload-identity.sh