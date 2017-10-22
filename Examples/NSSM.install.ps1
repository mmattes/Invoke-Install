# Setup variables, $TargetRoot is defined in a script used to initialize the setup see install.ps1
$TargetPath =  $TargetRoot + "\Sample.NSSM.Service"
$ProductZip = $PSScriptRoot + "\Sample.NSSM.Service.zip"
$BinaryPath = $TargetPath + "\bin\Sample.NSSM.Service.exe"

# Setup some more variables depending on enviroment
switch ($Enviroment) {
    "Development" {
        $ServiceName = "$Enviroment.Sample.NSSM.Service"
    }
    "Staging" {
        $ServiceName = "$Enviroment.Sample.NSSM.Service"
    }
    "Production" {
        $ServiceName = "Sample.NSSM.Service"
    }
    "Local" {
        $ServiceName = "Sample.NSSM.Service"
    }
    default {
        Write-Output "Enviroment is unkown"
        exit
    }
}

# Stop and uninstall the old Service
Stop-NSSMService -ServiceName $ServiceName -NSSMBinaryPath .\nssm.exe
Remove-NSSMService -ServiceName $ServiceName -NSSMBinaryPath .\nssm.exe
 
Remove-Directory $TargetPath

# Unzip the File containing the binaries and dependencies
Expand-Archive -Path $ProductZip -Destinationpath $TargetPath

New-NSSMService -ServiceName $ServiceName -ServiceBinaryPath $BinaryPath -ServiceArgs "-dothis" -NSSMBinaryPath .\nssm.exe
Set-NSSMAppDirectory -ServiceName $ServiceName -AppDirectory $TargetPath -NSSMBinaryPath .\nssm.exe


Start-NSSMService -ServiceName $ServiceName -NSSMBinaryPath .\nssm.exe