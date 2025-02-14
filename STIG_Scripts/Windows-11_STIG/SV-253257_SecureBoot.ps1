<#
==== Modified ==== !! ========================
            
========================WHAT THIS SCRIPT DOES!..==================================

===========This script remediates STIG Rule: SV-253257r971547_rule (WN11-00-000020)========
           ===============================================================

Reads a list of remote hosts:
- The script reads hostnames or IP addresses from a specified text file (`C:\SDPU\Test\Test-Remote-Host.txt`).

Checks connectivity to remote hosts:
- Verifies if each remote host is reachable using `Test-Connection`.
- Skips offline hosts and logs the status.

Verifies Secure Boot status:
- For reachable hosts:
  - Uses PowerShell Remoting (`Invoke-Command`) to check the registry key for Secure Boot (`HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State\UEFISecureBootEnabled`).
  - Ensures Secure Boot is enabled (value `1`).
  - If Secure Boot is not enabled, it updates the registry and logs the action.

Reports results:
- Outputs detailed status messages, including:
  - Hosts with compliant settings.
  - Hosts where Secure Boot was corrected.
  - Hosts skipped due to being offline.
  - Errors encountered during execution for troubleshooting.

========= Why Is This Important? ===========
Ensuring that Secure Boot is enabled on all Windows 11 systems is a critical security measure to protect against bootkits and other types of low-level malware.

====== Created by: YOUR NAME ========
======================================================================================================================================
#>

# Define the path to the remote hosts file
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"

# Define the log file path (unique based on SV identifier)
$logFile = "C:\SDPU\Test\log file\SV-253257_LogFile_SecureBoot.txt"

# Define the registry path and expected value for Secure Boot
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State"
$registryValueName = "UEFISecureBootEnabled"
$expectedValue = 1 # Secure Boot should be "1" for enabled

Clear-Host

# Read the remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
    "Script,Error,N/A" | Out-File -FilePath $logFile
    exit
}
$remotehosts = Get-Content -Path $remoteHostsFile

foreach ($remotehost in $remotehosts) {
    Write-Host "Processing remote host: $remotehost" -ForegroundColor Yellow

    ## Check if the host is online
    if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
        "$remotehost,Offline,N/A" | Out-File -FilePath $logFile -Append
        continue
    }

    ## Execute commands on the remote host
    try {
        $result = Invoke-Command -ComputerName $remotehost -ScriptBlock {
            param ($registryPath, $registryValueName, $expectedValue)

            ## Check if the registry path exists
            if (-Not (Test-Path $registryPath)) {
                New-Item -Path $registryPath -Force | Out-Null
            }

            ## Get the current value of the Secure Boot registry key
            $currentValue = (Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue).$registryValueName

            ## Set the value if it is incorrect or missing
            if ($currentValue -ne $expectedValue) {
                Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $expectedValue -Type DWORD
                [PSCustomObject]@{
                    Host    = $using:remotehost
                    Value   = $expectedValue
                    Compliant = "No"
                }
            } else {
                [PSCustomObject]@{
                    Host    = $using:remotehost
                    Value   = $currentValue
                    Compliant = "Yes"
                }
            }
        } -ArgumentList $registryPath, $registryValueName, $expectedValue -ErrorAction Stop

        "$($result.Host),$($result.Value),$($result.Compliant)" | Out-File -FilePath $logFile -Append
        Write-Host "Value already compliant on $remotehost."
    } catch {
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
        "$remotehost,Error,N/A" | Out-File -FilePath $logFile -Append
    }
}

Write-Host "Script execution completed." -ForegroundColor Green
"Script,Completed,N/A" | Out-File -FilePath $logFile -Append
