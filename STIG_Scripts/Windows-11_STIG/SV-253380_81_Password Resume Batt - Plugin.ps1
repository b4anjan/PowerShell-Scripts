
#Define the path to the remote hosts file
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"

#Define the log file path (unique based on SV identifier)
$logFile = "C:\SDPU\Test\log file\SV-253380_SV-253381_LogFile.txt"

#Define the registry path and expected values
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Power\PowerSettings\0e796bdb-100d-47d6-a2d5-f7d2daa51f51"
$registryValueNameDC = "DCSettingIndex"
$registryValueNameAC = "ACSettingIndex"
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
"$remotehost" #| Out-File -FilePath $logFile -Append
## Check if the host is online
if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
    "$remotehost, Offline" | Out-File -FilePath $logFile -Append
    continue
}

## Execute commands on the remote host
try {
    Invoke-Command -ComputerName $remotehost -ScriptBlock {
        param ($registryPath, $registryValueNameDC, $registryValueNameAC, $expectedValue)

        ## Check if the registry path exists
        if (-Not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }

        ## Get the current values of the registry keys
        $currentValueDC = (Get-ItemProperty -Path $registryPath -Name $registryValueNameDC -ErrorAction SilentlyContinue).$registryValueNameDC
        $currentValueDC = (Get-ItemProperty -Path $registryPath -Name $registryValueNameAC -ErrorAction SilentlyContinue).$registryValueNameAC
        Write-Host "Current Value - DC: $currentValueDC , AC: $currentValueDC"
        ## Set the values if they are incorrect or missing
        if ($currentValueDC -ne $expectedValue) {
            Set-ItemProperty -Path $registryPath -Name $registryValueNameDC -Value $expectedValue
            "Password prompt on resume (on battery) policy corrected to Enabled (1)."
        } else {
            "Password prompt on resume (on battery) policy already compliant."
        }

        if ($currentValueAC -ne $expectedValue) {
            Set-ItemProperty -Path $registryPath -Name $registryValueNameAC -Value $expectedValue
            "Password prompt on resume (plugged in) policy corrected to Enabled (1)."
        } else {
            "Password prompt on resume (plugged in) policy already compliant."
        }
    } -ArgumentList $registryPath, $registryValueNameDC, $registryValueNameAC, $expectedValue -ErrorAction Stop

    "$remotehost, SUCCESS" | Out-File -FilePath $logFile -Append
    Write-Host "SUCCESS: $remotehost verified/corrected." -ForegroundColor Green
} catch {
    "$remotehost, ERROR" | Out-File -FilePath $logFile -Append
    Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
}
}
Write-Host "Script execution completed." -ForegroundColor Green