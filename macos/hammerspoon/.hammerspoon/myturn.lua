-- myturn: ⌥T paleta (capturar · priorizar/cerrar el agente enfocado · ir a una tarea) y ⌥G salto al siguiente
-- agente que te espera. ⌥N no: en US International-PC es la ñ. SSOT: ~/dotfiles/docs/myturn.md
local M = {}

local HOME = os.getenv("HOME")
local BIN = HOME .. "/.local/bin/myturn"
local ENV = { PATH = HOME .. "/.local/bin:/opt/homebrew/bin:/usr/bin:/bin", HOME = HOME, USER = os.getenv("USER") }

local function myturn(args, cb)
  local t = hs.task.new(BIN, function(code, out, err)
    if cb then cb(code, out, err) end
  end, args)
  t:setEnvironment(ENV)
  t:start()
end

local chooser
local data = { focused = nil, rows = {} }

local function choicesFor(query)
  local q = (query or ""):lower()
  local rows = {}
  if #q > 0 then
    table.insert(rows, { text = "＋ " .. query, subText = "Capturar como pendiente (la IA saca fecha y prioridad)",
      action = "add", arg = query })
  end
  local f = data.focused
  if f and #q == 0 then
    if f.prio == 1 then
      table.insert(rows, { text = "☆ Quitar prioridad: " .. f.title, subText = "Agente enfocado en herdr",
        action = "prio", arg = "0" })
    else
      table.insert(rows, { text = "★ Prioridad: " .. f.title,
        subText = "Agente enfocado · te avisa cuando termine", action = "prio", arg = "1" })
    end
    if f.id then
      table.insert(rows, { text = "✓ Hecha: " .. f.title, subText = "Agente enfocado", action = "done" })
    end
  end
  for _, r in ipairs(data.rows or {}) do
    if #q == 0 or r.title:lower():find(q, 1, true) then
      table.insert(rows, { text = r.title, subText = r.group .. " · " .. table.concat(r.why or {}, " · "),
        action = "go", arg = r.id })
    end
  end
  return rows
end

local function onChoice(c)
  if not c then return end
  if c.action == "add" then
    myturn({ "add", "--raw", c.arg }, function(code)
      hs.alert.show(code == 0 and "myturn: capturada" or "myturn: falló la captura", 0.8)
    end)
  elseif c.action == "prio" then
    myturn({ "prio", c.arg }, function(_, out) hs.alert.show(out or "", 0.8) end)
  elseif c.action == "done" then
    myturn({ "done" }, function(_, out) hs.alert.show(out or "", 0.8) end)
  elseif c.action == "go" then
    myturn({ "go", c.arg })
  end
end

function M.palette()
  if not chooser then
    chooser = hs.chooser.new(onChoice)
    chooser:placeholderText("Captura algo… · ★ prioriza el agente enfocado · o busca una tarea")
    chooser:queryChangedCallback(function(q) chooser:choices(choicesFor(q)) end)
  end
  data = { focused = nil, rows = {} }
  chooser:choices(choicesFor(""))
  chooser:query("")
  chooser:show()
  myturn({ "palette", "--json" }, function(_, out)
    local ok, d = pcall(hs.json.decode, out or "")
    if ok and type(d) == "table" then
      data = d
      chooser:choices(choicesFor(chooser:query()))
    end
  end)
end

function M.jump()
  myturn({ "jump" }, function(_, out)
    out = (out or ""):gsub("%s+$", "")
    if out == "nadie te espera" then hs.alert.show("myturn: nadie te espera", 0.8) end
  end)
end

hs.hotkey.bind({ "alt" }, "t", M.palette)
hs.hotkey.bind({ "alt" }, "g", M.jump)

return M
