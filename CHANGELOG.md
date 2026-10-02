# 变更记录

本文件记录 KidTime 的公开版本变化。

## v0.1.1

- Fix Xiaomi BE6500 Router Adapter blacklist control.
- Add required `model=0` parameter to `/api/xqnetwork/edit_device`.
- Verified blocking and restoring for both configured 2.4 GHz and 5 GHz device MAC addresses.

## [0.1.0] - 2026-10-01

首个公开 Release Candidate。

### 新增

- 周一至周日独立时间窗口和每日额度；
- 基于 nftables 计数器采样的 ACTIVE/IDLE 计时；
- 已验证 Xiaomi BE6500 环境的 Router Adapter；
- 当天临时加时；
- 带 `MANAGEMENT_OFF` 状态的总管理开关；
- 基于 dnsmasq nftset 的 KidBlock 域名管理；
- 响应式 Web Panel 和 CGI API；
- 用于活动参数调试的 KidMonitor；
- 完整脱敏的公开配置示例。

### 调整

- 公开配置统一为 `BE6500_*` 变量；
- Router Adapter 统一放到 `etc-kidtime/router-adapters/`；
- daemon 周期改为读取 `CHECK_INTERVAL`；
- CGI 在校验前进行 URL decode；
- Web 状态拆分为活动状态、联网权限和限制原因；
- 总开关会记住并恢复关闭前的 KidBlock 状态。

### 修复

- 总开关重复实现和状态含义混杂；
- KidBlock 空列表处理；
- 重复添加域名；
- CLI 与 CGI 的域名校验不一致；
- BE6500 curl 请求缺少连接/总超时；
- 登录失败被管道末端命令掩盖；
- 手机端状态胶囊和按钮布局问题。

### 已验证

2026-10-01 在一套 R2S/ImmortalWrt + Xiaomi BE6500 + iPad 环境完成以下回归：

- Web 状态和七天配置读取；
- 七天配置保存；
- 临时加时；
- 总开关 ON/OFF，以及暂停后强制 ALLOW；
- 总开关恢复时恢复此前开启的 KidBlock；
- KidBlock 手动 ON/OFF；
- 域名新增、删除、非法输入拒绝、重复域名处理；
- Web Panel 主要手机端交互。

以上验证只代表该环境，不代表其他设备或网络拓扑无需重新调试。
