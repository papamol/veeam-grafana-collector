Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function ConvertTo-ProtectionMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$VMs,
        [Parameter(Mandatory)][object[]]$RestorePoints,
        [Parameter(Mandatory)][psobject]$Config,
        [int]$StaleBackupHours = 48,
        [int]$StaleReplicationHours = 24
    )

    $restoreByVm = @{}
    foreach ($point in $RestorePoints) {
        $vmName = Get-PropertyValue -InputObject $point -Names @('vmName', 'name')
        if ([string]::IsNullOrWhiteSpace($vmName)) { continue }
        if (-not $restoreByVm.ContainsKey($vmName)) { $restoreByVm[$vmName] = @() }
        $restoreByVm[$vmName] += $point
    }

    foreach ($vm in $VMs) {
        $vmName = Get-PropertyValue -InputObject $vm -Names @('name', 'vmName') -Default 'unknown'
        $points = if ($restoreByVm.ContainsKey($vmName)) { @($restoreByVm[$vmName]) } else { @() }
        $latest = $points | ForEach-Object { Get-PropertyValue -InputObject $_ -Names @('creationTime', 'time') } | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1
        $ageHours = if ($latest) { [int]((Get-Date).ToUniversalTime() - ([datetime]$latest).ToUniversalTime()).TotalHours } else { -1 }
        $hasBackup = $points.Count -gt 0
        [pscustomobject]@{
            Measurement = 'veeam_vm_protection'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                vm = $vmName
                protection_status = if ($hasBackup) { 'Protected' } else { 'Unprotected' }
            }
            Fields = @{
                protected = [int]$hasBackup
                restore_point_count = [int]$points.Count
                latest_restore_point_age_hours = [int]$ageHours
                stale_backup = [int]($ageHours -lt 0 -or $ageHours -gt $StaleBackupHours)
                stale_replication = [int]($ageHours -lt 0 -or $ageHours -gt $StaleReplicationHours)
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function ConvertTo-ProtectionMetrics }
