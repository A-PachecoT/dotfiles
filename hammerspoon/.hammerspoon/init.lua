-- HammerSpoon Audio Device Priority Manager
-- Two Priority Modes:
-- HEADPHONE MODE: WH-1000XM4 > fifine > Echo Dot > MacBook Pro Speakers
-- SPEAKER MODE: MacBook Pro Speakers only (skips fifine/headphones/Echo Dot)
-- Input Priority: fifine Microphone > MacBook Pro Microphone (never WH-1000XM4)

-- Enable IPC for command line control
hs.ipc.cliInstall()

-- Mode state
local speakerMode = false

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

local function isBluetoothDeviceConnected(deviceName)
    local handle = io.popen("system_profiler SPBluetoothDataType")
    local result = handle:read("*a")
    handle:close()

    -- Debug: log the bluetooth output
    log("Bluetooth scan result contains: " .. (result:find(deviceName) and "FOUND " .. deviceName or "NOT FOUND " .. deviceName))
    log("Connected section found: " .. (result:find("Connected:") and "YES" or "NO"))
    log("Not Connected section found: " .. (result:find("Not Connected:") and "YES" or "NO"))

    -- Simple check: is device name found AND "Connected:" section exists AND device is not in "Not Connected" section
    local deviceFound = result:find(deviceName)
    local hasConnectedSection = result:find("Connected:")
    local inNotConnectedSection = result:find("Not Connected:[^}]*" .. deviceName)

    log("Device found in bluetooth: " .. (deviceFound and "YES" or "NO"))
    log("In Not Connected section: " .. (inNotConnectedSection and "YES" or "NO"))

    return deviceFound and hasConnectedSection and not inNotConnectedSection
end

local function setOutputDevice()
    log("Setting output device...")

    local wh1000xm4 = deviceExists("WH-1000XM4", false)
    local fifine = deviceExists("fifine", false)
    local echo = deviceExists("Echo Dot-1DH", false)
    local macbook = deviceExists("MacBook Pro Speakers", false)

    -- Debug output
    log("Found WH-1000XM4: " .. (wh1000xm4 and "YES" or "NO"))
    log("Found fifine: " .. (fifine and "YES" or "NO"))
    log("Found Echo Dot-1DH: " .. (echo and "YES" or "NO"))
    log("Found MacBook: " .. (macbook and "YES" or "NO"))

    -- Check if WH-1000XM4 is actually connected via Bluetooth
    local wh1000xm4Connected = wh1000xm4 and isBluetoothDeviceConnected("WH-1000XM4")
    log("WH-1000XM4 Bluetooth connected: " .. (wh1000xm4Connected and "YES" or "NO"))

    log("Current mode: " .. (speakerMode and "SPEAKER MODE" or "HEADPHONE MODE"))

    if speakerMode then
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
        -- HEADPHONE MODE: WH-1000XM4 > fifine > Echo Dot > MacBook Pro Speakers
        if wh1000xm4 then
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
        -- Device connected/disconnected - check and set priority devices
        setOutputDevice()
        setInputDevice()
        showCurrentDevices()
        -- Update SketchyBar audio mode indicator
        hs.task.new("/opt/homebrew/bin/sketchybar", function() end, {"--trigger", "audio_mode_change"}):start()
    elseif event == "dOut" then
        -- Default output changed - might need to override if wrong priority
        hs.timer.doAfter(0.5, function()
            setOutputDevice()
            -- Update SketchyBar audio mode indicator
            hs.task.new("/opt/homebrew/bin/sketchybar", function() end, {"--trigger", "audio_mode_change"}):start()
        end)
    elseif event == "dIn" then
        -- Default input changed - might need to override if wrong priority
        hs.timer.doAfter(0.5, function()
            setInputDevice()
        end)
    end
end

-- Initialize audio device watcher
hs.audiodevice.watcher.setCallback(handleAudioDeviceChange)
hs.audiodevice.watcher.start()

-- Function to toggle between modes
local function toggleAudioMode()
    speakerMode = not speakerMode
    local modeText = speakerMode and "SPEAKER MODE" or "HEADPHONE MODE"
    log("🔄 Switched to " .. modeText)
    hs.notify.new({title="Audio Priority", informativeText="Switched to " .. modeText}):send()

    -- Immediately apply new priority
    setOutputDevice()
    setInputDevice()
    showCurrentDevices()

    -- Update SketchyBar audio mode indicator
    hs.task.new("/opt/homebrew/bin/sketchybar", function() end, {"--trigger", "audio_mode_change"}):start()
end

-- Add manual hotkey for testing (Ctrl+Alt+A)
hs.hotkey.bind({"ctrl", "alt"}, "a", function()
    log("Manual trigger activated!")
    setOutputDevice()
    setInputDevice()
    showCurrentDevices()
end)

-- Add hotkey to toggle between headphone/speaker mode (Cmd+Alt+0)
hs.hotkey.bind({"cmd", "alt"}, "0", toggleAudioMode)

-- Mute/Unmute microphone functionality
local micMuted = false
local function toggleMicMute()
    local currentInput = hs.audiodevice.defaultInputDevice()
    if currentInput then
        micMuted = not micMuted
        currentInput:setInputMuted(micMuted)

        local statusText = micMuted and "🔇 Microphone MUTED" or "🎤 Microphone UNMUTED"
        log(statusText)

        -- Update SketchyBar
        hs.task.new("/opt/homebrew/bin/sketchybar", function() end, {"--trigger", "mic_toggle"}):start()
    else
        log("❌ No input device found to mute/unmute")
        hs.alert.show("❌ No microphone found", 1)
    end
end

-- Add hotkey for microphone mute toggle (Cmd+Shift+M)
hs.hotkey.bind({"cmd", "shift"}, "m", toggleMicMute)

-- Add hotkey to reload SketchyBar (Cmd+Shift+R)
hs.hotkey.bind({"cmd", "shift"}, "r", function()
    hs.execute("/opt/homebrew/bin/sketchybar --reload", true)
    hs.alert.show("SketchyBar reloaded", 0.5)
end)

-- Set initial devices on load
setOutputDevice()
setInputDevice()
showCurrentDevices()

log("HammerSpoon Audio Priority Manager started! 🎵")
log("Press Ctrl+Alt+A to manually trigger audio switching")
log("Press Cmd+Alt+0 to toggle between HEADPHONE/SPEAKER modes")
log("Press Cmd+Shift+M to toggle microphone mute")-- Configuración de Hammerspoon para capturar pantalla con Alt+Shift+A (Option+Shift+A)
-- Copiar este contenido a ~/.hammerspoon/init.lua o agregarlo al archivo existente

-- Función para capturar la ventana activa
function captureActiveWindow()
    -- Ruta del script de captura
    local scriptPath = "/Users/styreep/uni/52/infra/lab3/capture_screen.sh"

    -- Ejecutar el script
    local task = hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            -- Mostrar alerta de éxito
            hs.alert.show("📸 Captura guardada", 1)
        else
            hs.alert.show("❌ Error en captura", 1)
        end
    end, {scriptPath})

    task:start()
end

-- Configurar el atajo de teclado Alt+Shift+A (Option+Shift+A en Mac)
hs.hotkey.bind({"alt", "shift"}, "A", captureActiveWindow)

-- Mensaje de confirmación
hs.alert.show("✓ Atajo Lab3 configurado: ⌥⇧A", 2)
