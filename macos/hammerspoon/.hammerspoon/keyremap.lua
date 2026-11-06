-- Remapeo de teclas con hidutil (nativo de macOS): reemplaza a Karabiner-Elements.
-- Karabiner metía un daemon en el camino de cada tecla y perdía key-ups → letras repetidas
-- (bitacora 2026-11-05). hidutil remapea en el driver HID: cero latencia, sin event taps.
--
--   Todos los teclados: Caps Lock ↔ Escape
--   Teclado 2.4G (se presenta como Apple 0x5ac/0x24f, layout Windows): además ⌘ ↔ ⌥ izquierdos
--
-- Un mapeo por dispositivo se pierde cuando el receptor se reconecta: el usb watcher lo reaplica.

local M = {}

local CAPS, ESC = 0x700000039, 0x700000029
local LCMD, LOPT = 0x7000000E3, 0x7000000E2
local DONGLE = { VendorID = 0x5ac, ProductID = 0x24f }

local function pair(a, b)
    return { { HIDKeyboardModifierMappingSrc = a, HIDKeyboardModifierMappingDst = b },
             { HIDKeyboardModifierMappingSrc = b, HIDKeyboardModifierMappingDst = a } }
end

local function concat(...)
    local out = {}
    for _, t in ipairs({ ... }) do for _, v in ipairs(t) do out[#out + 1] = v end end
    return out
end

local function hidutil(args, after)
    hs.task.new("/usr/bin/hidutil", function(code, _, err)
        if code ~= 0 then print("keyremap: hidutil falló: " .. (err or "")) end
        if after then after() end
    end, args):start()
end

-- En serie: el --set global pisa los mapeos por dispositivo, así que va primero.
function M.apply()
    local base = pair(CAPS, ESC)
    hidutil({ "property", "--set", hs.json.encode({ UserKeyMapping = base }) }, function()
        hidutil({ "property", "--matching", hs.json.encode(DONGLE), "--set",
                  hs.json.encode({ UserKeyMapping = concat(base, pair(LCMD, LOPT)) }) })
    end)
end

M.apply()
-- El hub puede tardar en enumerar el receptor: reaplicamos con un pequeño retraso.
M.usbWatcher = hs.usb.watcher.new(function(ev)
    if ev.eventType == "added" then hs.timer.doAfter(1, M.apply) end
end):start()
M.wakeWatcher = hs.caffeinate.watcher.new(function(ev)
    if ev == hs.caffeinate.watcher.systemDidWake then hs.timer.doAfter(2, M.apply) end
end):start()

return M
