# Define source path
$sourcePath = "C:\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate"  # Local module folder

# Get remote computer names
$remoteComputers = Get-Content "C:\SDPU\WindowsUpdate\test-old-OS-ver.txt"

Clear-Host

foreach ($remoteComputer in $remoteComputers) {
    # Define destination path
    $destinationPath = "\\$remoteComputer\C$\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate"

    # Check if folder exists
    if (Test-Path -Path $destinationPath) {
        Write-Host "Folder already exists on $remoteComputer. Skipping..."
        continue
    }

    # Create destination folder
    New-Item -Path $destinationPath -ItemType Directory -Force

    # Copy files and subfolders
    Get-ChildItem -Path $sourcePath -Recurse | Copy-Item -Destination $destinationPath -Force -Recurse

    # Install module on remote computer
    Invoke-Command -ComputerName $remoteComputer -ScriptBlock {
        Import-Module -Name PSWindowsUpdate -Force
        Start-Sleep -Seconds 10
        $module = Get-Module -ListAvailable -Name PSWindowsUpdate
        if ($module) {
            Write-Host "PSWindowsUpdate module installed on $using:remoteComputer"
        } else {
            Write-Host "Error installing PSWindowsUpdate module on $using:remoteComputer"
        }
    }
}

