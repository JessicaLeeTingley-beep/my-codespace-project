# my-codespace-project
A new project created for GitHub Codespaces development

## Azure Integration for EduBuddyBridge

This project now includes comprehensive Azure App Registration setup for the EduBuddyBridge application, providing Microsoft Graph API integration for email functionality.

### 🚀 Quick Setup

1. **Run the automated Azure setup:**
   ```bash
   ./scripts/setup-azure.sh
   ```

2. **Or follow the manual guide:** [azure-setup.md](azure-setup.md)

3. **Test your integration:**
   ```bash
   ./scripts/test-azure-integration.sh
   node scripts/test-graph-node.js
   ```

### 📚 Documentation

- **[README-Azure.md](README-Azure.md)** - Complete Azure integration guide
- **[azure-setup.md](azure-setup.md)** - Step-by-step setup instructions
- **[.env.template](.env.template)** - Environment variables template

### 🔧 Features

- ✅ Azure App Registration automated setup
- ✅ Microsoft Graph API integration utilities
- ✅ Email sending capabilities
- ✅ Multi-platform support (Linux, macOS, Windows)
- ✅ Comprehensive testing suite
- ✅ Error handling for common Codespace authentication issues

### 🆘 Troubleshooting

If you encounter Azure CLI authentication errors (like Error 53003), this is common in GitHub Codespaces. Use the Azure Portal method described in [azure-setup.md](azure-setup.md) instead.

## Original Project

This project was originally created for GitHub Codespaces development and has been enhanced with Azure integration capabilities.
