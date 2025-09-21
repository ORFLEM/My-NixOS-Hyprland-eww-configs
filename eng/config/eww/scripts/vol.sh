#!/bin/sh

while true; do
    vol=$(pamixer --get-volume)
    
    case "$vol" in
        0)
            sign="" ;;
        [1-9]|1[0-9]|2[0-9]|3[0-9]|4[0-5])
            sign="" ;;
        4[6-9]|5[0-9]|60)
            sign="" ;;
        [6-9][1-9]|100)
            sign="" ;;
    esac

    echo "$vol%"
    sleep 0.05
done

