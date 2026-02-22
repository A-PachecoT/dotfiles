-- Minimal spaces configuration
-- Uses sbar.exec() (async) for aerospace calls - never blocks the event loop
-- Focused workspace is passed via trigger event

local colors = require("colors")
local settings = require("settings")
local styles = require("styles")
local app_icons = require("helpers.app_icons")

local spaces = {}
local card_style = styles.card()

-- Session to workspace mapping for Claude pending badges
local session_workspace_map = {
  cofoundy = 2,
  bilio = 3,
  personal = 4,
  per = 4,
  notes = 9,
}

-- Debounce state
local last_update_time = 0
local debounce_ms = 200
local pending_update = false

-- Function to get pending Claude events per workspace
local function get_pending_by_workspace()
  local pending = {}
  local queue_dir = os.getenv("HOME") .. "/.claude-pending"
  local handle = io.popen("ls -1 '" .. queue_dir .. "' 2>/dev/null")
  if handle then
    for file in handle:lines() do
      local session = file:match("^%d+_([^_]+)_")
      local event_type = file:match("_([^_]+)$")
      if session then
        local ws = session_workspace_map[session]
        if ws then
          if not pending[ws] then
            pending[ws] = { count = 0, has_question = false }
          end
          pending[ws].count = pending[ws].count + 1
          if event_type == "question" then
            pending[ws].has_question = true
          end
        end
      end
    end
    handle:close()
  end
  return pending
end

-- Create space items for workspaces 1-9 (always visible)
for i = 1, 9 do
  local space = sbar.add("space", "space." .. i, {
    space = i,
    display = 1,
    icon = {
      font = { family = settings.font.numbers },
      string = tostring(i),
      padding_left = 15,
      padding_right = 8,
      color = colors.white,
      highlight_color = colors.red,
    },
    label = {
      padding_right = 20,
      color = colors.grey,
      highlight_color = colors.white,
      font = "sketchybar-app-font:Regular:16.0",
      y_offset = -1,
      string = " —",
    },
    padding_right = 1,
    padding_left = 1,
    background = card_style.background,
    drawing = true
  })

  spaces[i] = space

  -- Click handler - focus workspace (async, won't block)
  space:subscribe("mouse.clicked", function(env)
    sbar.exec("aerospace workspace " .. i)
  end)
end

-- Track current focused workspace
local current_focused = 1

-- Update function - highlights focused, then ONE async call for all app icons
local function do_update_workspaces(focused_ws)
  if focused_ws then
    current_focused = focused_ws
  end

  local claude_pending = get_pending_by_workspace()

  -- Step 1: Immediately update highlights (ZERO aerospace calls)
  for i = 1, 9 do
    local is_focused = (i == current_focused)

    local pending_info = claude_pending[i]
    local badge = ""
    if pending_info and pending_info.count > 0 then
      if pending_info.has_question then
        badge = " 󰂞"
      else
        badge = " ●"
      end
    end

    sbar.animate("tanh", 10, function()
      spaces[i]:set({
        icon = {
          highlight = is_focused,
          string = tostring(i) .. badge,
        },
        label = { highlight = is_focused },
        background = { border_color = is_focused and colors.black or colors.bg2 }
      })
    end)
  end

  -- Step 2: ONE async call to get all windows across all workspaces
  -- If aerospace hangs, highlights still work - only app icons won't update
  sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}' 2>/dev/null", function(result)
    -- Parse result: group apps by workspace
    local ws_apps = {}
    for line in (result or ""):gmatch("[^\n]+") do
      local ws_str, app_name = line:match("^(%d+)|(.+)$")
      if ws_str and app_name and app_name ~= "" then
        local ws_num = tonumber(ws_str)
        if ws_num then
          if not ws_apps[ws_num] then ws_apps[ws_num] = {} end
          ws_apps[ws_num][app_name] = (ws_apps[ws_num][app_name] or 0) + 1
        end
      end
    end

    -- Update app icons for all workspaces
    for i = 1, 9 do
      local icon_line = ""
      local apps = ws_apps[i]

      if apps then
        for app, _ in pairs(apps) do
          local lookup = app_icons[app]
          local icon = lookup or app_icons["default"] or "?"
          icon_line = icon_line .. icon .. " "
        end
      end

      if icon_line == "" then
        icon_line = " —"
      end

      spaces[i]:set({ label = { string = icon_line } })
    end
  end)
end

-- Debounced wrapper
local function update_workspaces(focused_ws)
  local now = os.clock() * 1000

  if now - last_update_time < debounce_ms then
    if not pending_update then
      pending_update = true
      -- Store focused_ws for deferred update
      local deferred_ws = focused_ws
      sbar.exec("sleep 0.2", function()
        pending_update = false
        last_update_time = os.clock() * 1000
        do_update_workspaces(deferred_ws)
      end)
    end
    return
  end

  last_update_time = now
  do_update_workspaces(focused_ws)
end

-- Event observer
local space_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

space_observer:subscribe("aerospace_workspace_change", function(env)
  local focused = tonumber(env.FOCUSED_WORKSPACE)
  update_workspaces(focused)
end)

space_observer:subscribe("front_app_switched", function(env)
  update_workspaces(nil)
end)

space_observer:subscribe("claude_pending_change", function(env)
  update_workspaces(nil)
end)

-- Initial update
update_workspaces(1)

print("Minimal spaces loaded - async aerospace calls only")
