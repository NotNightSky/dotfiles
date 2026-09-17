#!/usr/bin/env bash

COVER_PATH="/tmp/spotify_cover.png"

# Action Handler (Triggered on click)
case "$1" in
  --play-pause) playerctl --player=spotify play-pause ;;
  --next)       playerctl --player=spotify next ;;
  --previous)   playerctl --player=spotify previous ;;
esac

# Verify if Spotify is running
status=$(playerctl --player=spotify status 2>/dev/null)
if [ -z "$status" ]; then
  case "$1" in
    --title)       echo "Offline" ;;
    --artist)      echo "Spotify Not Running" ;;
    --progress)    echo "00:00 / 00:00" ;;
    --status-icon) echo "󰐊" ;; # Default Play icon when offline
  esac
  exit 0
fi

# Dynamic Play / Pause Icon
if [ "$1" = "--status-icon" ]; then
  if [ "$status" = "Playing" ]; then
    echo "󰏤" # Pause icon (Nerd Font: nf-md-pause)
  else
    echo "󰐊" # Play icon (Nerd Font: nf-md-play)
  fi
  exit 0
fi

# Fetch track information
title=$(playerctl --player=spotify metadata xesam:title 2>/dev/null || echo "No Track")
artist=$(playerctl --player=spotify metadata xesam:artist 2>/dev/null || echo "Unknown Artist")
art_url=$(playerctl --player=spotify metadata mpris:artUrl 2>/dev/null)

# Fetch position and length
pos=$(playerctl --player=spotify position 2>/dev/null)
len_us=$(playerctl --player=spotify metadata mpris:length 2>/dev/null)

if [ -n "$pos" ] && [ -n "$len_us" ]; then
  pos_sec=$(printf "%.0f" "$pos")
  len_sec=$(( len_us / 1000000 ))
  pos_fmt=$(date -u -d "@$pos_sec" +%M:%S 2>/dev/null || echo "00:00")
  len_fmt=$(date -u -d "@$len_sec" +%M:%S 2>/dev/null || echo "00:00")
  progress="${pos_fmt} / ${len_fmt}"
else
  progress="00:00 / 00:00"
fi

# Download cover art
if [ -n "$art_url" ]; then
  curl -s "$art_url" --output "$COVER_PATH"
fi

# Truncate long track titles and artist names
title=$(echo "$title" | cut -c 1-30)
artist=$(echo "$artist" | cut -c 1-30)

# Output text tags
case "$1" in
  --title)    echo "$title" ;;
  --artist)   echo "$artist" ;;
  --progress) echo "$progress" ;;
esac