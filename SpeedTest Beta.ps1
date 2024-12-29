param (
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$ScriptArgs
)

# Version
$CurrentVersion = '0.0.2'
$PowerShellGalleryName = 'speedtest'

# Suppress progress bars and confirmation prompts
$ProgressPreference = 'Continue'
$ConfirmPreference = 'None'

# ============================================================================ #
# Functions
# ============================================================================ #

# Display a progress bar
function Show-Progress {
    param (
        [string]$Activity,
        [int]$PercentComplete
    )
    Write-Progress -Activity $Activity -PercentComplete $PercentComplete
}

# Scrape the webpage to get the download link
function Get-SpeedTestDownloadLink {
    $url = "https://www.speedtest.net/apps/cli"
    Show-Progress -Activity "Fetching download link..." -PercentComplete 10
    $webContent = Invoke-WebRequest -Uri $url -UseBasicParsing
    if ($webContent.Content -match 'href="(https://install\.speedtest\.net/app/cli/ookla-speedtest-[\d\.]+-win64\.zip)"') {
        Show-Progress -Activity "Download link fetched." -PercentComplete 20
        return $matches[1]
    } else {
        Write-Error "Unable to find the win64 zip download link."
        return $null
    }
}

# Download the zip file
function Download-SpeedTestZip {
    param (
        [string]$downloadLink,
        [string]$destination
    )
    Show-Progress -Activity "Downloading SpeedTest CLI..." -PercentComplete 30
    Invoke-WebRequest -Uri $downloadLink -OutFile $destination -UseBasicParsing
    Show-Progress -Activity "Download complete." -PercentComplete 40
}

# Extract the zip file
function Extract-Zip {
    param (
        [string]$zipPath,
        [string]$destination
    )
    Show-Progress -Activity "Extracting zip file..." -PercentComplete 50
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $destination)
    Show-Progress -Activity "Extraction complete." -PercentComplete 70
}

# Run the speedtest executable
function Run-SpeedTest {
    param (
        [string]$executablePath,
        [array]$arguments
    )

    Show-Progress -Activity "Running SpeedTest..." -PercentComplete 80

    # Add necessary arguments if missing
    if (-not ($arguments -contains "--accept-license")) {
        $arguments += "--accept-license"
    }
    if (-not ($arguments -contains "--accept-gdpr")) {
        $arguments += "--accept-gdpr"
    }

    # Run the executable and capture output
    $output = & $executablePath $arguments
    Show-Progress -Activity "SpeedTest completed." -PercentComplete 90

    # Save results to a text file
    $timestamp = (Get-Date).ToString("yyyy-MM-dd_HH-mm-ss")
    $logFile = Join-Path -Path $PSScriptRoot -ChildPath "SpeedTestResults_$timestamp.txt"
    $output | Add-Content -Path $logFile

    Write-Output "==========================================="
    Write-Output " Speed Test Results:"
    Write-Output "==========================================="
    Write-Output $output
    Write-Output "==========================================="
    Write-Output "Results saved to: $logFile"
}

# Cleanup
function Remove-File {
    param (
        [string]$Path
    )
    try {
        if (Test-Path -Path $Path) {
            Remove-Item -Path $Path -Recurse -ErrorAction Stop
        }
    } catch {
        Write-Debug "Unable to remove item: $_"
    }
}

function Remove-Files {
    param(
        [string]$zipPath,
        [string]$folderPath
    )
    Remove-File -Path $zipPath
    Remove-File -Path $folderPath
}

# ============================================================================ #
# Main Script
# ============================================================================ #
try {
    $tempFolder = $env:TEMP
    $zipFilePath = Join-Path $tempFolder "speedtest-win64.zip"
    $extractFolderPath = Join-Path $tempFolder "speedtest-win64"

    Remove-Files -zipPath $zipFilePath -folderPath $extractFolderPath

    $downloadLink = Get-SpeedTestDownloadLink
    if (-not $downloadLink) {
        throw "Failed to retrieve the download link."
    }

    Write-Output "Starting SpeedTest CLI installation..."
    Download-SpeedTestZip -downloadLink $downloadLink -destination $zipFilePath

    Extract-Zip -zipPath $zipFilePath -destination $extractFolderPath

    $executablePath = Join-Path $extractFolderPath "speedtest.exe"
    Run-SpeedTest -executablePath $executablePath -arguments $ScriptArgs

    Write-Output "Cleaning up temporary files..."
    Remove-Files -zipPath $zipFilePath -folderPath $extractFolderPath

    Write-Output "==========================================="
    Write-Output " Speed test completed successfully! SpeedTest Deleted"
    Write-Output "==========================================="
} catch {
    Write-Error "An error occurred: $_"
}

# Keep the window open
Write-Output "Press Enter to close the window."
Read-Host
