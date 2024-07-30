# Documentation for ARO CLuster Management Tasks

## Create using TF

## Create using CLI

## Connect

daradu_MSDEMO: generate markdown doco for the current file

GitHub Copilot: # Documentation for script.connect.ps1

This PowerShell script is used to connect to an Azure Red Hat OpenShift (ARO) cluster and an Azure Container Registry (ACR). It also tests the connection by deploying a hello-world image from the ACR to the ARO cluster.

Here's a breakdown of what the script does:

1. **Login to OpenShift Cluster**: The script logs into the OpenShift cluster using the `oc login` command. The API server URL is retrieved using the `az aro show` command.

```powershell
$apiServer=$(az aro show -g $rg -n $clusterName --query apiserverProfile.url -o tsv)
oc login $apiServer -u kubeadmin -p $kubeadminPassword
```

2. **Connect to Azure Container Registry (ACR)**: The script connects to the ACR using the `az acr credential show` command to retrieve the ACR password. The ACR name is hardcoded in the script.

```powershell
$acrName = 'acraueadevncisws01'
$acrPassword = $(az acr credential show -n $acrName --query "passwords[0].value" -o tsv)
```

3. **Update OpenShift Secret**: The script updates the OpenShift secret with the ACR credentials. This allows the OpenShift cluster to pull images from the ACR.

```powershell
$pullSecretLocation = "C:\Data\ARO\all-xyz-acr.pull-secret.json"
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson=$pullSecretLocation 
```

4. **Test Image Deployment**: The script imports the hello-world image from Docker Hub to the ACR using the `az acr import` command. It then creates a new project in the OpenShift cluster, deploys the hello-world image, and finally deletes the project.

```powershell
az acr import -n $acrName --source=docker.io/library/hello-world:latest --image=hello-world:latest
oc new-project test
oc create deployment hello-world --image=$acrName.azurecr.io/hello-world:latest
oc delete project test
```

Please replace the placeholder values with your actual values before running the script.

## Upgrade

This PowerShell script is used to upgrade a cluster. Here's a breakdown of what each line does:

```powershell
# upgrade cluster
```
This is a comment indicating that the script is used for upgrading a cluster.

```powershell
$acrName = 'acraueadevncisws01'
```
This line sets the variable `$acrName` to the string 'acraueadevncisws01', which is the name of the Azure Container Registry (ACR).

```powershell
$acrServer = "$($acrName).azurecr.io"
```
This line sets the variable `$acrServer` to the server address of the ACR. It uses the `$acrName` variable and appends '.azurecr.io' to it.

```powershell
$ocpImage = "$($acrServer)/openshift-release-dev/ocp-release@sha256:86ee723d4dc2a83f836232d1d03f8b4193940c50a2636ee86924acb5d14b0b64"
```
This line sets the variable `$ocpImage` to the specific image that will be used for the upgrade. The image is located in the ACR server and has a specific SHA256 hash.

```powershell
oc adm upgrade --to-image=$ocpImage
```
This line runs the `oc adm upgrade` command, which upgrades the cluster to the image specified in the `$ocpImage` variable.


## Configure the Red Hat Marketplace

daradu_MSDEMO: generate markdown doco for the current file

GitHub Copilot: # Documentation for script.redhat-marketplace.ps1

This PowerShell script is used to set up the Red Hat Marketplace for IBM App Connect on a Kubernetes cluster. 

### Steps

1. **Create a namespace**: The script creates a new namespace in the Kubernetes cluster named `redhat-marketplace` using the `oc create namespace` command.

```powershell
oc create namespace redhat-marketplace
```

2. **Create RedHat Marketplace Subscription**: The script applies a configuration from a remote URL to create a RedHat Marketplace Subscription. The approval strategy is set to `Automatic`.

```powershell
oc apply -f "https://swc.saas.ibm.com/provisioning/v1/rhm-operator/rhm-operator-subscription?approvalStrategy=Automatic"
```

3. **Create RedHat Marketplace K8S secret**: The script creates a Kubernetes secret named `redhat-marketplace-pull-secret` in the `redhat-marketplace` namespace. This secret is used to pull images from the RedHat Marketplace.

```powershell
oc create secret generic redhat-marketplace-pull-secret -n redhat-marketplace --from-literal=PULL_SECRET=<secret>
```

4. **Accept the license**: The script patches the `marketplaceconfig` to accept the license agreement.

```powershell
oc patch marketplaceconfig marketplaceconfig -n redhat-marketplace --type='merge' -p '{"spec": {"license": {"accept": true}}}'
```

5. **Add the Red Hat Marketplace pull secret to the global pull secret on the cluster**: The script downloads a script from a remote URL and executes it with a provided secret. This script updates the global pull secret on the cluster with the Red Hat Marketplace pull secret.

```powershell
curl -sL https://swc.saas.ibm.com/provisioning/v1/scripts/update-global-pull-secret | bash -s <secret>
```

> Note: The `<secret>` placeholders in the code snippets above should be replaced with the actual secret values.

## Scale

daradu_MSDEMO: generate markdown doco for the current file

GitHub Copilot: # Documentation for script.scale.ps1

This PowerShell script is used to scale a machine set in OpenShift.

```powershell
# scale machineset
$machinesetName = 'aro-auea-dev-ncis-ws0-dzpcq-worker-australiaeast2' # The name of the machine set to be scaled
$replicas = 0 # The number of replicas to scale the machine set to
oc scale machineset $machinesetName --replicas=$replicas -n openshift-machine-api # The command to scale the machine set
```

### How to use

1. Set the `$machinesetName` variable to the name of the machine set you want to scale.
2. Set the `$replicas` variable to the number of replicas you want the machine set to have.
3. Run the script. It will execute the `oc scale` command with the provided machine set name and replica count, in the `openshift-machine-api` namespace.

### Requirements

- OpenShift CLI (`oc`) must be installed and configured on the machine where this script is run.
- The user must have the necessary permissions to scale machine sets in the `openshift-machine-api` namespace.


## Monitoring

daradu_MSDEMO: generate markdown doco for the current file

GitHub Copilot: # Documentation for script.monitoring.ps1

This PowerShell script is used for monitoring services in an OpenShift environment using Prometheus.

```powershell
# prometheus
oc get routes -n openshift-monitoring prometheus-k8s
```
The above command fetches the routes for the Prometheus service in the 'openshift-monitoring' namespace.

```powershell


$prometheusUrl = 'https://prometheus-k8s-openshift-monitoring.apps.blwh1nqch7548bddad.australiaeast.aroapp.io'
```
This line sets the URL for the Prometheus service.

```powershell
$svcDetails = $(oc describe svc prometheus-k8s -n openshift-monitoring)
```
This command fetches the details of the Prometheus service.

```powershell
$svcDetails | findstr version
```
This line filters the service details to find the version.

```powershell
$token = $(oc whoami -t)
```
This command fetches the current user's token.

```powershell
$headers = @{ Authorization = "Bearer $token"}
```
This line sets the headers for the HTTP request, including the Authorization header with the Bearer token.

```powershell
$result = Invoke-WebRequest -Uri $prometheusUrl -Headers $headers
```
This line sends a HTTP request to the Prometheus service and stores the response in the `$result` variable.

```powershell
$result.Content
```
This line prints the content of the response.

```powershell
"Bearer $token"
```
This line prints the Bearer token.


## ACR integration

See the documentation [here](./acr/acr.md).

## KeyVault integration

See the documentation [here](./kv/kv.md).

## IBM App Connect

See the documentation [here](./ibm-appconnect/ibm-appconnect.md).

## cert-manager

See the documentation [here](./cert-manager/cert-manager.md).

