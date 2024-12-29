# Script to download, use, and clean up Open Hardware Monitor for system temperature monitoring

# Step 1: Define paths and download Open Hardware Monitor if the DLL is not found
$ohmDll = ".\OpenHardwareMonitorLib.dll"
$ohmZipUrl = "https://openhardwaremonitor.org/files/openhardwaremonitor-v0.9.6.zip"
$ohmZipFile = ".\OpenHardwareMonitor.zip"
$ohmExtractPath = ".\OpenHardwareMonitor"

if (-Not (Test-Path $ohmDll)) {
    Write-Host "Open Hardware Monitor DLL not found. Attempting to download..."

    # Download the ZIP file
    Invoke-WebRequest -Uri $ohmZipUrl -OutFile $ohmZipFile
    Write-Host "Open Hardware Monitor downloaded as $ohmZipFile"

    # Extract the contents
    Expand-Archive -Path $ohmZipFile -DestinationPath $ohmExtractPath -Force
    Write-Host "Extracted Open Hardware Monitor files to $ohmExtractPath"

    # Locate the DLL file
    $ohmDllPath = Get-ChildItem -Path $ohmExtractPath -Recurse -Filter "OpenHardwareMonitorLib.dll" | Select-Object -ExpandProperty FullName
    if (-Not $ohmDllPath) {
        Write-Error "DLL file not found in the extracted archive. Exiting."
        exit
    } else {
        Copy-Item -Path $ohmDllPath -Destination $ohmDll -Force
        Write-Host "Located DLL and copied to working directory: $ohmDll"
    }
} else {
    Write-Host "Open Hardware Monitor DLL already exists at $ohmDll"
}

# Step 2: Load the Open Hardware Monitor library
Add-Type -Path $ohmDll

# Initialize the computer object
$computer = New-Object OpenHardwareMonitor.Hardware.Computer
$computer.Open()
$computer.CPUEnabled = $true
$computer.GPUEnabled = $true
$computer.RAMEnabled = $true

# Step 3: Function to read sensor data
function Get-SensorData {
    param (
        [OpenHardwareMonitor.Hardware.IHardware]$hardware
    )

    foreach ($sensor in $hardware.Sensors) {
        if ($sensor.SensorType -eq [OpenHardwareMonitor.Hardware.SensorType]::Temperature) {
            [PSCustomObject]@{
                Hardware    = $hardware.Name
                Sensor      = $sensor.Name
                Temperature = "{0:N1}" -f $sensor.Value + " °C"
            }
        }
    }
}

# Step 4: Collect and display temperature data
$sensorData = @()
foreach ($hardware in $computer.Hardware) {
    $hardware.Update()
    $sensorData += Get-SensorData -hardware $hardware
}

if ($sensorData.Count -eq 0) {
    Write-Host "No temperature data available."
} else {
    Write-Host "System Temperatures:" -ForegroundColor Green
    $sensorData | Format-Table -AutoSize
}

# Ensure the computer object is properly closed
$computer.Close()
$computer = $null
[GC]::Collect()
[GC]::WaitForPendingFinalizers()

Write-Host "Press Enter to clean up and exit." -ForegroundColor Yellow
Read-Host

# Cleanup: Delete the ZIP file, extracted folder, and DLL
Write-Host "Cleaning up temporary files..."

if (Test-Path $ohmZipFile) {
    Remove-Item -Path $ohmZipFile -Force
    Write-Host "Deleted ZIP file: $ohmZipFile"
}

if (Test-Path $ohmExtractPath) {
    Remove-Item -Path $ohmExtractPath -Recurse -Force
    Write-Host "Deleted extracted folder: $ohmExtractPath"
}

if (Test-Path $ohmDll) {
    Remove-Item -Path $ohmDll -Force
    Write-Host "Deleted DLL file: $ohmDll"
}

Write-Host "All temporary files deleted. Script completed."
