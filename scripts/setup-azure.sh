#!/bin/bash

# Azure App Registration Setup Script for EduBuddyBridge
# This script provides multiple authentication methods to work around Azure CLI issues in Codespaces

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="EduBuddyBridge"
REDIRECT_URIS=(
    "https://edubuddybridge.online/api/functions/microsoftEmailIntegration"
    "https://preview--edubuddybridge.base44.app/api/functions/microsoftEmailIntegration"
)

echo -e "${BLUE}=== Azure App Registration Setup for EduBuddyBridge ===${NC}"
echo

# Function to print colored output
print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if Azure CLI is installed
check_azure_cli() {
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Installing..."
        
        # Install Azure CLI based on the system
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Install for Linux
            curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            # Install for macOS
            brew install azure-cli
        else
            print_error "Unsupported operating system. Please install Azure CLI manually."
            exit 1
        fi
    else
        print_info "Azure CLI is already installed"
        az version
    fi
}

# Function to attempt different authentication methods
authenticate_azure() {
    print_step "Attempting Azure authentication..."
    
    # Method 1: Try standard login
    print_info "Method 1: Attempting standard Azure CLI login..."
    if az login --only-show-errors > /dev/null 2>&1; then
        print_info "✅ Standard login successful"
        return 0
    fi
    
    # Method 2: Try device code flow
    print_warning "Standard login failed. Trying device code authentication..."
    print_info "Method 2: Using device code flow..."
    if az login --use-device-code; then
        print_info "✅ Device code authentication successful"
        return 0
    fi
    
    # Method 3: Try service principal (if credentials are available)
    print_warning "Device code failed. Checking for service principal credentials..."
    if [[ -n "$AZURE_CLIENT_ID" && -n "$AZURE_CLIENT_SECRET" && -n "$AZURE_TENANT_ID" ]]; then
        print_info "Method 3: Using service principal authentication..."
        if az login --service-principal \
            -u "$AZURE_CLIENT_ID" \
            -p "$AZURE_CLIENT_SECRET" \
            --tenant "$AZURE_TENANT_ID"; then
            print_info "✅ Service principal authentication successful"
            return 0
        fi
    fi
    
    # All methods failed
    print_error "All authentication methods failed."
    echo
    print_warning "Alternative options:"
    echo "1. Use Azure Portal: https://portal.azure.com"
    echo "2. Use Azure Cloud Shell: https://shell.azure.com"
    echo "3. Set up service principal credentials as environment variables:"
    echo "   export AZURE_CLIENT_ID='your-client-id'"
    echo "   export AZURE_CLIENT_SECRET='your-client-secret'"
    echo "   export AZURE_TENANT_ID='your-tenant-id'"
    echo "4. Follow the manual setup guide in azure-setup.md"
    return 1
}

# Function to create app registration
create_app_registration() {
    print_step "Creating Azure App Registration..."
    
    # Create the app registration
    local app_id
    app_id=$(az ad app create \
        --display-name "$APP_NAME" \
        --sign-in-audience "AzureADandPersonalMicrosoftAccount" \
        --query "appId" \
        --output tsv)
    
    if [[ -z "$app_id" ]]; then
        print_error "Failed to create app registration"
        return 1
    fi
    
    print_info "✅ App registration created with ID: $app_id"
    
    # Add redirect URIs
    print_step "Adding redirect URIs..."
    local redirect_uris_json=""
    for uri in "${REDIRECT_URIS[@]}"; do
        redirect_uris_json+="{\"url\":\"$uri\",\"type\":\"Web\"},"
    done
    redirect_uris_json="[${redirect_uris_json%,}]"
    
    az ad app update --id "$app_id" --web-redirect-uris "${REDIRECT_URIS[@]}"
    print_info "✅ Redirect URIs added"
    
    # Create client secret
    print_step "Creating client secret..."
    local secret_result
    secret_result=$(az ad app credential reset --id "$app_id" --append --display-name "EduBuddyBridge Secret" --years 2)
    local client_secret
    client_secret=$(echo "$secret_result" | jq -r '.password')
    
    # Get tenant ID
    local tenant_id
    tenant_id=$(az account show --query "tenantId" --output tsv)
    
    # Configure API permissions
    print_step "Configuring API permissions..."
    
    # Microsoft Graph API ID
    local graph_api_id="00000003-0000-0000-c000-000000000000"
    
    # Add Mail.Send (Application permission)
    # Permission ID for Mail.Send: b633e1c5-b582-4048-a93e-9f11b44c7e96
    az ad app permission add --id "$app_id" --api "$graph_api_id" --api-permissions "b633e1c5-b582-4048-a93e-9f11b44c7e96=Role"
    
    # Add User.Read (Delegated permission)
    # Permission ID for User.Read: e1fe6dd8-ba31-4d61-89e7-88639da4683d
    az ad app permission add --id "$app_id" --api "$graph_api_id" --api-permissions "e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope"
    
    print_info "✅ API permissions configured"
    
    # Grant admin consent (if possible)
    print_step "Attempting to grant admin consent..."
    if az ad app permission admin-consent --id "$app_id" 2>/dev/null; then
        print_info "✅ Admin consent granted"
    else
        print_warning "Could not grant admin consent automatically. You may need to grant it manually in the Azure Portal."
    fi
    
    # Output the environment variables
    print_step "Setup complete! Here are your environment variables:"
    echo
    echo "=== COPY THESE VALUES TO YOUR ENVIRONMENT ==="
    echo "MICROSOFT_CLIENT_ID=$app_id"
    echo "MICROSOFT_CLIENT_SECRET=$client_secret"
    echo "MICROSOFT_TENANT_ID=$tenant_id"
    echo "==============================================="
    echo
    
    # Save to .env file
    cat > .env.template << EOF
# Azure App Registration Environment Variables for EduBuddyBridge
# Copy these values to your deployment environment (Base44, etc.)

MICROSOFT_CLIENT_ID=$app_id
MICROSOFT_CLIENT_SECRET=$client_secret
MICROSOFT_TENANT_ID=$tenant_id

# Optional: Set to "common" for multi-tenant scenarios (default behavior)
# MICROSOFT_TENANT_ID=common
EOF
    
    print_info "✅ Environment variables saved to .env.template"
    print_warning "Remember to add these to your Base44 dashboard!"
    
    return 0
}

# Main execution
main() {
    print_step "Starting Azure App Registration setup..."
    echo
    
    # Check and install Azure CLI
    check_azure_cli
    
    # Attempt authentication
    if ! authenticate_azure; then
        print_error "Authentication failed. Please follow manual setup instructions."
        exit 1
    fi
    
    # Create app registration
    if create_app_registration; then
        print_info "🎉 Azure App Registration setup completed successfully!"
        echo
        print_info "Next steps:"
        echo "1. Copy the environment variables to your Base44 dashboard"
        echo "2. Test the integration using the provided test scripts"
        echo "3. Deploy your application"
    else
        print_error "App registration setup failed"
        exit 1
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi