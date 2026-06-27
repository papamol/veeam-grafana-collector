Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamReplicationJobs {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/jobs?type=Replication'
}

function ConvertTo-ReplicationMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Replicas, [Parameter(Mandatory)][psobject]$Config)
    foreach ($replica in $Replicas) {
        [pscustomobject]@{
            Measurement = 'veeam_replication'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                replica_vm = Get-PropertyValue -InputObject $replica -Names @('vmName', 'name') -Default 'unknown'
                target_host = Get-PropertyValue -InputObject $replica -Names @('targetHost') -Default ''
                source_host = Get-PropertyValue -InputObject $replica -Names @('sourceHost') -Default ''
            }
            Fields = @{
                rpo_minutes = [int](Get-PropertyValue -InputObject $replica -Names @('rpoMinutes') -Default 0)
                duration_seconds = [int](Get-PropertyValue -InputObject $replica -Names @('durationSeconds') -Default 0)
                failure_reason = [string](Get-PropertyValue -InputObject $replica -Names @('failureReason') -Default '')
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamReplicationJobs, ConvertTo-ReplicationMetrics }
