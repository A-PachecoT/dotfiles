# Audio Priority System Documentation

## Overview

The audio priority system is a sophisticated HammerSpoon-based automation that intelligently manages audio device switching on macOS. It operates in two distinct modes (HEADPHONE and SPEAKER) with device-specific priority lists, automatic device detection, and seamless SketchyBar integration for visual feedback.

## Architecture

### Component Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Audio Priority System                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐       ┌──────────────────────────────┐   │
│  │   HammerSpoon    │       │        SketchyBar            │   │
│  │  (Core Logic)    │◄─────►│     (Visual Feedback)        │   │
│  │                  │       │                              │   │
│  │ • Device Watcher │       │ • Mode Indicator (󰋋/󰓃)      │   │
│  │ • Priority Logic │       │ • Device Name on Hover       │   │
│  │ • Mode Toggle    │       │ • Click Handler              │   │
│  │ • State Persist  │       │ • Color Animations           │   │
│  └──────────────────┘       └──────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              macOS Audio System                          │   │
│  │  • Device Connect/Disconnect Events                     │   │
│  │  • Default Device Changes                               │   │
│  │  • Audio Routing                                        │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### File Structure

```
dotfiles/
├── hammerspoon/
│   └── .hammerspoon/
│       ├── init.lua                    # Main config - hotkey bindings
│       └── audio-priority.lua          # Core audio priority logic
├── sketchybar/
│   └── .config/sketchybar/
│       ├── init.lua                    # Loads audio_mode.sh
│       ├── items/
│       │   └── audio_mode.sh          # SketchyBar item definition
│       └── plugins/
│           └── audio_mode_event.sh    # Event handler & UI updates
└── scripts/
    └── audio-priority.sh              # DEPRECATED - legacy bash script
```

## Operating Modes

The system operates in two mutually exclusive modes that determine output device priority.

### HEADPHONE MODE (Default)

**Output Device Priority:**
1. **Philips TAT1215** - Wireless earbuds (highest priority)
2. **WH-1000XM4** - Sony wireless headphones
3. **fifine** - USB audio interface (speaker output)
4. **Echo Dot-1DH** - Amazon Echo speaker
5. **MacBook Pro Speakers** - Built-in speakers (fallback)

**Input Device Priority:**
1. **fifine Microphone** - USB microphone
2. **MacBook Pro Microphone** - Built-in microphone

**Use Cases:**
- Personal listening with headphones/earbuds
- Recording with external microphone
- Default mode for most work scenarios

**SketchyBar Indicator:**
- Icon: 󰋋 (headphone)
- Color: `0xffbb9af7` (purple)

### SPEAKER MODE

**Output Device Priority:**
1. **Echo Dot-1DH** - Amazon Echo speaker (highest priority)
2. **MacBook Pro Speakers** - Built-in speakers (fallback)

**Note:** This mode **skips** all headphones and the fifine speaker output.

**Input Device Priority:**
- Same as HEADPHONE MODE (fifine > MacBook Pro Microphone)

**Use Cases:**
- Room audio for shared listening
- Video calls with speaker audio
- Presentations
- Background music while moving around

**SketchyBar Indicator:**
- Icon: 󰓃 (speaker)
- Color: `0xff7aa2f7` (blue)

## Core Logic Flow

### 1. Initialization Sequence

```lua
-- On HammerSpoon startup:
1. Load persisted mode state from hs.settings
2. Start audio device watcher
3. Detect all available devices
4. Apply priority logic for both output/input
5. Update SketchyBar with current mode
6. Show startup notification
```

**File:** `hammerspoon/.hammerspoon/audio-priority.lua:152-164`

### 2. Device Change Detection

HammerSpoon uses `hs.audiodevice.watcher` to monitor three types of events:

| Event Code | Description | Action |
|------------|-------------|--------|
| `dev#` | Device connected/disconnected | Immediately re-apply priority logic |
| `dOut` | Default output device changed | Wait 0.5s, then enforce priority |
| `dIn` | Default input device changed | Wait 0.5s, then enforce priority |

**Why the 0.5s delay?**
macOS can trigger multiple rapid events during device transitions. The delay allows the system to stabilize before enforcing priorities.

**File:** `hammerspoon/.hammerspoon/audio-priority.lua:120-149`

### 3. Priority Selection Algorithm

```lua
function setOutputDevice()
    -- Step 1: Detect all available devices
    local devices = {
        fifine = deviceExists("fifine", false),
        philips = deviceExists("Philips TAT1215", false),
        wh1000xm4 = deviceExists("WH-1000XM4", false),
        echo = deviceExists("Echo Dot-1DH", false),
        macbook = deviceExists("MacBook Pro Speakers", false)
    }

    -- Step 2: Apply mode-specific priority
    if speakerMode then
        -- SPEAKER MODE: echo > macbook
        try_device(echo) OR try_device(macbook)
    else
        -- HEADPHONE MODE: philips > wh1000xm4 > fifine > echo > macbook
        try_device(philips) OR try_device(wh1000xm4) OR
        try_device(fifine) OR try_device(echo) OR try_device(macbook)
    end

    -- Step 3: Update SketchyBar
    triggerSketchyBarUpdate()
end
```

**Device Detection:**
- Uses fuzzy string matching (`string.find()`) to handle variations in device names
- Searches through `hs.audiodevice.allOutputDevices()` or `hs.audiodevice.allInputDevices()`
- Returns device object or `nil` if not found

**File:** `hammerspoon/.hammerspoon/audio-priority.lua:27-83`

### 4. Input Device Logic

Input device selection is **mode-independent** and always follows the same priority:

```lua
function setInputDevice()
    fifine = deviceExists("fifine", true)
    macbook = deviceExists("MacBook Pro Microphone", true)

    -- Priority: fifine > macbook
    try_input(fifine) OR try_input(macbook)
end
```

**Critical Rule:** The WH-1000XM4 microphone is **NEVER** selected, even when the headphones are connected. This is intentional because:
- The WH-1000XM4 microphone has poor quality over Bluetooth
- The fifine USB microphone provides superior audio quality
- Automatic switching to WH-1000XM4 mic would degrade call/recording quality

**File:** `hammerspoon/.hammerspoon/audio-priority.lua:85-102`

## Mode Switching

### Toggle Mechanism

```lua
function toggleMode()
    -- 1. Flip the boolean state
    speakerMode = not speakerMode

    -- 2. Persist to disk (survives restarts)
    hs.settings.set("audioMode.speakerMode", speakerMode)

    -- 3. Show notification
    hs.notify.new({
        title = "Audio Priority",
        informativeText = speakerMode ? "SPEAKER MODE" : "HEADPHONE MODE"
    }):send()

    -- 4. Immediately re-apply priority logic
    setOutputDevice()
    setInputDevice()

    -- 5. Update SketchyBar UI
    updateSketchyBarMode()  -- Sends trigger with AUDIO_MODE env var
end
```

**File:** `hammerspoon/.hammerspoon/audio-priority.lua:166-181`

### Persistence

The mode state is stored in HammerSpoon's persistent settings:

```lua
-- On startup - load from disk
M.speakerMode = hs.settings.get("audioMode.speakerMode") or false

-- On toggle - save to disk
hs.settings.set("audioMode.speakerMode", M.speakerMode)
```

**Storage Location:** `~/Library/Preferences/org.hammerspoon.Hammerspoon.plist`

**Benefits:**
- Mode persists across HammerSpoon reloads
- Mode persists across system restarts
- No external configuration files needed

## SketchyBar Integration

### Visual Indicator

The SketchyBar item provides real-time visual feedback about the audio system state.

#### Static Display (Always Visible)

```bash
┌──────┐
│  󰋋   │  # Headphone mode - purple icon
└──────┘

┌──────┐
│  󰓃   │  # Speaker mode - blue icon
└──────┘
```

#### Hover State (Mouse Over)

```bash
┌─────────────────────────┐
│  󰋋  Philips Earbuds    │  # Animated expansion
└─────────────────────────┘

┌─────────────────────────┐
│  󰓃  Echo Dot           │  # Shows current device
└─────────────────────────┘
```

### Device Name Mapping

For cleaner display, device names are shortened:

| Actual Device Name | Display Name |
|-------------------|--------------|
| MacBook Pro Speakers | Built-in Speakers |
| fifine Microphone | Fifine Speaker |
| Philips TAT1215 | Philips Earbuds |
| WH-1000XM4 | Sony WH-1000XM4 |
| Echo Dot-1DH | Echo Dot |

**File:** `sketchybar/.config/sketchybar/plugins/audio_mode_event.sh:24-35`

### Event Communication

HammerSpoon → SketchyBar communication happens via custom events:

```bash
# HammerSpoon triggers event with environment variable
sketchybar --trigger audio_mode_change AUDIO_MODE=SPEAKER

# SketchyBar plugin receives event and updates UI
if [[ "$AUDIO_MODE" == "SPEAKER" ]]; then
    icon="󰓃"
    color=0xff7aa2f7  # blue
else
    icon="󰋋"
    color=0xffbb9af7  # purple
fi
```

**File:** `hammerspoon/.hammerspoon/audio-priority.lua:114-118`
**File:** `sketchybar/.config/sketchybar/plugins/audio_mode_event.sh:38-50`

### Click Handler

Clicking the SketchyBar indicator toggles between modes:

```bash
# Defined in item configuration
click_script="hs -c 'toggleAudioMode()'"

# Calls global function exposed in HammerSpoon init.lua
function toggleAudioMode()
    audioPriority.toggleMode()
end
```

**File:** `sketchybar/.config/sketchybar/items/audio_mode.sh:19`
**File:** `hammerspoon/.hammerspoon/init.lua:64-66`

### Animations

The UI uses smooth animations for state changes:

```bash
# Icon/color change animation (circular easing)
--animate circ 12

# Label expansion animation (hyperbolic tangent easing)
--animate tanh 20
```

**Benefits:**
- Professional, polished feel
- Clear visual feedback during transitions
- Non-jarring user experience

## User Interactions

### Hotkeys

| Hotkey | Action | Description |
|--------|--------|-------------|
| `Ctrl+Alt+A` | Manual trigger | Force re-apply priority logic immediately |
| `Cmd+Alt+0` | Toggle mode | Switch between HEADPHONE and SPEAKER modes |

**File:** `hammerspoon/.hammerspoon/init.lua:30-36`

### SketchyBar Click

- **Left click** on the audio mode indicator → Toggle between modes

### Automatic Switching

The system automatically responds to:
- USB device connection (fifine microphone/speaker)
- Bluetooth device connection (WH-1000XM4, Philips TAT1215)
- Bluetooth device disconnection
- Manual system audio changes (partially - will re-enforce priority after 0.5s)

## Common Scenarios

### Scenario 1: Connect WH-1000XM4 Headphones

```
Initial State: Using MacBook Pro Speakers (HEADPHONE MODE)

1. User powers on WH-1000XM4
2. Bluetooth connects
3. macOS triggers "dev#" event
4. HammerSpoon detects WH-1000XM4 available
5. Applies priority: WH-1000XM4 > MacBook (WH-1000XM4 wins)
6. Switches output to WH-1000XM4
7. Input stays on MacBook Pro Microphone (fifine not connected)
8. SketchyBar updates: "󰋋 Sony WH-1000XM4"
```

### Scenario 2: Toggle to SPEAKER MODE

```
Current State: Using WH-1000XM4 (HEADPHONE MODE)
Echo Dot is available

1. User clicks SketchyBar indicator (or presses Cmd+Alt+0)
2. HammerSpoon toggles speakerMode = true
3. Persists state to disk
4. Applies SPEAKER MODE priority: Echo Dot > MacBook
5. Switches output to Echo Dot (WH-1000XM4 skipped!)
6. Input unchanged (fifine > MacBook priority)
7. SketchyBar updates: "󰓃 Echo Dot"
8. Notification: "Switched to SPEAKER MODE"
```

### Scenario 3: Connect fifine During SPEAKER MODE

```
Current State: SPEAKER MODE, using Echo Dot

1. User plugs in fifine USB device
2. macOS detects new audio device
3. HammerSpoon receives "dev#" event
4. Applies SPEAKER MODE priority: Echo Dot > MacBook
5. Output stays on Echo Dot (fifine skipped in speaker mode)
6. Applies INPUT priority: fifine > MacBook
7. Switches input to fifine Microphone
8. SketchyBar: "󰓃 Echo Dot" (output unchanged)
```

### Scenario 4: System Preference Manual Change

```
Current State: HEADPHONE MODE, using Philips TAT1215
User manually changes output in System Settings to MacBook Pro Speakers

1. macOS changes default output device
2. HammerSpoon receives "dOut" event
3. Waits 0.5 seconds (debounce)
4. Checks priority: Philips TAT1215 still available
5. Overrides user change, switches back to Philips TAT1215
6. SketchyBar: "󰋋 Philips Earbuds"

Note: The system enforces priority and will override manual changes!
```

## Debugging

### HammerSpoon Console

View real-time logs with colored output:

```bash
# Show console
hs -c "hs.console.show()"

# Example log output:
🎧 Audio Priority: Setting output device...
🎧 Audio Priority: Found fifine: NO
🎧 Audio Priority: Found Philips TAT1215: YES
🎧 Audio Priority: Found WH-1000XM4: NO
🎧 Audio Priority: Found Echo Dot-1DH: YES
🎧 Audio Priority: Found MacBook: YES
🎧 Audio Priority: Current mode: HEADPHONE MODE
🎧 Audio Priority: ✅ Output: Philips TAT1215 (headphone mode)
```

### Check Current Devices

```bash
# List all output devices
hs -c "for _, d in pairs(hs.audiodevice.allOutputDevices()) do print(d:name()) end"

# List all input devices
hs -c "for _, d in pairs(hs.audiodevice.allInputDevices()) do print(d:name()) end"

# Check current defaults
hs -c "print(hs.audiodevice.defaultOutputDevice():name())"
hs -c "print(hs.audiodevice.defaultInputDevice():name())"
```

### Check Persisted Mode

```bash
# Get current mode setting
hs -c "print(hs.settings.get('audioMode.speakerMode'))"

# Manually set mode
hs -c "hs.settings.set('audioMode.speakerMode', false)"  # HEADPHONE
hs -c "hs.settings.set('audioMode.speakerMode', true)"   # SPEAKER
```

### Force Reload

```bash
# Reload HammerSpoon configuration
hs -c "hs.reload()"

# Reload SketchyBar
sketchybar --reload

# Manually trigger priority check
hs -c "audioPriority.manualTrigger()"
```

## Troubleshooting

### Problem: Device not switching automatically

**Diagnosis:**
```bash
# Check if watcher is running
hs -c "print(hs.audiodevice.watcher.isRunning())"
# Should return: true

# Check available devices
hs -c "for _, d in pairs(hs.audiodevice.allOutputDevices()) do print(d:name()) end"
```

**Solution:**
1. Verify device is actually connected (check Bluetooth/USB)
2. Check device name matches the search string in `deviceExists()`
3. Reload HammerSpoon: `hs -c "hs.reload()"`

### Problem: Wrong device selected

**Diagnosis:**
Check the priority order and current mode.

```bash
# Check current mode
hs -c "print(hs.settings.get('audioMode.speakerMode') and 'SPEAKER' or 'HEADPHONE')"

# Manually trigger with logging
hs -c "audioPriority.manualTrigger()"
# Check console for device detection logs
```

**Solution:**
1. Ensure you're in the correct mode (HEADPHONE vs SPEAKER)
2. Verify priority order matches your expectations
3. Check device names match exactly (case-sensitive partial matching)

### Problem: SketchyBar not updating

**Diagnosis:**
```bash
# Check if audio_mode item exists
sketchybar --query audio_mode

# Manually trigger event
sketchybar --trigger audio_mode_change AUDIO_MODE=HEADPHONE
```

**Solution:**
1. Reload SketchyBar: `sketchybar --reload`
2. Check plugin script is executable:
   ```bash
   chmod +x ~/.config/sketchybar/plugins/audio_mode_event.sh
   ```
3. Verify HammerSpoon can call sketchybar:
   ```bash
   hs -c "hs.execute('/opt/homebrew/bin/sketchybar --query bar')"
   ```

### Problem: Mode not persisting across restarts

**Diagnosis:**
```bash
# Check if setting is saved
hs -c "print(hs.settings.get('audioMode.speakerMode'))"
```

**Solution:**
1. Ensure HammerSpoon has proper permissions (System Settings > Privacy & Security)
2. Check plist file exists and is writable:
   ```bash
   ls -la ~/Library/Preferences/org.hammerspoon.Hammerspoon.plist
   ```
3. Manually test persistence:
   ```bash
   hs -c "hs.settings.set('audioMode.speakerMode', true)"
   hs -c "hs.reload()"
   hs -c "print(hs.settings.get('audioMode.speakerMode'))"  # Should return: true
   ```

### Problem: Click handler not working

**Diagnosis:**
```bash
# Test global function directly
hs -c "toggleAudioMode()"
```

**Solution:**
1. Ensure global function is defined in `init.lua`
2. Verify IPC is enabled: `hs.ipc.cliInstall()` in init.lua
3. Check SketchyBar click_script syntax:
   ```bash
   sketchybar --query audio_mode | grep click_script
   ```

## Legacy Components

### audio-priority.sh (DEPRECATED)

**File:** `scripts/audio-priority.sh`

**Status:** Deprecated in favor of HammerSpoon implementation

**Why deprecated:**
- Required external tool `SwitchAudioSource`
- No automatic device detection (manual execution only)
- No mode switching capability
- No SketchyBar integration
- Less reliable device matching

**Kept for:** Backup/reference purposes

**Old priority (for reference):**
- Output: WH-1000XM4 > fifine > MacBook Pro Speakers
- Input: fifine > MacBook Pro Microphone

## Design Philosophy

### Why Two Modes?

The dual-mode system addresses a common frustration: audio devices have different use cases.

**Problem:** When using speakers for room audio, you don't want the system to automatically switch to headphones just because they're paired. Conversely, when working with headphones, you want them to take priority.

**Solution:** Explicit mode switching gives the user control over the intended audio context.

### Why Persistent State?

Mode preference reflects the user's current working context, which often spans multiple days:
- Working from home office → HEADPHONE MODE for days
- Hosting a gathering → SPEAKER MODE for the event
- Recording content → HEADPHONE MODE for weeks

Requiring mode re-selection after every restart would be frustrating.

### Why Override Manual Changes?

The system enforces priority to prevent "audio device chaos":
- macOS can automatically switch devices unexpectedly
- Applications can change default devices
- Temporary device disconnections can cause fallback to wrong device

By enforcing priority, the system ensures predictable, consistent behavior.

### Why Exclude WH-1000XM4 Microphone?

The WH-1000XM4 microphone quality over Bluetooth is significantly worse than:
- USB microphones (fifine)
- Even built-in MacBook microphone

Allowing automatic selection would degrade call/recording quality. The explicit exclusion ensures quality is maintained.

## Performance Considerations

### Event Debouncing

The 0.5s delay on `dOut` and `dIn` events prevents:
- Rapid device switching loops
- Conflict with system audio transitions
- Multiple unnecessary priority checks

### Lazy Evaluation

Priority checking stops at the first successful device:
```lua
if philips then
    philips:setDefaultOutputDevice()
    return  -- Don't check remaining devices
end
```

This minimizes CPU usage and device queries.

### SketchyBar Animation Budget

Animations use low frame counts to reduce CPU load:
- Icon change: 12 frames (circular easing)
- Label expansion: 20 frames (tanh easing)

Smooth enough to feel polished, fast enough to not impact performance.

## Future Enhancements

### Potential Improvements

1. **Per-Application Audio Routing**
   - Route Zoom/Slack to headphones even in SPEAKER MODE
   - Route music apps to speakers even in HEADPHONE MODE

2. **Time-Based Mode Switching**
   - Auto-switch to SPEAKER MODE outside work hours
   - Auto-switch to HEADPHONE MODE during meeting times

3. **Location-Based Modes**
   - Detect WiFi network to infer location
   - Home network → SPEAKER MODE
   - Office network → HEADPHONE MODE

4. **Device-Specific Profiles**
   - Save device combinations as named profiles
   - "Recording" profile: fifine input + WH-1000XM4 output
   - "Presentation" profile: Echo output + MacBook input

5. **UI Enhancements**
   - SketchyBar submenu showing all available devices
   - Quick device override without changing mode
   - Battery level indicators for Bluetooth devices

### Implementation Notes

Most enhancements would require:
- Additional HammerSpoon modules (wifi location detection)
- More complex state management (profiles, schedules)
- Extended SketchyBar UI (submenus, device lists)

Current implementation prioritizes simplicity and reliability over features.

## Related Documentation

- [HammerSpoon API Reference](http://www.hammerspoon.org/docs/)
- [SketchyBar Documentation](https://felixkratz.github.io/SketchyBar/)
- [macOS Audio Device Management](https://developer.apple.com/documentation/coreaudio)

## Changelog

### 2025-10-21
- Added Philips TAT1215 as highest priority output device in HEADPHONE MODE
- Updated device priority documentation
- Enhanced SketchyBar display name mappings

### 2024-XX-XX
- Initial implementation with HEADPHONE/SPEAKER mode system
- HammerSpoon audio device watcher
- SketchyBar integration with click handler
- Persistent mode state across restarts
- Deprecated legacy bash script
