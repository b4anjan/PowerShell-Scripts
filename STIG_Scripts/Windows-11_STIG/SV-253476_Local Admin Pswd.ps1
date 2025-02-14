##Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253476._LogFile.txt"

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
            $adminUser = Get-LocalUser | Where-Object { $_.Name -eq "Administrator" -and $_.Enabled -eq $true }
            if ($null -ne $adminUser) {
                "Enabled local Administrator account found. Non-compliant."
            } else {
                "Enabled local Administrator account not found. You may have card access, check your local security policy."
            }
        } -ErrorAction Stop

        Write-Host "$remotehost, $result" -ForegroundColor Yellow
        "$remotehost, $result" | Out-File -FilePath $logFile -Append
    } catch {
        "$remotehost, Error" | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
    }
}
Write-Host "Script execution completed." -ForegroundColor Green