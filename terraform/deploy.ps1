<#
.DESCRIPTION
    This script aids in deploying using terraform


.INPUTS

.OUTPUTS

.EXAMPLE
    # Deploy using tfvars file Windows Reference
    .\deploy.ps1 -WorkingDirectory ".\" -UseTfVarsFile

    ./deploy.ps1 -UseTfvarsFile

    # Destroy resources using terraform
    ./deploy.ps1 -UseTfvarsFile -Destroy

.LINK
    https://github.com/PowerShell/PowerShell
    https://www.terraform.io/
    https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

.NOTES

    Prerequisites:
        - PowerShell 5.1 or later
        - Azure CLI
        - Terraform

    List all environment variables
    Get-ChildItem Env:

    History:
        1.0 - Inital version (Cory Stein)
        1.1 - Added support for azure-spn.tfvars (Cory Stein - 12/04/2018)

#>

param(
    [string] $WorkingDirectory = $PSScriptRoot,
    [string] $ProviderTfVarsFile = ".\azure-spn.tfvars",
    [string] $TfVarsFile,
    [switch] $RemoveBeforeInstall,
    [switch] $Destroy,
    [switch] $UseTfVarsFile,
    [switch] $VerifyOnly
)

###################################################################################
# IMPORTANT:  The below line must be included to enusre proper error handling
###################################################################################
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
###################################################################################

###################################################################################
# Script Requirements
###################################################################################
<#
if (-not($UseTfVarsFile)) {
    if (-not (Test-Path env:subscription_id)) { throw "Environment variable [subscription_id] is REQUIRED" }
    if (-not (Test-Path env:client_id)) { throw "Environment variable [client_id] is REQUIRED" }
    if (-not (Test-Path env:client_secret)) { throw "Environment variable [client_secret] is REQUIRED" }
    if (-not (Test-Path env:tenant_id)) { throw "Environment variable [tenant_id] is REQUIRED" }
}
#>

if ([String]::IsNullOrWhiteSpace($(Get-Command az -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition))) {
    throw "Azure CLI is missing" 
}

if ([String]::IsNullOrWhiteSpace($(Get-Command terraform -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition))) {
    throw "Terraform is missing" 
}

##################################################

###################################################################################
# BEGIN : Variables
###################################################################################
$DefaultTfVarsFile = "./terraform.tfvars"
###################################################################################
# BEGIN : Variables
###################################################################################

###################################################################################
# BEGIN : FUNCTIONS
###################################################################################

function main() {

    try {
        # (Start) Capture duration metrics
        $BuildTime = [Diagnostics.Stopwatch]::StartNew()


        Push-Location -Path $WorkingDirectory

        ###################################################################
        # Connect to Azure
        ###################################################################
        [Environment]::SetEnvironmentVariable("ADAL_PYTHON_SSL_NO_VERIFY", "1", "Process")
        [Environment]::SetEnvironmentVariable("AZURE_CLI_DISABLE_CONNECTION_VERIFICATION", "1", "Process")

        # Get provider file contents if exists
        $UseProviderTfVarsFile = $false
        if (Test-Path $ProviderTfVarsFile) {
            $tfvars = Get-Content -Path $ProviderTfVarsFile | ConvertFrom-StringData
            $subscription_id = $tfvars.subscription_id.Replace('"', '')
            $tenant_id = $tfvars.tenant_id.Replace('"', '')
            $client_id = $tfvars.client_id.Replace('"', '')
            $client_secret = $tfvars.client_secret.Replace('"', '')
            $UseProviderTfVarsFile = $true
        }

        # Log out
        try {
            az logout | Out-Null

            [Environment]::SetEnvironmentVariable("ARM_CLIENT_ID", "", "Process")
            [Environment]::SetEnvironmentVariable("ARM_CLIENT_SECRET", "", "Process")
            [Environment]::SetEnvironmentVariable("ARM_SUBSCRIPTION_ID", "", "Process")
            [Environment]::SetEnvironmentVariable("ARM_TENANT_ID", "", "Process")

            [Environment]::SetEnvironmentVariable("ARM_CLIENT_ID", "", "Machine")
            [Environment]::SetEnvironmentVariable("ARM_CLIENT_SECRET", "", "Machine")
            [Environment]::SetEnvironmentVariable("ARM_SUBSCRIPTION_ID", "", "Machine")
            [Environment]::SetEnvironmentVariable("ARM_TENANT_ID", "", "Machine")
        }
        catch {
            # Do nothing
        }

        <#
        if (-not($UseTfVarsFile)) {
            az login --service-principal -u "$($Env:client_id)" -p "$($Env:client_secret)" --tenant "$($Env:tenant_id)" --subscription $($Env:subscription_id)
            if ($LASTEXITCODE -ne 0) { throw "Failure logging in to Azure"}
        }
        else {
        #>
        Write-Warning "Logging into Azure using Tfvars info"
        az login --service-principal -u "$($client_id)" -p "$($client_secret)" --tenant "$($tenant_id)" --subscription $subscription_id
        if ($LASTEXITCODE -ne 0) { throw "Failure logging in to Azure"}
        Write-Output "Successfully logged into Azure" #-ForegroundColor Green

        az account set --subscription $subscription_id

        # Bug : Azure CLI token will not be recognized by Terraform.
        [Environment]::SetEnvironmentVariable("ARM_CLIENT_ID", $client_id, "Process")
        [Environment]::SetEnvironmentVariable("ARM_CLIENT_SECRET", $client_secret, "Process")
        [Environment]::SetEnvironmentVariable("ARM_SUBSCRIPTION_ID", $subscription_id, "Process")
        [Environment]::SetEnvironmentVariable("ARM_TENANT_ID", $tenant_id, "Process")
        #}
        ###################################################################


        ###################################################################
        # Input Values
        ###################################################################
        $azureRmContext = $(az account show) | ConvertFrom-Json
        $TenantId = $azureRmContext.tenantId
        $Account = $azureRmContext.user.name
        $SubscriptionId = $azureRmContext.id
        $SubscriptionName = $azureRmContext.name
        Write-Output "Account: ............................ [$($Account)]"
        Write-Output "Tenant Id: .......................... [$($TenantId)]"
        Write-Output "Subscription Id: .................... [$($SubscriptionId)]"    
        Write-Output "Subscription Name: .................. [$($SubscriptionName)]"  
        Write-Output "Remove Before Install: .............. [$($RemoveBeforeInstall)]" 
        Write-Output "Destroy: ............................ [$($Destroy)]" 
        Write-Output "Use Tfvars File: .................... [$($UseTfVarsFile)]" 
        Write-Output "Use Provider Tfvars File: ........... [$($UseProviderTfVarsFile)]" 
        Write-Output "Provider Tfvars File: ............... [$($ProviderTfVarsFile)]" 
        Write-Output "Tfvars File: ........................ [$($TfVarsFile)]" 
        Write-Output "Verify Only: ........................ [$($VerifyOnly)]" 
        ###################################################################


        ###################################################################
        # Create tfvars file
        ###################################################################
        if (-not([System.String]::IsNullOrWhiteSpace($TfVarsFile))) {
            Write-Warning "Creating terraform.tfvars file..."
            $CreatedTfVarsFile = $True
            if (Test-Path $DefaultTfVarsFile) { Remove-Item -Path $DefaultTfVarsFile -Force | Out-Null }
            Get-Content $ProviderTfVarsFile | Add-Content $DefaultTfVarsFile
            Get-Content $TfVarsFile | Add-Content $DefaultTfVarsFile
        }

        <#
        if (-not($UseTfVarsFile)) {
            if (Test-Path $TfVarsFile) { Remove-Item -Path $TfVarsFile -Force | Out-Null }
            $terraformvars = @" 
subscription_id = "$($Env:subscription_id)"
client_id = "$($Env:client_id)"
client_secret = "$($Env:client_secret)"
tenant_id = "$($Env:tenant_id)"
"@ 
            $terraformvars | Out-File -FilePath $TfVarsFile -Encoding ASCII -Force
        }
        else {
            Write-Warning "Using TfVars File"
        }
        #>
        ###################################################################

        # initialize Terraform
        if (-not(Test-Path "./terraform")) {
            terraform init
            if ($LASTEXITCODE -ne 0) { throw "Failure initializing terraform"}
        }

        if ($Destroy) {
            terraform destroy -auto-approve;
            return
        }
        
        # Used to download and update modules mentioned in the root module
        terraform get;

        # Used to validate the syntax of the terraform files
        terraform validate
        if ($LASTEXITCODE -ne 0) { throw "Failure validating terraform files"}

        # Used to create an execution plan
        terraform plan
        if ($LASTEXITCODE -ne 0) { throw "Failure executing terraform plan"}

        if (-not($VerifyOnly)) {
            # Used to apply the changes required to reach the desired state of the configuration, or the pre-determined set of actions generated by a terraform plan execution plan
            terraform apply -auto-approve
            if ($LASTEXITCODE -ne 0) { throw "Failure executing terraform apply"}
        }
        
        # Display execution duration
        $BuildTime.Stop()
        $TimeOutput = $BuildTime.Elapsed
        Write-Output "Total build time: [$($TimeOutput.Minutes)m $($TimeOutput.Seconds)s]"
    }
    catch {
        Write-Error $_.Exception.Message
        throw
    }
    finally {
        # Clean up
        if (-not($UseTfVarsFile) -or $CreatedTfVarsFile) {
            if (Test-Path .\terraform.tfvars) {
                Remove-Item -Path .\terraform.tfvars -Force | Out-Null
            }
        }

        Pop-Location
    }
} 

###################################################################################
# END : FUNCTIONS
###################################################################################

# Call main
main