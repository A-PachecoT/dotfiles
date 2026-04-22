-- Sleep/Wake recovery for services whose socket wedges after system sleep.
-- SketchyBar's daemon stays alive (no exit code) but becomes unresponsive, so
-- launchd's KeepAlive won't restart it. This module probes on wake and only
-- kickstarts services that actually fail a health check.

local M = {}

local SERVICES = {
    {
        label = "sketchybar",
        agent = "homebrew.mxcl.sketchybar",
        healthcheck = "/opt/homebrew/bin/sketchybar --query bar",
    },
}

local WAKE_SETTLE_SECONDS = 2
local HEALTHCHECK_TIMEOUT_SECONDS = 0.8

local cachedUid = nil

local function getUid()
    if cachedUid then return cachedUid end
    local out = hs.execute("id -u") or ""
    cachedUid = tonumber(out:match("(%d+)")) or 501
    return cachedUid
end

local function log(msg)
    print("💤 sleep-wake: " .. msg)
end

local function reviveService(svc)
    local cmd = string.format("launchctl kickstart -k gui/%d/%s", getUid(), svc.agent)
    hs.execute(cmd)
    log("kickstarted " .. svc.label)
end

local function checkHealth(svc, callback)
    local settled = false
    local timedOut = false

    local task = hs.task.new("/bin/sh", function(exitCode, _, _)
        if settled then return end
        settled = true
        callback(not timedOut and exitCode == 0)
    end, { "-c", svc.healthcheck .. " >/dev/null 2>&1" })

    task:start()

    hs.timer.doAfter(HEALTHCHECK_TIMEOUT_SECONDS, function()
        if not settled and task:isRunning() then
            timedOut = true
            task:terminate()
        end
    end)
end

function M.checkAndRevive()
    for _, svc in ipairs(SERVICES) do
        checkHealth(svc, function(healthy)
            if healthy then
                log(svc.label .. " healthy, no action")
            else
                log(svc.label .. " unresponsive")
                reviveService(svc)
            end
        end)
    end
end

function M.init()
    M.watcher = hs.caffeinate.watcher.new(function(event)
        if event == hs.caffeinate.watcher.systemDidWake then
            hs.timer.doAfter(WAKE_SETTLE_SECONDS, M.checkAndRevive)
        end
    end)
    M.watcher:start()
    log("watcher armed (systemDidWake)")
end

return M
