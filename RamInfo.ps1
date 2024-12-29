# Script to display RAM information

# Get RAM details
$memoryInfo = Get-CimInstance -ClassName Win32_PhysicalMemory

# Display details
Write-Host "======================"
Write-Host "RAM Information"
Write-Host "======================"

foreach ($memory in $memoryInfo) {
    Write-Host "Capacity (GB):" ([math]::Round($memory.Capacity / 1GB, 2))
    Write-Host "Speed (MHz):" $memory.Speed
    Write-Host "Manufacturer:" $memory.Manufacturer
    Write-Host "Part Number:" $memory.PartNumber
    Write-Host "Form Factor:" $memory.FormFactor
    Write-Host "======================"
}

# Display Total Physical Memory
$totalMemory = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty TotalPhysicalMemory
Write-Host "Total Physical Memory (GB):" ([math]::Round($totalMemory / 1GB, 2))
