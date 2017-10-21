<#
    Creates an Non-Sucking Service Manager Service
#>
function New-NSSMService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $ServiceBinaryPath     = $null,

        [Parameter(Mandatory=$true, Position=3)]
        [string]  $ServiceArgs     = $null,

        [Parameter(Mandatory=$true, Position=4)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    Begin {
    }
    
    Process {
        Write-Log "Creating Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "install $ServiceName $ServiceBinaryPath $ServiceArgs" -Verb runAs -Wait
        Write-Log "Service $ServiceName created"
    }
    
    End {
    }
}

<#
    Removes an Non-Sucking Service Manager Service
#>
function Remove-NSSMService
{
    Param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    Begin {
    }
    
    Process {
        Write-Log "Removing Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "remove $ServiceName confirm" -Verb runAs -Wait
        Write-Log "Service $ServiceName removed"
    }
    
    End {
    }
}

<#
    Set Non-Sucking Service Manager Parameter AppDirectory
#>
function Set-NSSMAppDirectory
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $AppDirectory     = $null,

        [Parameter(Mandatory=$true, Position=3)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    Begin {
    }
    
    Process {
        Write-Log "Set NSSM-AppDirectory $AppDirectory on Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "set $ServiceName AppDirectory $AppDirectory" -Verb runAs -Wait        
    }
    
    End {
    }
}

<#
    Starts an Non-Sucking Service Manager Service
#>
function Start-NSSMService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    Begin {
    }
    
    Process {
        Write-Log "Starting Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "start $ServiceName" -Verb runAs -Wait
        Write-Log "Service $ServiceName started"
    }
    
    End { 
    }
}

<#
    Stops an Non-Sucking Service Manager Service
#>
function Stop-NSSMService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $NSSMBinaryPath     = $null
    )
    
    Begin {
    }
    
    Process {
        Write-Log "Stopping Service $ServiceName"
        Start-Process -FilePath $NSSMBinaryPath -Args "stop $ServiceName" -Verb runAs -Wait
        Write-Log "Service $ServiceName stopped"
    }
    
    End {
    }
}