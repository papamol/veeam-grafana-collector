BeforeAll {
    Import-Module "$PSScriptRoot/../src/VMInventory.psm1" -Force
}

Describe 'New-VeeamVMInventoryFromCollectedData' {
    It 'derives unique VM inventory records from restore points, task sessions, and replication jobs' {
        $restorePoints = @(
            [pscustomobject]@{ vmName = 'vm-a' },
            [pscustomobject]@{ name = 'vm-b' }
        )
        $taskSessions = @(
            [pscustomobject]@{ vmName = 'vm-a' },
            [pscustomobject]@{ name = 'vm-c' }
        )
        $replicationJobs = @(
            [pscustomobject]@{ name = 'vm-d' }
        )

        $vms = @(New-VeeamVMInventoryFromCollectedData -RestorePoints $restorePoints -TaskSessions $taskSessions -ReplicationJobs $replicationJobs)

        $vms.Count | Should -Be 4
        @($vms.name) | Should -Contain 'vm-a'
        @($vms.name) | Should -Contain 'vm-b'
        @($vms.name) | Should -Contain 'vm-c'
        @($vms.name) | Should -Contain 'vm-d'
        $vms[0].inventorySource | Should -Be 'collector-derived'
    }
}
