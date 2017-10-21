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
        [string]$Password    = $null,

        # TODO: Improve that, this is not plain simple
        [Parameter(Mandatory=$false, Position=8)]
                $Settings    = $null
    )
    
    Begin {
        
        # PRIVATE FUNCTIONS
        function New-ScheduledTaskFolder
        {
            $errorActionPreference = "stop"
            
            $scheduleObject = New-Object -ComObject schedule.service
            
            $scheduleObject.connect()
            
            $rootFolder = $scheduleObject.GetFolder("\")
            
            try
            {
                $null = $scheduleObject.GetFolder($TaskPath)
            }
            catch
            {
                $null = $rootFolder.CreateFolder($TaskPath)
            }
            finally
            {
                $errorActionPreference = "continue"
            }
        }
    }
    
    Process {
        Write-Log "Installing Windows Task: $taskName"
                
        New-ScheduledTaskFolder
        
        $principal = New-ScheduledTaskPrincipal -UserId $user -LogonType S4U -RunLevel Highest
        
        $inputObject = New-ScheduledTask -Action $action `
                                         -Trigger $trigger `
                                         -Principal $principal `
                                         -Settings $settings `
                                         -Description $description

                                         
        if([string]::IsNullOrEmpty($password))
        {
            Register-ScheduledTask -TaskName    $taskName `
                                   -TaskPath    $taskPath `
                                   -InputObject $inputObject `
                                   -User        $user
        }
        else
        {
            Register-ScheduledTask -TaskName    $taskName `
                                   -TaskPath    $taskPath `
                                   -InputObject $inputObject `
                                   -User        $user `
                                   -Password    $password
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