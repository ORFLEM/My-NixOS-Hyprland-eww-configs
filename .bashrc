function fancy_prompt {
# Цвета
local TIME_COLOR="\[\033[01;36m\]"    # Голубой (время)
local USER_COLOR="\[\033[01;32m\]"    # Зелёный (ник)
local DIR_COLOR="\[\033[01;34m\]"     # Синий (путь)
local GIT_COLOR="\[\033[01;35m\]"     # Пурпурный (гит)
local ERROR_COLOR="\[\033[01;31m\]"   # Красный (ошибки)
local BRACKET_COLOR="\[\033[01;32m\]" # Зелёный (скобки и $)
local RESET="\[\033[00m\]"            # Сброс цвета

# Функция для промпта

    # Время (ЧЧ:ММ)
    local current_time="\D{%H:%M}"

    # Пользователь
    local username="\u"

    # Директория (сокращённая)
    local dir="\w"
    dir=${dir/#$HOME/\~}              # ~ вместо /home/user
    dir=${dir//\/projects\//\/p\/}    # ~/projects/ → ~/p/
    dir=${dir//\/documents\//\/d\/}   # ~/documents/ → ~/d/
    dir=${dir//\/downloads\//\/dl\/}  # ~/downloads/ → ~/dl/

    # Ветка гита
    local git_branch=""
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch=$(git branch --show-current 2>/dev/null)
        if ! git diff --quiet 2>/dev/null; then
            git_branch=" ${ERROR_COLOR}${branch}${RESET}"  # Красный, если есть изменения
        else
            git_branch=" ${GIT_COLOR}${branch}${RESET}"     # Пурпурный, если всё чисто
        fi
    fi

    # Код возврата (если команда упала)
    local exit_status="$?"
    local status_prompt=""
    if [ "$exit_status" -ne 0 ]; then
        status_prompt=" ${ERROR_COLOR}[${exit_status}]${RESET}"
    fi

    # Формируем промпт в формате: [время - ник: путь (ветка)]
    PS1="${BRACKET_COLOR}[${TIME_COLOR}${current_time}${RESET} - ${USER_COLOR}${username}${RESET}:${DIR_COLOR}${dir}${RESET}${git_branch}${status_prompt}${BRACKET_COLOR}]\$${RESET}  "
}

# Обновляем промпт перед каждой командой
PROMPT_COMMAND="fancy_prompt"

calc() {
    # Если аргумент один (например, calc "5 + 3")
    if [ $# -eq 1 ]; then
        local expr="$1"
    # Если аргументов несколько (например, calc 5 + 3)
    else
        local expr="$*"
    fi

    # Исправленный regex: '-' в конце списка символов
    if [[ "$expr" =~ ^[0-9+*/%^().\ -]+$ ]]; then
        if [[ "$expr" =~ \. ]]; then
            # Дроби: используем awk
            echo "$expr" | awk '{print $0 " = " $0 + 0}' | awk '{print $NF}'
        else
            # Целочисленные выражения: используем $((...))
            echo "$((expr))"
        fi
    else
        echo "Ошибка: неверное выражение. Разрешённые символы: 0-9, +-*/%^()."
    fi
}


    #games
    alias tetris='bastet'
    alias snake='nsnake'
    alias moonbuggy='moon-buggy'

    #change ls on lsd
    alias ls='lsd --group-dirs first --date relative --size short --icon always -a'

    #clear
    alias c='clear'

    #root
    alias op='su -'

    #micro
    alias mc='micro'
    alias mc-hypr='micro ~/.config/hypr/hyprland.conf'
    alias mc-niri='micro ~/.config/niri/config.kdl'
    alias mc-kitty='micro ~/.config/kitty/kitty.conf'
    alias mc-fish='micro ~/.config/fish/config.fish'
    alias mc-nix='micro /etc/nixos/configuration.nix'

    #eww
    alias mc-hbar='micro ~/.config/eww/bar/hbar.yuck'
    alias mc-nbar='micro ~/.config/eww/bar/nbar.yuck'
    alias mc-eww='micro ~/.config/eww/eww.yuck'
    alias mc-ewwstl='micro ~/.config/eww/eww.scss'
    alias mc-barstl='micro ~/.config/eww/bar/bar.scss'
    alias mc-btime='micro ~/.config/eww/Btime/btime.yuck'
    alias mc-roundm='micro "~/.config/eww/round monitor/roundm.yuck"'
    alias mc-roundmstl='micro "~/.config/eww/round monitor/roundm.scss"'
    alias mc-variables='micro ~/.config/eww/bar/variables&polling.yuck'
    alias mc-pwr='micro ~/.config/eww/power_pc/power.yuck'
    alias mc-pwrstl='micro ~/.config/eww/power_pc/power.scss'

    alias mc-clrs='micro ~/Документы/документы/colors.txt'
    alias mc-sddm='micro /usr/share/sddm/themes/ximper/theme.conf'

    #helix
    alias hx-hypr='hx ~/.config/hypr/hyprland.conf'
    alias hx-niri='hx ~/.config/niri/config.kdl'
    alias hx-kitty='hx ~/.config/kitty/kitty.conf'
    alias hx-fish='hx ~/.config/fish/config.fish'
    alias hx-nix='hx /etc/nixos/configuration.nix'

    #eww
    alias hx-hbar='hx ~/.config/eww/bar/hbar.yuck'
    alias hx-nbar='hx ~/.config/eww/bar/nbar.yuck'
    alias hx-eww='hx ~/.config/eww/eww.yuck'
    alias hx-ewwstl='hx ~/.config/eww/eww.scss'
    alias hx-barstl='hx ~/.config/eww/bar/bar.scss'
    alias hx-btime='hx ~/.config/eww/Btime/btime.yuck'
    alias hx-roundm='hx "~/.config/eww/round monitor/roundm.yuck"'
    alias hx-roundmstl='hx "~/.config/eww/round monitor/roundm.scss"'
    alias hx-variables='hx ~/.config/eww/bar/variables&polling.yuck'
    alias hx-pwr='hx ~/.config/eww/power_pc/power.yuck'
    alias hx-pwrstl='hx ~/.config/eww/power_pc/power.scss'
