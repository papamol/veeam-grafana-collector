Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamInfrastructure {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)

    [pscustomobject]@{
        Proxies = Get-VeeamCollection -Session $Session -Path '/v1/backupInfrastructure/proxies'
        Gateways = Get-VeeamCollection -Session $Session -Path '/v1/backupInfrastructure/gatewayServers'
        MountServers = Get-VeeamCollection -Session $Session -Path '/v1/backupInfrastructure/mountServers'
        WanAccelerators = Get-VeeamCollection -Session $Session -Path '/v1/backupInfrastructure/wanAccelerators'
    }
}

function ConvertTo-InfrastructureMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Infrastructure, [Parameter(Mandatory)][psobject]$Config)

    foreach ($proxy in @($Infrastructure.Proxies)) {
        [pscustomobject]@{
            Measurement = 'veeam_proxy'
            Tags = @{ customer = $Config.Customer; site = $Config.Site; server = $Config.ServerName; proxy = (Get-PropertyValue -InputObject $proxy -Names @('name') -Default 'unknown') }
            Fields = @{ enabled = [bool](Get-PropertyValue -InputObject $proxy -Names @('enabled', 'isEnabled') -Default $true); max_tasks = [int](Get-PropertyValue -InputObject $proxy -Names @('maxTasks') -Default 0) }
        }
    }

    foreach ($gateway in @($Infrastructure.Gateways)) {
        [pscustomobject]@{
            Measurement = 'veeam_gateway'
            Tags = @{ customer = $Config.Customer; site = $Config.Site; server = $Config.ServerName; gateway = (Get-PropertyValue -InputObject $gateway -Names @('name') -Default 'unknown') }
            Fields = @{ enabled = [bool](Get-PropertyValue -InputObject $gateway -Names @('enabled', 'isEnabled') -Default $true) }
        }
    }

    foreach ($mount in @($Infrastructure.MountServers)) {
        [pscustomobject]@{
            Measurement = 'veeam_mount_server'
            Tags = @{ customer = $Config.Customer; site = $Config.Site; server = $Config.ServerName; mount_server = (Get-PropertyValue -InputObject $mount -Names @('name') -Default 'unknown') }
            Fields = @{ enabled = [bool](Get-PropertyValue -InputObject $mount -Names @('enabled', 'isEnabled') -Default $true) }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamInfrastructure, ConvertTo-InfrastructureMetrics }
