Import-Module $PSScriptRoot\..\Source\Invoke-Install\Invoke-Install.psd1 -Force

Describe 'Testing Invoke-Install' {
    Context 'Single *.install.ps1' {
        $Count = Invoke-Install $PSScriptRoot\Single\HelloWorld.install.ps1 | Should Be "1"
    }

    Context 'Multiple *.install.ps1' {
        $Count = Invoke-Install $PSScriptRoot\Multiple | Should Be "2"
    }
}

