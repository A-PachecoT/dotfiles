-- ============================================================
-- HAMMERSPOON MAIN CONFIGURATION
-- ============================================================
-- Modular configuration following Single Responsibility Principle
-- Each module handles a specific concern

-- Enable IPC for command line control
hs.ipc.cliInstall()

-- Load modules
local audioPriority = require("audio-priority")
local micMute = require("mic-mute")
local windowManager = require("window-manager")
local screenshot = require("screenshot")
local pdfVim = require("pdf-vim")
local commsQueue = require("comms-queue")

-- ============================================================
-- MODULE INITIALIZATION
-- ============================================================

audioPriority.init()
micMute.init()
windowManager.init()
screenshot.init()
pdfVim.init()
commsQueue.init()

-- ============================================================
-- HOTKEY BINDINGS
-- ============================================================

-- Audio Priority Management
hs.hotkey.bind({"ctrl", "alt"}, "a", function()
    audioPriority.manualTrigger()
end)

hs.hotkey.bind({"cmd", "alt"}, "0", function()
    audioPriority.toggleMode()
end)

-- Microphone Mute Toggle
hs.hotkey.bind({"cmd", "shift"}, "m", function()
    micMute.toggle()
end)

-- Window Management
hs.hotkey.bind({"cmd", "alt"}, "c", function()
    windowManager.centerWindow()
end)

-- Screenshot Capture
hs.hotkey.bind({"alt", "shift"}, "A", function()
    screenshot.captureActiveWindow()
end)

-- Comms Queue
hs.hotkey.bind({"ctrl", "alt"}, "n", function()
    commsQueue.sendNext()
end)
hs.hotkey.bind({"ctrl", "alt", "shift"}, "n", function()
    commsQueue.sendAll()
end)

-- NOTE: Cmd+Shift+R is handled by AeroSpace → reload-all.sh (SketchyBar + AeroSpace + HammerSpoon)

-- ============================================================
-- GLOBAL FUNCTIONS (for external access)
-- ============================================================

-- Expose toggleAudioMode globally for SketchyBar click handler
function toggleAudioMode()
    audioPriority.toggleMode()
end

-- Expose pinAudioDevice globally for SketchyBar volume popup
function pinAudioDevice(deviceName)
    audioPriority.pinDevice(deviceName)
end

-- ============================================================
-- STARTUP MESSAGE
-- ============================================================

hs.alert.show("✓ Hammerspoon loaded", 1)
print("🚀 Hammerspoon configuration loaded successfully!")
print("📋 Hotkeys:")
print("  Ctrl+Alt+A       - Manual audio device trigger")
print("  Cmd+Alt+0        - Toggle HEADPHONE/SPEAKER mode")
print("  Cmd+Shift+M      - Toggle microphone mute")
print("  Cmd+Alt+C        - Center current window")
print("  Alt+Shift+A      - Capture screenshot")
print("  Ctrl+Alt+N       - Comms: paste next message")
print("  Ctrl+Alt+Shift+N - Comms: blast all messages")
print("  Cmd+Shift+R      - Reload all (via AeroSpace → reload-all.sh)")
print("  [Skim] j/k       - Scroll down/up")
print("  [Skim] d/u       - Half page down/up")
print("  [Skim] gg/G      - First/last page")
print("  [Skim] Ctrl+f/b  - Page down/up")
print("  [Skim] /         - Search, i=insert mode, Esc=normal")
