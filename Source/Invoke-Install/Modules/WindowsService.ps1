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
            $Service = Get-Service $Name | Where-Object {$_.status -eq 'Running'}

            if ($Service) {
                Write-Log "Stop Service: $Name`n"
                $Service | Stop-Service -Pass
            } 
            else {
                Write-Log "Service $Name not Running`n"
            }

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
            if(-Not (Assert-ServiceStopped)) {
                Stop-WindowsService -Name $ServiceName
            }          
            
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
        [string]$Password    = $null
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
    Adds a Windows Account to LogonAsService
#>
function Add-AccountToLogonAsService {
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Username = $null
    )
    
    Begin {
    }
    
    Process {
        $sidstr = $null
        
        try {
            $ntprincipal = new-object System.Security.Principal.NTAccount "$Username"
            $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
            $sidstr = $sid.Value.ToString()
        } catch {
            $sidstr = $null
        }
        
        Write-Log "Account: $($Username)"
        
        if([string]::IsNullOrEmpty($sidstr)) {
            Write-Log "Account $Username not found!" -LogLevel "Error"
            exit -1
        }
        
        Write-Log "Account SID: $($sidstr)"        
        
        $tmp = [System.IO.Path]::GetTempFileName()
        
        Write-Log "Export current Local Security Policy"
        
        secedit.exe /export /cfg "$($tmp)"
        
        $c = Get-Content -Path $tmp
        
        $currentSetting = ""
        
        foreach($s in $c) {
            if( $s -like "SeServiceLogonRight*") {
                $x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
                $currentSetting = $x[1].Trim()
            }
        }
        
        if( $currentSetting -notlike "*$($sidstr)*" ) {
            Write-Log "Modify Setting ""Logon as a Service"""
            
            if( [string]::IsNullOrEmpty($currentSetting) ) {
                $currentSetting = "*$($sidstr)"
            } else {
                $currentSetting = "*$($sidstr), $($currentSetting)"
            }
            
            Write-Log "$currentSetting"
            
            $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SeServiceLogonRight = $($currentSetting)
"@
        
            $tmp2 = [System.IO.Path]::GetTempFileName()
            
            
            Write-Log "Import new settings to Local Security Policy"
            $outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force
            
            #notepad.exe $tmp2
            Push-Location (Split-Path $tmp2)
            
            try {
                secedit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS 
            } finally {
                Pop-Location
            }
        } else {
            Write-Log "NO ACTIONS REQUIRED! Account already in ""Logon as a Service"""
        }
        
        Write-Log "Done."
    }
    
    end {}
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
        return $true
    }
}

function Assert-ServiceStopped()
{
    Start-Sleep -s 5
    
    $SmokeTestService = Get-Service -Name $serviceName
    
    if ($SmokeTestService.Status -ne "Stopped") {
        return $false
    } 
    else {
        return $true  
    }
}