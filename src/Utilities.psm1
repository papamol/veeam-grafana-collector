Set-StrictMode -Version Latest

function Read-CollectorConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "Configuration file not found: $Path"
    }

    $config = Get-Content -Path $Path -Raw | ConvertFrom-Json
    $null = Test-CollectorConfig -Config $config
    return $config
}

function Test-CollectorConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Config
    )

    $required = @(
        'Customer',
        'Site',
        'ServerName',
        'Veeam',
        'Influx'
    )

    foreach ($name in $required) {
        if (-not $Config.PSObject.Properties[$name]) {
            throw "Configuration is missing '$name'."
        }
    }

    foreach ($name in @('BaseUrl', 'Username', 'Password')) {
        if (-not $Config.Veeam.PSObject.Properties[$name] -or [string]::IsNullOrWhiteSpace($Config.Veeam.$name)) {
            throw "Configuration is missing 'Veeam.$name'."
        }
    }

    foreach ($name in @('Url', 'Org', 'Bucket', 'Token')) {
        if (-not $Config.Influx.PSObject.Properties[$name] -or [string]::IsNullOrWhiteSpace($Config.Influx.$name)) {
            throw "Configuration is missing 'Influx.$name'."
        }
    }

    return $true
}

function ConvertTo-SafeTagValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ''
    }

    return ([string]$Value).Replace('\', '\\').Replace(',', '\,').Replace(' ', '\ ').Replace('=', '\=')
}

function ConvertTo-InfluxFieldValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return '""'
    }

    if ($Value -is [bool]) {
        return $Value.ToString().ToLowerInvariant()
    }

    if ($Value -is [int] -or $Value -is [long]) {
        return ('{0}i' -f $Value)
    }

    if ($Value -is [decimal] -or $Value -is [double] -or $Value -is [float]) {
        return ([Convert]::ToString($Value, [Globalization.CultureInfo]::InvariantCulture))
    }

    return '"' + ([string]$Value).Replace('\', '\\').Replace('"', '\"') + '"'
}

function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$MaxAttempts = 3,

        [int]$InitialDelaySeconds = 2
    )

    $attempt = 0
    do {
        $attempt++
        try {
            return & $ScriptBlock
        }
        catch {
            if ($attempt -ge $MaxAttempts) {
                throw
            }

            $delay = [Math]::Min(60, $InitialDelaySeconds * [Math]::Pow(2, ($attempt - 1)))
            Start-Sleep -Seconds $delay
        }
    } while ($attempt -lt $MaxAttempts)
}

function Get-PropertyValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$InputObject,

        [Parameter(Mandatory)]
        [string[]]$Names,

        [AllowNull()]
        [object]$Default = $null
    )

    if ($null -eq $InputObject) {
        return $Default
    }

    foreach ($name in $Names) {
        if ($InputObject.PSObject.Properties[$name]) {
            return $InputObject.$name
        }
    }

    return $Default
}

function Get-JobCategory {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Type,

        [AllowNull()]
        [string]$Name
    )

    $combined = ('{0} {1}' -f $Type, $Name).ToLowerInvariant()

    switch -Regex ($combined) {
        'backup\s*copy|copy' { return 'Backup Copy' }
        'replica|replication' { return 'Replication' }
        'tape' { return 'Tape' }
        'surebackup|sure backup' { return 'SureBackup' }
        '\bnas\b|file share' { return 'NAS' }
        'agent|windows computer|linux computer' { return 'Agent' }
        'backup' { return 'Backup' }
        default { return 'Other' }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Read-CollectorConfig, Test-CollectorConfig, ConvertTo-SafeTagValue, ConvertTo-InfluxFieldValue, Invoke-WithRetry, Get-PropertyValue, Get-JobCategory }
