#!/usr/bin/env bash

get_volume() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'
}

is_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -q MUTED
}

display_volume() {
    local volume=$(get_volume)

    if is_muted; then
        echo "󰝟 muted"
    else
        local icon="󰕾"
        if [ "$volume" -gt 100 ]; then
            icon="󰕾"
        fi

        # Create bar visualization
        local bar_length=10
        local filled=$(( volume * bar_length / 150 ))  # Scale to 150% max
        [ "$filled" -gt "$bar_length" ] && filled=$bar_length

        local bar=""
        local i
        for ((i=0; i<filled; i++)); do
            if [ "$i" -lt 6 ]; then
                bar+="%{F#55aa55}—%{F-}"
            elif [ "$i" -lt 8 ]; then
                bar+="%{F#f5a70a}—%{F-}"
            else
                bar+="%{F#ff5555}—%{F-}"
            fi
        done

        for ((i=filled; i<bar_length; i++)); do
            bar+="%{F#555}—%{F-}"
        done

        echo "%{F#555}$icon%{F-} $bar $volume%"
    fi
}

# Listen for volume changes with wpctl
while true; do
    display_volume
    sleep 0.5
done
