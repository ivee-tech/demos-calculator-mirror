# scale machineset
$machinesetName = 'aro-auea-dev-ncis-ws0-dzpcq-worker-australiaeast2'
$replicas = 0
oc scale machineset $machinesetName --replicas=$replicas -n openshift-machine-api
