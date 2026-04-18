#!/bin/bash

CPU_PERCENT=$(top -l 1 | grep -E "^CPU" | grep -o '[0-9.]*%' | head -1)
sketchybar --set "$NAME" label="$CPU_PERCENT"