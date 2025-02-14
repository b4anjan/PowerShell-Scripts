$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253422r958400_rule_LogFile.txt"
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy"
$registryValueName = "LetAppsActivateWithVoiceAboveLock"
$expectedValue = 2 # Force Deny
Clear-Host

#Function to log messages
    function Write-Log {
    param (
    [string]$PC,
    [string]$Value,
    [string]$Compliant
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - PC: $PC, Value: $Value, Compliant: $Compliant" | Out-File -FilePath $logFile -Append
    }

#Read remote hosts file
    if (-Not (Test-Path $remoteHostsFile)) {
    Write-Host "ERROR: Hosts file not found at $remoteHostsFile." -ForegroundColor Red
    exit
    }
$remotehosts = Get-Content -Path $remoteHostsFile

#Process remote hosts
    foreach ($remotehost in $remotehosts) {
    Write-Host "Processing remote host: $remotehost" -ForegroundColor Yellow
    # Check if host is online
        if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
            Write-Host "WARNING: Remote host $remotehost is offline. Skipping." -ForegroundColor DarkYellow
            Write-Log -PC $remotehost -Value "N/A" -Compliant "No"
            continue
        }

# Execute commands on remote host
    try {
        $result = Invoke-Command -ComputerName $remotehost -ScriptBlock {
            param ($registryPath, $registryValueName, $expectedValue)

            # Check if registry path exists
            if (-Not (Test-Path $registryPath)) {
                New-Item -Path $registryPath -Force | Out-Null
            }

            # Get current registry value
            $currentValue = (Get-ItemProperty -Path $registryPath -Name $registryValueName -ErrorAction SilentlyContinue).$registryValueName

            # Set value if incorrect or missing
            if ($currentValue -ne $expectedValue) {
                Set-ItemProperty -Path $registryPath -Name $registryValueName -Value $expectedValue
                $compliant = "No"
            } else {
                $compliant = "Yes"
                }

            [PSCustomObject]@{
                Value     = $currentValue
                Compliant = $compliant
            }
        } -ArgumentList $registryPath, $registryValueName, $expectedValue -ErrorAction Stop

        Write-Log -PC $remotehost -Value $result.Value -Compliant $result.Compliant
        Write-Host "SUCCESS: Voice activation above lock policy verified/corrected on $remotehost." -ForegroundColor Green
    } catch {
        Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
        Write-Log -PC $remotehost -Value "Error" -Compliant "No"
        }
}

