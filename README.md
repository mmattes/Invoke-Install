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
* This Module uses
    * [Invoke-Parallel](https://github.com/RamblingCookieMonster/Invoke-Parallel)
