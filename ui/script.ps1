
$tag = '0.0.1'
docker rm calc-ui -f
cat Dockerfile
docker build -t calculator-ui:$($tag) .

docker run -d -p 8081:80 --name calc-ui calculator-ui:$($tag)
docker logs calc-ui -f
docker rm calc-ui -f
docker rmi calculator-ui:$($tag) -f


# push to docker hub
$tag = '0.0.1'
$image='calculator-ui'
# docker hub
$registry='docker.io'
$rns='daradu' # namespace
# acr
$registry='acr85618.azurecr.io'
$rns='calculator' # namespace

$img="${image}:${tag}"
docker tag ${img} ${registry}/${rns}/${img}
# requires docker login
docker push ${registry}/${rns}/${img}
