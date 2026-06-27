Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamTapeResources {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)

    $resources = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in @(
        @{ Kind = 'job'; Path = '/v1/jobs?type=Tape' },
        @{ Kind = 'library'; Path = '/v1/tape/libraries' },
        @{ Kind = 'pool'; Path = '/v1/tape/mediaPools' },
        @{ Kind = 'media'; Path = '/v1/tape/media' },
        @{ Kind = 'resource'; Path = '/v1/tape' }
    )) {
        try {
            foreach ($item in @(Get-VeeamCollection -Session $Session -Path $definition.Path)) {
                $item | Add-Member -NotePropertyName collectorResourceKind -NotePropertyValue $definition.Kind -Force
                $resources.Add($item)
            }
        }
        catch {
            if (Get-Command -Name Write-CollectorLog -ErrorAction SilentlyContinue) {
                Write-CollectorLog -Message ("Skipping tape {0} endpoint {1}: {2}" -f $definition.Kind, $definition.Path, $_.Exception.Message) -Level WARN
            }
        }
    }

    return $resources.ToArray()
}

function ConvertTo-TapeMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TapeResources, [Parameter(Mandatory)][psobject]$Config)
    foreach ($tape in $TapeResources) {
        [pscustomobject]@{
            Measurement = 'veeam_tape'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                name = Get-PropertyValue -InputObject $tape -Names @('name') -Default 'unknown'
                type = Get-PropertyValue -InputObject $tape -Names @('type') -Default (Get-PropertyValue -InputObject $tape -Names @('collectorResourceKind') -Default 'unknown')
                resource_kind = Get-PropertyValue -InputObject $tape -Names @('collectorResourceKind') -Default 'unknown'
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
