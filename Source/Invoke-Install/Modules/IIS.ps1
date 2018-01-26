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
        [Object[]]$bindings = @{protocol='http';bindingInformation=':80:'}
    )
    
    Begin {
        Use-WebAdministration
        # IIS Directory Settings
        [string]$iisSite = "IIS:\Sites\$($name)\"
    }
    
    Process {
        if(-Not (Test-Path $iisSite)) {
            Write-Log "Creating IIS Website: $name"
            New-Item $iisSite -Type Site -Bindings $bindings -PhysicalPath $root        
            Set-ItemProperty $iisSite -Name ApplicationPool -Value $appPool
        } else {
            Write-Log "IIS Website: $name already exists"
        }        
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

#TODO: Logging

function Create-IISServerFarm
{
    #TODO: Documentation
    
    <#
        .SYNOPSIS
            
        
        .DESCRIPTION

        .PARAMETER sleep            
        
        .EXAMPLE
            
    #>
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServerFarmName  = $null
    )

    Begin {
        Use-WebAdministration
        $ServerFarmHash = @{"name"=$ServerFarmName}
    }
    
    Process {
        $result = Get-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
        if ([String]::IsNullOrEmpty($result)) {
            Add-WebConfiguration -Filter "/webFarms" -Value $ServerFarmHash -PSPath "MACHINE/WEBROOT/APPHOST"
            Write-Log "Added ServerFarm $ServerFarmName" -LogLevel Information
        } else {
            Write-Log "ServerFarm $ServerFarmName already exists" -LogLevel Information
        }
    }
    
    End { 
    }
}

function Remove-IISServerFarm
{
    #TODO: Documentation
    <#
        .SYNOPSIS
            Adds a new Server Farm to an IIS Server if it does not exist
        
        .DESCRIPTION
            Adds a new Server Farm to an IIS Server using the WebAdministration Module, 

        .PARAMETER ServerFarmName 
            Specifies the name of the ServerFarm
        
        .EXAMPLE
            Create-IISServerFarm -ServerFarmName "MyServerFarm"
    #>
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServerFarmName  = $null
    )

    Begin {
        Use-WebAdministration
        $ServerFarmHash = @{"name"=$ServerFarmName}
    }
    
    Process {
        $result = Get-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
        if (-Not ([String]::IsNullOrEmpty($result))) {            
            Clear-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
            Write-Log "Removed ServerFarm $ServerFarmName" -LogLevel Information
        } else {
            Write-Log "ServerFarm $ServerFarmName does not exist" -LogLevel Information
        }
    }
    
    End { 
    }
}

function Add-IISServerToServerFarm
{
    #TODO: Documentation
    <#
        .SYNOPSIS
            Adds a new Server Farm to an IIS Server if it does not exist
        
        .DESCRIPTION
            Adds a new Server Farm to an IIS Server using the WebAdministration Module, 

        .PARAMETER ServerFarmName 
            Specifies the name of the ServerFarm
        
        .EXAMPLE
            Create-IISServerFarm -ServerFarmName "MyServerFarm"
    #>
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServerAddress  = $null,
        
        [Parameter(Mandatory=$true, Position=2)]
        [string]$ServerFarmName  = $null,
        
        [Parameter(Mandatory=$false, Position=3)]
        [bool]$Enabled  = $true,
        
        [Parameter(Mandatory=$false, Position=4)]
        [int]$Weight  = $null,
        
        [Parameter(Mandatory=$false, Position=5)]
        [int]$HttpPort  = $null,
        
        [Parameter(Mandatory=$false, Position=6)]
        [int]$HttpsPort  = $null
    )

    Begin {
        Use-WebAdministration
        $ServerFarmHash = @{"name"=$ServerFarmName}
        $ServerHash = @{"address"=$ServerAddress;"enabled"=$Enabled}
    }
    
    Process {
        $result = Get-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($ServerAddress)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
        if ([String]::IsNullOrEmpty($result)) {
            Add-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]" -Value $ServerHash -PSPath "MACHINE/WEBROOT/APPHOST"
            if($Weight) {
                Set-WebConfigurationProperty  `
                    -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($ServerAddress)""]" `
                    -Name "applicationRequestRouting" `
                    -Value @{ weight = $Weight }  `
                    -PSPath "MACHINE/WEBROOT/APPHOST"
            }
            if($HttpPort) {
                Set-WebConfigurationProperty  `
                    -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($ServerAddress)""]" `
                    -Name "applicationRequestRouting" `
                    -Value @{ httpPort = $HttpPort }  `
                    -PSPath "MACHINE/WEBROOT/APPHOST"
            }
            if($HttpsPort) {
                Set-WebConfigurationProperty  `
                    -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($ServerAddress)""]" `
                    -Name "applicationRequestRouting" `
                    -Value @{ httpsPort = $HttpsPort }  `
                    -PSPath "MACHINE/WEBROOT/APPHOST"
            }
            Write-Log "Server $ServerAddress added to the Server Farm $ServerFarmName" -LogLevel Information
        } else {
            Write-Log "Server $ServerAddress already exists in the Server Farm $ServerFarmName" -LogLevel Information
        }
    }
    
    End { 
    }
}

function Set-IISServerFarmServerState
{
    #TODO: Documentation
    <#
        .SYNOPSIS
            Adds a new Server Farm to an IIS Server if it does not exist
        
        .DESCRIPTION
            Adds a new Server Farm to an IIS Server using the WebAdministration Module, 

        .PARAMETER ServerFarmName 
            Specifies the name of the ServerFarm
        
        .EXAMPLE
            Create-IISServerFarm -ServerFarmName "MyServerFarm"
    #>
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServerAddress  = $null,
        
        [Parameter(Mandatory=$true, Position=2)]
        [string]$ServerFarmName  = $null,
        
        [Parameter(Mandatory=$true, Position=3)]
        [bool]$Online = $null       
    )

    Begin {
        Use-WebAdministration
        $ServerFarmHash = @{"name"=$ServerFarmName}
        $ServerStateHash = @{"enabled"=$Online}
        if($Online) {
            $State = "Online"
        } else {
            $State = "Offline"
        }
    }
    
    Process {
        $result = Get-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($ServerAddress)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
        if (-Not ([String]::IsNullOrEmpty($result))) {
            Set-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($ServerAddress)""]" -Value $ServerStateHash -PSPath "MACHINE/WEBROOT/APPHOST"
            Write-Log "State of server $ServerAddress in server farm $ServerFarmName was changed to $State" -LogLevel Information
        } else {
            Write-Log "Server $ServerAddress or server farm $ServerFarmName could not be found" -LogLevel Information
        }
    }
    
    End { 
    }
}

function Set-IISServerFarmHealthCheck
{
    #TODO:Documentation
    <#
        .SYNOPSIS
            Adds a new Server Farm to an IIS Server if it does not exist
        
        .DESCRIPTION
            Adds a new Server Farm to an IIS Server using the WebAdministration Module, 

        .PARAMETER ServerFarmName 
            Specifies the name of the ServerFarm
        
        .EXAMPLE
            Create-IISServerFarm -ServerFarmName "MyServerFarm"
    #>
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServerFarmName  = $null,
        
        [Parameter(Mandatory=$true, Position=2)]
        [string]$Url = $null,
        
        [Parameter(Mandatory=$true, Position=3)]
        [string]$ResponseMatch = $null
    )

    Begin {
        Use-WebAdministration       
    }
    
    Process {
        $result = Get-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
        if (-Not ([String]::IsNullOrEmpty($result))) {
            Set-WebConfigurationProperty  `
                -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/applicationRequestRouting" `
                -Name "healthCheck" `
                -Value @{ url = $Url }  `
                -PSPath "MACHINE/WEBROOT/APPHOST"
                
            Set-WebConfigurationProperty  `
                -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/applicationRequestRouting" `
                -Name "healthCheck" `
                -Value @{ responseMatch = $ResponseMatch }  `
                -PSPath "MACHINE/WEBROOT/APPHOST"
        } else {
            Write-Log "Server $ServerAddress or server farm $ServerFarmName could not be found" -LogLevel Information
        }
    }
    
    End { 
    }
}

function Add-IISGlobalRouting
{
    #TODO: Documentation
    <#
        .SYNOPSIS
            Adds a new Server Farm to an IIS Server if it does not exist
        
        .DESCRIPTION
            Adds a new Server Farm to an IIS Server using the WebAdministration Module, 

        .PARAMETER ServerFarmName 
            Specifies the name of the ServerFarm
        
        .EXAMPLE
            Create-IISServerFarm -ServerFarmName "MyServerFarm"
    #>
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$RuleName = $null,
        
        [Parameter(Mandatory=$true, Position=2)]
        [bool]$StopProcessing = $false,
        
        [Parameter(Mandatory=$true, Position=3)]
        [string]$MatchUrl = $null,
        
        [Parameter(Mandatory=$true, Position=4)]
        [array]$Conditions = $null, # @(@{"input"="{HTTP_HOST}"; "pattern"="^alwaysup$"},@{"input"="{SERVER_PORT}"; "pattern"="^80$"})
        
        [Parameter(Mandatory=$true, Position=5)]
        [hashtable]$Action = $null # @{"type"="Rewrite";url="http://myurl.com/{R:0}"}
    )

    Begin {
        Use-WebAdministration
        $RuleHash = @{"name"=$RuleName;"stopProcessing"=$StopProcessing}
    }
    
    Process {
        $result = Get-WebConfiguration -Filter "/system.webServer/rewrite/globalRules/rule[@name=""$($RuleName)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
        if (([String]::IsNullOrEmpty($result))) {
            Add-WebConfiguration `
                -Filter "/system.webServer/rewrite/globalRules" `
                -Value $RuleHash `
                -PSPath "MACHINE/WEBROOT/APPHOST"
        
            Set-WebConfigurationProperty  `
                -Filter "/system.webServer/rewrite/globalRules/rule[@name=""$($RuleName)""]" `
                -Name "match" `
                -Value @{ url = $MatchUrl }  `
                -PSPath "MACHINE/WEBROOT/APPHOST"
                
            Set-WebConfigurationProperty  `
                -Filter "/system.webServer/rewrite/globalRules/rule[@name=""$($RuleName)""]" `
                -Name "stopProcessing" `
                -Value @{ stopProcessing = $true }  `
                -PSPath "MACHINE/WEBROOT/APPHOST"
                
            Set-WebConfigurationProperty  `
                -Filter "/system.webServer/rewrite/globalRules/rule[@name=""$($RuleName)""]" `
                -Name "action" `
                -Value $Action  `
                -PSPath "MACHINE/WEBROOT/APPHOST"
                
            $Conditions | ForEach-Object {
                Add-WebConfiguration `
                    -Filter "/system.webServer/rewrite/globalRules/rule[@name=""$($RuleName)""]/conditions" `
                    -Value $_ `
                    -PSPath "MACHINE/WEBROOT/APPHOST"
            }
        } else {
            Write-Log "Rule $RuleName already exists, Add-IISGlobalRouting will do nothing" -LogLevel Information
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