# Azure Infrastructure Setup

This script automates the setup of various Azure resources using Terraform.

The infrastructure deployment script can be found here
`infra\aks-private-cluster-tf\script.ps1`. The script is used to automate the creation and configuration of various Azure resources using Terraform. It sets up a storage account for Terraform state, creates Azure AD groups, and initializes, plans, and applies Terraform configurations for different components like network hubs, network spokes, AKS supporting infrastructure, and AKS clusters.

## Steps

1. **State Storage Setup**

    The script begins by setting up a storage account in Azure to store the Terraform state. This is done in the `02-state-storage` section.

    ```powershell
    $REGION='AustraliaEast'
    $STORAGEACCOUNTNAME='stgauaeadevtfstate'
    $CONTAINERNAME='akscs'
    $TFSTATE_RG='rg-auea-dev-tfstate'
    $tf = "C:\tools\terraform\terraform.exe"
    az group create --name $TFSTATE_RG --location $REGION
    az storage account create -n $STORAGEACCOUNTNAME -g $TFSTATE_RG -l $REGION --sku Standard_LRS 
    az storage container-rm create --storage-account $STORAGEACCOUNTNAME --name $CONTAINERNAME
    Set-Alias -Name tf -Value $tf
    ```

2. **Enterprise ID Creation**

    The script then moves to the `03-EID-create` directory and initializes, plans, and applies the Terraform configuration.

    ```powershell
    cd .\03-EID-create
    tf init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME" -reconfigure
    tf plan
    tf apply
    cd ..
    ```

3. **Network Hub Creation**

    The script then moves to the `04-Network-Hub` directory and initializes, plans, and applies the Terraform configuration.

    ```powershell
    cd .\04-Network-Hub
    tf init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
    tf plan
    tf apply -var admin_password="***"
    cd ..
    ```

4. **Network Spoke Creation**

    The script then moves to the `05-Network-LZ` directory and initializes, plans, and applies the Terraform configuration.

    ```powershell
    cd ./05-Network-LZ
    tf init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
    tf plan
    tf apply
    cd..
    ```

5. **AKS Supporting Infrastructure Creation**

    The script then moves to the `06-AKS-supporting` directory and initializes, plans, and applies the Terraform configuration.

    ```powershell
    cd ./06-AKS-supporting
    tf init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
    tf plan
    tf apply
    cd ..
    ```

6. **AKS Cluster Creation**

    Finally, the script moves to the `07-AKS-Cluster` directory and initializes, plans, and applies the Terraform configuration.

    ```powershell
    cd ./07-AKS-Cluster
    tf init -backend-config="resource_group_name=$TFSTATE_RG" -backend-config="storage_account_name=$STORAGEACCOUNTNAME" -backend-config="container_name=$CONTAINERNAME"
    tf plan
    tf apply
    cd ..
    ```

## Error Handling

The script includes commented-out error messages for creating Azure AD groups. These errors indicate that the script attempted to create groups that already exist. If you encounter these errors, you may need to delete the existing groups or use different names.

```powershell
<#
╷
│ Error: Creating group "AKS App Admin Team 01357"
│
│   with azuread_group.appdevs,
│   on ad_groups.tf line 5, in resource "azuread_group" "appdevs":
│    5: resource "azuread_group" "appdevs" {
│
│ GroupsClient.BaseClient.Post(): unexpected status 400 with OData error: Request_BadRequest: Request contains a property with duplicate values.
╵
╷
│ Error: Creating group "AKS App Dev Team 01357"
│
│   with azuread_group.aksops,
│   on ad_groups.tf line 10, in resource "azuread_group" "aksops":
│   10: resource "azuread_group" "aksops" {


│


│ GroupsClient.BaseClient.Post(): unexpected status 400 with OData error: Request_BadRequest: Request contains a property with duplicate values.
╵
#>
```

# Pre-requisites:

The infrastructure deploys a jumpbox VM which can be used for cluster management, including deploying and testing the API and UI containers. The jumpbox VM is configured with a managed identity that has the necessary permissions to access the resources in the spoke network. The following steps are required to set up the jumpbox VM and configure access to the resources in the spoke network:

## Configure access: 
  - Enable Managed Identity (MI) on the jumpbox VM:
    ```bash
    az vm identity assign --name <vm-name> --resource-group <resource-group-name>
    ```
  - Add role assignment(s):
    - Contributor permissions to the MI on the resource group `escs-lz01-SPOKE`:
      ```bash
      az role assignment create --assignee <principal-id> --role Contributor --scope /subscriptions/<subscription-id>/resourceGroups/escs-lz01-SPOKE
      ```
    - Azure Kubernetes Service RBAC Cluster Admin role assignment on AKS:
      ```bash
      az aks create --name <aks-name> --resource-group <resource-group-name> --generate-ssh-keys --attach-acr <acr-name>
      ```
    - AcrPush to the container registry:
      ```bash
      az acr role assignment create --registry <acr-name> --role AcrPush --assignee <principal-id>
      ```
    - Key Vault Secrets Officer on the private Key Vault instance (or access policy to manage secrets):
      ```bash
      az keyvault set-policy --name <keyvault-name> --object-id <principal-id> --secret-permissions get list set delete backup restore recover
      ```
## Install Azure DevOps agent

Follow the instructions from Azure DevOps portal.
Alternatively, the steps belowuse Azure CLI examples for Azure DevOps (ADO) agent installation and configuration:

1. Download the agent package:

```bash
AZP_AGENTPACKAGE_URL=$(curl -sS https://vstsagentpackage.azureedge.net/agent/${AZP_AGENT_VERSION}/vsts-agent-linux-x64-${AZP_AGENT_VERSION}.tar.gz)
curl -O $AZP_AGENTPACKAGE_URL
```

2. Extract the agent package:

```bash
tar zxvf vsts-agent-linux-x64-${AZP_AGENT_VERSION}.tar.gz
```

3. Configure the agent:

```bash
./config.sh --url https://dev.azure.com/${AZP_ORGANIZATION} --auth pat --token ${AZP_TOKEN} --pool ${AZP_POOL} --agent ${AZP_AGENT_NAME} --replace --acceptTeeEula
```

Replace the placeholders with your actual values:
- `${AZP_AGENT_VERSION}`: The version of the Azure DevOps agent.
- `${AZP_ORGANIZATION}`: The name of your Azure DevOps organization.
- `${AZP_TOKEN}`: The Personal Access Token (PAT) with Agent Pools - Read & manage scope.
- `${AZP_POOL}`: The name of your Azure DevOps agent pool.
- `${AZP_AGENT_NAME}`: The name of your Azure DevOps agent.

4. Run the agent:

```bash
./run.sh
```

## Install Docker on the Jumpbox VM

Here are the detailed steps for installing Docker on an Ubuntu-based jumpbox VM:

Follow the instructions below to install Docker on an Ubuntu-based jumpbox VM:

1. Update your existing list of packages:

```bash
sudo apt-get update
```

2. Install a few prerequisite packages which let `apt` use packages over HTTPS:

```bash
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
```

3. Add the GPG key for the official Docker repository to your system:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

4. Add the Docker repository to APT sources:

```bash
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
```

5. Update the package database with the Docker packages from the newly added repo:

```bash
sudo apt-get update
```

6. Make sure you are about to install from the Docker repo instead of the default Ubuntu repo:

```bash
apt-cache policy docker-ce
```

7. Install Docker:

```bash
sudo apt-get install -y docker-ce
```

8. Docker should now be installed, the daemon started, and the process enabled to start on boot. Check that it's running:

```bash
sudo systemctl status docker
```

For more detailed instructions, refer to the official Docker documentation: [https://docs.docker.com/engine/install/ubuntu/](https://docs.docker.com/engine/install/ubuntu/)


## Install additional tools on the jumpbox VM:

- install az CLI
``` bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt

- install kubectl using the package manager
``` bash
# download
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# validate (optional)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
# it should display kubectl: OK
# install
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

OR

- install kubectl using az CLI (installs `kubelogin` as well)
``` bash
# requires sudo
sudo -i
# then
az aks install-cli
```
https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

- merge cluster config
``` bash
rg=escs-lz01-SPOKE
aksName=aks-akscs-blue
az aks get-credentials -g $rg -n $aksName
```

- login using MI
``` bash
export KUBECONFIG=~/.kube/config

kubelogin convert-kubeconfig -l msi

kubectl get nodes

```
https://azure.github.io/kubelogin/concepts/login-modes/msi.html

- install helm

``` bash
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

# Add a user node pool

In Azure, a node pool is a group of nodes with the same configuration. The AKS cluster initially comes with a system node pool, and you can add additional user node pools. 
Add a user node pool to your AKS cluster using the command `az aks nodepool add`. 
Here's an example:

``` PowerShell
az aks nodepool add `
    --resource-group myResourceGroup `
    --cluster-name myAKSCluster `
    --name mynodepool `
    --node-count 3 `
    --kubernetes-version 1.20.5 `
    --node-vm-size Standard_DS2_v2
```

In this example, a new node pool named 'mynodepool' is added to the 'myAKSCluster' AKS cluster. The node pool has 3 nodes, each running Kubernetes version 1.20.5 and using the 'Standard_DS2_v2' VM size.

Please replace "myResourceGroup", "myAKSCluster", "mynodepool", and other parameters with your actual values.

# Enable workload identity and configure KeyVault access

``` bash
$repo = 'daradu'
$tag = '0.0.1'
$ns = 'calculator'

$tenantId = '***' # change to your own tenant ID
$subscriptionId = '***' # change to your own subscription ID
$kvWorkloadId = '***' # Workload Managed Identity ID (ApplicationID) for Azure Key Vault
$rg = 'k8s-tech-brief-rg'
$location = 'AustraliaEast'
$kvName = 'ktb-kv2'
$aksName = 'ktb-aks'
$saName = 'calculator-sa'

# get KV url
$kvUrl = "$(az keyvault show -g $rg -n $kvName --query properties.vaultUri -o tsv)"
$kvUrl

# run config workload identity script
# $kvWorkloadIdName = 'ktb-aks-user-id'
..\..\scripts\cfg-kv-workload-identity.ps1 -subscriptionId $subscriptionId -location $location -rg $rg -aksName $aksName -kvName $kvName -ns $ns -saName $saName

```

The PowerShell script `k8s\mgmt\cfg-kv-workload-identity.ps1` is used to configure the workload identity for an Azure Kubernetes Service (AKS) cluster. Here's a step-by-step explanation of what the script does:

1. It accepts several parameters, including the subscription ID, location, resource group, AKS name, Key Vault name, Kubernetes namespace, and service account name. These parameters are all mandatory.

2. It sets the OpenID Connect (OIDC) issuer URL by querying the AKS service for the issuer URL associated with the provided AKS name and resource group.

3. It creates a Managed Identity (MI) with a name derived from the AKS name and assigns it to the specified resource group and location.

4. It creates an access policy in Azure Key Vault, which allows the newly created Managed Identity to get secrets. The Managed Identity's client ID is used as the service principal name (SPN) for this policy.

5. It establishes a Federated Identity by creating a federated credential. This links the Managed Identity to a Kubernetes service account in the specified namespace. The issuer for this federated credential is the OIDC issuer URL obtained earlier.


# Deploy SecretProviderClass resource

The following PowerShell script is used to configure a Kubernetes SecretProviderClass object using a YAML file named `calculator-spc.yaml`. 
This is an once-off configuration and it doesn't require automation.

``` PowerShell

$tenantId = '***' # change to your own tenant ID
$kvWorkloadId = '***' # Workload Managed Identity ID (ApplicationID) for Azure Key Vault
$kvName = 'ktb-kv2'

# SecretProviderClass
$c = $(Get-Content .\calculator-spc.yaml)
$c = $c.Replace("{{ .Values.workloadIdentityId }}", $kvWorkloadId)
$c = $c.Replace("{{ .Values.tenantId }}", $tenantId)
$c = $c.Replace("{{ .Values.kvName }}", $kvName)
$c | kubectl apply -n $ns -f -

```

Here's a step-by-step explanation:

1. The `Get-Content .\calculator-spc.yaml` command reads the content of the `calculator-spc.yaml` file and stores it in the variable `$c`.
2. The next three lines use the `Replace` method to substitute placeholders in the YAML file with actual values. The placeholders are `{{ .Values.workloadIdentityId }}`, `{{ .Values.tenantId }}`, and `{{ .Values.kvName }}`, and they are replaced with the values of the variables `$kvWorkloadId`, `$tenantId`, and `$kvName` respectively.
3. The final line pipes the modified content of `$c` to the `kubectl apply` command, which applies the configuration to the Kubernetes namespace specified by the `$ns` variable.

The `k8s\manifests\calculator-spc.yaml` file is a Kubernetes SecretProviderClass configuration file. It's used to specify how Kubernetes should fetch secrets from a specified backend (like Azure Key Vault, HashiCorp Vault, etc.). The exact content of this file can vary based on the backend and the specific secrets required, but it generally contains the backend type, the parameters for connecting to the backend, and the secrets to fetch. The placeholders in the file are replaced with actual values before applying the configuration to Kubernetes.

Here's an explanation of `parameters` and `secretObjects` key parts:

- `parameters`: These are specific to the Azure Key Vault provider. They include:
  - `usePodIdentity` and `useVMManagedIdentity`: These are set to "false", meaning the Azure Key Vault is not using Azure's Managed Identity feature for authentication.
  - `clientID`: This is the ID of the Azure AD application that has access to the Azure Key Vault.
  - `keyvaultName`: This is the name of the Azure Key Vault.
  - `objects`: This is an array of objects in the Azure Key Vault that the Secrets Store CSI driver should make available to the pod. Each object has a `objectName`, `objectType`, and `objectVersion`.

- `secretObjects`: This is an optional array of Kubernetes Secret objects that the Secrets Store CSI driver should create and keep in sync with the specified Azure Key Vault objects. Each Secret object has a `data` array that maps keys to Azure Key Vault object names, a `secretName`, and a `type`.



# API container image deployment

.pipelines\deployments\push-image-api.yml

This YAML file defines an Azure DevOps pipeline for building and pushing a Docker image to an Azure Container Registry (ACR). Here's a breakdown of its components:

- `parameters`: Defines a parameter `tag` of type `string` that can be passed to the pipeline.

- `trigger`: Specifies that the pipeline will not be triggered automatically.

- `stages`: Contains a single stage `Build_Web_Api_Image` which includes:

  - `variables`: Defines several variables used in the pipeline, including the ACR name (`acrName`), the type of the application (`type`), build arguments (`args`), the Dockerfile path (`dockerfilePath`), the tag for the Docker image (`tag`), the registry URL (`registry`), and the namespace (`rns`).

  - `jobs`: Contains a single job `Build_Push_ACR_Image` which includes:

    - `pool`: Specifies the agent pool `Demos` that will run the job.

    - `steps`: Contains a single step that executes a script. The script logs into Azure (`az login --identity`), logs into the ACR (`sudo az acr login --name $ACRNAME`), changes the directory to the pipeline workspace (`cd $(Pipeline.Workspace)/s/$TYPE`), builds the Docker image (`sudo docker build -t $img $ARGS -f $DOCKERFILEPATH .`), tags the Docker image (`sudo docker tag ${img} $REGISTRY/$RNS/$img`), and pushes the Docker image to the ACR (`sudo docker push $REGISTRY/$RNS/$img`).

Alternatively, you can use the Azure CLI to manually build and push the Docker image to the ACR. Here's an example command:
(see script )
``` PowerShell
# from api sol folder
# build image
$tag='0.0.1'
docker build -t calculator-api:$($tag) --build-arg USE_ENV_VAR=true --build-arg CALL_TYPE=Direct -f .\Calculator.Web.Api\Dockerfile .

# run container (assumes an Azure SQL DB is available)
$remoteUser = 'sqlusr001'
$remotePassword = '***'
$remoteSvr = 'demos-auea-dev-sql-calc'
$remoteDb = 'demos-auea-dev-db-calc'
$connectionString = "Server=tcp:$remoteSvr.database.windows.net,1433;Initial Catalog=$remoteDb;Persist Security Info=False;User ID=$remoteUser;Password='$remotePassword';MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
docker run --name calc-api -p 8080:80 -d -e "CALC_DB_CONNECTIONSTRING=$($connectionString)" calculator-api:$($tag)
# get logs
docker logs calc-api -f
# delete container
docker rm calc-api -f

```

Test the API by sending a request to the endpoint `http://localhost:8080/api/OPeration/execute`:

``` PowerShell
$expression = "1+2"
$baseUrl = 'http://localhost:8080' # container
$url = "$($baseUrl)/api/Operation/execute"
$data = @{ expression = $expression }
$contentType = 'application/json'
$method = 'POST'
$body = $data | ConvertTo-Json
$result = Invoke-WebRequest -Uri $url -Body $body -Method $method -ContentType $contentType
$result.Content

```

To push the Docker image to an external registry, such as Docker Hub or an Azure Container Registry (ACR), you can use the following script:

``` PowerShell
# push to external registry
$tag='0.0.1'
$image='calculator-api'
# docker hub
$registry='docker.io'
$rns='daradu' # namespace
# acr
$registry='acr85618.azurecr.io'
$rns='calculator' # namespace

$img="${image}:${tag}"
docker tag ${img} ${registry}/${rns}/${img}
# requires docker login
az acr login --name $registry
docker push ${registry}/${rns}/${img}

```

# UI container image deployment

.pipelines\deployments\push-image-ui.yml
This YAML file defines an Azure DevOps pipeline for building and pushing a Docker image to an Azure Container Registry (ACR).

Here's a breakdown of the key sections:

- `parameters`: Defines a parameter `tag` of type `string` that can be passed to the pipeline when it's run.

- `trigger`: The pipeline is not triggered automatically (`none`).

- `stages`: The pipeline consists of a single stage, `Build_Ui_Image`.

  - `variables`: Defines several variables used in the pipeline, including the ACR name (`acrName`), the type of image (`type`), build arguments (`args`), the Dockerfile path (`dockerfilePath`), the image tag (`tag`), the registry URL (`registry`), and the namespace (`rns`).

  - `jobs`: Defines a single job, `Build_Push_ACR_Image`, which runs on a pool named `Demos`.

    - `steps`: Defines a single script step that builds and pushes the Docker image. The script logs into Azure with managed identity, logs into the ACR, changes directory to the workspace, builds the Docker image, tags it, and pushes it to the ACR.

Alternatively, you can manually build and push the Docker image to the ACR using the Azure CLI. Here's an example command:

``` PowerShell
# from the ui folder
$tag = '0.0.1'
docker rm calc-ui -f
cat Dockerfile
docker build -t calculator-ui:$($tag) .

docker run -d -p 8081:80 --name calc-ui calculator-ui:$($tag)
# open the browser http://localhost:8081
# get logs
docker logs calc-ui -f
docker rm calc-ui -f
docker rmi calculator-ui:$($tag) -f

```

To push the Docker image to an external registry, such as Docker Hub or an Azure Container Registry (ACR), you can use the following script:

``` PowerShell
# push to docker hub
$tag = '0.0.1'
$image='calculator-ui'
# docker hub
$registry='docker.io'
$rns='daradu' # namespace
# acr
$registry='acr85618.azurecr.io'
$rns='calculator' # namespace

$img="${image}:${tag}"
docker tag ${img} ${registry}/${rns}/${img}
# requires docker login
docker push ${registry}/${rns}/${img}

```
# Application manifests deployment

The `.pipelines\deployments\deploy-k8s.yml` YAML file is a configuration for a CI/CD pipeline, specifically for deploying the `calculator` Kubernetes application. Here's a breakdown of what each section does:

- `trigger: none`: This line specifies that the pipeline will not be triggered automatically by a push or a pull request.

- `stages`: This section contains all the stages that the pipeline will go through. In this case, there's only one stage: `Build_Ui_Image`.

- `variables`: This section defines variables that can be used in the pipeline. Here, a variable `ns` (short for namespace) is defined with the value `calculator`.

- `jobs`: This section contains all the jobs that will be executed in the current stage. Here, there's only one job: `Deploy_Manifests`.

- `pool`: This section specifies the agent pool that will run the job. In this case, the pool is named `Demos`.

- `steps`: This section contains all the steps that will be executed in the current job. Here, there's only one step, which is a script.

- `script`: This section contains the commands that will be executed in the current step. Here, the script changes the current directory to the Kubernetes manifests directory in the pipeline workspace, then applies several Kubernetes manifests using `kubectl apply`.

- `displayName`: This is a human-readable name for the step, which will be displayed in the pipeline's logs and reports. Here, the step is named 'Deploy manifests'.