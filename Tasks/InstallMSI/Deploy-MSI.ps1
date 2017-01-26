#
# Script installs all .msi files found in a dir
#

[CmdletBinding()]
Param(
	[Parameter(Mandatory=$False)]
	[string] $msiDir = (Split-Path $MyInvocation.MyCommand.Path),
	
	[Parameter(Mandatory=$False)]
	[string] $msiFilesMask = '*.msi',
	
	[Parameter(Mandatory=$False)]
	[string] $EnvVarRegex = '^ENV_',
	
	[Parameter(Mandatory=$False)]
	[bool] $AnalyseFailureRootCause = $True
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

function ParseLogFile([string]$log_file, [string]$actionReturnValue) {
	$errorSearchString_beginning = ".+\s+Executing op:\s+.+"
	$errorSearchString_end = "^Action ended .+ Return value $actionReturnValue\.$"
	$maxContextLines = 20
	
	# Looking for the first failure and its pre-context
	$firstMatch = Select-String -Path $log_file -Pattern $errorSearchString_end -Context $maxContextLines,0 | Select-Object -First 1
	if (! $firstMatch) {
		Write-Host "Failed to analyse log file"
		return 1
	}
	$context = $firstMatch.Context.PreContext

	# Looking for the start of the failing operation
	$match = $context | Select-String -Pattern $errorSearchString_beginning -Context 1,$maxContextLines | Select-Object -Last 1
	if ($match) {
		$context = $match.Context.PostContext -join "`n"
	}
	
	Write-Host "----- extract from the log file:"
	Write-Host "..."
	Write-Host $context
	Write-Host "..."
	Write-Host "-----"

	return 0
}

function AnalyseFailureRootCause([Int64]$exitCode, [string]$log_file) {
	switch ($exitCode) {
		1601	{
			Write-Host "ERROR_INSTALL_SERVICE_FAILURE ($exitCode): The Windows Installer service could not be accessed. Contact your support personnel to verify that the Windows Installer service is properly registered."
			break
		}
		1603	{
			Write-Host "ERROR_INSTALL_FAILURE ($exitCode): A fatal error occurred during installation."
			ParseLogFile $log_file 3
			break
		}
		1618	{
			Write-Host "ERROR_INSTALL_ALREADY_RUNNING ($exitCode): Another installation is already in progress. Complete that installation before proceeding with this install. For information about the mutex, see _MSIExecute Mutex."
			break
		}
		1638	{
			Write-Host "ERROR_PRODUCT_VERSION ($exitCode): Another version of this product is already installed. Installation of this version cannot continue. To configure or remove the existing version of this product, use Add/Remove Programs in Control Panel."
			break
		}
		default	{ Write-Host ""; break; }
	}

	Write-Host "See full details in the log file: $log_file (click 'Download all logs as zip')"
	Write-Host "See MSDN - MsiExec.exe Error Messages: http://msdn.microsoft.com/en-us/library/aa376931(v=vs.85).aspx"
	Write-Host "See MSDN - Logging of Action Return Values: https://msdn.microsoft.com/en-us/library/windows/desktop/aa369778(v=vs.85).aspx"
	
	Write-Host "If you want this failure analysis improved, raise a Request here: https://github.com/IvanBoyko/vsts-install-MSI/issues"
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

		if ($AnalyseFailureRootCause) {
			AnalyseFailureRootCause $exitCode $log_file
		}
		
		$message = "##vso[task.logissue type=error]" + (hostname) + ": " + "ERROR: MSI installatin failed with exit code $exitCode for $msi_file"
		Write-Host $message
		
		$script:msi_failed += $msi_file
	}
}

function InstallMsiFilesFromDir([string]$msiDir, [string]$msi_params) {
	Write-Host "Looking for MSI files in the dir ""$msiDir"""
	$msi_files = @(Get-ChildItem (Join-Path $msiDir $msiFilesMask))

	# Install each MSI one by one
	$msi_files | %{
		InstallMsi $_.FullName $msi_params
	}
}


#
# Main programme
#

$msi_params = GetMsiParams

InstallMsiFilesFromDir $msiDir $msi_params

Write-Host "Installation is finished"
$logMessage = ">>>>>>>>>>>>> Deployed: " + $msi_installed
Write-Host $logMessage
$logMessage = ">>>>>>>>>>>>> Failed: " + $msi_failed
Write-Host $logMessage

$logMessage = 'deployed ' + $msi_installed.Count + '; failed: ' + $msi_failed.Count
Write-Host $logMessage

if ($msi_failed.Count -ne 0) {
	$logMessage = "ERROR: MSI installation failed"
	$logMessage = "##vso[task.complete result=Failed]$logMessage"
	Write-Host $logMessage
	exit 1
}
