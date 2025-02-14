
#################################################
#  This script imports the module               #
#  Installs the Windows update only "23H2"      #
#  Reboots to completes the Update.             #
#################################################


# Import the module on PC
Import-Module -Name PSWindowsUpdate -Force 


# Install Windows updates
Install-WindowsUpdate -AcceptAll -AutoReboot 
 
 # Retrieve available updates
$updates = Get-WindowsUpdate

# Filter updates to find the Windows 11, 23H2 update
$desiredUpdate = $updates | Where-Object {$_.Title -eq "Windows 11, version 23H2"}

# Install the desired update
Install-WindowsUpdate -KBArticleID $desiredUpdate.KBArticleID -AcceptAll -AutoReboot 