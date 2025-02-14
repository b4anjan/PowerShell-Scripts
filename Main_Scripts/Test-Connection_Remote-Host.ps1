
#Here's a modified PowerShell script:

#Define remote host
$remoteHost = Get-Content "C:\SDPU\WindowsUpdate\Log\23H2-Offline-log.txt"

#Check if remote host is online
$pingResult = Test-Connection -ComputerName $remoteHost -Count 1 -Quiet

Clear-Host

if ($pingResult) {
Write-Host "The PC $remoteHost is online." -ForegroundColor Green
} else {
Write-Host "The PC $remoteHost is offline." -ForegroundColor Red
}

#Optional: Log result to file
"$remoteHost`t(if ($pingResult) {'Online'} else {'Offline'})"
$logMessage | Out-File -FilePath $logFile -Append

#Optional: Display result in table format
[PSCustomObject]@{
Host = $remoteHost
Status = if ($pingResult) {'Online'} else {'Offline'}
} | Format-Table -AutoSize

#Replace "spbul-cs901v9" with your remote host name or IP address.