# This is where the module manifest lives
$SourcePath = $PSScriptRoot + "\..\Source\Invoke-Build"
$ManifestPath = $SourcePath + "\Invoke-Build.psd1"

# Start by importing the manifest to determine the version, then add 1 to the revision
$Manifest = Test-ModuleManifest -Path $ManifestPath
[System.Version]$Version = $Manifest.Version
Write-Output "Old Version: $Version"
[String]$NewVersion = New-Object -TypeName System.Version -ArgumentList ($Version.Major, $Version.Minor, ($Version.Build+1), 0)
Write-Output "New Version: $NewVersion"

Update-ModuleManifest -Path $ManifestPath -ModuleVersion $NewVersion

Publish-Module -Path $SourcePath -NuGetApiKey $ENV:NuGetApiKey -Verbose -ErrorAction Stop

# Publish the new version back to Master on GitHub
Try 
{
    # Set up a path to the git.exe cmd, import posh-git to give us control over git, and then push changes to GitHub
    # Note that "update version" is included in the appveyor.yml file's "skip a build" regex to avoid a loop
    $ENV:Path += ";$ENV:ProgramFiles\Git\cmd"
    Import-Module Posh-Git -ErrorAction Stop
    git add --all
    git status
    git commit -s -m "Update version to $NewVersion"
    git push origin master
    Write-Host "PowerShell Module version $NewVersion published to GitHub." -ForegroundColor Cyan
}
Catch 
{
    # Sad panda; it broke
    Write-Warning "Publishing update $NewVersion to GitHub failed."
    throw $_
}