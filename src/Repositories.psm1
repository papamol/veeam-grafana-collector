Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force

function Get-VeeamRepositories {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/backupInfrastructure/repositories'
}

function ConvertTo-RepositoryMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$Repositories, [Parameter(Mandatory)][psobject]$Config)
    foreach ($repo in $Repositories) {
        [pscustomobject]@{
            Measurement = 'veeam_repository'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                repository = Get-PropertyValue -InputObject $repo -Names @('name') -Default 'unknown'
                type = Get-PropertyValue -InputObject $repo -Names @('type') -Default 'unknown'
                immutable = [string](Get-PropertyValue -InputObject $repo -Names @('isImmutable', 'immutable') -Default $false)
            }
            Fields = @{
                capacity_bytes = [double](Get-PropertyValue -InputObject $repo -Names @('capacityBytes', 'capacity') -Default 0)
                free_bytes = [double](Get-PropertyValue -InputObject $repo -Names @('freeBytes', 'free') -Default 0)
                used_bytes = [double](Get-PropertyValue -InputObject $repo -Names @('usedBytes', 'used') -Default 0)
            }
        }
    }
}

Export-ModuleMember -Function Get-VeeamRepositories, ConvertTo-RepositoryMetrics
