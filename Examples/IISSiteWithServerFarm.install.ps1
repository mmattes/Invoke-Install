# SETUP

# a short guid is generated and used to uniquely identify the new release, could also be the current version number
$ShortGUID = Get-ShortGUID

# Define other variables used later
$PackageName = "Sample.Package"
$InstPath = $ENV:InstPath + "\$PackageName.$ShortGUID"
$IisRoot = $InstPath + "\bin"
$ProductZip = $PSScriptRoot + "\$PackageName.zip"
$BinaryPath = $InstPath + "\bin\$PackageName.exe"
$ServerFarmName = "$PackageName.ServerFarm"

# get more variables depending on the enviroment
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

# add a default website which listens to the main url and port normally www.example.com and 80
New-IISWebsite -name $SiteName -root $IisRoot -bindings @{protocol='http';bindingInformation='*:80:$Url'}

# append the guid to the variables for the next steps
$AppPoolName = "$AppPoolName.$ShortGUID"
$SiteName = "$SiteName.$ShortGUID"
$UrlWithGuid = "$ShortGUID.$Url"

# We get the next free port from Windows under which we will host the new release
$Port = Get-FreePortFromRange (8100..8199)

# make sure the directory where our solution should be installed exists
If(!(test-path $InstPath))
{
      New-Item -ItemType Directory -Force -Path $InstPath
}

# Unzip the file containing the artifact
Expand-Archive -Path $ProductZip -destinationpath $InstPath

# Install the IISSite and AppPool for the new release
New-IISApplicationPool -Name $AppPoolName -StartMode "AlwaysRunning" -IdentityType 4
New-IISWebsite -name $SiteName -root $IisRoot -appPool $AppPoolName
Use-WebAdministration
Remove-WebBinding -Name $SiteName -Protocol "http" -Port 80 -IPAddress "*"
New-WebBinding -Name $SiteName -Protocol "http" -Port $Port -IPAddress "*" -HostHeader $UrlWithGuid
Add-WebConfiguration -Value @{Name="ASPNETCORE_ENVIRONMENT"; Value=$ENV:Environment} -Filter system.webServer/aspNetCore/environmentVariables -PSPath "MACHINE/WEBROOT/APPHOST" -Location "$SiteName"
Start-Website -Name $SiteName

# We set a global URL Rewrite from our URL to the Server Farm which then deals with all requests
Add-IISGlobalRouting -RuleName "Rewrite $Url to ServerFarm $ServerFarmName" -MatchUrl ".*" -Conditions @(@{"input"="{HTTP_HOST}"; "pattern"="^$Url$"},@{"input"="{SERVER_PORT}"; "pattern"="^80$"}) -Action @{"type"="Rewrite";url="http://$Url/{R:0}"} -StopProcessing $false

# Create Server Farm will only create a new one if it does not exist so we can run it every time
Create-IISServerFarm -ServerFarmName "$ServerFarmName"
Set-IISServerFarmhealthCheck -ServerFarmName "$ServerFarmName" -Url "$Url/up.html" -ResponseMatch "up"

# Now we add a new enty pointing to 127.0.0.1 to the local hosts file of windows so that we do not need to worry
# about network wide dns resolution
Add-WindowsHostsRecord -DnsName $UrlWithGuid -IPAddress "127.0.0.1"
Add-IISServerToServerFarm -ServerFarmName "$ServerFarmName" -ServerAddress $UrlWithGuid -HttpPort $Port

#Todo: disable / remove old servers / releases