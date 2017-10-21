# Setup variables, $TargetRoot is defined in a script used to initialize the setup see install.ps1
$TargetPath =  $TargetRoot + "\Sample.Windows.Service"
$ProductZip = $PSScriptRoot + "\Sample.Windows.Service.zip"
$BinaryPath = $TargetPath + "\bin\Sample.Windows.Service.exe"

# Je nach Umgebung Variabeln die benötigt werden definieren
switch ($Enviroment) {
    "Development" {
        $ServiceName = "$Enviroment.Sample.Windows.Service"
    }
    "Staging" {
        $ServiceName = "$Enviroment.Sample.Windows.Service"
    }
    "Production" {
        $ServiceName = "Sample.Windows.Service"
    }
    "Local" {
        $ServiceName = "Sample.Windows.Service"
    }
    default {
        Write-Output "Enviroment is unkown"
        exit
    }
}

# Stop and uninstall the old Service
Stop-WindowsService $ServiceName
Remove-WindowsService $ServiceName
 
Remove-Directory $TargetPath

# Unzip the File containing the binaries and dependencies
Expand-Archive -Path $ProductZip -Destinationpath $TargetPath

New-WindowsService -ServiceName $ServiceName -DisplayName $ServiceName -BinaryPath $BinaryPath

Start-WindowsService $ServiceName