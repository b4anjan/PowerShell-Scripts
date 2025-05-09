<#

Script Description:
This PowerShell script automates the process of applying multiple STIG (Security Technical Implementation Guide) rules to remote hosts by reading 
the rules from a CSV file. It checks each remote host's connectivity, verifies and modifies registry settings, and logs the results accordingly.

How the Script Works:
Initialize Paths:
    Reads the list of remote hosts from C:\SDPU\Test\Test-Remote-Host.txt
    Reads STIG rules from C:\SDPU\Test\STIG-Rules.csv
    Logs all actions to C:\SDPU\Test\log file\STIG_Application_Log.txt
Check Remote Host Availability:
    If a host is offline, logs "RemoteHost Name - Offline" and skips to the next host.

Process Each STIG Rule from CSV:
    Extracts RuleNumber, RegistryPath, RegistryKey, and DesiredValue.

Connects to the remote host and checks if:
    The registry path exists. If not, creates it.
    The registry key exists with the correct desired value.
    If the value is correct, logs "RemoteHost - RuleNumber - Desired Value Exists".
    If the key or value does not exist, creates the key and sets the value.
    Logs "RemoteHost - RuleNumber - RegistryPath created and desired value applied." if the path was created.
    Logs "RemoteHost - RuleNumber - Applied" if only the value was changed.
    If applying the setting fails, logs "RemoteHost - RuleNumber - Not Applied or Error".

Final Logging:
Logs "Script execution completed." once all hosts and rules are processed.

CSV File Format (STIG-Rules.csv):
    RuleNumber	    RegistryPath	                                            RegistryKey	        DesiredValue
    V-123456	    HKLM:\SOFTWARE\Policies\Microsoft\Windows\	                EnableFirewall	    1
    V-654321	    HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\	            KeepAliveTime	    7200000
    V-789012	    HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\	NoLMHash	        1

Columns Explanation:
    RuleNumber: Unique STIG rule identifier (e.g., V-123456).
    RegistryPath: Full registry path where the setting is applied.
    RegistryKey: The specific key that needs modification.
    DesiredValue: The value that should be set for compliance.

Example Log Entries:
    yaml
    2025-01-08 08:00:00 - spbul-cs901v9 - V-123456 - Desired Value Exists
    2025-01-08 08:00:05 - spbul-cs901v9 - V-654321 - RegistryPath created and desired value applied.
    2025-01-08 08:00:10 - spbul-cs901v9 - V-789012 - Applied
    2025-01-08 08:00:15 - spbuw-cs30883 - Offline
    2025-01-08 08:00:20 - spbul-cs902v7 - V-123456 - Not Applied or Error.
    
Why This Approach?
    Single Script for Multiple Rules – No need to create separate scripts for each STIG rule.
    Automated Checking & Logging – Provides detailed logs for auditing.
    Handles Registry Path Creation – Ensures compliance even if the registry structure is missing.
    Prevents Unnecessary Changes – Skips applying values if they are already compliant.
#>

# Define paths
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$csvFile = "C:\SDPU\Test\STIG-Rules.csv"
$logFile = "C:\SDPU\Test\log file\STIG_Application_Log.txt"

Clear-Host

# Function to log messages
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    } catch {
        Write-Host "Error writing to log file: $_"
    }
}

# Read the remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
    Write-Host "ERROR: Hosts file not found at $remoteHostsFile."
    exit
}
$remotehosts = Get-Content -Path $remoteHostsFile

# Read the STIG rules CSV
if (-Not (Test-Path $csvFile)) {
    Write-Host "ERROR: STIG rules file not found at $csvFile."
    exit
}
$stigRules = Import-Csv -Path $csvFile

foreach ($remotehost in $remotehosts) {
    Write-Host "Processing remote host: $remotehost"
    Write-Log "Processing remote host: $remotehost"

    # Check if the host is online
    if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
        Write-Host "$remotehost - Offline" -ForegroundColor Red
        Write-Log "$remotehost - Offline"
        continue
    }

    foreach ($rule in $stigRules) {
        $ruleNumber = $rule.RuleNumber
        $registryPath = $rule.RegistryPath
        $policyName = $rule.RegistryKey
        $policyValue = $rule.DesiredValue

        try {
            $result = Invoke-Command -ComputerName $remotehost -ScriptBlock {
                param ($registryPath, $policyName, $policyValue, $ruleNumber)

                # Check if the registry path exists
                if (-Not (Test-Path $registryPath)) {
                    New-Item -Path $registryPath -Force | Out-Null
                    $pathCreated = $true
                } else {
                    $pathCreated = $false
                }

                # Get the current value of the registry key
                $currentValue = (Get-ItemProperty -Path $registryPath -Name $policyName -ErrorAction SilentlyContinue).$policyName

                if ($currentValue -eq $policyValue) {
                    return "$ruleNumber - Desired Value Exists"
                }

                # Apply the new registry setting
                Set-ItemProperty -Path $registryPath -Name $policyName -Value $policyValue -Type String
                if ($pathCreated) {
                    return "$ruleNumber - RegistryPath created and desired value applied."
                } else {
                    return "$ruleNumber - Applied"
                }
            } -ArgumentList $registryPath, $policyName, $policyValue, $ruleNumber -ErrorAction Stop

            Write-Host "$remotehost - $result" -ForegroundColor Green
            Write-Log "$remotehost - $result"
        } catch {
            Write-Host "$remotehost - $ruleNumber - Not Applied or Error." -ForegroundColor Red
            Write-Log "$remotehost - $ruleNumber - Not Applied or Error. $_"
        }
    }
}

Write-Log "Script execution completed."
Write-Host "Script execution completed."
