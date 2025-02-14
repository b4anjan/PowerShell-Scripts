


# Set the target time for the countdown
$targetTime = Get-Date ":59"

# Loop until the target time is reached
while ($targetTime -gt (Get-Date)) {
    # Calculate the time remaining
    $timeRemaining = New-TimeSpan -Start (Get-Date) -End $targetTime

    # Format the time remaining
    $formattedTime = $timeRemaining.ToString(":ss")

    # Clear the console and display the countdown
    Clear-Host
    Write-Host "Time remaining: $formattedTime"

    # Wait for one second
    Start-Sleep -Seconds 1
}

# Display a message when the countdown is complete
Write-Host "Countdown complete!"