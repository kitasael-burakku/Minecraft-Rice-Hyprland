#!/usr/bin/env bash

battery_dir=""
for candidate in /sys/class/power_supply/BAT*; do
    if [ -r "$candidate/capacity" ] && [ -r "$candidate/status" ]; then
        battery_dir="$candidate"
        break
    fi
done

if [ -z "$battery_dir" ]; then
    echo ""
    exit 0
fi

battery_percentage=$(cat "$battery_dir/capacity")
battery_status=$(cat "$battery_dir/status")

# Define the battery icons for each 10% segment
battery_icons=("󰂃" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰁹")

# Define the charging icon
charging_icon="󰂄"

# Calculate the index for the icon array
icon_index=$((battery_percentage / 10))
if [ "$icon_index" -gt 9 ]; then
    icon_index=9
fi

# Get the corresponding icon
battery_icon=${battery_icons[icon_index]}

# Check if the battery is charging
if [ "$battery_status" = "Charging" ]; then
	battery_icon="$charging_icon"
fi

# Output the battery percentage and icon
echo "$battery_percentage% $battery_icon" 