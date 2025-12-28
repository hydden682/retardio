# Claude Code Auto-Continue Script
# This script sends "please continue" to the active window (VS Code with Claude Code)
#
# Usage:
#   1. Run this script when you hit the context limit
#   2. Or use Task Scheduler to run it on a timer
#
# Config - Edit these values:
$MESSAGE = "please continue"
$DELAY_BEFORE_SEND = 2  # seconds to wait before sending (gives you time to focus VS Code)

# Function to send keystrokes to active window
function Send-Continue {
    Write-Host "Claude Code Auto-Continue" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Sending '$MESSAGE' in $DELAY_BEFORE_SEND seconds..."
    Write-Host "Make sure VS Code with Claude Code is focused!"
    Write-Host ""

    Start-Sleep -Seconds $DELAY_BEFORE_SEND

    # Use Windows Forms to send keystrokes
    Add-Type -AssemblyName System.Windows.Forms

    # Send the message
    [System.Windows.Forms.SendKeys]::SendWait($MESSAGE)

    # Press Enter to submit
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")

    Write-Host "Sent!" -ForegroundColor Green
}

# Function to schedule automatic continues
function Schedule-AutoContinue {
    param(
        [int]$IntervalMinutes = 60,  # How often to run (adjust based on your usage)
        [string]$ResetTime = "00:00"  # When your limit resets (24h format)
    )

    $taskName = "ClaudeCodeAutoContinue"

    # Create the scheduled task
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$PSCommandPath`" -AutoRun"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes($IntervalMinutes) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)

    # Register task (requires admin)
    try {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Force
        Write-Host "Scheduled task created: runs every $IntervalMinutes minutes" -ForegroundColor Green
        Write-Host "To remove: Unregister-ScheduledTask -TaskName '$taskName' -Confirm:`$false"
    }
    catch {
        Write-Host "Failed to create scheduled task (may need admin rights)" -ForegroundColor Red
        Write-Host "You can run this script manually when needed."
    }
}

# Main execution
param(
    [switch]$AutoRun,      # Run without prompts (for scheduled tasks)
    [switch]$Schedule,     # Create scheduled task
    [int]$Interval = 60    # Interval in minutes for scheduled task
)

if ($Schedule) {
    Schedule-AutoContinue -IntervalMinutes $Interval
}
elseif ($AutoRun) {
    # Minimal delay for automated runs
    $DELAY_BEFORE_SEND = 1
    Send-Continue
}
else {
    # Interactive mode
    Write-Host @"
Claude Code Auto-Continue
=========================

Options:
  1. Send 'please continue' now
  2. Create scheduled task (runs automatically)
  3. Exit

"@ -ForegroundColor Cyan

    $choice = Read-Host "Choose option (1-3)"

    switch ($choice) {
        "1" { Send-Continue }
        "2" {
            $mins = Read-Host "Run every how many minutes? (default: 60)"
            if ([string]::IsNullOrEmpty($mins)) { $mins = 60 }
            Schedule-AutoContinue -IntervalMinutes ([int]$mins)
        }
        "3" { exit }
        default { Send-Continue }
    }
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
