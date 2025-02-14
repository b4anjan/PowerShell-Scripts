# Define the remote host names
$remoteHostNames = Get-Content -Path "C:\SDPU\Remote-hosts\remote_hosts_kb10.txt"

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
if (!(Test-Path "C:\SDPU\Remote-hosts\remote_hosts_kb10.txt") -or !(Get-Content "C:\SDPU\Remote-hosts\remote_hosts_kb10.txt")) {
    Write-Host "Remote hosts file empty or not found." -ForegroundColor Red
}

# Check if $remoteHostNames is not empty
if ($remoteHostNames) {
    # Initialize the count variable
    $Count = 0
    
    # Get the total number of computers
    $CompAmt = $remoteHostNames.Count
    
    # Define the remote update package path
    $remoteUpdatePackagePath = "C$\SDPU\windows10.0-kb5045594-x64_a0c7d288c87e76eab9f78f8f8eec17a6dec2b884.msu"
    
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
                $updateInstallation = Start-Process -FilePath "wusa.exe" -ArgumentList "$using:remoteUpdatePackagePath /quiet /forcerestart /accepteula" -Wait -PassThru
                Write-Host "Waiting for 5 minutes" #Installation completion time.
                Start-Sleep 300

                if ($updateInstallation.ExitCode -eq 0) {
                    Write-Host "Update KB-Win-10 installed successfully on $env:COMPUTERNAME." -ForegroundColor Green
                } elseif ($updateInstallation.ExitCode -eq 3) {
                    Write-Host "Update KB-Win-10 installation failed with exit code $($updateInstallation.ExitCode) on $env:COMPUTERNAME. Checking disk space." -ForegroundColor Yellow
                    $diskSpace = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
                    Write-Host "Available disk space on $env:COMPUTERNAME: $($diskSpace.FreeSpace / 1GB) GB"
                } else {
                    Write-Host "Update KB-Win-10 installation failed with exit code $($updateInstallation.ExitCode) on $env:COMPUTERNAME." -ForegroundColor Cyan
                }
            } -ErrorAction Stop
        
            Remove-PSSession -Session $session
        } catch {
            Write-Host "Error connecting to $remoteHostName $_" -ForegroundColor Red
        }
        
        # Delete the .exe file after installation
        #Remove-Item -Path "\\$$remoteHostName\C$\SDPU\windows10.0-kb5045594-x64_a0c7d288c87e76eab9f78f8f8eec17a6dec2b884.msu" -Force
    }
}