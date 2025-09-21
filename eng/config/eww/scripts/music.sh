#!/bin/sh

DEFAULT_ART="$HOME/.config/eww/bar/images/music.png"
LAST_OUTPUT=""

# Функция генерации JSON с иконкой кнопки
generate_json() {
    local artist="$1"
    local title="$2"
    local art="$3"
    local player_status="$4"

    # Определяем иконку кнопки
    if [ "$player_status" = "Playing" ]; then
        button_icon="󰏤"  # Иконка "пауза"
    else
        button_icon="󰐊"  # Иконка "воспроизведение"
    fi

    printf '{"artist":"%s","title":"%s","art":"%s","status":"%s"}\n' "$artist" "$title" "$art" "$button_icon"
}

# Начальный вывод
generate_json "" "" "$DEFAULT_ART" "Stopped"

while true; do
    # Получаем статус плеера
    player_status=$(playerctl status 2>/dev/null)

    # Получаем метаданные
    metadata=$(playerctl metadata --format '{{artist}}␞{{title}}␞{{mpris:artUrl}}' 2>/dev/null)
    IFS="␞" read -r artist title art <<< "$metadata"

    # Обрабатываем путь к обложке
    art_path="${art#file://}"
    [ -z "$art_path" ] && art_path="$DEFAULT_ART"
    [ -z "$artist" ] && artist=""
    [ -z "$title" ] && title=""

    # Генерируем JSON
    current_output=$(generate_json "$artist" "$title" "$art_path" "$player_status")

    # Выводим только при изменении
    if [ "$current_output" != "$LAST_OUTPUT" ]; then
        echo "$current_output"
        LAST_OUTPUT="$current_output"
    fi

    # Пауза
    sleep 0.05
done
