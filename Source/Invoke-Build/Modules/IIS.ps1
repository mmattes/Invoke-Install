<#
    Creates an IIS website and sets the configuration
#>
function New-IISWebsite
{
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
        
        if($bindings -ne $null)
        {
            New-Item $iisSite -Type Site -Bindings $bindings -PhysicalPath $root
        }
        else
        {
            New-Item $iisSite -Type Site -PhysicalPath $root
        }
        
        Set-ItemProperty $iisSite -Name ApplicationPool -Value $appPool
    }
    
    End { 
    }
}

<#
    Removes the IIS Website installation for the given site name.
    The application pool gets only removed if the -appPoolName parameter is supplied.
#>
function Remove-IISWebsite
{
    param(                
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name    = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$root    = $null
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

<#
    Create an application pool an set the configuration.
#>
function New-IISApplicationPool
{
    param(
        # Application Pool Settings
        [Parameter(Mandatory=$true, Position=1)]
        [string]$name                  = $null,
        
        [bool]  $enable32Bit           = $false,
        
        [string]$startMode             = $null, # AlwaysRunning, 
        [string]$managedRuntimeVersion = $null,
        [string]$idleTimeout           = $null,
        [string]$periodicRestartTime   = $null,
        
                $identityType          = $null,
        [string]$user                  = $null,
        [string]$password              = $null,
        [bool]  $loadUserProfile       = $true
    )
    
    Begin {
        Use-WebAdministration
        # IIS Directory Settings
        [string]$iisPool = "IIS:\AppPools\$($name)\"
        
        # Sets the application pool settings for the given parameter
        function Set-AppPoolProperties([PSObject]$pool)
        {
            if(-not $pool) { throw "Empty application pool, Argument -Pool is missing" }
            
            Write-Log "Configuring ApplicationPool properties"
            
            if ($startMode            ) { $pool.startMode                      = $startMode             }
            if ($managedRuntimeVersion) { $pool.managedRuntimeVersion          = $managedRuntimeVersion }
            if ($idleTimeout          ) { $pool.processModel.idleTimeout       = $idleTimeout           }
            if ($periodicRestartTime  ) { $pool.recycling.periodicRestart.time = $periodicRestartTime   }
            
            if ($identityType -ne $null)
            { 
                $pool.processModel.identityType = $identityType
                
                if($identityType -eq 3) # 3 = SpecificUser
                {
                    if(-not $user    ) { throw "Empty user name, Argument -User is missing"  }
                    if(-not $password) { throw "Empty password, Argument -Password is missing" }
                    
                    Write-Log "Setting AppPool to run as $user"
                    
                    $pool.processmodel.username = $user
                    $pool.processmodel.password = $password
                }
            }
            
            $pool.processModel.loadUserProfile = $loadUserProfile
            
            $pool | Set-Item
            
            if($enable32Bit)
            {
                Set-ItemProperty $iisPool -Name enable32BitAppOnWin64 -Value "True"
            }
            else
            {
                Set-ItemProperty $iisPool -Name enable32BitAppOnWin64 -Value "False"
            }
        }
    }
    
    Process {
        Write-Log "Creating IIS ApplicationPool: $name"
        
        $pool = New-WebAppPool $name 
        
        Set-AppPoolProperties $pool
    }
    
    End { 
    }
}

<#
    Removes the IIS application pool for the given name.
#>
function Remove-IISApplicationPool
{
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

<#
    Stop the AppPool if it exists and is running, and throws no error if it doesn't.
#>
function Stop-IISAppPool
{
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
    if (!(Get-Module WebAdministration))
    {
        ## Load it nested, and we'll automatically remove it during clean up.
        Import-Module WebAdministration -ErrorAction Stop
        Sleep 2 #see http://stackoverflow.com/questions/14862854/powershell-command-get-childitem-iis-sites-causes-an-error
    }
}