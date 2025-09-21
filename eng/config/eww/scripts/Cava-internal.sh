#!/bin/sh
# Проверяем, запущен ли уже cava
if pgrep -x cava >/dev/null; then
    pkill -x cava
    sleep 0.5
fi

# Настройки (возвращаем Unicode блоки)
PIPE="/tmp/cava_eww.fifo"
CONFIG_FILE="/tmp/cava_eww_config"
BARS="▁▂▃▄▅▆▇█"

# Очищаем pipe
[ -p "$PIPE" ] && rm -f "$PIPE"
mkfifo "$PIPE"

# Создаем конфигурацию cava с оптимизированными настройками
cat > "$CONFIG_FILE" << 'CAVA_EOF'
[general]
bars = 20
framerate = 60
sleep_timer = 1
[input]
method = pulse
[output]
method = raw
raw_target = /tmp/cava_eww.fifo
data_format = ascii
ascii_max_range = 7
CAVA_EOF

# Запускаем cava в фоне
cava -p "$CONFIG_FILE" &
CAVA_PID=$!

# Функция очистки при выходе
cleanup() {
    kill $CAVA_PID 2>/dev/null
    rm -f "$PIPE" "$CONFIG_FILE"
    exit 0
}
trap cleanup EXIT INT TERM

# Предкомпилированный sed-скрипт для максимальной скорости
SED_SCRIPT="s/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g"

# Кэширование последнего вывода
LAST_OUTPUT=""

# Создаем предкомпилированный sed-скрипт (быстрее tr для Unicode)
SED_SCRIPT="s/;//g;s/0/▁/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g"

# Кэширование последнего вывода
LAST_OUTPUT=""

# Читаем данные из pipe с кэшированием
while IFS= read -r line; do
    # Используем sed с предкомпилированным скриптом
    result=$(echo "$line" | sed "$SED_SCRIPT")
    
    # Выводим только если результат изменился
    if [ "$result" != "$LAST_OUTPUT" ]; then
        echo "$result"
        LAST_OUTPUT="$result"
    fi
done < "$PIPE"


