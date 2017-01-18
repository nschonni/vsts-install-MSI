# vsts-install-MSI

VSTS extension to install \ deploy MSI as a build step in VSTS Release.

![Logo](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/icon.png)

# Features

1. Allows to specify directory with MSI files

2. Allows to specify file mask to match (\*.msi by default) if not all files from the directory should be installed

3. Allows to passes environment Variables as MSI properties.<br>
Variables to pass are defined by Regex.<br>
Use cases:
 * redefine TARGETDIR to install to an arbitrary folder
 * pass property containing DB Connection String to be injected into Web.config during MSI installation

# Example

Add step:

![Add step](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/screenshot_1_add_step.png)

Configure step (note Regex in Advanced section):

![Configure step](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/screenshot_2_configure_step.png)

Add env var to pass to MSI:

![Add env var to pass to MSI](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/screenshot_3_add_env_var.png)

