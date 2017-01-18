# vsts-install-MSI

VSTS extension to install \ deploy MSI as a build step in VSTS Release.

![Logo](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/logo.png)

Allows to specify directory with MSI files and a file mask to match (*.msi by default)

Also allows you to passes environment Variables as MSI properties.<br>
Variables to pass are defined by Regex.<br>
Example use cases:
- redefine TARGETDIR to install to an arbitrary folder
- pass property containing DB Connection String to be injected into Web.config during MSI installation
