# install docker on the self-hosted agent
# setup docker's apt repository
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# verify docker is working
sudo docker run hello-world 


# test calculator-api
remoteUser='sqlusr001'
remotePassword='***'
remoteSvr='demos-auea-dev-sql-calc'
remoteDb='demos-auea-dev-db-calc'
connectionString="Server=tcp:$remoteSvr.database.windows.net,1433;Initial Catalog=$remoteDb;Persist Security Info=False;User ID=$remoteUser;Password='$remotePassword';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

tag='0.0.1'
sudo docker pull docker.io/daradu/calculator-api:0.0.1
sudo docker run --name calc-api -p 8080:80 -d -e "CALC_DB_CONNECTIONSTRING=$connectionString" daradu/calculator-api:$tag
sudo docker logs calc-api -f
sudo docker rm calc-api -f

expression="1+2"
baseUrl='https://zz-calculator-api-dev-dr.azurewebsites.net' # cloud
baseUrl='http://localhost:8080' # container
baseUrl='http://calculator-api-svc' # K8S ClusterIP
url="${baseUrl}/api/Operation/execute"
contentType='application/json'
method='POST'
data="{\"expression\": \"${expression}\"}"
result=$(curl -s -X $method -H "Content-Type: $contentType" -d "$data" $url)
echo $result