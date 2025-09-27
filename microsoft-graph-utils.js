/**
 * Microsoft Graph API Integration Utilities for EduBuddyBridge
 * This module provides utilities for authenticating and interacting with Microsoft Graph API
 */

// Configuration constants
const MICROSOFT_GRAPH_ENDPOINTS = {
    TOKEN: 'https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token',
    GRAPH_API: 'https://graph.microsoft.com/v1.0',
    SEND_MAIL: 'https://graph.microsoft.com/v1.0/me/sendMail'
};

class MicrosoftGraphClient {
    constructor(clientId, clientSecret, tenantId = 'common') {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.tenantId = tenantId;
        this.accessToken = null;
        this.tokenExpiry = null;
    }

    /**
     * Get access token using client credentials flow
     * @returns {Promise<string>} Access token
     */
    async getAccessToken() {
        // Check if token is still valid
        if (this.accessToken && this.tokenExpiry && Date.now() < this.tokenExpiry) {
            return this.accessToken;
        }

        const tokenUrl = MICROSOFT_GRAPH_ENDPOINTS.TOKEN.replace('{tenant}', this.tenantId);
        
        const params = new URLSearchParams({
            client_id: this.clientId,
            client_secret: this.clientSecret,
            scope: 'https://graph.microsoft.com/.default',
            grant_type: 'client_credentials'
        });

        try {
            const response = await fetch(tokenUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                body: params
            });

            if (!response.ok) {
                const error = await response.text();
                throw new Error(`Token request failed: ${response.status} - ${error}`);
            }

            const tokenData = await response.json();
            this.accessToken = tokenData.access_token;
            this.tokenExpiry = Date.now() + (tokenData.expires_in * 1000) - 60000; // 1 minute buffer

            return this.accessToken;
        } catch (error) {
            console.error('Error getting access token:', error);
            throw error;
        }
    }

    /**
     * Send email using Microsoft Graph API
     * @param {Object} emailData - Email data
     * @param {string} emailData.subject - Email subject
     * @param {string} emailData.body - Email body (HTML)
     * @param {Array} emailData.recipients - Array of recipient email addresses
     * @param {string} emailData.fromEmail - Sender email address
     * @returns {Promise<Object>} Send result
     */
    async sendEmail(emailData) {
        try {
            const accessToken = await this.getAccessToken();

            const message = {
                message: {
                    subject: emailData.subject,
                    body: {
                        contentType: 'HTML',
                        content: emailData.body
                    },
                    toRecipients: emailData.recipients.map(email => ({
                        emailAddress: {
                            address: email
                        }
                    })),
                    from: {
                        emailAddress: {
                            address: emailData.fromEmail
                        }
                    }
                },
                saveToSentItems: 'true'
            };

            const response = await fetch(MICROSOFT_GRAPH_ENDPOINTS.SEND_MAIL, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${accessToken}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(message)
            });

            if (!response.ok) {
                const error = await response.text();
                throw new Error(`Send email failed: ${response.status} - ${error}`);
            }

            return { success: true, messageId: response.headers.get('request-id') };
        } catch (error) {
            console.error('Error sending email:', error);
            throw error;
        }
    }

    /**
     * Get user profile information
     * @returns {Promise<Object>} User profile
     */
    async getUserProfile() {
        try {
            const accessToken = await this.getAccessToken();

            const response = await fetch(`${MICROSOFT_GRAPH_ENDPOINTS.GRAPH_API}/me`, {
                headers: {
                    'Authorization': `Bearer ${accessToken}`
                }
            });

            if (!response.ok) {
                const error = await response.text();
                throw new Error(`Get user profile failed: ${response.status} - ${error}`);
            }

            return await response.json();
        } catch (error) {
            console.error('Error getting user profile:', error);
            throw error;
        }
    }

    /**
     * Test the Microsoft Graph connection
     * @returns {Promise<Object>} Test results
     */
    async testConnection() {
        try {
            const accessToken = await this.getAccessToken();
            
            // Test with a simple Graph API call
            const response = await fetch(`${MICROSOFT_GRAPH_ENDPOINTS.GRAPH_API}/$metadata`, {
                headers: {
                    'Authorization': `Bearer ${accessToken}`
                }
            });

            return {
                success: response.ok,
                status: response.status,
                hasToken: !!accessToken,
                tokenLength: accessToken ? accessToken.length : 0
            };
        } catch (error) {
            return {
                success: false,
                error: error.message,
                hasToken: false
            };
        }
    }
}

/**
 * Factory function to create MicrosoftGraphClient from environment variables
 * @returns {MicrosoftGraphClient} Configured client
 */
function createGraphClientFromEnv() {
    const clientId = process.env.MICROSOFT_CLIENT_ID;
    const clientSecret = process.env.MICROSOFT_CLIENT_SECRET;
    const tenantId = process.env.MICROSOFT_TENANT_ID || 'common';

    if (!clientId || !clientSecret) {
        throw new Error('Missing required environment variables: MICROSOFT_CLIENT_ID, MICROSOFT_CLIENT_SECRET');
    }

    return new MicrosoftGraphClient(clientId, clientSecret, tenantId);
}

/**
 * Helper function for EduBuddyBridge email integration
 * @param {Object} emailData - Email data
 * @returns {Promise<Object>} Send result
 */
async function sendEduBuddyBridgeEmail(emailData) {
    try {
        const client = createGraphClientFromEnv();
        
        const result = await client.sendEmail({
            subject: emailData.subject || 'EduBuddyBridge Notification',
            body: emailData.body || '<p>This is a notification from EduBuddyBridge.</p>',
            recipients: emailData.recipients || [],
            fromEmail: emailData.fromEmail
        });

        return result;
    } catch (error) {
        console.error('EduBuddyBridge email send error:', error);
        throw error;
    }
}

// Export for Node.js
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        MicrosoftGraphClient,
        createGraphClientFromEnv,
        sendEduBuddyBridgeEmail,
        MICROSOFT_GRAPH_ENDPOINTS
    };
}

// Export for browser/global usage
if (typeof window !== 'undefined') {
    window.MicrosoftGraphUtils = {
        MicrosoftGraphClient,
        createGraphClientFromEnv,
        sendEduBuddyBridgeEmail,
        MICROSOFT_GRAPH_ENDPOINTS
    };
}