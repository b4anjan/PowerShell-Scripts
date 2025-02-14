# Define the path to the remote hosts file
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
# Define the log file path (unique based on SV identifier)
$logFile = "C:\SDPU\Test\log file\SV-257592r991589_rule_LogFile.txt"
Clear-Host

# Function to log messages
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

# Read the remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
    Write-Log "ERROR: Hosts file not found at $remoteHostsFile."
    exit
}
$remotehosts = Get-Content -Path $remoteHostsFile

foreach ($remotehost in $remotehosts) {
    Write-Log "Processing remote host: $remotehost"

    # Check if the host is online
    if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
        Write-Log "WARNING: Remote host $remotehost is offline. Skipping."
        continue
    }

    # Execute commands on the remote host
    try {
        Invoke-Command -ComputerName $remotehost -ScriptBlock {
            # Check for existing portproxy configurations
            $portProxyConfig = netsh interface portproxy show all
            if ($portProxyConfig -match "v4tov4\\tcp\\") {
                Write-Host "PortProxy configuration found. Removing entries."
                netsh interface portproxy delete v4tov4
            } else {
                Write-Host "No PortProxy configuration found."
            }

            # Verify and remove any related registry entries
            $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\PortProxy"
            if (Test-Path $registryPath) {
                $subKeys = Get-ChildItem -Path $registryPath -Recurse | Where-Object { $_.Name -match "v4tov4\\tcp\\" }
                foreach ($subKey in $subKeys) {
                    Remove-Item -Path $subKey.PSPath -Recurse -Force
                }
                Write-Host "Registry entries for PortProxy removed."
            } else {
                Write-Host "PortProxy registry path does not exist."
            }
        } -ErrorAction Stop

        Write-Log "SUCCESS: PortProxy settings verified/corrected on $remotehost."
    } catch {
        Write-Log "ERROR: Failed to verify or correct PortProxy settings on $remotehost. $_"
    }
}

Write-Log "Script execution completed."