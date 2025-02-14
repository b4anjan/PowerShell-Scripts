# Define text file path containing remote hosts
$remoteHostsFilePath = "C:\SDPU\WindowsUpdate\Old_OS_PCs.txt"

# Define log file path
$logFilePath = "C:\SDPU\WindowsUpdate\Log\23h2-offline-hosts.log"

# Read remote hosts from text file
$remoteHosts = Get-Content -Path $remoteHostsFilePath

# Initialize variables
$offlineHosts = @()
$Count = 0
$CompAmt = $remoteHosts.Count

Clear-Host

foreach ($remoteHost in $remoteHosts) {
    $Count++
    Write-Host "Checking $remoteHost ($Count of $CompAmt)..." -ForegroundColor Yellow
    
    if (Test-Connection -ComputerName $remoteHost -Quiet) {
        Write-Host "$remoteHost is online." -ForegroundColor Green
    } else {
        Write-Host "$remoteHost is offline." -ForegroundColor Red
        $offlineHosts += $remoteHost
    }
}

# Log offline hosts
if ($offlineHosts.Count -gt 0) {
    Add-Content -Path $logFilePath -Value "$(Get-Date) - Offline hosts:"
    foreach ($offlineHost in $offlineHosts) {
        Add-Content -Path $logFilePath -Value "  $offlineHost"
    }
} else {
    Add-Content -Path $logFilePath -Value "$(Get-Date) - All hosts are online."
}

Write-Host "Offline hosts logged to $logFilePath" -ForegroundColor Cyan
Write-Host "Script completed. Checked $CompAmt hosts, found $($offlineHosts.Count) offline." -ForegroundColor Cyan