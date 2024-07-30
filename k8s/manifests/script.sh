# test api deployment
ns='calculator'
kubectl run -it --rm test-api --image=curlimages/curl -n $ns -- sh
# run this script inside the test-api pod
expression="1+2"
baseUrl='http://calculator-api-svc' # K8S ClusterIP
# baseUrl='http://10.1.16.153:32639'
baseUrl='http://10.1.16.182' # K8S internal LB
url="${baseUrl}/api/Operation/execute"
contentType='application/json'
method='POST'
data="{\"expression\": \"${expression}\"}"
result=$(curl -s -X $method -H "Content-Type: $contentType" -d "$data" $url)
echo $result