dir$PSScriptRoot
dir $PSScriptRoot\..\Source
dir $ENV:APPVEYOR_BUILD_FOLDER
dir $ENV:APPVEYOR_BUILD_FOLDER\Source
Publish-Module -Path $ENV:APPVEYOR_BUILD_FOLDER\Invoke-Install\Source\Invoke-Install.psd1 -NuGetApiKey $ENV:NuGetApiKey -Verbose