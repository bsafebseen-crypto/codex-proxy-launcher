# 在另一台 Windows 电脑接续使用

本教程供用户和其他 Agent 在新电脑检查、安装及适配本启动器。仓库保存通用源码；新电脑必须重新发现 Codex 安装位置、代理端口和快捷方式位置，不能沿用旧电脑的运行状态。

## 功能和边界

当前已在 Windows 11、Windows PowerShell 5.1、可用的 `curl.exe` 和当前用户安装的 Codex Store／MSIX 包 `OpenAI.Codex` 上验证。Windows 10、ARM64 未实测，不能据此宣称兼容；应用支持的系统要求以 README 链接的 OpenAI 官方文档为准。代理客户端需要由用户先开启，并提供本机 HTTP／混合监听端口。仅 SOCKS 端口不属于当前启动器的通过条件。

主启动器读取当前 TCP 监听和进程归属，结合代理进程实际端口、常用端口及已启用的本机系统代理端口生成候选。它枚举全部监听记录，并非向全部端口发送探测；只验证筛出的本机代理候选。已启用的系统代理端口优先，其余按端口排序。检测全部候选后自动采用第一个通过项，不让用户选端口。

每个候选通过 HTTP 代理向 `https://chatgpt.com/backend-api/codex/responses` 发送无凭据的 HTTPS 请求，并携带 WebSocket Upgrade 头。当前预期结果是未认证请求返回 `401`，这比仅发现端口监听多验证了一层服务可达性。它不是已登录的 WebSocket 会话，也不证明登录、模型生成或长连接稳定。服务端的接口、协议和状态码可能变化，不能保证 `401` 判定永远有效。

启动时仅通过 `ProcessStartInfo.EnvironmentVariables` 给新 Codex 进程设置 `HTTP_PROXY`、`HTTPS_PROXY`、`NO_PROXY`，使用 `UseShellExecute = $false`。不会修改 Windows 系统代理、持久环境变量、代理客户端配置、`.codex/.env` 或 `config.toml`。独立启动的 WorkBuddy、豆包及其他软件不会继承这里设置的变量；Codex 自己后续创建的部分子进程可能继承。

## 文件职责

| 文件 | 职责 |
| --- | --- |
| `Get-CodexApp.ps1` | 共享发现函数；读取 `OpenAI.Codex` 包清单中主应用 `Id=App` 的 `Executable`，供启动器和安装器使用。 |
| `Start-Codex-Proxy.ps1` | 动态发现代理、验证所有候选、自动选用并启动 Codex；保留 `-CheckOnly`。 |
| `Start-Codex-Proxy.cmd` | 用 Windows PowerShell 5.1 调用同目录主脚本，显示结果并保留窗口便于阅读。 |
| `Install-Shortcuts.ps1` | 在本机生成桌面和当前用户开始菜单入口及本地图标；`-CheckOnly` 仅预览。 |
| `Install-Shortcuts.cmd` | 调用同目录快捷方式安装脚本。 |
| `README.md` | 用户安装入口、仓库地址及简要说明。 |
| `AGENTS.md` | 修改、隐私、影响范围和验证约束。 |
| `docs/AGENT-HANDOFF.md` | 新电脑完整操作和可复制给 Agent 的任务提示词。 |
| `.local/` | 正常安装时按需生成的本地图标，Git 忽略；没有匹配资源时直接引用本机可执行文件图标。 |

请完整保留整个仓库，包括共享 `Get-CodexApp.ps1`、两组 `.cmd`／`.ps1` 和文档；不能只复制两个启动文件。源码包不含预制 `.lnk` 或 `.ico`，新电脑正常安装时才生成自己的 `Codex Auto Proxy` 入口和本地图标。安装后快捷方式引用当前仓库及其图标；不要从临时解压目录、浏览器缓存或即将删除的位置安装入口。

移动或重命名仓库后，旧 `Codex Auto Proxy` 入口可能仍指向旧目录。安装器会拒绝覆盖同名但指向其他目录或软件的入口，不会自动覆盖或改名。必须先核对旧入口目标、备份并移除需要替换的旧入口，再在新位置重新安装；不能直接重跑就认为旧入口已自动更新。不要移除属于其他软件的同名入口，应先说明冲突并让用户决定。

## 新电脑操作顺序

1. 从官方渠道安装 Codex，正常启动、登录，确认账号可用。安装并开启自己使用的代理客户端，确认其 HTTP／混合端口已开启。启动器不会替你安装、配置或启动代理。
2. 将这个公开仓库完整 clone／下载到准备长期保留的目录。下载 ZIP 时先完整解压，保留共享脚本和所有配套文件。不要复制旧电脑的 `.lnk`、登录配置或本机诊断文件。
3. 在仓库根目录打开 Windows PowerShell，执行下面的环境检查和两个预览命令。主启动器的检查可以在 Codex 仍运行时执行。
4. 预览无误后运行快捷方式安装器，正常安装时还会检查同名入口冲突。它在本机生成英文名 **Codex Auto Proxy** 的桌面和当前用户开始菜单入口，按需复制图标到 `.local/`，没有匹配资源时使用本机可执行文件图标。它不自动固定到“开始”；需要固定时，在正常 Windows 界面右键 **Codex Auto Proxy** 选择固定。若报告同名入口指向别处，先核对并备份／移除属于旧安装的入口，再重试；预览成功不代表已完成安装或排除了同名冲突。
5. 保存当前工作，通过应用正常退出 Codex。仅关窗口可能仍有后台进程；启动器提示仍运行时，应正常退出后重试，不能强杀。
6. 点击 **Codex Auto Proxy** 或运行 `Start-Codex-Proxy.cmd`。确认检测结果中存在通过项，以及自动选用的本机代理地址。没有可用项时先检查代理客户端，不要把多个代理 URL 拼进同一环境变量。
7. 在新启动的 Codex 连续对话几轮，包含一次较长回复。记录启动时间，并只读检查新日志和连接证据，确认没有把旧电脑或旧进程的错误当作本次结果。

在仓库根目录执行：

```powershell
$PSVersionTable.PSVersion
Get-Command curl.exe
Get-AppxPackage -Name OpenAI.Codex | Select-Object Name, Version

powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-Codex-Proxy.ps1 -CheckOnly
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Shortcuts.ps1 -CheckOnly
```

`Start-Codex-Proxy.ps1 -CheckOnly` 会检查本机并向公开服务发起不带凭据的探测，但不启动 Codex、不改配置。`Install-Shortcuts.ps1 -CheckOnly` 仅预览本机计划，不创建或覆盖快捷方式、目录和图标。两个模式不能混为同一种检查。

确认预览后，运行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Shortcuts.ps1
```

这里的 `ExecutionPolicy Bypass` 只作用于这次 PowerShell 进程，不是修改系统持久执行策略。不需要管理员权限；不要为了运行本项目而提权、关闭安全软件或改持久策略。

## 交给其他 Agent 的完整提示词

复制以下整段，并让 Agent 在本仓库目录中执行：

```text
请在这台 Windows 电脑核查并适配当前仓库 codex-proxy-launcher，使我能通过带图标的桌面和开始菜单入口启动 Codex，并让 Codex 使用当前可用的本地代理。先阅读仓库 AGENTS.md、README.md、docs/AGENT-HANDOFF.md 和实际脚本，核实环境，再作最小修改。

当前已验证环境为Windows 11、Windows PowerShell 5.1、curl.exe、当前用户的Codex Store/MSIX包OpenAI.Codex；Windows 10和ARM64未实测，具体系统要求以README链接的OpenAI官方文档为准。先只读确认本机条件，通过共享Get-CodexApp.ps1读取Get-AppxPackageManifest中主应用Id=App的Executable，核实实际可执行路径、当前代理进程和监听端口。代理可能是Clash、mihomo、v2rayN、Xray、sing-box等；不固定端口，不按端口号推断协议，不扫描整个硬盘，不读取订阅、节点、密钥或登录凭据。完整保留整个仓库和共享脚本，不能只复制两个启动文件。

保留主启动器 -CheckOnly。它应枚举监听，结合代理进程实际端口、常用端口、已启用系统代理的本机端口生成候选，测试全部候选，再自动采用第一个通过项；列出结果，不让我选择。当前验证方式是经 HTTP 代理发送不带凭据的 HTTPS WebSocket Upgrade 请求，预期目标 Codex 接口返回401。不要加载用户 curl 配置，不关闭TLS证书校验，不把端口监听、CONNECT成功或401结果解释成已证明长连接稳定。如果服务行为变化，先据证分析，不能直接接受任意状态码来绕过检查。

代理变量只放入新 Codex 进程的 ProcessStartInfo.EnvironmentVariables，UseShellExecute=false；不得写用户/系统环境，不得用 setx 或注册表修改持久环境。不得修改 Windows 系统代理、Clash/v2rayN 配置、.codex/.env 或 config.toml。不得影响独立运行的 WorkBuddy、豆包及其工具。不能自动关闭、杀死或重启已运行的 Codex；启动前重新检查，若还在运行就提示我保存并正常退出。

请在这台电脑用Install-Shortcuts.ps1重新生成英文名Codex Auto Proxy的桌面和当前用户开始菜单入口，不复制旧电脑.lnk。先执行安装器-CheckOnly，确认只预览、不创建或覆盖快捷方式、目录和图标，再正常安装；仅预览通过不代表已排除同名冲突或完成安装。安装器拒绝覆盖同名但指向其他目录或软件的入口，也不自动改名；若移动了仓库，先核对并备份/移除属于旧安装的入口再重装，不要直接覆盖或误删其他软件入口。源码包不含lnk/ico；图标在正常安装时复制到Git忽略的.local/，无匹配资源时使用本机exe图标。入口动态引用当前仓库与本机系统位置，不写死用户名、旧路径或包版本。不要自动固定到开始、修改布局数据库或写注册表；需要固定时由我正常右键完成。正常安装属于本次任务授权，别停在“可以安装”的建议上。

通常可执行文件改名已经由共享Get-CodexApp.ps1的清单读取覆盖，不要增加硬编码。若包名、主应用Id=App或清单布局变化，先用Get-AppxPackageManifest核实声明，再对应实际GUI进程，最小修改共享发现函数与必要的运行检测；不要只改启动路径而漏改运行检查。非MSIX不属于当前默认支持范围，先核实真实安装来源和入口，说明证据与最小适配，不猜路径、不伪造包信息。遵循我的明确授权完成必要适配，不做无关重构。

验证：Windows PowerShell 5.1语法检查；主启动器和安装器两个-CheckOnly；检查无代理、Codex仍运行等失败提示与退出码；正常安装后只读核对快捷方式目标、参数、工作目录、图标及未配置提权。主脚本仍运行的拒绝检查不能偷偷创建第二个Codex实例。真实启动要等我正常退出现有Codex；不自动点击入口或重启正在工作的应用。

真实启动后记录实际北京时间、GUI启动时间和查询截止时间，先看新进程是否通过所选本机代理连接，再只读查询新的模型网络日志，分别统计当前聊天与其他聊天的断流、重试、请求超时、WebSocket预热超时、10054及连接失败。SQLite必须mode=ro并PRAGMA query_only=ON；若Python不可用，使用可用的只读工具，不为了检查安装依赖或导出整个数据库。不得输出完整对话、凭据或把旧错误混入当前窗口。短时间无错误只能报告该观察窗口正常。

这是公开仓库，仅保存通用源码和教程。不能提交旧.lnk、本机绝对路径、代理订阅/密钥、auth.json、SQLite、会话日志或本机报告；检查git diff和暂存清单。不擅自更改仓库可见性、另建仓库、推送或创建带本机信息的报告。最终告诉我实际修改、验证结果、未完成部分以及恢复官方入口的方法。
```

## 适配检查点

- **包与可执行路径**：共享 `Get-CodexApp.ps1` 以 `Get-AppxPackage -Name OpenAI.Codex` 查包，从 `Get-AppxPackageManifest` 中选择主应用 `Id=App`，读取其 `Executable` 并拼接本机包安装目录，不固定可执行文件名。普通版本升级或文件改名由这一流程覆盖；若包名、应用 ID 或清单布局变化，可先只读运行以下命令检查声明，并和实际进程路径核对：

  ```powershell
  $codexPackage = Get-AppxPackage -Name OpenAI.Codex | Select-Object -First 1
  $codexManifest = Get-AppxPackageManifest -Package $codexPackage.PackageFullName
  $codexManifest.Package.Applications.Application |
      Select-Object Id, Executable, EntryPoint
  ```

  声明可能指向启动器，需确认实际 GUI；必要时最小修改共享发现函数，并同步核查“已运行”判断。非 MSIX 安装没有这一包声明，当前默认不支持，不能假装上述命令已验证它。

- **代理发现**：目前候选限本机 IPv4／IPv6 回环或通配监听；不支持远程带认证代理。代理进程实际监听端口可补足常用端口清单。新客户端名称未匹配时，先据实际进程和监听验证，再最小补充模式。
- **协议与请求**：只认当前 HTTP／混合代理探测结果，不把 SOCKS 专用端口或管理端口直接写入 `HTTP_PROXY`。`curl.exe --disable` 是第一个参数；不能附加账号 Cookie／Token。若接口不再返回预期 `401`，需先核实公开接口行为和客户端变化。
- **快捷方式**：英文入口名为 `Codex Auto Proxy`，工作目录和参数引用当前完整仓库。以 `cmd.exe` 作为目标，检查 `/d /c` 参数及带空格路径的双重引号；`/d` 禁用 Cmd AutoRun。图标应指向新电脑的 `.local/` 副本或本机可执行文件，且未配置管理员运行。正常安装才检查同名入口归属；拒绝覆盖指向别处的入口属于预期保护，不能绕过。开始菜单固定是 Windows 用户操作，不能假定安装快捷方式就已经固定。
- **PowerShell 兼容**：`.ps1` 需兼容 5.1，避免 PS7 专用语法；含中文的脚本保存时注意 5.1 编码。不要把 `$host` 当普通变量。验证 CMD 调用时仍指向 Windows PowerShell 5.1，而不是依赖另一台电脑的 PowerShell 7。
- **依赖与失败**：Windows 10 旧版本可能没有可用 `curl.exe`；缺依赖时明确说明，不擅自下载二进制或安装软件。未安装包、无通过项、已运行 Codex 时应失败退出并说明原因，不自动启动代理或强杀进程。

## 验证记录应包含什么

在聊天中报告 Windows／PowerShell 版本、包版本、实际检查时间、是否安装了入口、是否真实启动，以及每个检查的结果。记录可用本机代理地址、进程与端口即可；不要收集其节点、订阅或登录信息。

启动后的日志验证应限定为新 GUI 启动时间至实际查询截止时间，并报告北京时间和时区。必要时限制最近 24 小时，但必须说明窗口。区分当前聊天、其他聊天和辅助服务；成功建立 WebSocket 是正常活动证据，不能用仅有“connecting”日志声称成功。查询成功但窗口内没有相关日志，也应如实报告“无足够活动证据”。

SQLite 连接形式为 `sqlite3.connect('file:.../logs_2.sqlite?mode=ro', uri=True)`，连接后执行 `PRAGMA query_only=ON`。路径在本机动态定位，不进入提交文件。先核实表结构，再只读取必要时间、level、target、thread 标识和脱敏错误摘要；不复制数据库，不读 `auth.json`。本机诊断结果留在聊天中，不写入可提交的仓库报告。

## 回滚和迁移

1. 保存工作，正常退出通过此启动器打开的 Codex。
2. 在 Windows 正常界面取消固定 **Codex Auto Proxy**，核实目标后删除本项目创建的桌面和当前用户开始菜单快捷方式；不要删除官方 Codex 或其他软件的入口。
3. 从官方 Codex 入口重新打开。新进程不再继承本启动器的代理变量，无需修改系统代理、删除 `.env` 或恢复注册表。
4. 不再使用时，确认没有入口继续引用仓库后，可删除仓库及 `.local/` 本地图标。若只是移动目录，完整保留整个仓库，在旧入口被核对、备份并移除后，再从新位置重新运行安装器；未处理的同名旧入口会阻止重装。旧固定入口必要时由用户取消后重新固定，不能认为安装器会自动迁移或覆盖它。
5. 换电脑时重新 clone／下载并重复本教程，不迁移 `.lnk`、凭据、代理配置、SQLite 或本机报告。仅同步经过检查的通用源码和教程。
