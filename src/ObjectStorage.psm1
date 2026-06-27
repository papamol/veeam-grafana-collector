Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamObjectStorageRepositories {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)

    Get-VeeamCollectionFromFirstAvailablePath -Session $Session -Paths @(
        '/v1/backupInfrastructure/objectStorageRepositories',
        '/v1/objectStorage/repositories',
        '/v1/backupInfrastructure/repositories?type=ObjectStorage'
    )
}

function ConvertTo-ObjectStorageMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Repositories,
        [Parameter(Mandatory)][psobject]$Config
    )

    foreach ($repo in $Repositories) {
        [pscustomobject]@{
            Measurement = 'veeam_object_storage'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                repository = Get-PropertyValue -InputObject $repo -Names @('name') -Default 'unknown'
                type = Get-PropertyValue -InputObject $repo -Names @('type', 'repositoryType') -Default 'unknown'
                immutable = [string](Get-PropertyValue -InputObject $repo -Names @('isImmutable', 'immutable') -Default $false)
            }
            Fields = @{
                capacity_bytes = [double](Get-PropertyValue -InputObject $repo -Names @('capacityBytes', 'capacity') -Default 0)
                used_bytes = [double](Get-PropertyValue -InputObject $repo -Names @('usedBytes', 'used') -Default 0)
                free_bytes = [double](Get-PropertyValue -InputObject $repo -Names @('freeBytes', 'free') -Default 0)
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamObjectStorageRepositories, ConvertTo-ObjectStorageMetrics }
