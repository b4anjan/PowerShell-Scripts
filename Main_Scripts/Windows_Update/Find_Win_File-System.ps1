
# Clear the console
Clear-Host

# Define the path to the remote hosts file
$computers = Get-Content -Path "C:\SDPU\Test\Test-Remote-Host.txt"


# Loop through computers
foreach ($computer in $computers) {
    Write-Host "Checking file system on $computer..."

    # Test connection
    if (-Not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
        Write-Host "$computer - Offline" -ForegroundColor Red
        continue
    }
    
    try {
        # Get file system remotely
        $fileSystem = Invoke-Command -ComputerName $computer -ScriptBlock {
            Get-Volume -DriveLetter C | Select-Object -ExpandProperty FileSystem
        }
        
        # Display result
        Write-Host "$computer $fileSystem" -ForegroundColor Green
    } catch {
        Write-Host "Error checking $computer $($Error[0].Message)" -ForegroundColor Red
    }
}