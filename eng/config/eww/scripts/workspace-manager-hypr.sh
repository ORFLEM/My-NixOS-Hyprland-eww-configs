#!/bin/sh
# ~/bar/scripts/workspace-manager-hypr-nodaemon.sh
# Максимально оптимизированный скрипт без демона для мгновенного обновления

# Лог-файл
LOG_FILE="$HOME/workspace-listener.log"

# Настраиваемые иконки
: "${ICON_ACTIVE:=}"
: "${ICON_URGENT:=}"
: "${ICON_OCCUPIED:=}"
: "${ICON_EMPTY:=}"

# Функция логирования (минимизирована для скорости)
log() {
:
    #[[ "${DEBUG:-0}" -eq 1 ]] && echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" >> "$LOG_FILE"
    #truncate -s 10M "$LOG_FILE" 2>/dev/null
}

# Функция получения данных о воркспейсах
get_workspace_data() {
    local active_ws existing_ws
    # Один вызов hyprctl для всех данных
    local hypr_data=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | .activeWorkspace.id')
    active_ws=${hypr_data:-1}
    log "Debug: Active workspace: '$active_ws'"
    
    # Получаем существующие воркспейсы
    existing_ws=$(hyprctl -j workspaces 2>/dev/null | jq -r '[.[] | .id] | join(",")')
    existing_ws=${existing_ws:-$active_ws}
    log "Debug: Existing workspaces: '$existing_ws'"
    
    # Urgent отключаем для скорости, включается через USE_URGENT=1
    local urgent_ws=""
    if [[ "${USE_URGENT:-0}" -eq 1 && -x "$(command -v jq)" ]]; then
        urgent_ws=$(hyprctl -j clients 2>/dev/null | jq -r --arg active "$active_ws" '[.[] | select(.workspace.id != ($active | tonumber) and (.urgency == true or (.title // "" | test("telegram|discord|signal|thunderbird|steam"; "i")))) | .workspace.id] | unique | join(",")' 2>/dev/null || echo "")
        log "Debug: Urgent workspaces: '$urgent_ws'"
    fi
    
    echo "$active_ws:$urgent_ws:$existing_ws"
}

# Динамическое определение количества воркспейсов
get_max_workspaces() {
    local ws_count=$(hyprctl -j workspaces 2>/dev/null | jq -r '[.[] | .id] | length')
    ws_count=$(( ws_count > 0 ? ws_count : 10 ))
    ws_count=$(( ws_count < 10 ? 10 : ws_count ))
    log "Debug: Max workspaces: $ws_count"
    echo "$ws_count"
}

# Функция определения состояния и иконки для воркспейса
get_workspace_state() {
    local id=$1
    local active=$2
    local urgent=$3
    local existing=$4
    
    log "Debug: Checking WS$id: active='$active', urgent='$urgent', existing='$existing'"
    
    if [[ "$id" == "$active" ]]; then
        echo "active:$ICON_ACTIVE"
    elif [[ -n "$urgent" && "$urgent" == *"$id"* ]]; then
        echo "urgent:$ICON_URGENT"
    elif [[ -n "$existing" && "$existing" == *"$id"* ]]; then
        echo "occupied:$ICON_OCCUPIED"
    else
        echo "empty:$ICON_EMPTY"
    fi
}

# Глобальные переменные для кэширования
declare -A WORKSPACE_STATES
declare -A WORKSPACE_ICONS
LAST_UPDATE=0
LAST_ACTIVE=""
LAST_URGENT=""
LAST_EXISTING=""

# Функция обновления всех воркспейсов
update_all_workspaces() {
    local current_time=$(date +%s%N)
    
    # Получаем данные
    IFS=':' read -r active urgent existing < <(get_workspace_data)
    
    # Пропускаем обновление, если данные не изменились
    if [[ "$active:$urgent:$existing" == "$LAST_ACTIVE:$LAST_URGENT:$LAST_EXISTING" && $(( (current_time - LAST_UPDATE) / 1000000 )) -lt 50 ]]; then
        log "Debug: No changes in workspace data, skipping update"
        return 0
    fi
    
    local max_ws=$(get_max_workspaces)
    log "Debug: Updating all workspaces (max_ws=$max_ws)"
    
    # Обновляем кэш
    for ((id=1; id<=max_ws; id++)); do
        local state=$(get_workspace_state "$id" "$active" "$urgent" "$existing")
        WORKSPACE_STATES[$id]="${state%%:*}"
        WORKSPACE_ICONS[$id]="${state#*:}"
        log "Debug: WS$id: ${WORKSPACE_STATES[$id]} (${WORKSPACE_ICONS[$id]})"
    done
    
    LAST_ACTIVE="$active"
    LAST_URGENT="$urgent"
    LAST_EXISTING="$existing"
    LAST_UPDATE=$current_time
}

# Функция генерации JSON (оптимизирована)
generate_workspaces_json() {
    local max_ws=$(get_max_workspaces)
    local json="{\"ws1\":{\"class\":\"${WORKSPACE_STATES[1]:-empty}\",\"icon\":\"${WORKSPACE_ICONS[1]:-$ICON_EMPTY}\"}"
    for ((id=2; id<=max_ws; id++)); do
        json+=",\"ws$id\":{\"class\":\"${WORKSPACE_STATES[$id]:-empty}\",\"icon\":\"${WORKSPACE_ICONS[$id]:-$ICON_EMPTY}\"}"
    done
    json+="}"
    echo "$json"
}

# Функция для потокового вывода JSON
stream_workspaces_json() {
    log "Starting JSON stream (no daemon)"
    while true; do
        update_all_workspaces
        generate_workspaces_json
        sleep 0.05
    done
}

# Основная логика
case "$1" in
    "status")
        echo "=== WORKSPACE DATA ==="
        IFS=':' read -r active urgent existing < <(get_workspace_data)
        echo "Active: $active"
        echo "Urgent: $urgent"
        echo "Existing: $existing"
        
        echo ""
        echo "=== WORKSPACE STATES ==="
        update_all_workspaces
        max_ws=$(get_max_workspaces)
        for ((id=1; id<=max_ws; id++)); do
            echo "WS$id: ${WORKSPACE_STATES[$id]:-empty} (${WORKSPACE_ICONS[$id]:-$ICON_EMPTY})"
        done
        ;;
    "stream-workspaces-json")
        stream_workspaces_json
        ;;
    "get-workspace-state")
        id=$2
        [[ -z "$id" ]] && { echo "empty"; exit 0; }
        update_all_workspaces
        echo "${WORKSPACE_STATES[$id]:-empty}"
        ;;
    "get-workspace-icon")
        id=$2
        [[ -z "$id" ]] && { echo "$ICON_EMPTY"; exit 0; }
        update_all_workspaces
        echo "${WORKSPACE_ICONS[$id]:-$ICON_EMPTY}"
        ;;
    "switch-workspace")
        [[ -n "$2" ]] && hyprctl dispatch workspace "$2" >/dev/null 2>&1
        ;;
    "debug")
        id=${2:-1}
        echo "=== DEBUG INFO ==="
        echo "Workspace ID: $id"
        IFS=':' read -r active urgent existing < <(get_workspace_data)
        echo "Active: $active"
        echo "Urgent: $urgent"
        echo "Existing: $existing"
        echo "Log file: $LOG_FILE"
        update_all_workspaces
        echo "Sample JSON: $(generate_workspaces_json)"
        if [[ -n "${WORKSPACE_STATES[$id]}" ]]; then
            echo "Cached state: ${WORKSPACE_STATES[$id]}"
            echo "Cached icon: ${WORKSPACE_ICONS[$id]}"
        fi
        ;;
    *)
        echo "Usage: $0 {status|stream-workspaces-json|get-workspace-state|get-workspace-icon|switch-workspace|debug} [workspace_id]"
        exit 1
        ;;
esac


