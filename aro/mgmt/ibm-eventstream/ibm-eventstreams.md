The script `script.eventstream.ps1` is used to set up an IBM Event Streams instance in an air-gapped environment using the IBM Cloud Pak CLI (`oc ibm-pak`).

## Steps

1. **Set environment variables**: The script sets several environment variables that are used throughout the script. These include the name and version of the Cloud Pak for Automation (CP4A) case package (`ibm-eventstreams` and `3.3.2`), the offline directory, the case repository path, and the case archive path.

2. **Configure locale** (optional): The script sets the locale for the IBM Cloud Pak CLI to `en_US`.

3. **Configure IBM Cloud Pak CLI**: The script configures the IBM Cloud Pak CLI to download CASE as OCI artifacts from the IBM Cloud-Pak OCI registry.

4. **Download the CASE**: The script downloads the CASE for the specified case name and version.

5. **Generate mirror manifests**: The script generates mirror manifests for the specified case name and target registry.

6. **Check the images to be mirrored**: The script lists the images to be mirrored for the specified case name and version.

7. **Mirror images**: The script mirrors the images listed in the mirror manifests to the target registry. It uses a specified registry authentication file for authentication.

8. **Apply Catalog Source and Image Content Source Policy**: The script applies the Catalog Source and Image Content Source Policy configurations using the `oc apply` command.

9. **Check Catalog Source and Image Content Source Policy**: The script checks the status of the Catalog Source and Image Content Source Policy using the `oc get` command.

10. **Apply IBM Event Stream configurations**: The script applies the IBM Event Stream namespace, operator group, and subscription configurations using the `oc apply` command.

## Prerequisites

- You need to have the IBM Cloud Pak CLI (`oc ibm-pak`) installed and configured.
- You need to have access to an OpenShift cluster and the necessary permissions to create and manage resources.
- You need to have a registry authentication file for the target registry.

## Usage

Run the script in a PowerShell terminal:

```powershell
./script.eventstream.ps1
```
