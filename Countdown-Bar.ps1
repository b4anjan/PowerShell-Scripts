$timeoutSeconds = 75
$barLength = 50

Write-Host "`rWaiting: " -NoNewline

while ($timeoutSeconds -gt 0) {
    $filledLength = [math]::Round($barLength * (1 - $timeoutSeconds / 75))
    $bar = "." * $filledLength + " " * ($barLength - $filledLength)
    Clear-Host
    Write-Host "[$bar]"
    Start-Sleep -Seconds 1
    $timeoutSeconds--
}

Write-Host "`nDone waiting!"