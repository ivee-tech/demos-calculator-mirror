rg='demos-auea-dev-rg-calc'
fileName='./main.bicep'
# sql
dbServerName='demos-auea-dev-sql-calc'
dbName='demos-auea-dev-db-calc'
sqlAdministratorLogin='sqlusr001'
sqlAdministratorLoginPassword='***'
# web Api
planNameApi='demos-auea-dev-apiplan-calc'
appNameApi='demos-auea-dev-api-calc'
skuNameApi='B1'
skuCapacityApi=1
# web UI
planNameUI='demos-auea-dev-uiplan-calc'
appNameUI='demos-auea-dev-ui-calc'
skuNameUI='B1'
skuCapacityUI=1
parameters="dbServerName=$dbServerName dbName=$dbName sqlAdministratorLogin=$sqlAdministratorLogin planNameApi=$planNameApi appNameApi=$appNameApi skuNameApi=$skuNameApi skuCapacityApi=$skuCapacityApi planNameUI=$planNameUI appNameUI=$appNameUI skuNameUI=$skuNameUI skuCapacityUI=$skuCapacityUI sqlAdministratorLoginPassword='$sqlAdministratorLoginPassword'"
echo $parameters
az deployment group create --resource-group $rg --template-file $fileName --parameters $parameters

