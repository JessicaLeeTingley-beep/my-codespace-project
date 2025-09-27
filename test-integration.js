/**
 * EduBuddyBridge Microsoft Graph Integration Test
 * This script tests the Azure App Registration setup and Microsoft Graph API connectivity
 */

const https = require('https');
const querystring = require('querystring');

// Load environment variables (in real app, use dotenv)
const config = {
    clientId: process.env.MICROSOFT_CLIENT_ID || 'your_client_id',
    clientSecret: process.env.MICROSOFT_CLIENT_SECRET || 'your_client_secret', 
    tenantId: process.env.MICROSOFT_TENANT_ID || 'common',
    redirectUri: process.env.MICROSOFT_REDIRECT_URI_PREVIEW || 'https://preview--edubuddybridge.base44.app/api/functions/microsoftEmailIntegration',
    graphApiUrl: 'https://graph.microsoft.com/v1.0'
};

class MicrosoftGraphTester {
    constructor(config) {
        this.config = config;
        this.accessToken = null;
    }

    /**
     * Step 1: Generate authorization URL for user login
     */
    getAuthorizationUrl() {
        const authUrl = `https://login.microsoftonline.com/${this.config.tenantId}/oauth2/v2.0/authorize`;
        const params = {
            client_id: this.config.clientId,
            response_type: 'code',
            redirect_uri: this.config.redirectUri,
            scope: 'https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/User.Read',
            response_mode: 'query',
            state: 'test-state-' + Date.now()
        };
        
        return `${authUrl}?${querystring.stringify(params)}`;
    }

    /**
     * Step 2: Exchange authorization code for access token
     */
    async getAccessToken(authorizationCode) {
        const tokenUrl = `https://login.microsoftonline.com/${this.config.tenantId}/oauth2/v2.0/token`;
        
        const tokenData = {
            client_id: this.config.clientId,
            client_secret: this.config.clientSecret,
            code: authorizationCode,
            redirect_uri: this.config.redirectUri,
            grant_type: 'authorization_code',
            scope: 'https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/User.Read'
        };

        try {
            const response = await this.makeHttpRequest('POST', tokenUrl, tokenData, {
                'Content-Type': 'application/x-www-form-urlencoded'
            });
            
            const tokenResponse = JSON.parse(response);
            
            if (tokenResponse.error) {
                throw new Error(`Token exchange failed: ${tokenResponse.error_description}`);
            }
            
            this.accessToken = tokenResponse.access_token;
            return tokenResponse;
        } catch (error) {
            console.error('❌ Token exchange failed:', error.message);
            throw error;
        }
    }

    /**
     * Step 3: Test User.Read permission
     */
    async testUserRead() {
        if (!this.accessToken) {
            throw new Error('No access token available. Please authenticate first.');
        }

        try {
            const response = await this.makeHttpRequest('GET', `${this.config.graphApiUrl}/me`, null, {
                'Authorization': `Bearer ${this.accessToken}`,
                'Content-Type': 'application/json'
            });

            const user = JSON.parse(response);
            console.log('✅ User.Read permission test successful');
            console.log('📋 User info:', {
                displayName: user.displayName,
                mail: user.mail,
                userPrincipalName: user.userPrincipalName
            });
            
            return user;
        } catch (error) {
            console.error('❌ User.Read test failed:', error.message);
            throw error;
        }
    }

    /**
     * Step 4: Test Mail.Send permission (sends test email)
     */
    async testMailSend(recipientEmail, testMode = true) {
        if (!this.accessToken) {
            throw new Error('No access token available. Please authenticate first.');
        }

        const emailData = {
            message: {
                subject: testMode ? '[TEST] EduBuddyBridge Integration Test' : 'EduBuddyBridge Email Test',
                body: {
                    contentType: 'HTML',
                    content: `
                        <h2>EduBuddyBridge Integration Test</h2>
                        <p>This is a test email sent from the EduBuddyBridge application using Microsoft Graph API.</p>
                        <p><strong>Test Details:</strong></p>
                        <ul>
                            <li>Timestamp: ${new Date().toISOString()}</li>
                            <li>API: Microsoft Graph v1.0</li>
                            <li>Permission: Mail.Send</li>
                            <li>Mode: ${testMode ? 'Test' : 'Production'}</li>
                        </ul>
                        <p>If you received this email, the integration is working correctly! 🎉</p>
                        <hr>
                        <p><small>This is an automated test message from EduBuddyBridge.</small></p>
                    `
                },
                toRecipients: [
                    {
                        emailAddress: {
                            address: recipientEmail
                        }
                    }
                ]
            },
            saveToSentItems: true
        };

        try {
            const response = await this.makeHttpRequest('POST', `${this.config.graphApiUrl}/me/sendMail`, 
                JSON.stringify(emailData), {
                'Authorization': `Bearer ${this.accessToken}`,
                'Content-Type': 'application/json'
            });

            console.log('✅ Mail.Send permission test successful');
            console.log(`📧 Test email sent to: ${recipientEmail}`);
            
            return { success: true, recipient: recipientEmail };
        } catch (error) {
            console.error('❌ Mail.Send test failed:', error.message);
            throw error;
        }
    }

    /**
     * Helper: Make HTTP requests
     */
    makeHttpRequest(method, url, data, headers = {}) {
        return new Promise((resolve, reject) => {
            const urlObj = new URL(url);
            const postData = typeof data === 'string' ? data : querystring.stringify(data);
            
            const options = {
                hostname: urlObj.hostname,
                path: urlObj.pathname + urlObj.search,
                method: method,
                headers: {
                    ...headers,
                    ...(method === 'POST' && {'Content-Length': Buffer.byteLength(postData)})
                }
            };

            const req = https.request(options, (res) => {
                let responseData = '';
                
                res.on('data', (chunk) => {
                    responseData += chunk;
                });
                
                res.on('end', () => {
                    if (res.statusCode >= 200 && res.statusCode < 300) {
                        resolve(responseData);
                    } else {
                        reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
                    }
                });
            });

            req.on('error', (error) => {
                reject(error);
            });

            if (method === 'POST' && postData) {
                req.write(postData);
            }
            
            req.end();
        });
    }

    /**
     * Comprehensive test suite
     */
    async runTestSuite() {
        console.log('🧪 Starting EduBuddyBridge Microsoft Graph Integration Tests\n');
        
        // Test 1: Configuration validation
        console.log('1️⃣ Testing configuration...');
        this.validateConfiguration();
        console.log('✅ Configuration is valid\n');

        // Test 2: Generate auth URL
        console.log('2️⃣ Generating authorization URL...');
        const authUrl = this.getAuthorizationUrl();
        console.log('✅ Authorization URL generated:');
        console.log(`🔗 ${authUrl}\n`);
        
        console.log('📋 Next steps for manual testing:');
        console.log('1. Open the authorization URL in your browser');
        console.log('2. Complete the Microsoft login flow');
        console.log('3. Copy the authorization code from the redirect URL');
        console.log('4. Use the code with getAccessToken() method');
        console.log('5. Run testUserRead() and testMailSend() methods\n');
        
        return {
            authUrl,
            status: 'ready-for-manual-testing'
        };
    }

    validateConfiguration() {
        const required = ['clientId', 'clientSecret', 'tenantId', 'redirectUri'];
        const missing = required.filter(key => 
            !this.config[key] || this.config[key].startsWith('your_')
        );
        
        if (missing.length > 0) {
            throw new Error(`❌ Missing configuration: ${missing.join(', ')}`);
        }

        console.log('📋 Configuration summary:');
        console.log(`   Client ID: ${this.config.clientId.substring(0, 8)}...`);
        console.log(`   Tenant ID: ${this.config.tenantId}`);
        console.log(`   Redirect URI: ${this.config.redirectUri}`);
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { MicrosoftGraphTester, config };
}

// CLI usage
if (require.main === module) {
    console.log('🚀 EduBuddyBridge Microsoft Graph Integration Tester\n');
    
    const tester = new MicrosoftGraphTester(config);
    
    // Parse command line arguments
    const args = process.argv.slice(2);
    const command = args[0];
    
    switch (command) {
        case 'test':
            tester.runTestSuite().catch(console.error);
            break;
            
        case 'auth-url':
            console.log('🔗 Authorization URL:');
            console.log(tester.getAuthorizationUrl());
            break;
            
        case 'token':
            const authCode = args[1];
            if (!authCode) {
                console.error('❌ Usage: node test-integration.js token <authorization_code>');
                process.exit(1);
            }
            tester.getAccessToken(authCode)
                .then(token => console.log('✅ Token received:', token))
                .catch(console.error);
            break;
            
        default:
            console.log('Usage:');
            console.log('  node test-integration.js test           # Run full test suite');
            console.log('  node test-integration.js auth-url       # Generate auth URL');
            console.log('  node test-integration.js token <code>   # Exchange auth code for token');
            console.log('\nEnvironment variables required:');
            console.log('  MICROSOFT_CLIENT_ID');
            console.log('  MICROSOFT_CLIENT_SECRET');
            console.log('  MICROSOFT_TENANT_ID');
    }
}