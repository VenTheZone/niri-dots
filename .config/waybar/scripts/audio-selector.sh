#!/bin/bash
# Unified audio selector for waybar - handles both speakers and microphones

get_default_sink_name() {
    pactl info | grep "Default Sink:" | cut -d: -f2 | xargs
}

get_default_source_name() {
    pactl info | grep "Default Source:" | cut -d: -f2 | xargs
}

# Get description for a sink by name
get_sink_desc() {
    local name="$1"
    pactl list sinks | awk -v n="$name" '
        /^Name:/{found=0}
        $2==n{found=1}
        found && /^\s*Description:/{sub(/^\s*Description: /, ""); print; exit}
    '
}

# Get description for a source by name  
get_source_desc() {
    local name="$1"
    pactl list sources | awk -v n="$name" '
        /^Name:/{found=0}
        $2==n{found=1}
        found && /^\s*Description:/{sub(/^\s*Description: /, ""); print; exit}
    '
}

show_audio_menu() {
    local current_sink_name current_source_name
    current_sink_name=$(get_default_sink_name)
    current_source_name=$(get_default_source_name)

    local menu="󰓃 SPEAKERS (Output)\n"

    # Get sinks
    local sinks_short
    sinks_short=$(pactl list sinks short | awk '{print $2}')
    
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        local desc
        desc=$(get_sink_desc "$name")
        [ -z "$desc" ] && desc="$name"
        
        if [ "$name" = "$current_sink_name" ]; then
            menu="${menu}→ $desc\n"
        else
            menu="${menu}  $desc\n"
        fi
    done <<< "$sinks_short"

    menu="${menu}─────────────────\n"
    menu="${menu}󰍬 MICROPHONES (Input)\n"

    # Get sources (exclude monitors)
    local sources_short
    sources_short=$(pactl list sources short | grep -v "\.monitor" | awk '{print $2}')
    
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        local desc
        desc=$(get_source_desc "$name")
        [ -z "$desc" ] && desc="$name"
        
        if [ "$name" = "$current_source_name" ]; then
            menu="${menu}→ $desc\n"
        else
            menu="${menu}  $desc\n"
        fi
    done <<< "$sources_short"

    # Show menu
    local choice
    choice=$(echo -e "$menu" | fuzzel --dmenu --prompt="Audio: " --lines=15 --width=50)
    [ -z "$choice" ] && return

    # Clean up selection
    choice=$(echo "$choice" | sed 's/^[→ ]*//')
    [[ "$choice" =~ ^(󰓃|󰍬|─) ]] && return

    # Find and switch sink
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        local desc
        desc=$(get_sink_desc "$name")
        [ -z "$desc" ] && desc="$name"
        if [ "$desc" = "$choice" ]; then
            pactl set-default-sink "$name"
            notify-send "Audio" "Switched to: $choice"
            return
        fi
    done <<< "$sinks_short"

    # Find and switch source
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        local desc
        desc=$(get_source_desc "$name")
        [ -z "$desc" ] && desc="$name"
        if [ "$desc" = "$choice" ]; then
            pactl set-default-source "$name"
            notify-send "Audio" "Switched to: $choice"
            return
        fi
    done <<< "$sources_short"
}

toggle_mute() {
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED"; then
        notify-send "Audio" "Speakers muted"
    else
        notify-send "Audio" "Speakers unmuted"
    fi
}

get_volume() {
    local vol_line
    vol_line=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
    if [[ "$vol_line" =~ Volume:\ ([0-9])\.([0-9]+) ]]; then
        local integer="${BASH_REMATCH[1]}"
        local decimal="${BASH_REMATCH[2]}"
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
    menu)
        show_audio_menu
        ;;
    toggle)
        toggle_mute
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
