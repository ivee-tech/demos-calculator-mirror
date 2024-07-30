# ACR Documentation

This document provides a detailed explanation of the `script.acr.ps1` PowerShell script. This script is primarily used for importing Docker images from various sources into an Azure Container Registry (ACR). The images are then pushed to the ACR.

## Variables

The script uses the following variables:

- `$acrName`: This variable holds the name of the Azure Container Registry.

- `$source`: This variable holds the source image that needs to be imported.

- `$image`: This variable holds the image name and tag in the `repository:tag` format.

## Commands

The script uses the following commands:

- `az acr import -n $acrName --source $source --image $image`: This command imports an image from a source registry into the Azure Container Registry.

- `docker login https://registry.redhat.io`: This command logs in to the Red Hat registry.

- `docker pull $source`: This command pulls an image from a source registry.

- `docker tag $source $destImg`: This command tags an image with a new name.

- `docker push $destImg`: This command pushes an image to a registry.

## Images Imported

The script is designed to import images from various sources. The specific images imported will depend on the values assigned to the `$source` and `$image` variables.