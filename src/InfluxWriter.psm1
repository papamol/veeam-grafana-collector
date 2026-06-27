Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function ConvertTo-InfluxLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Measurement,

        [Parameter(Mandatory)]
        [hashtable]$Tags,

        [Parameter(Mandatory)]
        [hashtable]$Fields,

        [datetime]$Timestamp = (Get-Date).ToUniversalTime()
    )

    $tagText = ($Tags.GetEnumerator() | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Value) } | Sort-Object Name | ForEach-Object {
        '{0}={1}' -f (ConvertTo-SafeTagValue $_.Name), (ConvertTo-SafeTagValue $_.Value)
    }) -join ','

    $fieldText = ($Fields.GetEnumerator() | Sort-Object Name | ForEach-Object {
        '{0}={1}' -f (ConvertTo-SafeTagValue $_.Name), (ConvertTo-InfluxFieldValue $_.Value)
    }) -join ','

    if ([string]::IsNullOrWhiteSpace($fieldText)) {
        throw "Measurement '$Measurement' has no fields."
    }

    $ns = [int64](($Timestamp.ToUniversalTime() - [datetime]'1970-01-01T00:00:00Z').TotalMilliseconds * 1000000)
    if ([string]::IsNullOrWhiteSpace($tagText)) {
        return '{0} {1} {2}' -f (ConvertTo-SafeTagValue $Measurement), $fieldText, $ns
    }

    return '{0},{1} {2} {3}' -f (ConvertTo-SafeTagValue $Measurement), $tagText, $fieldText, $ns
}

function Write-InfluxMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Config,

        [Parameter(Mandatory)]
        [string[]]$Lines
    )

    if ($Lines.Count -eq 0) {
        return
    }

    $uri = '{0}/api/v2/write?org={1}&bucket={2}&precision=ns' -f $Config.Influx.Url.TrimEnd('/'), [uri]::EscapeDataString($Config.Influx.Org), [uri]::EscapeDataString($Config.Influx.Bucket)
    $headers = @{
        Authorization = "Token $($Config.Influx.Token)"
    }

    Invoke-WithRetry -ScriptBlock {
        Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body ($Lines -join "`n") -ContentType 'text/plain; charset=utf-8'
    } | Out-Null
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function ConvertTo-InfluxLine, Write-InfluxMetrics }
