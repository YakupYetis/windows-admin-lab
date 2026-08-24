Import-Module ActiveDirectory

$CSVPath = "C:\Users\msi-nb\Desktop\users.csv"
$LogPath = "C:\Users\msi-nb\Desktop\AD_Creation_Log.txt"
$DomainName = "lab.test"
$DomainDN = "DC=lab,DC=test"
$BaseOU = "OU=users2,$DomainDN"

# Loglama Fonksiyonu
function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    Add-Content -Path $LogPath -Value $LogEntry
    
    switch ($Level) {
        "SUCCESS" { Write-Host $LogEntry -ForegroundColor Green }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        "ERROR"   { Write-Host $LogEntry -ForegroundColor Red }
        default   { Write-Host $LogEntry -ForegroundColor Cyan }
    }
}

Write-Log "Kullanıcı toplu oluşturma scripti baslatildi." "INFO"

if (-not (Test-Path $CSVPath)) {
    Write-Log "Kritik Hata: CSV dosyasi bulunamadi -> $CSVPath" "ERROR"
    exit
}

$Users = Import-Csv -Path $CSVPath

foreach ($User in $Users) {
    $SamName  = $User.SamAccountName
    $FirstName= $User.GivenName
    $LastName = $User.Surname
    $Dept     = $User.Department
    $TempPass = $User.Password

    $DisplayName = "$FirstName $LastName"
    $UPN = "$SamName@$DomainName"
    $TargetOU = "OU=$Dept,$BaseOU"
    $GroupName = "G_${Dept}_Users"

    try {
        $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$SamName'" -ErrorAction SilentlyContinue
        if ($ExistingUser) {
            Write-Log "Atlandi: '$SamName' ($DisplayName) kullanici adi zaten mevcut." "WARNING"
            continue
        }

        $SecurePassword = $TempPass | ConvertTo-SecureString -AsPlainText -Force

        New-ADUser -Name $DisplayName `
                   -SamAccountName $SamName `
                   -GivenName $FirstName `
                   -Surname $LastName `
                   -UserPrincipalName $UPN `
                   -Path $TargetOU `
                   -AccountPassword $SecurePassword `
                   -Enabled $true `
                   -ChangePasswordAtLogon $true `
                   -ErrorAction Stop

        Write-Log "Basarili: '$DisplayName' ($SamName) olusturuldu. Hedef OU: $TargetOU" "SUCCESS"

        $Group = Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue
        if ($Group) {
            Add-ADGroupMember -Identity $GroupName -Members $SamName -ErrorAction Stop
            Write-Log "Grup Islemi: '$SamName' kullanicisi '$GroupName' grubuna eklendi." "SUCCESS"
        } else {
            Write-Log "Uyari: '$GroupName' guvenlik grubu bulunamadi." "WARNING"
        }

    }
    catch {
        Write-Log "Islem Hatasi ($SamName): $_" "ERROR"
    }
}

Write-Log "Tum islemler tamamlandi." "INFO"