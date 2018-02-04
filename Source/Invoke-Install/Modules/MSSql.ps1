function Use-SqlServerModule
{
    <#
        .SYNOPSIS
            Loads and installs the sqlserver module if not already installed or loaded
        
        .DESCRIPTION
            Loads and installs the sqlserver module if not already installed or loaded
        
        .EXAMPLE
            Use-WebAdministration
    #>
    
    if (!(Get-Module -ListAvailable -Name sqlserver)) {
        Install-Module sqlserver -Force -ErrorAction Stop    
    }
    
    if (!(Get-Module sqlserver)) {
        Import-Module sqlserver -ErrorAction Stop -Force 
    }
}


function Use-MicrosoftSqlServerDac
{
    <#
        .SYNOPSIS
            Loads the latest Microsoft.SqlServer.Dac.dll with Add-Type
        
        .DESCRIPTION
            Loads the latest Microsoft.SqlServer.Dac.dll with Add-Type
        
        .EXAMPLE
            Use-MicrosoftSqlServerDac
    #>
    if ("Microsoft.SqlServer.Dac.DacService" -as [type]) {
    {
        $Version = 0
        $MicrosoftSqlServerDacDLLPath = ""
    
        Get-ChildItem "${env:ProgramFiles(x86)}\Microsoft SQL Server\*" -Recurse -Filter "*Microsoft.SqlServer.Dac.dll" |
        ForEach-Object {
            if($Version -lt $_.FullName.split("\")[3]) {
                $Version = $_.FullName.split("\")[3]
                $MicrosoftSqlServerDacDLLPath = $_.FullName
            }   
        }

        #Register the DLL we need
        Add-Type -Path $MicrosoftSqlServerDacDLLPath
    }        
}


function Update-SqlDatabase
{
    <#
        .SYNOPSIS
            Updates a MSSql Database to a given schema from a dacpac file
        
        .DESCRIPTION
            Updates a MSSql Database to a given schema from a dacpac file
        
        .PARAMETER ConnectionString
            Specifies the connection String to the database server e.g.
            "data source=LOCALHOST;Integrated Security=true;"

        .PARAMETER DatabaseName
            Specifies the name of the Database to Update
        
        .PARAMETER DacpacFilePath
            Specifies the path to the dacpac file which contains the latest schema for the database

        .PARAMETER DacDeployOptions
            Optionally specifies DacDeployOptions see 
            https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.dac.dacdeployoptions(v=sql.120).aspx 
            for more information 

        .EXAMPLE
            Update-SqlDatabase -ConnectionString "data source=LOCALHOST;Integrated Security=true;" -Database "MyDatabase" -DacpacFilePath "C:\MySolution\MyDatabase.dacpac"
    #>
    
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ConnectionString     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $DatabaseName     = $null,

        [Parameter(Mandatory=$true, Position=3)]
        [string]  $DacpacFilePath     = $null,

        [Parameter(Mandatory=$false, Position=3)]
        [psobject]  $DacDeployOptions    = $null        
    )
    
    Begin {
        Use-MicrosoftSqlServerDac

        if(-Not($DacDeployOptions)) {
            $DeployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions
        }
    }
    
    Process {
        $DacService = New-Object Microsoft.SqlServer.dac.dacservices($ConnectionString)
        if(Test-Path -Path $DacpacFilePath) {
            $DacPackage = [Microsoft.SqlServer.Dac.DacPackage]::Load($DacpacFilePath)
        } else {
            Throw "$DacpacFilePath could not be found"   
        }

        $DacService.deploy($DacPackage, $DatabaseName, $true, $DeployOptions)
    }
    
    End { 
    }
}


function Get-SqlUpdateScript
{
    <#
        .SYNOPSIS
            Returns an update script for a mssql database using a dacpac file
        
        .DESCRIPTION
            Returns an update script for a mssql database using a dacpac file
        
        .PARAMETER ConnectionString
            Specifies the connection String to the database server e.g.
            "data source=LOCALHOST;Integrated Security=true;"

        .PARAMETER DatabaseName
            Specifies the name of the Database to Update
        
        .PARAMETER DacpacFilePath
            Specifies the path to the dacpac file which contains the latest schema for the database

        .PARAMETER DacDeployOptions
            Optionally specifies DacDeployOptions see 
            https://msdn.microsoft.com/en-us/library/microsoft.sqlserver.dac.dacdeployoptions(v=sql.120).aspx 
            for more information 

        .EXAMPLE
            Get-SqlUpdateScript -ConnectionString "data source=LOCALHOST;Integrated Security=true;" -Database "MyDatabase" -DacpacFilePath "C:\MySolution\MyDatabase.dacpac"
    #>
    
    param(
        [Parameter(Mandatory=$true, Position=1)]
        [string]  $ConnectionString     = $null,

        [Parameter(Mandatory=$true, Position=2)]
        [string]  $DatabaseName     = $null,

        [Parameter(Mandatory=$true, Position=3)]
        [string]  $DacpacFilePath     = $null,

        [Parameter(Mandatory=$false, Position=3)]
        [psobject]  $DacDeployOptions    = $null        
    )
    
    Begin {
        Use-MicrosoftSqlServerDac

        if(-Not($DacDeployOptions)) {
            $DeployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions
        }
    }
    
    Process {
        $DacService = New-Object Microsoft.SqlServer.dac.dacservices($ConnectionString)
        if(Test-Path -Path $DacpacFilePath) {
            $DacPackage = [Microsoft.SqlServer.Dac.DacPackage]::Load($DacpacFilePath)
        } else {
            Throw "$DacpacFilePath could not be found"   
        }

        return $DacService.GenerateDeployScript($DacPackage, $DatabaseName, $DeployOptions)
    }
    
    End { 
    }
}
