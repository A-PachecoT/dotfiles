-- myturn: el panel del widget (clic en la barra o ⌥T) y ⌥G para ir al agente que te espera.
-- Se abre en modo lista (teclado: n nueva, f buscar, hjkl, Enter/Espacio, Esc vuelve a tu ventana).
-- El panel es un webview (sketchybar no tiene campos de texto); habla con el CLI `myturn`.
-- ⌥N no: en US International-PC es la ñ. SSOT: ~/dotfiles/docs/myturn.md
local M = {}

local HOME = os.getenv("HOME")
local BIN = HOME .. "/.local/bin/myturn"
local HTML = HOME .. "/.hammerspoon/myturn-panel.html"
local ENV = { PATH = HOME .. "/.local/bin:/opt/homebrew/bin:/usr/bin:/bin", HOME = HOME, USER = os.getenv("USER") }
local W = 640

local panel, hiddenAt, maxH = nil, 0, 2000
local prevWin -- la ventana donde estabas al abrir el panel: Esc / ⌥T te devuelven ahí
local LOG = HOME .. "/.cache/myturn/panel.log"

local function log(...)
  local f = io.open(LOG, "a")
  if f then f:write(os.date("%H:%M:%S "), table.concat({ ... }, " "), "\n"); f:close() end
end

local function run(args, cb)
  local t = hs.task.new(BIN, function(code, out, err)
    if code ~= 0 then log("error", table.concat(args, " "), "→", code, err or "") end
    if cb then cb(code, (out or ""):gsub("%s+$", ""), err) end
  end, args)
  t:setEnvironment(ENV)
  t:start()
end

local function push()
  if panel then panel:evaluateJavaScript("window.loading && window.loading(true)") end
  run({ "panel" }, function(code, out)
    if not panel then return end
    if code == 0 and out ~= "" then panel:evaluateJavaScript("window.render(" .. out .. ")") end
    panel:evaluateJavaScript("window.loading(false)")
  end)
end

-- back = volver a la ventana previa (cierre con teclado); perder el foco por un clic afuera no la toca
function M.hide(back)
  if panel and panel:isVisible() then
    panel:hide()
    hiddenAt = hs.timer.secondsSinceEpoch()
    if back and prevWin then
      -- por AeroSpace: cambia de workspace si hace falta y no pasa por accesibilidad
      local w = prevWin
      local t = hs.task.new("/opt/homebrew/bin/aerospace", function(code)
        if code ~= 0 and w:application() then w:focus() end
      end, { "focus", "--window-id", string.format("%d", w:id()) })
      t:start()
    end
  end
end

local function onMessage(msg)
  local b = msg.body or {}
  local a = b.action
  if a ~= "resize" then log("msg", hs.json.encode(b)) end
  if a == "close" then
    M.hide(true)
  elseif a == "resize" and panel then
    local f = panel:frame()
    f.h = math.min(b.h, maxH)
    panel:frame(f)
  elseif a == "add" then
    local args = { "add", b.title }
    if b.prio then table.insert(args, "--prio"); table.insert(args, string.format("%d", b.prio)) end
    run(args, push)
  elseif a == "edit" then
    run({ "edit", b.id, b.title }, push)
  elseif a == "prio" then
    run({ "prio", string.format("%d", b.level), "--id", b.id }, push)
  elseif a == "done" or a == "archive" then
    run({ a, b.id }, push)
  elseif a == "copy" then
    hs.pasteboard.setContents(b.text)
  elseif a == "go" then
    M.hide()
    run({ "go", b.id }, function(_, out) if out ~= "" then hs.alert.show(out, 1) end end)
  end
end

local function build()
  local uc = hs.webview.usercontent.new("myturn")
  uc:setCallback(onMessage)
  panel = hs.webview.new({ x = 0, y = 0, w = W, h = 200 }, { developerExtrasEnabled = false }, uc)
  panel:windowStyle({ "borderless" })
  panel:allowTextEntry(true)
  panel:transparent(true)
  panel:level(hs.drawing.windowLevels.popUpMenu)
  panel:windowCallback(function(action, _, state)
    if action == "focusChange" and state == false then M.hide() end
  end)
  local f = io.open(HTML, "r")
  panel:html(f and f:read("*a") or "<p>falta myturn-panel.html</p>")
  if f then f:close() end
end

function M.show()
  if not panel then build() end
  prevWin = hs.window.frontmostWindow() -- antes de mostrar: dentro del timer ya sería Hammerspoon
  local scr = hs.mouse.getCurrentScreen():fullFrame()
  local f = panel:frame()
  maxH = scr.h - 40 - 16 -- nunca más alto que la pantalla: la lista scrollea
  panel:frame({ x = scr.x + (scr.w - W) / 2, y = scr.y + 40, w = W, h = math.min(f.h, maxH) })
  panel:evaluateJavaScript(string.format("window.setMaxH(%d)", maxH))
  panel:show()
  panel:bringToFront(true)
  push()
  -- sin activar Hammerspoon el campo no recibe teclas; recién mostrada, la ventana todavía no acepta el foco
  -- win:focus() (accesibilidad) congelaba Hammerspoon 1,6 s: se activa la app y, ya activa, show() la vuelve clave
  hs.timer.doAfter(0.12, function()
    hs.focus()
    hs.timer.doAfter(0.05, function()
      panel:show()
      panel:evaluateJavaScript("window.focusList()")
    end)
  end)
end

function M.toggle()
  -- un clic en la barra quita el foco al panel (lo cierra) justo antes de pedir abrirlo otra vez
  if (panel and panel:isVisible()) or hs.timer.secondsSinceEpoch() - hiddenAt < 0.4 then
    M.hide(true)
  else
    M.show()
  end
end

function M.jump()
  run({ "jump" }, function(_, out)
    if out == "nadie te espera" then hs.alert.show("Nadie te espera", 1) end
  end)
end

-- depurar desde la terminal: hs -c 'require("myturn").eval("document.title")'
function M.eval(js) if panel then panel:evaluateJavaScript(js, function(r, e) log("eval", hs.inspect(r), hs.inspect(e)) end) end end

-- precargado: el primer clic tras recargar Hammerspoon no paga crear el webview
build()
push()

hs.urlevent.bind("myturn-panel", function() M.toggle() end)
hs.hotkey.bind({ "alt" }, "t", M.toggle)
hs.hotkey.bind({ "alt" }, "g", M.jump)

return M
