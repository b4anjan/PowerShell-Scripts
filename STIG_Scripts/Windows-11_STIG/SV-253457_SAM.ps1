﻿
##Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253457_LogFile.txt"

$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$registryValueName = "RestrictRemoteSAM"
$registryValueData = "O:BAG:BAD:(A;;RC;;;BA)"

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
    
    ## Check host online status
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
                "Replaced"
            } else {
                "Value exists"
            }
        } -ArgumentList $registryPath, $registryValueName, $registryValueData -ErrorAction Stop

        "$remotehost, $result" | Out-File -FilePath $logFile -Append
        if ($result -eq "Replaced") {
            Write-Host "SUCCESS: $remotehost RestrictRemoteSAM policy replaced." -ForegroundColor Green
        } else {
            Write-Host "INFO: $remotehost RestrictRemoteSAM policy value exists." -ForegroundColor Yellow
        }
    } catch {
        "$remotehost, Error" | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
    }
}
Write-Host "Script execution completed." -ForegroundColor Green