
#Define the path to the remote hosts file
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"

#Define the log file path (unique based on SV identifier)
$logFile = "C:\SDPU\Test\log file\SV-253371_LogFile.txt"

#Define the registry path and expected value
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"
$registryValueName = "HypervisorEnforcedCodeIntegrity"
$expectedValue = 1

Clear-Host

#Read the remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
"ERROR: Hosts file not found at $remoteHostsFile." | Out-File -FilePath $logFile
exit
}
$remotehosts = Get-Content -Path $remoteHostsFile
foreach ($remotehost in $remotehosts) {
Write-Host "Processing remote host: $remotehost" -ForegroundColor Yellow
## Check if the host is online
if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
    "$remotehost, Offline" | Out-File -FilePath $logFile -Append
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

        ## Get the current value of the registry key
        $currentValue = (Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue).$registryValueName

        ## Set the value if it is incorrect or missing
        if ($currentValue -ne $expectedValue) {
            Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $expectedValue
            "Policy corrected to Enabled ($expectedValue)."
        } else {
            "Policy already compliant."
        }

        ## Check if Hypervisor enforced Code Integrity is running
        $deviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
        if ($deviceGuard.SecurityServicesRunning -notcontains 2) {
            "ERROR: Code Integrity is not running."
        } else {
            "SUCCESS: Code Integrity is running."
        }
    } -ArgumentList $registryPath, $registryValueName, $expectedValue -ErrorAction Stop

    "$remotehost, $result" | Out-File -FilePath $logFile -Append
    Write-Host "SUCCESS: $remotehost verified/corrected." -ForegroundColor Green
} catch {
    "$remotehost, Error" | Out-File -FilePath $logFile -Append
    Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
}
}
Write-Host "Script execution completed." -ForegroundColor Green