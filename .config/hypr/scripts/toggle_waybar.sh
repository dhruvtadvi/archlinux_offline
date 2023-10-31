#!/bin/bash

WAYBAR_PID=$(pgrep -x waybar)

if [ -z "$WAYBAR_PID" ]; then
    waybar &   # Start Waybar if it's not running
else
    kill $WAYBAR_PID  # Stop Waybar if it's running
fi
