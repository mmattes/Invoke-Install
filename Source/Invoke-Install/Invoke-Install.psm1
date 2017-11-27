# Import all *.ps1 Files
$Modules = Get-ChildItem -Recurse -Path $PSScriptRoot -Filter *.ps1 

foreach ($Module in $Modules) {
    . $Module.FullName
}

