#!/bin/sh

CONFIG="/etc/kidtime/config"
. "$CONFIG"

nft delete table inet kidtime 2>/dev/null

nft -f - <<NFT
table inet kidtime {
    counter kid_up {
    }

    counter kid_down {
    }

    set video4 {
        type ipv4_addr
    }

    set blocked4 {
        type ipv4_addr
    }

    chain forward {
        type filter hook forward priority 10; policy accept;

        ip saddr ${DEVICE_IP} counter name kid_up
        ip daddr ${DEVICE_IP} counter name kid_down

        ip saddr ${DEVICE_IP} ip daddr @video4 drop

        ip saddr @blocked4 drop
        ip daddr @blocked4 drop
    }
}
NFT