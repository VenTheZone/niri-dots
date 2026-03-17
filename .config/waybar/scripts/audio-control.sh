#!/bin/bash
# Fast audio control for waybar - optimized for responsiveness

get_volume() {
    local vol_line
    vol_line=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    # wpctl outputs: "Volume: 0.65" or "Volume: 1.00"
    if [[ "$vol_line" =~ Volume:\ ([0-9])\.([0-9]+) ]]; then
        local integer="${BASH_REMATCH[1]}"
        local decimal="${BASH_REMATCH[2]}"
        # 0.65 -> 65, 1.00 -> 100
        if [ "$integer" = "0" ]; then
            echo "$(( 10#$decimal ))"
        else
            echo "100"
        fi
    else
        echo "0"
    fi
}

is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED"
}

case "$1" in
    toggle)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    *)
        vol=$(get_volume)
        if is_muted; then
            echo '{"text": " 󰖁 Muted ", "tooltip": "Scroll ↑↓ Volume • Right-click Mute • Click Menu", "class": "muted"}'
        elif [ "$vol" -lt 30 ]; then
            echo "{\"text\": \" 󰕿 ${vol}% \", \"tooltip\": \"Scroll ↑↓ Volume • Right-click Mute • Click Menu\", \"class\": \"low\"}"
        elif [ "$vol" -lt 70 ]; then
            echo "{\"text\": \" 󰖀 ${vol}% \", \"tooltip\": \"Scroll ↑↓ Volume • Right-click Mute • Click Menu\", \"class\": \"medium\"}"
        else
            echo "{\"text\": \" 󰕾 ${vol}% \", \"tooltip\": \"Scroll ↑↓ Volume • Right-click Mute • Click Menu\", \"class\": \"high\"}"
        fi
        ;;
esac
