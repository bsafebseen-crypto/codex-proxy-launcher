param([switch]$CheckOnly)

$ErrorActionPreference = 'Stop'

try {
    . (Join-Path $PSScriptRoot 'Get-CodexApp.ps1')
    $codexApp = Get-CodexApp
    $launcherPath = Join-Path $PSScriptRoot 'Start-Codex-Proxy.cmd'
    if (-not (Test-Path -LiteralPath $launcherPath)) { throw 'Start-Codex-Proxy.cmd is missing.' }
    $shortcutName = 'Codex Auto Proxy.lnk'
    $desktopPath = [Environment]::GetFolderPath('Desktop')
    $programsPath = [Environment]::GetFolderPath('Programs')
    $targetPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    $arguments = '/d /c ""' + $launcherPath + '""'
    $shortcutPaths = @((Join-Path $desktopPath $shortcutName), (Join-Path $programsPath $shortcutName))
    $sourceIcon = @('resources\chatgpt-app-light.ico', 'resources\icon-chatgpt.ico') |
        ForEach-Object { Join-Path (Split-Path -Parent $codexApp.Path) $_ } |
        Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    $localIcon = Join-Path $PSScriptRoot '.local\Codex-Proxy.ico'
    $iconLocation = if ($sourceIcon) { $localIcon + ',0' } else { $codexApp.Path + ',0' }

    Write-Host ('Codex package: {0} {1}' -f $codexApp.PackageName, $codexApp.PackageVersion)
    Write-Host ('Launcher: {0}' -f $launcherPath)
    foreach ($shortcutPath in $shortcutPaths) { Write-Host ('Shortcut: {0}' -f $shortcutPath) }
    Write-Host ('Icon: {0}' -f $iconLocation)
    if ($CheckOnly) {
        Write-Host 'Check only: no shortcuts, icons, or settings were written.'
        exit 0
    }

    $shortcutShell = New-Object -ComObject WScript.Shell
    try {
        # Refuse to replace another installation's or another app's shortcut.
        foreach ($shortcutPath in $shortcutPaths) {
            if (Test-Path -LiteralPath $shortcutPath) {
                $existing = $shortcutShell.CreateShortcut($shortcutPath)
                try {
                    if ($existing.TargetPath -ne $targetPath -or $existing.Arguments -ne $arguments) {
                        throw "Shortcut already points elsewhere. Review and back it up first: $shortcutPath"
                    }
                } finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($existing) }
            }
        }
        if ($sourceIcon) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $localIcon) -Force | Out-Null
            Copy-Item -LiteralPath $sourceIcon -Destination $localIcon -Force
        }
        foreach ($shortcutPath in $shortcutPaths) {
            New-Item -ItemType Directory -Path (Split-Path -Parent $shortcutPath) -Force | Out-Null
            $shortcut = $shortcutShell.CreateShortcut($shortcutPath)
            try {
                $shortcut.TargetPath = $targetPath
                $shortcut.Arguments = $arguments
                $shortcut.WorkingDirectory = $PSScriptRoot
                $shortcut.IconLocation = $iconLocation
                $shortcut.Description = 'Detect a local HTTP proxy and start Codex with process-only proxy variables.'
                $shortcut.WindowStyle = 1
                $shortcut.Save()
            } finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut) }
        }
    } finally { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shortcutShell) }
    Write-Host 'Desktop and Start-menu shortcuts created: Codex Auto Proxy.'
    Write-Host 'To pin it, right-click Codex Auto Proxy in the Start menu and choose Pin to Start.'
    exit 0
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
