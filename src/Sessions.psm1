Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamSessions {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/sessions'
}

function ConvertTo-SessionMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Sessions, [Parameter(Mandatory)][psobject]$Config)
    foreach ($session in $Sessions) {
        $jobName = Get-PropertyValue -InputObject $session -Names @('jobName', 'name') -Default 'unknown'
        $jobType = Get-PropertyValue -InputObject $session -Names @('jobType', 'type') -Default 'unknown'
        [pscustomobject]@{
            Measurement = 'veeam_job_session'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                job_name = $jobName
                job_category = Get-JobCategory -Type $jobType -Name $jobName
                result = ConvertTo-VeeamResultText -Value (Get-PropertyValue -InputObject $session -Names @('result') -Default 'Unknown')
                status = ConvertTo-FlatString -Value (Get-PropertyValue -InputObject $session -Names @('state', 'status') -Default 'Unknown')
            }
            Fields = @{
                duration_seconds = [int](Get-PropertyValue -InputObject $session -Names @('durationSeconds', 'duration') -Default 0)
                transferred_bytes = [double](Get-PropertyValue -InputObject $session -Names @('transferredBytes') -Default 0)
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamSessions, ConvertTo-SessionMetrics }
