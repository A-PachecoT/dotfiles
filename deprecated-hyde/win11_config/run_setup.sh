#!/bin/bash

# Convert the WSL path to a Windows path
WIN_SCRIPT_PATH=$(wslpath -w "$HOME/dotfiles/win11_config/setup.bat")
TEMP_OUTPUT_FILE=$(wslpath -w "$HOME/dotfiles/win11_config/setup_output.txt")

# Use powershell.exe to run the batch file with elevated privileges and capture output
/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command "Start-Process cmd -ArgumentList '/c $WIN_SCRIPT_PATH > $TEMP_OUTPUT_FILE 2>&1' -Verb RunAs -Wait"

# Check if the output file exists and display its contents
if [ -f "$(wslpath -u "$TEMP_OUTPUT_FILE")" ]; then
    echo "Windows script output:"
    cat "$(wslpath -u "$TEMP_OUTPUT_FILE")"
    rm "$(wslpath -u "$TEMP_OUTPUT_FILE")"
else
    echo "No output was captured from the Windows script."
fi

# Check the exit status
if [ $? -eq 0 ]; then
    echo "Windows script executed successfully."
else
    echo "There was an error running the Windows script."
fi
