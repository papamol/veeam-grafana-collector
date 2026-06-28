BeforeAll {
    Import-Module "$PSScriptRoot/../src/ProtectionAnalysis.psm1" -Force
}

Describe 'ConvertTo-ProtectionMetrics' {
    It 'classifies backup, backup copy, replication, and unprotected VMs' {
        $config = [pscustomobject]@{
            Customer = 'CustomerA'
            Site = 'SiteA'
            ServerName = 'VBR01'
        }
        $vms = @(
            [pscustomobject]@{ name = 'vm-backup' },
            [pscustomobject]@{ name = 'vm-copy' },
            [pscustomobject]@{ name = 'vm-replica' },
            [pscustomobject]@{ name = 'vm-both' },
            [pscustomobject]@{ name = 'vm-none' }
        )
        $restorePoints = @(
            [pscustomobject]@{ vmName = 'vm-backup'; creationTime = (Get-Date).ToUniversalTime().AddHours(-1).ToString('o') },
            [pscustomobject]@{ vmName = 'vm-copy'; creationTime = (Get-Date).ToUniversalTime().AddHours(-1).ToString('o'); backupCopyStatus = 'Copy' },
            [pscustomobject]@{ vmName = 'vm-both'; creationTime = (Get-Date).ToUniversalTime().AddHours(-1).ToString('o') }
        )
        $tasks = @(
            [pscustomobject]@{ vmName = 'vm-replica'; jobType = 'Replication'; endTime = (Get-Date).ToUniversalTime().AddHours(-1).ToString('o') },
            [pscustomobject]@{ vmName = 'vm-both'; jobType = 'Replication'; endTime = (Get-Date).ToUniversalTime().AddHours(-1).ToString('o') }
        )

        $metrics = @(ConvertTo-ProtectionMetrics -VMs $vms -RestorePoints $restorePoints -TaskSessions $tasks -ReplicationJobs @() -Config $config)
        $byVm = @{}
        foreach ($metric in $metrics) { $byVm[$metric.Tags.vm] = $metric }

        $byVm['vm-backup'].Tags.protection_type | Should -Be 'Backup'
        $byVm['vm-copy'].Tags.protection_type | Should -Be 'Backup Copy'
        $byVm['vm-replica'].Tags.protection_type | Should -Be 'Replication'
        $byVm['vm-both'].Tags.protection_type | Should -Be 'Both Backup and Replication'
        $byVm['vm-none'].Tags.protection_type | Should -Be 'Unprotected'
        $byVm['vm-none'].Fields.no_backup | Should -Be 1
    }

    It 'uses successful backup task sessions as backup evidence when restore points are incomplete' {
        $config = [pscustomobject]@{
            Customer = 'CustomerA'
            Site = 'SiteA'
            ServerName = 'VBR01'
        }
        $vms = @(
            [pscustomobject]@{ name = 'vm-task-protected' }
        )
        $tasks = @(
            [pscustomobject]@{
                vmName = 'vm-task-protected'
                jobType = 'Backup'
                jobName = 'Daily Backup'
                result = 'Success'
                status = 'Stopped'
                endTime = (Get-Date).ToUniversalTime().AddHours(-2).ToString('o')
            }
        )

        $metrics = @(ConvertTo-ProtectionMetrics -VMs $vms -RestorePoints @() -TaskSessions $tasks -ReplicationJobs @() -Config $config)

        $metrics[0].Tags.protection_status | Should -Be 'Protected'
        $metrics[0].Tags.protection_type | Should -Be 'Backup'
        $metrics[0].Fields.protected | Should -Be 1
        $metrics[0].Fields.no_backup | Should -Be 0
        $metrics[0].Fields.backup_task_count | Should -Be 1
    }
}
