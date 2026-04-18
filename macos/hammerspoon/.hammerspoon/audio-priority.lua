-- Audio Device Priority Manager
-- Two Priority Modes:
-- HEADPHONE MODE: Philips TAT1215 > WH-1000XM4 > fifine > Echo Dot > MacBook Pro Speakers
-- SPEAKER MODE: Echo Dot > MacBook Pro Speakers (skips fifine/headphones)
-- Input Priority: fifine Microphone > MacBook Pro Microphone (never WH-1000XM4)

local M = {}

-- Mode state - load from persistent storage
M.speakerMode = hs.settings.get("audioMode.speakerMode") or false

-- Manual pin: when user selects a device manually, don't override it
M.manualPin = false

local function log(message)
    print("🎧 Audio Priority: " .. message)
    hs.console.printStyledtext(hs.styledtext.new("🎧 " .. message, {color = {hex = "#7aa2f7"}}))
end

local function deviceExists(deviceName, isInput)
    local devices = isInput and hs.audiodevice.allInputDevices() or hs.audiodevice.allOutputDevices()
    for _, device in pairs(devices) do
        if string.find(device:name(), deviceName, 1, true) then
            return device
        end
    end
    return nil
end

local function setOutputDevice()
    log("Setting output device...")

    local fifine = deviceExists("fifine", false)
    local philips = deviceExists("Philips TAT1215", false)
    local wh1000xm4 = deviceExists("WH-1000XM4", false)
    local echo = deviceExists("Echo Dot-1DH", false)
    local macbook = deviceExists("MacBook Pro Speakers", false)

    -- Debug output
    log("Found fifine: " .. (fifine and "YES" or "NO"))
    log("Found Philips TAT1215: " .. (philips and "YES" or "NO"))
    log("Found WH-1000XM4: " .. (wh1000xm4 and "YES" or "NO"))
    log("Found Echo Dot-1DH: " .. (echo and "YES" or "NO"))
    log("Found MacBook: " .. (macbook and "YES" or "NO"))
    log("Current mode: " .. (M.speakerMode and "SPEAKER MODE" or "HEADPHONE MODE"))

    if M.speakerMode then
        -- SPEAKER MODE: Echo Dot > MacBook Pro Speakers (skip headphones/fifine)
        if echo then
            echo:setDefaultOutputDevice()
            log("✅ Output: Echo Dot-1DH (speaker mode)")
            return
        elseif macbook then
            macbook:setDefaultOutputDevice()
            log("✅ Output: MacBook Pro Speakers (speaker mode)")
            return
        else
            log("❌ No suitable speaker device found")
        end
    else
        -- HEADPHONE MODE: Philips TAT1215 > WH-1000XM4 > fifine > Echo Dot > MacBook Pro Speakers
        if philips then
            philips:setDefaultOutputDevice()
            log("✅ Output: Philips TAT1215 (headphone mode)")
            return
        elseif wh1000xm4 then
            wh1000xm4:setDefaultOutputDevice()
            log("✅ Output: WH-1000XM4 (headphone mode)")
            return
        elseif fifine then
            fifine:setDefaultOutputDevice()
            log("✅ Output: fifine speaker (headphone mode)")
            return
        elseif echo then
            echo:setDefaultOutputDevice()
            log("✅ Output: Echo Dot-1DH (headphone mode)")
            return
        elseif macbook then
            macbook:setDefaultOutputDevice()
            log("✅ Output: MacBook Pro Speakers (headphone mode)")
            return
        else
            log("❌ No suitable output device found")
        end
    end
end

local function setInputDevice()
    log("Setting input device...")

    local fifine = deviceExists("fifine", true)
    local macbook = deviceExists("MacBook Pro Microphone", true)

    if fifine then
        fifine:setDefaultInputDevice()
        log("✅ Input: fifine Microphone")
        return
    elseif macbook then
        macbook:setDefaultInputDevice()
        log("✅ Input: MacBook Pro Microphone")
        return
    else
        log("❌ No suitable input device found")
    end
end

local function showCurrentDevices()
    local currentOutput = hs.audiodevice.defaultOutputDevice()
    local currentInput = hs.audiodevice.defaultInputDevice()

    log("")
    log("Current audio configuration:")
    log("Output: " .. (currentOutput and currentOutput:name() or "Unknown"))
    log("Input: " .. (currentInput and currentInput:name() or "Unknown"))
end

local function updateSketchyBarMode()
    local mode = M.speakerMode and "SPEAKER" or "HEADPHONE"
    hs.task.new("/opt/homebrew/bin/sketchybar", function() end,
        {"--trigger", "audio_mode_change", "AUDIO_MODE=" .. mode}):start()
end

local function handleAudioDeviceChange(event)
    log("Audio device event: " .. event)

    -- Debug: List all current devices
    local outputDevices = hs.audiodevice.allOutputDevices()
    local deviceNames = {}
    for _, device in pairs(outputDevices) do
        table.insert(deviceNames, device:name() .. " (" .. device:transportType() .. ")")
    end
    log("Available output devices: " .. table.concat(deviceNames, ", "))

    if event == "dev#" then
        -- Device connected/disconnected - clear manual pin and re-apply priority
        M.manualPin = false
        log("Manual pin cleared (device change)")
        setOutputDevice()
        setInputDevice()
        showCurrentDevices()
        updateSketchyBarMode()
    elseif event == "dOut" then
        if M.manualPin then
            log("Skipping dOut override (manual pin active)")
            updateSketchyBarMode()
            return
        end
        -- Default output changed - might need to override if wrong priority
        hs.timer.doAfter(0.5, function()
            setOutputDevice()
            updateSketchyBarMode()
        end)
    elseif event == "dIn" then
        -- Default input changed - might need to override if wrong priority
        hs.timer.doAfter(0.5, function()
            setInputDevice()
        end)
    end
end

-- Public API
function M.init()
    -- Initialize audio device watcher
    hs.audiodevice.watcher.setCallback(handleAudioDeviceChange)
    hs.audiodevice.watcher.start()

    -- Set initial devices on load
    setOutputDevice()
    setInputDevice()
    showCurrentDevices()
    updateSketchyBarMode()

    log("Audio Priority Manager started! 🎵")
end

function M.toggleMode()
    M.speakerMode = not M.speakerMode
    M.manualPin = false

    -- Persist mode across restarts
    hs.settings.set("audioMode.speakerMode", M.speakerMode)

    local modeText = M.speakerMode and "SPEAKER MODE" or "HEADPHONE MODE"
    log("🔄 Switched to " .. modeText)
    hs.notify.new({title="Audio Priority", informativeText="Switched to " .. modeText}):send()

    -- Immediately apply new priority
    setOutputDevice()
    setInputDevice()
    showCurrentDevices()
    updateSketchyBarMode()
end

function M.manualTrigger()
    log("Manual trigger activated!")
    M.manualPin = false
    setOutputDevice()
    setInputDevice()
    showCurrentDevices()
end

function M.pinDevice(deviceName)
    local device = deviceExists(deviceName, false)
    if device then
        M.manualPin = true
        device:setDefaultOutputDevice()
        log("📌 Manual pin: " .. device:name())
        updateSketchyBarMode()
    else
        log("❌ Pin failed: device not found: " .. deviceName)
    end
end

return M
