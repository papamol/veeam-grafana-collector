param(
    [string]$InstallPath = 'C:\Program Files\VeeamGrafanaCollector',
    [switch]$SkipValidation
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Set-OrAddProperty {
    param(
        [Parameter(Mandatory)][psobject]$InputObject,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value
    )

    if ($InputObject.PSObject.Properties[$Name]) {
        $InputObject.$Name = $Value
    }
    else {
        $InputObject | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    }
}

function Set-HashtableValue {
    param(
        [Parameter(Mandatory)][psobject]$InputObject,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value
    )

    Set-OrAddProperty -InputObject $InputObject -Name $Name -Value $Value
}

function Update-CollectionConfig {
    param([Parameter(Mandatory)][string]$ConfigPath)

    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    if (-not $config.PSObject.Properties['Collection'] -or $null -eq $config.Collection) {
        Set-OrAddProperty -InputObject $config -Name 'Collection' -Value ([pscustomobject]@{})
    }

    Set-OrAddProperty -InputObject $config.Collection -Name 'PageSize' -Value 1
    Set-OrAddProperty -InputObject $config.Collection -Name 'MaxPages' -Value 1
    if (-not $config.Collection.PSObject.Properties['RequestTimeoutSeconds']) {
        Set-OrAddProperty -InputObject $config.Collection -Name 'RequestTimeoutSeconds' -Value 30
    }

    if (-not $config.Collection.PSObject.Properties['EndpointPageSize'] -or $null -eq $config.Collection.EndpointPageSize) {
        Set-OrAddProperty -InputObject $config.Collection -Name 'EndpointPageSize' -Value ([pscustomobject]@{})
    }
    if (-not $config.Collection.PSObject.Properties['EndpointMaxPages'] -or $null -eq $config.Collection.EndpointMaxPages) {
        Set-OrAddProperty -InputObject $config.Collection -Name 'EndpointMaxPages' -Value ([pscustomobject]@{})
    }

    $protectionEndpoints = @(
        '/v1/inventory/vms',
        '/v1/inventory/virtualMachines',
        '/v1/inventory/vSphere/virtualMachines',
        '/v1/inventory/hyperV/virtualMachines',
        '/v1/restorePoints',
        '/v1/sessions',
        '/v1/taskSessions'
    )
    foreach ($endpoint in $protectionEndpoints) {
        Set-HashtableValue -InputObject $config.Collection.EndpointPageSize -Name $endpoint -Value 100
        Set-HashtableValue -InputObject $config.Collection.EndpointMaxPages -Name $endpoint -Value 50
    }

    $config | ConvertTo-Json -Depth 20 | Set-Content -Path $ConfigPath -Encoding UTF8
}

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$backupPath = Join-Path $InstallPath ("backup-{0:yyyyMMddHHmmss}" -f (Get-Date))

if (-not (Test-Path $InstallPath)) {
    throw "Install path does not exist: $InstallPath"
}

New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
Copy-Item -Path (Join-Path $InstallPath 'config.json') -Destination $backupPath -Force
Copy-Item -Path (Join-Path $InstallPath 'collector.log') -Destination $backupPath -Force -ErrorAction SilentlyContinue
Copy-Item -Path (Join-Path $root '*') -Destination $InstallPath -Recurse -Force
$configPath = Join-Path $InstallPath 'config.json'
Copy-Item -Path (Join-Path $backupPath 'config.json') -Destination $configPath -Force
Update-CollectionConfig -ConfigPath $configPath

if (-not $SkipValidation) {
    & pwsh -NoProfile -File (Join-Path $InstallPath 'src\Collector.ps1') -ConfigPath $configPath -LogPath (Join-Path $InstallPath 'collector.log')
    if ($LASTEXITCODE -ne 0) {
        throw "Post-upgrade collector validation failed. Review $(Join-Path $InstallPath 'collector.log'). Rerun with -SkipValidation only if you need to stage files before fixing connectivity."
    }
}

Write-Host "Upgrade complete. Backup created at $backupPath"
