# create secret settings--calcdbconnectionstring

. ../../utils/base64.ps1

$ns = 'calculator'
# oc get ns $ns
# oc create ns $ns

$connectionString = "***"
$connectionStringBase64 = $connectionString | base64
# $connectionStringBase64
oc create secret generic settings--calcdbconnectionstring --from-literal CALC_DB_CONNECTIONSTRING=$connectionStringBase64 -n $ns


oc apply -f .\calculator-api-dep.yaml -f .\calculator-api-svc.yaml -n $ns
