#!/bin/bash
# Work Session Indicator

PLUGIN_DIR="$CONFIG_DIR/plugins"

# Work session indicator (moon icon when active)
sketchybar --add item work_session right \
           --set work_session script="$PLUGIN_DIR/work_session.sh" \
                update_freq=60 \
                drawing=off \
                position=right