# cert-manager

This PowerShell script is used to manage Azure Container Registry (ACR) and OpenShift operators for `cert-manager`. It imports images into ACR, applies a ClusterServiceVersion (CSV) for cert-manager, and manages Docker images.

## Code Explanation

```powershell
# Import an image into Azure Container Registry (ACR)
az acr import -n $acrName --source $source

# Define the source image
$source = 'quay.io/jetstack/cert-manager-webhook:v1.14.2'

# Import the source image into ACR
az acr import -n $acrName --source $source

# Define the registry server
$regServer = "$acrName.azurecr.io"
$regServer
```
The above code imports an image from a source into the Azure Container Registry (ACR) defined by `$acrName`.

```powershell
# Apply the ClusterServiceVersion (CSV) for cert-manager
$ns = 'openshift-operators'
oc apply -f clusterserviceversion-cert-manager.v1.14.2.yaml -n $ns
```
This part of the script applies a ClusterServiceVersion (CSV) for cert-manager in the 'openshift-operators' namespace.

```powershell
# Pull the bundle image
docker pull <bundle-image>

# Tag and push the bundle image to your ACR
docker tag <bundle-image> <your-acr-name>.azurecr.io/<your-image-path>:<your-tag>
docker push <your-acr-name>.azurecr.io/<your-image-path>:<your-tag>

# Generate index image using opm tool
opm index add --bundles $acrName.azurecr.io/<your-image-path>:<your-tag> --tag <your-acr-name>.azurecr.io/<your-image-path>/index:<your-tag>

# Push the index image to ACR
docker push <your-acr-name>.azurecr.io/<your-image-path>/index:<your-tag>
```
The final part of the script pulls a Docker image, tags it, and pushes it to ACR. It then uses the `opm` tool to generate an index image and pushes this image to ACR.

**Note:** Replace `<bundle-image>`, `<your-acr-name>`, `<your-image-path>`, and `<your-tag>` with your specific values.