# upgrade cluster
$acrName = 'acraueadevncisws01'
$acrServer = "$($acrName).azurecr.io"
$ocpImage = "$($acrServer)/openshift-release-dev/ocp-release@sha256:86ee723d4dc2a83f836232d1d03f8b4193940c50a2636ee86924acb5d14b0b64"
oc adm upgrade --to-image=$ocpImage
