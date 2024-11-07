#!/bin/bash

# Create necessary directories first
mkdir -p "/mnt/c/Users/$USER/Documents/WindowsScripts"
mkdir -p "/mnt/c/Users/$USER/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"

# Create script to configure Windows taskbar auto-hide
cat << 'EOL' > "/mnt/c/Users/$USER/Documents/WindowsScripts/TaskbarAutoHide.ps1"
$p = Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name Settings
$p.Settings[8] = $p.Settings[8] -bor 1
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name Settings -Value $p.Settings
Stop-Process -Name explorer -Force
EOL

# Create batch file in Windows Startup folder
cat << 'EOL' > "/mnt/c/Users/$USER/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/RunTaskbarHide.bat"
powershell -windowstyle hidden -Command "Start-Process powershell -ArgumentList '-windowstyle hidden -ExecutionPolicy Bypass -File "%USERPROFILE%\Documents\WindowsScripts\TaskbarAutoHide.ps1"' -Verb RunAs"
EOL

# Set proper permissions
chmod +x "/mnt/c/Users/$USER/Documents/WindowsScripts/TaskbarAutoHide.ps1"
chmod +x "/mnt/c/Users/$USER/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/RunTaskbarHide.bat"

echo "Windows taskbar auto-hide configuration has been set up:"
echo "1. PowerShell script created at: /mnt/c/Users/$USER/Documents/WindowsScripts/TaskbarAutoHide.ps1"
echo "2. Batch file created at: /mnt/c/Users/$USER/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/RunTaskbarHide.bat"
