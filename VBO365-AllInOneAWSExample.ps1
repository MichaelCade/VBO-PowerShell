Import-Module "C:\Program Files\Veeam\Backup365\Veeam.Archiver.PowerShell\Veeam.Archiver.PowerShell.psd1"

# Organization settings
$O365Username = "<USERNAME>"
$O365Password = "<PASSWORD>"
$Organization = "<ORG>"
$AppID = "<ApplicationID>"
$AppSecret = "<ApplicationSecret>"

# Object storage settings
$S3AccessKey = "<AccessKey>"
$S3SecurityKey = "<SecurityKey"
$ObjectStorageName = "<ObjStorRepoName>"
$BucketName = "<BucketName>"
$FolderName = "<FolderName"

# Backup repository settings
$LocalFolder = "c:\localrepo"
$RepositoryName = "Backup Repository"
$RepositoryDesc = "Backup Repository"

# Combine it all together - do not touch below
$O365PasswordConverted = ConvertTo-SecureString $O365Password -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($O365Username, $O365PasswordConverted)

# Add the organization
$ApplicationSecret = ConvertTo-SecureString -String $AppSecret -AsPlainText -Force
$Connection = New-VBOOffice365ConnectionSettings -AppCredential $Credentials -ApplicationId $AppID -ApplicationSecret $ApplicationSecret -GrantRolesAndPermissions
$Org = Add-VBOOrganization -Name $Organization -Office365ExchangeConnectionsSettings $Connection -Office365SharePointConnectionsSettings $Connection

# Add Object Storage
$SecurityKey = ConvertTo-SecureString -String $S3SecurityKey -AsPlainText -Force
$Account = Add-VBOAmazonS3Account -AccessKey $S3AccessKey -SecurityKey $SecurityKey
$AWSconn = New-VBOAmazonS3ServiceConnectionSettings -Account $Account -RegionType Global
$Bucket = Get-VBOAmazonS3Bucket -AmazonS3ConnectionSettings $AWSconn -Name $BucketName
$Folder = Get-VBOAmazonS3Folder -Bucket $Bucket -Name $FolderName
$ObjectStorage = Add-VBOAmazonS3ObjectStorageRepository -Folder $Folder -Name $ObjectStorageName

# Add Backup Repository
$Proxy = Get-VBOProxy
$Repository = Add-VBORepository -Proxy $Proxy -Path $LocalFolder -Name $RepositoryName -ObjectStorageRepository $ObjectStorage -RetentionPeriod Years3 -RetentionFrequencyType Daily -DailyTime "10:00" -DailyType Everyday -RetentionType ItemLevel -Description $RepositoryDesc

# Add the backup jobs

$MailJobItems = New-VBOBackupItem -Organization $Org -Mailbox -ArchiveMailbox
Add-VBOJob -Organization $Org -Repository $Repository -Name "E-mailTest" -SelectedItems $MailJobItems -Description "E-mail backup" -RunJob

$OneDriveItems = New-VBOBackupItem -Organization $Org -OneDrive
Add-VBOJob -Organization $Org -Repository $Repository -Name "OneDrive" -SelectedItems $OneDriveItems -Description "OneDrive backup" -RunJob

$SharePointItems = New-VBOBackupItem -Organization $Org -Sites
Add-VBOJob -Organization $Org -Repository $Repository -Name "SharePoint" -SelectedItems $SharePointItems -Description "SharePoint backup" -RunJob

$oldRepo = Get-VBORepository -Name "Default Backup Repository"
Remove-VBORepository -Repository $oldRepo -Confirm:$false

$path = "C:\VeeamRepository"
$hostname = "localhost"
$cert = New-SelfSignedCertificate -subject $hostname -NotAfter (Get-Date).AddYears(10) -KeyDescription "Veeam Backup for Microsoft Office 365 auto install" -KeyFriendlyName "Veeam Backup for Microsoft Office 365 auto install"
	$certfile = (join-path $path "cert.pfx")
	$securepassword = ConvertTo-SecureString "Veeam123!" -AsPlainText -Force

	Export-PfxCertificate -Cert $cert -FilePath $certfile -Password $securepassword

	#log("[VBO365 Install] Enabling RESTful API service")
	Set-VBORestAPISettings -EnableService -CertificateFilePath $certfile -CertificatePassword $securepassword

function Disable-ieESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
    Stop-Process -Name Explorer
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}
Disable-ieESC

#This will open the Swagger UI
start https://localhost:4443/swagger/ui/index