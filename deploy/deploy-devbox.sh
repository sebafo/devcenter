# Deployment
BASE_PREFIX=<set your prefix>
DEPLOYMENT_NAME=$BASE_PREFIX-deployment-$(date +%s)

## Start deployment
az deployment sub create --name $DEPLOYMENT_NAME --template-file main.bicep --parameters parameters-devbox.json --parameter basePrefix=$BASE_PREFIX