# Deployment
BASE_PREFIX=<DEFINE-A-PREFIX-FOR-ALL-RESOURCES>
LOCATION=westeurope

## Set GitHub PAT
### Add your GitHub PAT
### If stored in a KeyVault, use the following command to retrieve it
### GITHUB_PAT=$(az keyvault secret show --vault-name $KEYVAULT_NAME--name $SECRET_NAME --query value -o tsv)
GITHUB_PAT=''

## Start deployment
az deployment sub create --template-file main.bicep --parameters parameters-ade.json --parameter gitHubPat=$GITHUB_PAT basePrefix=$BASE_PREFIX