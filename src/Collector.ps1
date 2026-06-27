param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\config.json'),
    [string]$LogPath = (Join-Path $PSScriptRoot '..\collector.log')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$moduleNames = @(
    'Logging',
    'Utilities',
    'Authentication',
    'InfluxWriter',
    'Jobs',
    'Sessions',
    'TaskSessions',
    'VMInventory',
    'ProtectionAnalysis',
    'RestorePoints',
    'Repositories',
    'SOBR',
    'BackupCopy',
    'Replication',
    'Tape',
    'Infrastructure'
)

foreach ($moduleName in $moduleNames) {
    Import-Module (Join-Path $PSScriptRoot "$moduleName.psm1") -Force
}

function Add-MetricLines {
    param(
        [Parameter(Mandatory)][System.Collections.Generic.List[string]]$Lines,
        [Parameter(Mandatory)][object[]]$MetricObjects
    )

    foreach ($metric in $MetricObjects) {
        $Lines.Add((ConvertTo-InfluxLine -Measurement $metric.Measurement -Tags $metric.Tags -Fields $metric.Fields))
    }
}

Initialize-Logger -LogPath $LogPath
Write-CollectorLog -Message 'Collector started.'

try {
    $config = Read-CollectorConfig -Path $ConfigPath
    $session = Connect-VeeamApi -Config $config
    $lines = [System.Collections.Generic.List[string]]::new()

    $jobs = @(Get-VeeamJobs -Session $session)
    $sessions = @(Get-VeeamSessions -Session $session)
    $taskSessions = @(Get-VeeamTaskSessions -Session $session)
    $vms = @(Get-VeeamVMInventory -Session $session)
    $restorePoints = @(Get-VeeamRestorePoints -Session $session)
    $repositories = @(Get-VeeamRepositories -Session $session)
    $sobr = @(Get-VeeamSOBR -Session $session)
    $replicas = @(Get-VeeamReplicationJobs -Session $session)
    $tape = @(Get-VeeamTapeResources -Session $session)
    $infrastructure = Get-VeeamInfrastructure -Session $session

    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-JobMetrics -Jobs $jobs -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-JobCategorySummaryMetrics -Jobs $jobs -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-SessionMetrics -Sessions $sessions -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-TaskSessionMetrics -TaskSessions $taskSessions -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-VMInventoryMetrics -VMs $vms -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-RestorePointMetrics -RestorePoints $restorePoints -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-ProtectionMetrics -VMs $vms -RestorePoints $restorePoints -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-RepositoryMetrics -Repositories $repositories -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-SOBRMetrics -Repositories $sobr -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-ReplicationMetrics -Replicas $replicas -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-TapeMetrics -TapeResources $tape -Config $config)
    Add-MetricLines -Lines $lines -MetricObjects @(ConvertTo-InfrastructureMetrics -Infrastructure $infrastructure -Config $config)

    $summaryTags = @{
        customer = $config.Customer
        site = $config.Site
        server = $config.ServerName
    }
    $summaryFields = @{
        jobs = [int]$jobs.Count
        sessions = [int]$sessions.Count
        vms = [int]$vms.Count
        repositories = [int]$repositories.Count
        restore_points = [int]$restorePoints.Count
    }
    $lines.Add((ConvertTo-InfluxLine -Measurement 'veeam_server_summary' -Tags $summaryTags -Fields $summaryFields))

    Write-InfluxMetrics -Config $config -Lines $lines.ToArray()
    Write-CollectorLog -Message ("Collector completed. Wrote {0} metric lines." -f $lines.Count)
}
catch {
    Write-CollectorLog -Message $_.Exception.Message -Level ERROR
    throw
}
