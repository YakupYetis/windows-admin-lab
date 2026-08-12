$outputDir = $PSScriptRoot
if(-not $outputDir) {$outputDir = Get-Location}
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$jsonFile = Join-Path $outputDir "SystemInfo_$timestamp.json"
$csvFile = Join-Path $outputDir "SystemInfo_$timestamp.csv"


$os = Get-CimInstance Win32_OperatingSystem
$cpu = Get-CimInstance Win32_Processor


$totalVisibleGB = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freePhysicalGB = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedPhysicalGB = [Math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 2)


$activeAdapters = Get-NetAdapter | Where-Object Status -eq 'Up'
$ips = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -ne '127.0.0.1'}).IPAddress


$disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
$diskInfo = foreach ($disk in $disks){
    [PSCustomObject]@{
        DriveLetter = $disk.DeviceID
        TotalSizeGB = [Math]::Round($disk.Size / 1GB, 2)
        FreeSpaceGB = [Math]::Round($disk.FreeSpace / 1GB, 2)
        UsedSpaceGB = [Math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)

    }
}


$rebootRequired = $false
if ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") -or 
    (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired")  -or 
    (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name "PendingFileRenameOperations" -ErrorAction SilentlyContinue)) {
     $rebootRequired = $true   
    <# Action to perform if the condition is true #>
}

$runningServicesCount = (Get-Service | Where-Object Status -eq 'Running'.Count)

$systemData = [PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    OperatingSystem = $os.Caption
    OSVersion = $os.Version
    LastBootTime = $os.LastBootUpTime
    IPAdresses = ($ips -join ', ')
    ActiveAdapters = ($activeAdapters.Name -join ', ')
    CPU = $cpu.Name
    TotalRAM_GB = $totalVisibleGB
    UsedRam_GB = $usedPhysicalGB
    FreeRam_GB = $freePhysicalGB
    Disks = $diskInfo
    RunningervicesCount = $runningServicesCount
    RebootRequired = $rebootRequired
}


$systemData | Format-List
$systemData | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonFile -Encoding utf8
$csvData = [PSCustomObject]@{
    ComputerName = $systemData.ComputerName
    OperatingSystem = $systemData.OperatingSystem
    OSVersion = $systemData.OSVersion
    LastBootTime = $systemData.LastBootTime
    ActiveAdapters = $systemData.ActiveAdapters
    CPU = $systemData.CPU 
    TotalRAM_GB = $systemData.TotalRAM_GB
    UsedRam_GB = $systemData.UsedRam_GB
    FreeRam_GB = $systemData.FreeRam_GB
    RebootRequired = $systemData.RebootRequired

}
$csvData | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
