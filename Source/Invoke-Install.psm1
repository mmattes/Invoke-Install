# TODO: Propper Description of this file above

# Import all *.ps1 Files
Get-ChildItem -Recurse -Path $PSScriptRoot\*.ps1 |
ForEach-Object {
    if ($_.PSChildName -match "test.*\.ps1") {
        return
    }
    . $_.FullName
}