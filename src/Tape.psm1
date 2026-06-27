Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamTapeResources {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/tape'
}

function ConvertTo-TapeMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$TapeResources, [Parameter(Mandatory)][psobject]$Config)
    foreach ($tape in $TapeResources) {
        [pscustomobject]@{
            Measurement = 'veeam_tape'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                name = Get-PropertyValue -InputObject $tape -Names @('name') -Default 'unknown'
                type = Get-PropertyValue -InputObject $tape -Names @('type') -Default 'unknown'
                pool = Get-PropertyValue -InputObject $tape -Names @('poolName', 'pool') -Default ''
            }
            Fields = @{
                capacity_bytes = [double](Get-PropertyValue -InputObject $tape -Names @('capacityBytes') -Default 0)
                free_bytes = [double](Get-PropertyValue -InputObject $tape -Names @('freeBytes') -Default 0)
                error_count = [int](Get-PropertyValue -InputObject $tape -Names @('errorCount') -Default 0)
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamTapeResources, ConvertTo-TapeMetrics }
