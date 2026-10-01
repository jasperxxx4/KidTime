#!/bin/sh

DOMAIN_FILE="/etc/kidtime/kidblock-domains.txt"
DNSMASQ_CONF="/tmp/dnsmasq.d/kidblock.conf"

# 清空旧的动态 IP，确保删除域名后能够立即解除封锁
nft flush set inet kidtime video4 2>/dev/null

# 重新生成 dnsmasq nftset 配置
: > "$DNSMASQ_CONF"

[ -f "$DOMAIN_FILE" ] || exit 0

while IFS= read -r DOMAIN
do
    case "$DOMAIN" in
        ""|\#*) continue ;;
    esac

    # 后续 DNS 查询继续自动更新 video4
    echo "nftset=/${DOMAIN}/4#inet#kidtime#video4" >> "$DNSMASQ_CONF"

    # 主动解析当前 IPv4，使新增域名无需等待 iPad 重新查询 DNS
    nslookup "$DOMAIN" 127.0.0.1 2>/dev/null |
        awk '/^Address: / {print $2}' |
        grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' |
        while IFS= read -r IP
        do
            nft add element inet kidtime video4 "{ $IP }" 2>/dev/null
        done

done < "$DOMAIN_FILE"
