$tf = "C:\tools\terraform\terraform.exe"

Set-Alias -Name tf -Value $tf

tf init -upgrade

tf plan -out main.tfplan

tf apply main.tfplan
