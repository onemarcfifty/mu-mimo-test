#!/bin/bash

# Check if an SSID is provided
if [ -z "$1" ]; then
  echo "Please provide an SSID as a parameter."
  exit 1
fi

# Find the interface connected to the SSID
interface=$(iw dev | awk '$1=="Interface"{print $2}')
connected_interface=""

for iface in $interface; do
    echo $iface
    ssid=$(iw dev "$iface" info | awk  '/ssid/{print $2}')
    ssid=$(echo "$ssid" | awk '{$1=$1};1')  # Trim leading/trailing spaces
    echo $ssid
    if [ "$ssid" == "$1" ]; then
        connected_interface="$iface"
        break
    fi
done

if [ -z "$connected_interface" ]; then
  echo "No Wi-Fi adapter is connected to the specified SSID."
  exit 1
fi

# Get the connection parameters
bitrate=$(iw dev "$connected_interface" link | awk '/tx bitrate:/ {print $3}')
vht_mcs=$(iw dev "$connected_interface" link | awk '/VHT-MCS/ {print $2}')
channel_width=$(iw dev "$connected_interface" link | awk '/width:/ {print $2}')

# Print the connection parameters
echo "Connection parameters for SSID: $1"
echo "---------------------------------"
echo "Bitrate: $bitrate"
echo "VHT-MCS: $vht_mcs"
echo "Channel Width: $channel_width"