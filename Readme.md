# DISCLAIMER

<mark>PROJECT IS STILL UNDER CONSTRUCTION!<mark>

<mark>DevBox and Azure Deployment Environment (ADE) are currently in preview. This project is not intended for production use.</mark>

# Azure Dev Center

## Prerequisites
* Azure Subscription
* Owner or contributer rights for subscription

## Microsoft DevBox

### Documention
https://learn.microsoft.com/en-us/azure/dev-box/overview-what-is-microsoft-dev-box

### Deployment with Bicep
1) Infrastructure code is located in /deploy
2) Provide the relevant parameters in a parameters file (e.g. parameters-devbox.json) - Make sure to set **deployDevBox** to **true**
3) Deploy the DevBox infrastructure with the following command:

```
az deployment sub create --template-file main.bicep --parameters parameters-devbox.json
```
4) Alternatively you can use the deploy-devbox.sh file to deploy the infrastructure

Optional: You can deploy DevBox AND ADE infrastructure when you set **deployAde** to **true** and **deployDevBox** to **true**

## Azure Deployment Environments

### Documention
https://learn.microsoft.com/en-us/azure/deployment-environments/

### Deployment with Bicep
1) Infrastructure code is located in /deploy
2) Provide the relevant parameters in a parameters file (e.g. parameters-ade.json) - Make sure to set **deployAde** to **true**
3) Deploy the ADE infrastructure with the following command:

```
az deployment sub create --template-file main.bicep --parameters parameters-ade.json
```
4) Alternatively you can use the deploy-ade.sh file to deploy the infrastructure

Optional: You can deploy DevBox AND ADE infrastructure when you set **deployAde** to **true** and **deployDevBox** to **true**

### Catalog Items
Example catalog items are located in /ade-catalog.

Currently only ARM templates are supported. When developing with Bicep you have to build the ARM template first.

```
az bicep build --file main.bicep --outfile azuredeploy.json
```

### Deployment Environment User URL
https://devportal.microsoft.com

## Check

TODO