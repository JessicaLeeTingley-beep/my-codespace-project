# EduBuddyBridge Azure Integration Troubleshooting Guide

## Common Issues and Solutions

### 1. Authentication Issues

#### ❌ "AADSTS70011: The provided value for the 'redirect_uri' parameter is not valid"
**Cause**: The redirect URI in your request doesn't match what's configured in Azure.

**Solutions**:
- Verify redirect URIs in Azure App Registration match exactly (including https://)
- Check for trailing slashes - they matter!
- Ensure you're using the correct environment URL (production vs preview)

```bash
# Configured URIs should be:
# Production: https://edubuddybridge.online/api/functions/microsoftEmailIntegration
# Preview: https://preview--edubuddybridge.base44.app/api/functions/microsoftEmailIntegration
```

#### ❌ "AADSTS7000215: Invalid client secret provided"
**Cause**: The client secret is incorrect, expired, or not properly configured.

**Solutions**:
- Check that you copied the secret **Value** (not the Secret ID)
- Verify the secret hasn't expired
- Create a new client secret if needed
- Ensure no extra spaces in the environment variable

#### ❌ "AADSTS50020: User account from identity provider does not exist in tenant"
**Cause**: The user account type doesn't match the configured account types.

**Solutions**:
- Verify "Supported account types" is set to "Accounts in any organizational directory and personal Microsoft accounts"
- For personal Microsoft accounts, ensure they're allowed
- Check if the user needs to be invited to the tenant

### 2. Permission Issues

#### ❌ "Insufficient privileges to complete the operation"
**Cause**: Required permissions not granted or admin consent not provided.

**Solutions**:
- Verify both Mail.Send and User.Read permissions are added
- Ensure admin consent has been granted (green checkmarks in Azure)
- Wait a few minutes after granting consent for changes to propagate
- Try revoking and re-granting permissions

#### ❌ "Application does not have permission to Send mail as user"
**Cause**: Mail.Send permission is not properly configured.

**Solutions**:
- Confirm Mail.Send is configured as **Application** permission (not Delegated)
- Grant admin consent for the permission
- Check that the permission shows "Granted for [organization]"

### 3. Token Issues

#### ❌ "AADSTS54005: OAuth2 Authorization code was already redeemed"
**Cause**: Trying to use an authorization code that was already exchanged for a token.

**Solutions**:
- Authorization codes can only be used once
- Generate a new authorization URL and get a fresh code
- Implement proper token refresh logic in production

#### ❌ "AADSTS70008: The provided authorization grant has expired"
**Cause**: The authorization code or refresh token has expired.

**Solutions**:
- Authorization codes expire quickly (usually 10 minutes)
- Use the authorization code immediately after receiving it
- Implement token refresh using refresh_token for long-running applications

### 4. Network and API Issues

#### ❌ "Error: getaddrinfo ENOTFOUND login.microsoftonline.com"
**Cause**: Network connectivity issues or DNS resolution problems.

**Solutions**:
- Check internet connection
- Verify DNS resolution works: `nslookup login.microsoftonline.com`
- Check if corporate firewall blocks Microsoft endpoints
- Try using different network (mobile hotspot for testing)

#### ❌ "Microsoft Graph API returns 401 Unauthorized"
**Cause**: Invalid or expired access token.

**Solutions**:
- Verify access token is being sent in Authorization header
- Check token hasn't expired (tokens usually last 1 hour)
- Ensure proper Bearer token format: `Authorization: Bearer <token>`
- Refresh the token if expired

### 5. Environment Configuration Issues

#### ❌ "Missing configuration: clientId, clientSecret, tenantId"
**Cause**: Environment variables not properly set.

**Solutions**:
- Verify .env file exists and has correct values
- Check environment variable names match exactly:
  - `MICROSOFT_CLIENT_ID`
  - `MICROSOFT_CLIENT_SECRET` 
  - `MICROSOFT_TENANT_ID`
- Restart application after changing environment variables
- Verify no quotes around values unless needed

#### ❌ "your_client_id_here" appears in logs
**Cause**: Environment variables not loaded or using template values.

**Solutions**:
- Copy .env.template to .env and fill in real values
- Install and configure dotenv if using Node.js
- Verify environment loading in application startup

### 6. Base44 Specific Issues

#### ❌ Environment variables not available in Base44 functions
**Cause**: Secrets not properly configured in Base44 dashboard.

**Solutions**:
- Add variables in Base44 dashboard under Environment > Secrets
- Use exact names: MICROSOFT_CLIENT_ID, MICROSOFT_CLIENT_SECRET, MICROSOFT_TENANT_ID
- Redeploy function after adding secrets
- Verify secrets are available: `console.log(Object.keys(process.env))`

#### ❌ "Function timeout" when calling Microsoft Graph API
**Cause**: Network latency or API response time exceeds function timeout.

**Solutions**:
- Increase function timeout in Base44 configuration
- Implement proper error handling and retries
- Use async/await properly to avoid blocking
- Consider implementing queue-based processing for email sending

### 7. Testing and Development Issues

#### ❌ Test integration script fails with "Cannot read property..."
**Cause**: Missing dependencies or incorrect Node.js version.

**Solutions**:
- Ensure Node.js version 14+ is installed
- No additional dependencies needed (uses built-in https, querystring)
- Check file path and permissions
- Run with: `node test-integration.js test`

### Debugging Commands

```bash
# Test Azure CLI login
az login
az account show

# Test network connectivity
curl -I https://login.microsoftonline.com
curl -I https://graph.microsoft.com

# Verify environment variables
node -e "console.log(process.env.MICROSOFT_CLIENT_ID)"

# Test basic HTTP connectivity
curl -X GET "https://graph.microsoft.com/v1.0" -H "Authorization: Bearer YOUR_TOKEN"
```

### Monitoring and Logs

#### Azure AD Sign-in Logs
- Portal → Azure Active Directory → Monitoring → Sign-in logs
- Filter by your application name "EduBuddyBridge"
- Check for authentication failures and error codes

#### Microsoft Graph API Logs  
- Use Graph Explorer for testing: https://developer.microsoft.com/graph/graph-explorer
- Enable detailed logging in your application
- Monitor API rate limits and throttling

### Getting Help

1. **Check Azure AD Error Codes**: https://docs.microsoft.com/azure/active-directory/develop/reference-aadsts-error-codes
2. **Microsoft Graph Documentation**: https://docs.microsoft.com/graph/
3. **Stack Overflow**: Search for specific error messages
4. **Microsoft Q&A**: https://docs.microsoft.com/answers/

### Production Checklist

Before deploying to production:

- [ ] Client secret expiration date set appropriately
- [ ] Admin consent granted for all permissions
- [ ] Correct redirect URIs configured for production domain
- [ ] Environment variables secured (not in source control)
- [ ] Error handling implemented for all API calls
- [ ] Token refresh logic implemented
- [ ] Monitoring and alerting configured
- [ ] Rate limiting handled appropriately
- [ ] Security review completed

### Emergency Procedures

#### If Client Secret is Compromised:
1. Immediately create a new client secret in Azure
2. Update environment variables with new secret
3. Redeploy application
4. Delete the compromised secret
5. Monitor for unauthorized usage

#### If App Registration is Accidentally Deleted:
1. Re-run the setup script or follow manual setup guide
2. Update all environment variables
3. Re-grant admin consent
4. Update any hardcoded references to the old app ID