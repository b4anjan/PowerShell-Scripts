

#======Remove================================================================

Remove-Item -Path "\\spbuw-iss000073.area52.afnoapps.usaf.mil\C\$Program Files (x86)\Adobe\*" -Recurse -Force 
 
#======Check=========
 $filePath = "\\spbuw-iss000073.area52.afnoapps.usaf.mil\C$\Program Files (x86)\Adobe\Acrobat DC"
    if (Test-Path -Path $filePath) {
        Write-Host "File exists to spbul-iss00073" -ForegroundColor Green

    } else {
        Write-Host "File doesn't exist to spbuw-iss000073" -ForegroundColor Yellow
        }

#======Reboot===============================================================
# Restart the remote PC
$remotehost = "spbuw-iss000073"
Restart-Computer -ComputerName $remotehost -Force


#======Reboot with Warning==================================================

# Send warning message 2 minutes before reboot
$remotehost = "spbuw-iss000070"

Try {
    # Send warning message
    Invoke-Command -ComputerName $remotehost -ScriptBlock {
        msg * "WARNING: System will reboot in 2 minutes to complete Win-Update. Please save your work."
    }
    
    # Wait 2 minutes
    Start-Sleep -Seconds 120
    
    # Restart the remote PC
    Restart-Computer -ComputerName $remotehost -Force
} Catch {
    Write-Error "Error occurred: $($Error[0].Message)"
}#===========================================================================