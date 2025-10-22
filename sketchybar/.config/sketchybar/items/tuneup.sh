#!/bin/bash
# TuneUp - Audio Profile Indicator

# TuneUp profile indicator with toggle
sketchybar --add event tuneup_profile_change \
           --add item tuneup right \
           --set tuneup script="$CONFIG_DIR/plugins/tuneup.sh" \
                update_freq=0 \
                icon.font="Hack Nerd Font:Regular:16.0" \
                icon.color=0xff7aa2f7 \
                icon="🎵" \
                label.font="SF Pro:Semibold:12.0" \
                label.color=0xffcdd6f4 \
                label.drawing=on \
                label="Normal" \
                label.padding_left=4 \
                label.padding_right=8 \
                background.drawing=off \
                padding_right=8 \
                click_script="hs -c 'tuneup.toggleProfile()'" \
                --subscribe tuneup tuneup_profile_change

# Initialize TuneUp on startup
sketchybar --trigger tuneup_profile_change
