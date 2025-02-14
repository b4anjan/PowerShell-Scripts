
##Define the path to the remote hosts file
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
##Define the log file path (unique based on SV identifier)
$logFile = "C:\SDPU\Test\log file\SV-253369_LogFile.txt"


##Define the registry path and expected values
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard"
$vbsRegistryValues = @{
EnableVirtualizationBasedSecurity = 1
RequirePlatformSecurityFeatures = 3 # Secure Boot and DMA Protection
}
Clear-Host

#Read the remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
"ERROR: Hosts file not found at $remoteHostsFile." | Out-File -FilePath $logFile
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
        param ($registryPath, $vbsRegistryValues)


        ## Check and update registry values
        if (-Not (Test-Path $registryPath)) {
            New-Item -Path $registryPath -Force | Out-Null
        }


        foreach ($key in $vbsRegistryValues.Keys) {
            $currentValue = (Get-ItemProperty -Path $registryPath -Name $key -ErrorAction SilentlyContinue).$key
            if ($currentValue -ne $vbsRegistryValues[$key]) {
                Set-ItemProperty -Path $registryPath -Name $key -Value $vbsRegistryValues[$key]
            }
        }


        ## Check VBS status
        $deviceGuard = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
        if ($deviceGuard.VirtualizationBasedSecurityStatus -ne 2) {
            "ERROR"
        } elseif (-not ($deviceGuard.RequiredSecurityProperties -contains 2)) {
            "ERROR: Secure Boot not enabled."
        } elseif (-not ($deviceGuard.RequiredSecurityProperties -contains 3)) {
            "WARNING: DMA Protection not configured."
        } else {
            "SUCCESS"
        }
    } -ArgumentList $registryPath, $vbsRegistryValues -ErrorAction Stop


    "$remotehost, $result" | Out-File -FilePath $logFile -Append
    Write-Host "VBS and Secure Boot settings verified/corrected on $remotehost $result" -ForegroundColor Green
} catch {
    "$remotehost, Error" | Out-File -FilePath $logFile -Append
    Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
}
}
Write-Host "Script execution completed."