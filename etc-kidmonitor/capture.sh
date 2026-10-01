#!/bin/sh

. /etc/kidmonitor/config

mkdir -p "$DATA_DIR"

exec tcpdump \
    -i "$INTERFACE" \
    -n \
    -s 0 \
    -C 50 \
    -W 40 \
    -w "$DATA_DIR/kid.pcap" \
    "host $DEVICE_IP"
