# AU Packages Template: https://github.com/majkinetor/au-packages-template

param([string] $Name, [string] $ForcedPackages, [string] $Root = "$PSScriptRoot\..\Chocolatey")

if (Test-Path $PSScriptRoot/update_vars.ps1) { . $PSScriptRoot/update_vars.ps1 }

$Options = [ordered]@{
    Timeout        = 100                                     #Connection timeout in seconds
    UpdateTimeout  = 1200                                    #Update timeout in seconds
    Threads        = 10                                      #Number of background jobs to use
    Push           = $Env:au_Push -eq 'true'                 #Push to chocolatey
    PluginPath     = ''                                      #Path to user plugins

    ForcedPackages = $ForcedPackages -split ' '
    BeforeEach     = {
        param($PackageName, $Options )
        $p = $Options.ForcedPackages | ? { $_ -match "^${PackageName}(?:\:(.+))*$" }
        if (!$p) { return }

        $global:au_Force = $true
        $global:au_Version = ($p -split ':')[1]
    }
}

if ($ForcedPackages) { Write-Host "FORCED PACKAGES: $ForcedPackages" }
$global:au_Root = $Root                                    #Path to the AU packages
$global:info = updateall -Name $Name -Options $Options

#Uncomment to fail the build on AppVeyor on any package error
#if ($global:info.error_count.total) { throw 'Errors during update' }