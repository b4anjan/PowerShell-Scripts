
#Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253410_LogFile.txt"

$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
$registryValueName = "EnableUserControl"
$expectedValue = 0

#Clear console
Clear-Host

#Read remote hosts file
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
            param ($registryPath, $registryValueName, $expectedValue)


            ## Check registry path
            if (-Not (Test-Path $registryPath)) {
                New-Item -Path $registryPath -Force | Out-Null
            }


            ## Get current registry value
            $currentValue = (Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue).$registryValueName


            ## Set value if incorrect or missing
            if ($currentValue -ne $expectedValue) {
                Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $expectedValue
                "0"
            } else {
                $currentValue
            }
        } -ArgumentList $registryPath, $registryValueName, $expectedValue -ErrorAction Stop


        "$remotehost, $result" | Out-File -FilePath $logFile -Append
        Write-Host "SUCCESS: $remotehost verified/corrected to $result." -ForegroundColor Green
    } catch {
        "$remotehost, Error" | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
    }
}
Write-Host "Script execution completed." -ForegroundColor Green