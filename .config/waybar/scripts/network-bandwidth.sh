#!/bin/bash
# Custom network module with bandwidth monitoring for waybar
# Outputs JSON for waybar consumption

INTERFACE="${1:-wlan0}"

# Get current connection info
get_connection_info() {
    local conn_info
    conn_info=$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep "^[^:]*:802-11-wireless$" | head -1)
    echo "${conn_info%%:*}"
}

# Get signal strength
get_signal() {
    local signal
    signal=$(nmcli -t -f ACTIVE,SIGNAL device wifi list 2>/dev/null | grep "^yes:" | cut -d: -f2)
    echo "${signal:-0}"
}

# Get frequency (band) using nmcli
get_freq() {
    local freq
    freq=$(nmcli -t -f ACTIVE,FREQ device wifi list 2>/dev/null | grep "^yes:" | cut -d: -f2)
    echo "${freq:-0}"
}

# Get IP address
get_ip() {
    local ip
    ip=$(ip -4 addr show "$INTERFACE" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    echo "${ip:-N/A}"
}

# Read bytes from interface
read_bytes() {
    cat "/sys/class/net/$INTERFACE/statistics/rx_bytes" 2>/dev/null || echo 0
    cat "/sys/class/net/$INTERFACE/statistics/tx_bytes" 2>/dev/null || echo 0
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(echo "scale=1; $bytes/1024" | bc)K"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(echo "scale=1; $bytes/1048576" | bc)M"
    else
        echo "$(echo "scale=1; $bytes/1073741824" | bc)G"
    fi
}

# Calculate bandwidth
 calculate_bandwidth() {
    local rx1=$1
    local tx1=$2
    sleep 1
    local rx2 tx2 rx_rate tx_rate
    read -r rx2 tx2 <<< "$(read_bytes)"
    
    rx_rate=$((rx2 - rx1))
    tx_rate=$((tx2 - tx1))
    
    echo "$(format_bytes $rx_rate) $(format_bytes $tx_rate)"
}

# Main output
main() {
    local essid signal freq ip rx tx
    
    essid=$(get_connection_info)
    
    if [ -z "$essid" ] || [ "$essid" = "--" ]; then
        echo '{"text": " 󰈀 Disconnected ", "tooltip": "No WiFi connection", "class": "disconnected"}'
        return
    fi
    
    signal=$(get_signal)
    freq=$(get_freq)
    ip=$(get_ip)
    
    # Determine band from frequency (strip MHz if present)
    local band="?"
    local freq_num=$(echo "$freq" | grep -oP '^\d+' | head -1)
    if [ -n "$freq_num" ] && [ "$freq_num" -gt 0 ]; then
        if [ "$freq_num" -lt 3000 ]; then
            band="2.4G"
        else
            band="5G"
        fi
    fi
    
    # Calculate bandwidth (one-second sample)
    read -r rx tx <<< "$(read_bytes)"
    sleep 1
    local rx2 tx2 rx_rate tx_rate
    read -r rx2 tx2 <<< "$(read_bytes)"
    rx_rate=$((rx2 - rx1))
    tx_rate=$((tx2 - tx1))
    
    local down up
    down=$(format_bytes $rx_rate)
    up=$(format_bytes $tx_rate)
    
    # Build tooltip
    local tooltip="${essid} [${band}]\n"
    tooltip+="Signal: ${signal}%\n"
    tooltip+="IP: ${ip}\n"
    tooltip+="Download: ${down}/s\n"
    tooltip+="Upload: ${up}/s\n"
    tooltip+="Frequency: ${freq}"
    
    # Choose icon based on signal
    local icon="󰈀"
    if [ "$signal" -ge 75 ]; then
        icon="󰤨"
    elif [ "$signal" -ge 50 ]; then
        icon="󰤥"
    elif [ "$signal" -ge 25 ]; then
        icon="󰤢"
    else
        icon="󰤟"
    fi
    
    echo "{\"text\": \" ${icon} ${essid} ${signal}% \", \"tooltip\": \"${tooltip}\", \"class\": \"connected\"}"
}

# Run continuously for waybar
while true; do
    main
    sleep 2
done
