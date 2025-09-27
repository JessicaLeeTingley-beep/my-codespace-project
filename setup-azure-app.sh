#!/bin/bash

# EduBuddyBridge Azure App Registration Setup Script
# This script creates an Azure App Registration for Microsoft Graph integration

set -e  # Exit on any error

echo "🚀 Setting up EduBuddyBridge Azure App Registration..."

# Configuration
APP_NAME="EduBuddyBridge"
PRODUCTION_REDIRECT_URI="https://edubuddybridge.online/api/functions/microsoftEmailIntegration"
PREVIEW_REDIRECT_URI="https://preview--edubuddybridge.base44.app/api/functions/microsoftEmailIntegration"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI not found. Installing..."
    pipx install azure-cli
    export PATH="$HOME/.local/bin:$PATH"
fi

# Login to Azure (this will open a browser)
echo "🔐 Please log in to Azure..."
az login

# Get the current subscription info
echo "📋 Current Azure subscription:"
az account show --output table

# Create the App Registration
echo "📝 Creating App Registration: $APP_NAME..."

# Create the app registration and capture the output
APP_JSON=$(az ad app create \
    --display-name "$APP_NAME" \
    --sign-in-audience "AzureADandPersonalMicrosoftAccount" \
    --web-redirect-uris "$PRODUCTION_REDIRECT_URI" "$PREVIEW_REDIRECT_URI" \
    --output json)

# Extract the Application ID
APP_ID=$(echo "$APP_JSON" | jq -r '.appId')
OBJECT_ID=$(echo "$APP_JSON" | jq -r '.id')
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "✅ App Registration created!"
echo "📋 Application ID: $APP_ID"
echo "📋 Tenant ID: $TENANT_ID"

# Create a client secret
echo "🔑 Creating client secret..."
SECRET_JSON=$(az ad app credential reset \
    --id "$APP_ID" \
    --display-name "EduBuddyBridge Secret" \
    --years 2 \
    --output json)

CLIENT_SECRET=$(echo "$SECRET_JSON" | jq -r '.password')

# Configure API permissions
echo "🔒 Configuring Microsoft Graph permissions..."

# Add Mail.Send (Application permission)
az ad app permission add \
    --id "$APP_ID" \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions b633e1c5-b582-4048-a93e-9f11b44c7e96=Role

# Add User.Read (Delegated permission) 
az ad app permission add \
    --id "$APP_ID" \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope

echo "⚡ Granting admin consent for API permissions..."
az ad app permission admin-consent --id "$APP_ID"

# Save environment variables to file
echo "💾 Saving environment variables to .env file..."
cat > .env << EOF
# EduBuddyBridge Azure App Registration Environment Variables
# Generated on $(date)

MICROSOFT_CLIENT_ID=$APP_ID
MICROSOFT_CLIENT_SECRET=$CLIENT_SECRET
MICROSOFT_TENANT_ID=$TENANT_ID

# Redirect URIs configured:
# Production: $PRODUCTION_REDIRECT_URI
# Preview: $PREVIEW_REDIRECT_URI
EOF

echo ""
echo "🎉 Azure App Registration setup complete!"
echo ""
echo "📋 Your environment variables:"
echo "MICROSOFT_CLIENT_ID=$APP_ID"
echo "MICROSOFT_CLIENT_SECRET=$CLIENT_SECRET"
echo "MICROSOFT_TENANT_ID=$TENANT_ID"
echo ""
echo "💡 These values have been saved to .env file"
echo "🔐 Add these to your Base44 dashboard secrets"
echo ""
echo "✅ Next steps:"
echo "1. Add the environment variables to your Base44 project"
echo "2. Test the integration with the provided sample code"
echo "3. Deploy your application"

echo ""
echo "🔗 App Registration URL:"
echo "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$APP_ID"