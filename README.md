# Invoke-Install

[![Build status](https://ci.appveyor.com/api/projects/status/vjynfakil886epi1/branch/master?svg=true)](https://ci.appveyor.com/project/mmattes/invoke-install/branch/master)

Module to simplify PowerShell installations

### Description 

Invoke-Install is inspired by PSDeploy and Invoke-Build but rather then using a specific script language/format it just uses Powershell scripts and runs them. Imaging you have an application which comes with several independent services/modules/apis and all of them somehow need to be installed. Rather then having one large installation script for all services/modules/apis you will create independet ```*.install.ps1``` files which all will complete an independent installation.

Invoke-Install comes with special Modules for more complicated tasks so that anything what needs to be done is a one liner. 

The idea is that any ```*.install.ps1``` is plain simple and straight forward understandable, they should not contain functions or a lot of switches or if, loops. 

### Installing

```ps
Install-Module Invoke-Install

```

### Usage

Execute the following command to runn all ```*.install.ps1``` files within the same directory

```ps
Invoke-Install .

```

or specify a specific ```*.install.ps1``` to be used. 

```ps
Invoke-Install MyApp.install.ps1

```

Check out the Examples in ``Examples/`` to see what currently can be done with Invoke-Install. Feel free to contribute and add more Modules. 

## Release History

* 1.7.1
    * ADD: Use-IISAdministration loads the IISAdministration Module if it is not already loaded
    * ADD: Get-IISVersion gets the Version as System.Version Object from the installed IIS Server
    * ADD: Get-WindowsReleaseId gets the Windwos ReleaseId e.g. 1809
    * ADD: Set-IISSiteHSTS enables HSTS on a IIS Site
* 1.6.1
    * ADD: Set-IISServerFarmServerAvailability to set the availability/state of a server within a server farm
* 1.5.1
    * ADD: Set-IISAppPoolConfig to set some config parameters of AppPools
* 1.4.1
	* ADD: Use-SqlServerModule to install and load the SqlServerModule
	* ADD: Update-SqlDatabase updates a sqldatabase using a dacpac file 
	* ADD: Get-SqlUpdateScript generates a sql update script for a sqldatabase using a dacpac file
* 1.3.1
	* ADD: Remove-IISServerFromServerFarm to remove on or more severs from a server farm
* 1.2.1
    * CHANGE: Remove-IISWebsite has now a filter and exculde parameter to delete multiple items at once
    * CHANGE: Remove-IISApplicationPool has now a filter and exculde parameter to delete multiple items at once
* 1.1.1
    * ADD: Get-ShortGUID, Get-FreePortFromRange, Remove-IISServerFarm, Add-IISServerToServerFarm, Set-IISServerFarmServerState, Set-IISServerFarmHealthCheck, Add-IISGlobalRouting, Add-WindowsHostsRecord, Remove-WindowsHostsRecord
    * ADD: [IIS Server Farm sample](Examples/IISSiteWithServerFarm.install.ps1)
* 1.0.1
    * First propper release

## Contributing

Please read [CONTRIBUTING.md](Doc/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning.

## Authors

* **Markus Mattes** - *Initial work* - [mmattes](https://github.com/mmattes)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Inspiration 
    * [PSDeploy](https://github.com/RamblingCookieMonster/PSDeploy)
    * [InvokeBuild](https://github.com/nightroman/Invoke-Build)
