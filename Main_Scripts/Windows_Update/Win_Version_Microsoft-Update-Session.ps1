# Define variables
$remoteComputers = Get-Content "C:\SDPU\WindowsUpdate\test-old-OS-ver.txt"
$targetVersion = "23H2"
$productVersion = "Windows 11"

# Define registry paths
$regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
$regKey1 = "ProductVersion"
$regKey2 = "TargetReleaseVersion"
$regKey3 = "TargetReleaseVersionInfo"

# Log file path
$logDir = "C:\SDPU\WindowsUpdate\Log"
$logFile = Join-Path -Path $logDir -ChildPath "ScriptExecutionLog.txt"

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
        Add-Content -Path $logFile -Value "$computer - Offline. Skipping."
        continue
    }

    try {
        Invoke-Command -ComputerName $computer -ScriptBlock {
            param ($regPath, $regKey1, $regKey2, $regKey3, $productVersion, $targetVersion)

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
                "Group Policy settings updated."
                Start-Sleep -Seconds 90
                "Group Policy updated successfully."
            } catch {
                "Failed to apply Group Policy update: $_"
                throw
            }

            # Create Microsoft.Update.Session COM object
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            if ($null -eq $updateSession) {
                Write-Host "Failed to create update session."
                return
            }

            $updateSearcher = $updateSession.CreateUpdateSearcher()
            if ($null -eq $updateSearcher) {
                Write-Host "Failed to create update searcher."
                return
            }

            # Search for updates synchronously
            $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
            if ($null -eq $searchResult) {
                Write-Host "No updates found."
                return
            }

            # Install updates
            if ($searchResult.Updates.Count -gt 0) {
                $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($update in $searchResult.Updates) {
                    $updatesToInstall.Add($update)
                }
                $installer = $updateSession.CreateUpdateInstaller()
                if ($null -eq $installer) {
                    Write-Host "Failed to create update installer."
                    return
                }
                $installer.Updates = $updatesToInstall
                $installationResult = $installer.Install()
                if ($null -eq $installationResult) {
                    Write-Host "Failed to install updates."
                    return
                }
                "Installed updates: $($installationResult.UpdatesInstalled)"
            }
        } -ArgumentList $regPath, $regKey1, $regKey2, $regKey3, $productVersion, $targetVersion | 
        ForEach-Object {
            Add-Content -Path $logFile -Value "$computer - $_"
            Write-Host "$computer - $_"
        }
    } catch {
        Add-Content -Path $logFile -Value "$computer - Error: $_"
        Write-Host "$computer - Error: $_" -ForegroundColor Red
    }
}

# End logging
Add-Content -Path $logFile -Value "`n========= Script Execution Completed: $(Get-Date) ========="
Write-Host "Script execution completed. Check the log file at $logFile" -ForegroundColor Green