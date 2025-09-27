# PowerShell script for Azure App Registration Setup
# Azure App Registration Setup Script for EduBuddyBridge (PowerShell)

param(
    [string]$AppName = "EduBuddyBridge",
    [switch]$UseServicePrincipal,
    [string]$TenantId,
    [string]$ClientId,
    [string]$ClientSecret
)

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

# Configuration
$RedirectUris = @(
    "https://edubuddybridge.online/api/functions/microsoftEmailIntegration",
    "https://preview--edubuddybridge.base44.app/api/functions/microsoftEmailIntegration"
)

function Write-Step {
    param([string]$Message)
    Write-Host "${Green}[STEP]${Reset} $Message"
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "${Yellow}[WARNING]${Reset} $Message"
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "${Red}[ERROR]${Reset} $Message"
}

function Write-Info {
    param([string]$Message)
    Write-Host "${Blue}[INFO]${Reset} $Message"
}

function Install-AzureModule {
    Write-Step "Checking for Azure PowerShell module..."
    
    if (!(Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-Info "Installing Azure PowerShell module..."
        Install-Module -Name Az -Scope CurrentUser -Force -AllowClobber
        Write-Info "✅ Azure PowerShell module installed"
    } else {
        Write-Info "✅ Azure PowerShell module is already installed"
    }
    
    # Import required modules
    Import-Module Az.Accounts -Force
    Import-Module Az.Resources -Force
}

function Connect-AzureAccount {
    Write-Step "Attempting Azure authentication..."
    
    try {
        if ($UseServicePrincipal -and $TenantId -and $ClientId -and $ClientSecret) {
            Write-Info "Using service principal authentication..."
            $SecureClientSecret = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($ClientId, $SecureClientSecret)
            Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $TenantId
        } else {
            Write-Info "Using interactive authentication..."
            Connect-AzAccount
        }
        Write-Info "✅ Azure authentication successful"
        return $true
    }
    catch {
        Write-Error-Custom "Authentication failed: $_"
        return $false
    }
}

function New-AppRegistration {
    Write-Step "Creating Azure App Registration..."
    
    try {
        # Create the application
        $App = New-AzADApplication -DisplayName $AppName -SignInAudience "AzureADandPersonalMicrosoftAccount"
        
        Write-Info "✅ App registration created with ID: $($App.AppId)"
        
        # Add redirect URIs
        Write-Step "Adding redirect URIs..."
        $WebApp = @{
            RedirectUris = $RedirectUris
            ImplicitGrantSettings = @{
                EnableAccessTokenIssuance = $false
                EnableIdTokenIssuance = $false
            }
        }
        Update-AzADApplication -ObjectId $App.Id -Web $WebApp
        Write-Info "✅ Redirect URIs added"
        
        # Create client secret
        Write-Step "Creating client secret..."
        $ClientSecret = New-AzADAppCredential -ObjectId $App.Id -DisplayName "EduBuddyBridge Secret"
        Write-Info "✅ Client secret created"
        
        # Get tenant ID
        $Context = Get-AzContext
        $TenantId = $Context.Tenant.Id
        
        # Configure API permissions
        Write-Step "Configuring API permissions..."
        
        # Microsoft Graph API permissions
        $GraphApiId = "00000003-0000-0000-c000-000000000000"
        
        # Mail.Send (Application permission) - b633e1c5-b582-4048-a93e-9f11b44c7e96
        # User.Read (Delegated permission) - e1fe6dd8-ba31-4d61-89e7-88639da4683d
        
        $RequiredResourceAccess = @{
            ResourceAppId = $GraphApiId
            ResourceAccess = @(
                @{
                    Id = "b633e1c5-b582-4048-a93e-9f11b44c7e96"
                    Type = "Role"
                },
                @{
                    Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
                    Type = "Scope"
                }
            )
        }
        
        Update-AzADApplication -ObjectId $App.Id -RequiredResourceAccess $RequiredResourceAccess
        Write-Info "✅ API permissions configured"
        
        # Grant admin consent (if possible)
        Write-Step "Attempting to grant admin consent..."
        try {
            # This requires admin privileges
            Write-Warning-Custom "Admin consent must be granted manually in the Azure Portal"
            Write-Info "Go to: https://portal.azure.com -> Azure AD -> App registrations -> $AppName -> API permissions -> Grant admin consent"
        }
        catch {
            Write-Warning-Custom "Could not grant admin consent automatically. You may need to grant it manually."
        }
        
        # Output results
        Write-Step "Setup complete! Here are your environment variables:"
        Write-Host ""
        Write-Host "=== COPY THESE VALUES TO YOUR ENVIRONMENT ===" -ForegroundColor Yellow
        Write-Host "MICROSOFT_CLIENT_ID=$($App.AppId)"
        Write-Host "MICROSOFT_CLIENT_SECRET=$($ClientSecret.SecretText)"
        Write-Host "MICROSOFT_TENANT_ID=$TenantId"
        Write-Host "===============================================" -ForegroundColor Yellow
        Write-Host ""
        
        # Save to .env file
        $EnvContent = @"
# Azure App Registration Environment Variables for EduBuddyBridge
# Copy these values to your deployment environment (Base44, etc.)

MICROSOFT_CLIENT_ID=$($App.AppId)
MICROSOFT_CLIENT_SECRET=$($ClientSecret.SecretText)
MICROSOFT_TENANT_ID=$TenantId

# Optional: Set to "common" for multi-tenant scenarios (default behavior)
# MICROSOFT_TENANT_ID=common
"@
        
        $EnvContent | Out-File -FilePath ".env.template" -Encoding UTF8
        Write-Info "✅ Environment variables saved to .env.template"
        Write-Warning-Custom "Remember to add these to your Base44 dashboard!"
        
        return $true
    }
    catch {
        Write-Error-Custom "App registration failed: $_"
        return $false
    }
}

# Main execution
function Main {
    Write-Step "Starting Azure App Registration setup..."
    Write-Host ""
    
    # Install Azure module
    Install-AzureModule
    
    # Connect to Azure
    if (!(Connect-AzureAccount)) {
        Write-Error-Custom "Authentication failed. Exiting."
        exit 1
    }
    
    # Create app registration
    if (New-AppRegistration) {
        Write-Info "🎉 Azure App Registration setup completed successfully!"
        Write-Host ""
        Write-Info "Next steps:"
        Write-Host "1. Copy the environment variables to your Base44 dashboard"
        Write-Host "2. Test the integration using the provided test scripts"
        Write-Host "3. Deploy your application"
    } else {
        Write-Error-Custom "App registration setup failed"
        exit 1
    }
}

# Run main function
Main