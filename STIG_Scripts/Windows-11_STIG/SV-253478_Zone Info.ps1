
##Define paths
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253478r991589_rule_LogFile.txt"

$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Attachments"
$registryValueName = "SaveZoneInformation"
$registryValueData = 2

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
            param ($registryPath, $registryValueName, $registryValueData)

            ## Check registry path
            if (-Not (Test-Path $registryPath)) {
                New-Item -Path $registryPath -Force | Out-Null
            }

            ## Get current registry value
            $currentValue = (Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue).$registryValueName

            ## Set value if incorrect or missing
            if ($currentValue -ne $registryValueData) {
                Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $registryValueData
                "Zone information preservation policy corrected to $registryValueData."
                Write-Host "Zone information preservation policy corrected to $registryValueData." -ForegroundColor Green

            } elseif ($null -eq $currentValue) {
                "Zone information preservation policy is not configured, which is compliant."
                Write-Host "Zone information preservation policy is not configured, which is compliant." -ForegroundColor Green

            } else {
                "Zone information preservation policy is already compliant."
                Write-Host "Zone information preservation policy is already compliant." -ForegroundColor Green
            }
        } -ArgumentList $registryPath, $registryValueName, $registryValueData -ErrorAction Stop

        "$remotehost, $result" | Out-File -FilePath $logFile -Append
    } catch {
        "$remotehost, Error" | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
    }
}
Write-Host "Script execution completed." -ForegroundColor DarkYellow