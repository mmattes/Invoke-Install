    <#
        .SYNOPSIS
            Creates a new Windows Task
        
        .DESCRIPTION
            Creates a new Windows Task within the specified TaskPath

        .PARAMETER TaskName
            Name of the Task to create
               
        .PARAMETER TaskPath
            Path of the Task within the Windows Task Tree Structure

        .PARAMETER Action

        .PARAMETER Trigger

        .PARAMETER Description
            Description of the Task to create

        .PARAMETER User
            User under which the Task should run

        .PARAMETER SecurePassword
            SecurePassword for the User, must be supplied as SecureString

        .PARAMETER Settings

        .EXAMPLE
            New-WindowsTask -TaskName "MyTask" -TaskPath "MyPath/MyTasks" -Action -Trigger
    #>
function New-WindowsTask
{
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string] $TaskName    = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string] $TaskPath    = $null,

        # TODO: Improve that, this is not plain simple
        [Parameter(Mandatory=$true, Position=3)]
                $Action      = $null,
        
        # TODO: Improve that, this is not plain simple
        [Parameter(Mandatory=$true, Position=4)]
                $Trigger     = $null,
        
        [Parameter(Mandatory=$false, Position=5)]
        [string] $Description = $null,

        [Parameter(Mandatory=$true, Position=6)]
        [string] $User        = $null,
        
        [Parameter(Mandatory=$false, Position=7)]
        [securestring] $SecurePassword    = $null,

        # TODO: Improve that, this is not plain simple
        [Parameter(Mandatory=$true, Position=8)]
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

                                         
        if([string]::IsNullOrEmpty($SecurePassword))
        {
            Register-ScheduledTask -TaskName    $TaskName `
                                   -TaskPath    $TaskPath `
                                   -InputObject $InputObject `
                                   -User        $User
        }
        else
        {
            # Register-ScheduledTask does not accept
            
            $Credentials = New-Object System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
            $PlainPassword = $Credentials.GetNetworkCredential().Password 

            Register-ScheduledTask -TaskName    $TaskName `
                                   -TaskPath    $TaskPath `
                                   -InputObject $InputObject `
                                   -User        $User `
                                   -Password    $PlainPassword
        }
    }
    
    End { 
    }
}

    <#
        .SYNOPSIS
            Removes a Windows Task
        
        .DESCRIPTION
            Removes the Windows Task within the specified TaskPath

        .PARAMETER TaskName
            Name of the Task to remove
               
        .PARAMETER TaskPath
            Path of the Task within the Windows Task Tree Structure

        .PARAMETER Host
            Host on which the task should be deleted

        .EXAMPLE
            New-WindowsTask -TaskName "MyTask" -TaskPath "MyPath/MyTasks" -Action -Trigger
    #>
function Remove-WindowsTask
{
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string ]$TaskName   = $null,
        
        [Parameter(Mandatory=$true, Position=2)]
        [string] $TaskPath    = $null,

        [Parameter(Mandatory=$true, Position=3)]
        [string] $Host       = $null
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