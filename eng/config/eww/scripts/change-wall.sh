#!/usr/bin/env bash
set -euo pipefail

WALLPAPER_DIR="$HOME/Документы/change-wallpaper"
CACHE_IMG="$HOME/.config/hypr/no-live-bg.png"
CACHE_VID="$HOME/.config/hypr/live-bg.mp4"
MODE="${1:-stat}"
TIMEOUT_IPC=20
LOG_FILE="$HOME/.config/hypr/wallpaper.log"

exec >> "$LOG_FILE" 2>&1

# Функция для перезапуска hyprpaper
restart_hyprpaper() {
    pkill -x hyprpaper || true
    hyprpaper &
    for _ in $(seq 1 $TIMEOUT_IPC); do
        if hyprctl hyprpaper listloaded >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
    sleep 0.5
    hyprctl hyprpaper preload "$CACHE_IMG" || true
    hyprctl hyprpaper wallpaper ",$CACHE_IMG" || true
    hyprctl reload
}

# Функция для чистки обработанных файлов
cleanup() {
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.mp4" \) -size +0c -exec rm -f {} \;
}

case "$MODE" in
  stat)
    pkill mpvpaper 2>/dev/null || true
    IMAGE_FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" \) -size +0c | shuf -n1 || true)
    if [ -n "$IMAGE_FILE" ]; then
        cp "$IMAGE_FILE" "$CACHE_IMG" || true
        # Чистим папку после успешной обработки
        cleanup
    fi
    restart_hyprpaper
    sleep 1
    ;;
  zoom|no-zoom)
    pkill hyprpaper 2>/dev/null || true
    pkill mpvpaper 2>/dev/null || true
    VIDEO_FILE=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f -iname "*.mp4" -size +0c | shuf -n1 || true)
    if [ -n "$VIDEO_FILE" ]; then
        cp "$VIDEO_FILE" "$CACHE_VID" || true
        # Чистим папку после успешной обработки
        cleanup
    fi
    ZOOM_OPT=$([ "$MODE" = "zoom" ] && echo "video-zoom=0.43" || echo "video-zoom=0")
    mpvpaper -v -o "no-audio loop $ZOOM_OPT" '*' "$CACHE_VID" >/dev/null 2>&1 &
    ;;
  *)
    echo "Usage: $0 {stat|zoom|no-zoom}"
    exit 1
    ;;
esac

exit 0
