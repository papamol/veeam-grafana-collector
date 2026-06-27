Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
& pwsh -NoProfile -File (Join-Path $root 'src\Collector.ps1') -ConfigPath (Join-Path $root 'config.json') -LogPath (Join-Path $root 'collector.log')
