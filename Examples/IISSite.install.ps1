$PackageName = "Sample.Package"
# needed as iis can not deal with foo\..\bar 
$InstPath = Convert-Path "$ENV:InstPath\..\Data\External"
$IisRoot = $InstPath

# Je nach Umgebung Variabeln die benötigt werden definieren
switch ($ENV:Environment) {
    "Development" {
        $SiteName = "$ENV:Environment.$PackageName"
        $AppPoolName = $SiteName
        $Url = "dev.sample.package.com"
        
        $User = ".\MyUser"
        $Password = "MyPassword"
    }
    "Staging" {
        $SiteName = "$ENV:Environment.$PackageName"
        $AppPoolName = $SiteName
        $Url = "test.sample.package.com"
        
        $User = "MyUser"
        $Password = "MyPassword"
    }
    "Production" {
        $SiteName = "$PackageName"
        $AppPoolName = $SiteName        
        $Url = "sample.package.com"
        
        $User = ".\MyUser"
        $Password = "MyPassword"
    }
    "Local" {        
        $SiteName = "$PackageName"
        $AppPoolName = $SiteName
        $Url = "sample.package.com"
        
        $User = ".\MyUser"
        $Password = "MyPassword"
    }
    default {
        Write-Output "Installation of $PackageName not possible environment is unkown"
        exit
    }
}

If(!(test-path $InstPath))
{
      New-Item -ItemType Directory -Force -Path $InstPath
}

# Stop and uninstall the old IISSite and AppPool
Remove-IISApplicationPool $AppPoolName
Remove-IISWebsite $SiteName

# Install the IISSite and AppPool
New-IISApplicationPool -Name $AppPoolName -StartMode "AlwaysRunning" -IdentityType 4
New-IISWebsite -name $SiteName -root $IisRoot -appPool $AppPoolName
Use-WebAdministration
Remove-WebBinding -Name $SiteName -Protocol "http" -Port 80 -IPAddress "*"
New-WebBinding -Name $SiteName -Protocol "http" -Port 80 -IPAddress "*" -HostHeader $Url
New-WebBinding -Name $SiteName -Protocol "https" -Port 443 -IPAddress "*" -HostHeader $Url
Add-WebConfiguration -Value @{Name="ASPNETCORE_ENVIRONMENT"; Value=$ENV:Environment} -Filter system.webServer/aspNetCore/environmentVariables -PSPath "MACHINE/WEBROOT/APPHOST" -Location "$SiteName"
Add-WebConfiguration -Value @{Name="Access-Control-Allow-Origin"; Value="*"} -Filter system.webServer/httpProtocol/customHeaders -PSPath "MACHINE/WEBROOT/APPHOST" -Location "$SiteName"
Add-WebConfiguration -Value @{Name="Access-Control-Allow-Methods"; Value="GET,OPTIONS"} -Filter system.webServer/httpProtocol/customHeaders -PSPath "MACHINE/WEBROOT/APPHOST" -Location "$SiteName"
Add-WebConfiguration -Value @{Name="Access-Control-Allow-Headers"; Value="Content-Type"} -Filter system.webServer/httpProtocol/customHeaders -PSPath "MACHINE/WEBROOT/APPHOST" -Location "$SiteName"
Start-Website -Name $SiteName