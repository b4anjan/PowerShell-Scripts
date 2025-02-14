
##Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253468_LogFile.txt"

$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$registryValueName = "FilterAdministratorToken"
$registryValueData = 1

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
            param ($registryPath, $registryValueName, $registryValueData, $remotehost)

            ## Check registry path
            if (-Not (Test-Path $registryPath)) {
                New-Item -Path $registryPath -Force | Out-Null
            }

            ## Get current registry value
            $currentValue = (Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue).$registryValueName

            ## Set value if incorrect or missing
            if ($currentValue -ne $registryValueData) {
                Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $registryValueData
                Write-Host "Replaced $registryValueName on $remotehost" -ForegroundColor Green
                "1"

            } else {
                Write-Host "$registryValueName already exists on $remotehost" -ForegroundColor Yellow
                $currentValue
            }
        } -ArgumentList $registryPath, $registryValueName, $registryValueData, $remotehost -ErrorAction Stop

        "$remotehost, $result" | Out-File -FilePath $logFile -Append
    } catch {
        "$remotehost, Error" | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
    }
}
Write-Host "Script execution completed." -ForegroundColor Green