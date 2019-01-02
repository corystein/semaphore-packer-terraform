<#
.DESCRIPTION
    This script aids in deleting images using the Azure CLI

.INPUTS

.OUTPUTS

.EXAMPLE
    # Build using variables file
    ./image-cleanup.ps1 


.LINK
    https://docs.microsoft.com/en-us/cli/azure/image?view=azure-cli-latest#az-image-delete

.NOTES

    Prerequisites:
        - PowerShell 5.1 or later
        - Azure CLI

    List all environment variables
    Get-ChildItem Env:

#>


param(
    [string] $SubscriptionId,
    [string] $ResourceGroup = "PZI-GXUS-G-RGP-PADM-P001"
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

###################################################################################

###################################################################################
# BEGIN : FUNCTIONS
###################################################################################

function main() {
    try {

        if ([String]::IsNullOrWhiteSpace($SubscriptionId)) {
            $azureRmContext = $(az account show) | ConvertFrom-Json
            $SubscriptionId = $azureRmContext.id
        }
        #Write-Output "Subscription Id: .................... [$($SubscriptionId)]"    
        $result = az image list --resource-group $ResourceGroup --subscription "$($SubscriptionId)" | ConvertFrom-Json

        if ($result.Count -gt 0) {
            [int]$Deleted = 0
            $result | ForEach-Object {

                $StartDate = (GET-DATE)

                $EndDate = $_.tags.create_time
                Write-Verbose "Start Date: [$StartDate]"
                Write-Verbose "End Date: [$EndDate]"

                #$EndDate
                $EndDateParts = $EndDate.Split("-")
                #$EndDateParts
                $EndDateParts2 = $EndDateParts[2].Split("T")
                #$EndDateParts2
                $EndDatePart = "{0}/{1}/{2}" -f $EndDateParts[1], $EndDateParts2[0], $EndDateParts[0]

                $EndDatePart = [datetime]::parseexact($EndDatePart, 'MM/dd/yyyy', $null).ToString('MM/dd/yyyy')

                $ts = New-TimeSpan –Start $StartDate –End $EndDatePart
                #$ts.Days

                if ($ts.Days -le -7) {
                    Write-Warning "Image older than 7 days"
                    Write-Output "Deleting [$($_.name)]..."
                    az image delete --name "$($_.name)" --resource-group $ResourceGroup --subscription "$($SubscriptionId)"
                    $Deleted++
                }

                if ($Deleted -gt 0) {
                    Write-Warning "Deleted [$Deleted] images"
                    Write-Output "Completed deleting images"
                } 

                #$_.name
            }
            
            if ($Deleted -eq 0) {
                Write-Output "No images to delete"
            }
        }

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