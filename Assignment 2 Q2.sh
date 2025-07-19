#!/bin/bash

# ===== CONFIGURATION =====
REFRESH_RATE=60
LOG_FILE="system_anomalies.log"
SHOW_ALL_METRICS=1

# ===== COLORS =====
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m"

# ===== FUNCTIONS =====

draw_bar() {
    local percent=$1
    local length=20
    local filled=$((percent * length / 100))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="#"; done
    for ((i=filled; i<length; i++)); do bar+="."; done

    # Color logic
    if [ "$percent" -lt 50 ]; then
        color=$GREEN
    elif [ "$percent" -lt 80 ]; then
        color=$YELLOW
    else
        color=$RED
    fi
    echo -e "${color}${bar}${NC} ${percent}%"
}

get_cpu_usage() {
    local idle1 idle2 total1 total2
    read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    idle1=$idle
    total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
    sleep 0.5
    read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
    idle2=$idle
    total2=$((user + nice + system + idle + iowait + irq + softirq + steal))

    cpu_usage=$((100 * ( (total2 - total1) - (idle2 - idle1) ) / (total2 - total1) ))
    echo $cpu_usage
}

get_mem_usage() {
    read total used free shared buff cache available <<< $(free -m | awk '/Mem:/ {print $2, $3, $4, $5, $6, $7, $7}')
    percent=$((100 * (total - available) / total))
    echo $percent
}

get_disk_usage() {
    percent=$(df / | awk 'END {gsub("%", "", $5); print $5}')
    echo $percent
}

get_network_usage() {
    read rx1 tx1 < <(cat /sys/class/net/eth0/statistics/rx_bytes /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null || echo 0 0)
    sleep 0.5
    read rx2 tx2 < <(cat /sys/class/net/eth0/statistics/rx_bytes /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null || echo 0 0)
    rx_rate=$(((rx2 - rx1) * 2 / 1024))
    tx_rate=$(((tx2 - tx1) * 2 / 1024))
    echo "${rx_rate}KB/s ↓  ${tx_rate}KB/s ↑"
}

log_anomaly() {
    local metric=$1
    local value=$2
    echo "$(date) - Anomaly Detected: $metric = ${value}%" >> "$LOG_FILE"
}

handle_input() {
    read -rsn1 -t $REFRESH_RATE key
    case "$key" in
        q) clear; exit 0 ;;
        r) 
            echo -ne "\nEnter new refresh rate (in seconds): "
            read new_rate
            if [[ "$new_rate" =~ ^[0-9]+$ && "$new_rate" -gt 0 ]]; then
                REFRESH_RATE=$new_rate
            fi ;;
        f)
            SHOW_ALL_METRICS=$((1 - SHOW_ALL_METRICS))
            ;;
    esac
}

# ===== MAIN LOOP =====
while true; do
    clear
    echo -e "🔧 ${GREEN}System Health Monitor${NC} — Press [q] to quit, [r] to change rate, [f] to filter view"
    echo "Refresh rate: ${REFRESH_RATE}s"
    echo "------------------------------"

    cpu=$(get_cpu_usage)
    mem=$(get_mem_usage)
    disk=$(get_disk_usage)
    net=$(get_network_usage)

    echo -n "CPU Usage   : "; draw_bar $cpu
    echo -n "Memory Usage: "; draw_bar $mem
    if [ "$SHOW_ALL_METRICS" -eq 1 ]; then
        echo -n "Disk Usage  : "; draw_bar $disk
        echo "Network     : $net"
    fi

    # Anomaly detection
    [[ $cpu -gt 90 ]] && log_anomaly "CPU" "$cpu"
    [[ $mem -gt 90 ]] && log_anomaly "Memory" "$mem"
    [[ $disk -gt 90 ]] && log_anomaly "Disk" "$disk"

    echo "------------------------------"
    handle_input
done
