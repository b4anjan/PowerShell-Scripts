

##Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253281_rule_LogFile.txt"

##Clear console
Clear-Host

##Read remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
"$remoteHostsFile, Hosts file not found." | Out-File -FilePath $logFile
exit
}

$remotehosts = Get-Content -Path $remoteHostsFile

foreach ($remotehost in $remotehosts) {
Write-Host "Processing remote host: $remotehost" -ForegroundColor Yellow
## Check if host is online
if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
    "$remotehost, Offline" | Out-File -FilePath $logFile -Append
    continue
}

## Execute commands on remote host
try {
    $result = Invoke-Command -ComputerName $remotehost -ScriptBlock {
        $firewallStatus = (Get-Service -Name MpsSvc).Status
        if ($firewallStatus -eq "Running") {
            Write-Host "Firewall is enabled: $remotehost" -ForegroundColor Green
            "Firewall is enabled"
        } else {
            Write-Host "Firewall is disabled: $remotehost" -ForegroundColor Red
            "Firewall is disabled"
        }
    } -ErrorAction Stop

    "$remotehost, $result" | Out-File -FilePath $logFile -Append
} catch {
    "$remotehost, Error" | Out-File -FilePath $logFile -Append
    Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
}
}
Write-Host "Script execution completed." -ForegroundColor Green