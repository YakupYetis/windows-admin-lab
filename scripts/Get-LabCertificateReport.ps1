

$ComputerNames = @(
    "CA01",
    "SRV01",
    "CL01"
)

$OutputDirectory = "C:\LabReports"

$CsvPath  = Join-Path $OutputDirectory "CertificateReport.csv"
$JsonPath = Join-Path $OutputDirectory "CertificateReport.json"

$WarningDays = 60

if (-not (Test-Path $OutputDirectory)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
}

$Report = foreach ($ComputerName in $ComputerNames) {

    Write-Host "Checking $ComputerName..." -ForegroundColor Cyan

    # Önce makineye erişimi kontrol et
    if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {

        [PSCustomObject]@{
            ComputerName      = $ComputerName
            Subject           = $null
            Issuer            = $null
            Thumbprint        = $null
            NotBefore         = $null
            NotAfter          = $null
            DaysRemaining     = $null
            EnhancedKeyUsage  = $null
            HasPrivateKey     = $null
            Status            = "FAIL"
        }

        continue
    }

    try {

        $Certificates = Invoke-Command -ComputerName $ComputerName -ScriptBlock {

            Get-ChildItem -Path "Cert:\LocalMachine\My"

        } -ErrorAction Stop

        foreach ($Certificate in $Certificates) {

            $Now = Get-Date

            $DaysRemaining = [math]::Floor(
                ($Certificate.NotAfter - $Now).TotalDays
            )

            # EKU bilgilerini al
            $EnhancedKeyUsage = if ($Certificate.EnhancedKeyUsageList) {
                ($Certificate.EnhancedKeyUsageList |
                    ForEach-Object { $_.FriendlyName }) -join "; "
            }
            else {
                ""
            }

            # Sertifika durumunu belirle
            if ($Certificate.NotAfter -lt $Now) {
                $Status = "FAIL"
            }
            elseif ($DaysRemaining -lt $WarningDays) {
                $Status = "WARNING"
            }
            else {
                $Status = "PASS"
            }

            [PSCustomObject]@{
                ComputerName      = $ComputerName
                Subject           = $Certificate.Subject
                Issuer            = $Certificate.Issuer
                Thumbprint        = $Certificate.Thumbprint
                NotBefore         = $Certificate.NotBefore
                NotAfter          = $Certificate.NotAfter
                DaysRemaining     = $DaysRemaining
                EnhancedKeyUsage  = $EnhancedKeyUsage
                HasPrivateKey     = $Certificate.HasPrivateKey
                Status            = $Status
            }
        }
    }
    catch {

        [PSCustomObject]@{
            ComputerName      = $ComputerName
            Subject           = $null
            Issuer            = $null
            Thumbprint        = $null
            NotBefore         = $null
            NotAfter          = $null
            DaysRemaining     = $null
            EnhancedKeyUsage  = $null
            HasPrivateKey     = $null
            Status            = "FAIL"
        }

        Write-Warning "$ComputerName could not be queried: $($_.Exception.Message)"
    }
}

# CSV
$Report | Export-Csv `
    -Path $CsvPath `
    -NoTypeInformation `
    -Encoding UTF8

# JSON
$Report | ConvertTo-Json -Depth 5 |
    Set-Content -Path $JsonPath -Encoding UTF8

# Konsol özeti
Write-Host ""
Write-Host "Certificate Report" -ForegroundColor Green
Write-Host "=================="

$Report | Format-Table `
    ComputerName,
    Subject,
    NotAfter,
    DaysRemaining,
    HasPrivateKey,
    Status `
    -AutoSize

Write-Host ""
Write-Host "CSV : $CsvPath"
Write-Host "JSON: $JsonPath"