#!/bin/bash
# Clipboard manager with individual delete and clear all options

# Get the list of clipboard items
clip_list=$(cliphist list)

# If clipboard is empty, show message
if [ -z "$clip_list" ]; then
    notify-send "Clipboard" "History is empty"
    exit 0
fi

# Build menu with icons
# Format: ID<TAB>preview text
menu_items=""
while IFS= read -r line; do
    id=$(echo "$line" | cut -f1)
    preview=$(echo "$line" | cut -f2-)
    # Truncate preview if too long
    if [ ${#preview} -gt 60 ]; then
        preview="${preview:0:57}..."
    fi
    menu_items="${menu_items}󰆙 ${preview}\n"
done <<< "$clip_list"

# Add clear all option at the top
CLEAR_STR="󰃢  Clear All History"
menu_items="${CLEAR_STR}\n${menu_items}"

# Show menu
selected=$(printf "$menu_items" | fuzzel --dmenu --prompt="󰅌 " --lines 15)

# Handle selection
if [ "$selected" == "$CLEAR_STR" ]; then
    # Clear all history
    cliphist wipe
    rm -f "$HOME/.cache/cliphist/db"
    notify-send "Clipboard" "History cleared and counter reset"
elif [ -n "$selected" ]; then
    # Extract the preview text (remove icon)
    preview="${selected#󰆙 }"

    # Find the line in clipboard that matches this preview
    selected_line=$(echo "$clip_list" | grep -F "$preview" | head -n1)

    if [ -n "$selected_line" ]; then
        id=$(echo "$selected_line" | cut -f1)

        # Ask what to do with the selected item
        action=$(printf "󰆌 Copy\n󰆴 Delete" | fuzzel --dmenu --prompt="󰅌 " --lines 2)

        if [ "$action" == "󰆌 Copy" ]; then
            echo "$selected_line" | cliphist decode | wl-copy
            notify-send "Clipboard" "Copied to clipboard"
        elif [ "$action" == "󰆴 Delete" ]; then
            # Delete the specific item by ID
            echo "$id" | cliphist delete
            notify-send "Clipboard" "Item deleted"
        fi
    fi
fi
