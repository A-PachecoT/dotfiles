-- ============================================================
-- ZEN HERDR KEYS (drive Zen like a herdr window)
-- ============================================================
-- Active only when Zen is focused. Zen has no rebindable "next tab"
-- or "focus split pane" action, so Hammerspoon catches the herdr keys
-- and sends Zen's own shortcuts instead.
--
--   ⌘j / ⌘k   next / previous tab        (Ctrl+PageDown / Ctrl+PageUp)
--   ⌘h / ⌘l   previous / next workspace  (⌘⌥← / ⌘⌥→)
--   ⌘d        new empty split, right     (⌘⇧*)
--   ⌘⇧d       split horizontal           (⌘⌃⌥h, rebound in Zen)
--
-- Native and untouched: ⌘1-9 tabs, ⌘t new tab, ⌘w close tab/pane,
-- ⌘c/⌘x/⌘z copy/cut/undo (a browser needs them).
--
-- Zen side lives in its profile, outside dotfiles
-- (zen-keyboard-shortcuts.json, or Settings → Keyboard Shortcuts):
--   focusURLBar               ⌘l → ⌘e   (⌘l is taken here)
--   key_findSelection         ⌘e → none
--   zen-split-view-horizontal ⌘⌥h → ⌘⌃⌥h (⌘⌥h is macOS "Hide Others")

local M = {}

local ZEN_BUNDLE = "app.zen-browser.zen"

local hotkeys    = {}
local appWatcher = nil

local function sendKey(mods, key)
    hs.eventtap.keyStroke(mods, key, 0)
end

-- repeat = true keeps firing while held (⌘j held walks the tab list)
local BINDINGS = {
    { {"cmd"},          "j", {"ctrl"},               "pagedown", true  },
    { {"cmd"},          "k", {"ctrl"},               "pageup",   true  },
    { {"cmd"},          "h", {"cmd", "alt"},         "left",     false },
    { {"cmd"},          "l", {"cmd", "alt"},         "right",    false },
    { {"cmd"},          "d", {"cmd", "shift"},       "8",        false },
    { {"cmd", "shift"}, "d", {"cmd", "ctrl", "alt"}, "h",        false },
}

local function setActive(on)
    for _, hk in ipairs(hotkeys) do
        if on then hk:enable() else hk:disable() end
    end
end

local function isZen(app)
    return app ~= nil and app:bundleID() == ZEN_BUNDLE
end

function M.init()
    for _, b in ipairs(BINDINGS) do
        local fromMods, fromKey, toMods, toKey, rep = table.unpack(b)
        local fire = function() sendKey(toMods, toKey) end
        table.insert(hotkeys, hs.hotkey.new(fromMods, fromKey, fire, nil, rep and fire or nil))
    end

    appWatcher = hs.application.watcher.new(function(_, event, app)
        if event == hs.application.watcher.activated then
            setActive(isZen(app))
        elseif event == hs.application.watcher.deactivated and isZen(app) then
            setActive(false)
        end
    end)
    appWatcher:start()

    setActive(isZen(hs.application.frontmostApplication()))

    print("🧘 Zen herdr keys ready")
end

return M
