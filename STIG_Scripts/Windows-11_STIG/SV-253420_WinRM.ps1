
#Define the path to the remote hosts file
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253420_LogFile.txt"
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service"
$registryValueName = "DisableRunAs"
$expectedValue = 1 # Disallowed

Clear-Host

#Function to log messages
function Write-Log {
    param (
    [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    }
    
    #Read the remote hosts file
    if (-Not (Test-Path $remoteHostsFile)) {
        "$remoteHostsFile, Hosts file not found." | Out-File -FilePath $logFile
        exit
    }
    
    $remotehosts = Get-Content -Path $remoteHostsFile
    
    foreach ($remotehost in $remotehosts) {
        Write-Host "Processing remote host: $remotehost" -ForegroundColor Yellow
    
    ## Check if the host is online
    if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
        "$remotehost, Offline" | Out-File -FilePath $logFile -Append
        continue
    }

    ## Execute commands on the remote host
    try {
        $result = Invoke-Command -ComputerName $remotehost -ScriptBlock {
            param ($registryPath, $registryValueName, $expectedValue)

            ## Check if the registry path exists
            if (-Not (Test-Path $registryPath)) {
                New-Item -Path $registryPath -Force | Out-Null
            }

            ## Get the current value of the registry key
            $currentValue = (Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue).$registryValueName

            ## Set the value if it is incorrect or missing
            if ($currentValue -ne $expectedValue) {
                Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $expectedValue
                "1"
            } else {
                $currentValue
            }
        } -ArgumentList $registryPath, $registryValueName, $expectedValue -ErrorAction Stop

        "$remotehost, $result" | Out-File -FilePath $logFile -Append
        Write-Host "SUCCESS: $remotehost verified/corrected to this: $result." -ForegroundColor Green
    } catch {
        "$remotehost, Error" | Out-File -FilePath $logFile -Append
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
    }
}
Write-Host "Script execution completed." -ForegroundColor Green