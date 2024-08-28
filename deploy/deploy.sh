# Deployment
BASE_PREFIX=<set your prefix>
DEPLOYMENT_NAME=$BASE_PREFIX-deployment-$(date +%s)
LOCATION='northeurope'

## Set GitHub PAT
### Add your GitHub PAT
### If stored in a KeyVault, use the following command to retrieve it
### GITHUB_PAT=$(az keyvault secret show --vault-name $KEYVAULT_NAME--name $SECRET_NAME --query value -o tsv)
GITHUB_PAT=''

## Start deployment
az deployment sub create --name $DEPLOYMENT_NAME --location $LOCATION --template-file main.bicep --parameters parameters.json --parameter gitHubPat=$GITHUB_PAT basePrefix=$BASE_PREFIX