<#
.DESCRIPTION
    This script aids in creating an image using packer

.INPUTS

.OUTPUTS

.EXAMPLE
    # Build using variables file
    ./build.ps1 -VariablesFile "variables.json" -File "azurerm-centos-7.5.json"


.LINK
    https://github.com/PowerShell/PowerShell
    https://www.packer.io/
    https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

.NOTES

    Prerequisites:
        - PowerShell 5.1 or later
        - Azure CLI
        - Packer

    List all environment variables
    Get-ChildItem Env:

#>

param(
    [string] $WorkingDirectory = $PSScriptRoot,
    [string] $File,
    [string] $VariablesFile = "variables.json"
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

if ([String]::IsNullOrWhiteSpace($(Get-Command az -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition))) {
    throw "Azure CLI is missing" 
}

if ([String]::IsNullOrWhiteSpace($(Get-Command packer -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition))) {
    throw "Packer is missing" 
}
##################################################

###################################################################################
# BEGIN : FUNCTIONS
###################################################################################

function main() {

    try {
        # (Start) Capture duration metrics
        $BuildTime = [Diagnostics.Stopwatch]::StartNew()

        # Change to working directory
        Push-Location -Path $WorkingDirectory
        
        ###################################################################
        # Input Values (Script Parameters)
        ###################################################################
        Write-Output "Working Directory .......................... [$WorkingDirectory]" 
        Write-Output "File ....................................... [$File]" 
        Write-Output "Variables File: ............................ [$VariablesFile]" 
        ###################################################################

        # Get version
        $version = "0.0.0"
        if (Test-Path ".\version.json") {
            $data = Get-Content -Path ".\version.json" | ConvertFrom-Json
            $version = "{0}.{1}.{2}" -f $($data.Major), $($data.Minor), $($data.Patch)

        }
        Write-Output "Version: ................................... [$version]"

        # Check if using variables file
        $VariablesFileExist = $false
        if (Test-Path $VariablesFile) {
            $VariablesFileExist = $true
        }
        Write-Output "Variables File Exist: ...................... [$VariablesFileExist]"


        ###################################################################
        # Clear Azure Token
        ###################################################################
        az logout | Out-Null

        [Environment]::SetEnvironmentVariable("ARM_CLIENT_ID", "", "Process")
        [Environment]::SetEnvironmentVariable("ARM_CLIENT_SECRET", "", "Process")
        [Environment]::SetEnvironmentVariable("ARM_SUBSCRIPTION_ID", "", "Process")
        [Environment]::SetEnvironmentVariable("ARM_TENANT_ID", "", "Process")
        ###################################################################


        # Used to validate the syntax of the packer files
        Write-Output "Validating Packer Script..." #-ForegroundColor Cyan
        if (-not($VariablesFileExist)) {
            packer validate $File
        }
        else {
            packer validate --var-file=$VariablesFile $File
        }
        if ($LASTEXITCODE -ne 0) { throw "Failure validating packer files"}
        Write-Output "Successfully Validated Packer Script" #-ForegroundColor Green

        # Execute packer build
        Write-Output "Build using Packer..." #-ForegroundColor Cyan
        if (-not($VariablesFileExist)) {
            packer build $File
        }
        else {
            if ($version -ne "0.0.0") {
                packer build --var-file=$VariablesFile --var 'version=$version' $File 
            }
            else {
                packer build --var-file=$VariablesFile $File
            }
        }
        if ($LASTEXITCODE -ne 0) { throw "Failure executing packer build"}
        
        
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
        Pop-Location
    }
} 

###################################################################################
# END : FUNCTIONS
###################################################################################

# Call main
main