Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamVMInventory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)

    Get-VeeamCollectionFromFirstAvailablePath -Session $Session -Paths @(
        '/v1/inventory/vms',
        '/v1/inventory/virtualMachines',
        '/v1/inventory/vSphere/virtualMachines',
        '/v1/inventory/hyperV/virtualMachines'
    )
}

function ConvertTo-VMInventoryMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$VMs, [Parameter(Mandatory)][psobject]$Config)
    foreach ($vm in $VMs) {
        [pscustomobject]@{
            Measurement = 'veeam_vm_inventory'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                vm = Get-PropertyValue -InputObject $vm -Names @('name', 'vmName') -Default 'unknown'
                platform = Get-PropertyValue -InputObject $vm -Names @('platform', 'type') -Default 'unknown'
                cluster = Get-PropertyValue -InputObject $vm -Names @('clusterName', 'cluster') -Default ''
                host = Get-PropertyValue -InputObject $vm -Names @('hostName', 'host') -Default ''
                folder = Get-PropertyValue -InputObject $vm -Names @('folder') -Default ''
                datastore = Get-PropertyValue -InputObject $vm -Names @('datastore') -Default ''
                power_state = Get-PropertyValue -InputObject $vm -Names @('powerState') -Default 'unknown'
            }
            Fields = @{
                present = 1
            }
        }
    }
}

function New-VeeamVMInventoryFromCollectedData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$RestorePoints,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TaskSessions,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$ReplicationJobs
    )

    $vmNames = [System.Collections.Generic.SortedSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($point in $RestorePoints) {
        $vmName = Get-PropertyValue -InputObject $point -Names @('vmName', 'name')
        if (-not [string]::IsNullOrWhiteSpace($vmName)) {
            $null = $vmNames.Add($vmName)
        }
    }

    foreach ($task in $TaskSessions) {
        $vmName = Get-PropertyValue -InputObject $task -Names @('vmName', 'name')
        if (-not [string]::IsNullOrWhiteSpace($vmName)) {
            $null = $vmNames.Add($vmName)
        }
    }

    foreach ($replica in $ReplicationJobs) {
        $vmName = Get-PropertyValue -InputObject $replica -Names @('vmName', 'name')
        if (-not [string]::IsNullOrWhiteSpace($vmName)) {
            $null = $vmNames.Add($vmName)
        }
    }

    foreach ($vmName in $vmNames) {
        [pscustomobject]@{
            name = $vmName
            platform = 'unknown'
            clusterName = ''
            hostName = ''
            folder = ''
            datastore = ''
            powerState = 'unknown'
            inventorySource = 'collector-derived'
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamVMInventory, New-VeeamVMInventoryFromCollectedData, ConvertTo-VMInventoryMetrics }
