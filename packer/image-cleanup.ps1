<#
.DESCRIPTION
    This script aids in retrieving and deleting images using the Azure CLI

.INPUTS

.OUTPUTS

.EXAMPLE
    # Remove images
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
    [string] $ResourceGroup = "PZI-GXUS-G-RGP-PADM-P001",
    [int] $DaysToDelete = 7,
    [string] $ImagePattern = "semaphore",
    [switch] $KeepOnlyLatest
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
function Get-PackerImages {
    param(
        $SubscriptionId,
        $ResourceGroupName,
        $Pattern
    )

    Process {
        # Get list of images from resource group
        $result = az image list --resource-group $ResourceGroup --subscription "$($SubscriptionId)" | ConvertFrom-Json


        # Enumerate through list
        $objectCollection = @()
        if ($result.Count -gt 0) {
            $result | ForEach-Object {
                #$_

                # Create object
                $object = New-Object PSObject
                Add-Member -InputObject $object -MemberType NoteProperty -Name Name -Value ""
                Add-Member -InputObject $object -MemberType NoteProperty -Name DateCreated -Value ""
                
                ######################################
                # START : Construct Date
                ######################################
                $EndDate = $_.tags.create_time
                $EndDateParts = $EndDate.Split("-")
                $EndDateParts2 = $EndDateParts[2].Split("T")
                $Hour = $EndDateParts2[1].Substring(0, 2)
                $Minute = $EndDateParts2[1].Substring(2, 2)
                $HourMinute = "{0}:{1}" -f $Hour, $Minute
                $EndDateTime = "{0:hh:mm tt}" -f [datetime]$HourMinute
                $EndDatePart = [datetime]$("{0}/{1}/{2} {3}" -f $EndDateParts[1], $EndDateParts2[0], $EndDateParts[0], $EndDateTime)
                ######################################
                # END : Construct Date
                ######################################

                # Add value to properties
                $object.Name = $_.name
                $object.DateCreated = $EndDatePart

                # Add object to collection
                if ($_.name -like "*$($Pattern)*") {
                    $objectCollection += $object
                }
            }
        }

        return $objectCollection

    }
}

function Get-LatestPackerImage {
    param(
        $imageList,
        $pattern
    )

    Process {
        return $($imageList | Sort-Object DateCreated | Select-Object -Last 1 | Select-Object -Property Name).Name
    }
}

function main() {
    try {

        # Get subscription id from current token/session
        if ([String]::IsNullOrWhiteSpace($SubscriptionId)) {
            $azureRmContext = $(az account show) | ConvertFrom-Json
            $SubscriptionId = $azureRmContext.id
        }

        ###################################################################
        # Display Parameter Values
        ###################################################################
        Write-Output "Subscription Id: ......................... [$($SubscriptionId)]"
        Write-Output "Resource Group Name: ..................... [$($ResourceGroup)]"
        Write-Output "Days To Delete: .......................... [$($DaysToDelete)]"
        Write-Output "Keep Only Latest: ........................ [$($KeepOnlyLatest)]" 
        Write-Output "Pattern: ................................. [$($ImagePattern)]" 
        ###################################################################

        <#
        # Get list of images from resource group
        $result = az image list --resource-group $ResourceGroup --subscription "$($SubscriptionId)" | ConvertFrom-Json

        # Enumerate through list
        $objectCollection = @()
        if ($result.Count -gt 0) {
            $result | ForEach-Object {
                #$_

                # Create object
                $object = New-Object PSObject
                Add-Member -InputObject $object -MemberType NoteProperty -Name Name -Value ""
                Add-Member -InputObject $object -MemberType NoteProperty -Name DateCreated -Value ""
                
                ######################################
                # START : Construct Date
                ######################################
                $EndDate = $_.tags.create_time
                $EndDateParts = $EndDate.Split("-")
                $EndDateParts2 = $EndDateParts[2].Split("T")
                $Hour = $EndDateParts2[1].Substring(0, 2)
                $Minute = $EndDateParts2[1].Substring(2, 2)
                $HourMinute = "{0}:{1}" -f $Hour, $Minute
                $EndDateTime = "{0:hh:mm tt}" -f [datetime]$HourMinute
                $EndDatePart = [datetime]$("{0}/{1}/{2} {3}" -f $EndDateParts[1], $EndDateParts2[0], $EndDateParts[0], $EndDateTime)
                ######################################
                # END : Construct Date
                ######################################

                # Add value to properties
                $object.Name = $_.name
                $object.DateCreated = $EndDatePart

                # Add object to collection
                $objectCollection += $object
            }
        }
        #>

        $packerImages = Get-PackerImages -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroup -Pattern $ImagePattern

        # Get most recent image
        #$LatestImage = $($objectCollection | Sort-Object DateCreated | Select-Object -Last 1 | Select-Object -Property Name).Name
        $LatestImage = Get-LatestPackerImage -imageList $packerImages

        ############################################################
        # START : Process images for deletion
        ############################################################
        [int]$Deleted = 0
        $StartDate = (GET-DATE)

        if ($KeepOnlyLatest) {
            Write-Verbose "Deleting all images except latest"
            $packerImages | Where-Object { $_.Name -ne $LatestImage } | ForEach-Object {
                Write-Output "Deleting image [$($_.name)]..."
                az image delete --name "$($_.name)" --resource-group $ResourceGroup --subscription "$($SubscriptionId)"
                $Deleted++
                Write-Output "Successfully deleted image"
            }
        }
        else {
            Write-Verbose "Deleting images older than days specified"
            $packerImages | ForEach-Object {
                $ts = New-TimeSpan –Start $StartDate –End $EndDatePart
                if ($ts.Days -le ($DaysToDelete * -1)) {
                    Write-Warning "Image older than $DaysToDelete day(s)"
                    Write-Output "Deleting image [$($_.name)]..."
                    az image delete --name "$($_.name)" --resource-group $ResourceGroup --subscription "$($SubscriptionId)"
                    $Deleted++
                    Write-Output "Successfully deleted image"
                }
            }
        }

        # Display number of images deleted
        if ($Deleted -gt 0) {
            Write-Warning "Deleted [$Deleted] images"
            Write-Output "Completed deleting images"
        }
        else {
            Write-Output "No images to delete"
        }
        ############################################################
        # END : Process images for deletion
        ############################################################

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