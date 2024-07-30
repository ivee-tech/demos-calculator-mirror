# install operator
oc apply -f ./openshift-logging-ns.yaml
oc apply -f ./openshift-logging-operator-group.yaml
oc apply -f ./openshift-logging-sub.yaml
