#!/bin/sh
status=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
vol=$(echo "$status" | awk -F'.' '{print $2}' | sed 's/^0//')
[ -z "$vol" ] && vol=0

is_mute=0
echo "$status" | /usr/bin/grep -q '\[MUTED\]' && is_mute=1

is_head=0
pactl list sinks 2>/dev/null | /usr/bin/grep -q 'Active Port: analog-output-headphones' && is_head=1

if [ $is_mute -eq 1 ]; then
    if [ $is_head -eq 1 ]; then
        echo "^c#6272A4^ 󰋌  ^d^"
    else
        echo "^c#6272A4^ 󰝟  ^d^"
    fi
else
    color="^c#BD93F9^"
    [ $vol -gt 50 ] && color="^c#FF5555^"
    
    if [ $is_head -eq 1 ]; then
        echo "${color} 󰋋 ${vol}% ^d^"
    else
        echo "${color} 󰕾 ${vol}% ^d^"
    fi
fi
