Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force

function Get-VeeamVMInventory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/inventory/vms'
}

function ConvertTo-VMInventoryMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$VMs, [Parameter(Mandatory)][psobject]$Config)
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

Export-ModuleMember -Function Get-VeeamVMInventory, ConvertTo-VMInventoryMetrics
