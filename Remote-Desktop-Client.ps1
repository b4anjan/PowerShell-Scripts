# Define the remote host names
$remoteHostNames = Get-Content -Path "C:\SDPU\Remote-hosts\remote_hosts_rdc.txt"

# Check remote host connections
$onlineHosts = @()
foreach ($remoteHostName in $remoteHostNames) {
    if (Test-Connection -ComputerName $remoteHostName -Count 1 -Quiet) {
        $onlineHosts += $remoteHostName
        Write-Host "$remoteHostName is online" -ForegroundColor Green
    } else {
        Write-Host "$remoteHostName is offline" -ForegroundColor Red
    }
}

# Validate remote host names file, ===== Test-Path checks if the file exist ========= checks if there are any online hosts.====
$onlineHosts.Count -eq 0 
if (!(Test-Path "C:\SDPU\Remote-hosts\remote_hosts_rdc.txt") -or !(Get-Content "C:\SDPU\Remote-hosts\remote_hosts_rdc.txt")) {
    Write-Host "Remote hosts file empty or not found." -ForegroundColor Red
}

# Check if $remoteHostNames is not empty
if ($remoteHostNames) {
    # Initialize the count variable
    $Count = 0
    
    # Get the total number of computers
    $CompAmt = $remoteHostNames.Count
    
    # Define the remote update package path
    $remoteUpdatePackagePath = "C:\SDPU\Scritps\RDC\WindowsApp.msix"
    
    Clear-Host
    
    # Install the update and restart the remote hosts

    foreach ($remoteHostName in $onlineHosts) {
        $Count++ 
        Write-Host "Running on $remoteHostName ($Count of $CompAmt)" -ForegroundColor Gray

        try {
            $sessionOption = New-PSSessionOption
            $sessionOption.IdleTimeout = [timespan]::FromSeconds(600)
            Write-Host "Session Option IdleTimeout: $($sessionOption.IdleTimeout)"
            $session = New-PSSession -ComputerName $remoteHostName -SessionOption $sessionOption

            Invoke-Command -Session $session -ScriptBlock {
                Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $using:remoteUpdatePackagePath /quiet /forcerestart" -NoWait

                # Wait for the installation to complete
                while ((Get-Process -Name msiexec).Count -gt 0) {
                    Start-Sleep 1
                }

                # Verify installation result
                $installationResult = Get-Content -Path "C:\Windows\Logs\CBS\CBS.log" | Select-String -Pattern "installed"
                if ($installationResult) {
                    Write-Host "Update installed successfully on $env:COMPUTERNAME." -ForegroundColor Green
                } else {
                    Write-Host "Update installation failed on $env:COMPUTERNAME." -ForegroundColor Red
                }
            } -ErrorAction Stop

            Remove-PSSession -Session $session
        } catch {
            Write-Host "Error connecting to $remoteHostName $_" -ForegroundColor Red
        }

        # Delete the .msi file after installation
        #Remove-Item -Path "\\$remoteHostName\C$\SDPU\*" -Force
    }
}