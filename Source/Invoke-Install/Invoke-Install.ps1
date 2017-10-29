# TODO: Propper Description of this file above
# TODO: Tests? 

function Invoke-Install (
    [Parameter(Position=0, Mandatory=$true, HelpMessage="Path to the *.install.ps1")]
    [string] $InstallFilePath,

    [string] $Filter =  ".*\.install\.ps1"
) {
    $InstallScripts = Get-InstallScripts -InstallFilePath $InstallFilePath -Filter $Filter

    $Count = 0 

    foreach ($Script in $InstallScripts) {
        . $Script
        $Count += 1
    }

    return $Count
}

function Get-InstallScripts (
    [Parameter(Position=0, Mandatory=$true, HelpMessage="Path to the *.install.ps1")]
    [string] $InstallFilePath, 

    [string] $Filter
) {
    $InstallScripts = @()
    
    if ((Get-Item $InstallFilePath) -is [System.IO.DirectoryInfo]) {
        $FoundInstallScripts = Get-ChildItem $InstallFilePath | Where-Object {$_.Name -match  $Filter }
        if ($FoundInstallScripts.Length -gt 0) {            
            $FoundInstallScripts | ForEach-Object {
                $InstallScripts += $_.FullName
            }
        }
    } else {
        if ($InstallFilePath -match $Filter) {
            $InstallScripts += (Get-Item $InstallFilePath)    
        }        
    }
    
   if ($InstallScripts.Length -lt 1) {
        Write-Host "No File found witch matches the Filter $Filter to run Invoke-Install on it"
    } else {
        return $InstallScripts
    }

}