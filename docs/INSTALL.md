# 安装、升级与卸载

本文面向 OpenWrt/ImmortalWrt 风格系统，默认使用 root shell。当前 Router Adapter 已验证 Xiaomi BE6500；其他主路由需要实现等价的 `allow` / `block` 控制。

## 1. 依赖

当前脚本会使用：

- `nft`
- 支持 nftset 的 `dnsmasq`
- `curl`
- `sha256sum`
- 常见 BusyBox 工具（`awk`、`sed`、`grep`、`date`、`ip` 等）
- 如需 Web Panel：`uhttpd` 或其他支持 CGI 的本地 Web Server
- 如需 KidMonitor：`tcpdump`

运行 KidTime 的节点必须能够看到受控设备的真实流量。

## 2. 首次安装

建立目录：

```sh
mkdir -p /etc/kidtime/router-adapters
mkdir -p /etc/kidmonitor
mkdir -p /www/cgi-bin
```

安装命令：

```sh
cp bin/kidtime /usr/bin/kidtime
cp bin/kidblock /usr/bin/kidblock
cp bin/kidmonitor /usr/bin/kidmonitor
chmod +x /usr/bin/kidtime /usr/bin/kidblock /usr/bin/kidmonitor
```

安装 KidTime 运行文件：

```sh
cp etc-kidtime/daemon.sh /etc/kidtime/daemon.sh
cp etc-kidtime/firewall.sh /etc/kidtime/firewall.sh
cp etc-kidtime/kidblock_dns.sh /etc/kidtime/kidblock_dns.sh
cp etc-kidtime/router-adapters/be6500_control.sh /etc/kidtime/router-adapters/
cp etc-kidtime/router-adapters/be6500_login.sh /etc/kidtime/router-adapters/
chmod +x /etc/kidtime/*.sh /etc/kidtime/router-adapters/*.sh
```

**只在首次安装时**由示例创建私有配置：

```sh
cp etc-kidtime/config.example /etc/kidtime/config
chmod 600 /etc/kidtime/config
```

然后修改 `/etc/kidtime/config` 中的全部示例值。

创建路由器密码文件：

```sh
cp etc-kidtime/router-adapters/be6500.pass.example /etc/kidtime/be6500.pass
chmod 600 /etc/kidtime/be6500.pass
```

把文件内容替换为真实路由器密码。这个文件绝不能提交到公开仓库。

创建 KidBlock 域名文件：

```sh
cp etc-kidtime/kidblock-domains.example.txt /etc/kidtime/kidblock-domains.txt
```

如需 KidMonitor：

```sh
cp etc-kidmonitor/capture.sh /etc/kidmonitor/capture.sh
cp etc-kidmonitor/config.example /etc/kidmonitor/config
chmod +x /etc/kidmonitor/capture.sh
chmod 600 /etc/kidmonitor/config
```

安装 procd 服务：

```sh
cp init.d/kidtime /etc/init.d/kidtime
chmod +x /etc/init.d/kidtime
/etc/init.d/kidtime enable
```

安装 Web Panel：

```sh
cp web/kidtime.html /www/kidtime.html
cp web/cgi-bin/kidtime-api /www/cgi-bin/kidtime-api
chmod +x /www/cgi-bin/kidtime-api
```

把 `system-config/firewall-kidtime.example` 中的 include 加入本机 firewall 配置，然后重启 firewall。

如需开机恢复 KidBlock，可参考 `system-config/rc.local.example` 把对应命令加入自己的启动流程。

启动 KidTime：

```sh
/etc/init.d/kidtime restart
kidtime status
```

## 3. 升级

升级前先备份私有运行数据：

```sh
mkdir -p /root/kidtime-backup
cp -a /etc/kidtime/config /root/kidtime-backup/ 2>/dev/null
cp -a /etc/kidtime/be6500.pass /root/kidtime-backup/ 2>/dev/null
cp -a /etc/kidtime/kidblock-domains.txt /root/kidtime-backup/ 2>/dev/null
cp -a /etc/kidtime/state /root/kidtime-backup/ 2>/dev/null
```

停止服务：

```sh
/etc/init.d/kidtime stop
```

只替换程序和运行脚本，**不要覆盖**上面的私有配置：

```sh
cp bin/kidtime /usr/bin/kidtime
cp bin/kidblock /usr/bin/kidblock
cp bin/kidmonitor /usr/bin/kidmonitor

cp etc-kidtime/daemon.sh /etc/kidtime/daemon.sh
cp etc-kidtime/firewall.sh /etc/kidtime/firewall.sh
cp etc-kidtime/kidblock_dns.sh /etc/kidtime/kidblock_dns.sh
cp etc-kidtime/router-adapters/be6500_control.sh /etc/kidtime/router-adapters/
cp etc-kidtime/router-adapters/be6500_login.sh /etc/kidtime/router-adapters/

cp init.d/kidtime /etc/init.d/kidtime
cp web/kidtime.html /www/kidtime.html
cp web/cgi-bin/kidtime-api /www/cgi-bin/kidtime-api
```

恢复执行权限并检查 shell 语法：

```sh
chmod +x /usr/bin/kidtime /usr/bin/kidblock /usr/bin/kidmonitor
chmod +x /etc/kidtime/*.sh /etc/kidtime/router-adapters/*.sh
chmod +x /etc/init.d/kidtime /www/cgi-bin/kidtime-api

sh -n /usr/bin/kidtime
sh -n /usr/bin/kidblock
sh -n /usr/bin/kidmonitor
sh -n /www/cgi-bin/kidtime-api
```

把当前私有 `/etc/kidtime/config` 和新版本 `etc-kidtime/config.example` 对照，如新增了必要变量，手工补入真实配置。

重启：

```sh
/etc/init.d/kidtime restart
kidtime status
kidblock status
```

## 4. 回滚

升级失败时，停止 KidTime，恢复上一版程序文件和私有配置，恢复执行权限后重新启动。

不要从 `/tmp` 恢复旧 token 或临时状态文件。

## 5. 卸载

先确保受控设备恢复联网：

```sh
kidtime master-off
```

再停止并禁用服务：

```sh
/etc/init.d/kidtime stop
/etc/init.d/kidtime disable
```

删除自己加入的 firewall include，并重启 firewall。

删除程序和 Web 文件：

```sh
rm -f /usr/bin/kidtime /usr/bin/kidblock /usr/bin/kidmonitor
rm -f /etc/init.d/kidtime
rm -f /www/kidtime.html /www/cgi-bin/kidtime-api
```

确认不再需要配置、域名列表和状态后，再删除运行目录：

```sh
rm -rf /etc/kidtime /etc/kidmonitor
```

最后删除你曾加入 `rc.local` 或其他启动脚本的 KidBlock 启动命令。

## 6. 安装后最小验收

至少检查：

```sh
kidtime status
kidtime master-status
kidblock status
```

再从本地 Web Panel 做一次简单冒烟测试：

- 状态能自动刷新；
- 临时加时一次；
- 修改并恢复一个无害的时间规则；
- 总开关 OFF 后设备保持 ALLOW；
- 总开关 ON 后恢复正常规则判断；
- KidBlock ON/OFF；
- 新增并删除一个临时测试域名。
