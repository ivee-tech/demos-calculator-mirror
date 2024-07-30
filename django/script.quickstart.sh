# build Docker image
image='sample-django-app'
tag='0.0.5'
img="${image}:${tag}"
sudo docker build -t $img .

# test Docker image
sudo docker run --name $image -d -p 8000:8000 $img
sudo docker rm $image
sudo docker ps -a
sudo docker logs $image


# push to ACR
image='sample-django-app'
tag='0.0.5'
# acr
registry='acr85618.azurecr.io'
rns='itp' # namespace

img="${image}:${tag}"
sudo docker tag ${img} ${registry}/${rns}/${img}
# requires docker login
az acr login --name $registry
# OR
token=$(az acr login --name $registry --expose-token --output tsv --query accessToken)
sudo docker login $registry --username 00000000-0000-0000-0000-000000000000 --password $token

sudo docker push ${registry}/${rns}/${img}

# test the app
user='admin'
password='***'
authBas64=$(echo -n $user:$password | base64)
echo $authBas64
# local
baseUrl='http://127.0.0.1:8000'
# k8s - internal
baseUrl='http://sample-django-app-svc'
# k8s - external
baseUrl='http://10.1.16.95'
url="$baseUrl/users/"
curl -u "admin:$password" -H 'Accept: application/json; indent=4' $url
# k8s - ingress external
baseUrl='http://10.1.16.96/itp'
url="$baseUrl/users/"
curl -u "admin:$password" -H 'Accept: application/json; indent=4' $url

# obtain image tag from Dockerfile
dockerfile_path="./Dockerfile"
line=$(grep -E 'LABEL VERSION=' "$dockerfile_path")
regex='[0-9]+\.[0-9]+\.[0-9]+'
[[ $line =~ $regex ]] && tag="${BASH_REMATCH[0]}"
echo "$tag"


# no sudo
sudo groupadd docker
sudo usermod -aG docker $USER
newgrp docker
# test
docker run hello-world