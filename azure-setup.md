# Azure App Registration Setup for EduBuddyBridge

This guide provides multiple methods to set up Azure App Registration for your EduBuddyBridge project.

## Method 1: Azure Portal (Recommended)

### Step 1: Create App Registration

1. **Navigate to Azure Portal:**
   - Go to [portal.azure.com](https://portal.azure.com)
   - Sign in with your Azure account

2. **Access App Registrations:**
   - Search for "Azure Active Directory" or find it in the left sidebar
   - Click on "App registrations"
   - Click "+ New registration"

3. **Configure Registration:**
   - **Name:** `EduBuddyBridge`
   - **Supported account types:** 
     - Select "Accounts in any organizational directory and personal Microsoft accounts (personal Microsoft accounts and Azure AD accounts)"
   - **Redirect URI:**
     - Type: `Web`
     - URLs to add:
       - Production: `https://edubuddybridge.online/api/functions/microsoftEmailIntegration`
       - Preview: `https://preview--edubuddybridge.base44.app/api/functions/microsoftEmailIntegration`

### Step 2: Collect Required Values

After registration, collect these values for your environment variables:

1. **Application (client) ID** → `MICROSOFT_CLIENT_ID`
2. **Directory (tenant) ID** → `MICROSOFT_TENANT_ID`

### Step 3: Create Client Secret

1. Go to "Certificates & secrets" in your app registration
2. Click "+ New client secret"
3. **Description:** `EduBuddyBridge Secret`
4. **Expires:** 24 months (recommended)
5. Click "Add"
6. **Copy the Value** (not the Secret ID) → `MICROSOFT_CLIENT_SECRET`

⚠️ **Important:** Copy the secret value immediately - it won't be shown again!

### Step 4: Configure API Permissions

1. Go to "API permissions" in your app registration
2. Click "+ Add a permission"
3. Select "Microsoft Graph"
4. Add these permissions:

   **Application permissions:**
   - `Mail.Send` - Send mail as any user

   **Delegated permissions:**
   - `User.Read` - Sign in and read user profile

5. Click "Grant admin consent" if you have admin privileges

### Step 5: Set Environment Variables

Add these to your Base44 dashboard or deployment environment:

```
MICROSOFT_CLIENT_ID=your_application_client_id_here
MICROSOFT_CLIENT_SECRET=your_client_secret_value_here  
MICROSOFT_TENANT_ID=your_tenant_id_here
```

## Method 2: Azure CLI (Alternative)

If you encounter authentication issues in Codespaces, try these alternatives:

### Option A: Service Principal Authentication
```bash
# Login using service principal (if you have one)
az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>
```

### Option B: Browser-based Login
```bash
# Use browser-based authentication
az login --use-device-code
```

### Option C: Use Azure Cloud Shell
1. Go to [shell.azure.com](https://shell.azure.com)
2. Run the automated setup script provided in this repository

## Method 3: PowerShell (Windows Users)

Use the PowerShell script provided in `scripts/azure-setup.ps1`

## Troubleshooting

### Error 53003 - Device Authentication Issues

This error typically occurs in GitHub Codespaces due to device registration restrictions.

**Solutions:**
1. **Use Azure Portal** (Method 1) - Most reliable
2. **Use Azure Cloud Shell** - Bypasses local authentication issues
3. **Use Service Principal** - If you have existing credentials
4. **Contact Azure Support** - For persistent device registration issues

### Common Issues:

1. **Permission denied when granting admin consent**
   - Contact your Azure administrator
   - Use personal Microsoft account if available

2. **Redirect URI mismatch**
   - Ensure URLs match exactly (including https://)
   - Add both production and preview URLs

3. **Token acquisition failures**
   - Verify client secret hasn't expired
   - Check application permissions are granted

## Next Steps

After completing the setup:

1. Test the integration using the provided test scripts
2. Deploy your application with the new environment variables
3. Monitor the application logs for any authentication issues

## Security Notes

- Never commit secrets to version control
- Rotate client secrets regularly (every 12-24 months)
- Use separate app registrations for development and production
- Monitor API usage and permissions regularly