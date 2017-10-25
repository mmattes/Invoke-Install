Import-Module $PSScriptRoot\..\Source\Invoke-Install\Invoke-Install.psd1 -Force

Describe 'Testing Invoke-Install' {
    Context 'Single *.install.ps1' {
        Invoke-Install $PSScriptRoot\HelloWorld.install.ps1 | Should -Be "Hello World!"
    }
}

