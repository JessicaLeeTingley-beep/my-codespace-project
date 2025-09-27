# EduBuddyBridge Azure App Registration Manual Setup Guide

## Overview
This guide will walk you through setting up an Azure App Registration for the EduBuddyBridge application to enable Microsoft Graph API integration for email functionality.

## Prerequisites
- Azure account with appropriate permissions
- Access to Azure Portal (portal.azure.com)
- Admin access to create app registrations in your tenant

## Step-by-Step Setup

### 1. Navigate to Azure Portal
1. Open your browser and go to [portal.azure.com](https://portal.azure.com)
2. Sign in with your Azure account
3. In the search bar, type "Azure Active Directory" and select it
4. In the left sidebar, click on "App registrations"
5. Click "New registration" button

### 2. Register Your Application
Fill in the registration form:

**Basic Information:**
- **Name**: `EduBuddyBridge`
- **Supported account types**: Select "Accounts in any organizational directory and personal Microsoft accounts (Personal Microsoft accounts - e.g. Skype, Xbox)"

**Redirect URI:**
- **Type**: Web
- **URLs to add**:
  - Production: `https://edubuddybridge.online/api/functions/microsoftEmailIntegration`
  - Preview: `https://preview--edubuddybridge.base44.app/api/functions/microsoftEmailIntegration`

Click "Register" to create the application.

### 3. Collect Required Information
After registration, you'll be redirected to the app overview page. Copy these values:

#### Application (Client) ID
- Found on the Overview page
- This becomes your `MICROSOFT_CLIENT_ID`
- Example format: `12345678-1234-1234-1234-123456789012`

#### Directory (Tenant) ID  
- Also found on the Overview page
- This becomes your `MICROSOFT_TENANT_ID`
- Example format: `87654321-4321-4321-4321-210987654321`

### 4. Create Client Secret
1. In the left sidebar, click "Certificates & secrets"
2. Click "New client secret"
3. Fill in the details:
   - **Description**: `EduBuddyBridge Secret`
   - **Expires**: Choose "24 months" (recommended)
4. Click "Add"
5. **IMPORTANT**: Copy the **Value** immediately (not the Secret ID)
   - This becomes your `MICROSOFT_CLIENT_SECRET`
   - You cannot view this value again after leaving the page
   - Example format: `abcdefghijklmnopqrstuvwxyz~1234567890ABCDEFGHIJK`

### 5. Configure API Permissions
1. In the left sidebar, click "API permissions"
2. Click "Add a permission"
3. Select "Microsoft Graph"

#### Add Application Permission (for sending emails on behalf of app):
1. Click "Application permissions"
2. Search for and select "Mail.Send"
3. Click "Add permissions"

#### Add Delegated Permission (for user authentication):
1. Click "Add a permission" again
2. Select "Microsoft Graph"
3. Click "Delegated permissions" 
4. Search for and select "User.Read"
5. Click "Add permissions"

#### Grant Admin Consent:
1. Click "Grant admin consent for [your organization]"
2. Click "Yes" to confirm
3. Verify all permissions show "Granted for [your organization]" with green checkmarks

### 6. Environment Variables Setup
Add these environment variables to your Base44 dashboard:

```bash
MICROSOFT_CLIENT_ID=your_application_client_id_here
MICROSOFT_CLIENT_SECRET=your_client_secret_value_here  
MICROSOFT_TENANT_ID=your_tenant_id_here
```

**Important Notes:**
- Replace the placeholder values with your actual values from steps 3 and 4
- The `TENANT_ID` can be set to "common" for multi-tenant scenarios (default behavior)
- Keep the `CLIENT_SECRET` secure and never commit it to version control

### 7. Verification
After setup, your app registration should have:
- ✅ Correct redirect URIs configured
- ✅ Mail.Send (Application) permission granted
- ✅ User.Read (Delegated) permission granted  
- ✅ Admin consent granted for all permissions
- ✅ Client secret created and saved
- ✅ Environment variables configured in Base44

## Testing the Setup
Use the provided test script (`test-integration.js`) to verify your configuration works correctly.

## Security Best Practices
1. **Rotate client secrets regularly** (before expiration)
2. **Use least privilege** - only request necessary permissions
3. **Monitor app registration usage** in Azure AD logs
4. **Store secrets securely** - never in source code
5. **Use managed identities** when possible in production

## Troubleshooting
See `TROUBLESHOOTING.md` for common issues and solutions.

## Additional Resources
- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/)
- [Azure App Registration Guide](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-register-app)
- [Microsoft Graph Permissions Reference](https://docs.microsoft.com/en-us/graph/permissions-reference)