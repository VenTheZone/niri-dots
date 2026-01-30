#!/bin/bash

# Detect which compositor is running
if [ "$XDG_CURRENT_DESKTOP" = "Niri" ] || pgrep -x "niri" > /dev/null 2>&1; then
    WORKSPACE_MODULE="niri/workspaces"
else
    WORKSPACE_MODULE="hyprland/workspaces"
fi

# Generate config
OUTPUT="$HOME/.config/waybar/config"

# Create the config file
cat > "$OUTPUT" << EOF
{
    "layer": "top",
    "position": "top",
    "height": 40,
    "width": "auto",
    "spacing": 8,
    "margin-top": 8,
    "margin-left": 12,
    "margin-right": 12,

    "modules-left": ["custom/launcher", "$WORKSPACE_MODULE", "custom/media"],
    "modules-center": ["clock"],
    "modules-right": ["tray", "cpu", "memory", "upower", "custom/power"],

    "custom/launcher": {
        "format": " 󰣇 ",
        "on-click": "fuzzel",
        "tooltip": false
    },

    "custom/power": {
        "format": " 󰐥 ",
        "on-click": "sh -c $HOME/.local/bin/powermenu",
        "tooltip": false
    },

    "$WORKSPACE_MODULE": {
        "all-outputs": true,
        "format": "{name}",
        "on-click": "activate"
    },

    "custom/media": {
        "format": " 󰝚 {} ",
        "max-length": 35,
        "interval": 2,
        "exec": "playerctl -a metadata --format '{{title}}' 2>/dev/null || echo 'No Media'",
        "on-click": "playerctl play-pause"
    },

    "clock": {
        "format": " 󱑎 {:%I:%M %p  󰃭 %a, %b %d} ",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
        "interval": 1,
        "locale": "C.utf8"
    },

    "cpu": {
        "format": " {usage}%",
        "interval": 2,
        "tooltip": true,
        "tooltip-format": "CPU Usage: {usage}%\\nLoad: {load}"
    },

    "memory": {
        "format": " {used:0.1f}G/{total:0.1f}G ({percentage}%)",
        "interval": 2,
        "tooltip": true,
        "tooltip-format": "RAM: {used:0.1f}GB / {total:0.1f}GB\\nSwap: {swapUsed:0.1f}GB / {swapTotal:0.1f}GB"
    },

    "upower": {
        "show-icon": false,
        "format": "  {percentage}% ",
        "interval": 30
    },

    "tray": {
        "icon-size": 18,
        "spacing": 10
    }
}
EOF

# Launch waybar
exec waybar -c "$OUTPUT" -s "$HOME/.config/waybar/style.css"
