


# ============================================================
# AYARLAR
# ============================================================

$ReportPath = "\\SRV01\Shares\LabHealth"
$LogPath    = "$ReportPath\HealthLogs"

$DcName = "DC01"
$DcIP   = "10.30.0.10"

$SrvName = "SRV01"
$SrvIP   = "10.30.0.11"

$ClientName = "CL01"

$DomainName = "lab.test"

$SharePath = "\\SRV01\Shares"

$RetentionDays = 5


# ============================================================
# KLASORLER
# ============================================================

try {

    if (!(Test-Path -Path $ReportPath)) {
        New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
    }

    if (!(Test-Path -Path $LogPath)) {
        New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
    }

}
catch {

    Write-Host ""
    Write-Host "Rapor klasorune erisilemiyor: $ReportPath" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}


# ============================================================
# DOSYA ISIMLERI
# ============================================================

$CurrentDate = Get-Date -Format "yyyy-MM-dd"

$JsonFile = Join-Path $LogPath "LabHealth_$CurrentDate.json"
$CsvFile  = Join-Path $LogPath "LabHealth_$CurrentDate.csv"


# ============================================================
# SONUC LISTESI
# ============================================================

$Results = [System.Collections.Generic.List[PSCustomObject]]::new()


# ============================================================
# KONTROL SONUCU EKLEME
# ============================================================

function Add-CheckResult {

    param(
        [string]$Category,
        [string]$TestName,
        [string]$Status,
        [string]$Details
    )

    switch ($Status) {

        "PASS" {
            Write-Host "[PASS]    - $Category / $TestName : $Details" `
                -ForegroundColor Green
        }

        "WARNING" {
            Write-Host "[WARNING] - $Category / $TestName : $Details" `
                -ForegroundColor Yellow
        }

        "FAIL" {
            Write-Host "[FAIL]    - $Category / $TestName : $Details" `
                -ForegroundColor Red
        }
    }

    $Results.Add(
        [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Category  = $Category
            TestName  = $TestName
            Status    = $Status
            Details   = $Details
        }
    )
}


# ============================================================
# BASLANGIC
# ============================================================

$StartTime = Get-Date

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host " LAB ORTAMI KAPSAMLI SAGLIK TARAMASI" `
    -ForegroundColor Cyan

Write-Host " Tarih: $($StartTime.ToString('yyyy-MM-dd HH:mm:ss'))" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""


# ============================================================
# 1. DC01
# ============================================================

if (
    Test-Connection `
        -ComputerName $DcIP `
        -Count 1 `
        -Quiet `
        -ErrorAction SilentlyContinue
) {

    Add-CheckResult `
        -Category "DC01" `
        -TestName "Erisilebilirlik" `
        -Status "PASS" `
        -Details "DC01 ($DcIP) aktif ve yanit veriyor."

}
else {

    Add-CheckResult `
        -Category "DC01" `
        -TestName "Erisilebilirlik" `
        -Status "FAIL" `
        -Details "DC01 ($DcIP) adresine ulasilamiyor."
}


# ============================================================
# 2. SRV01
# ============================================================

if (
    Test-Connection `
        -ComputerName $SrvIP `
        -Count 1 `
        -Quiet `
        -ErrorAction SilentlyContinue
) {

    Add-CheckResult `
        -Category "SRV01" `
        -TestName "Erisilebilirlik" `
        -Status "PASS" `
        -Details "SRV01 ($SrvIP) aktif ve yanit veriyor."

}
else {

    Add-CheckResult `
        -Category "SRV01" `
        -TestName "Erisilebilirlik" `
        -Status "FAIL" `
        -Details "SRV01 ($SrvIP) adresine ulasilamiyor."
}


# ============================================================
# 3. DNS
# ============================================================

try {

    $DnsResult = Resolve-DnsName `
        -Name $DomainName `
        -ErrorAction Stop

    if ($DnsResult) {

        Add-CheckResult `
            -Category "DNS" `
            -TestName "Domain Cozumlemesi" `
            -Status "PASS" `
            -Details "$DomainName basariyla cozumlendi."

    }
    else {

        Add-CheckResult `
            -Category "DNS" `
            -TestName "Domain Cozumlemesi" `
            -Status "WARNING" `
            -Details "DNS sorgusu bos sonuc verdi."
    }

}
catch {

    Add-CheckResult `
        -Category "DNS" `
        -TestName "Domain Cozumlemesi" `
        -Status "FAIL" `
        -Details "$DomainName cozulemedi: $($_.Exception.Message)"
}


# DNS SRV kaydi
try {

    $DnsSrv = Resolve-DnsName `
        -Name "_ldap._tcp.dc._msdcs.$DomainName" `
        -Type SRV `
        -ErrorAction Stop

    if ($DnsSrv) {

        Add-CheckResult `
            -Category "DNS" `
            -TestName "AD SRV Kayitlari" `
            -Status "PASS" `
            -Details "LDAP/AD SRV kaydi basariyla bulundu."

    }

}
catch {

    Add-CheckResult `
        -Category "DNS" `
        -TestName "AD SRV Kayitlari" `
        -Status "FAIL" `
        -Details "AD SRV kaydi bulunamadi."
}


# ============================================================
# 4. ACTIVE DIRECTORY
# ============================================================

try {

    $Domain = `
        [System.DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()

    Add-CheckResult `
        -Category "AD" `
        -TestName "Domain Erisimi" `
        -Status "PASS" `
        -Details "Active Directory domain aktif: $($Domain.Name)"

}
catch {

    Add-CheckResult `
        -Category "AD" `
        -TestName "Domain Erisimi" `
        -Status "FAIL" `
        -Details "Active Directory domain erisimi basarisiz: $($_.Exception.Message)"
}


# DC Discovery
try {

    $DcDiscovery = nltest /dsgetdc:$DomainName 2>&1

    if ($LASTEXITCODE -eq 0) {

        Add-CheckResult `
            -Category "AD" `
            -TestName "Domain Controller Discovery" `
            -Status "PASS" `
            -Details "Domain Controller discovery basarili."

    }
    else {

        Add-CheckResult `
            -Category "AD" `
            -TestName "Domain Controller Discovery" `
            -Status "FAIL" `
            -Details "Domain Controller discovery basarisiz."

    }

}
catch {

    Add-CheckResult `
        -Category "AD" `
        -TestName "Domain Controller Discovery" `
        -Status "FAIL" `
        -Details "nltest calistirilamadi."
}


# ============================================================
# 5. DHCP
# ============================================================

try {

    $DhcpService = Get-Service `
        -ComputerName $SrvName `
        -Name "DHCPServer" `
        -ErrorAction Stop

    if ($DhcpService.Status -eq "Running") {

        Add-CheckResult `
            -Category "DHCP" `
            -TestName "DHCP Server Servisi" `
            -Status "PASS" `
            -Details "SRV01 uzerindeki DHCP Server servisi calisiyor."

    }
    else {

        Add-CheckResult `
            -Category "DHCP" `
            -TestName "DHCP Server Servisi" `
            -Status "FAIL" `
            -Details "DHCP Server servisi calismiyor. Durum: $($DhcpService.Status)"
    }

}
catch {

    Add-CheckResult `
        -Category "DHCP" `
        -TestName "DHCP Server Servisi" `
        -Status "FAIL" `
        -Details "DHCP Server servisine erisilemedi: $($_.Exception.Message)"
}


# DHCP Scope
try {

    $Scopes = Get-DhcpServerv4Scope `
        -ComputerName $SrvName `
        -ErrorAction Stop

    if ($Scopes) {

        $ActiveScopes = $Scopes |
            Where-Object { $_.State -eq "Active" }

        if ($ActiveScopes) {

            Add-CheckResult `
                -Category "DHCP" `
                -TestName "DHCP Scope" `
                -Status "PASS" `
                -Details "$($ActiveScopes.Count) aktif DHCP scope bulundu."

        }
        else {

            Add-CheckResult `
                -Category "DHCP" `
                -TestName "DHCP Scope" `
                -Status "WARNING" `
                -Details "DHCP scope bulundu ancak aktif scope bulunamadi."
        }

    }
    else {

        Add-CheckResult `
            -Category "DHCP" `
            -TestName "DHCP Scope" `
            -Status "FAIL" `
            -Details "DHCP scope bulunamadi."
    }

}
catch {

    Add-CheckResult `
        -Category "DHCP" `
        -TestName "DHCP Scope" `
        -Status "WARNING" `
        -Details "DHCP scope bilgileri okunamadi: $($_.Exception.Message)"
}


# CL01 Lease
try {

    $Cl01Lease = $null

    foreach ($Scope in $Scopes) {

        try {

            $Leases = Get-DhcpServerv4Lease `
                -ComputerName $SrvName `
                -ScopeId $Scope.ScopeId `
                -ErrorAction Stop

            $FoundLease = $Leases |
                Where-Object {
                    $_.HostName -like "*$ClientName*" -or
                    $_.ClientName -like "*$ClientName*"
                }

            if ($FoundLease) {

                $Cl01Lease = $FoundLease
                break
            }

        }
        catch {
            continue
        }
    }


    if ($Cl01Lease) {

        $LeaseIP = ($Cl01Lease | Select-Object -First 1).IPAddress

        Add-CheckResult `
            -Category "DHCP" `
            -TestName "CL01 Lease" `
            -Status "PASS" `
            -Details "CL01 icin aktif DHCP lease bulundu. IP: $LeaseIP"

    }
    else {

        Add-CheckResult `
            -Category "DHCP" `
            -TestName "CL01 Lease" `
            -Status "WARNING" `
            -Details "CL01 adina aktif DHCP lease bulunamadi."
    }

}
catch {

    Add-CheckResult `
        -Category "DHCP" `
        -TestName "CL01 Lease" `
        -Status "WARNING" `
        -Details "CL01 DHCP lease kontrolu yapilamadi."
}


# ============================================================
# 6. SMB / FILE SERVER
# ============================================================

try {

    if (Test-Path $SharePath -ErrorAction Stop) {

        Add-CheckResult `
            -Category "SMB" `
            -TestName "File Share Erisimi" `
            -Status "PASS" `
            -Details "$SharePath paylasimina erisilebiliyor."

    }
    else {

        Add-CheckResult `
            -Category "SMB" `
            -TestName "File Share Erisimi" `
            -Status "FAIL" `
            -Details "$SharePath paylasimina erisilemiyor."
    }

}
catch {

    Add-CheckResult `
        -Category "SMB" `
        -TestName "File Share Erisimi" `
        -Status "FAIL" `
        -Details "SMB share kontrolu basarisiz: $($_.Exception.Message)"
}


# SMB port
try {

    $SmbConnection = Test-NetConnection `
        -ComputerName $SrvIP `
        -Port 445 `
        -WarningAction SilentlyContinue

    if ($SmbConnection.TcpTestSucceeded) {

        Add-CheckResult `
            -Category "SMB" `
            -TestName "TCP 445" `
            -Status "PASS" `
            -Details "SRV01 TCP 445 uzerinden SMB baglantisi kabul ediyor."

    }
    else {

        Add-CheckResult `
            -Category "SMB" `
            -TestName "TCP 445" `
            -Status "FAIL" `
            -Details "SRV01 TCP 445 portuna erisilemiyor."
    }

}
catch {

    Add-CheckResult `
        -Category "SMB" `
        -TestName "TCP 445" `
        -Status "FAIL" `
        -Details "TCP 445 kontrolu yapilamadi."
}


# LanmanServer
try {

    $SmbService = Get-Service `
        -ComputerName $SrvName `
        -Name "LanmanServer" `
        -ErrorAction Stop

    if ($SmbService.Status -eq "Running") {

        Add-CheckResult `
            -Category "SMB" `
            -TestName "Server Service" `
            -Status "PASS" `
            -Details "LanmanServer servisi calisiyor."

    }
    else {

        Add-CheckResult `
            -Category "SMB" `
            -TestName "Server Service" `
            -Status "FAIL" `
            -Details "LanmanServer servisi calismiyor."
    }

}
catch {

    Add-CheckResult `
        -Category "SMB" `
        -TestName "Server Service" `
        -Status "WARNING" `
        -Details "LanmanServer servisi kontrol edilemedi."
}


# ============================================================
# 7. WEF
# ============================================================

# Collector
try {

    $WecService = Get-Service `
        -ComputerName $SrvName `
        -Name "Wecsvc" `
        -ErrorAction Stop

    if ($WecService.Status -eq "Running") {

        Add-CheckResult `
            -Category "WEF" `
            -TestName "Windows Event Collector" `
            -Status "PASS" `
            -Details "SRV01 Windows Event Collector servisi calisiyor."

    }
    else {

        Add-CheckResult `
            -Category "WEF" `
            -TestName "Windows Event Collector" `
            -Status "FAIL" `
            -Details "Windows Event Collector servisi calismiyor."
    }

}
catch {

    Add-CheckResult `
        -Category "WEF" `
        -TestName "Windows Event Collector" `
        -Status "FAIL" `
        -Details "Windows Event Collector servisi kontrol edilemedi."
}


# ForwardedEvents
try {

    $ForwardedLog = Get-WinEvent `
        -ListLog "ForwardedEvents" `
        -ComputerName $SrvName `
        -ErrorAction Stop

    if ($ForwardedLog.IsEnabled) {

        if ($ForwardedLog.RecordCount -gt 0) {

            Add-CheckResult `
                -Category "WEF" `
                -TestName "ForwardedEvents" `
                -Status "PASS" `
                -Details "ForwardedEvents aktif. Kayit sayisi: $($ForwardedLog.RecordCount)"

        }
        else {

            Add-CheckResult `
                -Category "WEF" `
                -TestName "ForwardedEvents" `
                -Status "WARNING" `
                -Details "ForwardedEvents aktif ancak henuz event bulunmuyor."

        }

    }
    else {

        Add-CheckResult `
            -Category "WEF" `
            -TestName "ForwardedEvents" `
            -Status "FAIL" `
            -Details "ForwardedEvents logu aktif degil."
    }

}
catch {

    Add-CheckResult `
        -Category "WEF" `
        -TestName "ForwardedEvents" `
        -Status "WARNING" `
        -Details "ForwardedEvents logu okunamadi: $($_.Exception.Message)"
}


# WEF Subscription
try {

    $SubscriptionOutput = wecutil gr lab 2>&1

    if ($LASTEXITCODE -eq 0) {

        Add-CheckResult `
            -Category "WEF" `
            -TestName "Subscription lab" `
            -Status "PASS" `
            -Details "WEF 'lab' subscription sorgulanabiliyor."

    }
    else {

        Add-CheckResult `
            -Category "WEF" `
            -TestName "Subscription lab" `
            -Status "WARNING" `
            -Details "WEF 'lab' subscription sorgulanamadi."

    }

}
catch {

    Add-CheckResult `
        -Category "WEF" `
        -TestName "Subscription lab" `
        -Status "WARNING" `
        -Details "WEF subscription kontrolu yapilamadi."
}


# ============================================================
# 8. LAPS
# ============================================================

# CL01 registry policy kontrolu
try {

    $LapsRegistry = Get-ItemProperty `
        -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\LAPS" `
        -ErrorAction Stop


    if ($LapsRegistry.BackupDirectory -eq 2) {

        Add-CheckResult `
            -Category "LAPS" `
            -TestName "AD Backup Policy" `
            -Status "PASS" `
            -Details "Windows LAPS parolalari Active Directory'ye yedekleyecek sekilde yapilandirilmis."

    }
    else {

        Add-CheckResult `
            -Category "LAPS" `
            -TestName "AD Backup Policy" `
            -Status "WARNING" `
            -Details "LAPS BackupDirectory degeri AD backup icin beklenen 2 degerinde degil."

    }


    # Encryption
    if ($LapsRegistry.ADPasswordEncryptionEnabled -eq 1) {

        Add-CheckResult `
            -Category "LAPS" `
            -TestName "Password Encryption" `
            -Status "PASS" `
            -Details "LAPS AD password encryption aktif."

    }
    else {

        Add-CheckResult `
            -Category "LAPS" `
            -TestName "Password Encryption" `
            -Status "WARNING" `
            -Details "LAPS AD password encryption aktif degil."

    }


    # AdministratorAccountName
    if (
        [string]::IsNullOrWhiteSpace(
            $LapsRegistry.AdministratorAccountName
        )
    ) {

        Add-CheckResult `
            -Category "LAPS" `
            -TestName "Administrator Account" `
            -Status "PASS" `
            -Details "AdministratorAccountName bos; Windows LAPS built-in Administrator hesabini SID/RID 500 ile yonetiyor."

    }
    else {

        Add-CheckResult `
            -Category "LAPS" `
            -TestName "Administrator Account" `
            -Status "WARNING" `
            -Details "LAPS belirli bir administrator account adi icin yapilandirilmis: $($LapsRegistry.AdministratorAccountName)"
    }

}
catch {

    Add-CheckResult `
        -Category "LAPS" `
        -TestName "LAPS Policy" `
        -Status "FAIL" `
        -Details "Windows LAPS policy registry bilgileri okunamadi."
}


# LAPS Event Log
try {

    $LapsEvents = Get-WinEvent `
        -ComputerName $ClientName `
        -LogName "Microsoft-Windows-LAPS/Operational" `
        -MaxEvents 10 `
        -ErrorAction Stop

    if ($LapsEvents) {

        $SuccessEvent = $LapsEvents |
            Where-Object { $_.Id -eq 10004 } |
            Select-Object -First 1

        if ($SuccessEvent) {

            Add-CheckResult `
                -Category "LAPS" `
                -TestName "Policy Processing" `
                -Status "PASS" `
                -Details "CL01 uzerinde basarili LAPS policy processing eventi bulundu."

        }
        else {

            Add-CheckResult `
                -Category "LAPS" `
                -TestName "Policy Processing" `
                -Status "WARNING" `
                -Details "CL01 LAPS logunda son olaylar arasinda 10004 basari eventi bulunamadi."
        }

    }

}
catch {

    Add-CheckResult `
        -Category "LAPS" `
        -TestName "Policy Processing" `
        -Status "WARNING" `
        -Details "CL01 LAPS Operational logu okunamadi."
}


# ============================================================
# 9. FIREWALL
# ============================================================

try {

    $FirewallProfiles = Get-NetFirewallProfile

    $DisabledProfiles = $FirewallProfiles |
        Where-Object { $_.Enabled -ne $true }

    if (!$DisabledProfiles) {

        Add-CheckResult `
            -Category "Firewall" `
            -TestName "Firewall Profiles" `
            -Status "PASS" `
            -Details "Domain, Private ve Public firewall profillerinin tamami aktif."

    }
    else {

        $Names = $DisabledProfiles.Name -join ", "

        Add-CheckResult `
            -Category "Firewall" `
            -TestName "Firewall Profiles" `
            -Status "WARNING" `
            -Details "Devre disi firewall profilleri: $Names"
    }

}
catch {

    Add-CheckResult `
        -Category "Firewall" `
        -TestName "Firewall Profiles" `
        -Status "FAIL" `
        -Details "Firewall profilleri okunamadi."
}


# Default inbound policy
try {

    $FirewallProfiles = Get-NetFirewallProfile

    $BadInbound = $FirewallProfiles |
        Where-Object {
            $_.Enabled -eq $true -and
            $_.DefaultInboundAction -ne "Block"
        }

    if (!$BadInbound) {

        Add-CheckResult `
            -Category "Firewall" `
            -TestName "Default Inbound Policy" `
            -Status "PASS" `
            -Details "Aktif firewall profillerinde varsayilan inbound action Block."

    }
    else {

        $Names = $BadInbound.Name -join ", "

        Add-CheckResult `
            -Category "Firewall" `
            -TestName "Default Inbound Policy" `
            -Status "WARNING" `
            -Details "$Names profilinde varsayilan inbound policy Block degil."
    }

}
catch {

    Add-CheckResult `
        -Category "Firewall" `
        -TestName "Default Inbound Policy" `
        -Status "WARNING" `
        -Details "Firewall inbound policy okunamadi."
}


# ============================================================
# 10. MICROSOFT DEFENDER
# ============================================================

try {

    $Defender = Get-MpComputerStatus -ErrorAction Stop

    if ($Defender.AntivirusEnabled) {

        Add-CheckResult `
            -Category "Defender" `
            -TestName "Antivirus" `
            -Status "PASS" `
            -Details "Microsoft Defender Antivirus aktif."

    }
    else {

        Add-CheckResult `
            -Category "Defender" `
            -TestName "Antivirus" `
            -Status "FAIL" `
            -Details "Microsoft Defender Antivirus aktif degil."
    }


    if ($Defender.RealTimeProtectionEnabled) {

        Add-CheckResult `
            -Category "Defender" `
            -TestName "Real-Time Protection" `
            -Status "PASS" `
            -Details "Real-Time Protection aktif."

    }
    else {

        Add-CheckResult `
            -Category "Defender" `
            -TestName "Real-Time Protection" `
            -Status "FAIL" `
            -Details "Real-Time Protection aktif degil."
    }


    if ($Defender.AntivirusSignatureAge -le 7) {

        Add-CheckResult `
            -Category "Defender" `
            -TestName "Signature Age" `
            -Status "PASS" `
            -Details "Defender signature yasi $($Defender.AntivirusSignatureAge) gun."

    }
    else {

        Add-CheckResult `
            -Category "Defender" `
            -TestName "Signature Age" `
            -Status "WARNING" `
            -Details "Defender signature yasi $($Defender.AntivirusSignatureAge) gun."
    }

}
catch {

    Add-CheckResult `
        -Category "Defender" `
        -TestName "Defender Status" `
        -Status "WARNING" `
        -Details "Microsoft Defender durumu okunamadi: $($_.Exception.Message)"
}


# ============================================================
# GENEL DURUM
# ============================================================

$PassCount = @(
    $Results | Where-Object { $_.Status -eq "PASS" }
).Count

$WarningCount = @(
    $Results | Where-Object { $_.Status -eq "WARNING" }
).Count

$FailCount = @(
    $Results | Where-Object { $_.Status -eq "FAIL" }
).Count


if ($FailCount -gt 0) {

    $OverallStatus = "FAIL"

}
elseif ($WarningCount -gt 0) {

    $OverallStatus = "WARNING"

}
else {

    $OverallStatus = "PASS"
}


# ============================================================
# JSON ENTRY
# ============================================================

$JsonEntry = [PSCustomObject]@{

    Timestamp     = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
    Computer      = $env:COMPUTERNAME
    OverallStatus = $OverallStatus

    Summary = [PSCustomObject]@{
        PASS    = $PassCount
        WARNING = $WarningCount
        FAIL    = $FailCount
        TOTAL   = $Results.Count
    }

    Checks = $Results
}


# ============================================================
# CSV
# ============================================================

if (!(Test-Path $CsvFile)) {

    $Results |
        Export-Csv `
            -Path $CsvFile `
            -NoTypeInformation `
            -Encoding UTF8

}
else {

    $Results |
        Export-Csv `
            -Path $CsvFile `
            -NoTypeInformation `
            -Encoding UTF8 `
            -Append
}


# ============================================================
# JSON
# ============================================================

$ExistingJson = @()

if (Test-Path $JsonFile) {

    try {

        $JsonContent = Get-Content `
            -Path $JsonFile `
            -Raw `
            -ErrorAction Stop

        if ($JsonContent.Trim()) {

            $ExistingJson = @(
                $JsonContent | ConvertFrom-Json
            )
        }

    }
    catch {

        $ExistingJson = @()
    }
}


$ExistingJson += $JsonEntry


$ExistingJson |
    ConvertTo-Json -Depth 8 |
    Out-File `
        -FilePath $JsonFile `
        -Encoding UTF8


# ============================================================
# 5 GUNDEN ESKI LOGLARI SIL
# ============================================================

$DeleteBefore = (Get-Date).AddDays(-$RetentionDays)

Get-ChildItem `
    -Path $LogPath `
    -File `
    -ErrorAction SilentlyContinue |
    Where-Object {

        $_.LastWriteTime -lt $DeleteBefore -and
        (
            $_.Extension -eq ".json" -or
            $_.Extension -eq ".csv"
        )

    } |
    ForEach-Object {

        try {

            Remove-Item `
                -Path $_.FullName `
                -Force `
                -ErrorAction Stop

            Write-Host "Eski log silindi: $($_.Name)" `
                -ForegroundColor DarkGray

        }
        catch {

            Write-Host "Log silinemedi: $($_.Name)" `
                -ForegroundColor Yellow
        }
    }


# ============================================================
# OZET
# ============================================================

$EndTime = Get-Date

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

switch ($OverallStatus) {

    "PASS" {
        Write-Host " GENEL DURUM : PASS" -ForegroundColor Green
    }

    "WARNING" {
        Write-Host " GENEL DURUM : WARNING" -ForegroundColor Yellow
    }

    "FAIL" {
        Write-Host " GENEL DURUM : FAIL" -ForegroundColor Red
    }
}

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""
Write-Host "PASS    : $PassCount" -ForegroundColor Green
Write-Host "WARNING : $WarningCount" -ForegroundColor Yellow
Write-Host "FAIL    : $FailCount" -ForegroundColor Red
Write-Host "TOPLAM  : $($Results.Count)"
Write-Host ""

Write-Host "JSON : $JsonFile"
Write-Host "CSV  : $CsvFile"

Write-Host ""
Write-Host "Log retention : $RetentionDays gun"
Write-Host "Log klasoru   : $LogPath"

Write-Host "============================================================" `
    -ForegroundColor Cyan