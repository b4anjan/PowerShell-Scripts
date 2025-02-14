
# This script configures group policy for targeting a specific Windows feature update,
# triggers Windows Update to check and install updates, and optionally reverts settings.

# WHAT THIS SCRIPT DOES!
# ======================================================================================
# - Configures group policy remotely to target a specific feature update (e.g., "23H2").
# - Triggers Windows Update to detect and install updates.
# - Optionally reverts group policy settings after execution.
# - Provides feedback on the process for each remote machine.

# Requirements:################################################################################
# - Run script as administrator.                                                              #
# - Ensure PowerShell remoting is enabled on target machines.                                 #
###############################################################################################


# Define variables
#$remoteComputers = Get-Content "C:\SDPU\Scritps\Windows\Last25\21h2_last.txt"
$remoteComputers = "SPBUW-SFS10008"
$targetVersion = "23H2"
$productVersion = "Windows 11"

# Define registry paths
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$regKey1 = "ProductVersion"
$regKey2 = "TargetReleaseVersion"
$regKey3 = "TargetReleaseVersionInfo"

# Log file path
$logDir = "C:\SDPU\Scritps\Windows\Log"
$logFile = Join-Path -Path $logDir -ChildPath "ScriptExecutionLog-SPBUW-SFS10008.txt"

# Create log directory if it doesn't exist
if (!(Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory
}

Clear-Host

# Start logging
Add-Content -Path $logFile -Value "`n========= Script Execution Started: $(Get-Date) ========="

foreach ($computer in $remoteComputers) {
    Write-Host "Processing $computer..." -ForegroundColor Cyan

    # Test connection
    if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
        Write-Host "$computer is offline. Skipping." -ForegroundColor Red
        Add-Content -Path $logFile -Value "$(Get-Date) - $computer - Offline. Skipping."
        continue
    }

    try {
        Invoke-Command -ComputerName $computer -ScriptBlock {
            param ($regPath, $regKey1, $regKey2, $regKey3, $productVersion, $targetVersion)

            # Check if registry values exist
            if ((Get-ItemProperty -Path $regPath -Name $regKey1 -ErrorAction SilentlyContinue) -and
                (Get-ItemProperty -Path $regPath -Name $regKey2 -ErrorAction SilentlyContinue) -and
                (Get-ItemProperty -Path $regPath -Name $regKey3 -ErrorAction SilentlyContinue)) {
                "Registry values already exist. Skipping."
                return
            }

            # Ensure registry path exists
            if (-not (Test-Path $regPath)) {
                try {
                    New-Item -Path $regPath -Force | Out-Null
                    "Registry path created."
                } catch {
                    "Failed to create registry path: $_"
                    throw
                }
            }

            # Set Group Policy values
            try {
                Set-ItemProperty -Path $regPath -Name $regKey1 -Value $productVersion -Force
                Set-ItemProperty -Path $regPath -Name $regKey2 -Value 1 -Force
                Set-ItemProperty -Path $regPath -Name $regKey3 -Value $targetVersion -Force
                "Registry values set successfully."
            } catch {
                "Failed to set registry values: $_"
                throw
            }

            # Force Group Policy update
            try {
                gpupdate /force | Out-Null
                "GP - updated."
                Start-Sleep -Seconds 50
                "Group Policy updated successfully."
            } catch {
                "Failed to apply Group Policy update: $_"
                throw
            }

            # Trigger Windows Update
            try {
                Start-Process -FilePath "usoclient.exe" -ArgumentList "/startscan" -NoNewWindow -Wait
                "Triggered update detection."
                Start-Process -FilePath "usoclient.exe" -ArgumentList "/startinstall" -NoNewWindow -Wait
                "Triggered update installation."
                "Windows Update triggered successfully."
            } catch {
                "Failed to trigger Windows Update: $_"
                throw
            }
        } -ArgumentList $regPath, $regKey1, $regKey2, $regKey3, $productVersion, $targetVersion | 
        ForEach-Object {
            Add-Content -Path $logFile -Value "$(Get-Date) - $computer - $_"
            Write-Host "$computer - $_"
        }
    } catch {
        Add-Content -Path $logFile -Value "$(Get-Date) - $computer - Error: $_"
        Write-Host "$computer - Error: $_" -ForegroundColor Red
    }
}

# End logging
Add-Content -Path $logFile -Value "`n========= Script Execution Completed: $(Get-Date) ========="
Write-Host "Script execution completed. Check log file at $logFile" -ForegroundColor Green


# Reverse Group Policy settings (Optional)
<# Uncomment the following block to reverse settings after update is applied.
    foreach ($computer in $remoteComputers) {
        Write-Host "Reverting settings on $computer..." -ForegroundColor Yellow
        try {
            Invoke-Command -ComputerName $computer -ScriptBlock {
                param ($regPath, $regKey1, $regKey2, $regKey3)

                # Remove registry values to reset settings
                Remove-ItemProperty -Path $regPath -Name $regKey1, $regKey2, $regKey3 -ErrorAction SilentlyContinue
                gpupdate /force | Out-Null
                "Group Policy settings reverted."

            } -ArgumentList $regPath, $regKey1, $regKey2, $regKey3 -ErrorAction Stop
        } catch {
            Write-Host "Error reverting settings on $computer: $_" -ForegroundColor Red
        }
    }
#>