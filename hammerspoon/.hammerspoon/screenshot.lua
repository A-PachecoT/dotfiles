-- Screenshot Manager
-- Captures active window and saves to configured folder

local M = {}

local SCRIPT_PATH = "/Users/styreep/uni/52/infra/capture_screen_flexible.sh"
local CONFIG_PATH = "/Users/styreep/uni/52/infra/capture_config.txt"
local DEFAULT_FOLDER = "lab3"

local function log(message)
    print("📸 Screenshot: " .. message)
    hs.console.printStyledtext(hs.styledtext.new("📸 " .. message, {color = {hex = "#bb9af7"}}))
end

local function getActiveFolder()
    local configFile = io.open(CONFIG_PATH, "r")
    if configFile then
        local folder = configFile:read("*l") or DEFAULT_FOLDER
        configFile:close()
        return folder
    end
    return DEFAULT_FOLDER
end

-- Public API
function M.captureActiveWindow()
    local task = hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            local folder = getActiveFolder()
            hs.alert.show("📸 Guardada en " .. folder .. "/recursos", 1)
            log("✓ Screenshot saved to " .. folder .. "/recursos")
        else
            hs.alert.show("❌ Error en captura", 1)
            log("❌ Screenshot failed: " .. stdErr)
        end
    end, {SCRIPT_PATH})

    task:start()
end

function M.init()
    log("Screenshot Manager initialized")
    log("Capture path: " .. SCRIPT_PATH)
end

return M
