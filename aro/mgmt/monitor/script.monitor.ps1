# follow instructions here:
# https://cloud.redhat.com/experts/aro/clf-to-azure/

# install the RedHat OpenShift Logging operator in openshift-logging
# oc create ns openshift-logging

$AZR_RESOURCE_LOCATION='australiaeast'
$AZR_RESOURCE_GROUP='rg-auea-dev-ncis'
# this value must be unique
$AZR_LOG_APP_NAME='la-auea-dev-ncis-ws01' # "$AZR_RESOURCE_GROUP-$AZR_RESOURCE_LOCATION"

$ns = 'openshift-logging'
# optional, in case you don't have this extension
# az extension add --name log-analytics

# optional, create LA RG and instance
# az group create -n $AZR_RESOURCE_GROUP -l $AZR_RESOURCE_LOCATION
# az monitor log-analytics workspace create -g $AZR_RESOURCE_GROUP -n $AZR_LOG_APP_NAME -l $AZR_RESOURCE_LOCATION

# get the ket
$WORKSPACE_ID=$(az monitor log-analytics workspace show `
    -g $AZR_RESOURCE_GROUP -n $AZR_LOG_APP_NAME `
    --query customerId -o tsv)
$SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys `
    -g $AZR_RESOURCE_GROUP -n $AZR_LOG_APP_NAME `
    --query primarySharedKey -o tsv)

$lns = 'openshift-logging' # 'ibm-cp4i-dev'
# create OpenShift secret
oc -n $lns create secret generic azure-monitor-shared-key --from-literal=shared_key=${SHARED_KEY}
# oc delete secret azure-monitor-shared-key -n $lns

# create ClusterLogging resource
$content = Get-Content -Path "cluster-logging.yaml" -Raw
$content = $content -replace '\${NS}', $lns
# Run oc apply
$content | oc apply -f -
oc get ClusterLogging -n $lns
oc describe ClusterLogging -n $lns
# oc delete ClusterLogging instance -n $lns

oc get sa -n $lns
# create ClusterLogForwarder resource
$content = Get-Content -Path "cluster-log-forwarder.yaml" -Raw
$content = $content -replace '\${NS}', $lns
$content = $content -replace '\${WORKSPACE_ID}', $WORKSPACE_ID
# Run oc apply
$content | oc apply -f -
oc get ClusterLogForwarder -n $lns -o wide
oc describe ClusterLogForwarder -n $lns
# oc delete ClusterLogForwarder instance -n $lns


# wait 5 - 15 minutes
# check logs using az CLI or in the portal
az monitor log-analytics query -w $WORKSPACE_ID  `
   --analytics-query "aro_infrastructure_logs_CL | take 10" --output tsv

# query examples
<#
# keycloak
aro_application_logs_CL 
| where kubernetes_namespace_name_s == "ibm-cp4i-dev" and Message contains "keycloak"
| project TimeGenerated, kubernetes_container_image_s, kubernetes_container_name_s, Message

# PlatformUI
aro_application_logs_CL 
| where kubernetes_namespace_name_s == "ibm-cp4i-dev" and kubernetes_pod_name_s startswith "platformui-ibm-integration-platform-navigator-deployment"
| project TimeGenerated, kubernetes_container_image_s, kubernetes_container_name_s, Message

# audit logs
aro_audit_logs_CL 
| where not(isempty(annotations_authentication_openshift_io_username_s)) and TimeGenerated > ago(5m)
| take 100

aro_audit_logs_CL 
| where annotations_authentication_openshift_io_username_s == "<user name>" and TimeGenerated > ago(5m)
| take 100
#>
