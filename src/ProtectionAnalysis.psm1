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
        $backupTasks = @($tasks | Where-Object {
                $taskJobType = Get-PropertyValue -InputObject $_ -Names @('jobType', 'type') -Default ''
                $taskJobName = Get-PropertyValue -InputObject $_ -Names @('jobName', 'name') -Default ''
                $taskCategory = Get-JobCategory -Type $taskJobType -Name $taskJobName
                $taskResult = ConvertTo-VeeamResultText -Value (Get-PropertyValue -InputObject $_ -Names @('result') -Default 'Unknown')
                $taskStatus = ConvertTo-FlatString -Value (Get-PropertyValue -InputObject $_ -Names @('state', 'status') -Default 'Unknown')

                ($taskCategory -eq 'Backup' -or $taskCategory -eq 'Backup Copy' -or $taskCategory -eq 'Agent' -or $taskCategory -eq 'NAS') -and
                $taskResult -notmatch 'Failed|Error' -and
                $taskStatus -notmatch 'Failed|Error'
            })
        $latestBackupTask = $backupTasks | ForEach-Object { Get-PropertyValue -InputObject $_ -Names @('endTime', 'stopTime', 'creationTime', 'time') } | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1
        $backupTaskAgeHours = if ($latestBackupTask) { [int]((Get-Date).ToUniversalTime() - ([datetime]$latestBackupTask).ToUniversalTime()).TotalHours } else { -1 }
        $effectiveAgeHours = if ($ageHours -ge 0 -and $backupTaskAgeHours -ge 0) {
            [Math]::Min($ageHours, $backupTaskAgeHours)
        }
        elseif ($ageHours -ge 0) {
            $ageHours
        }
        else {
            $backupTaskAgeHours
        }
        $hasBackup = $points.Count -gt 0 -or $backupTasks.Count -gt 0
        $hasBackupCopy = @($points | Where-Object { (Get-PropertyValue -InputObject $_ -Names @('backupCopyStatus', 'type', 'jobType') -Default '') -match 'copy' }).Count -gt 0
        $hasBackupCopy = $hasBackupCopy -or @($backupTasks | Where-Object { (Get-JobCategory -Type (Get-PropertyValue -InputObject $_ -Names @('jobType', 'type') -Default '') -Name (Get-PropertyValue -InputObject $_ -Names @('jobName', 'name') -Default '')) -eq 'Backup Copy' }).Count -gt 0
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
                backup_task_count = [int]$backupTasks.Count
                latest_restore_point_age_hours = [int]$ageHours
                latest_backup_evidence_age_hours = [int]$effectiveAgeHours
                stale_backup = [int]($effectiveAgeHours -lt 0 -or $effectiveAgeHours -gt $StaleBackupHours)
                stale_replication = [int]($hasReplication -and ($replicationAgeHours -lt 0 -or $replicationAgeHours -gt $StaleReplicationHours))
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function ConvertTo-ProtectionMetrics }
