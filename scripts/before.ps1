#requires -RunAsAdministrator

$Computers = @(
    "DC01.lab.test",
    "SRV01.lab.test",
    "CL01.lab.test"
)

$OutputDir = "reports\security-baseline-before"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$Results = foreach ($Computer in $Computers) {

    Write-Host "Collecting security baseline from $Computer..." -ForegroundColor Cyan

    try {
        $Result = Invoke-Command -ComputerName $Computer -ErrorAction Stop -ScriptBlock {


            $Firewall = Get-NetFirewallProfile |
                Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction


            $Defender = Get-MpComputerStatus |
                Select-Object `
                    AMServiceEnabled,
                    AntivirusEnabled,
                    AntispywareEnabled,
                    BehaviorMonitorEnabled,
                    IoavProtectionEnabled,
                    RealTimeProtectionEnabled,
                    NISEnabled,
                    AntivirusSignatureVersion,
                    AntivirusSignatureLastUpdated


            $SMBServer = Get-SmbServerConfiguration |
                Select-Object `
                    EnableSMB1Protocol,
                    EnableSMB2Protocol,
                    EncryptData,
                    RequireSecuritySignature,
                    EnableSecuritySignature

            $SMBClient = Get-SmbClientConfiguration |
                Select-Object `
                    EnableSecuritySignature,
                    RequireSecuritySignature


            $Administrators = Get-LocalGroupMember -Group "Administrators" |
                Select-Object Name, ObjectClass, PrincipalSource

            if ($env:COMPUTERNAME -eq "DC01") {

    Import-Module ActiveDirectory

    $DomainPolicy = Get-ADDefaultDomainPasswordPolicy

    $PasswordPolicy = [PSCustomObject]@{
        PolicyType                   = "Domain"
        MinPasswordLength            = $DomainPolicy.MinPasswordLength
        PasswordHistoryCount         = $DomainPolicy.PasswordHistoryCount
        MaxPasswordAge               = $DomainPolicy.MaxPasswordAge
        MinPasswordAge               = $DomainPolicy.MinPasswordAge
        ComplexityEnabled            = $DomainPolicy.ComplexityEnabled
        ReversibleEncryptionEnabled  = $DomainPolicy.ReversibleEncryptionEnabled
    }

    $LockoutPolicy = [PSCustomObject]@{
        PolicyType              = "Domain"
        LockoutThreshold        = $DomainPolicy.LockoutThreshold
        LockoutDuration         = $DomainPolicy.LockoutDuration
        LockoutObservationWindow = $DomainPolicy.LockoutObservationWindow
    }

}
else {

    $LocalAccountsPolicy = net accounts

    $PasswordPolicy = [PSCustomObject]@{
        PolicyType = "Local"
        RawOutput  = $LocalAccountsPolicy
    }

    $LockoutPolicy = [PSCustomObject]@{
        PolicyType = "Local"
        RawOutput  = $LocalAccountsPolicy
    }
}


            $AuditPolicy = auditpol /get /category:* 2>&1

            $ExecutionPolicy = Get-ExecutionPolicy -List |
                Select-Object Scope, ExecutionPolicy


            $RDPRegistry = Get-ItemProperty `
                -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
                -ErrorAction SilentlyContinue

            $RDPService = Get-Service -Name TermService -ErrorAction SilentlyContinue |
                Select-Object Name, Status, StartType

            $RDP = [PSCustomObject]@{
                RDPEnabled = if ($RDPRegistry.fDenyTSConnections -eq 0) {
                    $true
                } else {
                    $false
                }
                RDPPort = (Get-ItemProperty `
                    -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
                    -ErrorAction SilentlyContinue).PortNumber
                ServiceName = $RDPService.Name
                ServiceStatus = $RDPService.Status
                ServiceStartType = $RDPService.StartType
            }


            [PSCustomObject]@{
                ComputerName      = $env:COMPUTERNAME
                CollectionTime    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")

                Firewall          = $Firewall
                Defender          = $Defender

                SMBServer         = $SMBServer
                SMBClient         = $SMBClient

                LocalAdministrators = $Administrators

                PasswordPolicy    = $PasswordPolicy
                LockoutPolicy     = $LockoutPolicy

                AuditPolicy       = $AuditPolicy

                PowerShellExecutionPolicy = $ExecutionPolicy

                RDP               = $RDP
            }
        }

        $Result
    }
    catch {
        Write-Warning "Failed to collect data from $Computer : $($_.Exception.Message)"

        [PSCustomObject]@{
            ComputerName   = $Computer
            CollectionTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            Error          = $_.Exception.Message
        }
    }
}



$JsonPath = Join-Path $OutputDir "security-baseline-before.json"

$Results |
    ConvertTo-Json -Depth 10 |
    Out-File -FilePath $JsonPath -Encoding UTF8



$CsvResults = foreach ($Result in $Results) {

    if ($Result.Error) {
        [PSCustomObject]@{
            ComputerName = $Result.ComputerName
            CollectionTime = $Result.CollectionTime
            Error = $Result.Error
        }

        continue
    }

    [PSCustomObject]@{
        ComputerName = $Result.ComputerName
        CollectionTime = $Result.CollectionTime

        Firewall_Domain_Enabled =
            ($Result.Firewall |
                Where-Object Name -eq "Domain").Enabled

        Firewall_Private_Enabled =
            ($Result.Firewall |
                Where-Object Name -eq "Private").Enabled

        Firewall_Public_Enabled =
            ($Result.Firewall |
                Where-Object Name -eq "Public").Enabled

        Defender_AntivirusEnabled =
            $Result.Defender.AntivirusEnabled

        Defender_RealTimeProtectionEnabled =
            $Result.Defender.RealTimeProtectionEnabled

        SMB1 =
            $Result.SMBServer.EnableSMB1Protocol

        SMB2 =
            $Result.SMBServer.EnableSMB2Protocol

        SMB_EncryptData =
            $Result.SMBServer.EncryptData

        SMB_RequireSecuritySignature =
            $Result.SMBServer.RequireSecuritySignature

        LocalAdministrators =
            (($Result.LocalAdministrators.Name) -join "; ")

        PasswordPolicy =
            (($Result.PasswordPolicy) -join " | ")

        LockoutPolicy =
            (($Result.LockoutPolicy) -join " | ")

        AuditPolicy =
            (($Result.AuditPolicy) -join " | ")

        PowerShellExecutionPolicy =
            (($Result.PowerShellExecutionPolicy |
                ForEach-Object {
                    "$($_.Scope)=$($_.ExecutionPolicy)"
                }) -join "; ")

        RDPEnabled =
            $Result.RDP.RDPEnabled

        RDPPort =
            $Result.RDP.RDPPort

        RDPServiceStatus =
            $Result.RDP.ServiceStatus

        RDPServiceStartType =
            $Result.RDP.ServiceStartType
    }
}

$CsvPath = Join-Path $OutputDir "security-baseline-before.csv"

$CsvResults |
    Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8



Write-Host ""
Write-Host "Security baseline collection completed." -ForegroundColor Green
Write-Host ""
Write-Host "JSON: $JsonPath"
Write-Host "CSV : $CsvPath"