#!/bin/bash
# ~/bar/scripts/workspace-manager-niri.sh
# Скрипт для работы с воркспейсами в niri

# Функция получения активного воркспейса
get_active_workspace() {
    # Niri использует idx вместо id, и может возвращать null для active
    niri msg --json workspaces | jq -r '.Ok[] | select(.is_active == true) | .idx' 2>/dev/null || echo "1"
}

# Функция получения всех существующих воркспейсов (с окнами)
get_existing_workspaces() {
    # Исправляем структуру JSON ответа
    niri msg --json workspaces | jq -r '.Ok[] | select(.windows > 0) | .idx' 2>/dev/null | tr '\n' ',' | sed 's/,$//'
}

# Функция получения urgent воркспейсов
get_urgent_workspaces() {
    local active=$(get_active_workspace)
    local urgent_workspaces=""
    
    # Получаем воркспейсы с окнами, исключая активный
    local workspaces=$(niri msg --json workspaces | jq -r '.Ok[] | select(.windows > 0 and .is_active == false) | .idx' 2>/dev/null)
    
    for ws in $workspaces; do
        # Проверяем окна в воркспейсе на urgent заголовки
        local urgent_windows=$(niri msg --json windows | jq -r --arg ws "$ws" '
            .Ok[] | select(
                .workspace_id == ($ws | tonumber) and 
                (.title // "" | test("telegram|discord|signal|thunderbird|steam|notification"; "i"))
            ) | .title
        ' 2>/dev/null)
        
        if [[ -n "$urgent_windows" ]]; then
            if [[ -z "$urgent_workspaces" ]]; then
                urgent_workspaces="$ws"
            else
                urgent_workspaces="$urgent_workspaces,$ws"
            fi
        fi
    done
    
    echo "$urgent_workspaces"
}

# Функция определения иконки и класса для воркспейса
get_workspace_state() {
    local id=$1
    local active=$2
    local urgent=$3
    local existing=$4
    
    # Активный воркспейс
    if [[ "$active" == "$id" ]]; then
        echo "active:  "
        return
    fi
    
    # Urgent воркспейс
    if [[ ",$urgent," =~ ",$id," ]]; then
        echo "urgent:󱈸"
        return
    fi
    
    # Существующий воркспейс (есть окна)
    if [[ ",$existing," =~ ",$id," ]]; then
        echo "occupied:"
        return
    fi
    
    # Пустой воркспейс
    echo "empty:"
}

# Функция генерации JSON для всех воркспейсов
generate_workspaces_json() {
    local active=$(get_active_workspace)
    local urgent=$(get_urgent_workspaces)
    local existing=$(get_existing_workspaces)
    
    echo "{"
    for id in {1..5}; do
        local state=$(get_workspace_state "$id" "$active" "$urgent" "$existing")
        local class=$(echo "$state" | cut -d: -f1)
        local icon=$(echo "$state" | cut -d: -f2)
        
        # Если иконка пустая, ставим fallback
        if [[ -z "$icon" ]]; then
            icon=""
        fi
        
        echo "  \"ws$id\": {\"class\": \"$class\", \"icon\": \"$icon\"}"
        if [[ $id -lt 5 ]]; then echo ","; fi
    done
    echo "}"
}

# Основная функция для deflisten
listen_mode() {
    # Отправляем начальное состояние
    generate_workspaces_json
    
    # Используем event-stream API нiri для реального времени
    if command -v niri >/dev/null 2>&1; then
        niri msg --json event-stream 2>/dev/null | while IFS= read -r line; do
            # Проверяем события изменения воркспейсов или окон
            if echo "$line" | jq -e '.Ok.WorkspacesChanged // .Ok.WindowsChanged // .Ok.WindowFocusChanged' >/dev/null 2>&1; then
                generate_workspaces_json
            fi
        done
    else
        # Fallback к polling если event-stream не работает
        local last_state=""
        while true; do
            local current_state=$(generate_workspaces_json)
            if [[ "$current_state" != "$last_state" ]]; then
                echo "$current_state"
                last_state="$current_state"
            fi
            sleep 0.1
        done
    fi
}

# Функция переключения на воркспейс
switch_to_workspace() {
    local workspace_id=$1
    if [[ -n "$workspace_id" && "$workspace_id" =~ ^[1-9][0-9]*$ ]]; then
        # Используем правильное действие для niri
        niri msg action focus-workspace --reference-by index "$workspace_id" >/dev/null 2>&1
    fi
}

# Основная логика
case "$1" in
    "listen")
        listen_mode
        ;;
    "get-workspace-info")
        # Обратная совместимость со старым API
        id=$2
        if [[ -z "$id" ]]; then
            echo ""
            exit 0
        fi
        
        active=$(get_active_workspace)
        urgent=$(get_urgent_workspaces)
        existing=$(get_existing_workspaces)
        
        state=$(get_workspace_state "$id" "$active" "$urgent" "$existing")
        icon=$(echo "$state" | cut -d: -f2)
        
        if [[ -z "$icon" ]]; then
            icon=""
        fi
        
        echo "${icon}"
        ;;
    "get-workspace-state")
        # Получаем класс состояния для воркспейса
        id=$2
        if [[ -z "$id" ]]; then
            echo "empty"
            exit 0
        fi
        
        active=$(get_active_workspace)
        urgent=$(get_urgent_workspaces)
        existing=$(get_existing_workspaces)
        
        state=$(get_workspace_state "$id" "$active" "$urgent" "$existing")
        class=$(echo "$state" | cut -d: -f1)
        
        echo "${class}"
        ;;
    "switch-workspace")
        if [[ -n "$2" ]]; then
            switch_to_workspace "$2"
        fi
        ;;
    "debug")
        id=${2:-1}
        echo "=== DEBUG INFO ==="
        echo "Workspace ID: $id"
        echo "Active: $(get_active_workspace)"
        echo "Urgent: $(get_urgent_workspaces)"
        echo "Existing: $(get_existing_workspaces)"
        echo "State: $(get_workspace_state "$id" "$(get_active_workspace)" "$(get_urgent_workspaces)" "$(get_existing_workspaces)")"
        
        # Дополнительная отладка API ответов
        echo ""
        echo "=== RAW API RESPONSES ==="
        echo "Workspaces JSON:"
        niri msg --json workspaces 2>/dev/null | jq . || echo "ERROR: Failed to get workspaces"
        echo ""
        echo "Windows JSON:"
        niri msg --json windows 2>/dev/null | jq . || echo "ERROR: Failed to get windows"
        ;;
    *)
        echo "Usage: $0 {listen|get-workspace-info|get-workspace-state|switch-workspace|debug} [workspace_id]"
        echo "Examples:"
        echo "  $0 listen                    # Start listening mode for deflisten"
        echo "  $0 get-workspace-info 1      # Get icon for workspace 1"
        echo "  $0 get-workspace-state 1     # Get state class for workspace 1"
        echo "  $0 switch-workspace 4        # Switch to workspace 4"
        echo "  $0 debug 1                   # Debug info for workspace 1"
        exit 1
        ;;
esac
