Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamSOBR {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/backupInfrastructure/scaleOutRepositories'
}

function ConvertTo-SOBRMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Repositories, [Parameter(Mandatory)][psobject]$Config)
    foreach ($repo in $Repositories) {
        [pscustomobject]@{
            Measurement = 'veeam_sobr'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                repository = Get-PropertyValue -InputObject $repo -Names @('name') -Default 'unknown'
                policy = Get-PropertyValue -InputObject $repo -Names @('policyType', 'policy') -Default 'unknown'
            }
            Fields = @{
                extent_count = [int](Get-PropertyValue -InputObject $repo -Names @('extentCount') -Default 0)
                capacity_bytes = [double](Get-PropertyValue -InputObject $repo -Names @('capacityBytes') -Default 0)
                free_bytes = [double](Get-PropertyValue -InputObject $repo -Names @('freeBytes') -Default 0)
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamSOBR, ConvertTo-SOBRMetrics }
