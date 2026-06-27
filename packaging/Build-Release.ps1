param(
    [Parameter(Mandatory)]
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$artifacts = Join-Path $root 'artifacts'
$stage = Join-Path $artifacts "veeam-grafana-collector-$Version"

Remove-Item -Path $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $stage -Force | Out-Null

$items = @('src', 'installer', 'dashboards', 'docs', 'examples', 'LICENSE', 'README.md', 'CHANGELOG.md', 'SECURITY.md', 'CONTRIBUTING.md', 'CODE_OF_CONDUCT.md')
foreach ($item in $items) {
    Copy-Item -Path (Join-Path $root $item) -Destination $stage -Recurse -Force
}

$zipPath = Join-Path $artifacts "veeam-grafana-collector-$Version.zip"
Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $zipPath -Force
Write-Host "Created $zipPath"
