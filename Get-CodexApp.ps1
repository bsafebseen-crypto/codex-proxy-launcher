function Get-CodexApp {
    $package = Get-AppxPackage -Name OpenAI.Codex | Select-Object -First 1
    if (-not $package) {
        throw 'The OpenAI.Codex MSIX app is not installed for this Windows user. See README.md.'
    }
    $manifest = $package | Get-AppxPackageManifest
    $application = $manifest.Package.Applications.Application |
        Where-Object { $_.Id -eq 'App' } | Select-Object -First 1
    if (-not $application.Executable) {
        throw 'Main app entry not found in the package manifest. See docs/AGENT-HANDOFF.md.'
    }
    $relativePath = ([string]$application.Executable).Replace('/', '\')
    $executablePath = Join-Path $package.InstallLocation $relativePath
    if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
        throw "Codex executable not found: $executablePath"
    }
    [pscustomobject]@{
        Path = $executablePath
        RelativePath = $relativePath
        PackageName = $package.Name
        PackageVersion = [string]$package.Version
    }
}
