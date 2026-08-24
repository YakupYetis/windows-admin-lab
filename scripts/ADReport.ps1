if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "AD Modulu Bulunamadi"
    return  
}
Import-Module ActiveDirectory
Write-Host "[*] AD Verileri Toplaniyor..." -ForegroundColor Cyan

$ADDomain = Get-ADDomain
$CurrentDC = (Get-ADDomain).PDCEmulator

$TotalOUs = (Get-ADOrganizationalUnit -Filter *).Count 
$TotalUsers = (Get-ADUser -Filter *).Count 
$TotalGroups = (Get-ADGroup -Filter *).Count 
$TotalComputers = (Get-ADComputer -Filter *).Count 

$DomainSummary  = [PSCustomObject]@{
    DomainName = $ADDomain.DNSRoot
    DomainController = $CurrentDC
    TotalOUs = $TotalOUs
    TotalUsers = $TotalUsers
    TotalGroups = $TotalGroups
    TotalComputers = $TotalComputers
    GeneratedDate = (Get-Date).ToString("yyyy.MM.dd HH:mm:ss")
}


Write-Host "[*] Kullanici Verileri Ve Grup Bilgileri Toplaniyor..." -ForegroundColor Cyan

$ADUsers = Get-ADUser -Filter * -Properties Department, DistinguishedName, Enabled, LastLogOnDate, MemberOf

$UserDetailsList = foreach($User in $ADUsers){
    $OUPath = if ($User.DistinguishedName -match 'OU=(.*)') {"OU=" + $Matches[1]} else { "Kok Dizin (CN=Users vb.)"}

    $GroupNames = if ($User.MemberOf) {
        ($User.MemberOf | ForEach-Object {($_ -split ',*..=')[1]}) -join "; "}
        else {
            "Yok"
        }
[PSCustomObject]@{
    SamAccountName = $User.SamAccountName
    DisplayName = $User.Name
    Department = if ($User.Department) {$User.Department} else{"Belirtilmemis"}
    OU = $OUPath
    Enabled = $User.Enabled
    LastLogOn = if ($User.LastLogOnDate) {
        $User.LastLogOnDate.ToString("yyyy-MM-dd HH:mm:ss")} else { "Hic Giris Yapilmadi" }
        GroupMembership = $GroupNames
}
}

$ExportPath = "$Home\Desktop\AD_Report"
if (-not (Test-Path -Path $ExportPath)) {
    New-Item -ItemType Directory -Path $ExportPath -Force | Out-Null
}
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$FullReport = [PSCustomObject]@{
    $DomainSummary = $DomainSummary
    Users = $UserDetailsList
}

$JsonFilePath = "$ExportPath\AD_Full_Report_$Timestamp.json"
$FullReport | ConvertTo-Json -Depth 4 | Out-File -FilePath $JsonFilePath -Encoding utf8

$DomainSummaryCsv = "$ExportPath\AD_Domain_Summary_$Timestamp.csv"
$UserDetailsCsv = "$ExportPath\AD_User_Details_$Timestamp.csv"

$DomainSummary | Export-Csv -Path $DomainSummaryCsv -NoTypeInformation -Encoding UTF8 -Delimiter ","
$UserDetailsList | Export-Csv -Path $UserDetailsCsv -NoTypeInformation -Encoding UTF8 -Delimiter ","

Write-Host "`n[+] Raporlama Basariyla Tamamlandi!" -ForegroundColor Green
Write-Host "Dosyalar suraya kaydedildi: $ExportPath" -ForegroundColor Yellow
Write-Host " - JSON: $JsonFilePath"
Write-Host " - CSV 1 (Ozet): $DomainSummaryCsv"
Write-Host " - CSV 2 (Kullanicilar): $UserDetailsCsv"