# build container images

# inside the jumpbox VM, home dir, create a src directory
mkdir src

# get ratings API repo 
cd src
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-api.git

# get ratings app repo
cd src
git clone https://github.com/MicrosoftDocs/mslearn-aks-workshop-ratings-web.git

# build ratings api and app images
# enter the name of your ACR below
SPOKERG=escs-lz01-SPOKE
ACRNAME=acr85618
cd mslearn-aks-workshop-ratings-api
sudo docker build . -t $ACRNAME.azurecr.io/ratings-api:v1
cd ../mslearn-aks-workshop-ratings-web
sudo docker build . -t $ACRNAME.azurecr.io/ratings-web:v1

# login to ACR
sudo az acr login -n $ACRNAME
# push images to ACR
sudo docker push $ACRNAME.azurecr.io/ratings-api:v1
sudo docker push $ACRNAME.azurecr.io/ratings-web:v1
# verify images in ACR
az acr repository show -n $ACRNAME --image ratings-api:v1
az acr repository show -n $ACRNAME --image ratings-web:v1



# configure Key Vault secret
# update keyvault name, username and password before running the command below
KEYVAULTNAME=kv85618-akscs
USERNAME=dbusr001
PASSWORD='***'
az keyvault secret set --name mongodburi --vault-name $KEYVAULTNAME --value "mongodb://$USERNAME:$PASSWORD@ratings-mongodb.ratingsapp:27017/ratingsdb"

# create environment variable for cluster and its resource group name
ClusterRGName=escs-lz01-SPOKE
ClusterName=aks-akscs-blue

# check the cluster
az aks command invoke --resource-group $ClusterRGName --name $ClusterName  \
    --command "kubectl get nodes"
kubectl get nodes

# create ns ratingsapp
az aks command invoke --resource-group $ClusterRGName --name $ClusterName  \
    --command "kubectl create namespace ratingsapp"
kubectl create namespace ratingsapp

# deploy MongoDB into the cluster
az aks command invoke --resource-group $ClusterRGName --name $ClusterName  \
    --command "helm repo add bitnami https://charts.bitnami.com/bitnami && helm install ratings bitnami/mongodb --namespace ratingsapp --set auth.username=$USERNAME,auth.password=$PASSWORD,auth.database=ratingsdb"
helm repo add bitnami https://charts.bitnami.com/bitnami && helm install ratings bitnami/mongodb --namespace ratingsapp --set auth.username=$USERNAME,auth.password=$PASSWORD,auth.database=ratingsdb

# update the manifests with the corresponding settings

# deploy manifests
# deploy SPC
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f api-secret-provider-class.yaml -n ratingsapp" --file api-secret-provider-class.yaml
kubectl apply -f api-secret-provider-class.yaml -n ratingsapp

# deploy api
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 1-ratings-api-deployment.yaml -n ratingsapp" --file 1-ratings-api-deployment.yaml
kubectl apply -f 1-ratings-api-deployment.yaml -n ratingsapp
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 2-ratings-api-service.yaml -n ratingsapp" --file 2-ratings-api-service.yaml
kubectl apply -f 2-ratings-api-service.yaml -n ratingsapp

# deploy app
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 3a-ratings-web-deployment.yaml -n ratingsapp" --file 3a-ratings-web-deployment.yaml
kubectl apply -f 3a-ratings-web-deployment.yaml -n ratingsapp
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 4-ratings-web-service.yaml -n ratingsapp" --file 4-ratings-web-service.yaml
kubectl apply -f 4-ratings-web-service.yaml -n ratingsapp

# check deployment(s)
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get pods -n ratingsapp"
kubectl get pods -n ratingsapp
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl describe pod <pod name> -n ratingsapp"
kubectl describe pod <pod name> -n ratingsapp
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl logs <pod name> -n ratingsapp"
kubectl logs <pod name> -n ratingsapp

# deploy ingress
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl apply -f 5-http-ratings-web-ingress.yaml -n ratingsapp" --file 5a-http-ratings-web-ingress.yaml
kubectl apply -f 5a-http-ratings-web-ingress.yaml -n ratingsapp
# get IP address from ingress
az aks command invoke --resource-group $ClusterRGName --name $ClusterName   --command "kubectl get ingress -n ratingsapp"
kubectl get ingress -n ratingsapp

# check app gateway
rg=escs-lz01-SPOKE
appGwyName=lzappgw-blue
az network application-gateway show -g $rg -n $appGwyName
az network application-gateway start -g $rg -n $appGwyName
az network application-gateway stop -g $rg -n $appGwyName
