
##Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-257592_LogFile.txt"

$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\PortProxy"
$portProxyCommand = "netsh interface portproxy show all"

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
        param ($registryPath, $portProxyCommand)

        ## Check registry path
        if (Test-Path $registryPath) {
            ## Check for proxied ports
            $portProxyResult = Invoke-Expression $portProxyCommand
            if ($portProxyResult) {
                ## Delete port proxies
                Invoke-Expression "netsh interface portproxy delete"
                Write-Host "Port proxies deleted: $remotehost" -ForegroundColor Green
                "Port proxies deleted"
            } else {
                Write-Host "No port proxies found: $remotehost" -ForegroundColor Green
                "No port proxies found"
            }
        } else {
            Write-Host "No port proxy registry key found: $remotehost" -ForegroundColor Green
            "No port proxy registry key found"
        }
    } -ArgumentList $registryPath, $portProxyCommand -ErrorAction Stop

    "$remotehost, $result" | Out-File -FilePath $logFile -Append
} catch {
    "$remotehost, Error" | Out-File -FilePath $logFile -Append
    Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
}
}
Write-Host "Script execution completed." -ForegroundColor Green