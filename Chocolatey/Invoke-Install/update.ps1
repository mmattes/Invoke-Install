$SourceDir   = "$PSScriptRoot\..\..\Source\"
$moduleName  = 'Invoke-Install'

function global:au_SearchReplace {
    @{
    }
}

function global:au_BeforeUpdate() {
    $params = @{ 
        Path        = "$SourceDir\*"
        Destination = "tools\"
        Force       = $true
        Recurse     = $true
    }
    Copy-Item @params

    $params = @{ 
        Path        = "$PSScriptRoot\..\..\Readme.md"
        Destination = $PSScriptRoot
        Force       = $true
    }
    Copy-Item @params
}

function global:au_AfterUpdate { 
    #Set-DescriptionFromReadme -SkipFirst 5
}

function global:au_GetLatest {
    if ($PSVersionTable.PSVersion.Major -ge 5)
    {
        $manifestFile = Join-Path -Path $SourceDir -ChildPath "$moduleName\$moduleName.psd1"
        $manifest     = Test-ModuleManifest -Path $manifestFile -WarningAction Ignore -ErrorAction Stop        
    }

    return @{
        Version       = $manifest.Version.ToString()
        ModuleVersion = $manifest.Version.ToString()
    }
}

update -ChecksumFor none