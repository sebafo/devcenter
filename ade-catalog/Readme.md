# Azure Deployment Environments

## Create Catalog Items
Currently only ARM templates are supported. 

If you want to create bicep-files you need to build them to ARM templates first:

```
az bicep build --file main.bicep --outfile azuredeploy.json
```

## Configure Catalog Items