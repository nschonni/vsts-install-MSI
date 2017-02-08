# vsts-install-MSI

Extension to install \ deploy MSI as a build step in VSTS Release.

![Logo](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/icon.png)

# Features

1. Allows to specify directory with MSI files

2. Allows to specify file mask to match (\*.msi by default) if not all files from the directory should be installed

3. Allows to pass environment Variables as MSI properties. Variables are defined by Regex.<br>
Use cases:
 * redefine TARGETDIR to install to an arbitrary folder
 * pass property containing DB Connection String to be injected into Web.config during MSI installation

4. In case of installation failure:
 * verbose log is attached to the Release, to see it click "Download all logs as zip"
 * it will try to analyse log to find out the root cause and show it in the task output (this might not work on non-English versions of Windows)

# Example

Add step:

![Add step](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/screenshot_1_add_step.png)

Configure step (note Regex in Advanced section):

![Configure step](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/screenshot_2_configure_step.png)

Add env var to pass to MSI:

![Add env var to pass to MSI](https://raw.githubusercontent.com/IvanBoyko/vsts-install-MSI/master/images/screenshot_3_add_env_var.png)

# Compatibility

* Visual Studio Team Services - tested
* Team Foundation Server - not tested


# TODO

- Escape double quotes (") in values of environment variables passed to MSI


# Support

Extension is open source and free to use.
But it's provided as is, without any responsibility, and is not guaranteed to work.
Use at your own risk.

However if you find any issue, feel free to raise it here:
https://github.com/IvanBoyko/vsts-install-MSI/issues
