#!/usr/bin/env bash

CURRENT_KEYBOARD=$(setxkbmap -query)

if [[ $CURRENT_KEYBOARD == *"layout:     us"* ]]; then
    setxkbmap am phonetic-alt
elif [[ $CURRENT_KEYBOARD == *"layout:     am"* ]]; then
    setxkbmap ru phonetic_winkeys
elif [[ $CURRENT_KEYBOARD == *"layout:     ru"* ]]; then
    setxkbmap us
fi
