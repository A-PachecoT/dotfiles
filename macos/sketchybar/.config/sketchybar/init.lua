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

-- tk: la tarea de ahora + popup (reemplazó al widget de Spotify, 2026-10-05). SSOT: ~/dotfiles/docs/tk.md
-- Spotify sigue en items/spotify.sh por si se quiere volver.
sbar.exec("bash ~/.config/sketchybar/items/tk.sh")

-- Load shell-based audio mode indicator
sbar.exec("bash ~/.config/sketchybar/items/audio_mode.sh")

-- Load shell-based mic status indicator
sbar.exec("bash ~/.config/sketchybar/items/mic_status.sh")
-- Force initialization after short delay to ensure items are created
sbar.exec("bash -c 'sleep 1 && sketchybar --trigger tk_update' &")

sbar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
