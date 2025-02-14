# Define variables
$remoteComputers = Get-Content "C:\SDPU\WindowsUpdate\Revert_Win_Update_PC-List.txt"
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

foreach ($computer in $remoteComputers) {
    Write-Host "Reverting settings on $computer..." -ForegroundColor Yellow

    # Test connection
    if (-not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
        Write-Host "$computer is offline. Skipping." -ForegroundColor Red
        Add-Content -Path $logFile -Value "$(Get-Date) - $computer - Offline. Skipping."
        continue
    }

    try {
        Invoke-Command -ComputerName $computer -ScriptBlock {
            param ($regPath, $regKey1, $regKey2, $regKey3)

            # Check if registry values exist
            if (Get-ItemProperty -Path $regPath -Name $regKey1 -ErrorAction SilentlyContinue) {
                Remove-ItemProperty -Path $regPath -Name $regKey1, $regKey2, $regKey3 -ErrorAction SilentlyContinue
                gpupdate /force | Out-Null
                "Group Policy settings reverted."
            } else {
                "$($env:COMPUTERNAME) - Value doesn't exist. Skipping."
            }

        } -ArgumentList $regPath, $regKey1, $regKey2, $regKey3 | 
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
Add-Content -Path $logFile -Value "`n========= Revert Completed: $(Get-Date) ========="
Write-Host "Revert completed. Check log file at $logFile" -ForegroundColor Green