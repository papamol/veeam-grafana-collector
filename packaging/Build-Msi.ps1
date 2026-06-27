param(
    [Parameter(Mandatory)]
    [string]$Version
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$artifacts = Join-Path $root 'artifacts'
New-Item -ItemType Directory -Path $artifacts -Force | Out-Null

$wix = Get-Command wix -ErrorAction SilentlyContinue
if (-not $wix) {
    Write-Warning 'WiX Toolset CLI was not found. Creating MSI placeholder manifest instead of compiling MSI.'
    Set-Content -Path (Join-Path $artifacts "veeam-grafana-collector-$Version.msi.txt") -Value 'Install WiX Toolset CLI and rerun packaging/Build-Msi.ps1 to create the MSI.'
    return
}

& wix build (Join-Path $root 'installer\Product.wxs') -d Version=$Version -out (Join-Path $artifacts "veeam-grafana-collector-$Version.msi")
