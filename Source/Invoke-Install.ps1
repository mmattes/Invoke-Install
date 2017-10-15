# TODO: Propper Description of this file above
function Invoke-Install (
    [Parameter(Position=0, Mandatory=$true, HelpMessage="Path to the *.install.ps1")]
    [string] $InstallFilePath
) {
    #Set-Alias task Add-InstallTask
    Write-Output "Hello World, Invoke-Install was called, the path is $InstallFilePath"
}