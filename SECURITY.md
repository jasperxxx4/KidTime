# 安全说明

## 适用范围

KidTime 是一个面向家庭可信管理网络的实验项目。当前 Web CGI **不适合直接暴露到公网或不可信局域网**。

当前版本有以下明确安全限制：

- CGI 的所有 action 都通过 GET 参数调用，包括写操作；
- CGI 没有内置登录、授权、会话或 CSRF 防护；
- CGI 可以改写 `/etc/kidtime/config` 并调用高权限系统命令；
- 已验证的 Xiaomi BE6500 Router Adapter 使用路由器本地 HTTP 接口；
- KidBlock 只处理 IPv4，不能阻止 DoH、共享 CDN、客户端缓存等绕过路径。

部署时应把 Web Panel 限制在可信管理网，并通过 uhttpd、反向代理或其他上层机制增加访问控制。

## 私密数据

以下内容不得提交到公开仓库：

- `/etc/kidtime/config`
- `/etc/kidtime/be6500.pass`
- `/etc/kidtime/kidblock-domains.txt`
- 抓包文件（`*.pcap`、`*.pcapng`）
- 路由器 token、调试日志和登录响应
- 真实家庭 IP、MAC、设备标识和网络拓扑细节

仓库中的配置只保留文档示例值。

## 漏洞报告

正式创建公开 GitHub 仓库后，建议开启 GitHub 的 **Private vulnerability reporting**，作为首选报告渠道。

在设置专门安全联系方式之前，请不要在公开 Issue 中粘贴密码、token、抓包、家庭网络参数或可利用的详细调试输出。

## 支持版本

当前属于实验性项目，暂不维护 LTS 分支。安全修复以最新公开版本为主。
