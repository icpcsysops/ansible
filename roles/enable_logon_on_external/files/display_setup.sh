#!/bin/bash
# Turn off internal screen and force external screen as primary at boot
# internal is listed first
mapfile -t displays < <(xrandr | grep " connected")
if [ "${#displays[@]}" -ne 2 ]; then
    echo "Warning: Expected 2 displays, but found ${#displays[@]}."
    exit 0
fi
xrandr --output ${displays[0]%% *} --off --output ${displays[1]%% *} --auto --primary
