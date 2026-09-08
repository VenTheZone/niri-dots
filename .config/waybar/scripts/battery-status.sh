#!/bin/bash
# Battery status for waybar custom/battery (Cyberpunk 2077 thresholds)
# >50% green, 20-50% yellow, <20% red

bat=$(upower -e 2>/dev/null | grep -m1 BAT)
if [ -z "$bat" ]; then
    echo '{"text":"","class":"ok"}'
    exit 0
fi

info=$(upower -i "$bat")
pct=$(echo "$info" | awk -F': *' '/^ *percentage:/ {print int($2); exit}')
state=$(echo "$info" | awk -F': *' '/^ *state:/ {print $2; exit}')

if [ -z "$pct" ]; then
    echo '{"text":"","class":"ok"}'
    exit 0
fi

if [ "$state" = "charging" ] || [ "$state" = "fully-charged" ]; then
    icon="󰂄"
    cls="ok"
elif [ "$pct" -lt 20 ]; then
    icon="󰂃"
    cls="crit"
elif [ "$pct" -lt 50 ]; then
    icon="󰁼"
    cls="warn"
else
    icon="󰁹"
    cls="ok"
fi

printf '{"text":"%s %d%%","class":"%s"}\n' "$icon" "$pct" "$cls"
