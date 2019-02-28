#Declaimer: This is a destructive script, means, it deletes files, databases etc. 
#Use it at your own risk.
############################################################################################
#This script is created to remove Sitecore 9.1 instance from local machine.
#This will not uninstall Solr but, it will remove Solr collections.
#Uncomment two sections below to delete the entire solr from your desktop
#The script looks at the Prefix parameter and find out all instances and remove them.
#Change the default values before using the script. Or, pass the values as parameters.

#Usage: .\UninstallSitecore9.1.ps1 -Prefix "xp0"



#License: MIT
############################################################################################
param(
	#Website related parameters
	[string]$Prefix = 'sc910',
	[string]$WebsiteOhysicalRootPath = 'D:\inetpub\wwwroot\',

	#Database related parameters
	[string]$SQLInstanceName = 'DESKTOP-RKKGJ5M',
	[string]$SQLUsername = 'sa',
	[string]$SQLPassword = 'Password123',

	#Certificate related parameters
	[string]$CertificateRootStore = 'Cert:\Localmachine\Root',
	[string]$CertificatePersonalStore = 'Cert:\Localmachine\My',
	[string]$XConnectCertName = "$Prefix.xconnect",
	[string]$XConnectClientCertName = "$Prefix.xconnect_client",
	[string]$SitecoreRootCertName = 'DO_NOT_TRUST_SitecoreRootCert',
	[string]$SitecoreFundamentalsRootCertName = 'DO_NOT_TRUST_SitecoreFundamentalsRoot',
	[string]$CertPath = 'C:\Certificates',
	
	#Will only remove the SOLR cores
	[string]$SolrPath = 'D:\solr\solr-7.2.1'
	# Uncomment if you want to delete the entire Solr installation
	#[string]$SolrService = "solr-7.2.1",
	#[string]$SolrHost = "solr",
	#[string]$SolrPathAll = 'D:\solr\solr-7.2.1'
)

$XConnectWebsiteName = "$Prefix.xconnect"
$SitecoreWebsiteName = "$Prefix.sc"
$IdentityServerSiteName = "$prefix.identityserver"
$XConnectWebsitePhysicalPath = "$WebsiteOhysicalRootPath$Prefix.xconnect"
$SitecoreWebsitePhysicalPath = "$WebsiteOhysicalRootPath$Prefix.sc"
$IdentityServerPhysicalPath = "$WebsiteOhysicalRootPath$Prefix.identityserver"
$HostFileLocation = "c:\windows\system32\drivers\etc\hosts"
$MarketingAutomationService = "$Prefix.xconnect-MarketingAutomationService"
$ProcessingEngineService = "$Prefix.xconnect-ProcessingEngineService"
$IndexWorker = "$Prefix.xconnect-IndexWorker"

Write-Host -foregroundcolor Green  "Starting Sitecore 9 instance removal..."

#Remove Sitecore website
if([bool](Get-Website $SitecoreWebsiteName)) {
	Write-host -foregroundcolor Green "Deleting Website $SitecoreWebsiteName"
	Remove-WebSite -Name $SitecoreWebsiteName
	Write-host -foregroundcolor Green "Deleting App Pool $SitecoreWebsiteName"
	Remove-WebAppPool $SitecoreWebsiteName
}
else {
	Write-host -foregroundcolor Red "Website $SitecoreWebsiteName does not exists."
}

#Remove XConnect website
if([bool](Get-Website $XConnectWebsiteName)) {
	Write-host -foregroundcolor Green "Deleting Website $XConnectWebsiteName"
	Remove-WebSite -Name $XConnectWebsiteName
	Write-host -foregroundcolor Green "Deleting App Pool $XConnectWebsiteName"
	Remove-WebAppPool $XConnectWebsiteName
}
else {
	Write-host -foregroundcolor Red "Website $XConnectWebsiteName does not exists."
}

#Remove Identity Server  website
if([bool](Get-Website $IdentityServerSiteName)) {
	Write-host -foregroundcolor Green "Deleting Website $IdentityServerSiteName"
	Remove-WebSite -Name $IdentityServerSiteName
	Write-host -foregroundcolor Green "Deleting App Pool $IdentityServerSiteName"
	Remove-WebAppPool $IdentityServerSiteName
}
else {
	Write-host -foregroundcolor Red "Website $IdentityServerSiteName does not exists."
}
#Remove hosts entries
if([bool]((get-content $HostFileLocation) -match $Prefix)) {
Write-Host -foregroundcolor Green  "Deleting hosts entires."
(get-content $HostFileLocation) -notmatch $Prefix | Out-File $HostFileLocation
}
else {
	Write-Host -foregroundcolor Red  "No hosts entires found."
}

#Stop and remove MarketingAutomationService
Get-WmiObject -Class Win32_Service -Filter "Name='$MarketingAutomationService'" | Remove-WmiObject

$Service = Get-WmiObject -Class Win32_Service -Filter "Name='$MarketingAutomationService'"
if($Service) {
	Get-Process -Name "MarketingAutomationService" | Stop-Process -Force
	Write-Host -foregroundcolor Green  "Deleting " $MarketingAutomationService
	$Service.StopService()
	$Service.delete()
}
else {
	Write-Host -foregroundcolor Red  $MarketingAutomationService " service does not exists."
}

#Stop and remove ProcessingEngineService
Get-WmiObject -Class Win32_Service -Filter "Name='$ProcessingEngineService'" | Remove-WmiObject

$Service = Get-WmiObject -Class Win32_Service -Filter "Name='$ProcessingEngineService'"
if($Service) {
	Get-Process -Name "ProcessingEngineService" | Stop-Process -Force
	Write-Host -foregroundcolor Green  "Deleting " $ProcessingEngineService
	$Service.StopService()
	$Service.delete()
}
else {
	Write-Host -foregroundcolor Red  $ProcessingEngineService " service does not exists."
}

$Service = Get-WmiObject -Class Win32_Service -Filter "Name='$IndexWorker'"
if($Service) {
	Write-Host -foregroundcolor Green  "Deleting " $IndexWorker
	$Service.StopService()
	$Service.delete()
}
else {
	Write-Host -foregroundcolor Red  $IndexWorker " service does not exists."
}

#Remove Sitecore Files
if (Test-Path $SitecoreWebsitePhysicalPath) { 
     
Remove-Item -path $SitecoreWebsitePhysicalPath\* -recurse 
Remove-Item -path $SitecoreWebsitePhysicalPath 
Write-host -foregroundcolor Green $SitecoreWebsitePhysicalPath " Deleted" 
[System.Threading.Thread]::Sleep(1500) 
 
} else { 
 
Write-host -foregroundcolor Red  $SitecoreWebsitePhysicalPath  " Does not exist" 
 
} 

#Remove XConnect files
if (Test-Path $XConnectWebsitePhysicalPath) { 
     
Remove-Item -path $XConnectWebsitePhysicalPath\* -recurse -Force -ErrorAction SilentlyContinue
Remove-Item -path $XConnectWebsitePhysicalPath -Force
Write-host -foregroundcolor Green $XConnectWebsitePhysicalPath " Deleted" 
[System.Threading.Thread]::Sleep(1500) 
 
} else { 
 
Write-host -foregroundcolor Red  $XConnectWebsitePhysicalPath  " Does not exist" 
}

#Remove Identity Server files
if (Test-Path $IdentityServerPhysicalPath) { 
     
	Remove-Item -path $IdentityServerPhysicalPath\* -recurse -Force -ErrorAction SilentlyContinue
	Remove-Item -path $IdentityServerPhysicalPath -Force
	Write-host -foregroundcolor Green $IdentityServerPhysicalPath " Deleted" 
	[System.Threading.Thread]::Sleep(1500) 
	 
	} else { 
	 
	Write-host -foregroundcolor Red  $IdentityServerPhysicalPath  " Does not exist" 
	}


#Remove SQL Databases
Write-Host -foregroundcolor Green  "[4/7] Remove SQL Databases..."
$DBList = New-Object System.Collections.ArrayList
Get-SqlDatabase -ServerInstance $SQLInstanceName |
where { $_.name -like "$Prefix*" } | foreach {
    [void]$DBList.Add($_.name)
}
$server = New-Object Microsoft.SqlServer.Management.Smo.Server($SQLInstanceName)
ForEach($DB in $DBList) {
    Write-host -foregroundcolor Green "Deleting Database $DB"
    $server.databases[$DB].Drop()
}

#Remove Certificates
if([bool](Get-ChildItem -Path $CertificateRootStore -dnsname $SitecoreRootCertName)) {
	Write-host -foregroundcolor Green "Deleting certificate " $SitecoreRootCertName
	Get-ChildItem -Path $CertificateRootStore -dnsname $SitecoreRootCertName | Remove-Item
}
else {
	Write-host -foregroundcolor Red "Certificate " $SitecoreRootCertName " does not exists."
}

if([bool](Get-ChildItem -Path $CertificateRootStore -dnsname $SitecoreFundamentalsRootCertName)) {
	Write-host -foregroundcolor Green "Deleting certificate " $SitecoreFundamentalsRootCertName
	Get-ChildItem -Path $CertificateRootStore -dnsname $SitecoreFundamentalsRootCertName | Remove-Item
}
else {
	Write-host -foregroundcolor Red "Certificate " $SitecoreFundamentalsRootCertName " does not exists."
}

if([bool](Get-ChildItem -Path $CertificatePersonalStore -dnsname $XConnectCertName)) {
	Write-host -foregroundcolor Green "Deleting certificate " $XConnectCertName
	Get-ChildItem -Path $CertificatePersonalStore -dnsname $XConnectCertName | Remove-Item
}
else {
	Write-host -foregroundcolor Red "Certificate " $XConnectCertName " does not exists."
}

if([bool](Get-ChildItem -Path $CertificatePersonalStore -dnsname $XConnectClientCertName)) {
	Write-host -foregroundcolor Green "Deleting certificate " $XConnectClientCertName
	Get-ChildItem -Path $CertificatePersonalStore -dnsname $XConnectClientCertName | Remove-Item
}
else {
	Write-host -foregroundcolor Red "Certificate " $XConnectClientCertName " does not exists."
}

if (Test-Path $CertPath) {      
	Remove-Item -path $CertPath\* -recurse 
	Remove-Item -path $CertPath 
	Write-host -foregroundcolor Green $CertPath " Deleted" 
	[System.Threading.Thread]::Sleep(1500) 
 
} else {  
	Write-host -foregroundcolor Red  $CertPath  " Does not exist" 
}

# Remove Solr Cores
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_core_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_fxm_master_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_fxm_web_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_marketing_asset_index_master")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_marketing_asset_index_web")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_marketingdefinitions_master")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_marketingdefinitions_web")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_suggested_test_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_testing_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_web_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_master_index")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_xdb")
& "$SolrPath\bin\solr.cmd" delete -c ($Prefix + "_xdb_rebuild")

#Stop and remove Solr Windows Service
Get-WmiObject -Class Win32_Service -Filter "Name='$SolrService'" | Remove-WmiObject

$Service = Get-WmiObject -Class Win32_Service -Filter "Name='$SolrService'"
if($Service) {
	Get-Process -Name "solr-7.2.1" | Stop-Process -Force
	Write-Host -foregroundcolor Green  "Deleting " $SolrService
	$Service.StopService()
	$Service.delete()
}
else {
	Write-Host -foregroundcolor Red  $SolrService " service does not exists."
}

# Remove solr host entry
if([bool]((get-content $HostFileLocation) -match $SolrHost)) {
	Write-Host -foregroundcolor Green  "Deleting hosts entires."
	(get-content $HostFileLocation) -notmatch $SolrHost | Out-File $HostFileLocation
	}
	else {
		Write-Host -foregroundcolor Red $SolrHost "  hosts entire not found."
	}

#Remove Solr files
if (Test-Path $SolrPathAll) { 
     
	Remove-Item -path $SolrPath\* -recurse 
	Remove-Item -path $SolrPath 
	Write-host -foregroundcolor Green $SolrPath " Deleted" 
	[System.Threading.Thread]::Sleep(1500) 
	 
	} else { 
	 
	Write-host -foregroundcolor Red  $SolrPath  " Does not exist" 
	 
	} 
Write-Host -foregroundcolor Green  "Finished Sitecore 9 instance removal..."