#!/bin/sh

STATE="/tmp/kidtime/state"
PERSIST="/etc/kidtime/state"
CONFIG="/etc/kidtime/config"

[ -r "$CONFIG" ] && . "$CONFIG"

INTERVAL="${CHECK_INTERVAL:-6}"
case "$INTERVAL" in
    ''|*[!0-9]*) INTERVAL=6 ;;
esac
[ "$INTERVAL" -ge 1 ] 2>/dev/null || INTERVAL=6

PERSIST_TICKS=$((60 / INTERVAL))
[ "$PERSIST_TICKS" -ge 1 ] || PERSIST_TICKS=1

# 重启后恢复当天状态
if [ ! -f "$STATE" ] && [ -f "$PERSIST" ]; then
    cp "$PERSIST" "$STATE"
fi

COUNT=0

while true
do
    /usr/bin/kidtime tick

    COUNT=$((COUNT + 1))

    # 按配置周期计算，约每分钟持久化一次
    if [ "$COUNT" -ge "$PERSIST_TICKS" ]; then
        cp "$STATE" "$PERSIST.tmp"
        mv "$PERSIST.tmp" "$PERSIST"
        chmod 600 "$PERSIST"
        COUNT=0
    fi

    sleep "$INTERVAL"
done
