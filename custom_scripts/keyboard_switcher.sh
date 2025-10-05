#!/usr/bin/env bash

CURRENT_KEYBOARD=$(setxkbmap -query)

if [[ $CURRENT_KEYBOARD == *"layout:     us"* ]]; then
    setxkbmap am phonetic-alt -option caps:escape
elif [[ $CURRENT_KEYBOARD == *"layout:     am"* ]]; then
    setxkbmap ru phonetic_winkeys -option caps:escape
elif [[ $CURRENT_KEYBOARD == *"layout:     ru"* ]]; then
    setxkbmap us -option caps:escape
fi
