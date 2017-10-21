# TODO: Propper Description of this file above

# Import all *.ps1 Files
Get-ChildItem -Recurse -Path $PSScriptRoot -Filter *.ps1 |
ForEach-Object {
    . $_.FullName
}
