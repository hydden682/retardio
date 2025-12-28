@echo off
:: Simple "please continue" sender for Claude Code
:: Just double-click this file, then click on VS Code within 3 seconds

echo.
echo Claude Code Auto-Continue
echo ==========================
echo.
echo Click on VS Code NOW - sending in 3 seconds...
echo.
timeout /t 3 /nobreak > nul

:: Use PowerShell to send keystrokes
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.SendKeys]::SendWait('please continue'); [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')"

echo.
echo Sent "please continue" + Enter
echo.
pause
