#!/bin/sh

CONFIG="${KIDTIME_CONFIG:-/etc/kidtime/config}"

[ -r "$CONFIG" ] || {
    echo "ERROR: KidTime config is not readable: $CONFIG" >&2
    exit 1
}

. "$CONFIG"

: "${BE6500_ROUTER:?Set BE6500_ROUTER in $CONFIG}"
: "${BE6500_DEVICE_ID:?Set BE6500_DEVICE_ID in $CONFIG}"

BE6500_KEY="${BE6500_KEY:-a2ffa5c9be07488bbb04a3a47d3c5f6a}"
BE6500_PASSFILE="${BE6500_PASSFILE:-/etc/kidtime/be6500.pass}"

[ -r "$BE6500_PASSFILE" ] || {
    echo "ERROR: BE6500 password file is not readable" >&2
    exit 1
}

NONCE="0_${BE6500_DEVICE_ID}_$(date +%s)_$(awk 'BEGIN{srand(); print int(rand()*10000)}')"
PWD="$(cat "$BE6500_PASSFILE")"

HASH1="$(printf '%s' "${PWD}${BE6500_KEY}" | sha256sum | awk '{print $1}')"
HASH2="$(printf '%s' "${NONCE}${HASH1}" | sha256sum | awk '{print $1}')"
unset PWD

RESPONSE="$(curl -sS \
  --connect-timeout 5 \
  --max-time 15 \
  "http://${BE6500_ROUTER}/cgi-bin/luci/api/xqsystem/login" \
  --data-urlencode 'username=admin' \
  --data-urlencode "password=${HASH2}" \
  --data-urlencode 'logtype=2' \
  --data-urlencode "nonce=${NONCE}")" || {
    echo "ERROR: BE6500 login request failed" >&2
    exit 1
}

TOKEN="$(printf '%s' "$RESPONSE" | sed -n 's/.*"token":"\([^"]*\)".*/\1/p')"
unset RESPONSE

[ -n "$TOKEN" ] || {
    echo "ERROR: BE6500 login response did not contain a token" >&2
    exit 1
}

printf '%s\n' "$TOKEN"
