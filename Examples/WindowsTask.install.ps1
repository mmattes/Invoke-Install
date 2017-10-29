# Setup variables, $TargetRoot is defined in a script used to initialize the setup see install.ps1
$TargetPath =  $TargetRoot + "\Sample.Windows.Task"
$ProductZip = $PSScriptRoot + "\Sample.Windows.Task.zip"
$BinaryPath = $TargetPath + "\bin\Sample.Windows.Task.exe"
$TaskPath = "MyTasks"

# Setup some more variables depending on enviroment
switch ($Enviroment) {
    "Development" {
        $TaskName = "$Enviroment.Sample.Windows.Task"
    }
    "Staging" {
        $TaskName = "$Enviroment.Sample.Windows.Task"
    }
    "Production" {
        $TaskName = "Sample.Windows.Task"
    }
    "Local" {
        $TaskName = "Sample.Windows.Task"
    }
    default {
        Write-Output "Enviroment is unkown"
        exit
    }
}

# Remove the old Task
Remove-WindowsTask -TaskName $TaskName -Host LOCALHOST -TaskPath $TaskPath
 
Remove-Directory $TargetPath

# Unzip the File containing the binaries and dependencies
Expand-Archive -Path $ProductZip -Destinationpath $TargetPath

New-WindowsTask -TaskName $TaskName 
