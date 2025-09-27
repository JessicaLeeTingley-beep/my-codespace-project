# EduBuddyBridge Azure Integration Setup

This repository contains everything needed to set up Azure App Registration for the EduBuddyBridge application's Microsoft Graph integration.

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)
Run the automated setup script to create the Azure App Registration:

```bash
./setup-azure-app.sh
```

This script will:
- ✅ Install Azure CLI (if needed)
- ✅ Guide you through Azure login
- ✅ Create the app registration with correct settings
- ✅ Configure required permissions (Mail.Send, User.Read)  
- ✅ Generate client secret
- ✅ Save environment variables to .env file
- ✅ Grant admin consent

### Option 2: Manual Setup
If you prefer manual setup or automated script fails, follow the detailed guide:
📖 [Manual Setup Guide](AZURE_SETUP_GUIDE.md)

## 📋 What You'll Get

After setup, you'll have:

### Azure App Registration
- **Name**: EduBuddyBridge
- **Account Types**: Multi-tenant + Personal Microsoft accounts
- **Redirect URIs**: 
  - Production: `https://edubuddybridge.online/api/functions/microsoftEmailIntegration`
  - Preview: `https://preview--edubuddybridge.base44.app/api/functions/microsoftEmailIntegration`

### API Permissions
- **Mail.Send** (Application) - Send emails on behalf of the app
- **User.Read** (Delegated) - Read user profile information
- **Admin Consent** - Pre-granted for your organization

### Environment Variables
```bash
MICROSOFT_CLIENT_ID=your_application_client_id
MICROSOFT_CLIENT_SECRET=your_client_secret_value  
MICROSOFT_TENANT_ID=your_tenant_id
```

## 🧪 Testing Your Setup

### Quick Test
```bash
node test-integration.js test
```

### Step-by-Step Testing
1. **Generate auth URL**:
   ```bash
   node test-integration.js auth-url
   ```

2. **Open the URL in browser and complete login**

3. **Exchange code for token**:
   ```bash
   node test-integration.js token <authorization_code>
   ```

4. **Test API calls** (modify test-integration.js with your token)

## 🔧 Integration with Base44

### Add Environment Variables
In your Base44 dashboard, go to Environment > Secrets and add:

```
MICROSOFT_CLIENT_ID = [your_client_id]
MICROSOFT_CLIENT_SECRET = [your_client_secret]
MICROSOFT_TENANT_ID = [your_tenant_id]
```

### Sample Integration Code
```javascript
const { MicrosoftGraphTester } = require('./test-integration');

// Initialize with environment variables
const graphClient = new MicrosoftGraphTester({
    clientId: process.env.MICROSOFT_CLIENT_ID,
    clientSecret: process.env.MICROSOFT_CLIENT_SECRET,
    tenantId: process.env.MICROSOFT_TENANT_ID,
    redirectUri: process.env.MICROSOFT_REDIRECT_URI
});

// In your Base44 function
exports.microsoftEmailIntegration = async (req, res) => {
    try {
        // Handle OAuth callback
        const { code } = req.query;
        const tokenResponse = await graphClient.getAccessToken(code);
        
        // Send email
        await graphClient.testMailSend('recipient@example.com', false);
        
        res.json({ success: true, message: 'Email sent successfully' });
    } catch (error) {
        console.error('Integration error:', error);
        res.status(500).json({ error: error.message });
    }
};
```

## 📁 Files Overview

| File | Description |
|------|-------------|
| `setup-azure-app.sh` | Automated setup script using Azure CLI |
| `AZURE_SETUP_GUIDE.md` | Detailed manual setup instructions |
| `test-integration.js` | Complete testing suite for the integration |
| `TROUBLESHOOTING.md` | Solutions for common issues |
| `.env.template` | Template for environment variables |

## 🔒 Security Best Practices

### Environment Variables
- ✅ Never commit real secrets to version control
- ✅ Use `.env` file for local development (add to `.gitignore`)
- ✅ Store secrets securely in Base44 dashboard
- ✅ Rotate client secrets regularly

### Production Checklist
- [ ] Client secret expiration monitoring
- [ ] Admin consent granted
- [ ] Production redirect URIs configured
- [ ] Error handling implemented
- [ ] Rate limiting handled
- [ ] Security review completed

## 🆘 Troubleshooting

### Common Issues
- **"Invalid redirect_uri"** → Check URIs match exactly in Azure
- **"Invalid client secret"** → Verify you copied the Value (not Secret ID)
- **"Insufficient privileges"** → Ensure admin consent is granted

### Get Help
- 📖 [Full Troubleshooting Guide](TROUBLESHOOTING.md)
- 🔍 [Microsoft Graph Documentation](https://docs.microsoft.com/graph/)
- 💬 [Azure AD Error Codes Reference](https://docs.microsoft.com/azure/active-directory/develop/reference-aadsts-error-codes)

## 🚀 Next Steps

1. **Run the setup**: `./setup-azure-app.sh`
2. **Test the integration**: `node test-integration.js test`  
3. **Add secrets to Base44**: Copy from generated `.env` file
4. **Deploy your application**: Update production environment
5. **Monitor and maintain**: Set up alerts for token expiration

---

## Support

Need help? Check the troubleshooting guide or create an issue with:
- Error messages and logs
- Steps to reproduce
- Environment details (Node.js version, etc.)

**Happy integrating! 🎉**
