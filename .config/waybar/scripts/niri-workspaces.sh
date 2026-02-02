#!/bin/bash
# Simple Niri workspace indicator for Waybar

workspaces=$(niri msg workspaces 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$workspaces" ]; then
    echo "1 2 3"
    exit 0
fi

output=""
while IFS= read -r line; do
    if echo "$line" | grep -q '^\s*\*\s*[0-9]'; then
        ws_num=$(echo "$line" | sed 's/^[^0-9]*//; s/[^0-9].*$//')
        [ -n "$ws_num" ] && output="${output} [${ws_num}]"
    elif echo "$line" | grep -q '^\s*[0-9]\+\s*$'; then
        ws_num=$(echo "$line" | sed 's/[^0-9]//g')
        [ -n "$ws_num" ] && output="${output} ${ws_num}"
    fi
done <<< "$workspaces"

echo "$output" | sed 's/^ *//'
