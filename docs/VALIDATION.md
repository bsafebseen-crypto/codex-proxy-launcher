# 验证与已知限制

本页是可重复执行的检查步骤，不保存某台电脑的扫描记录、用户名、令牌或聊天日志。目前实测环境为 Windows 11 和 Windows PowerShell 5.1；其他系统或架构须在目标电脑重新验证。

## 1. 语法与目录完整性

在仓库根目录用 Windows PowerShell 5.1 执行：

```powershell
Get-ChildItem -File *.ps1 | ForEach-Object {
    $parseTokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName, [ref]$parseTokens, [ref]$parseErrors)
    if ($parseErrors.Count) { throw ($parseErrors.Message -join '; ') }
    Write-Output ('PASS: ' + $_.Name)
}
```

应看到所有 `.ps1` 均通过。必须保留 `Get-CodexApp.ps1` 与两个主脚本；只复制 `.cmd` 文件不是完整安装。

## 2. 两种检查模式

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Shortcuts.ps1 -CheckOnly
$LASTEXITCODE
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Start-Codex-Proxy.ps1 -CheckOnly
$LASTEXITCODE
```

安装器检查只读取包信息并打印将使用的入口和图标路径，退出码为 `0`；不创建 `.local/`、图标、快捷方式或其他目录。主启动器检查会枚举 TCP 监听并发送无凭据联网探测；有通过项时打印自动选用地址并以 `0` 退出，无通过项时以 `1` 退出。两者都不启动 Codex。

检查前后核对已有入口及 `.codex/config.toml`、`.codex/.env`、Windows 系统代理和用户／系统环境变量，内容应保持不变。不要为通过检查而修改代理客户端设置、降低 TLS 验证或关闭安全软件。

## 3. 已运行保护和失败提示

仅在已确认桌面 Codex 正在运行时，运行普通 `Start-Codex-Proxy.ps1`：在找到通过的代理后，应提示 `Codex is still running` 并以 `1` 退出，不创建第二个实例，不关闭原实例。若 Codex 未运行，不要把这条命令当作只读检查执行。

在目标电脑本来未安装应用或本来无可用代理时，核对相应错误及退出码。不要为了构造失败场景卸载应用、停止用户代理或修改系统设置。

## 4. 安装与新路径验证

正常安装会创建自己的桌面和当前用户开始菜单快捷方式，并可能生成 `.local/Codex-Proxy.ico`。已有同名、同目标和同参数的入口可重复更新；指向其他位置的同名入口必须先检查并备份，否则安装器停止。

用 Windows 快捷方式属性或只读 `WScript.Shell.CreateShortcut` 核对：

- 目标为本机 `%SystemRoot%\System32\cmd.exe`；参数 `/d /c` 后引用当前仓库的 `Start-Codex-Proxy.cmd`，路径正确加双重引号。
- 工作目录为当前仓库，图标存在，未配置管理员运行。
- 目录含空格或中文时仍正确保留参数。迁移目录前先检查、备份旧入口，重建后重新核对；不要绕过同名冲突检查。
- 固定到“开始”须由用户在正常 Windows 菜单中操作。快捷方式存在不等于已经固定。

## 5. 真实连接验证

等用户保存并正常退出 Codex，再通过新入口启动。先记录新 GUI 启动时间，确认后端与自动选用的本机代理建立连接，然后连续对话，包含较长回复。

若查询 Codex 日志，先核实当前版本的存储位置和表结构；SQLite 必须以 `mode=ro` 连接并设置 `PRAGMA query_only=ON`。仅读取新启动后的必要网络事件，分别统计当前聊天与其他聊天中的断流、重试、超时、WebSocket 失败等。报告实际时区、查询截止时间和观察窗口；不要复制整个数据库、输出完整对话或读取 `auth.json`。

## 限制

- 未认证请求返回 `401` 仅说明该次 HTTP 代理、TLS 与目标服务路径可达，不是登录后的 WebSocket、模型生成或长期稳定性证明。未公开端点行为可能变化。
- 仅支持本机无认证 HTTP／混合代理；SOCKS 专用、远程代理、TUN 专用方式不在当前检测范围。
- 包名 `OpenAI.Codex`、主应用 ID `App`、探测端点和图标文件名可能随上游更新改变；须据新电脑真实安装信息适配，不能猜路径。
- Codex 运行中不会热切换代理。客户端或端口变化后应由用户完全退出，再通过启动器启动。
- 快捷方式是本机生成物，不适合跨电脑复制；应用账号和代理配置不由此仓库迁移。
