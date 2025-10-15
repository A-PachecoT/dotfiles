-- Window Manager
-- Auto-centers floating windows and provides manual centering

local M = {}

-- Apps that should auto-center when opened (floating windows)
local autoCenterApps = {
    "iTerm2",
    "Finder",
    "WhatsApp",
    "Telegram",
    "Mail",
    "Spotify"
}

-- Helper function to check if app should be centered (fuzzy match)
local function shouldCenterApp(appName)
    -- Clean app name of invisible characters
    local cleanName = appName:gsub("[%z\1-\31\127-\255]", "")

    for _, targetApp in ipairs(autoCenterApps) do
        if cleanName:find(targetApp, 1, true) or targetApp:find(cleanName, 1, true) then
            return true
        end
    end
    return false
end

local function log(message)
    print("🪟 Window Manager: " .. message)
    hs.console.printStyledtext(hs.styledtext.new("🪟 " .. message, {color = {hex = "#9ece6a"}}))
end

local function centerWindowFrame(window)
    if not window then
        log("❌ centerWindowFrame: No window provided")
        return false
    end

    if not window:isStandard() then
        log("❌ centerWindowFrame: Window is not standard")
        return false
    end

    local screen = window:screen()
    if not screen then
        log("❌ centerWindowFrame: No screen found")
        return false
    end

    local frame = screen:frame()
    local winFrame = window:frame()

    log(string.format("Screen: %dx%d, Window: %dx%d", frame.w, frame.h, winFrame.w, winFrame.h))

    -- Maximum size constraints (60% width, 70% height)
    local maxWidth = frame.w * 0.6
    local maxHeight = frame.h * 0.7

    -- Resize if window exceeds maximums
    if winFrame.w > maxWidth then
        winFrame.w = maxWidth
        log(string.format("Resized width to max: %.0f", maxWidth))
    end
    if winFrame.h > maxHeight then
        winFrame.h = maxHeight
        log(string.format("Resized height to max: %.0f", maxHeight))
    end

    -- Center the window on the screen
    winFrame.x = frame.x + (frame.w - winFrame.w) / 2
    winFrame.y = frame.y + (frame.h - winFrame.h) / 2

    -- Use 0.2 second animation for smooth native macOS transition
    window:setFrame(winFrame, 0.2)
    log(string.format("✓ Positioned at x=%d, y=%d (size: %.0fx%.0f)", winFrame.x, winFrame.y, winFrame.w, winFrame.h))
    return true
end

-- Public API
function M.centerWindow()
    local win = hs.window.focusedWindow()
    if win then
        log("Manual center triggered for: " .. win:application():name())
        if centerWindowFrame(win) then
            log("✓ Window centered: " .. win:application():name())
        end
    else
        log("❌ No focused window found")
    end
end

function M.init()
    -- Window filter to watch for new windows
    local windowFilter = hs.window.filter.new()

    -- Handle NEW windows
    windowFilter:subscribe(hs.window.filter.windowCreated, function(window)
        if not window then return end

        local app = window:application()
        if not app then return end

        local appName = app:name()
        log("New window detected: " .. appName)

        if shouldCenterApp(appName) then
            log("Matched for centering: " .. appName)
            -- Longer delay to ensure window is fully created and positioned by AeroSpace
            hs.timer.doAfter(0.3, function()
                if window:isVisible() and window:isStandard() then
                    log("Attempting to auto-center new window: " .. appName)
                    centerWindowFrame(window)
                else
                    log("❌ Window not ready - visible: " .. tostring(window:isVisible()) .. ", standard: " .. tostring(window:isStandard()))
                end
            end)
        end
    end)

    -- Handle EXISTING windows when they get focused
    windowFilter:subscribe(hs.window.filter.windowFocused, function(window)
        if not window then return end

        local app = window:application()
        if not app then return end

        local appName = app:name()

        if shouldCenterApp(appName) then
            -- Small delay to let AeroSpace set it to floating first
            hs.timer.doAfter(0.15, function()
                if window:isVisible() and window:isStandard() then
                    log("Auto-centering focused window: " .. appName)
                    centerWindowFrame(window)
                end
            end)
        end
    end)

    log("Window Manager initialized")
    log("Auto-centering enabled for: " .. table.concat(autoCenterApps, ", "))
end

return M
