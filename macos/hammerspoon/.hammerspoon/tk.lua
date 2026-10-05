-- tk: captura en un segundo (⌃⌥T). Escribe → Enter agrega (la IA la ordena después).
-- Elegir una tarea existente te lleva a su agente o la vuelve la de ahora. SSOT: ~/dotfiles/docs/tk.md
local M = {}

local HOME = os.getenv("HOME")
local TK = HOME .. "/.local/bin/tk"
local ENV = { PATH = HOME .. "/.local/bin:/opt/homebrew/bin:/usr/bin:/bin", HOME = HOME, USER = os.getenv("USER") }

local function tk(args, cb)
  local t = hs.task.new(TK, function(code, out, err)
    if cb then cb(code, out, err) end
  end, args)
  t:setEnvironment(ENV)
  t:start()
end

local chooser
local tasks = {}

local function choicesFor(query)
  local rows = {}
  if query and #query > 0 then
    table.insert(rows, { text = "＋ " .. query, subText = "Capturar (Enter)", add = query })
  end
  for _, t in ipairs(tasks) do
    if not query or #query == 0 or t.title:lower():find(query:lower(), 1, true) then
      table.insert(rows, { text = t.title, subText = table.concat(t.why or {}, " · "), id = t.id })
    end
  end
  return rows
end

local function onChoice(c)
  if not c then return end
  if c.add then
    tk({ "add", "--raw", c.add }, function(code)
      if code == 0 then hs.alert.show("tk: capturada", 0.8) else hs.alert.show("tk: falló la captura") end
    end)
  elseif c.id then
    tk({ "bump", c.id }, function() tk({ "go", c.id }) end)
  end
end

function M.show()
  if not chooser then
    chooser = hs.chooser.new(onChoice)
    chooser:placeholderText("Captura una tarea… (Enter) · o busca una para volver a ella")
    chooser:queryChangedCallback(function(q) chooser:choices(choicesFor(q)) end)
  end
  tasks = {}
  chooser:choices(choicesFor(""))
  chooser:query("")
  chooser:show()
  tk({ "ls", "--json" }, function(_, out)
    local ok, list = pcall(hs.json.decode, out or "")
    if ok and type(list) == "table" then
      tasks = list
      chooser:choices(choicesFor(chooser:query()))
    end
  end)
end

hs.hotkey.bind({ "ctrl", "alt" }, "t", M.show)

return M
