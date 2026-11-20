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
local zenKeys = require("zen-keys") -- Zen como ventana de herdr: ⌘hjkl, ⌘d split
local sleepWake = require("sleep-wake")
local keyremap = require("keyremap") -- Caps↔Esc + ⌘↔⌥ del 2.4G vía hidutil (reemplaza Karabiner)
local myturn = require("myturn") -- ⌥T marcar prioridad · ⌥G ir al que te espera (docs/myturn.md)

-- ⌘0 dentro de la Herdr app = ⌥G (era «agente 1 = el más urgente» en el TUI). Solo con la app al frente: en el
-- resto ⌘0 sigue siendo «tamaño real». Un mod propio no: los de la app van sellados por el paquete del toolkit.
HerdrJump = hs.hotkey.new({ "cmd" }, "0", myturn.jump)
HerdrJumpWatcher = hs.application.watcher.new(function(name, event)
    if name ~= "Herdr" then return end
    if event == hs.application.watcher.activated then HerdrJump:enable()
    elseif event == hs.application.watcher.deactivated then HerdrJump:disable() end
end)
HerdrJumpWatcher:start()
if (hs.application.frontmostApplication():name() or "") == "Herdr" then HerdrJump:enable() end

-- ============================================================
-- MODULE INITIALIZATION
-- ============================================================

audioPriority.init()
micMute.init()
windowManager.init()
screenshot.init()
pdfVim.init()
zenKeys.init()
sleepWake.init()

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

-- NOTE: Cmd+Ctrl+Shift+R is handled by AeroSpace → hard-reset-all.sh (hard-restart SketchyBar + HammerSpoon)

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
print("  Cmd+Ctrl+Shift+R - Hard reset SketchyBar + HammerSpoon (hard-reset-all.sh)")
print("  [Skim] j/k       - Scroll down/up")
print("  [Skim] d/u       - Half page down/up")
print("  [Skim] gg/G      - First/last page")
print("  [Skim] Ctrl+f/b  - Page down/up")
print("  [Skim] /         - Search, i=insert mode, Esc=normal")
require("live-coach")
