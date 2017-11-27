<#
    Stops the given Windows Service and waits for 5 seconds.
#>
function Stop-WindowsService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Name  = $null,
        
        [Parameter(Mandatory=$false, Position=2)]
        [string]$Sleep = 5 # seconds
    )
    
    Begin {
    }
    
    Process {
        # Verify if the service exists, and if yes stop it and wait for new state.
        if(Assert-ServiceExists $Name) {
            # Stop Service
            Write-Log "Stop Service: $Name`n"
            
            Get-Service $Name | Where-Object {$_.status -eq 'Running'} | Stop-Service -Pass

            Start-Sleep -s $Sleep
        }
    }
    
    End {
    }
}

<#
    Removes the given Windows Service.
#>
function Remove-WindowsService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServiceName = $null
    )
    
    Begin {
    }
    
    Process {
        # Verify if the service already exists, and if yes remove it
        if(Assert-ServiceExists $ServiceName) {
            Stop-WindowsService -Name $ServiceName
            
            # Remove Service
            Start-Process -FilePath sc.exe -Args "delete $ServiceName" -Verb runAs -Wait
            
            Write-Log "Service removed: $ServiceName"
        }
    }
    
    End {
    }
}

<#
    Creates a Windows Service and sets the configuration.
#>
function New-WindowsService
{
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$ServiceName = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$DisplayName = $null,

        [Parameter(Mandatory=$true, Position=3)]
        [string]$BinaryPath  = $null,

        [Parameter(Mandatory=$false, Position=4)]
        [string]$Description = $null,

        [Parameter(Mandatory=$false, Position=5)]
        [string]$StartUpType = $null, # Automatic, Manual, Disabled

        [Parameter(Mandatory=$false, Position=6)]
        [string]$DelayedStart= $null, # DelayedAutoStart

        [Parameter(Mandatory=$false, Position=7)]
        [string]$User       = $null, # NT AUTHORITY\LocalSystem, NT AUTHORITY\LocalService, NT AUTHORITY\NetworkService, <Domain\User>

        [Parameter(Mandatory=$false, Position=8)]
        [securestring]$SecurePassword    = $null
    )
    
    Begin {
        if ((Test-Path $BinaryPath) -eq $false)
        {
            Write-Log "Service binary path not found: $BinaryPath. Service was NOT installed." -LogLevel Error
        }
    }
    
    Process {
        Write-Log "Installing service: $serviceName`n"
        
        # Install dotNET Service.
        
        New-Service -BinaryPathName $BinaryPath -Name $ServiceName -DisplayName $DisplayName
                    
        if($Description) {
            Set-Service $ServiceName -Description $Description
        }
        
        if($StartUpType) {
            Set-Service $ServiceName -StartupType $StartupType
            
            if($StartUpType -eq "Automatic" -and $DelayedStart) {
                Start-Process -FilePath sc.exe -Args "config $ServiceName start=delayed-auto" -Verb runAs -Wait
            }
        }
        
        if($User) {
            # if password is empty, create a dummy one to allow having credentials for system accounts:
            # NT AUTHORITY\LocalSystem
            # NT AUTHORITY\LocalService
            # NT AUTHORITY\NetworkService
            $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
            $Password = $Credentials.GetNetworkCredential().Password 

            if ([string]::IsNullOrEmpty($Password)) {
                $Password = "dummy"
            }
            else {
                # Add account to logon as a service.
                Add-AccountToLogonAsService $User
            }
            
            $Service = Get-WmiObject -Class Win32_Service -Filter "name='$ServiceName'"
            
            Stop-WindowsService -Name $ServiceName
            
            $Service.change($null, $null, $null, $null, $null, $null, $User, $Password, $null, $null, $null)
        }
        
        Write-Log "Installation completed: $ServiceName"
    }
    
    End {
    }
}

<# 
    Determines if a Service exists with a name as defined in $serviceName.
    Returns a boolean $True or $false.
#> 
function Assert-ServiceExists {
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string] $Name
    )

    # If you use just "Get-Service $Name", it will return an error if 
    # the service didn't exist.  Trick Get-Service to return an array of 
    # Services, but only if the name exactly matches the $Name.  
    # This way you can test if the array is empty.
    if (Get-Service "$Name*" -Include $Name) {
        return $true
    }
    Write-Log "The Service $Name does not Exist" -LogLevel "Error"
    
    return $false
}

<# 
    Starts the given Windows Service and waits for the service to reach the Stopped state or a maximum of 2 minutes seconds.
#> 
function Start-WindowsService()
{
    Get-Service -Name $serviceName | Set-Service -Status Running
    Assert-ServicesStarted
}

function Assert-ServicesStarted () 
{
    Start-Sleep -s 5
    
    $SmokeTestService = Get-Service -Name $serviceName
    
    if ($SmokeTestService.Status -ne "Running") {
        Throw "Smoke test: FAILED. (SERVICE FAILED TO START)"
    } 
    else {
    }
}