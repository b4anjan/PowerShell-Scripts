<#===================================================================================================================
------This Script copies the file to the destination and generates the report----------
------Checks if the file is exists or not.
===================================================================================================================#>


# Get the list of remote hosts from the text file
#$remoteHosts = Get-Content -Path "C:\SDPU\WindowsUpdate\Old_OS_PCs.txt"
$remoteHosts = "SPBUW-ISS30973"

# Define the package file and destination
# Make sure to provide directory path not the file's path
$packageFile = "C:\SDPU\WindowsUpdate\23H2"
$destination = "C$\SDPU"

# Create an array to store the results
$results = @()

# Initialize the count variable
$Count = 0

# Get the total number of computers
$CompAmt = $remoteHosts.Count

Clear-Host

# Loop through each remote host
foreach ($remoteHost in $remoteHosts) {
    $Count++
    Write-Host "Running on $remoteHost ($Count of $CompAmt)" -ForegroundColor Gray

    # Check if the remote host is online
    if (!(Test-Connection -ComputerName $remoteHost -Count 1 -Quiet)) {
        Write-Host "Host $remoteHost is offline, skipping..." -ForegroundColor Yellow
        $results += [PSCustomObject]@{
            ComputerName = $remoteHost
            FileExists   = $false
            Copied       = $false
            Status       = "Offline"
        }
        continue
    }

    # Check if the destination folder exists
    $destPath = "\\$remoteHost\$destination"
    if (!(Test-Path -Path $destPath)) {
        # Destination folder does not exist, create it
        New-Item -ItemType Directory -Force -Path $destPath | Out-Null
        Write-Host "Destination folder created on $remoteHost" -ForegroundColor Cyan
    }

    # Check if the file exists
    $filePath = "$destination\Win_11_23H2.msu"

    if (Test-Path -Path "\\$remoteHost\$filePath") {
        # File exists, write a message to the host
        Write-Host "File already exists on $remoteHost, skipping..." -ForegroundColor Yellow
        # File exists, add a result to the array
        $results += [PSCustomObject]@{
            ComputerName = $remoteHost
            FileExists   = $true
            Copied       = $false
        }
    } else {
        # File does not exist, copy the file to the destination
        Robocopy "$packageFile" "\\$remoteHost\$destination" /IS /S /E /MIR /NP /R:1

        # Check if the file was copied successfully
        if (Test-Path -Path "\\$remoteHost\$filePath") {
            # File was copied, write a success message to the host
            Write-Host "File copied to $remoteHost" -ForegroundColor Green
            # File was copied, add a success result to the array
            $results += [PSCustomObject]@{
                ComputerName = $remoteHost
                FileExists   = $true
                Copied       = $true
            }
        } else {
            # File was not copied, write a failure message to the host
            Write-Host "File not copied to $remoteHost" -ForegroundColor Red
            # File was not copied, add a failure result to the array
            $results += [PSCustomObject]@{
                ComputerName = $remoteHost
                FileExists   = $false
                Copied       = $false
            }
        }
    }
}

# Export the results to a CSV file
#$results | Export-Csv -Path "C:\22h2_copy_results.csv" -NoTypeInformation

# Write a completion message to the host
Write-Host "Script completed." -ForegroundColor Yellow #Results exported to C:\22h2_copy_results.csv