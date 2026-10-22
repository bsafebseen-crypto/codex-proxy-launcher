param([switch]$CheckOnly)

$ErrorActionPreference = 'Stop'

try {
    . (Join-Path $PSScriptRoot 'Get-CodexApp.ps1')
    $codexApp = Get-CodexApp
    $appPath = $codexApp.Path
    $curlPath = (Get-Command curl.exe -ErrorAction Stop).Source

    $processes = Get-CimInstance Win32_Process
    $processNames = @{}
    foreach ($item in $processes) { $processNames[[int]$item.ProcessId] = $item.Name }
    $proxyPattern = 'clash|mihomo|v2ray|xray|sing.?box|shadowsocks|ss-local|nekoray|nekobox|hysteria|trojan|naive|outline|tun2socks|brook|geph'
    $proxyIds = @($processes | Where-Object { $_.Name -match $proxyPattern } | ForEach-Object { $_.ProcessId })
    $listeners = @(Get-NetTCPConnection -State Listen)
    $commonPorts = @(7890, 7891, 7897, 1080, 10808, 10809, 10810, 2080, 2081, 20170, 20171, 8080, 8118, 8888)

    # Read the current local system-proxy ports for priority; never change them.
    $systemSettings = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $systemProxy = if ($systemSettings.ProxyEnable -eq 1) { $systemSettings.ProxyServer } else { '' }
    $systemPorts = @([regex]::Matches([string]$systemProxy, '(?:127\.0\.0\.1|localhost|\[::1\]):(\d+)') | ForEach-Object { [int]$_.Groups[1].Value })
    $proxyListeners = @($listeners | Where-Object {
        $_.LocalAddress -in @('127.0.0.1', '0.0.0.0', '::', '::1') -and
        ($_.OwningProcess -in $proxyIds -or $_.LocalPort -in $commonPorts -or $_.LocalPort -in $systemPorts)
    })
    $orderedPorts = @(@($systemPorts) + @($proxyListeners.LocalPort | Sort-Object -Unique) | Select-Object -Unique)
    $candidates = @()
    foreach ($port in $orderedPorts) {
        foreach ($listener in @($proxyListeners | Where-Object { $_.LocalPort -eq $port })) {
            $hosts = if ($listener.LocalAddress -eq '::1') { @('[::1]') } elseif ($listener.LocalAddress -eq '::') { @('127.0.0.1', '[::1]') } else { @('127.0.0.1') }
            foreach ($proxyHost in $hosts) {
                $url = 'http://{0}:{1}' -f $proxyHost, $port
                if ($url -notin $candidates.Url) {
                    $candidates += [pscustomobject]@{ Url = $url; Process = $processNames[[int]$listener.OwningProcess] }
                }
            }
        }
    }

    Write-Host ('Enumerated {0} TCP listeners; {1} local proxy candidates.' -f $listeners.Count, $candidates.Count)
    Write-Host 'Testing all candidates against the Codex service. No login credentials are sent.'
    $usable = @()
    foreach ($candidate in $candidates) {
        # A 401 on this unauthenticated WebSocket request confirms HTTPS service reachability.
        $status = & $curlPath --disable --silent --output NUL --connect-timeout 2 --max-time 6 --http1.1 `
            --proxy $candidate.Url --noproxy 'localhost,127.0.0.1,::1' `
            --header 'Connection: Upgrade' --header 'Upgrade: websocket' `
            --header 'Sec-WebSocket-Version: 13' --header 'Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==' `
            --write-out '%{http_code}' 'https://chatgpt.com/backend-api/codex/responses'
        $passed = $LASTEXITCODE -eq 0 -and [string]$status -eq '401'
        $label = if ($passed) { 'PASS' } else { 'SKIP' }
        Write-Host ('[{0}] {1} ({2}) HTTP {3}' -f $label, $candidate.Url, $candidate.Process, $status)
        if ($passed) { $usable += $candidate }
    }
    if ($usable.Count -eq 0) {
        throw 'No usable local HTTP/mixed proxy found. Start Clash or v2rayN with an HTTP/mixed listener, then run this launcher again. No settings were changed.'
    }
    $selected = $usable[0]
    Write-Host ('Automatically selected: {0} ({1})' -f $selected.Url, $selected.Process)
    if ($CheckOnly) {
        Write-Host 'Check only: Codex was not started and no settings were changed.'
        exit 0
    }

    $appFileName = Split-Path -Leaf $appPath
    $runningCodex = @(Get-CimInstance Win32_Process -Filter "Name = '$appFileName'" | Where-Object {
        $_.ExecutablePath -like ('*\' + $codexApp.PackageName + '_*\' + $codexApp.RelativePath)
    })
    if ($runningCodex.Count -gt 0) {
        throw 'Codex is still running. Save your work, fully quit Codex, and run this launcher again. This script will not stop any processes.'
    }

    # Set proxy variables only in the new Codex process; leave this PowerShell unchanged.
    $launchInfo = New-Object System.Diagnostics.ProcessStartInfo
    $launchInfo.FileName = $appPath
    $launchInfo.WorkingDirectory = Split-Path -Parent $appPath
    $launchInfo.UseShellExecute = $false
    $launchInfo.EnvironmentVariables['HTTP_PROXY'] = $selected.Url
    $launchInfo.EnvironmentVariables['HTTPS_PROXY'] = $selected.Url
    $launchInfo.EnvironmentVariables['NO_PROXY'] = 'localhost,127.0.0.1,::1'
    $startedProcess = [System.Diagnostics.Process]::Start($launchInfo)
    if (-not $startedProcess) { throw 'Windows did not create the Codex process.' }
    Write-Host ('Codex launch requested (PID {0}). Send several messages to verify connection stability.' -f $startedProcess.Id)
    exit 0
} catch {
    Write-Host ('ERROR: ' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
