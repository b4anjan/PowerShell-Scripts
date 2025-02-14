
<#================================================================

====== THIS SCRIPT REMOVES/DELETES FILES FROM REMOTE HOST  =======

=================================================================#>



# Define remote PC list
$remotePcs = Get-Content -Path "C:\SDPU\Remote-hosts\remote_hosts_intel-chipset.txt"

# Define path to delete
$deletePath = "C:\SDPU\*"

foreach ($pc in $remotePcs) {
    Write-Host "Processing $pc..." -ForegroundColor Cyan
    
    # Check if host is online
    if (Test-Connection -ComputerName $pc -Quiet) {
        try {
            # Check if path exists on remote PC
            if (Invoke-Command -ComputerName $pc -ScriptBlock { Test-Path -Path $using:deletePath }) {
                # Delete files
                Write-Host "Deleting.............." -ForegroundColor Magenta
                Invoke-Command -ComputerName $pc -ScriptBlock {
                    Remove-Item -Path $using:deletePath -Recurse -Force
                }
                Write-Host "Cleanup complete on $pc!" -ForegroundColor Green
            } else {
                Write-Host "Path not found on $pc $deletePath" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error deleting files on $pc $($Error[0].Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "$pc is offline. Skipping..." -ForegroundColor Red
    }
}

#========= END =====================================================