#!/bin/bash

# Detect which compositor is running
if [ "$XDG_CURRENT_DESKTOP" = "Niri" ] || pgrep -x "niri" > /dev/null 2>&1; then
    # Use Niri workspaces
    WORKSPACE_MODULE="niri/workspaces"
    WORKSPACE_CONFIG='"niri/workspaces": {
        "all-outputs": true,
        "format": "{name}",
        "on-click": "activate"
    }'
else
    # Use Hyprland workspaces
    WORKSPACE_MODULE="hyprland/workspaces"
    WORKSPACE_CONFIG='"hyprland/workspaces": {
        "all-outputs": true,
        "format": "{name}",
        "on-click": "activate"
    }'
fi

# Generate config from template
TEMPLATE="$HOME/.config/waybar/config.template"
OUTPUT="$HOME/.config/waybar/config"

# Replace placeholders
sed -e "s/WORKSPACE_MODULE/$WORKSPACE_MODULE/g" \
    -e "s|\"WORKSPACE_MODULE_CONFIG\"|$WORKSPACE_CONFIG|g" \
    "$TEMPLATE" > "$OUTPUT"

# Launch waybar
exec waybar -c "$OUTPUT" -s "$HOME/.config/waybar/style.css"
