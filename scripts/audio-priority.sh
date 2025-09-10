#!/bin/bash

# Audio Priority Switcher
# Output: WH-1000XM4 > fifine > MacBook
# Input: fifine > MacBook (never WH-1000XM4)

echo "🎧 Checking audio devices..."

# Function to check if device exists
device_exists() {
    SwitchAudioSource -a -t "$1" 2>/dev/null | grep -q "$2"
}

# OUTPUT PRIORITY
echo "Setting output device..."
if device_exists "output" "WH-1000XM4"; then
    SwitchAudioSource -t output -s "WH-1000XM4"
    echo "✅ Output: WH-1000XM4"
elif device_exists "output" "fifine Microphone"; then
    # Note: fifine Microphone appears as an output device (speaker functionality)
    SwitchAudioSource -t output -s "fifine Microphone"
    echo "✅ Output: fifine speaker"
else
    SwitchAudioSource -t output -s "MacBook Pro Speakers"
    echo "✅ Output: MacBook Pro Speakers"
fi

# INPUT PRIORITY
echo "Setting input device..."
if device_exists "input" "fifine Microphone"; then
    SwitchAudioSource -t input -s "fifine Microphone"
    echo "✅ Input: fifine Microphone"
else
    SwitchAudioSource -t input -s "MacBook Pro Microphone"
    echo "✅ Input: MacBook Pro Microphone"
fi

# Show current settings
echo ""
echo "Current audio configuration:"
echo "Output: $(SwitchAudioSource -c -t output)"
echo "Input: $(SwitchAudioSource -c -t input)"