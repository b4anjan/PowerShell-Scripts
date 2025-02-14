
$remotePCs = Get-Content -Path "C:\SDPU\Scritps\Windows\Last25\21h2_last.txt"
$totalPCs = $remotePCs.Count
Clear-Host

for ($i = 0; $i -lt $totalPCs; $i++) {
    $pc = $remotePCs[$i]
    Write-Host "Processing PC $($i + 1) of $totalPCs"
    try {
        Restart-Computer -ComputerName $pc -Force  -ErrorAction Stop
        Write-Host "$pc rebooted successfully." -ForegroundColor Green
    } catch {
        Write-Host "$pc Error rebooting " -ForegroundColor Red
    }
}

#===== This is for single PC Reboot =============================

    If (Restart-Computer -ComputerName SPBUW-CES31048 -Force) {
        Write-Host "Rebooted"
    } else {
        Write-host "Not rebooted"
    }
#================================================================      

#Start Remote Service and Reboot === for Single PC ==============

    # Define remote computer name
    $computerName = "SPBUW-CES31048"

    # Define service name
    $serviceName = "wuauserv"

    # Start remote service =====================================
    Invoke-Command -ComputerName $computerName -ScriptBlock {
        Start-Service -Name $using:serviceName
    }

    # Reboot remote computer ====================================
    If (Restart-Computer -ComputerName $computerName -Force) {
            Write-Host "Rebooted"
        } else {
            Write-host "Not rebooted"
        }
#===============================================================

 #Check PC Status - Online/Offline ===Single PC Test Connection==

    $remoteHost = "SPBUL-CEIG901V7"

 if (Test-Connection -ComputerName $remoteHost -Quiet) {
        Write-Host "$remoteHost is online." -ForegroundColor Green
    } else {
        Write-Host "$remoteHost is offline." -ForegroundColor Red
    }


#Add Remote Computer to Trusted Hosts (if needed) =================
Set-Item WSMan:\localhost\Client\TrustedHosts -Value SPBUW-CES31048

#Enable PowerShell Remoting (if needed) ===========================
    $computers = "SPBUW-CES31048"
foreach ($computer in $computers) {
    Invoke-Command -ComputerName $computer -ScriptBlock {
        Restart-Service -Name WinRM -Force
        Enable-PSRemoting -Force
    } -ErrorAction Stop
}


Invoke-Command -ComputerName SPBUW-CES31048 -ScriptBlock { Restart-Service -Name WinRM -Force }