# KidTime v0.1.0 — 首个公开 Release Candidate

KidTime 是一套运行在 OpenWrt 家庭网络中的小型管理项目，核心目标是：

> 只在设备真正被使用时扣减时间，只限制确实需要限制的内容。

首个公开候选版本包括：

- 周一至周日独立时段和额度；
- 基于 nftables 流量计数的 ACTIVE/IDLE 计时；
- 当天临时加时；
- 一键暂停/恢复整个管理系统；
- 在已验证环境中通过 Xiaomi BE6500 Router Adapter 控制整台设备联网；
- 基于 dnsmasq + nftables 的 KidBlock 域名限制；
- 面向日常使用的响应式 Web Panel；
- 用于临时抓包和参数调试的 KidMonitor。

## 已验证环境

当前基线已在以下环境完成回归：

- R2S + ImmortalWrt/OpenWrt；
- Xiaomi BE6500 主路由；
- iPad 作为受控终端；
- 家庭网络同时存在 IPv4 和 IPv6。

其他路由器、固件版本、网络拓扑和终端需要自行验证和调参。

## 重要安全提示

Web CGI 没有内置认证，并且使用 GET 执行写操作。只能部署在可信管理网络，并应由上层访问控制保护；不要直接暴露到互联网。

## 当前限制

- 只支持一个受控设备；
- 时间窗口不能跨午夜；
- KidBlock 只覆盖 IPv4；
- Router Adapter 路径仍在 core 中写死；
- ACTIVE/IDLE 参数来自当前 iPad 场景，不是通用默认最佳值。

部署前请阅读 `README.md`、`docs/INSTALL.md`、`SECURITY.md` 和 `CHANGELOG.md`。
