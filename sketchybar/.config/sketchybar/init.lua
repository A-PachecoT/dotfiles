-- Require the sketchybar module
sbar = require("sketchybar")

-- Set the bar name, if you are using another bar instance than sketchybar
-- sbar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
sbar.begin_config()
-- Force drawing to be on
sbar.exec("sketchybar --bar drawing=on")

-- No need for custom providers - Spotify sends native notifications

require("bar")
require("default")
require("items")

-- Load shell-based Spotify plugin from community
sbar.exec("sketchybar --add event spotify_init")
sbar.exec("bash ~/.config/sketchybar/items/spotify.sh")
sbar.exec("sketchybar --trigger spotify_init")

sbar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
