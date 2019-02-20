function Get-WindowsReleaseId 
{
	<#
        .SYNOPSIS
            Gets the ReleaseId from Windows
        
        .DESCRIPTION
            Gets the ReleaseId from Windows and returns it as an int
        
        .EXAMPLE
            Get-WindowsReleaseId 
    #>
    Begin {
        [int]$ReleaseId = $null
    }
    
    Process {
        $ReleaseId = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\" -Name ReleaseID).ReleaseId
    }
    
    End { 
        return $ReleaseId
    }
}