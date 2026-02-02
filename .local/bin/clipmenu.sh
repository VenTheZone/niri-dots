#!/bin/bash
# Clipboard manager with Clear All option

CLEAR_STR="󰃢  Clear All History"
# Prepend the clear option to the list
selected=$(printf "$CLEAR_STR\n$(cliphist list)" | fuzzel --dmenu --prompt="󰅌 ")

if [ "$selected" == "$CLEAR_STR" ]; then
    cliphist wipe
    notify-send "Clipboard" "History cleared"
elif [ -n "$selected" ]; then
    echo "$selected" | cliphist decode | wl-copy
fi
