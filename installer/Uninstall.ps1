param(
    [string]$InstallPath = 'C:\Program Files\VeeamGrafanaCollector',
    [string]$TaskName = 'Veeam Grafana Collector',
    [switch]$KeepConfig
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

if (Test-Path $InstallPath) {
    if ($KeepConfig) {
        $preservePath = Join-Path $env:ProgramData 'VeeamGrafanaCollector'
        New-Item -ItemType Directory -Path $preservePath -Force | Out-Null
        Copy-Item -Path (Join-Path $InstallPath 'config.json') -Destination $preservePath -Force -ErrorAction SilentlyContinue
        Copy-Item -Path (Join-Path $InstallPath 'collector.log') -Destination $preservePath -Force -ErrorAction SilentlyContinue
    }

    Remove-Item -Path $InstallPath -Recurse -Force
}

Write-Host 'Veeam Grafana Collector uninstalled.'
