$ErrorActionPreference = 'Stop'

$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$moduleName  = 'Invoke-Install'

$sourcePath = Join-Path -Path $toolsDir -ChildPath "$modulename\*"
$destPath   = Join-Path -Path $env:ProgramFiles -ChildPath "WindowsPowerShell\Modules\$moduleName"

if ($PSVersionTable.PSVersion.Major -ge 5)
{
    $manifestFile = Join-Path -Path $toolsDir -ChildPath "$moduleName\$moduleName.psd1"
    $manifest     = Test-ModuleManifest -Path $manifestFile -WarningAction Ignore -ErrorAction Stop
    $destPath     = Join-Path -Path $destPath -ChildPath $manifest.Version.ToString()
}

# module may already be installed outside of Chocolatey
Uninstall-Module -Name "Invoke-Install" -Force -ErrorAction SilentlyContinue -RequiredVersion $manifest.Version.ToString()

Write-Verbose "Creating destination directory '$destPath' for module."
New-Item -Path $destPath -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

Write-Verbose "Moving '$moduleName' files from '$sourcePath' to '$destPath'."
Move-Item -Path $sourcePath -Destination $destPath -Force

if ($PSVersionTable.PSVersion.Major -lt 4)
{
    $modulePaths = [Environment]::GetEnvironmentVariable('PSModulePath', 'Machine') -split ';'
    if ($modulePaths -notcontains $destPath)
    {
        Write-Verbose "Adding '$destPath' to PSModulePath."
        $newModulePath = @($destPath, $modulePaths) -join ';'

        [Environment]::SetEnvironmentVariable('PSModulePath', $newModulePath, 'Machine')
        $env:PSModulePath = $newModulePath
    }
}