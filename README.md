# Codex 自动代理启动器

用于 Windows 桌面版 Codex 的个人启动工具。每次启动时检测本机 HTTP／混合代理，通过不带登录凭据的 HTTPS 请求检查候选，自动使用可用的一项，无需手动选择端口。

仓库：[bsafebseen-crypto/codex-proxy-launcher](https://github.com/bsafebseen-crypto/codex-proxy-launcher)。这是个人维护的工具，不是 OpenAI 官方产品，也不保证解决所有“Reconnecting 1/5…5/5”问题。

## 复制给 Agent 的简短提示词

将下面整段复制给新电脑上的 Agent：

```text
请在这台 Windows 电脑安装并适配 Codex 自动代理启动器：
https://github.com/bsafebseen-crypto/codex-proxy-launcher

先完整克隆或下载仓库（已有则复用，保留本地修改），阅读 AGENTS.md、README.md、docs/AGENT-HANDOFF.md 和实际脚本，按文档操作。
自动检测可用本地代理，先检查预览，再安装带图标的桌面和开始菜单入口并验证。正常安装已授权，请直接完成。
代理只用于新 Codex 进程；不改系统代理、其他软件或 Codex 配置，不关闭现有 Codex。真实启动等我正常退出，最后报告结果及恢复方法。
```

## 换一台电脑怎么用

适用范围：Windows 原生环境、当前用户已安装的 `OpenAI.Codex` Store／MSIX 包、Windows PowerShell 5.1 和 `curl.exe`。已在 Windows 11 上验证；未实测 Windows 10、ARM64、WSL、macOS 或 Linux。具体应用支持的系统要求以 [OpenAI Windows 文档](https://learn.chatgpt.com/docs/windows/windows-app) 为准。

1. 在新电脑安装并正常登录官方桌面应用，先确认 `Get-AppxPackage -Name OpenAI.Codex` 能找到它。安装来源参见 [OpenAI Windows 部署说明](https://learn.chatgpt.com/docs/enterprise/windows-deployment)。本工具不安装应用、不迁移账号登录信息。
2. 安装并开启自己的 Clash、v2rayN、mihomo、sing-box 等代理客户端，确保至少有一个本机 HTTP／混合端口；SOCKS 专用端口不能直接用于本工具。
3. 将这个公开仓库克隆或下载 ZIP 并解压到一个长期保留的目录：

   ```powershell
   git clone https://github.com/bsafebseen-crypto/codex-proxy-launcher.git
   cd codex-proxy-launcher
   ```

4. 先运行检查。这两个命令都不会启动 Codex；第二个会向 Codex 服务发送无登录凭据的网络请求：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Shortcuts.ps1 -CheckOnly
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-Codex-Proxy.ps1 -CheckOnly
   ```

5. 双击 `Install-Shortcuts.cmd`，在新电脑上生成带图标的 **Codex Auto Proxy** 桌面和开始菜单入口。需要固定到“开始”时，在开始菜单中右键这个入口，选择“固定到开始”。安装器不会自动固定，也不会要求管理员权限。若已有同名且指向别处的入口，安装器会停止，先查看并备份旧入口再处理。
6. 保存工作，完全退出 Codex，再点击 **Codex Auto Proxy**。也可以直接双击 `Start-Codex-Proxy.cmd`。连续对话几轮并查看新日志，验证是否还会重连。

不要直接在 ZIP 压缩包里运行，不要复制另一台电脑的 `.lnk`。快捷方式使用新电脑的完整路径；移动仓库目录后，先核对并备份旧入口，再重新运行安装器。

`ExecutionPolicy Bypass` 只作用于这一次 PowerShell 进程，不修改持久执行策略。CMD 文件会保留控制台供你查看结果。不要把令牌写入命令或源码，也不建议用“下载后立即执行”的单行命令。

## 自动适配哪些内容

- **Codex 安装目录、版本和主程序文件名**：从本机 `Get-AppxPackage` 和包清单读取，不写死用户名、安装版本或 `ChatGPT.exe`。当前识别包名为 `OpenAI.Codex`、主应用 ID 为 `App`；若上游改变这两个标识，需按 Agent 教程检查后适配。
- **代理端口**：枚举全部 TCP 监听，检查代理进程的实际端口、已启用的本机系统代理端口及常见端口。常见端口为 7890、7891、7897、1080、10808、10809、10810、2080、2081、20170、20171、8080、8118、8888；已识别的代理进程其他监听端口也会检测。
- **多个代理同时运行**：全部候选检测后，优先使用已启用系统代理配置中的本机端口，再按端口排序，自动使用首个通过检查的地址。只读取系统代理配置，不修改它。
- **快捷方式和图标**：在新电脑上重新生成；从本机应用复制图标到忽略提交的 `.local/`。如果没有匹配图标资源，使用应用可执行文件的图标。这里使用英文入口名，以便 Windows PowerShell 5.1 在不同系统编码下都能正常运行。

## 影响范围和恢复

只为新启动的 Codex 进程设置：

```text
HTTP_PROXY=http://本机已验证地址:端口
HTTPS_PROXY=http://本机已验证地址:端口
NO_PROXY=localhost,127.0.0.1,::1
```

使用 `ProcessStartInfo.EnvironmentVariables`，不修改启动脚本自身、用户或系统的环境变量。不会创建或修改 `.codex/.env`、`config.toml`、代理客户端配置或系统代理。

独立运行的 WorkBuddy、豆包工作及其独立启动的 PowerShell 不会从本工具继承这些变量。Codex 自己启动的部分工具可能继承代理；若这些工具访问国内服务受影响，应只对相应工具做局部适配，不要扩大为系统级代理修改。

恢复原启动方式：完全退出通过本工具打开的 Codex，从原来的开始菜单入口正常打开。要移除工具，取消固定并删除 **Codex Auto Proxy** 两个快捷方式；确认没有入口再引用仓库后，可删除仓库目录。不要删除 Codex 本身、登录信息或 `.codex` 目录。

## 检测通过代表什么

主启动器通过 HTTP 代理发送一个不带登录凭据的 WebSocket 升级请求。当前服务返回预期的 **401** 时记为通过，说明这次代理、TLS 和目标服务路径可达；不代表完成了登录或 WebSocket 升级，也不代表生成请求或长连接一定稳定。

这个未公开服务端点和返回行为可能改变。如果全部检测失败，先排查端点、状态码、DNS、证书和代理，再根据实际证据修改探测方式；不要直接把“端口在监听”当作代理有效。运行中不会切换代理；换客户端或端口后，要完全退出 Codex再通过工具启动。

## 给其他 Agent 的文件

- [部署和适配教程、可直接复制的提示词](docs/AGENT-HANDOFF.md)
- [仓库维护约束](AGENTS.md)
- [验证与已知限制](docs/VALIDATION.md)

```text
Get-CodexApp.ps1          读取本机应用包清单，共享给两个入口脚本
Start-Codex-Proxy.ps1     自动检测代理并启动；-CheckOnly 仅检查
Start-Codex-Proxy.cmd     双击启动入口
Install-Shortcuts.ps1    在本机生成桌面／开始菜单入口；-CheckOnly 仅预览
Install-Shortcuts.cmd    双击安装入口
docs/                   新电脑部署、适配和验证说明
.local/                 本机生成图标，Git 忽略
```

日常更新使用 `git pull --ff-only`；如源码或安装位置发生变化，先查看差异并重新做检查。此仓库不包含登录凭据、代理节点、订阅、历史聊天、日志数据库、本机扫描记录、预制快捷方式或复制的应用图标。
