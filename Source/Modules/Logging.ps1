function Write-Log 
{ 
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