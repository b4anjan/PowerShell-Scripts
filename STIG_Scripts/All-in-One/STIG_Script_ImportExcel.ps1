
# Define paths
$remoteHostsFile = "C:\SDPU\Test\Test-Remote-Host.txt"
$excelFile = "C:\SDPU\Test\STIG-Rules.xlsx"
$logFile = "C:\SDPU\Test\log file\STIG_Application_Log.txt"

Clear-Host

# Function to log messages
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    try {
        "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    } catch {
        Write-Host "Error writing to log file: $_"
    }
}

# Read the remote hosts file
if (-Not (Test-Path $remoteHostsFile)) {
    Write-Host "ERROR: Hosts file not found at $remoteHostsFile."
    exit
}
$remotehosts = Get-Content -Path $remoteHostsFile

# Import ImportExcel module
Import-Module ImportExcel

# Read the STIG rules from Excel
if (-Not (Test-Path $excelFile)) {
    Write-Host "ERROR: STIG rules file not found at $excelFile."
    exit
}

try {
    $stigRules = Import-Excel -Path $excelFile -WorksheetName "YourSheetName" | 
        Select-Object @{
            Name = 'RuleNumber'
            Expression = { $_.RuleNumber }
        }, @{
            Name = 'RuleDescription'
            Expression = { $_.RuleDescription }
        }, @{
            Name = 'RegistryPath'
            Expression = { $_.RegistryPath }
        }, @{
            Name = 'RegistryKey'
            Expression = { $_.RegistryKey }
        }, @{
            Name = 'DesiredValue'
            Expression = { $_.DesiredValue }
        }
} catch {
    Write-Host "ERROR: Failed to read Excel file: $_"
    exit
}

# Registry hive mapping
$hiveMap = @{
    "HKEY_LOCAL_MACHINE" = "HKLM"
    "HKEY_CURRENT_USER" = "HKCU"
    "HKEY_CLASSES_ROOT" = "HKCR"
    "HKEY_USERS" = "HKU"
    "HKEY_CURRENT_CONFIG" = "HKCC"
}

foreach ($remotehost in $remotehosts) {
    Write-Host "Processing remote host: $remotehost"
    
    # Check if the host is online
    if (-Not (Test-Connection -ComputerName $remotehost -Count 1 -Quiet)) {
        Write-Host "$remotehost - Offline" -ForegroundColor Red
        Write-Log "$remotehost - Offline"
        continue
    }

    foreach ($rule in $stigRules) {
        $ruleNumber = $rule.RuleNumber
        $ruleDescription = $rule.RuleDescription
        $registryPath = $rule.RegistryPath
        $policyName = $rule.RegistryKey
        $policyValue = $rule.DesiredValue

        # Normalize registry path
        foreach ($fullHive in $hiveMap.Keys) {
            if ($registryPath -match "^$fullHive\\") {
                $registryPath = $registryPath -replace "^$fullHive\\", "$($hiveMap[$fullHive])\\"
                break
            }
        }

        # Check if registry path is valid ===== This block is optional, it is good to have but RuleDescription column also requires Registry Path in Excel file 
        if (-Not (Test-Path $registryPath)) {
            # Try extracting recommended path from description
            if ($ruleDescription -match "HKLM:\\\\[^ ]+") {
                $recommendedPath = $matches[0]
                Write-Host "$remotehost - $ruleNumber - Invalid registry path. Using recommended path: $recommendedPath" -ForegroundColor Yellow
                Write-Log "$remotehost - $ruleNumber - Invalid registry path. Using recommended path: $recommendedPath"
                $registryPath = $recommendedPath
            } else {
                Write-Host "$remotehost - $ruleNumber - Invalid registry path and no recommendation found." -ForegroundColor Red
                Write-Log "$remotehost - $ruleNumber - Invalid registry path and no recommendation found."
                continue
            }
        }

        try {
            $result = Invoke-Command -ComputerName $remotehost -ScriptBlock {
                param ($registryPath, $policyName, $policyValue, $ruleNumber)

                # Check if the registry path exists
                if (-Not (Test-Path $registryPath)) {
                    New-Item -Path $registryPath -Force | Out-Null
                    $pathCreated = $true
                } else {
                    $pathCreated = $false
                }

                # Get the current value of the registry key
                $currentValue = (Get-ItemProperty -Path $registryPath -Name $policyName -ErrorAction SilentlyContinue).$policyName

                if ($currentValue -eq $policyValue) {
                    return "$ruleNumber - Desired Value Exists"
                }

                # Apply the new registry setting
                Set-ItemProperty -Path $registryPath -Name $policyName -Value $policyValue -Type String
                if ($pathCreated) {
                    return "$ruleNumber - RegistryPath created and desired value applied."
                } else {
                    return "$ruleNumber - Applied"
                }
            } -ArgumentList $registryPath, $policyName, $policyValue, $ruleNumber -ErrorAction Stop

            Write-Host "$remotehost - $result" -ForegroundColor Green
            Write-Log "$remotehost - $result"
        } catch {
            Write-Host "$remotehost - $ruleNumber - Not Applied or Error." -ForegroundColor Red
            Write-Log "$remotehost - $ruleNumber - Not Applied or Error. $_"
        }
    }
}

Write-Log "Script execution completed."
Write-Host "Script execution completed."