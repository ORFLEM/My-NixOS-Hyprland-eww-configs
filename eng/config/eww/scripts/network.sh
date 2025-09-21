#!/bin/bash

CACHE_FILE="/tmp/eww_network_cache"
CACHE_TIMEOUT=5  # секунды

get_network_info() {
    # Проверяем кэш
    if [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_TIMEOUT ]]; then
        cat "$CACHE_FILE"
        return
    fi
    
    # Получаем активный интерфейс
    local ifname
    ifname=$(ip route show default 2>/dev/null | awk 'NR==1{print $5}')
    
    if [[ -z "$ifname" ]]; then
        echo "Нет соединения" | tee "$CACHE_FILE"
        return
    fi
    
    # Получаем IP информацию
    local ip_info ipaddr cidr gwaddr
    ip_info=$(ip -4 addr show dev "$ifname" 2>/dev/null | awk '/inet / {print $2; exit}')
    ipaddr=${ip_info%/*}
    cidr=${ip_info#*/}
    gwaddr=$(ip route show default 2>/dev/null | awk 'NR==1{print $3}')
    
    local output="Интерфейс: ${ifname:-N/A}
IP: ${ipaddr:-N/A}/${cidr:-N/A}
Шлюз: ${gwaddr:-N/A}"
    
    # Для WiFi получаем дополнительную информацию
    if [[ -e "/sys/class/net/$ifname/wireless" ]]; then
        local essid signal_info
        essid=$(iw dev "$ifname" link 2>/dev/null | awk '/SSID/ {print $2}')
        signal_info=$(iw dev "$ifname" link 2>/dev/null | awk '/signal/ {print $2 " " $3}')
        
        output="Сеть: ${essid:-N/A}
Сигнал: ${signal_info:-N/A}
$output"
    fi
    
    echo "$output" | tee "$CACHE_FILE"
}

get_network_info
