$expression = "1+4"
$baseUrl = 'https://zz-calculator-api-dev-dr.azurewebsites.net' # cloud
$baseUrl = 'http://localhost:8080' # container
$baseUrl = 'https://localhost:7057' # VS
$baseUrl = 'http://4.147.253.79' # ktb-aks LoadBalancer
$baseUrl = 'https://demos-auea-dev-api-calc.azurewebsites.net'
$baseUrl = 'https://apim-auea-dev-xyz.azure-api.net'
$url = "$($baseUrl)/api/operation/execute"
$data = @{ expression = $expression }
$contentType = 'application/json'
$method = 'POST'
$body = $data | ConvertTo-Json
# $headersArr = ((Get-Content .\Calculator.Web.Api\headers.json -Raw) | ConvertFrom-Json -Depth 3).headers
# $headers = @{}
# $headersArr | ForEach-Object {
#     $headers.Add($_.Name, $_.Value)
# }
# $subscriptionKey = '***'
# $headers = @{'Ocp-Apim-Subscription-Key' = $subscriptionKey}
# $result = Invoke-WebRequest -Uri $url -Headers $headers -Body $body -Method $method -ContentType $contentType
$result = Invoke-WebRequest -Uri $url -Body $body -Method $method -ContentType $contentType
$result.Content
$result = $null
$result


# test root level
Invoke-WebRequest -Uri $baseUrl

# container
# from api sol folder
$tag='0.0.3'
docker build -t calculator-api:$($tag) --build-arg USE_ENV_VAR=true --build-arg CALL_TYPE=Direct -f .\Calculator.Web.Api\Dockerfile .

# inspect calc-net network and capture calc-db IP address
docker network inspect calc-net

# container connection string
$dbPassword = '***'
# docker container
$IP = '172.25.0.2' # get the IP from calc-db container, using docker network inspect calc-net
$connectionString = "Data source=$($IP);Initial Catalog=CalculatorDB;User ID=sa;Password='$($dbPassword)'"
# local dev
$connectionString = "Data source=.;Initial Catalog=Calculator;Integrated Security=SSPI;"
# remote
$remoteUser = 'sqlusr001'
$remotePassword = '***'
$remoteSvr = 'demos-auea-dev-sql-calc'
$remoteDb = 'demos-auea-dev-db-calc'
$connectionString = "Server=tcp:$remoteSvr.database.windows.net,1433;Initial Catalog=$remoteDb;Persist Security Info=False;User ID=$remoteUser;Password='$remotePassword';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

$env:CALC_DB_CONNECTIONSTRING = $connectionString
[Environment]::SetEnvironmentVariable("CALC_DB_CONNECTIONSTRING", $env:CALC_DB_CONNECTIONSTRING, [System.EnvironmentVariableTarget]::User)

# run container
docker run --name calc-api -p 8080:80 -d -e "CALC_DB_CONNECTIONSTRING=$($env:CALC_DB_CONNECTIONSTRING)" --network calc-net calculator-api:$($tag)
docker run --name calc-api -p 8080:80 -d -e "CALC_DB_CONNECTIONSTRING=$($connectionString)" calculator-api:$($tag)
docker logs calc-api -f
docker rm calc-api -f


# push to external registry
$tag='0.0.3'
$image='calculator-api'
# docker hub
$registry='docker.io'
$rns='daradu' # namespace
# acr
$registry='acraueadevncisws01.azurecr.io'
$rns='calculator' # namespace

$img="${image}:${tag}"
docker tag ${img} ${registry}/${rns}/${img}
# requires docker login
az acr login --name $registry
docker push ${registry}/${rns}/${img}
