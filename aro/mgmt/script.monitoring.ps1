<#
Metrics overview
https://learn.microsoft.com/en-gb/azure/azure-monitor/essentials/prometheus-metrics-overview
Query examples
https://prometheus.io/docs/prometheus/latest/querying/examples/
Check CPU & memory
https://access.redhat.com/solutions/6800531
#>
# prometheus
oc get routes -n openshift-monitoring prometheus-k8s
$prometheusUrl = 'https://prometheus-k8s-openshift-monitoring.apps.blwh1nqch7548bddad.australiaeast.aroapp.io'
$svcDetails = $(oc describe svc prometheus-k8s -n openshift-monitoring)
$svcDetails | findstr version

$token = $(oc whoami -t)
$headers = @{ Authorization = "Bearer $token"}
$result = Invoke-WebRequest -Uri $prometheusUrl -Headers $headers
$result.Content
"Bearer $token"
