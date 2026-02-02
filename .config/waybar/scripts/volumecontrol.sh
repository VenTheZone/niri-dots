#!/bin/bash
# Volume control script (silent - no notifications)
# Usage: volumecontrol.sh [up|down|mute]

case "$1" in
    up)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac
