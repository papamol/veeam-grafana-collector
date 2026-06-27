Set-StrictMode -Version Latest

function Initialize-Logger {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LogPath
    )

    $directory = Split-Path -Parent $LogPath
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    if (-not (Test-Path $LogPath)) {
        New-Item -ItemType File -Path $LogPath -Force | Out-Null
    }

    $script:CollectorLogPath = $LogPath
}

function Write-CollectorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = (Get-Date).ToUniversalTime().ToString('o')
    $line = '{0} [{1}] {2}' -f $timestamp, $Level, $Message

    if ($script:CollectorLogPath) {
        Add-Content -Path $script:CollectorLogPath -Value $line
    }

    Write-Information $line -InformationAction Continue
}

Export-ModuleMember -Function Initialize-Logger, Write-CollectorLog
