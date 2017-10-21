function Remove-Directory {
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Path  = $null
    )
    
    Remove-Item -Recurse -Force $Path
}