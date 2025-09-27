# EduBuddyBridge Azure Integration

This repository contains Azure App Registration setup and Microsoft Graph integration for the EduBuddyBridge project.

## 🚀 Quick Start

### Method 1: Automated Setup (Recommended)

1. **Run the setup script:**
   ```bash
   ./scripts/setup-azure.sh
   ```

2. **Follow the authentication prompts** (will try multiple methods automatically)

3. **Copy the generated environment variables** to your Base44 dashboard

4. **Test the integration:**
   ```bash
   ./scripts/test-azure-integration.sh
   ```

### Method 2: Manual Azure Portal Setup

If the automated setup fails (common in Codespaces due to authentication restrictions), follow the detailed guide in [azure-setup.md](azure-setup.md).

## 📁 Project Structure

```
├── azure-setup.md              # Detailed setup guide
├── microsoft-graph-utils.js    # Graph API integration utilities
├── .env.template              # Environment variables template
├── .gitignore                 # Git ignore rules
└── scripts/
    ├── setup-azure.sh         # Automated setup script (Linux/macOS)
    ├── setup-azure.ps1        # Automated setup script (PowerShell)
    ├── test-azure-integration.sh # Integration test script
    └── test-graph-node.js      # Node.js API test script
```

## ⚙️ Configuration

### Required Environment Variables

```bash
# Your Azure App Registration credentials
MICROSOFT_CLIENT_ID=your_application_client_id_here
MICROSOFT_CLIENT_SECRET=your_client_secret_value_here
MICROSOFT_TENANT_ID=your_tenant_id_here  # or 'common' for multi-tenant
```

### Setup Steps

1. **Copy environment template:**
   ```bash
   cp .env.template .env
   ```

2. **Edit .env file** with your actual Azure credentials

3. **Add to your deployment environment** (Base44 dashboard)

## 🧪 Testing

### Shell Script Tests
```bash
# Test Azure CLI and Graph API access
./scripts/test-azure-integration.sh
```

### Node.js Tests
```bash
# Test with Node.js runtime
node scripts/test-graph-node.js

# Send a real test email (optional)
TEST_EMAIL_ADDRESS=your-email@example.com node scripts/test-graph-node.js
```

## 🔧 Usage

### Basic Graph API Client

```javascript
const { createGraphClientFromEnv } = require('./microsoft-graph-utils');

// Create client from environment variables
const client = createGraphClientFromEnv();

// Send an email
await client.sendEmail({
    subject: 'Hello from EduBuddyBridge',
    body: '<p>This is a test email</p>',
    recipients: ['user@example.com'],
    fromEmail: 'sender@example.com'
});
```

### EduBuddyBridge Integration

```javascript
const { sendEduBuddyBridgeEmail } = require('./microsoft-graph-utils');

// Send notification email
await sendEduBuddyBridgeEmail({
    subject: 'Bridge Notification',
    body: '<p>Your bridge connection is ready!</p>',
    recipients: ['student@school.edu'],
    fromEmail: 'noreply@edubuddybridge.online'
});
```

## 🔒 Security

### Best Practices

- ✅ Never commit secrets to version control
- ✅ Use separate app registrations for dev/staging/prod
- ✅ Rotate client secrets every 12-24 months
- ✅ Monitor API usage and permissions
- ✅ Use least-privilege principle for API permissions

### Required API Permissions

- **Mail.Send** (Application) - Send emails as any user
- **User.Read** (Delegated) - Read basic user profile

## 🐛 Troubleshooting

### Common Issues

#### Error 53003 - Device Authentication Failed
This is common in GitHub Codespaces. Solutions:
1. Use Azure Portal setup instead
2. Use Azure Cloud Shell
3. Set up service principal authentication

#### Invalid Client Credentials
- Verify MICROSOFT_CLIENT_ID and MICROSOFT_CLIENT_SECRET
- Check if client secret has expired
- Ensure app registration exists in correct tenant

#### Permission Denied
- Grant admin consent for API permissions
- Check if user has appropriate Azure AD roles
- Verify redirect URIs match exactly

### Debug Commands

```bash
# Check Azure CLI authentication
az account show

# Test token acquisition
curl -X POST "https://login.microsoftonline.com/common/oauth2/v2.0/token" \
  -d "client_id=$MICROSOFT_CLIENT_ID" \
  -d "client_secret=$MICROSOFT_CLIENT_SECRET" \
  -d "scope=https://graph.microsoft.com/.default" \
  -d "grant_type=client_credentials"

# Test Graph API access
# (replace TOKEN with actual access token)
curl -H "Authorization: Bearer TOKEN" \
  "https://graph.microsoft.com/v1.0/me"
```

## 📚 Resources

- [Azure App Registrations Documentation](https://docs.microsoft.com/en-us/azure/active-directory/develop/app-registrations-training-guide)
- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/)
- [Base44 Environment Variables](https://docs.base44.app/environment-variables)

## 🆘 Support

If you encounter issues:

1. **Check the troubleshooting section** above
2. **Run the test scripts** to identify the problem
3. **Review Azure Portal** for app registration status
4. **Check API permissions** and admin consent
5. **Verify environment variables** are set correctly

## 🔄 Updates

### Version History

- **v1.0** - Initial Azure App Registration setup
- **v1.1** - Added PowerShell support and enhanced error handling
- **v1.2** - Added comprehensive testing and troubleshooting

### Maintenance

- Review and rotate client secrets annually
- Monitor API usage and costs
- Update redirect URIs when deployment URLs change
- Review and update API permissions as needed