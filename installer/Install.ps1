param(
    [string]$InstallPath = 'C:\Program Files\VeeamGrafanaCollector',
    [string]$TaskName = 'Veeam Grafana Collector'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-PowerShell7 {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'PowerShell 7 or later is required. Install PowerShell 7 from https://github.com/PowerShell/PowerShell/releases and rerun the installer.'
    }
}

function Read-RequiredValue {
    param([Parameter(Mandatory)][string]$Prompt)
    do {
        $value = Read-Host $Prompt
    } while ([string]::IsNullOrWhiteSpace($value))
    return $value
}

Assert-PowerShell7

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
Copy-Item -Path (Join-Path $root '*') -Destination $InstallPath -Recurse -Force

$secureVeeamPassword = Read-Host 'Veeam Password' -AsSecureString
$plainVeeamPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureVeeamPassword))

$config = [ordered]@{
    Customer = Read-RequiredValue 'Customer'
    Site = Read-RequiredValue 'Site'
    ServerName = Read-RequiredValue 'Server Name'
    Veeam = [ordered]@{
        BaseUrl = Read-RequiredValue 'Veeam REST API Base URL (example https://localhost:9419/api)'
        Username = Read-RequiredValue 'Veeam Username'
        Password = $plainVeeamPassword
        IgnoreCertificateErrors = [bool]::Parse((Read-Host 'Ignore certificate errors? true/false'))
    }
    Influx = [ordered]@{
        Url = Read-RequiredValue 'InfluxDB URL'
        Org = Read-RequiredValue 'InfluxDB Org'
        Bucket = Read-RequiredValue 'InfluxDB Bucket'
        Token = Read-RequiredValue 'InfluxDB Token'
    }
}

$configPath = Join-Path $InstallPath 'config.json'
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
New-Item -ItemType File -Path (Join-Path $InstallPath 'collector.log') -Force | Out-Null

& pwsh -NoProfile -File (Join-Path $InstallPath 'src\Collector.ps1') -ConfigPath $configPath -LogPath (Join-Path $InstallPath 'collector.log')
if ($LASTEXITCODE -ne 0) {
    throw "Initial collector validation failed. Review $(Join-Path $InstallPath 'collector.log') before creating the scheduled task."
}

$action = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$InstallPath\src\Collector.ps1`" -ConfigPath `"$configPath`" -LogPath `"$InstallPath\collector.log`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Minutes 15)
$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -RunLevel Highest
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null

Write-Host "Installed Veeam Grafana Collector to $InstallPath"
