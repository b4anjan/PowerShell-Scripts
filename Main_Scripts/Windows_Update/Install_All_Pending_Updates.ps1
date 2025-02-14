
# Copy the module folder to the remote pc
Copy-Item -Path "C:\Program Files\WindowsPowerShell\Modules\PSWindowsUpdate" -Destination "\\SPBUW-SFS10008\C$\Program Files\WindowsPowerShell\Modules" -Recurse -Force

# Import the module on remote PC (locally - by remoting in)
Import-Module -Name PSWindowsUpdate -Force 


# Install Windows updates (locally - by remoting in)
Install-WindowsUpdate -AcceptAll -AutoReboot 
 
 # Retrieve available updates (locally - by remoting in)
    $updates = Get-WindowsUpdate

    # Filter updates
    $desiredUpdate = $updates | Where-Object {$_.Title -eq "Windows 11, version 23H2"}

    # Install the desired update
    Install-WindowsUpdate -KBArticleID $desiredUpdate.KBArticleID -AcceptAll -AutoReboot 