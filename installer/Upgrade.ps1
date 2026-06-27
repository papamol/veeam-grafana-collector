param(
    [string]$InstallPath = 'C:\Program Files\VeeamGrafanaCollector',
    [switch]$SkipValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$backupPath = Join-Path $InstallPath ("backup-{0:yyyyMMddHHmmss}" -f (Get-Date))

if (-not (Test-Path $InstallPath)) {
    throw "Install path does not exist: $InstallPath"
}

New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
Copy-Item -Path (Join-Path $InstallPath 'config.json') -Destination $backupPath -Force
Copy-Item -Path (Join-Path $InstallPath 'collector.log') -Destination $backupPath -Force -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $root '*') -Destination $InstallPath -Recurse -Force
Copy-Item -Path (Join-Path $backupPath 'config.json') -Destination (Join-Path $InstallPath 'config.json') -Force

if (-not $SkipValidation) {
    & pwsh -NoProfile -File (Join-Path $InstallPath 'src\Collector.ps1') -ConfigPath (Join-Path $InstallPath 'config.json') -LogPath (Join-Path $InstallPath 'collector.log')
    if ($LASTEXITCODE -ne 0) {
        throw "Post-upgrade collector validation failed. Review $(Join-Path $InstallPath 'collector.log'). Rerun with -SkipValidation only if you need to stage files before fixing connectivity."
    }
}

Write-Host "Upgrade complete. Backup created at $backupPath"
