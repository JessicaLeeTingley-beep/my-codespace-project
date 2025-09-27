#!/bin/bash

# Test script for Azure App Registration and Microsoft Graph integration
# This script validates that the Azure setup is working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${GREEN}[TEST]${NC} $1"
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

# Check if .env file exists
check_env_file() {
    print_step "Checking for environment variables..."
    
    if [[ -f ".env" ]]; then
        print_info "Found .env file, loading variables..."
        set -a  # Export all variables
        source .env
        set +a  # Stop exporting
    elif [[ -f ".env.template" ]]; then
        print_warning ".env.template found but no .env file"
        print_info "Please copy .env.template to .env and fill in your values"
        return 1
    else
        print_warning "No environment file found"
    fi
    
    # Check required variables
    local missing_vars=()
    
    if [[ -z "$MICROSOFT_CLIENT_ID" ]]; then
        missing_vars+=("MICROSOFT_CLIENT_ID")
    fi
    
    if [[ -z "$MICROSOFT_CLIENT_SECRET" ]]; then
        missing_vars+=("MICROSOFT_CLIENT_SECRET")
    fi
    
    if [[ -z "$MICROSOFT_TENANT_ID" ]]; then
        print_warning "MICROSOFT_TENANT_ID not set, using 'common' for multi-tenant"
        export MICROSOFT_TENANT_ID="common"
    fi
    
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        print_error "Missing required environment variables: ${missing_vars[*]}"
        echo
        print_info "Please set these environment variables:"
        for var in "${missing_vars[@]}"; do
            echo "export $var='your_value_here'"
        done
        return 1
    fi
    
    print_info "✅ Environment variables are set"
    print_info "  - Client ID: ${MICROSOFT_CLIENT_ID:0:8}..."
    print_info "  - Client Secret: [HIDDEN]"
    print_info "  - Tenant ID: $MICROSOFT_TENANT_ID"
    return 0
}

# Test Azure CLI authentication (if available)
test_azure_cli() {
    print_step "Testing Azure CLI authentication..."
    
    if ! command -v az &> /dev/null; then
        print_warning "Azure CLI not installed, skipping CLI tests"
        return 0
    fi
    
    if az account show &> /dev/null; then
        local account_info
        account_info=$(az account show --query "{name: name, tenantId: tenantId}" --output table)
        print_info "✅ Azure CLI is authenticated"
        echo "$account_info"
    else
        print_warning "Azure CLI is not authenticated"
        print_info "Run 'az login' to authenticate"
    fi
}

# Test Microsoft Graph API access
test_graph_api() {
    print_step "Testing Microsoft Graph API access..."
    
    # Get access token using client credentials flow
    local tenant_id="${MICROSOFT_TENANT_ID:-common}"
    local token_url="https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token"
    
    local token_response
    token_response=$(curl -s -X POST "$token_url" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "client_id=$MICROSOFT_CLIENT_ID" \
        -d "client_secret=$MICROSOFT_CLIENT_SECRET" \
        -d "scope=https://graph.microsoft.com/.default" \
        -d "grant_type=client_credentials")
    
    if [[ $(echo "$token_response" | jq -r '.error // "null"') != "null" ]]; then
        print_error "Failed to get access token"
        echo "Error: $(echo "$token_response" | jq -r '.error_description // .error')"
        return 1
    fi
    
    local access_token
    access_token=$(echo "$token_response" | jq -r '.access_token')
    
    if [[ -z "$access_token" || "$access_token" == "null" ]]; then
        print_error "No access token received"
        return 1
    fi
    
    print_info "✅ Access token obtained successfully"
    
    # Test Graph API endpoint
    local api_response
    api_response=$(curl -s -H "Authorization: Bearer $access_token" \
        "https://graph.microsoft.com/v1.0/\$metadata")
    
    if [[ $(echo "$api_response" | head -c 5) == "<?xml" ]]; then
        print_info "✅ Microsoft Graph API is accessible"
    else
        print_error "Microsoft Graph API test failed"
        echo "Response: ${api_response:0:200}..."
        return 1
    fi
}

# Test app registration permissions
test_app_permissions() {
    print_step "Testing app registration permissions..."
    
    if ! command -v az &> /dev/null; then
        print_warning "Azure CLI not available, skipping permission check"
        return 0
    fi
    
    if ! az account show &> /dev/null; then
        print_warning "Azure CLI not authenticated, skipping permission check"
        return 0
    fi
    
    # Get app registration details
    local app_info
    app_info=$(az ad app show --id "$MICROSOFT_CLIENT_ID" --query "{displayName: displayName, signInAudience: signInAudience}" --output json 2>/dev/null)
    
    if [[ -n "$app_info" ]]; then
        print_info "✅ App registration found:"
        echo "$app_info" | jq '.'
        
        # Check API permissions
        local permissions
        permissions=$(az ad app show --id "$MICROSOFT_CLIENT_ID" --query "requiredResourceAccess[0].resourceAccess[].id" --output tsv 2>/dev/null)
        
        if [[ -n "$permissions" ]]; then
            print_info "✅ API permissions configured"
            echo "Permission IDs: $permissions"
        else
            print_warning "No API permissions found or permission check failed"
        fi
    else
        print_warning "Could not retrieve app registration details"
    fi
}

# Run all tests
run_tests() {
    echo -e "${BLUE}=== EduBuddyBridge Azure Integration Test Suite ===${NC}"
    echo
    
    local tests_passed=0
    local tests_failed=0
    
    # Test 1: Environment variables
    if check_env_file; then
        ((tests_passed++))
    else
        ((tests_failed++))
        print_error "Environment test failed - cannot continue"
        return 1
    fi
    
    echo
    
    # Test 2: Azure CLI
    test_azure_cli
    echo
    
    # Test 3: Microsoft Graph API
    if test_graph_api; then
        ((tests_passed++))
        print_info "✅ Graph API test passed"
    else
        ((tests_failed++))
        print_error "❌ Graph API test failed"
    fi
    
    echo
    
    # Test 4: App permissions
    test_app_permissions
    echo
    
    # Summary
    print_step "Test Summary:"
    print_info "Tests passed: $tests_passed"
    if [[ $tests_failed -gt 0 ]]; then
        print_error "Tests failed: $tests_failed"
    else
        print_info "Tests failed: $tests_failed"
    fi
    
    if [[ $tests_failed -eq 0 ]]; then
        echo -e "${GREEN}🎉 All critical tests passed! Your Azure integration is ready.${NC}"
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Please review the errors above.${NC}"
    fi
    
    echo
    print_info "Next steps:"
    echo "1. If tests passed, your integration is ready to use"
    echo "2. Add environment variables to your Base44 dashboard"
    echo "3. Test email sending in your application"
    echo "4. Monitor API usage and permissions in Azure Portal"
}

# Check for required tools
check_prerequisites() {
    local missing_tools=()
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo
        print_info "Please install the missing tools:"
        echo "  Ubuntu/Debian: apt-get install ${missing_tools[*]}"
        echo "  CentOS/RHEL: yum install ${missing_tools[*]}"
        echo "  macOS: brew install ${missing_tools[*]}"
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    if ! check_prerequisites; then
        exit 1
    fi
    
    run_tests
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi