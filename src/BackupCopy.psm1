Set-StrictMode -Version Latest

Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1') -Force

function Get-VeeamBackupCopyJobs {
    [CmdletBinding()]
    param([Parameter(Mandatory)][psobject]$Session)
    Get-VeeamCollection -Session $Session -Path '/v1/jobs?type=BackupCopy'
}

Export-ModuleMember -Function Get-VeeamBackupCopyJobs
