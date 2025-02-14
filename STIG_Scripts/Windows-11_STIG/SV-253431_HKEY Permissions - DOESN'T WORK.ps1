#Define paths and values
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$logFile = "C:\SDPU\Test\log file\SV-253431_LogFile.txt"
$registryKeys = @(
"HKLM:\SECURITY",
"HKLM:\SOFTWARE",
"HKLM:\SYSTEM"
)

#Clear console
Clear-Host

#Function to log messages
function Write-Log {
param (
[string]$Message
)
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
"$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

#Read remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
"$remoteHostsFile, Hosts file not found." | Out-File -FilePath $logFile
exit
}

$remotehosts = Get-Content -Path $remoteHostsFile

foreach ($remotehost in $remotehosts) {
Write-Host "Processing remote host: $remotehost" -ForegroundColor Yellow

## Check host online status
if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
    "$remotehost, Offline" | Out-File -FilePath $logFile -Append
    continue
}

## Execute remote commands
try {
    $result = Invoke-Command -ComputerName $remotehost -ScriptBlock {
        param ($registryKeys)

        foreach ($key in $registryKeys) {
            try {
                $acl = Get-Acl -Path $key
                $defaultPermissions = @(
                    "SYSTEM:FullControl",
                    "Administrators:FullControl",
                    "Users:Read",
                    "ALL APPLICATION PACKAGES:Read"
                )

                $currentPermissions = $acl.Access | ForEach-Object {
                    "{0}:{1}" -f $_.IdentityReference, $_.FileSystemRights
                }

                if (-Not ($currentPermissions -contains $defaultPermissions)) {
                    foreach ($perm in $defaultPermissions) {
                        $identity, $rights = $perm -split ":"
                        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($identity, $rights, "Allow")
                        $acl.SetAccessRule($rule)
                    }
                    Set-Acl -Path $key -AclObject $acl
                    "Permissions corrected."
                } else {
                    "Permissions already compliant."
                }
            } catch {
                "Error processing permissions."
            }
        }
    } -ArgumentList $registryKeys -ErrorAction Stop

    "$remotehost, $result" | Out-File -FilePath $logFile -Append
    Write-Host "SUCCESS: $remotehost verified/corrected to this: $result." -ForegroundColor Green
} catch {
    "$remotehost, Error" | Out-File -FilePath $logFile -Append
    Write-Host "ERROR: Failed to process $remotehost. $_" -ForegroundColor Red
}
}
Write-Host "Script execution completed." -ForegroundColor Green