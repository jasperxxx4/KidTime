# KidTime Project Context

## 文档定位

本文面向后续开发、维护和视频制作，解释项目为什么存在、关键设计是怎样形成的、当前代码基线是什么，以及哪些事项仍未完成。安装和日常使用只看 [README.md](README.md)；安装升级细节见 [docs/INSTALL.md](docs/INSTALL.md)。

维护时建议按以下顺序核对：

1. 当前代码；
2. `README.md`；
3. `docs/INSTALL.md` 与 `SECURITY.md`；
4. 本文件。

## 项目起源

KidTime 来自真实的家庭网络管理需求。孩子需要使用 iPad 完成资料查询、开放性作业、英语口语练习和其他学习任务，完全没收设备或彻底断网并不现实；另一方面，传统路由器和 App 分类管控容易出现两类问题：

- 限制某个 App 后，视频仍可从浏览器、搜索或词典等入口访问；
- 限制范围过大时，又会误伤正常学习工具。

因此项目目标不是“最大限度封锁”，而是：

> 只在真正使用设备时扣减时间，只限制需要限制的内容，并尽量保留正常学习能力。

项目形成了两个相互独立但可组合的方向：

- KidTime Core：管理时间、额度、活动状态和联网许可。
- KidBlock：以域名为入口补充限制特定内容。

KidMonitor 只服务于参数调试，不是日常运行依赖。

## 已验证环境与网络边界

主要验证环境：

- 主路由：Xiaomi BE6500；
- 旁路由/网关：R2S + OpenWrt；
- 主要终端：iPad；
- 家庭网络同时存在 IPv4 和 IPv6。

R2S 能看到指定设备的部分网络活动，KidTime 在 R2S 上判断状态；实际断网/恢复由 BE6500 Router Adapter 调用主路由接口完成。这样可以降低“只在旁路由阻止 IPv4、设备却从主路由 IPv6 继续联网”的绕过风险。

这不是对 R2S 的硬依赖。迁移的必要条件是：运行 KidTime 的节点能看到目标设备的实际流量，并能执行或触发可靠的联网控制。普通 LAN 服务器如果不在流量路径上，无法仅靠当前 nftables 计数器正确判断使用状态。

## 当前代码基线（2026-10-01 审阅）

### KidTime Core

入口为 `bin/kidtime`，当前实现：

- 每天独立的开始时间、结束时间和额度；
- `/tmp/kidtime/state` 当天状态，约每分钟复制到 `/etc/kidtime/state`；
- 临时加时保存在 `BONUS_SECONDS`，跨日清零；
- 不在时段时标记 `OUT_OF_WINDOW` 并 BLOCK；
- 达到 `LIMIT_SECONDS + BONUS_SECONDS` 时标记 `LIMIT_REACHED` 并 BLOCK；
- 总管理关闭时标记 `MANAGEMENT_OFF`，允许联网且停止计时；
- 仅在期望的 Router 状态变化时调用适配器。

时间窗口判断是 `START <= 当前时间 < END`，所以不支持跨午夜窗口。系统重启、守护进程停顿或时钟变化导致 tick 间隔异常时，单轮计时会回退到 `CHECK_INTERVAL`，避免一次补记很长时间。

### ACTIVE/IDLE 判定

`firewall.sh` 为目标 `DEVICE_IP` 设置上行和下行 named counter。`kidtime` 每轮读取累计字节数，并维护最近 5 次采样的命中历史：

1. 任一方向字节数增长，本轮为命中；
2. 5 次中至少 3 次命中，IDLE 才转为 ACTIVE；
3. ACTIVE 时，本轮有流量就继续计时并清空空闲累计；
4. ACTIVE 时短暂无流量，在 `IDLE_TIMEOUT` 内仍计时，避免阅读/缓冲间隙频繁切换；
5. 超过超时后进入 IDLE，停止计时。

若采样间隔超过 12 秒，5 次历史会重置。当前 daemon 固定每 6 秒调用一次 tick；`CHECK_INTERVAL` 并不控制 daemon 的 sleep。

这些参数来自特定 iPad 场景。Windows Update、云同步、后台推送、浏览器标签等都可能造成无人使用时仍有流量，因此其他设备必须重新采样调优，不能照搬为通用最佳值。

### Router Adapter

核心程序把 allow/block 委托给 `/etc/kidtime/router-adapters/be6500_control.sh`。当前 BE6500 实现：

- 从配置读取路由地址、登录设备标识和 2.4G/5G MAC；
- 从独立密码文件读取密码并计算登录摘要；
- 获取短期 token 后，通过 HTTP 调用路由器接口；
- 对两条 MAC 分别执行 allow 或 block。

核心仍然硬编码了 BE6500 控制脚本路径，所以“可替换适配器”目前是文件接口层面的约定，还不是配置化插件系统。

### KidBlock

KidBlock 使用 `kidblock-domains.txt`、dnsmasq nftset 和 `inet kidtime video4`：

- `on/off/status/add/del/list/apply` 均已实现；
- 应用规则时先清空旧集合，再生成 `/tmp/dnsmasq.d/kidblock.conf`；
- 主动解析当前 IPv4，并让后续 DNS 查询继续更新集合；
- 规则变化且 KidBlock 开启时会重启 dnsmasq。

它是域名到动态 IPv4 的补充控制，不是内容识别引擎。共享 CDN、DoH、QUIC、IPv6 和客户端缓存都可能降低效果或造成误伤。域名候选必须通过“目标内容、普通搜索、图片、学习 App”等对照场景短时验证。

### Web Panel V1

Web Panel 已实现，不再属于后续计划。它是单页响应式界面，调用一个 CGI 入口，提供：

- 总管理开关；
- 每 7 秒自动刷新的状态卡；
- 固定或自定义加时；
- 七天规则读取与统一保存；
- KidBlock 状态、开关、列表、添加和删除。

页面显示的状态来自 `kidtime status-json`。实际 JSON 字段为：

```json
{
  "device": "Child device",
  "date": "2026-10-01",
  "query_time": "2026-10-01 11:00:00",
  "window_start": "08:00",
  "window_end": "21:00",
  "limit_seconds": 3600,
  "used_seconds": 120,
  "remaining_seconds": 3480,
  "activity_state": "ACTIVE",
  "access_state": "ALLOW",
  "restriction_reason": "NONE"
}
```

旧规格中的 `status`、`router_state` 字段并不存在于当前输出。

### 总开关语义

`master-off` 会创建 `/etc/kidtime/master.disabled`，尝试记住 KidBlock 先前是否开启，关闭 KidBlock，然后执行 tick 使路由状态变为 ALLOW。`master-on` 删除标记，仅在之前记录为开启时恢复 KidBlock，再执行 tick 重新按规则判断。

这不是“人工强制 BLOCK/ALLOW”。管理开启后，下一次 tick 仍以时间窗口、额度和活动状态为准。

## 配置与公开边界

私有配置、密码、token、真实 MAC、私网地址、抓包和访问日志不应进入公开版本。公开模板只应保留示例值。

2026-10-01 收口修订已经统一公开配置：仓库只保留完整、脱敏的 `config.example`，包括 core、firewall 和 BE6500 适配器实际需要的字段；真实 `config` 由 `.gitignore` 排除。旧变量名不再作为公开接口保留，现网升级时需要把私有值迁移到 `BE6500_*` 字段。

配置文件由 shell 直接 source，必须限制写权限。密码文件应独立保存并设为 `0600`。

## 安全模型

当前 Web Panel 的设计前提是“可信家庭管理网 + 上层访问控制”，不是公网应用：

- CGI 没有自身认证、会话、权限分级或 CSRF token；
- 所有 action 都通过 GET 参数，包括写操作；
- CGI 能改写 `/etc/kidtime/config` 并调用高权限命令；
- 路由器登录和控制请求使用 HTTP；
- JSON 输出未完整转义来自配置/域名文件的字符串。

部署必须限制来源并使用上层认证；不得把 CGI 暴露到互联网或不可信局域网。若未来转为多人或远程使用，应先改为带认证的 POST API、CSRF 防护、最小权限执行和 HTTPS。

## 本次代码审阅发现

2026-10-01 已完成第一批静态修复：统一公开配置、清理重复总开关代码、补充 `MANAGEMENT_OFF`、让 daemon 使用 `CHECK_INTERVAL`、统一加时/域名输入校验、过滤 KidBlock 空列表、增加基础 JSON 转义，并在同目录校验后替换配置。

现场预部署检查发现 ImmortalWrt 未安装 `timeout`，因此 BE6500 登录与控制脚本已直接为 curl 增加 5 秒连接超时和 15 秒总超时，避免路由器不可达时长期挂起。

同次检查还确认 BE6500 登录 nonce 的随机尾数必须保持现网已验证的不补零整数格式；固定四位补零会导致该固件拒绝登录。登录脚本现已显式检查 curl 和 token，避免管道末端 `sed` 掩盖请求失败。

仍需处理：

1. CGI 写操作使用 GET，且没有自身认证/授权或 CSRF 防护。
2. JSON 尚未覆盖全部控制字符，只适合受控的简单配置值。
3. Router Adapter 路径在 core 中写死，尚不能通过配置选择。
4. KidBlock/防火墙内容规则只覆盖 IPv4；整体断网依赖主路由适配器。
5. 时间窗口不能跨午夜，且当前只支持单设备。

2026-10-01 已在 R2S/ImmortalWrt + Xiaomi BE6500 + iPad 环境完成一次完整现场回归，覆盖 Web 配置读写、加时、总开关、KidBlock 开关与恢复、域名增删/校验/去重以及主要 Web Panel 交互。其他设备、固件和网络拓扑仍需独立验证。

## 设计原则

- CLI 是业务核心，Web 只做操作层，不重复实现计时和封锁逻辑。
- App 自带且准确的青少年模式优先；网络层规则只补充不足。
- 域名发现只产生候选，不自动大范围封锁。
- 优先减少误伤，不追求最大封锁覆盖率。
- 抓包只在调试期间启用，不默认长期保存。
- 个人设备参数与通用默认值分开，不把当前家庭参数写成普适结论。
- README 只写已实现能力；计划和历史放在明确标注的上下文或归档文档中。

## 视频叙事保留项

本项目适合用真实问题驱动，而不是从命令和配置讲起。建议保留的主线：

1. 学习需要联网，完全断网不可行；
2. App 分类和简单时长限制都可能被绕过或误伤；
3. “联网多久”与“真正使用多久”不是一回事；
4. 通过流量采样、迟滞和实际测试形成 ACTIVE/IDLE 逻辑；
5. 旁路由只控 IPv4 可能被 IPv6 绕过，因此引入主路由适配器；
6. KidBlock 用域名候选和短时验证补充内容限制；
7. Web Panel 把高频操作变成家庭用户可理解的按钮和状态卡。

视觉上优先使用网络拓扑、状态机、流量对比和“域名 -> DNS -> 动态 IP -> nftables”流程；真实密码、MAC、IP、token、抓包内容和家庭网络细节必须脱敏。

## 后续方向

按当前代码风险排序：

1. 完成首个 GitHub 公开发布版，包括许可证、版本说明、安装/升级/卸载文档和截图；
2. 为 CGI 增加可靠的认证/授权边界，改用 POST 并加入 CSRF 防护；
3. 完善控制字符转义、HTTP 错误码和失败回滚；
4. 扩展更多 Router Adapter，并减少 core 中的硬编码路径；
5. 再考虑多设备、跨午夜时段、历史统计、域名发现/试封。

## 公开仓库文档策略

公开仓库只维护当前事实和必要的维护背景：

- `README.md`：功能、使用、限制与安全边界；
- `docs/INSTALL.md`：安装、升级、回滚与卸载；
- `SECURITY.md`：安全模型和漏洞报告；
- `CHANGELOG.md`：公开版本历史；
- 本文件：项目背景、设计取舍和后续方向。

一次性同步记录、真实抓包、家庭网络参数、私有备份和开发过程压缩包不进入公开仓库。
