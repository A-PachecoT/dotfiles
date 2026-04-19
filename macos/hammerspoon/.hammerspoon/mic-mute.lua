-- Microphone Mute Manager
-- Handles microphone mute/unmute with visual feedback

local M = {}

M.muted = false

local function log(message)
    print("🎤 Mic Mute: " .. message)
    hs.console.printStyledtext(hs.styledtext.new("🎤 " .. message, {color = {hex = "#f7768e"}}))
end

local function updateSketchyBar()
    hs.task.new("/opt/homebrew/bin/sketchybar", function() end, {"--trigger", "mic_toggle"}):start()
end

-- Public API
function M.toggle()
    local currentInput = hs.audiodevice.defaultInputDevice()

    if not currentInput then
        log("❌ No input device found")
        hs.alert.show("❌ No microphone found", 1)
        return
    end

    M.muted = not M.muted
    currentInput:setInputMuted(M.muted)

    -- Play sound feedback
    if M.muted then
        -- Muted - play Pop sound
        hs.task.new("/usr/bin/afplay", nil, {"/System/Library/Sounds/Pop.aiff"}):start()
    else
        -- Unmuted - play Tink sound
        hs.task.new("/usr/bin/afplay", nil, {"/System/Library/Sounds/Tink.aiff"}):start()
    end

    local statusText = M.muted and "🔇 Microphone MUTED" or "🎤 Microphone UNMUTED"
    log(statusText)

    updateSketchyBar()
end

function M.getMuteState()
    return M.muted
end

function M.init()
    log("Microphone Mute Manager initialized")
end

return M
