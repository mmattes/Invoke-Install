# TODO: Propper Description of this file above

# Import all *.ps1 Files
Get-ChildItem -Path $PSScriptRoot\*.ps1 |
ForEach-Object {
    if ($_.PSChildName -eq "test.ps1") {
        return
    }
    . $_.FullName
}