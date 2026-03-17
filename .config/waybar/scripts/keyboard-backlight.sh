#!/bin/bash
# Keyboard backlight control script for waybar/asusctl
# Usage: keyboard-backlight.sh [toggle|up|down|get]

get_brightness() {
    # asusctl -k returns something like "Current keyboard brightness: 2"
    # or "Keyboard backlight is off"
    local output
    output=$(asusctl -k 2>/dev/null)
    if echo "$output" | grep -q "off"; then
        echo "0"
    else
        # Extract the number from "Current keyboard brightness: X"
        echo "$output" | grep -oP '\d+' | head -1
    fi
}

case "$1" in
    toggle)
        current=$(get_brightness)
        if [ "$current" = "0" ]; then
            asusctl -k 1 >/dev/null 2>&1
        else
            asusctl -k off >/dev/null 2>&1
        fi
        ;;
    up)
        asusctl -k up >/dev/null 2>&1
        ;;
    down)
        asusctl -k down >/dev/null 2>&1
        ;;
    get|"")
        brightness=$(get_brightness)
        # Output JSON for waybar
        if [ "$brightness" = "0" ]; then
            echo '{"text": " 󰌌 ", "tooltip": "Keyboard backlight: OFF", "class": "off"}'
        else
            echo "{\"text\": \" 󰌌 ${brightness}\", \"tooltip\": \"Keyboard backlight: ${brightness}/3\", \"class\": \"on\"}"
        fi
        ;;
esac
