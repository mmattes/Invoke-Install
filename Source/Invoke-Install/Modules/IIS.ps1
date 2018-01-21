function New-IISWebsite
{
    <#
        .SYNOPSIS
            Creates a new IIS website 
        
        .DESCRIPTION
            Uses the PowerShell Web Administration SnapIn to creates a new IIS website 

        .PARAMETER name
            Name of the website to create in IIS

        .PARAMETER root
            Root path of the website

        .PARAMETER appPool
            Name of the AppPool to be created, use New-IISApplicationPool to create one. 
            
            Default = DefaultAppPool
        
        .PARAMETER bindings
            The bindings for the website e.g. @{protocol='http';bindingInformation=':80:'}.
            You can also leave this blank and use the WebAdministration to change the binding
            after the website is created. Call Use-WebAdministration to make sure the WebAdministration
            Module is loaded. 

            Default = @{protocol='http';bindingInformation=':80:'}

        .EXAMPLE
            New-IISWebsite -name "MyWebsite" -root "C:\inetsrv\www"

        .EXAMPLE
            New-IISWebsite -name "MyWebsite" -root "C:\inetsrv\www" -bindings @{protocol='http';bindingInformation='*:80:www.mysite.com'}

        .EXAMPLE
            New-IISWebsite -name "MyWebsite" -root "C:\inetsrv\www" -appPool "MyAppPool" -bindings @{protocol='http';bindingInformation='192.168.100.55:80:www.mysite.com'}
    #>

    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $name     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $root     = $null,

        [string]  $appPool  = "DefaultAppPool",
        [Object[]]$bindings = $null
    )
    
    Begin {
        Use-WebAdministration
        # IIS Directory Settings
        [string]$iisSite = "IIS:\Sites\$($name)\"
    }
    
    Process {
        Write-Log "Creating IIS Website: $name"
        
        if($bindings)
        {
            New-Item $iisSite -Type Site -Bindings $bindings -PhysicalPath $root
        }
        else
        {
            # New-Item is not possible without a Binding, we add one here, you need to remove it later on
            New-Item $iisSite -Type Site -PhysicalPath $root -Bindings @{protocol='http';bindingInformation=':80:'}
        }
        
        Set-ItemProperty $iisSite -Name ApplicationPool -Value $appPool
    }
    
    End { 
    }
}

function Remove-IISWebsite
{
    <#
        .SYNOPSIS
            Removes a IIS website 
        
        .DESCRIPTION
            Uses the PowerShell Web Administration SnapIn to remove a IIS website 

        .PARAMETER name
            Name of the website to remove in IIS
        
        .EXAMPLE
            Remove-IISWebsite -name "MyWebsite"
    #>

    param(                
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name    = $null
    )
    
    Begin {
        Use-WebAdministration
        # IIS Directory Settings
        [string]$iisSite = "IIS:\Sites\$($name)"
    }
    
    Process {
        # Remove Website
        if(Test-Path $iisSite)
        {
            Write-Log "Deleting IIS Website: $name"
            
            Remove-Website $name
        }
    }
    
    End { 
    }
}


function New-IISApplicationPool
{
    <#
        .SYNOPSIS
            Creates a new IIS Application Pool
        
        .DESCRIPTION
            Uses the PowerShell Web Administration SnapIn to create a new IIS Application Pool

        .PARAMETER Name
            Name of the Application Pool

        .PARAMETER Enable32Bit
            When true, enables a 32-bit application to run on a computer that runs a 64-bit version of Windows.

            The default value is false

        .PARAMETER StartMode
            Specifies the startup type for the application pool.

            Note: This attribute was added in IIS 7.5.

            The startMode attribute can be one of the following possible values; the default value is OnDemand.

            Possible values:
            AlwaysRunning
            OnDemand

        .PARAMETER ManagedRuntimeVersion
            Specifies the .NET Framework version to be used by the application pool.

            The managedRuntimeVersion attribute can be one of the following possible values; the default value is "".

            Possible values:
            v1.1
            v2.0
            v4.0

        .PARAMETER IdleTimeout
            When these settings are configured, a worker process will shut down after a specified period of inactivity. 
            The default value for idle time-out is 20 minutes.

        .PARAMETER PeriodicRestartTime
            The PeriodicRestartTime value contains configuration settings that allow you to control when an 
            application pool is recycled.

        .PARAMETER IdentityType
            Possible values:
            0 = LocalSystem 
            1 = LocalService
            2 = NetworkService
            3 = SpecificUser
            4 = ApplicationPoolIdentity

        .PARAMETER User
            Specifies the User under which the Application Pool should be running. Only needed if IdentityType is set to SpecificUser

        .PARAMETER Password
            Specifies the Password for the User under which the Application Pool should be running. Only needed if IdentityType is set to SpecificUser

        .PARAMETER LoadUserProfile
            Defines wether or not the Application Pool should load the user profile or not. Only needed if IdentityType is set to SpecificUser
        
        .EXAMPLE
            New-IISApplicationPool -Name "MyAppPool"

        .EXAMPLE
            New-IISApplicationPool -Name "MyAppPool" -StartMode "AlwaysRunning" -IdentityType 4

        .EXAMPLE
            New-IISApplicationPool -Name "MyAppPool" -StartMode "AlwaysRunning" -IdentityType 3 -User ".\MyUser" -Passsword "MyPassword"
    #>

    param(
        # Application Pool Settings
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Name                  = $null,
        
        [bool]  $Enable32Bit           = $false,
        
        [string]$StartMode             = $null,
        [string]$ManagedRuntimeVersion = $null,
        [string]$IdleTimeout           = $null,
        [string]$PeriodicRestartTime   = $null,
        
                $IdentityType          = $null,
        [string]$User                  = $null,
        [string]$Password              = $null,
        [bool]  $LoadUserProfile       = $true
    )
    
    Begin {
        Use-WebAdministration
        # IIS Directory Settings
        [string]$IisPool = "IIS:\AppPools\$($name)\"
        
        # Sets the application pool settings for the given parameter
        function Set-AppPoolProperties([PSObject]$Pool)
        {
            if(-not $pool) { throw "Empty application pool, Argument -Pool is missing" }
            
            Write-Log "Configuring ApplicationPool properties"
            
            if ($StartMode            ) { $Pool.startMode                      = $StartMode             }
            if ($ManagedRuntimeVersion) { $Pool.managedRuntimeVersion          = $ManagedRuntimeVersion }
            if ($IdleTimeout          ) { $Pool.processModel.idleTimeout       = $IdleTimeout           }
            if ($PeriodicRestartTime  ) { $Pool.recycling.periodicRestart.time = $PeriodicRestartTime   }
            
            if ($IdentityType -ne $null)
            { 
                $Pool.processModel.identityType = $IdentityType
                
                if($IdentityType -eq 3) # 3 = SpecificUser
                {
                    if(-not $User    ) { throw "Empty user name, Argument -User is missing"  }
                    if(-not $Password) { throw "Empty password, Argument -Password is missing" }
                    
                    Write-Log "Setting AppPool to run as $User"
                    
                    $Pool.processmodel.username = $User
                    $Pool.processmodel.password = $Password
                }
            }
            
            $Pool.processModel.loadUserProfile = $LoadUserProfile
            
            $Pool | Set-Item
            
            if($Enable32Bit)
            {
                Set-ItemProperty $IisPool -Name enable32BitAppOnWin64 -Value "True"
            }
            else
            {
                Set-ItemProperty $IisPool -Name enable32BitAppOnWin64 -Value "False"
            }
        }
    }
    
    Process {
        Write-Log "Creating IIS ApplicationPool: $Name"
        
        $Pool = New-WebAppPool $Name
        
        Set-AppPoolProperties $Pool
    }
    
    End { 
    }
}

function Remove-IISApplicationPool
{
    <#
        .SYNOPSIS
            Removes an IIS Application Pool
        
        .DESCRIPTION
            Uses the PowerShell Web Administration SnapIn to remove an IIS Application Pool

        .PARAMETER name
            Name of the IIS Application Pool to remove
        
        .EXAMPLE
            Remove-IISApplicationPool -name "MyAppPool"
    #>
    param(        
        # Application Pool Settings
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name = $null
    )
    
    Begin {
        Use-WebAdministration
        # IIS Directory Settings
        [string]$iisPoolPath = "IIS:\AppPools\$($name)\"
    }
    
    Process {
        if(Test-Path $iisPoolPath)
        {
            Write-Log "Removing Application Pool: $name"
            
            Stop-IISAppPool $name
            
            Remove-WebAppPool $name
        }
    }
    
    End {
    }
}


function Stop-IISAppPool
{
    <#
        .SYNOPSIS
            Stops an IIS Application Pool
        
        .DESCRIPTION
            Uses the PowerShell Web Administration SnapIn to stopo an IIS Application Pool

        .PARAMETER name
            Name of the IIS Application Pool to stop

        .PARAMETER sleep
            Seconds to wait after the Pool stop command was send, this is sometimes needed 
            as stopping an Application Pool can take time. 
        
        .EXAMPLE
            Stop-IISAppPool -name "MyAppPool" -sleep 10
    #>
    param(
        # Application Pool Settings
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name  = $null,
        [bool]  $sleep = $false # seconds
    )
    
    Begin {
        Use-WebAdministration
        # IIS Directory Settings
        [string]$iisPoolPath = "IIS:\AppPools\$($name)\"
    }
    
    Process {
        Write-Log "Trying to stop the AppPool: $name"
        
        if (Test-Path $iisPoolPath)
        {
            if ((Get-WebAppPoolState -Name $name).Value -ne "Stopped")
            {
                Stop-WebAppPool -Name $name
                
                if (-not [string]::IsNullOrWhiteSpace($sleep))
                {
                    Start-Sleep -s $sleep
                }
                
                Write-Log "Stopped AppPool: $name"
            }
            else 
            {
                Write-Log "WARNING: AppPool $name was already stopped. Have you already run this?"
            }
        }
        else
        {
            Write-Log "WARNING: Could not find an AppPool called: $name to stop. Assuming this is a new installation."
        }
    }
    
    End { 
    }
}

function Use-WebAdministration () {
    <#
        .SYNOPSIS
            Loads the WebAdministration Module if it is not already loaded
        
        .DESCRIPTION
            Loads the WebAdministration Module if it is not already loaded
        
        .EXAMPLE
            Use-WebAdministration
    #>

    if (!(Get-Module -ListAvailable -Name WebAdministration)) {
        throw "WebAdministration Module not available, please install IIS Powershell Snap-in, https://www.microsoft.com/en-us/download/details.aspx?id=7436 or https://www.microsoft.com/en-us/download/details.aspx?id=15488"
    } 

    if (!(Get-Module WebAdministration))
    {
        ## Load it nested, and we'll automatically remove it during clean up.
        Import-Module WebAdministration -ErrorAction Stop
        Sleep 2 #see http://stackoverflow.com/questions/14862854/powershell-command-get-childitem-iis-sites-causes-an-error
    }
}