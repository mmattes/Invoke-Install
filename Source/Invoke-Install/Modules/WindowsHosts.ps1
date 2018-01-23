function Add-WindowsHostsRecord
{
        <#
        .SYNOPSIS
            Adds a new record to the windows hosts file
        
        .DESCRIPTION
            Adds a new record to the windows hosts file if the record is not already present

        .PARAMETER DnsName
            Specifies the dns name for the record to be added

        .PARAMETER IPAddress
            Specifies the IP address for the record to be added

        .EXAMPLE
            Add-WindowsHostsRecord -DnsName "mydns" -IPAddress "127.0.0.1"
    #>
    param(        
        [Parameter(Mandatory=$true, Position=1)]
        [string] $DnsName     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string] $IPAddress   = $null
    )
    
    Begin {
        
    }
    
    Process {
        if((Get-Content "$($env:windir)\system32\Drivers\etc\hosts") -notcontains "$IPAddress`t$DnsName") {
            Add-Content -Encoding UTF8 "$($env:windir)\system32\Drivers\etc\hosts" "`r`n$IPAddress`t$DnsName" -NoNewline
        }

    }
    
    End { 
    }
}

    
function Remove-WindowsHostsRecord
{
    <#
        .SYNOPSIS
            Removes one or more records from the windows hosts file
        
        .DESCRIPTION
            Removes one or more records from the windows hosts file depending on the provided data

        .PARAMETER DnsName
            Specifies the dns name for the record to be removed

        .PARAMETER IPAddress
            Specifies the IP address for the record to be removed

        .EXAMPLE
            Remove-WindowsHostsRecord -IPAddress "127.0.0.1"

        .EXAMPLE
            Remove-WindowsHostsRecord -DnsName "mydns*.com"

        .EXAMPLE
            Remove-WindowsHostsRecord -IPAddress "127.0.0.1" -DnsName "mydns*.com"
    #>
    param(
        [CmdletBinding(DefaultParameterSetName='ByDnsName')]
        [Parameter(Mandatory=$true, ParameterSetName='ByDnsName', Position=1)]
        [string] $DnsName     = $null,

        [Parameter(Mandatory=$true, ParameterSetName='ByIPAddress', Position=2)]
        [string] $IPAddress   = $null
    )
    
    Begin {
        if([string]::IsNullOrEmpty($DnsName)) {
            $DnsName = ".*"
        } else {
            $DnsName = $DnsName.replace(".", "\.")
            $DnsName = $DnsName.replace("*", ".*")
        }

        if([string]::IsNullOrEmpty($IPAddress)) {
            $IPAddress = ".*"
        } else {
            $IPAddress = $IPAddress.replace(".", "\.")
            $IPAddress = $IPAddress.replace("*", ".*")   
        }
    }
    
    Process {
        $ReplaceWithoutNewLine = "$IPAddress`t$DnsName"
        $ReplaceWithNewLine = "$IPAddress`t$DnsName`r`n"

        $Content = Get-Content "$($env:windir)\system32\Drivers\etc\hosts" -Raw 
        $Content = $Content -replace $ReplaceWithNewLine, ''        
        $Content = $Content -replace $ReplaceWithoutNewLine, ''
        
        Set-Content -Encoding UTF8 -Value $Content -Path "$($env:windir)\system32\Drivers\etc\hosts" -NoNewline
    }
    
    End { 
    }
}