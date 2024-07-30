Q: where can I find the bundle image for cert-manager?

A: The bundle image for cert-manager is not officially provided by the cert-manager project. The cert-manager project provides Docker images for the cert-manager components (like the controller, cainjector, and webhook), but it does not provide a bundle image that can be used with Operator Lifecycle Manager (OLM).

If you want to deploy cert-manager with OLM, you might need to create the bundle image yourself. This involves creating a ClusterServiceVersion (CSV) for cert-manager, and then using the operator-sdk tool to create the bundle image.

Alternatively, you can deploy cert-manager without using OLM. The cert-manager project provides YAML manifests that can be used to deploy cert-manager with kubectl or oc. This is the recommended way to install cert-manager on most Kubernetes distributions.

If you are using OpenShift, you can also install cert-manager from the OperatorHub. The OperatorHub provides an operator for cert-manager that includes a CSV and can be deployed with OLM. However, this operator is not officially provided by the cert-manager project, and it might not be available in air-gapped environments.
