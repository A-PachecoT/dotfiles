-- Media Controller
-- Business logic for media player (Spotify, Music, etc.)
-- Pure logic, no UI manipulation

local MediaController = {
  -- Whitelist of supported media apps
  whitelist = {
    ["Spotify"] = true,
    ["Music"] = true,
  },
}

-- Check if app is whitelisted
function MediaController.is_supported(app_name)
  return MediaController.whitelist[app_name] == true
end

-- Transform playback state change event into UI data
function MediaController.on_playback_changed(env_info)
  -- Validate app is supported
  if not MediaController.is_supported(env_info.app) then
    return nil
  end

  -- Transform event data into UI-friendly format
  local is_playing = (env_info.state == "playing")

  return {
    is_playing = is_playing,
    should_draw = is_playing,
    artist = env_info.artist or "Unknown Artist",
    title = env_info.title or "Unknown Title",
    album = env_info.album or "",
    app = env_info.app,
  }
end

-- Calculate if media should show detailed view
function MediaController.should_show_details(interrupt_count)
  return interrupt_count > 0
end

-- Get animation timing for detail view
function MediaController.get_detail_animation_config()
  return {
    timing_function = "tanh",
    duration = 30,
    delay = 5, -- seconds to auto-hide after showing
  }
end

return MediaController
