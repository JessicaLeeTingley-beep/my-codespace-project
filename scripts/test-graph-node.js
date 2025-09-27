#!/usr/bin/env node

/**
 * Node.js test script for Microsoft Graph integration
 * This script tests the Microsoft Graph utilities with actual API calls
 */

const fs = require('fs');
const path = require('path');

// Load the Microsoft Graph utilities
const { 
    MicrosoftGraphClient, 
    createGraphClientFromEnv, 
    sendEduBuddyBridgeEmail 
} = require('../microsoft-graph-utils');

// Load environment variables from .env file if it exists
function loadEnv() {
    const envPath = path.join(__dirname, '.env');
    if (fs.existsSync(envPath)) {
        const envContent = fs.readFileSync(envPath, 'utf8');
        envContent.split('\n').forEach(line => {
            const [key, value] = line.split('=');
            if (key && value && !key.startsWith('#')) {
                process.env[key.trim()] = value.trim();
            }
        });
        console.log('✅ Loaded environment variables from .env');
    } else {
        console.log('⚠️  No .env file found, using system environment variables');
    }
}

async function testGraphConnection() {
    console.log('\n🧪 Testing Microsoft Graph Connection...');
    
    try {
        const client = createGraphClientFromEnv();
        const testResult = await client.testConnection();
        
        if (testResult.success) {
            console.log('✅ Connection test passed');
            console.log(`   - Token acquired: ${testResult.hasToken}`);
            console.log(`   - Token length: ${testResult.tokenLength}`);
            console.log(`   - Status: ${testResult.status}`);
        } else {
            console.log('❌ Connection test failed');
            console.log(`   - Error: ${testResult.error}`);
        }
        
        return testResult.success;
    } catch (error) {
        console.log('❌ Connection test error:', error.message);
        return false;
    }
}

async function testTokenAcquisition() {
    console.log('\n🔑 Testing Access Token Acquisition...');
    
    try {
        const client = createGraphClientFromEnv();
        const token = await client.getAccessToken();
        
        console.log('✅ Token acquisition successful');
        console.log(`   - Token length: ${token.length}`);
        console.log(`   - Token preview: ${token.substring(0, 20)}...`);
        
        return true;
    } catch (error) {
        console.log('❌ Token acquisition failed:', error.message);
        
        if (error.message.includes('AADSTS70011')) {
            console.log('   💡 This error suggests invalid scope. Check your API permissions.');
        } else if (error.message.includes('AADSTS7000215')) {
            console.log('   💡 Invalid client secret. Please verify MICROSOFT_CLIENT_SECRET.');
        } else if (error.message.includes('AADSTS700016')) {
            console.log('   💡 Invalid client ID. Please verify MICROSOFT_CLIENT_ID.');
        }
        
        return false;
    }
}

async function testEmailSending() {
    console.log('\n📧 Testing Email Sending (Dry Run)...');
    
    // This is a dry run - we'll prepare the email but won't actually send it
    // unless the user provides a test email address
    
    const testEmail = {
        subject: 'EduBuddyBridge Test Email',
        body: `
            <html>
            <body>
                <h2>🎉 EduBuddyBridge Integration Test</h2>
                <p>This is a test email from your EduBuddyBridge Azure App Registration setup.</p>
                <p><strong>Test Details:</strong></p>
                <ul>
                    <li>Timestamp: ${new Date().toISOString()}</li>
                    <li>Client ID: ${process.env.MICROSOFT_CLIENT_ID?.substring(0, 8)}...</li>
                    <li>Tenant: ${process.env.MICROSOFT_TENANT_ID || 'common'}</li>
                </ul>
                <p>If you received this email, your Microsoft Graph integration is working correctly! 🚀</p>
            </body>
            </html>
        `,
        recipients: [], // No recipients for dry run
        fromEmail: 'test@example.com' // Placeholder
    };
    
    console.log('✅ Email prepared for sending');
    console.log(`   - Subject: ${testEmail.subject}`);
    console.log(`   - Body length: ${testEmail.body.length} characters`);
    
    // Check if user wants to send a real test email
    const testEmailAddress = process.env.TEST_EMAIL_ADDRESS;
    if (testEmailAddress) {
        console.log(`\n📮 Sending test email to ${testEmailAddress}...`);
        
        try {
            testEmail.recipients = [testEmailAddress];
            testEmail.fromEmail = testEmailAddress; // Use same email as sender
            
            const result = await sendEduBuddyBridgeEmail(testEmail);
            console.log('✅ Test email sent successfully');
            console.log(`   - Message ID: ${result.messageId}`);
            return true;
        } catch (error) {
            console.log('❌ Test email failed:', error.message);
            return false;
        }
    } else {
        console.log('   💡 To send a real test email, set TEST_EMAIL_ADDRESS environment variable');
        return true; // Consider dry run as success
    }
}

async function runTests() {
    console.log('🔍 EduBuddyBridge Microsoft Graph Integration Test');
    console.log('='.repeat(50));
    
    // Load environment variables
    loadEnv();
    
    // Check required environment variables
    const requiredVars = ['MICROSOFT_CLIENT_ID', 'MICROSOFT_CLIENT_SECRET'];
    const missingVars = requiredVars.filter(varName => !process.env[varName]);
    
    if (missingVars.length > 0) {
        console.log('❌ Missing required environment variables:', missingVars.join(', '));
        console.log('\n💡 Please ensure you have:');
        console.log('   1. Created .env file from .env.template');
        console.log('   2. Set the required environment variables');
        console.log('   3. Run the Azure setup script first');
        process.exit(1);
    }
    
    console.log('✅ Environment variables loaded');
    console.log(`   - Client ID: ${process.env.MICROSOFT_CLIENT_ID.substring(0, 8)}...`);
    console.log(`   - Tenant ID: ${process.env.MICROSOFT_TENANT_ID || 'common'}`);
    
    let testsRun = 0;
    let testsPassed = 0;
    
    // Test 1: Token acquisition
    testsRun++;
    if (await testTokenAcquisition()) testsPassed++;
    
    // Test 2: Graph connection
    testsRun++;
    if (await testGraphConnection()) testsPassed++;
    
    // Test 3: Email preparation/sending
    testsRun++;
    if (await testEmailSending()) testsPassed++;
    
    // Summary
    console.log('\n📊 Test Summary');
    console.log('='.repeat(30));
    console.log(`Tests run: ${testsRun}`);
    console.log(`Tests passed: ${testsPassed}`);
    console.log(`Tests failed: ${testsRun - testsPassed}`);
    
    if (testsPassed === testsRun) {
        console.log('\n🎉 All tests passed! Your Microsoft Graph integration is ready.');
        console.log('\n📋 Next steps:');
        console.log('   1. Add environment variables to your Base44 dashboard');
        console.log('   2. Test with your application');
        console.log('   3. Monitor API usage in Azure Portal');
    } else {
        console.log('\n⚠️  Some tests failed. Please review the errors above.');
        process.exit(1);
    }
}

// Run tests if this script is executed directly
if (require.main === module) {
    runTests().catch(error => {
        console.error('💥 Unexpected error:', error);
        process.exit(1);
    });
}