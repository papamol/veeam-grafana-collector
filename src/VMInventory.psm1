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

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamVMInventory, ConvertTo-VMInventoryMetrics }
