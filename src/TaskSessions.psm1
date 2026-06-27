Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'Utilities.psm1') -Force -Global

function Get-VeeamTaskSessions {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/taskSessions'
}

function ConvertTo-TaskSessionMetrics {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyCollection()][object[]]$TaskSessions, [Parameter(Mandatory)][psobject]$Config)
    foreach ($task in $TaskSessions) {
        $jobName = Get-PropertyValue -InputObject $task -Names @('jobName') -Default 'unknown'
        $jobType = Get-PropertyValue -InputObject $task -Names @('jobType') -Default 'unknown'
        [pscustomobject]@{
            Measurement = 'veeam_vm_task_session'
            Tags = @{
                customer = $Config.Customer
                site = $Config.Site
                server = $Config.ServerName
                job_name = $jobName
                vm = Get-PropertyValue -InputObject $task -Names @('vmName', 'name') -Default 'unknown'
                job_category = Get-JobCategory -Type $jobType -Name $jobName
                result = Get-PropertyValue -InputObject $task -Names @('result') -Default 'Unknown'
                status = Get-PropertyValue -InputObject $task -Names @('state', 'status') -Default 'Unknown'
            }
            Fields = @{
                duration_seconds = [int](Get-PropertyValue -InputObject $task -Names @('durationSeconds', 'duration') -Default 0)
                failure_message = [string](Get-PropertyValue -InputObject $task -Names @('failureMessage', 'message') -Default '')
            }
        }
    }
}

if ($ExecutionContext.SessionState.Module) { Export-ModuleMember -Function Get-VeeamTaskSessions, ConvertTo-TaskSessionMetrics }
