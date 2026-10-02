#!/bin/sh

CONFIG="${KIDTIME_CONFIG:-/etc/kidtime/config}"
LOGIN="${BE6500_LOGIN_SCRIPT:-/etc/kidtime/router-adapters/be6500_login.sh}"

[ -r "$CONFIG" ] || {
    echo "ERROR: KidTime config is not readable: $CONFIG" >&2
    exit 1
}

. "$CONFIG"

: "${BE6500_ROUTER:?Set BE6500_ROUTER in $CONFIG}"
: "${BE6500_MAC_24G:?Set BE6500_MAC_24G in $CONFIG}"
: "${BE6500_MAC_5G:?Set BE6500_MAC_5G in $CONFIG}"

TOKEN="$($LOGIN)"

[ -n "$TOKEN" ] || {
    echo "ERROR: BE6500 login failed" >&2
    exit 1
}

edit_mac() {
    MAC="$1"
    OPTION="$2"

    curl -fsS \
      --connect-timeout 5 \
      --max-time 15 \
      "http://${BE6500_ROUTER}/cgi-bin/luci/;stok=${TOKEN}/api/xqnetwork/edit_device" \
      --data-urlencode "mac=${MAC}" \
      --data-urlencode "model=0" \
      --data-urlencode "option=${OPTION}"
}

case "$1" in
    block)
        edit_mac "$BE6500_MAC_24G" 0
        edit_mac "$BE6500_MAC_5G" 0
        ;;
    allow)
        edit_mac "$BE6500_MAC_24G" 1
        edit_mac "$BE6500_MAC_5G" 1
        ;;
    *)
        echo "Usage: $0 {block|allow}" >&2
        exit 1
        ;;
esac
