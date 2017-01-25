#
# Script installs all .msi files found in a dir
#

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False)]
	[string] $msi_Dir = (Split-Path $MyInvocation.MyCommand.Path),
	
	[Parameter(Mandatory=$False)]
	[string] $msi_FilesMask = '*.msi',
	
	[Parameter(Mandatory=$False)]
	[string] $EnvVarRegex = '^ENV_'
)

#
# Constants
#
$errorActionPreference = "Stop"


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

		$KeyValueArray += "$key=`"$value`""
	}

	return $KeyValueArray
}

function InstallMsi([string] $msi_file, $msi_params) {

	$log_file = "${msi_file}_install.log"

	$parms = @("/i", $msi_file, "/qn", '/l*v', $log_file)
	if ($msi_params) {
		$parms += $msi_params
	}
	Write-Host "##[command]msiexec.exe $parms"
	$exitCode = (Start-Process -FilePath msiexec.exe -ArgumentList $parms -Wait -Passthru).ExitCode

	if ($exitCode -eq 0) {
		Write-Host "Installed successfully"
		$script:msi_installed += $msi_file
	} else {
		Write-Host "##vso[task.uploadfile]$log_file"

		$error_message = "ERROR: cannot install $msi_file, msiexec exit code is $exitCode, see the log file " + (Split-Path $log_file -Leaf) + " and MSDN documentation: http://msdn.microsoft.com/en-us/library/aa376931(v=vs.85).aspx"
		Write-Host $error_message

		$error_message = "##vso[task.logissue type=error]" + (hostname) + ": " + $error_message
		Write-Host $error_message
		
		$script:msi_failed += $msi_file
	}
}

function InstallMsiFilesFromDir([string]$msi_dir, [string]$msi_params) {
	Write-Host "Looking for MSI files in the dir ""$msi_dir"""
	$msi_files = @(Get-ChildItem (Join-Path $msi_dir $msi_FilesMask))

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
$logMessage = ">>>>>>>>>>>>> Deployed: " + $msi_installed
Write-Host $logMessage
$logMessage = ">>>>>>>>>>>>> Failed: " + $msi_failed
Write-Host $logMessage

$logMessage = 'deployed ' + $msi_installed.Count + '; failed: ' + $msi_failed.Count
Write-Host $logMessage

if ($msi_failed.Count -ne 0) {
	$logMessage = "ERROR: MSI installation failed"
	$logMessage = "##vso[task.logissue type=error]$logMessage"
	Write-Host $logMessage
	exit 1
}
