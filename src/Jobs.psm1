Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force

function Get-VeeamJobs {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/jobs'
}

function ConvertTo-JobMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Jobs,
        [Parameter(Mandatory)]
        [psobject]$Config
    )

    foreach ($job in $Jobs) {
        $name = Get-PropertyValue -InputObject $job -Names @('name', 'Name') -Default 'unknown'
        $type = Get-PropertyValue -InputObject $job -Names @('type', 'jobType', 'Type') -Default 'unknown'
        $category = Get-JobCategory -Type $type -Name $name
        [pscustomobject]@{
            Measurement = 'veeam_job_info'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                job_name = $name
                job_type = $type
                job_category = $category
            }
            Fields = @{
                enabled = [bool](Get-PropertyValue -InputObject $job -Names @('isEnabled', 'enabled') -Default $true)
                priority = [int](Get-PropertyValue -InputObject $job -Names @('priority') -Default 0)
            }
        }
    }
}

function ConvertTo-JobCategorySummaryMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$Jobs,
        [Parameter(Mandatory)]
        [psobject]$Config
    )

    $Jobs | Group-Object { Get-JobCategory -Type (Get-PropertyValue -InputObject $_ -Names @('type', 'jobType', 'Type')) -Name (Get-PropertyValue -InputObject $_ -Names @('name', 'Name')) } | ForEach-Object {
        [pscustomobject]@{
            Measurement = 'veeam_job_category_summary'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                job_category = $_.Name
            }
            Fields = @{
                count = [int]$_.Count
            }
        }
    }
}

Export-ModuleMember -Function Get-VeeamJobs, ConvertTo-JobMetrics, ConvertTo-JobCategorySummaryMetrics
