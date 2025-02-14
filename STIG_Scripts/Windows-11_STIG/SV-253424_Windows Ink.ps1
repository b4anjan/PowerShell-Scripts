
#Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253424_LogFile.txt"

$registryPath = "HKLM:\Software\Policies\Microsoft\WindowsInkWorkspace"
$registryValueName = "AllowWindowsInkWorkspace"
$expectedValue = 1 # On, but disallow access above lock

#Clear console
Clear-Host

#Function to log messages
function Write-Log {
    param (
    [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    }

    #Read remote hosts file
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

    ## Execute remote commands
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