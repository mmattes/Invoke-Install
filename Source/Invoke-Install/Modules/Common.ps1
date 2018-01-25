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


function Get-ShortGUID {
    <#
        .SYNOPSIS
            Gives a short GUID like 3jhCD75fUWjQek8XRmMg 
        
        .DESCRIPTION
            Gives a short GUID like 3jhCD75fUWjQek8XRmMg 

        .EXAMPLE
            Get-ShortGUID
    #>    
    
    $RandomChar = -join ((65..90) + (97..122) | Get-Random | % {[char]$_})
    [regex]::Replace([System.Convert]::ToBase64String([guid]::NewGuid().toByteArray()), "[/+=]", $RandomChar)
}

#TODO: Get free port from range windows