-- Comms Queue — paste messages via global hotkey
-- Ctrl+Alt+N     = send next message
-- Ctrl+Alt+Shift+N = blast all remaining messages
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

local function pasteMessage(msg, callback)
    hs.pasteboard.setContents(msg)
    hs.eventtap.keyStroke({"cmd"}, "v")
    hs.timer.doAfter(0.05, function()
        hs.eventtap.keyStroke({}, "return")
        if callback then
            hs.timer.doAfter(0.15, callback)
        end
    end)
end

function M.sendNext()
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

    pasteMessage(msg, function()
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

function M.sendAll()
    if M.busy then return end
    M.busy = true

    local queue = readQueue()
    if not queue or not queue.messages or queue.idx >= #queue.messages then
        hs.alert.show("No more messages", 1)
        os.remove(QUEUE_FILE)
        M.busy = false
        return
    end

    local total = #queue.messages

    -- Synchronous blast — no timer overhead
    for idx = queue.idx + 1, total do
        hs.pasteboard.setContents(queue.messages[idx])
        hs.eventtap.keyStroke({"cmd"}, "v")
        hs.timer.usleep(30000)   -- 30ms for paste to land
        hs.eventtap.keyStroke({}, "return")
        if idx < total then
            hs.timer.usleep(120000)  -- 120ms between messages
        end
    end

    hs.alert.show(total .. " sent ✓", 0.8)
    os.remove(QUEUE_FILE)
    M.busy = false
end

function M.init()
    log("Comms Queue initialized (Ctrl+Alt+N = next, Ctrl+Alt+Shift+N = blast all)")
end

return M
