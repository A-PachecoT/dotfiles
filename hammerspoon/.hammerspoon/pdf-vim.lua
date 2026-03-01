-- ============================================================
-- PDF VIM KEYBINDINGS (eventtap-based, lower level than hotkey)
-- ============================================================
-- Active only when Skim is focused.
-- Normal mode: j/k/d/u/gg/G/Ctrl-f/Ctrl-b
-- Insert mode: press i or / → Esc to return to normal

local M = {}

local PDF_APPS    = { "Skim" }
local SCROLL_STEP = 120   -- pixels per j/k
local HALF_PAGE   = 400   -- pixels per d/u

local isActive   = false
local insertMode = false
local ggPending  = false
local ggTimer    = nil
local keyTap     = nil
local appWatcher = nil

local function isSkim(name)
    for _, a in ipairs(PDF_APPS) do
        if name == a then return true end
    end
    return false
end

local function scroll(px)
    hs.eventtap.event.newScrollEvent({0, px}, {}, "pixel"):post()
end

local function sendKey(mods, key)
    hs.eventtap.keyStroke(mods, key, 0)
end

local function handleKey(event)
    if not isActive then return false end

    local code  = event:getKeyCode()
    local flags = event:getFlags()
    local shift = flags["shift"] or false

    local ctrl  = flags["ctrl"]  or false
    local cmd   = flags["cmd"]   or false
    local alt   = flags["alt"]   or false
    local key   = hs.keycodes.map[code]

    -- Always let cmd/alt combos pass through (Skim shortcuts)
    if cmd or alt then return false end

    -- Escape always exits insert mode
    if key == "escape" then
        if insertMode then
            insertMode = false
            sendKey({}, "escape")
            return true
        end
        return false
    end

    -- Insert mode: let everything pass through except Escape
    if insertMode then return false end

    -- Normal mode key handling
    if not ctrl and not shift then
        if key == "j" then scroll(-SCROLL_STEP); return true end
        if key == "k" then scroll(SCROLL_STEP);  return true end
        if key == "d" then scroll(-HALF_PAGE);   return true end
        if key == "u" then scroll(HALF_PAGE);    return true end
        if key == "i" then insertMode = true; return true end
        if key == "\\" then
            local skim = hs.application.get("Skim")
            if not skim:selectMenuItem({"View", "Hide Contents Pane"}) then
                skim:selectMenuItem({"View", "Show Contents Pane"})
            end
            return true
        end
        if key == "/" then
            insertMode = true
            sendKey({"cmd"}, "f")
            return true
        end
        if key == "g" then
            if ggPending then
                if ggTimer then ggTimer:stop() end
                ggPending = false
                hs.timer.doAfter(0.05, function()
                    for _ = 1, 100 do sendKey({}, "pageup") end
                end)
            else
                ggPending = true
                ggTimer = hs.timer.doAfter(0.4, function()
                    ggPending = false
                end)
            end
            return true
        end
    end

    if not ctrl and shift then
        if key == "g" then
            hs.timer.doAfter(0.05, function()
                for _ = 1, 100 do sendKey({}, "pagedown") end
            end)
            return true
        end
    end

    if ctrl and not shift then
        if key == "f" then sendKey({}, "pagedown"); return true end
        if key == "b" then sendKey({}, "pageup");   return true end
    end

    return false
end

function M.init()
    keyTap = hs.eventtap.new({hs.eventtap.event.types.keyDown}, handleKey)

    appWatcher = hs.application.watcher.new(function(name, event, _)
        if event == hs.application.watcher.activated then
            if isSkim(name) then
                isActive = true
                insertMode = false
                keyTap:start()
            else
                isActive = false
                keyTap:stop()
            end
        elseif event == hs.application.watcher.deactivated then
            if isSkim(name) then
                isActive = false
                keyTap:stop()
            end
        end
    end)
    appWatcher:start()

    -- Activate immediately if Skim already focused
    local front = hs.application.frontmostApplication()
    if front and isSkim(front:name()) then
        isActive = true
        keyTap:start()
    end

    print("📄 PDF Vim keybindings ready (eventtap)")
end

return M
