# Ercan Polat 
# erjan123@yahoo.com
# LinkedIn: https://www.linkedin.com/in/ercan-polat/
# 07/26/2019
# Version: 1.0
#################################################################################################
# Enhanced PowerShell script that will download and install latest version of JRE

# Solr Installation starts. 
# Make sure to update the versions and folder path
Param(
    $solrVersion = "7.5.0",
    $installFolder = "C:\solr\epcom92",
    $solrPort = "8990",
    $solrHost = "solrepcom92",
    $solrSSL = $true,
    $nssmVersion = "2.24",
	$downloadInstallJRE = $false,
    $JREVersion64 = $false,
	$JREPath  = "C:\Program Files\Java\jre1.8.0_221"  #Note: If you set '$downloadInstallJRE' to false then you have to enable this parameter with a Valid JRE path.
) 

## Verify elevated
## https://superuser.com/questions/749243/detect-if-powershell-is-running-as-administrator
$elevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
if($elevated -eq $false)
{
    throw "In order to install services, please run this script elevated."
}

if($downloadInstallJRE -eq $true)
{
	if($JREVersion64 -eq $true)
	{
		$URL=(Invoke-WebRequest -UseBasicParsing https://www.java.com/en/download/manual.jsp).Content | 	ForEach-Object{[regex]::matches($_, '(?:<a title="Download Java software for Windows \(64-bit\)" href=")(.*)(?:">)').Groups[1].Value} 
	}
	else
	{		
		$URL=(Invoke-WebRequest -UseBasicParsing https://www.java.com/en/download/manual.jsp).Content | ForEach-Object{[regex]::matches($_, '(?:<a title="Download Java software for Windows Online" href=")(.*)(?:">)').Groups[1].Value}
	}
		Invoke-WebRequest -UseBasicParsing -OutFile jre8.exe $URL
		Start-Process .\jre8.exe '/s REBOOT=0 SPONSORS=0 AUTO_UPDATE=0' -wait
		
	if($JREVersion64 -eq $true)
	{
		$JREVersion = Get-ChildItem -Path "C:\Program Files\Java" -name | Where-Object { -not $_.PsIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -first 1 
		
		Write-Host "JREVersion: $JREVersion"
		$JREPath = "C:\Program Files\Java\$JREVersion"
		Write-Host 	"JREPath" + $JREPath
		Write-Host "Downloading 64 bit of JRE"
	}	
	else{

		$JREVersion = Get-ChildItem -Path "C:\Program Files (x86)\Java" -name | Where-Object { -not $_.PsIsContainer } | Sort-Object LastWriteTime -Descending | Select-Object -first 1 

		Write-Host "JREVersion: $JREVersion"
		$JREPath = "C:\Program Files (x86)\Java\$JREVersion"
		Write-Host 	"JREPath " + $JREPath
		Write-Host "Downloading 32 bit of JRE"
	}

		Write-Host "JRE package URL " $URL
}

$jreVal = [Environment]::GetEnvironmentVariable("JAVA_HOME", [EnvironmentVariableTarget]::Machine)
# Ensure Java environment variable
if($jreVal -ne $JREPath)
{
    Write-Host "Setting JAVA_HOME environment variable"
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $JREPath, [EnvironmentVariableTarget]::Machine)
}

$solrName = "solr-$solrVersion"
$solrRoot = "$installFolder\$solrName"
$nssmRoot = "$installFolder\nssm-$nssmVersion"
$solrPackage = "https://archive.apache.org/dist/lucene/solr/$solrVersion/$solrName.zip"
$nssmPackage = "https://nssm.cc/release/nssm-$nssmVersion.zip"
$downloadFolder = "~\Downloads"

function downloadAndUnzipIfRequired
{
    Param(
        [string]$toolName,
        [string]$toolFolder,
        [string]$toolZip,
        [string]$toolSourceFile,
        [string]$installRoot
    )

    if(!(Test-Path -Path $toolFolder))
    {
        if(!(Test-Path -Path $toolZip))
        {
            Write-Host "Downloading $toolName..."
            Start-BitsTransfer -Source $toolSourceFile -Destination $toolZip
        }

        Write-Host "Extracting $toolName to $toolFolder..."
        Expand-Archive $toolZip -DestinationPath $installRoot
    }
	else
	{
		Write-Host $toolName " does exist in Download folder. "
	}
}
# download & extract the solr archive to the right folder
$solrZip = "$downloadFolder\$solrName.zip"
downloadAndUnzipIfRequired "Solr" $solrRoot $solrZip $solrPackage $installFolder

# download & extract the nssm archive to the right folder
$nssmZip = "$downloadFolder\nssm-$nssmVersion.zip"
downloadAndUnzipIfRequired "NSSM" $nssmRoot $nssmZip $nssmPackage $installFolder

# if we're using HTTP
if($solrSSL -eq $false)
{
    # Update solr cfg to use right host name
    if(!(Test-Path -Path "$solrRoot\bin\solr.in.cmd.old"))
    {
        Write-Host "Rewriting solr config"

        $cfg = Get-Content "$solrRoot\bin\solr.in.cmd"
        Rename-Item "$solrRoot\bin\solr.in.cmd" "$solrRoot\bin\solr.in.cmd.old"
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
        $newCfg | Set-Content "$solrRoot\bin\solr.in.cmd"
    }
}

# if we're using HTTPS
if($solrSSL -eq $true)
{
    # Generate SSL cert
    $existingCert = Get-ChildItem Cert:\LocalMachine\Root | where FriendlyName -eq "$solrHost"
    if(!($existingCert))
    {
        Write-Host "Creating & trusting an new SSL Cert for $solrHost"

        # Generate a cert
        # https://docs.microsoft.com/en-us/powershell/module/pkiclient/new-selfsignedcertificate?view=win10-ps
        $cert = New-SelfSignedCertificate -FriendlyName "$solrHost" -DnsName "$solrHost" -CertStoreLocation "cert:\LocalMachine" -NotAfter (Get-Date).AddYears(10)

        # Trust the cert
        # https://stackoverflow.com/questions/8815145/how-to-trust-a-certificate-in-windows-powershell
        $store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root","LocalMachine"
        $store.Open("ReadWrite")
        $store.Add($cert)
        $store.Close()

        # remove the untrusted copy of the cert
        $cert | Remove-Item
    }

    # export the cert to pfx using solr's default password
    if(!(Test-Path -Path "$solrRoot\server\etc\solr-ssl.keystore.pfx"))
    {
        Write-Host "Exporting cert for Solr to use"

        $cert = Get-ChildItem Cert:\LocalMachine\Root | where FriendlyName -eq "$solrHost"
    
        $certStore = "$solrRoot\server\etc\solr-ssl.keystore.pfx"
        $certPwd = ConvertTo-SecureString -String "secret" -Force -AsPlainText
        $cert | Export-PfxCertificate -FilePath $certStore -Password $certpwd | Out-Null
    }

    # Update solr cfg to use keystore & right host name
    if(!(Test-Path -Path "$solrRoot\bin\solr.in.cmd.old"))
    {
        Write-Host "Rewriting solr config"

        $cfg = Get-Content "$solrRoot\bin\solr.in.cmd"
        Rename-Item "$solrRoot\bin\solr.in.cmd" "$solrRoot\bin\solr.in.cmd.old"
        $newCfg = $cfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$certStore" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=secret" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$certStore" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=secret" }
        $newCfg = $newCfg | % { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
        $newCfg | Set-Content "$solrRoot\bin\solr.in.cmd"
    }
}

# Ensure the solr host name is in your hosts file
if($solrHost -ne "localhost")
{
    $hostFileName = "c:\\windows\system32\drivers\etc\hosts"
    $hostFile = [System.Io.File]::ReadAllText($hostFileName)
    if(!($hostFile -like "*$solrHost*"))
    {
        Write-Host "Updating host file"
        "`r`n127.0.0.1`t$solrHost" | Add-Content $hostFileName
    }
}

# install the service & runs
$svc = Get-Service "$solrHost" -ErrorAction SilentlyContinue
if(!($svc))
{
    Write-Host "Installing Solr service"
    &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" install "$solrHost" "$solrRoot\bin\solr.cmd" "-f" "-p $solrPort"
    $svc = Get-Service "$solrHost" -ErrorAction SilentlyContinue
}
if($svc.Status -ne "Running")
{
    Write-Host "Starting Solr service"
    Start-Service "$solrHost"
}

# finally prove it's all working
$protocol = "http"
if($solrSSL -eq $true)
{
    $protocol = "https"
}
Invoke-Expression "start $($protocol)://$($solrHost):$solrPort/solr/#/"


Write-Host ""
Write-Host "Verify Solr Admin page!"
Write-Host ""
Write-Host ""
Write-Host "If you want to be happy, then be happy!" -ForegroundColor Green