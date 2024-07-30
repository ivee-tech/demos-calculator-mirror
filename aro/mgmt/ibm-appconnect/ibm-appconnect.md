# IBM App Connect

This PowerShell script is used to set up IBM's App Connect on a local machine. It involves several steps including logging into Azure Container Registry (ACR), creating a new project in OpenShift, checking available operators, setting up variables for mirroring icr.io, getting IBM PAK, and generating mirror manifests.

## Code Explanation

```powershell
# App Connect (IBM)
$acrName = 'acraueadevncisws01'
$source = "icr.io/cpopen/appconnect-operator@sha256:9a6d6aa93de33d99e66ecfc1f71fb76aa24b0904fbc479ce82c49e49d542f920"
$image = "cpopen/appconnect-operator:11.5.1-20240510-151448"
```
The above lines set up the variables for the Azure Container Registry name, the source image, and the image name.

```powershell
az acr import -n $acrName --source $source --image $image
```
This line imports the image from the source to the Azure Container Registry.

```powershell
$ns = 'ibm-ace-dev'
oc new-project $ns
```
These lines create a new project in OpenShift.

```powershell
oc get packagemanifests -n openshift-marketplace
oc describe packagemanifests ibm-appconnect -n openshift-marketplace
```
These lines retrieve and describe the package manifests from the OpenShift marketplace.

```powershell
$CASE_NAME='ibm-appconnect'
$CASE_VERSION='11.5.1'
$ARCH='amd64'
```
These lines set up the variables for the case name, case version, and architecture.

```powershell
oc ibm-pak get ${CASE_NAME} --version ${CASE_VERSION}
oc ibm-pak generate mirror-manifests ${CASE_NAME} icr.io --version ${CASE_VERSION}
```
These lines get the IBM PAK and generate the mirror manifests.

```powershell
docker login -u $acrName -p $acrPassword $acrName.azurecr.io
az acr login -n $acrName
```
These lines log into the Docker and Azure Container Registry.

```powershell
$REGISTRY_AUTH_FILE='C:\Users\daradu\.docker\config.json'
```
This line sets the path for the Docker registry authentication file.

## Prerequisites

- Azure CLI
- Docker
- OpenShift CLI
- IBM PAK

## Usage

Run this script in a PowerShell terminal. Make sure to replace the placeholders with your actual values.