# TODO: Propper Description of this file above
function Add-InstallTask (    
    [Parameter(Position=0, Mandatory=$true, HelpMessage="Name of the Task to be performed")]
    [string] $Name,
    
    [Parameter(Position=1, Mandatory=$true, HelpMessage="Scriptblock, what should the task execute")]
    [System.Object[]] $ScriptBlock
) {
    Write-Output $Name
}