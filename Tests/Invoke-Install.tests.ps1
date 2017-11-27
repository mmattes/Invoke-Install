Import-Module $PSScriptRoot\..\Source\Invoke-Install\Invoke-Install.psd1 -Force

Describe 'Testing Invoke-Install' {
    Context 'Single *.install.ps1' {
        $Result = Invoke-Install $PSScriptRoot\Single\HelloWorld.install.ps1
        $Result[0] | Should Be "Hello World!"
        $Result[1] | Should Be "1"
    }

    Context 'Multiple *.install.ps1' {
        $Result = Invoke-Install $PSScriptRoot\Multiple        
        $Result[0] | Should Be "Hello World!"
        $Result[1] | Should Be "Hello Second World!"
        $Result[2] | Should Be "2"
    }
}

