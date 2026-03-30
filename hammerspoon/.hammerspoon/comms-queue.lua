-- Comms Queue — paste messages one at a time via global hotkey
-- Queue file: /tmp/comms-queue.json (written by send.py)

local M = {}

local QUEUE_FILE = "/tmp/comms-queue.json"
M.busy = false

local function log(message)
    print("📋 Comms: " .. message)
end

local function readQueue()
    local f = io.open(QUEUE_FILE, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    return hs.json.decode(content)
end

local function writeQueue(queue)
    local f = io.open(QUEUE_FILE, "w")
    if not f then return end
    f:write(hs.json.encode(queue))
    f:close()
end

function M.sendNext()
    -- Guard against rapid presses
    if M.busy then return end
    M.busy = true

    local queue = readQueue()
    if not queue or not queue.messages or queue.idx >= #queue.messages then
        hs.alert.show("No more messages", 1)
        log("Queue empty or finished")
        os.remove(QUEUE_FILE)
        M.busy = false
        return
    end

    queue.idx = queue.idx + 1
    local msg = queue.messages[queue.idx]
    local remaining = #queue.messages - queue.idx

    -- Copy to clipboard, paste, enter — minimal delays
    hs.pasteboard.setContents(msg)
    hs.eventtap.keyStroke({"cmd"}, "v")
    hs.timer.doAfter(0.08, function()
        hs.eventtap.keyStroke({}, "return")

        -- Status
        local status = string.format("%d/%d", queue.idx, #queue.messages)
        if remaining == 0 then
            status = "All sent ✓"
            os.remove(QUEUE_FILE)
        end
        hs.alert.show(status, 0.5)
        log(status .. ": " .. msg)

        writeQueue(queue)
        M.busy = false
    end)
end

function M.init()
    log("Comms Queue initialized (Ctrl+Shift+V to send next)")
end

return M
