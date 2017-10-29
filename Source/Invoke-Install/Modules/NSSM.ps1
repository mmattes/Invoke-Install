function New-NSSMService
{
     <#
        .SYNOPSIS
            Creates a new service using the None-Sucking Service Manager
        
        .DESCRIPTION
            Some binaries for example node are not built that they can be run as a service in Windows
            By using a tool like the None-Sucking Service Manager which will wrap around them 
            you can still get the binary running as a service. 

        .PARAMETER ServiceName
            Name of the service under which it will be listed

        .PARAMETER ServiceBinaryPath
            Path to the binary which should be run as a service

        .PARAMETER ServiceArgs
            Arguments which should be past to the ServiceBinary

        .PARAMETER NSSMBinaryPath
            Path to the nssm.exe which is needed to run the binary as a service
            
        .EXAMPLE
            New-NSSMService -ServiceName "MyService" -ServiceBinaryPath "C:\MyService.exe" -NSSMBinaryPath "C:\nssm.exe"
            New-NSSMService -ServiceName "MyService" -ServiceBinaryPath "C:\MyService.exe" -ServiceArgs "-silent" -NSSMBinaryPath "C:\nssm.exe"
    #>
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ServiceName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $ServiceBinaryPath     = $null,

        [Parameter(Mandatory=$false, Position=3)]
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

function Remove-NSSMService
{
     <#
        .SYNOPSIS
            Removes a service which got installed by using the None-Sucking Service Manager
        
        .DESCRIPTION
            Removes a service which got installed by using the None-Sucking Service Manager

        .PARAMETER ServiceName
            Name of the service under which it will be removed

        .PARAMETER NSSMBinaryPath
            Path to the nssm.exe which is needed to run the binary as a service
            
        .EXAMPLE
            Remove-NSSMService -ServiceName "MyService" -NSSMBinaryPath "C:\nssm.exe"            
    #>
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

function Set-NSSMAppDirectory
{
    <#
        .SYNOPSIS
            Sets the parameter AppDirectory for a service installed by the None-Sucking Service Manager
        
        .DESCRIPTION
            Sets the parameter AppDirectory for a service installed by the None-Sucking Service Manager

        .PARAMETER ServiceName
            Name of the service for which we will set the AppDirectory parameter

        .PARAMETER AppDirectory
            The applications working directory
        
        .PARAMETER NSSMBinaryPath
            Path to the nssm.exe which is needed to run the binary as a service

        .EXAMPLE
            Set-NSSMAppDirectory -ServiceName "MyService" -AppDirectory "C:\MyServiceRunsHere" -NSSMBinaryPath "C:\nssm.exe"
    #>
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


function Start-NSSMService
{
    <#
        .SYNOPSIS
            Starts a Service which is run by the None-Sucking Service Manager
        
        .DESCRIPTION
            Starts a Service which is run by the None-Sucking Service Manager

        .PARAMETER ServiceName
            Name of the service to be started by using the None-Sucking Service Manager
               
        .PARAMETER NSSMBinaryPath
            Path to the nssm.exe which is needed to start the service

        .EXAMPLE
            Start-NSSMService -ServiceName "MyService" -NSSMBinaryPath "C:\nssm.exe"
    #>
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

function Stop-NSSMService
{
    <#
        .SYNOPSIS
            Stops a Service which is run by the None-Sucking Service Manager
        
        .DESCRIPTION
            Stops a Service which is run by the None-Sucking Service Manager

        .PARAMETER ServiceName
            Name of the service to be stopped by using the None-Sucking Service Manager
               
        .PARAMETER NSSMBinaryPath
            Path to the nssm.exe which is needed to stop the service

        .EXAMPLE
            Stop-NSSMService -ServiceName "MyService" -NSSMBinaryPath "C:\nssm.exe"
    #>
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