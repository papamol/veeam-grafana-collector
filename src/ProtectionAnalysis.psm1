Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function ConvertTo-ProtectionMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$VMs,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$RestorePoints,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TaskSessions,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ReplicationJobs,
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

    $taskByVm = @{}
    foreach ($task in $TaskSessions) {
        $vmName = Get-PropertyValue -InputObject $task -Names @('vmName', 'name')
        if ([string]::IsNullOrWhiteSpace($vmName)) { continue }
        if (-not $taskByVm.ContainsKey($vmName)) { $taskByVm[$vmName] = @() }
        $taskByVm[$vmName] += $task
    }

    $replicationVmNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($replica in $ReplicationJobs) {
        $replicaName = Get-PropertyValue -InputObject $replica -Names @('vmName', 'name')
        if (-not [string]::IsNullOrWhiteSpace($replicaName)) {
            $null = $replicationVmNames.Add($replicaName)
        }
    }

    $vmNames = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($vm in $VMs) {
        $vmName = Get-PropertyValue -InputObject $vm -Names @('name', 'vmName')
        if (-not [string]::IsNullOrWhiteSpace($vmName)) { $null = $vmNames.Add($vmName) }
    }
    foreach ($vmName in $restoreByVm.Keys) { $null = $vmNames.Add($vmName) }
    foreach ($vmName in $taskByVm.Keys) { $null = $vmNames.Add($vmName) }
    foreach ($vmName in $replicationVmNames) { $null = $vmNames.Add($vmName) }

    foreach ($vmName in $vmNames) {
        $points = @(if ($restoreByVm.ContainsKey($vmName)) { $restoreByVm[$vmName] })
        $tasks = @(if ($taskByVm.ContainsKey($vmName)) { $taskByVm[$vmName] })
        $latest = $points | ForEach-Object { Get-PropertyValue -InputObject $_ -Names @('creationTime', 'time') } | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1
        $latestTask = $tasks | ForEach-Object { Get-PropertyValue -InputObject $_ -Names @('endTime', 'stopTime', 'creationTime', 'time') } | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1
        $ageHours = if ($latest) { [int]((Get-Date).ToUniversalTime() - ([datetime]$latest).ToUniversalTime()).TotalHours } else { -1 }
        $replicationAgeHours = if ($latestTask) { [int]((Get-Date).ToUniversalTime() - ([datetime]$latestTask).ToUniversalTime()).TotalHours } else { -1 }
        $hasBackup = $points.Count -gt 0
        $hasBackupCopy = @($points | Where-Object { (Get-PropertyValue -InputObject $_ -Names @('backupCopyStatus', 'type', 'jobType') -Default '') -match 'copy' }).Count -gt 0
        $hasReplication = $replicationVmNames.Contains($vmName) -or @($tasks | Where-Object { (Get-PropertyValue -InputObject $_ -Names @('jobType', 'type', 'jobName') -Default '') -match 'Replica|Replication' }).Count -gt 0
        $protectionType = if ($hasBackup -and $hasReplication) {
            'Both Backup and Replication'
        }
        elseif ($hasBackupCopy) {
            'Backup Copy'
        }
        elseif ($hasBackup) {
            'Backup'
        }
        elseif ($hasReplication) {
            'Replication'
        }
        else {
            'Unprotected'
        }

        [pscustomobject]@{
            Measurement = 'veeam_vm_protection'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                vm = $vmName
                protection_status = if ($hasBackup) { 'Protected' } else { 'Unprotected' }
                protection_type = $protectionType
            }
            Fields = @{
                protected = [int]$hasBackup
                backup = [int]$hasBackup
                backup_copy = [int]$hasBackupCopy
                replication = [int]$hasReplication
                no_backup = [int](-not $hasBackup)
                restore_point_count = [int]$points.Count
                latest_restore_point_age_hours = [int]$ageHours
                stale_backup = [int]($ageHours -lt 0 -or $ageHours -gt $StaleBackupHours)
                stale_replication = [int]($hasReplication -and ($replicationAgeHours -lt 0 -or $replicationAgeHours -gt $StaleReplicationHours))
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function ConvertTo-ProtectionMetrics }
