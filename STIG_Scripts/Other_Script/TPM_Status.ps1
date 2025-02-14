# Define variables
$computers = Get-Content -Path "C:\SDPU\Test\Test-Remote-Host.txt"
$logFilePath = "C:\SDPU\Test\log file\SV-253255_TPM_Status_Log.csv"
Clear-Host

# Create log file if it doesn't exist
if (!(Test-Path $logFilePath)) {
    New-Item -Path $logFilePath -ItemType File
}

# Loop through computers
foreach ($computer in $computers) {
    Write-Host "Checking TPM on $computer..."
    
    # Test connection
    if (-Not (Test-Connection -ComputerName $computer -Count 1 -Quiet)) {
        Write-Host "$computer - Offline" -ForegroundColor Red
        Add-Content -Path $logFilePath -Value "$computer,Offline"
        continue
    }
    
    try {
        # Get TPM status
        $tpmStatus = Invoke-Command -ComputerName $computer -ScriptBlock {
            $tpm = Get-TPM
            [PSCustomObject]@{
                Enabled = $tpm.TPMEnabled
                Ready   = $tpm.TPMReady
                Version = $tpm.SpecificationVersion
            }
        }
        
        # Log TPM status
        if ($tpmStatus.Enabled -and $tpmStatus.Ready -and $tpmStatus.Version -eq "2.0") {
            Write-Host "TPM enabled and ready on $computer" -ForegroundColor Green
            Add-Content -Path $logFilePath -Value "$computer,TPM enabled and ready,Version $($tpmStatus.Version)"
        } else {
            Write-Host "TPM not enabled or ready on $computer" -ForegroundColor Red
            Add-Content -Path $logFilePath -Value "$computer,TPM not enabled or ready,Version $($tpmStatus.Version)"
        }
    } catch {
        Write-Host "Error checking TPM on $computer $($Error[0].Message)" -ForegroundColor Red
        Add-Content -Path $logFilePath -Value "$computer,Error checking TPM: $($Error[0].Message)"
    }
}

Write-Host "TPM status check complete. Log report saved to $logFilePath"