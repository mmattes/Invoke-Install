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
            
        .PARAMETER Filter
            Specifies a filter for the name of the iis site, all sites matching the filter will be removed
            
        .PARAMETER Exclude
            Specifies which sites should be excluded when using the filter parameter
        
        .EXAMPLE
            Remove-IISWebsite -name "MyWebsite"
            
        .EXAMPLE
            Remove-IISWebsite -Filter "MySite.*" -Exclude "MySite.1.1.14"
    #>

    param(                
        [CmdletBinding(DefaultParameterSetName='ByName')]
        [Parameter(Mandatory=$true, ParameterSetName='ByName', Position=1)]
        [string]$name    = $null,
        
        [Parameter(Mandatory=$true, ParameterSetName='ByFilter', Position=2)]
        [string]$Filter    = $null,
        
        [Parameter(Mandatory=$false, ParameterSetName='ByFilter', Position=2)]
        [string]$Exclude    = ""
    )
    
    Begin {
        Use-WebAdministration
        
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            # IIS Directory Settings
            [string]$iisSite = "IIS:\Sites\$($name)"
        }
    }
    
    Process {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            if(Test-Path $iisSite)
            {
                Write-Log "Deleting IIS Website: $name"
                Remove-Website $name
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'ByFilter') {
            $Result = Get-Item -Path "IIS:\Sites\$Filter"
            foreach ($Item in $Result) {
                if ($Item.Name -notlike $Exclude) {
                    Remove-Website $Item.Name
                }
            }
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
            
        .PARAMETER Filter
            Specifies a filter for the name of the iis apppool, all apppools matching the filter will be removed
            
        .PARAMETER Exclude
            Specifies which apppool should be excluded when using the filter parameter
        
        .EXAMPLE
            Remove-IISApplicationPool -name "MyAppPool"
            
        .EXAMPLE
            Remove-IISApplicationPool -Filter "MyAppPool.*" -Exclude "MyAppPool.1.1.14"
    #>
    param(        
        [CmdletBinding(DefaultParameterSetName='ByName')]
        [Parameter(Mandatory=$true, ParameterSetName='ByName', Position=1)]
        [string]$name    = $null,
        
        [Parameter(Mandatory=$true, ParameterSetName='ByFilter', Position=2)]
        [string]$Filter    = $null,
        
        [Parameter(Mandatory=$false, ParameterSetName='ByFilter', Position=2)]
        [string]$Exclude    = ""
    )
    
    Begin {
        Use-WebAdministration
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            # IIS Directory Settings
            [string]$iisPoolPath = "IIS:\AppPools\$($name)"
        }        
    }
    
    Process {
        if ($PSCmdlet.ParameterSetName -eq 'ByName')
        {
            if(Test-Path $iisPoolPath)
            {
                Write-Log "Removing Application Pool: $name"
                Stop-IISAppPool $name
                Remove-WebAppPool $name
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'ByFilter') {
            $Result = Get-Item -Path "IIS:\AppPools\$Filter"
            foreach ($Item in $Result) {
                if ($Item.Name -notlike $Exclude) {
                    Stop-IISAppPool $Item.Name
                    Remove-WebAppPool $Item.Name
                }
            }
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

function Create-IISServerFarm
{
    <#
        .SYNOPSIS
            Creates an IIS Server Farm with the specified ServerFarmName if it does not already exist
        
        .DESCRIPTION
            Creates an IIS Server Farm with the specified ServerFarmName if it does not already exist

        .PARAMETER ServerFarmName
            Specifies the name of the server farm to create
        
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
        if ([String]::IsNullOrEmpty($result)) {
            Add-WebConfiguration -Filter "/webFarms" -Value $ServerFarmHash -PSPath "MACHINE/WEBROOT/APPHOST"
            Write-Log "Created ServerFarm: $ServerFarmName" -LogLevel Information
        } else {
            Write-Log "ServerFarm $ServerFarmName already exists" -LogLevel Information
        }
    }
    
    End { 
    }
}

function Remove-IISServerFarm
{
    <#
        .SYNOPSIS
            Removes server farm from IIS if it exists
        
        .DESCRIPTION
            Removes server farm from IIS if it exists

        .PARAMETER ServerFarmName 
            Specifies the name of the ServerFarm to be removed
        
        .EXAMPLE
            Remove-IISServerFarm -ServerFarmName "MyServerFarm"
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
            Write-Log "Removed server farm: $ServerFarmName" -LogLevel Information
        } else {
            Write-Log "Server farm $ServerFarmName does not exist" -LogLevel Information
        }
    }
    
    End { 
    }
}


function Set-IISAppPoolConfig
{
    <#
        .SYNOPSIS
            Sets the config for the AppPool specified by the parameter AppPoolName
        
        .DESCRIPTION
            Sets the config for the AppPool specified by the parameter AppPoolName

        .PARAMETER AppPoolName
            Specifies the AppPool where the configuration should be changed

        .PARAMETER IdleTimeout
            Specifies the IdleTimeout value to be set for the specified AppPool

        .PARAMETER AppPoolName
            Specifies the PeriodicRestart value to be set for the specified AppPool
        
        .EXAMPLE
            Set-IISAppPoolConfig -AppPoolName "MyAppPool" -IdleTimeout "00:00:00" -PeriodicRestart "00:00:00"
    #>
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$AppPoolName  = $null,

        [Parameter(Mandatory=$false, Position=2)]
        [string]$IdleTimeout  = $null,

        [Parameter(Mandatory=$false, Position=3)]
        [string]$PeriodicRestart  = $null
    )

    Begin {
        Use-WebAdministration        
    }
    
    Process {
        $result = Get-WebConfiguration -Filter "/system.applicationHost/applicationPools/add[@name=""$($AppPoolName)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
        if (-Not ([String]::IsNullOrEmpty($result))) {
            if($IdleTimeout) {
                Set-WebConfigurationProperty `
                    -Filter "/system.applicationHost/applicationPools/add[@name=""$($AppPoolName)""]" `
                    -Name "processModel" `
                    -Value @{"idleTimeout"=$IdleTimeout} `
                    -PSPath "MACHINE/WEBROOT/APPHOST"
            }
            
            if($PeriodicRestart) {
                Set-WebConfigurationProperty `
                    -Filter "/system.applicationHost/applicationPools/add[@name=""$($AppPoolName)""]/recycling" `
                    -Name "periodicRestart" `
                    -Value @{"time"=$PeriodicRestart} `
                    -PSPath "MACHINE/WEBROOT/APPHOST"
            }
        } else {
            Write-Log "AppPool $AppPoolName does not exist" -LogLevel Information
        }
    }
    
    End { 
    }
}


function Add-IISServerToServerFarm
{
    <#
        .SYNOPSIS
            Adds a server to a IIS server farm
        
        .DESCRIPTION
            Adds a server to a IIS server farm if the server farm exists

        .PARAMETER ServerAddress
            Specifies the address of the server which should be added to the server farm

        .PARAMETER ServerFarmName 
            Specifies the name of the server farm to which the server should be added
        
        .PARAMETER Enabled
            Specifies whether or not the server should be added as online or offline to the server farm

            Default = $true

        .PARAMETER Weight
            Specifies the weight for the routing / load balancing

        .PARAMETER HttpPort
            Specifies the HTTP port under which the server is litening at the given ServerAddress

        .PARAMETER HttpPort
            Specifies the HTTPS port under which the server is litening at the given ServerAddress
        
        .EXAMPLE
            Add-IISServerToServerFarm -ServerFarmName "MyServerFarm" -ServerAddress "a.myfarm.example.com" -HttpPort 8001

        .EXAMPLE
            Add-IISServerToServerFarm -ServerFarmName "MyServerFarm" -ServerAddress "a.myfarm.example.com" -HttpPort 8001 -Weight 50
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
            Write-Log "Server $ServerAddress added to the server farm $ServerFarmName" -LogLevel Information
        } else {
            Write-Log "Server $ServerAddress already exists in the server farm $ServerFarmName" -LogLevel Information
        }
    }
    
    End { 
    }
}

function Remove-IISServerFromServerFarm
{
    <#
        .SYNOPSIS
            Removes one or more servers from the sever farm
        
        .DESCRIPTION
            Removes one or more servers from the sever farm, either use SeverAddress or Filter

        .PARAMETER ServerAddress
            Specifies the address of the server which should be removed from the server farm

        .PARAMETER ServerFarmName 
            Specifies the name of the server farm from which one or more servers should be removed 
        
        .PARAMETER Filter
            Specifies a filter for the address of the server, all servers matching the filter will be removed
            
        .PARAMETER Exclude
            Specifies which server address should be excluded when using the filter parameter

        .EXAMPLE
            Remove-IISServerFromServerFarm -ServerFarmname "MyServerFarm" -ServerAddress "a.myserver.com"

        .EXAMPLE
            Remove-IISServerFromServerFarm -ServerFarmname "MyServerFarm" -Filter "*.myserver.com" -Exclude "b.myserver.com"
    #>
    param(        
        [CmdletBinding(DefaultParameterSetName='ByAddress')]
        [Parameter(Mandatory=$true, ParameterSetName='ByAddress', Position=1)]      
        [string]$ServerAddress  = $null,
        
        [Parameter(Mandatory=$true, ParameterSetName='ByAddress', Position=2)]
        [Parameter(Mandatory=$true, ParameterSetName='ByFilter', Position=2)]
        [string]$ServerFarmName  = $null,
        
        [Parameter(Mandatory=$true, ParameterSetName='ByFilter', Position=3)]
        [string]$Filter  = $null,
        
        [Parameter(Mandatory=$false, ParameterSetName='ByFilter', Position=4)]
        [string]$Exclude  = ""
    )

    Begin {
        Use-WebAdministration
    }
    
    Process {
        $result = Get-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
        if (([String]::IsNullOrEmpty($result))){
            Write-Log "Server farm $ServerFarmName not found" -LogLevel Information
            return
        }
        
        if ($PSCmdlet.ParameterSetName -eq 'ByAddress') {
            $result = Get-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($ServerAddress)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
            if (-not ([String]::IsNullOrEmpty($result))){ 
                Clear-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($ServerAddress)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
                Write-Log "Server $ServerAddress remove from sever farm $ServerFarmName" -LogLevel Information
            } else {
                Write-Log "Server $ServerAddress could not be found in server farm $ServerFarmName" -LogLevel Information
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'ByFilter') {
            $result = Get-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@*]" -PSPath "MACHINE/WEBROOT/APPHOST"
            if (-not ([String]::IsNullOrEmpty($result))) {
                foreach ($server in $result) {
                    if (($server.Address -like $Filter) -and ($server.Address -notlike $Exclude)) {
                        Clear-WebConfiguration -Filter "/webFarms/WebFarm[@name=""$($ServerFarmName)""]/server[@address=""$($server.Address)""]" -PSPath "MACHINE/WEBROOT/APPHOST"
                        Write-Log "Server $server.Address remove from sever farm $ServerFarmName" -LogLevel Information
                    }
                }
            } else {
                Write-Log "Server farm $ServerFarmName does not contain any servers" -LogLevel Information
            }
        }
    }
    
    End { 
    }
}

function Set-IISServerFarmServerState
{
    <#
        .SYNOPSIS
            Changes the state of a server within a iis server farm
        
        .DESCRIPTION
            Changes the state of a server within a iis server farm

        .PARAMETER ServerAddress
            Specifies the address of the server which should be added to the server farm

        .PARAMETER ServerFarmName 
            Specifies the name of the server farm to which the server should be added

        .PARAMETER Online
            Specifies whether or not the server should be set online or offline
        
        .EXAMPLE
            Set-IISServerFarmServerState -ServerFarmName "MyServerFarm" -ServerAddress "a.myfarm.example.com" -Online $false
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
    <#
        .SYNOPSIS
            Sets the IIS health check for a IIS server farm
        
        .DESCRIPTION
            Sets the IIS health check for a IIS server farm

        .PARAMETER ServerFarmName 
            Specifies the name of the server farm
        
        .PARAMETER Url
            Specifies the URL which should be verified to validate health of a server within the server farm

        .PARAMETER ResponseMatch
            Specifies the expected response from the url if a server is healty
        
        .EXAMPLE
            Set-IISServerFarmHealthCheck -ServerFarmName "MyServerFarm" -Url "a.myfarm.example.com/health.html" -ResponseMatch "up"
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

            Write-Log "Set health check for server farm $ServerFarmName to Url $Url, ResponseMatch: $ResponseMatch" -LogLevel Information
        } else {
            Write-Log "Server $ServerAddress or server farm $ServerFarmName could not be found" -LogLevel Information
        }
    }
    
    End { 
    }
}

function Add-IISGlobalRouting
{
    <#
        .SYNOPSIS
            Adds a new global routing to IIS 
        
        .DESCRIPTION
            Adds a new global routing to IIS if it does not already exist
            
        .PARAMETER RuleName
            Specifies the name of the rule to be added
        
        .PARAMETER StopProcessing
            Specifies wether or not other rules should be processed after this one 

        .PARAMETER MatchUrl
            Specifies the url which needs to be matched so that this rule applies. 
            This match is for the content behind the domain so in case of 
            www.sample.com/foo/bar it is about the /foo/bar part

        .PARAMETER Conditions
            Specifies further conditions which need to match in order to continue with the action.
            This needs to be provided as an array of hashes. 
            @(@{"input"="{HTTP_HOST}"; "pattern"="^www.sample.com$"},@{"input"="{SERVER_PORT}"; "pattern"="^80$"})

        .PARAMETER Action
            Specifies the action to be performed when the url and conditions match
            This is a hashtable of the format @{"type"="Rewrite";url="http://myurl.com/{R:0}"}
            In case of redirecting to a server farm the myurl.com part needs to match the exact name of the 
            server farm on this IIS server
        
        .EXAMPLE
            Add-IISGlobalRouting -RuleName "Rewrite myurl.com to ServerFarm MyServerFarm" -MatchUrl ".*" -Conditions @(@{"input"="{HTTP_HOST}"; "pattern"="^myurl.com$"},@{"input"="{SERVER_PORT}"; "pattern"="^80$"}) -Action @{"type"="Rewrite";url="http://MyServerFarm/{R:0}"} -StopProcessing $false
    #>
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$RuleName = $null,
        
        [Parameter(Mandatory=$true, Position=2)]
        [bool]$StopProcessing = $false,
        
        [Parameter(Mandatory=$true, Position=3)]
        [string]$MatchUrl = $null,
        
        [Parameter(Mandatory=$true, Position=4)]
        [array]$Conditions = $null, 
        
        [Parameter(Mandatory=$true, Position=5)]
        [hashtable]$Action = $null 
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

            Write-Log "Created rule: $RuleName" -LogLevel Information

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


function Get-ServerFarm {
    <#
        .SYNOPSIS
            Gets a specified ServerFarm
        
        .DESCRIPTION
            Gets a specified ServerFarm
            
        .PARAMETER ServerFarmName
            Specifies the name of the Server Farm you want to modify
        
        .EXAMPLE
            Get-ServerFarm -ServerFarmName "MyServerFarm"
    #>
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServerFarmName = $null
    )

    Begin {
        $Assembly = [System.Reflection.Assembly]::LoadFrom("$Env:systemroot\system32\inetsrv\Microsoft.Web.Administration.dll")
        $ServerManager = new-object Microsoft.Web.Administration.ServerManager "$Env:systemroot\system32\inetsrv\config\applicationhost.config"
    }
    
    Process {
        $Config = $ServerManager.GetApplicationHostConfiguration()
        $Section = $Config.GetSection("webFarms")
        $WebFarms = $Section.GetCollection()
        $WebFarm = $WebFarms | Where {
            $_.GetAttributeValue("name") -eq $ServerFarmName
        }

        return $WebFarm    
    }
    
    End { 
    }    
}


function Set-IISServerFarmServerAvailability {
    <#
        .SYNOPSIS
            Sets the availability of a server within a server farm
        
        .DESCRIPTION
            Sets the availability of a server within a server farm, possible values are
            0 = Available
            1 = Drain
            2 = Unavailable
            3 = Unavailable Gracefully
            
        .PARAMETER ServerFarmName
            Specifies the name of the Server Farm you want to modify

        .PARAMETER SeverAddress
            Specifies the server address (url) of the server of which the availability should be changed

        .PARAMETER Filter
            Specifies a filter for the name of the server ulr, all sites matching the filter will be set to the new
            availability
            
        .PARAMETER Exclude
            Specifies which sites should be excluded when using the filter parameter        

        .PARAMETER Availability
            Specifies the availability of a server within a server farm, possible values are
            0 = Available
            1 = Drain
            2 = Unavailable
            3 = Unavailable Gracefully
        
        .EXAMPLE
            Set-IISServerFarmServerAvailability -ServerFarmName "MyServerFarm" -SeverAddress "server-a.myserver.com" -Availability 0

        .EXAMPLE
            Set-IISServerFarmServerAvailability -ServerFarmName "MyServerFarm" -Filter "*.myserver.com" -Exclude "blue.myserver.com" -Availability 0
    #>
    param(
        [CmdletBinding(DefaultParameterSetName='BySeverAddress')]
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServerFarmName = $null,

        [Parameter(Mandatory=$true, ParameterSetName='BySeverAddress', Position=2)]
        [string]$SeverAddress = $null,

        [Parameter(Mandatory=$true, ParameterSetName='ByFilter', Position=3)]
        [string]$Filter = $null,

        [Parameter(Mandatory=$false, ParameterSetName='ByFilter', Position=4)]
        [string]$Exclude = $null,

        [Parameter(Mandatory=$true, Position=5)]
        [int]$Availability = $null
    )

    Begin {        
        $ServerFarm = Get-ServerFarm $ServerFarmName
        $Servers = $ServerFarm.GetCollection()
    }
    
    Process {
        if (($Availability -lt 0) -or ($Availability -gt 3)) {
            Write-Host "Availability needs to be between 0 and 3" 
            return
        }

        if ($PSCmdlet.ParameterSetName -eq 'BySeverAddress')
        {
            $Servers = $Servers | Where {
                $_.GetAttributeValue("address") -eq $ServerAddress
            }    
        }

        if ($PSCmdlet.ParameterSetName -eq 'ByFilter')
        {
            $Servers = $Servers | Where {                
                ($_.GetAttributeValue("address") -like $Filter) -and ($_.GetAttributeValue("address") -notlike $Exclude)
            }    
        }   
        
        foreach($server in $servers) {
            $arr = $Server.GetChildElement("applicationRequestRouting")
            $MethodInstance = $arr.Methods["SetState"].CreateInstance()
       
            $MethodInstance.Input.Attributes[0].Value = $Availability
            $MethodInstance.Execute()
        }
    }
    
    End { 
    }    
}