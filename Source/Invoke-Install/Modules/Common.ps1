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


function Get-FreePortFromRange
{
    <#
        .SYNOPSIS
            Provides the next free port from a range
        
        .DESCRIPTION
            Provides the next free port from a range of port numbers passed to the function

        .PARAMETER PortRange
            Specifies the range of ports which should be checked for a not used port

        .PARAMETER IpAddress
            Specifies the IpAddress which should be checked for a not used port from the range specified
        
        .EXAMPLE
            Get-FreePortFromRange -PortRange (8000..8100)

        .EXAMPLE
            Get-FreePortFromRange -PortRange (8000..8100) -IpAddress "192.168.1.20"
    #>
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [array]$PortRange  = $null,
        
        [Parameter(Mandatory=$false, Position=2)]
        [string]$IpAddress = $null
    )

    Begin {
        if (!(Get-Module -ListAvailable -Name Nettcpip)) {
            throw "Nettcpip Module not available"
        } 

        if (!(Get-Module Nettcpip))
        {
            Import-Module Nettcpip -ErrorAction Stop            
        }
    }
    
    Process {
        $PortsInUse = @()
        if($IpAddress) {
            Get-NetTCPConnection -State "Listen" -LocalAddress $IpAddress | ForEach-Object { $PortsInUse += $_.LocalPort }
        } else {
            Get-NetTCPConnection -State "Listen" | ForEach-Object { $PortsInUse += $_.LocalPort }
        }
        
        
        foreach ($Port in $PortRange) {
            if ($PortsInUse -notcontains $Port) {
                return $Port
            }
        }
        return $null
    }
    
    End { 
    }
}

