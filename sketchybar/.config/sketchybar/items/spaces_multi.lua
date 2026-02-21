local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local styles = require("styles")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_brackets = {}
local max_spaces = 10

-- Aerospace monitor ID -> SketchyBar display ID mapping
-- (they number monitors in opposite order)
local aero_to_sbar_display = { [1] = 2, [2] = 1 }

-- Get theme-aware card style
local card_style = styles.card()

-- Session to workspace mapping for Claude pending badges
local session_workspace_map = {
  cofoundy = 2,
  bilio = 3,
  personal = 4,
  per = 4,
  dotfiles = 4,
  standalone = 5,  -- Ad-hoc sessions in workspace 5
  notes = 9,
}

-- Debounce state
local last_update_time = 0
local debounce_ms = 150  -- Minimum ms between updates
local pending_update = false

-- Track current focused workspace (updated from trigger env)
local current_focused_ws = nil
local prev_focused_ws = nil

-- Helper: run command and return output directly (used only for non-aerospace calls)
local function exec(cmd)
  local handle = io.popen(cmd .. " 2>/dev/null")
  if not handle then return "" end
  local result = handle:read("*a") or ""
  handle:close()
  return result
end

-- Function to get pending Claude events per workspace
local function get_pending_by_workspace()
  local pending = {}
  local queue_dir = os.getenv("HOME") .. "/.claude-pending"

  -- List files in queue directory
  local output = exec("ls -1 '" .. queue_dir .. "'")
  for file in output:gmatch("[^\n]+") do
    -- Parse filename: timestamp_session_window_type
    local session = file:match("^%d+_([^_]+)_")
    local event_type = file:match("_([^_]+)$")
    if session then
      local ws = session_workspace_map[session]
      if ws then
        -- Track both count and whether any are questions
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

  return pending
end

-- Create spaces for each display
for display = 1, 2 do
  for i = 1, max_spaces do
    local space_name = "space." .. display .. "." .. i

    local space = sbar.add("space", space_name, {
      space = i,
      display = display,  -- Pin to specific display
      icon = {
        font = { family = settings.font.numbers },
        string = i,
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
      popup = { background = { border_width = 5, border_color = colors.black } },
      drawing = false -- Start hidden
    })

    -- Store in 2D array [display][workspace]
    spaces[display] = spaces[display] or {}
    spaces[display][i] = space

    -- Single item bracket for space items to achieve double border on highlight
    local space_bracket = sbar.add("bracket", { space_name }, {
      background = {
        color = colors.transparent,
        border_color = colors.bg2,
        height = 28,
        border_width = 2
      },
      drawing = false -- Start hidden
    })

    space_brackets[display] = space_brackets[display] or {}
    space_brackets[display][i] = space_bracket

    -- Space popup for screenshots
    local space_popup = sbar.add("item", {
      position = "popup." .. space_name,
      padding_left = 5,
      padding_right = 0,
      background = {
        drawing = true,
        image = {
          corner_radius = 9,
          scale = 0.2
        }
      }
    })

    -- Mouse click handler
    space:subscribe("mouse.clicked", function(env)
      if env.BUTTON == "other" then
        -- Middle click - show space preview
        sbar.exec("screencapture -x -D " .. display .. " /tmp/space_" .. display .. "_" .. i .. ".png", function()
          space_popup:set({ background = { image = "/tmp/space_" .. display .. "_" .. i .. ".png" } })
          space:set({ popup = { drawing = "toggle" } })
        end)
      else
        -- Left/right click - focus workspace
        sbar.exec("aerospace workspace " .. i)
      end
    end)

    space:subscribe("mouse.exited", function(_)
      space:set({ popup = { drawing = false } })
    end)
  end
end

-- Spaces indicator toggle (one per display)
local spaces_indicators = {}
for display = 1, 2 do
  spaces_indicators[display] = sbar.add("item", {
    position = "left",
    display = display,
    padding_left = -3,
    padding_right = 0,
    icon = {
      padding_left = 8,
      padding_right = 9,
      color = colors.grey,
      string = icons.switch.on,
    },
    label = {
      width = 0,
      padding_left = 0,
      padding_right = 8,
      string = "Spaces",
      color = colors.bg1,
    },
    background = {
      color = colors.with_alpha(colors.grey, 0.0),
      border_color = colors.with_alpha(colors.bg1, 0.0),
    }
  })

  -- Spaces indicator animations
  spaces_indicators[display]:subscribe("mouse.entered", function(env)
    sbar.animate("tanh", 30, function()
      spaces_indicators[display]:set({
        background = {
          color = { alpha = 1.0 },
          border_color = { alpha = 1.0 },
        },
        icon = { color = colors.bg1 },
        label = { width = "dynamic" }
      })
    end)
  end)

  spaces_indicators[display]:subscribe("mouse.exited", function(env)
    sbar.animate("tanh", 30, function()
      spaces_indicators[display]:set({
        background = {
          color = { alpha = 0.0 },
          border_color = { alpha = 0.0 },
        },
        icon = { color = colors.grey },
        label = { width = 0 }
      })
    end)
  end)

  spaces_indicators[display]:subscribe("mouse.clicked", function(env)
    sbar.trigger("swap_menus_and_spaces")
  end)
end

-- Helper to apply workspace UI updates given parsed data
-- ws_monitor maps workspace number -> monitor/display number
local function apply_workspace_updates(focused_ws, ws_apps, ws_monitor)
  local claude_pending = get_pending_by_workspace()

  -- Update each display
  for display = 1, 2 do
    for i = 1, max_spaces do
      local is_focused = (i == focused_ws)
      local has_apps = ws_apps[i] ~= nil and next(ws_apps[i]) ~= nil
      local belongs_to_display = (ws_monitor[i] == display)
      -- Show on this display only if workspace belongs here
      local should_show = belongs_to_display and (has_apps or is_focused)

      if spaces[display] and spaces[display][i] then
        spaces[display][i]:set({ drawing = should_show })
        space_brackets[display][i]:set({ drawing = should_show })

        if should_show then
          -- Claude pending badge
          local pending_info = claude_pending[i]
          local badge = ""
          if pending_info and pending_info.count > 0 then
            if pending_info.has_question then
              badge = " 󰂞"
            else
              badge = " ●"
            end
          end

          spaces[display][i]:set({ icon = { string = tostring(i) .. badge } })

          sbar.animate("tanh", 10, function()
            spaces[display][i]:set({
              icon = { highlight = is_focused },
              label = { highlight = is_focused },
              background = { border_color = is_focused and colors.black or colors.bg2 }
            })
            space_brackets[display][i]:set({
              background = { border_color = is_focused and colors.grey or colors.bg2 }
            })
          end)

          -- Build app icon string
          local icon_line = ""
          if has_apps then
            for app, _ in pairs(ws_apps[i]) do
              local lookup = app_icons[app]
              local icon = lookup or app_icons["default"] or "?"
              icon_line = icon_line .. icon .. " "
            end
          end

          if icon_line == "" and is_focused then
            icon_line = " —"
          elseif icon_line == "" then
            icon_line = " —"
          end

          sbar.animate("tanh", 10, function()
            spaces[display][i]:set({ label = { string = icon_line } })
          end)
        end
      end
    end
  end
end

-- ASYNC update: uses sbar.exec() so aerospace hangs don't freeze sketchybar
-- Gets focused_ws from trigger env (no aerospace call needed)
local function do_update_workspaces()
  local focused_ws = current_focused_ws

  -- If no focused_ws yet (startup), query it
  if not focused_ws then
    local focused_output = exec("aerospace list-workspaces --focused")
    focused_ws = tonumber(focused_output:match("%d+"))
    current_focused_ws = focused_ws
  end

  -- ONE async call to get all windows with monitor info
  sbar.exec("aerospace list-windows --all --format '%{workspace}|%{app-name}|%{monitor-id}' 2>/dev/null", function(result)
    local ws_apps = {}
    local ws_monitor = {}
    for line in (result or ""):gmatch("[^\n]+") do
      local ws_str, app_name, mon_str = line:match("^(%d+)|(.+)|(%d+)$")
      if ws_str and app_name and app_name ~= "" then
        local ws_num = tonumber(ws_str)
        local mon_num = tonumber(mon_str)
        if ws_num then
          if not ws_apps[ws_num] then ws_apps[ws_num] = {} end
          ws_apps[ws_num][app_name] = true
          if mon_num then ws_monitor[ws_num] = aero_to_sbar_display[mon_num] or mon_num end
        end
      end
    end

    -- Focused workspace: if it has no windows, query its monitor
    if focused_ws and not ws_monitor[focused_ws] then
      local mon_out = exec("aerospace list-workspaces --focused --format '%{workspace}|%{monitor-id}'")
      local _, mon_str = mon_out:match("^(%d+)|(%d+)")
      local mon_num = tonumber(mon_str) or 1
      ws_monitor[focused_ws] = aero_to_sbar_display[mon_num] or mon_num
    end

    apply_workspace_updates(focused_ws, ws_apps, ws_monitor)
  end)
end

-- Debounced wrapper for update_workspaces
local function update_workspaces()
  local now = os.clock() * 1000  -- Current time in ms

  if now - last_update_time < debounce_ms then
    -- Too soon, schedule update if not already pending
    if not pending_update then
      pending_update = true
      sbar.exec("sleep 0.15", function()
        pending_update = false
        last_update_time = os.clock() * 1000
        do_update_workspaces()
      end)
    end
    return
  end

  last_update_time = now
  do_update_workspaces()
end

-- Space window observer (hidden item for event subscriptions)
local space_window_observer = sbar.add("item", {
  drawing = false,
  updates = true,
})

-- Instant focus highlight update (no async, no aerospace call)
local function update_focus_highlight(new_ws, old_ws)
  for display = 1, 2 do
    -- Unhighlight old workspace
    if old_ws and spaces[display] and spaces[display][old_ws] then
      spaces[display][old_ws]:set({
        icon = { highlight = false },
        label = { highlight = false },
        background = { border_color = colors.bg2 }
      })
      space_brackets[display][old_ws]:set({
        background = { border_color = colors.bg2 }
      })
    end
    -- Highlight new workspace (ensure it's visible)
    if new_ws and spaces[display] and spaces[display][new_ws] then
      spaces[display][new_ws]:set({
        drawing = true,
        icon = { highlight = true },
        label = { highlight = true },
        background = { border_color = colors.black }
      })
      space_brackets[display][new_ws]:set({
        drawing = true,
        background = { border_color = colors.grey }
      })
    end
  end
end

-- Subscribe to aerospace workspace change event
space_window_observer:subscribe("aerospace_workspace_change", function(env)
  -- Get focused workspace from trigger env (FREE, no aerospace call)
  local ws = tonumber(env.FOCUSED_WORKSPACE)
  if ws then
    prev_focused_ws = current_focused_ws
    current_focused_ws = ws
    -- Instant highlight swap (no delay)
    update_focus_highlight(ws, prev_focused_ws)
  end
  -- Full update (icons, occupancy) happens async
  update_workspaces()
end)

-- Subscribe to manual space_windows_change events
space_window_observer:subscribe("space_windows_change", function(env)
  update_workspaces()
end)

-- Subscribe to front app change
space_window_observer:subscribe("front_app_switched", function(env)
  update_workspaces()
end)

-- Subscribe to Claude pending changes
space_window_observer:subscribe("claude_pending_change", function(env)
  update_workspaces()
end)

-- Initial update
do_update_workspaces()
