
$timeoutSeconds = 75

Write-Host "Waiting for: $timeoutSeconds seconds"

while ($timeoutSeconds -gt 0) {
    $timeoutSeconds--
    Clear-Host
    Write-Host "Waiting for: $timeoutSeconds seconds"
    Start-Sleep -Seconds 1
}

Write-Host "Done waiting!"