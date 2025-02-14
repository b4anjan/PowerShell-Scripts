# Define variables
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$regKey1 = "ProductVersion"
$regKey2 = "TargetReleaseVersion"
$regKey3 = "TargetReleaseVersionInfo"

# Log file path
$logDir = "C:\SDPU\WindowsUpdate\Log"
$logFile = Join-Path -Path $logDir -ChildPath "RevertLog.txt"

# Create log directory if it doesn't exist
if (!(Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory
}

Clear-Host

# Start logging
Add-Content -Path $logFile -Value "`n========= Revert Started: $(Get-Date) ========="

try {
    # Remove registry values to reset settings
    Remove-ItemProperty -Path $regPath -Name $regKey1, $regKey2, $regKey3 -ErrorAction SilentlyContinue
    gpupdate /force | Out-Null
    "Group Policy settings reverted."
    Add-Content -Path $logFile -Value "$(Get-Date) - Group Policy settings reverted."
} catch {
    Add-Content -Path $logFile -Value "$(Get-Date) - Error: $_"
    Write-Host "Error: $_" -ForegroundColor Red
}

# End logging
Add-Content -Path $logFile -Value "`n========= Revert Completed: $(Get-Date) ========="
Write-Host "Revert completed. Check log file at $logFile" -ForegroundColor Green