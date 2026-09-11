#!/bin/bash
# Keyboard backlight control script for waybar/asusctl
# Usage: keyboard-backlight.sh [toggle|up|down|get]
# Also syncs aura static colour to battery tier (green/orange/red) on each poll.
# ponytail: static colour stomps any custom aura effect on tier change; kill
# sync_battery_color call if you want rainbow back.

BAT_CACHE=/tmp/kbd-battery-tier

sync_battery_color() {
    local cap tier ac
    cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
    [[ "$cap" =~ ^[0-9]+$ ]] || return
    ac=$(cat /sys/class/power_supply/AC0/online 2>/dev/null)
    if [ "$ac" = "1" ]; then tier="5ef6ff"   # plugged in: cyan
    elif [ "$cap" -gt 50 ]; then tier="00ff00"
    elif [ "$cap" -ge 20 ]; then tier="ff9900"
    else tier="ff0000"; fi
    if [ "$(cat "$BAT_CACHE" 2>/dev/null)" != "$tier" ]; then
        asusctl aura effect static -c "$tier" >/dev/null 2>&1
        echo "$tier" > "$BAT_CACHE"
    fi
}

get_brightness() {
    # asusctl leds get returns "Current keyboard led brightness: <Off|Low|Med|High>"
    case "$(asusctl leds get 2>/dev/null)" in
        *High*) echo 3 ;;
        *Med*)  echo 2 ;;
        *Low*)  echo 1 ;;
        *)      echo 0 ;;
    esac
}

case "$1" in
    toggle)
        current=$(get_brightness)
        if [ "$current" = "0" ]; then
            asusctl leds set low >/dev/null 2>&1
        else
            asusctl leds set off >/dev/null 2>&1
        fi
        ;;
    up)
        asusctl leds next >/dev/null 2>&1
        ;;
    down)
        asusctl leds prev >/dev/null 2>&1
        ;;
    get|"")
        sync_battery_color
        brightness=$(get_brightness)
        # Output JSON for waybar
        if [ "$brightness" = "0" ]; then
            echo '{"text": " 󰌌 ", "tooltip": "Keyboard backlight: OFF", "class": "off"}'
        else
            echo "{\"text\": \" 󰌌 ${brightness}\", \"tooltip\": \"Keyboard backlight: ${brightness}/3\", \"class\": \"on\"}"
        fi
        ;;
esac
