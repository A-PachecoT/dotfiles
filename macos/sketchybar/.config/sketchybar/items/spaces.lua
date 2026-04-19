-- Debug output
print("Loading spaces.lua")

local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local styles = require("styles")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_brackets = {}
local max_spaces = 10

-- Debounce state to prevent trigger flooding
local last_update_time = 0
local debounce_ms = 150  -- Minimum ms between updates
local pending_update = false

-- Safe exec (reads output directly, no temp files)
-- Note: macOS doesn't have timeout command, using direct io.popen
local function safe_exec(cmd)
  local handle = io.popen(cmd .. " 2>/dev/null")
  if not handle then return "" end
  local result = handle:read("*a") or ""
  handle:close()
  return result
end

-- Get theme-aware card style
local card_style = styles.card()

-- Create all 10 space items but hide them initially
for i = 1, max_spaces do
  local space = sbar.add("space", "space." .. i, {
    space = i,
    display = 1,
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

  spaces[i] = space

  -- Single item bracket for space items to achieve double border on highlight
  local space_bracket = sbar.add("bracket", { space.name }, {
    background = {
      color = colors.transparent,
      border_color = colors.bg2,
      height = 28,
      border_width = 2
    },
    drawing = false -- Start hidden
  })

  space_brackets[i] = space_bracket

  -- Space popup for screenshots
  local space_popup = sbar.add("item", {
    position = "popup." .. space.name,
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
      sbar.exec("screencapture -x -D 1 /tmp/space_" .. i .. ".png", function()
        space_popup:set({ background = { image = "/tmp/space_" .. i .. ".png" } })
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

-- Spaces indicator toggle
local spaces_indicator = sbar.add("item", {
  position = "left",
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

-- Session to workspace mapping
local session_workspace_map = {
  cofoundy = 2,
  bilio = 3,
  personal = 4,
  per = 4,
  dotfiles = 4,  -- For testing in personal workspace
  notes = 9,
}

-- Function to get pending Claude events per workspace
local function get_pending_by_workspace()
  local pending = {}
  local queue_dir = os.getenv("HOME") .. "/.claude-pending"

  -- List files in queue directory
  local handle = io.popen("ls -1 " .. queue_dir .. " 2>/dev/null")
  if handle then
    for file in handle:lines() do
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
    handle:close()
  end

  return pending
end

-- Core update logic (called after debounce check)
local function do_update_workspaces()
  -- Get pending Claude events
  local claude_pending = get_pending_by_workspace()

  -- Get occupied workspaces and focused workspace
  local occupied = {}
  local focused_ws = nil

  -- Get occupied workspaces on focused monitor (with timeout)
  local occupied_output = safe_exec("aerospace list-workspaces --monitor focused --empty no", 2)
  for line in occupied_output:gmatch("[^\n]+") do
    local ws_num = tonumber(line)
    if ws_num then
      occupied[ws_num] = true
    end
  end

  -- Get focused workspace (with timeout)
  local focused_output = safe_exec("aerospace list-workspaces --focused", 2)
  focused_ws = tonumber(focused_output:match("%d+"))

  -- Add focused workspace to occupied list
  if focused_ws then
    occupied[focused_ws] = true
  end

  -- Cache for app lists (avoid duplicate queries)
  local workspace_apps_cache = {}

  -- Update each space
  for i = 1, max_spaces do
    local is_occupied = occupied[i] ~= nil
    local is_focused = (i == focused_ws)

    -- Show/hide based on occupancy
    spaces[i]:set({ drawing = is_occupied })
    space_brackets[i]:set({ drawing = is_occupied })

    if is_occupied then
      -- Check for pending Claude in this workspace
      local pending_info = claude_pending[i]
      local badge = ""
      local badge_color = colors.white

      if pending_info and pending_info.count > 0 then
        if pending_info.has_question then
          badge = " 󰂞"  -- Question needs attention
          badge_color = colors.red or 0xfff7768e
        else
          badge = " ●"  -- Completed
          badge_color = colors.green or 0xff9ece6a
        end
      end

      -- Update selection state with animation
      sbar.animate("tanh", 10, function()
        spaces[i]:set({
          icon = {
            highlight = is_focused,
            string = i .. badge,
          },
          label = { highlight = is_focused },
          background = { border_color = is_focused and colors.black or colors.bg2 }
        })
        space_brackets[i]:set({
          background = { border_color = is_focused and colors.grey or colors.bg2 }
        })
      end)

      -- Get apps for this workspace (with timeout, using cache)
      if not workspace_apps_cache[i] then
        workspace_apps_cache[i] = safe_exec("aerospace list-windows --workspace " .. i .. " --format '%{app-name}'", 2)
      end

      local icon_line = ""
      local has_apps = false

      -- Count each app
      local app_count = {}
      local apps_content = workspace_apps_cache[i] or ""
      for app in apps_content:gmatch("[^\n]+") do
        if app and app ~= "" then
          has_apps = true
          app_count[app] = (app_count[app] or 0) + 1
        end
      end

      -- Build icon string
      for app, _ in pairs(app_count) do
        local lookup = app_icons[app]
        local icon = lookup or app_icons["default"] or "?"
        icon_line = icon_line .. icon .. " "
      end

      if not has_apps then
        icon_line = " —"
      end

      -- Update label with animation
      sbar.animate("tanh", 10, function()
        spaces[i]:set({ label = { string = icon_line } })
      end)
    end
  end
end

-- Debounced wrapper to prevent trigger flooding
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

-- Subscribe to aerospace workspace change event
space_window_observer:subscribe("aerospace_workspace_change", function(env)
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

-- Spaces indicator animations
spaces_indicator:subscribe("mouse.entered", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 1.0 },
        border_color = { alpha = 1.0 },
      },
      icon = { color = colors.bg1 },
      label = { width = "dynamic" }
    })
  end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 0.0 },
        border_color = { alpha = 0.0 },
      },
      icon = { color = colors.grey },
      label = { width = 0 }
    })
  end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)

-- Initial update
update_workspaces()