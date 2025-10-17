#!/usr/bin/env bash

# Универсальный скрипт для eww launcher
# Использование:
#   launch.sh drun list [search_query] - список приложений
#   launch.sh drun launch <desktop_file> - запустить приложение
#   launch.sh clipboard list [search] - список буфера
#   launch.sh clipboard paste <id> - вставить из буфера
#   launch.sh files list [search] [dir] - список файлов
#   launch.sh windows list [search] - список окон
#   launch.sh windows focus <id> - фокус на окно

MODE="${1:-drun}"
ACTION="${2:-list}"
QUERY="${3:-}"

# ==================== DRUN ====================

parse_desktop_file() {
    local file="$1"
    local search="$2"
    
    [[ ! -f "$file" ]] && return
    
    local name="" exec="" icon="" comment="" terminal="false" 
    local nodisplay="false" hidden="false" type=""
    
    local in_section=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^\[Desktop\ Entry\] ]]; then
            in_section=true
            continue
        fi
        
        if [[ "$line" =~ ^\[.*\] ]]; then
            in_section=false
            continue
        fi
        
        if [[ "$in_section" == true ]]; then
            case "$line" in
                Name=*) name="${line#Name=}" ;;
                Exec=*) exec="${line#Exec=}" ;;
                Icon=*) icon="${line#Icon=}" ;;
                Comment=*) comment="${line#Comment=}" ;;
                Terminal=*) terminal="${line#Terminal=}" ;;
                NoDisplay=*) nodisplay="${line#NoDisplay=}" ;;
                Hidden=*) hidden="${line#Hidden=}" ;;
                Type=*) type="${line#Type=}" ;;
            esac
        fi
    done < "$file"
    
    [[ "$type" != "Application" ]] && return
    [[ "$nodisplay" == "true" ]] && return
    [[ "$hidden" == "true" ]] && return
    [[ -z "$name" ]] && return
    [[ -z "$exec" ]] && return
    
    if [[ -n "$search" ]]; then
        local search_lower=$(echo "$search" | tr '[:upper:]' '[:lower:]')
        local name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
        local comment_lower=$(echo "$comment" | tr '[:upper:]' '[:lower:]')
        
        if [[ ! "$name_lower" =~ $search_lower ]] && \
           [[ ! "$comment_lower" =~ $search_lower ]]; then
            return
        fi
    fi
    
    exec=$(echo "$exec" | sed -E 's/%[a-zA-Z]//g' | xargs)
    
    name=$(echo "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')
    exec=$(echo "$exec" | sed 's/\\/\\\\/g; s/"/\\"/g')
    icon=$(echo "$icon" | sed 's/\\/\\\\/g; s/"/\\"/g')
    comment=$(echo "$comment" | sed 's/\\/\\\\/g; s/"/\\"/g')
    file=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')
    
    cat <<EOF
{
  "name": "$name",
  "exec": "$exec",
  "icon": "$icon",
  "comment": "$comment",
  "terminal": $([[ "$terminal" == "true" ]] && echo "true" || echo "false"),
  "file": "$file"
}
EOF
}

get_desktop_files() {
    echo "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:${XDG_DATA_HOME:-$HOME/.local/share}" | \
    tr ':' '\n' | \
    while read -r dir; do
        find "$dir/applications" -maxdepth 1 -name "*.desktop" 2>/dev/null
    done | sort -u
}

drun_list() {
    echo "["
    local first=true
    while IFS= read -r desktop_file; do
        result=$(parse_desktop_file "$desktop_file" "$QUERY")
        if [[ -n "$result" ]]; then
            [[ "$first" == false ]] && echo ","
            echo "$result"
            first=false
        fi
    done < <(get_desktop_files)
    echo "]"
}

drun_launch() {
    local desktop_file="$QUERY"
    
    [[ ! -f "$desktop_file" ]] && exit 1
    
    local exec_line=$(grep "^Exec=" "$desktop_file" | head -1 | cut -d= -f2-)
    local terminal=$(grep "^Terminal=" "$desktop_file" | head -1 | cut -d= -f2-)
    
    exec_line=$(echo "$exec_line" | sed -E 's/%[a-zA-Z]//g' | xargs)
    
    if [[ "$terminal" == "true" ]]; then
        ${TERMINAL:-alacritty} -e $exec_line &
    else
        setsid -f $exec_line >/dev/null 2>&1
    fi
}

# ==================== MAIN ====================

case "$MODE" in
    drun)
        case "$ACTION" in
            list) drun_list ;;
            launch) drun_launch ;;
        esac
        ;;
    
    clipboard)
        echo "[]"  # TODO: implement
        ;;
    
    files)
        echo "[]"  # TODO: implement
        ;;
    
    windows)
        echo "[]"  # TODO: implement
        ;;
    
    *)
        echo "Usage: $0 {drun|clipboard|files|windows} {list|launch|paste|focus} [args]"
        exit 1
        ;;
esac
