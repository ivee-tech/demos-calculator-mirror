oc apply -f .\platformui.yaml


$ns = 'openshift-marketplace'
oc delete catalogsource ibm-operator-catalog -n $ns
oc apply -f .\ibm-operator-catalog.yaml

$USER_NAME = 'kc-client'
$SECRET = '***'
$REDIRECT_URI = 'https://keycloak-ibm-cp4i-dev.apps.llyp1jmlx9e4cc7cce.australiaeast.aroapp.io/realms/cloudpak/broker/openshift-v4/endpoint'
$c = $(Get-Content .\oauthclient.yaml)
$c = $c.Replace("`${USER_NAME}", $USER_NAME)
$c = $c.Replace("`${SECRET}", $SECRET)
$c = $c.Replace("`${REDIRECT_URI}", $REDIRECT_URI)
# $c
# $c | kubectl delete -n $ns -f -
$c | kubectl apply -n $ns -f -

# get the Url
oc status