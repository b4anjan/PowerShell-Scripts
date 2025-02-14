
##Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253445_LogFile.txt"

$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$registryValueName = "LegalNoticeText"
$legalNoticeText = @"
You are accessing a U.S. Government (USG) Information System (IS) that is provided for USG-authorized use only.

By using this IS (which includes any device attached to this IS), you consent to the following conditions:

-The USG routinely intercepts and monitors communications on this IS for purposes including, but not limited to, penetration testing, COMSEC monitoring, network operations and defense, personnel misconduct (PM), law enforcement (LE), and counterintelligence (CI) investigations.

-At any time, the USG may inspect and seize data stored on this IS.

-Communications using, or data stored on, this IS are not private, are subject to routine monitoring, interception, and search, and may be disclosed or used for any USG-authorized purpose.

-This IS includes security measures (e.g., authentication and access controls) to protect USG interests--not for your personal benefit or privacy.

-Notwithstanding the above, using this IS does not constitute consent to PM, LE or CI investigative searching or monitoring of the content of privileged communications, or work product, related to personal representation or services by attorneys, psychotherapists, or clergy, and their assistants. Such communications and work product are private and confidential. See User Agreement for details.
"@


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
            param ($registryPath, $registryValueName, $legalNoticeText)

            ## Check registry path
            if (-Not (Test-Path $registryPath)) {
                New-Item -Path $registryPath -Force | Out-Null
            }

            ## Get current registry value
            $currentValue = (Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue).$registryValueName

            ## Set value if missing
            if (!$currentValue) {
                Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $legalNoticeText
                "Configured"
            } else {
                "Already Configured"
            }
        } -ArgumentList $registryPath, $registryValueName, $legalNoticeText -ErrorAction Stop

        "$remotehost, $result" | Out-File -FilePath $logFile -Append
        Write-Host "SUCCESS: $remotehost verified/corrected to $result." -ForegroundColor Green
    } catch {
        "$remotehost, Error" | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
    }
}
Write-Host "Script execution completed." -ForegroundColor Green