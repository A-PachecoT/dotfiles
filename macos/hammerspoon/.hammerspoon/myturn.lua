-- myturn: ⌥T marca/desmarca como prioridad el agente que estás mirando en herdr · ⌥G te lleva al que te espera.
-- ⌥N no: en US International-PC es la ñ. SSOT: ~/dotfiles/docs/myturn.md
local M = {}

local HOME = os.getenv("HOME")
local BIN = HOME .. "/.local/bin/myturn"
local ENV = { PATH = HOME .. "/.local/bin:/opt/homebrew/bin:/usr/bin:/bin", HOME = HOME, USER = os.getenv("USER") }

local function myturn(args, cb)
  local t = hs.task.new(BIN, function(code, out, err)
    if cb then cb(code, (out or ""):gsub("%s+$", ""), err) end
  end, args)
  t:setEnvironment(ENV)
  t:start()
end

function M.toggle()
  myturn({ "toggle" }, function(_, out) hs.alert.show(out ~= "" and out or "myturn: algo falló", 1.5) end)
end

function M.jump()
  myturn({ "jump" }, function(_, out)
    if out == "nadie te espera" then hs.alert.show("Nadie te espera", 1) end
  end)
end

hs.hotkey.bind({ "alt" }, "t", M.toggle)
hs.hotkey.bind({ "alt" }, "g", M.jump)

return M
