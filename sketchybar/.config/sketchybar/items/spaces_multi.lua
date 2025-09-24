local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_brackets = {}
local max_spaces = 10

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
      background = {
        color = colors.bg1,
        border_width = 1,
        height = 26,
        border_color = colors.black,
      },
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

-- Function to update workspace visibility and app icons
local function update_workspaces()
  -- Get focused workspace
  local focused_ws = nil
  os.execute("aerospace list-workspaces --focused > /tmp/focused_ws.txt")
  local f = io.open("/tmp/focused_ws.txt", "r")
  if f then
    local focused_output = f:read("*a")
    focused_ws = tonumber(focused_output:match("%d+"))
    f:close()
  end

  -- Update workspaces for each display
  for display = 1, 2 do
    local workspace_states = {}

    -- Get all workspaces that exist on this monitor
    os.execute("aerospace list-workspaces --monitor " .. display .. " > /tmp/occupied_ws_" .. display .. ".txt")
    local f = io.open("/tmp/occupied_ws_" .. display .. ".txt", "r")
    if f then
      for line in f:lines() do
        local ws_num = tonumber(line)
        if ws_num then
          workspace_states[ws_num] = { exists = true, has_windows = false }
        end
      end
      f:close()
    end

    -- Check which workspaces actually have windows
    for ws_num, _ in pairs(workspace_states) do
      os.execute("aerospace list-windows --workspace " .. ws_num .. " --format '%{app-name}' > /tmp/ws_check_" .. ws_num .. ".txt 2>/dev/null")
      local check = io.open("/tmp/ws_check_" .. ws_num .. ".txt", "r")
      if check then
        local content = check:read("*a")
        if content and content:match("%S") then  -- Has non-whitespace content
          workspace_states[ws_num].has_windows = true
        end
        check:close()
      end
    end

    -- Update each space for this display
    for i = 1, max_spaces do
      local state = workspace_states[i]
      local is_focused = (i == focused_ws)
      -- Show if: has windows OR is currently focused
      local should_show = (state and state.has_windows) or is_focused

      -- Show/hide based on whether it should be shown
      if spaces[display] and spaces[display][i] then
        spaces[display][i]:set({ drawing = should_show })
        space_brackets[display][i]:set({ drawing = should_show })

        if should_show then
          -- Update selection state with animation
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

          -- Get apps for this specific workspace (reuse the file we already created)
          local icon_line = ""
          local has_apps = false

          -- Count each app
          local app_count = {}
          local apps_file = io.open("/tmp/ws_check_" .. i .. ".txt", "r")
          if apps_file then
            for app in apps_file:lines() do
              if app and app ~= "" then
                has_apps = true
                app_count[app] = (app_count[app] or 0) + 1
              end
            end
            apps_file:close()
          end

          -- Build icon string
          for app, _ in pairs(app_count) do
            local lookup = app_icons[app]
            local icon = lookup or app_icons["default"] or "?"
            icon_line = icon_line .. icon .. " "
          end

          -- Only show dash for focused empty workspace
          if not has_apps and is_focused then
            icon_line = " —"
          end

          -- Update label with animation
          sbar.animate("tanh", 10, function()
            spaces[display][i]:set({ label = { string = icon_line } })
          end)
        end
      end
    end
  end
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

-- Initial update
update_workspaces()