Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamServerInfo {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)

    Invoke-VeeamFirstAvailablePath -Session $Session -Paths @(
        '/v1/serverInfo',
        '/v1/server',
        '/v1/about'
    )
}

function Get-VeeamLicenseInfo {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)

    Invoke-VeeamFirstAvailablePath -Session $Session -Paths @(
        '/v1/license',
        '/v1/licenses'
    )
}

function ConvertTo-SystemInfoMetrics {
    [CmdletBinding()]
    param(
        [AllowNull()][object]$ServerInfo,
        [AllowNull()][object]$LicenseInfo,
        [Parameter(Mandatory)][psobject]$Config
    )

    $hasServerInfo = $null -ne $ServerInfo -and -not ($ServerInfo -is [System.Collections.ICollection] -and $ServerInfo.Count -eq 0)
    $hasLicenseInfo = $null -ne $LicenseInfo -and -not ($LicenseInfo -is [System.Collections.ICollection] -and $LicenseInfo.Count -eq 0)

    if ($hasServerInfo) {
        [pscustomobject]@{
            Measurement = 'veeam_version_info'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                version = Get-PropertyValue -InputObject $ServerInfo -Names @('version', 'productVersion', 'buildVersion') -Default 'unknown'
                edition = Get-PropertyValue -InputObject $ServerInfo -Names @('edition', 'productEdition') -Default 'unknown'
                build = Get-PropertyValue -InputObject $ServerInfo -Names @('build', 'buildNumber') -Default 'unknown'
            }
            Fields = @{
                present = 1
            }
        }
    }

    if ($hasLicenseInfo) {
        $expiration = Get-PropertyValue -InputObject $LicenseInfo -Names @('expirationDate', 'expiresAt', 'expiration') -Default $null
        $daysRemaining = if ($expiration) {
            [int](([datetime]$expiration).ToUniversalTime() - (Get-Date).ToUniversalTime()).TotalDays
        }
        else {
            -1
        }

        [pscustomobject]@{
            Measurement = 'veeam_license_info'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                edition = Get-PropertyValue -InputObject $LicenseInfo -Names @('edition', 'licenseEdition') -Default 'unknown'
                status = Get-PropertyValue -InputObject $LicenseInfo -Names @('status', 'licenseStatus') -Default 'unknown'
                type = Get-PropertyValue -InputObject $LicenseInfo -Names @('type', 'licenseType') -Default 'unknown'
            }
            Fields = @{
                instances_used = [int](Get-PropertyValue -InputObject $LicenseInfo -Names @('instancesUsed', 'usedInstances') -Default 0)
                instances_total = [int](Get-PropertyValue -InputObject $LicenseInfo -Names @('instancesTotal', 'totalInstances') -Default 0)
                days_remaining = [int]$daysRemaining
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamServerInfo, Get-VeeamLicenseInfo, ConvertTo-SystemInfoMetrics }
