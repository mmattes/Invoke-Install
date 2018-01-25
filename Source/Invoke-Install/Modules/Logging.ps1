#TODO: Improve Logging, add message Type, Colors, may Date

function Write-Log 
{ 
    <#
        .SYNOPSIS
            Log Message with given level, default level is "Information"
        
        .DESCRIPTION
            Log Message with given level, default level is "Information"

        .PARAMETER Message
            Message to be logged

        .PARAMETER LogLevel
            Possible values are 'Error', 'Warning', 'Information', 'Verbose', 'Debug'

        .EXAMPLE
            Write-Log "Everything went ok!" -LogLevel Information
            Write-Log "Result is $Result" -LogLevel Debug
            Write-Log "Could not stop service" -LogLevel Error
    #>
    [CmdletBinding()] 
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(Mandatory=$false, Position=1)]
        [ValidateSet('Error', 'Warning', 'Information', 'Verbose', 'Debug')]
        [string]$LogLevel = 'Information'
      )
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue' 
        $InformationPreference = 'Continue' 
        $DebugPreference = 'Continue'
    } 
    Process 
    { 
        switch ($LogLevel) {
            'Error' {
                Write-Error $Message
            }
            'Warning' {
                Write-Warning $Message
            }
            'Information' {
                Write-Information $Message
            }
            'Verbose' {
                Write-Verbose $Message
            }
            'Debug' {
                Write-Debug $Message
             }
            default       { throw "Invalid log level: $_" }
          }
    } 
    End 
    { 
    } 
}