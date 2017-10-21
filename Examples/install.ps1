[cmdletbinding()]
param (   
    [Parameter(Mandatory=$true, Position=1)]
    [Alias('env')]
    [string]  $Enviroment    = $null
)

if ($PSVersionTable.PSVersion.Major -lt 5)
{
    Write-Host -ForegroundColor Red "PowerShell Version 5 required"
    Exit
}

if (!(Get-Module Invoke-Install)){
    Import-Module Invoke-Install -ErrorAction Stop
}

# Set global variables which are used within the *.install.ps1 files then
switch ($Enviroment) {
    "Development" {
        $TargetRoot = "D:\$Enviroment\App"
    }
    "Staging" {
        $TargetRoot = "D:\$Enviroment\App"
    }
    "Production" {
        $TargetRoot = "D:\Web\App"
    }
    "Local" {
        $TargetRoot = "C:\Web\App"
    }
    default {
        Write-Output "Enviroment is unkown"
        exit
    }
}

# Installation Starten
Invoke-Install .