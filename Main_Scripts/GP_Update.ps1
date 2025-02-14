
#Define the path to the remote hosts file
$remoteHostsFile = "C:\SDPU\STIG Remote Hosts\CS.txt"

Clear-host

#Read the remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
Write-Host "ERROR: Hosts file not found at $remoteHostsFile."
exit
}

$remotehosts = Get-Content -Path $remoteHostsFile
foreach ($remotehost in $remotehosts) {
Write-Host "Processing remote host: $remotehost"
## Check if the host is online
if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
    Write-Host "WARNING: Remote host $remotehost is offline. Skipping."
    continue
}


## Execute GPUpdate command on the remote host
try {
    Invoke-Command -ComputerName $remotehost -ScriptBlock {
        gpupdate /force /wait:0
        Write-Host "GPUpdate completed successfully on $using:remotehost."
    } -ErrorAction Stop
} catch {
    Write-Host "ERROR: Failed to run GPUpdate on $remotehost. $_"
}
}
Write-Host "Script execution completed."