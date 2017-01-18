#
# Script installs all .msi files found in a dir
#

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False)]
	[string] $msi_dir = (Split-Path $MyInvocation.MyCommand.Path),
	
	[Parameter(Mandatory=$False)]
	[string] $EnvVarRegex = '^ENV_'
)

#
# Constants
#
$errorActionPreference = "Stop"
$msiFilesMask = '*.msi'


#
# Vars
#
$msi_installed = @()
$msi_failed = @()


#
# Functions
#

function GetMsiParams() {
	$KeyValueArray = @()
	
	gci Env: | ?{$_.Key -match $EnvVarRegex} | %{
		$key   = $_.Key
		$value = $_.Value

		if ($key -cmatch '[a-z]') {
			throw "ERROR: env var $key contains lowercase characters, while Public properties in Windows Installer must be all UPPERCASE, see this: https://msdn.microsoft.com/en-us/library/aa370912(v=vs.85).aspx"
		}
		# TODO: escape double quotes (") in values?

		$KeyValueArray += "$key=`"$value`""
	}

	return $KeyValueArray
}

function InstallMsi([string] $msi_file, $msi_params) {
	Write-Host "Installing $msi_file with parameters: " $msi_params

	$log_file = "${msi_file}_install.log"

	$parms = @("/i", $msi_file, "/qn", '/l*v', $log_file)
	if ($msi_params) {
		$parms += $msi_params
	}
	$exitCode = (Start-Process -FilePath msiexec.exe -ArgumentList $parms -Wait -Passthru).ExitCode

	if ($exitCode -eq 0) {
		Write-Host "Installed successfully"
		$script:msi_installed += $msi_file
	} else {
		Write-Host "ERROR: cannot install $msi_file, msiexec exit code is $exitCode, see the log file " (Split-Path $log_file -Leaf) " and MSDN documentation: http://msdn.microsoft.com/en-us/library/aa376931(v=vs.85).aspx"
		$script:msi_failed += $msi_file
	}
}

function InstallMsiFilesFromDir([string]$msi_dir, [string]$msi_params) {
	Write-Host "Looking for MSI files in the dir ""$msi_dir"""
	$msi_files = @(Get-ChildItem (Join-Path $msi_dir $msiFilesMask))

	# Install each MSI one by one
	$msi_files | %{
		InstallMsi $_.FullName $msi_params
	}
}


#
# Main programme
#

$msi_params = GetMsiParams

InstallMsiFilesFromDir $msi_dir $msi_params

Write-Host "Installation is finished"
Write-Host ">>>>>>>>>>>>> Deployed:" $msi_installed
Write-Host ">>>>>>>>>>>>> Failed:" $msi_failed

$logMessage = 'deployed ' + $msi_installed.Count + '; failed: ' + $msi_failed.Count
Write-Host $logMessage

if ($msi_failed.Count -ne 0) {
	exit 1
}