# Script to generate a GitHub Actions secrets for a Managed Identity with Federated Credentials in Azure 

# Variables
RESOURCE_GROUP_NAME="<resource-group-name>"
LOCATION="<location>"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
IDENTITY_NAME="<identity-name>"

# Get managed identity client ID
IDENTITY_CLIENT_ID=$(az identity show --name $IDENTITY_NAME --resource-group $RESOURCE_GROUP_NAME --query clientId -o tsv)

# Create Json output with clientID, subscriptionID and tenantID for GitHub Actions
echo "{
  \"clientId\": \"$IDENTITY_CLIENT_ID\",
  \"subscriptionId\": \"$SUBSCRIPTION_ID\",
  \"tenantId\": \"$(az account show --query tenantId -o tsv)\"
}"

