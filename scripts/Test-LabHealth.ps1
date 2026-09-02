<#
.SYNOPSIS
    Lab Ortami Kapsamli Saglik Kontrolü ve Raporlama Scripti
.DESCRIPTION
    DC01, SRV01, DNS, Active Directory, DHCP ve File Server paylasimlarini kontrol eder.
    Sonuclari PASS, WARNING, FAIL olarak konsola yazar ve JSON/CSV ciktisi uretir.
#>

$ReportPath = "C:\LabReports"
if (!(Test-Path -Path $ReportPath)) { New-Item -ItemType Directory -Path $ReportPath | Out-Null }
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$JsonFile = "$ReportPath\LabHealthReport_$Timestamp.json"
$CsvFile  = "$ReportPath\LabHealthReport_$Timestamp.csv"

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()

function Add-CheckResult {
    param(
        [string]$TestName,
        [string]$Status, # PASS, WARNING, FAIL
        [string]$Details
    )
    
   
    switch ($Status) {
        "PASS"    { Write-Host "[PASS]    - $TestName : $Details" -ForegroundColor Green }
        "WARNING" { Write-Host "[WARNING] - $TestName : $Details" -ForegroundColor Yellow }
        "FAIL"    { Write-Host "[FAIL]    - $TestName : $Details" -ForegroundColor Red }
    }

    $Results.Add([PSCustomObject]@{
        Timestamp   = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        TestName    = $TestName
        Status      = $Status
        Details     = $Details
    })
}

Write-Host "=== Lab Ortami Saglik Taramasi Baslatiliyor... ===" -ForegroundColor Cyan


$DcIP = "10.30.0.10"
if (Test-Connection -ComputerName $DcIP -Count 1 -Quiet -ErrorAction SilentlyContinue) {
    Add-CheckResult -TestName "DC01 Erisilebilirligi" -Status "PASS" -Details "DC01 ($DcIP) aktif ve yanit veriyor."
} else {
    Add-CheckResult -TestName "DC01 Erisilebilirligi" -Status "FAIL" -Details "DC01 ($DcIP) adresine ulasilamiyor."
}


$SrvIP = "10.30.0.11"
if (Test-Connection -ComputerName $SrvIP -Count 1 -Quiet -ErrorAction SilentlyContinue) {
    Add-CheckResult -TestName "SRV01 Erisilebilirligi" -Status "PASS" -Details "SRV01 ($SrvIP) aktif ve yanit veriyor."
} else {
    Add-CheckResult -TestName "SRV01 Erisilebilirligi" -Status "FAIL" -Details "SRV01 ($SrvIP) adresine ulasilamiyor."
}


try {
    $DnsResult = Resolve-DnsName -Name "lab.test" -ErrorAction Stop
    if ($DnsResult) {
        Add-CheckResult -TestName "DNS lab.test Cozumlemesi" -Status "PASS" -Details "lab.test basariyla cozumlendi."
    } else {
        Add-CheckResult -TestName "DNS lab.test Cozumlemesi" -Status "WARNING" -Details "DNS sorgusu bos dondu."
    }
} catch {
    Add-CheckResult -TestName "DNS lab.test Cozumlemesi" -Status "FAIL" -Details "lab.test cozumlenemedi: $_"
}


try {
    $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
    Add-CheckResult -TestName "Active Directory Domain Erisimi" -Status "PASS" -Details "Domain aktif: $($Domain.Name)"
} catch {
    Add-CheckResult -TestName "Active Directory Domain Erisimi" -Status "FAIL" -Details "Domain erisim hatasi: $_"
}


try {
    $DhcpService = Get-Service -ComputerName "SRV01" -Name "DHCPServer" -ErrorAction Stop
    if ($DhcpService.Status -eq 'Running') {
        Add-CheckResult -TestName "DHCP Servis Durumu" -Status "PASS" -Details "DHCP Server servisi calisiyor."
    } else {
        Add-CheckResult -TestName "DHCP Servis Durumu" -Status "FAIL" -Details "DHCP Server servisi calismiyor (Durum: $($DhcpService.Status))."
    }
} catch {
    Add-CheckResult -TestName "DHCP Servis Durumu" -Status "FAIL" -Details "DHCP servisi sistemde bulunamadi veya erisilemedi."
}


$SharePath = "\\SRV01\Shares"
if (Test-Path -Path $SharePath) {
    Add-CheckResult -TestName "File Server Paylasim Erisimi" -Status "PASS" -Details "$SharePath paylasimina erisilebiliyor."
} else {
    Add-CheckResult -TestName "File Server Paylasim Erisimi" -Status "FAIL" -Details "$SharePath paylasimina erisilemedi veya henuz olusturulmadi."
}


try {
    $Leases = Get-DhcpServerv4Scope -ErrorAction SilentlyContinue | Get-DhcpServerv4Lease -ErrorAction SilentlyContinue
    if ($Leases) {
        $Cl01Lease = $Leases | Where-Object { $_.HostName -like "*CL01*" -or $_.ClientName -like "*CL01*" }
        if ($Cl01Lease) {
            Add-CheckResult -TestName "CL01 DHCP Lease Durumu" -Status "PASS" -Details "CL01 icin aktif IP kiralamasi bulundu (IP: $($Cl01Lease.IPAddress))."
        } else {
            Add-CheckResult -TestName "CL01 DHCP Lease Durumu" -Status "WARNING" -Details "DHCP tablosunda aktif kiralamalar var ancak CL01 adina ait kayit bulunamadi."
        }
    } else {
        Add-CheckResult -TestName "CL01 DHCP Lease Durumu" -Status "FAIL" -Details "Aktif DHCP scope veya kiralanan IP bulunamadi."
    }
} catch {
    Add-CheckResult -TestName "CL01 DHCP Lease Durumu" -Status "WARNING" -Details "DHCP scope/lease bilgileri okunamadi (Rol yuklu olmayabilir): $_"
}


$Results | ConvertTo-Json -Depth 3 | Out-File -FilePath $JsonFile -Encoding utf8
$Results | Export-Csv -Path $CsvFile -NoTypeInformation -Encoding utf8

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Raporlar basariyla kaydedildi:" -ForegroundColor Green
Write-Host " - JSON Raporu: $JsonFile"
Write-Host " - CSV Raporu:  $CsvFile"
Write-Host "================================================" -ForegroundColor Cyan