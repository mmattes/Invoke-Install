function Invoke-Install {
     <#
        .SYNOPSIS
            Gets all *.install.ps1 and executes them
        
        .DESCRIPTION
            Gets all *.install.ps1 files and will execute them one by one

        .PARAMETER Path
            Path to the *.install.ps1 file/files

        .PARAMETER Filter
            Filter for which scripts Invoke-Install should look for to execute them

        .EXAMPLE
            Invoke-Install HelloWorld.install.ps1

        .EXAMPLE
            Invoke-Install . -Filter ".*\.myfilter\.ps1"
    #>
    param (
        [Parameter(Position=0, Mandatory=$true, HelpMessage="Path to the *.install.ps1")]
        [string] $Path,

        [string] $Filter =  ".*\.install\.ps1"
    )

    $InstallScripts = Get-InstallScripts -Path $Path -Filter $Filter

    $Count = 0

    foreach ($Script in $InstallScripts) {
        $StartDateTime = Get-date -Format u
        
        Write-Log "`n`n"        
        Write-Log "$StartDateTime | Starting install Script: $Script"
        Write-Log "----"
                
        . $Script
        $Count += 1

        $FinishDateTime = Get-date -Format u
        $ExecutionTime = New-TimeSpan -Start $StartDateTime -End $FinishDateTime
        $ExecutionTime = $ExecutionTime.ToString("G")

        Write-Log "----"
        Write-Log "$FinishDateTime | Finished install Script: $Script, Execution Time: $ExecutionTime"        
    }

    return $Count
}

function Get-InstallScripts {
         <#
        .SYNOPSIS
            Gets all scripts within a specific folder which match the filter
        
        .DESCRIPTION
            Gets all scripts within a specific folder which match the filter

        .PARAMETER Path
            Path to the files

        .PARAMETER Filter
            Filter for which scripts should be looked for

        .EXAMPLE
            Get-InstallScripts .

        .EXAMPLE
            Get-InstallScripts . -Filter ".*\.filter\.ps1"
    #>
    param(
        [Parameter(Position = 0, Mandatory = $true, HelpMessage = "Path to the *.install.ps1")]
        [string] $Path, 

        [string] $Filter
    )    

    $InstallScripts = @()
    
    if ((Get-Item $Path) -is [System.IO.DirectoryInfo]) {
        $FoundInstallScripts = Get-ChildItem $Path | Where-Object {$_.Name -match  $Filter }
        if ($FoundInstallScripts.Length -gt 0) {            
            $FoundInstallScripts | ForEach-Object {
                $InstallScripts += $_.FullName
            }
        }
    } else {
        if ($Path -match $Filter) {
            $InstallScripts += (Get-Item $Path)    
        }        
    }
    
   if ($InstallScripts.Length -lt 1) {
        Write-Host "No File found witch matches the Filter $Filter to run Invoke-Install on it"
    } else {
        return $InstallScripts
    }

}