#!/bin/bash
# Audio Mode Indicator (Speaker/Headphone)

# Audio mode indicator with toggle
sketchybar --add event audio_mode_change \
           --add item audio_mode right \
           --set audio_mode script="$CONFIG_DIR/plugins/audio_mode_event.sh" \
                update_freq=0 \
                icon.font="Hack Nerd Font:Regular:16.0" \
                icon.color=0xff7aa2f7 \
                icon="󰋋" \
                label.font="SF Pro:Semibold:12.0" \
                label.color=0xffcdd6f4 \
                label.drawing=on \
                label.width=0 \
                label.padding_left=0 \
                background.drawing=off \
                padding_right=8 \
                click_script="hs -c 'toggleAudioMode()'" \
                --subscribe audio_mode audio_mode_change mouse.entered mouse.exited

# Initialize audio mode on startup
sketchybar --trigger audio_mode_change