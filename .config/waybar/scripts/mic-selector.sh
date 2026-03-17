#!/bin/bash
# Microphone selector and mute toggle for waybar

get_mic_info() {
    # Get default source (microphone)
    local source_name
    source_name=$(wpctl status | grep "Sources:" -A 5 | grep "\*" | sed 's/\*//' | awk '{$1=$1};1')
    
    if [ -z "$source_name" ]; then
        # Try pactl as fallback
        source_name=$(pactl info | grep "Default Source:" | cut -d: -f2 | xargs)
    fi
    
    echo "$source_name"
}

get_mic_volume() {
    local vol
    vol=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -oP '\d+\.\d+' | head -1)
    if [ -z "$vol" ]; then
        vol=$(pactl list sources | grep -A 5 "Name: $(pactl info | grep 'Default Source' | cut -d: -f2 | xargs)" | grep "Volume:" | head -1 | grep -oP '\d+%' | head -1 | tr -d '%')
        # Convert to decimal if needed
        if [ -n "$vol" ]; then
            vol=$(echo "scale=2; $vol/100" | bc)
        fi
    fi
    echo "${vol:-0}"
}

is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q "MUTED"
    return $?
}

show_mic_menu() {
    # Get list of sources
    local sources
    sources=$(pactl list sources short | awk '{print $2}' | grep -v "monitor")
    
    # Build menu
    local menu=""
    while IFS= read -r source; do
        [ -z "$source" ] && continue
        local desc
        desc=$(pactl list sources | grep -A 2 "Name: $source" | grep "Description:" | cut -d: -f2 | xargs)
        menu="$menu$desc\n"
    done <<< "$sources"
    
    # Show in fuzzel
    local choice
    choice=$(echo -e "$menu" | fuzzel --dmenu --prompt="🎤 Mic: " --lines=8)
    
    if [ -n "$choice" ]; then
        # Find source name from description
        local selected_source
        while IFS= read -r source; do
            [ -z "$source" ] && continue
            local desc
            desc=$(pactl list sources | grep -A 2 "Name: $source" | grep "Description:" | cut -d: -f2 | xargs)
            if [ "$desc" = "$choice" ]; then
                selected_source="$source"
                break
            fi
        done <<< "$sources"
        
        if [ -n "$selected_source" ]; then
            pactl set-default-source "$selected_source"
            notify-send "Microphone" "Switched to: $choice"
        fi
    fi
}

case "$1" in
    toggle)
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if is_muted; then
            notify-send "Microphone" "Muted"
        else
            notify-send "Microphone" "Unmuted"
        fi
        ;;
    up)
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.05+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.05-
        ;;
    menu)
        show_mic_menu
        ;;
    *)
        # Output for waybar
        local vol
        vol=$(get_mic_volume)
        local vol_percent
        vol_percent=$(echo "scale=0; $vol * 100 / 1" | bc 2>/dev/null || echo "0")
        
        local mic_info
        mic_info=$(get_mic_info)
        # Shorten name if too long
        if [ "${#mic_info}" -gt 20 ]; then
            mic_info="${mic_info:0:17}..."
        fi
        
        local icon="🎤"
        if is_muted; then
            icon="🎤❌"
            echo "{\"text\": \" $icon Muted \", \"tooltip\": \"Microphone: $mic_info\nClick to select mic\nRight-click to toggle mute\nScroll to adjust volume\", \"class\": \"muted\"}"
        else
            echo "{\"text\": \" $icon ${vol_percent}% \", \"tooltip\": \"Microphone: $mic_info\nClick to select mic\nRight-click to toggle mute\nScroll to adjust volume\", \"class\": \"active\"}"
        fi
        ;;
esac
