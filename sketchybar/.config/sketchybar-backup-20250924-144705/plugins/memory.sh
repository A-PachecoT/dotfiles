#!/bin/bash

MEMORY_PERCENT=$(memory_pressure | grep "System-wide memory free percentage:" | awk '{print 100-$5"%"}')
if [ -z "$MEMORY_PERCENT" ]; then
    MEMORY_PERCENT=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    MEMORY_PERCENT=$((100 - ($MEMORY_PERCENT * 4096 / 1024 / 1024 / 1024)))%
fi
sketchybar --set "$NAME" label="$MEMORY_PERCENT"