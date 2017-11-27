function Remove-Directory {
    <#
        .SYNOPSIS
            Removes the given Path including the complete content
        
        .DESCRIPTION
            Removes the given Path including the complete content

        .PARAMETER Path
            Path to delete

        .EXAMPLE
            Remove-Directory -Path C:\DeleteThis
    #>
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]$Path  = $null
    )
    
    Remove-Item -Recurse -Force $Path
}