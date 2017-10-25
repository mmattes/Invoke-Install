# TODO: Loggin

<#
    Creates a Windows Task and sets the configuration.
#>
function New-WindowsTask
{
    param(
        # Windows Task Settings
        [Parameter(Mandatory=$true, Position=1)]
        [string]$TaskName    = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$TaskPath    = $null,

        # TODO: Improve that, this is not plain simple
        [Parameter(Mandatory=$true, Position=3)]
        $Action      = $null,
        
        # TODO: Improve that, this is not plain simple
        [Parameter(Mandatory=$true, Position=4)]
        $Trigger     = $null,
        
        [Parameter(Mandatory=$false, Position=5)]
        [string]$Description = $null,

        [Parameter(Mandatory=$false, Position=6)]
        [string]$User        = $null,
        
        [Parameter(Mandatory=$false, Position=7)]
        [securestring]$SecurePassword    = $null,

        # TODO: Improve that, this is not plain simple
        [Parameter(Mandatory=$false, Position=8)]
                $Settings    = $null
    )
    
    Begin {
        
        # PRIVATE FUNCTIONS
        function New-ScheduledTaskFolder
        {
            $ErrorActionPreference = "stop"
            
            $ScheduleObject = New-Object -ComObject schedule.service
            
            $ScheduleObject.connect()
            
            $RootFolder = $ScheduleObject.GetFolder("\")
            
            try
            {
                $null = $ScheduleObject.GetFolder($TaskPath)
            }
            catch
            {
                $null = $RootFolder.CreateFolder($TaskPath)
            }
            finally
            {
                $ErrorActionPreference = "continue"
            }
        }
    }
    
    Process {
        Write-Log "Installing Windows Task: $TaskName"
                
        New-ScheduledTaskFolder
        
        $Principal = New-ScheduledTaskPrincipal -UserId $User -LogonType S4U -RunLevel Highest
        
        $InputObject = New-ScheduledTask -Action $Action `
                                         -Trigger $Trigger `
                                         -Principal $Principal `
                                         -Settings $Settings `
                                         -Description $Description

                                         
        if([string]::IsNullOrEmpty($Password))
        {
            Register-ScheduledTask -TaskName    $TaskName `
                                   -TaskPath    $TaskPath `
                                   -InputObject $InputObject `
                                   -User        $User
        }
        else
        {
            # Register-ScheduledTask does not accept
            
            $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $UserName, $SecurePassword
            $Password = $Credentials.GetNetworkCredential().Password 

            Register-ScheduledTask -TaskName    $TaskName `
                                   -TaskPath    $TaskPath `
                                   -InputObject $InputObject `
                                   -User        $User `
                                   -Password    $Password
        }
    }
    
    End { 
    }
}

<#
    Removes the given Windows Task.
#>
function Remove-WindowsTask
{
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string]$TaskName   = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]$BinaryPath = $null,
        
        [Parameter(Mandatory=$false, Position=3)]
        [string]$TaskPath    = $null,

        [Parameter(Mandatory=$false, Position=4)]
        [string]$host       = $null
    )
    
    Begin {     
    }
    
    Process {
        # Verify if the scheduled task already exists, and if yes remove it
        
        $Tasks = schtasks -query
        
        if(Select-String -pattern $TaskName -InputObject $Tasks)
        {   
            # TODO: Would it work without host? 
            Schtasks /Delete /S $host /TN "$TaskPath\$TaskName" /F
        }
    }

    End { 
    }
}