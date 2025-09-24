local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local spotify = sbar.add("item", "spotify", {
  position = "right",
  update_freq = 2,  -- Poll every 2 seconds
  icon = {
    font = {
      family = settings.font.symbols,
      size = 19.0
    },
    string = "",
    color = colors.green,
  },
  label = {
    drawing = false,
    padding_left = 8,
  },
  background = {
    color = colors.transparent,
    height = 20,
  },
  padding_right = 10,
  drawing = false,
})

spotify:subscribe({"routine", "forced"}, function(env)
  -- Check if Spotify is running
  local app_state = sbar.exec("pgrep -x Spotify")

  if app_state ~= "" then
    -- Get playback state
    local state = sbar.exec("osascript -e 'tell application \"Spotify\" to player state as string'")

    if state:match("playing") then
      local track = sbar.exec("osascript -e 'tell application \"Spotify\" to name of current track as string'")
      local artist = sbar.exec("osascript -e 'tell application \"Spotify\" to artist of current track as string'")

      -- Clean up strings
      track = track:gsub("\n", "")
      artist = artist:gsub("\n", "")

      -- Truncate if too long
      if string.len(track) > 20 then
        track = string.sub(track, 1, 20) .. "..."
      end
      if string.len(artist) > 20 then
        artist = string.sub(artist, 1, 20) .. "..."
      end

      spotify:set({
        drawing = true,
        label = {
          drawing = true,
          string = artist .. " - " .. track
        }
      })
    else
      spotify:set({ drawing = false })
    end
  else
    spotify:set({ drawing = false })
  end
end)

-- Click to play/pause
spotify:subscribe("mouse.clicked", function(env)
  sbar.exec("osascript -e 'tell application \"Spotify\" to playpause'")
end)