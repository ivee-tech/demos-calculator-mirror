# redhat-marketplace (for IBM App Connect)
# create ns
oc create namespace redhat-marketplace
oc create namespace ibm-software-central
# create RedHat Marketplace Subscription
oc apply -f "https://swc.saas.ibm.com/provisioning/v1/rhm-operator/rhm-operator-subscription?approvalStrategy=Automatic"
# create RedHat Marketplace K8S secret
# RedHat Marketplace Pull Secret (REDHAT_MARKETPLACE_PULL_SECRET)
oc create secret generic redhat-marketplace-pull-secret -n redhat-marketplace --from-literal=PULL_SECRET=$env:REDHAT_MARKETPLACE_PULL_SECRET

# accept the licence
oc patch marketplaceconfig marketplaceconfig -n redhat-marketplace --type='merge' -p '{"spec": {"license": {"accept": true}}}'
# Add the Red Hat Marketplace pull secret to the global pull secret on the cluster (ensure you are using bash)
curl -sL https://swc.saas.ibm.com/provisioning/v1/scripts/update-global-pull-secret | bash -s $env:REDHAT_MARKETPLACE_PULL_SECRET


oc get pods -n ibm-software-central
oc get pods -n redhat-marketplace
