expression="1+2"
baseUrl='https://zz-calculator-api-dev-dr.azurewebsites.net' # cloud
baseUrl='http://localhost:8080' # container
baseUrl='https://localhost:7057' # VS
baseUrl='http://4.147.253.79' # ktb-aks LoadBalancer
baseUrl='http://calculator-api-svc' # ktb-aks ClusterIP
url="${baseUrl}/api/Operation/execute"
contentType='application/json'
method='POST'
data="{\"expression\": \"${expression}\"}"

# using curl
result=$(curl -s -X $method -H "Content-Type: $contentType" -d $data $url)
echo $result

# using wget
result=$(wget -qO- --header="Content-Type: $contentType" --body-data=$data $url)
echo $result