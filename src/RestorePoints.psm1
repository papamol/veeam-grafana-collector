Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force

function Get-VeeamRestorePoints {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/restorePoints'
}

function ConvertTo-RestorePointMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object[]]$RestorePoints, [Parameter(Mandatory)][psobject]$Config)
    $RestorePoints | Group-Object { Get-PropertyValue -InputObject $_ -Names @('vmName', 'name') -Default 'unknown' } | ForEach-Object {
        $latest = $_.Group | ForEach-Object { Get-PropertyValue -InputObject $_ -Names @('creationTime', 'time') } | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1
        $ageHours = if ($latest) { [int]((Get-Date).ToUniversalTime() - ([datetime]$latest).ToUniversalTime()).TotalHours } else { -1 }
        [pscustomobject]@{
            Measurement = 'veeam_restore_points'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                vm = $_.Name
                repository = Get-PropertyValue -InputObject $_.Group[0] -Names @('repositoryName', 'repository') -Default ''
            }
            Fields = @{
                restore_point_count = [int]$_.Count
                latest_restore_point_age_hours = [int]$ageHours
                backup_copy_status = [string](Get-PropertyValue -InputObject $_.Group[0] -Names @('backupCopyStatus') -Default 'Unknown')
            }
        }
    }
}

Export-ModuleMember -Function Get-VeeamRestorePoints, ConvertTo-RestorePointMetrics
