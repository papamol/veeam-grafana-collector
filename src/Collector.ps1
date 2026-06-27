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
    $modulePath = Join-Path $PSScriptRoot "$moduleName.psm1"
    if (-not (Test-Path $modulePath)) {
        throw "Required module not found: $modulePath"
    }

    Import-Module $modulePath -Force -Global
}

$requiredCommands = @(
    'Initialize-Logger',
    'Write-CollectorLog',
    'Read-CollectorConfig',
    'Connect-VeeamApi',
    'ConvertTo-InfluxLine',
    'Write-InfluxMetrics'
)

foreach ($commandName in $requiredCommands) {
    if (-not (Get-Command -Name $commandName -ErrorAction SilentlyContinue)) {
        throw "Required collector command was not loaded: $commandName"
    }
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

function Invoke-CollectorStep {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$ScriptBlock
    )

    Write-CollectorLog -Message "Collecting $Name..."
    $result = & $ScriptBlock
    $count = if ($null -eq $result) {
        0
    }
    elseif ($result -is [System.Collections.ICollection]) {
        $result.Count
    }
    else {
        1
    }
    Write-CollectorLog -Message ("Collected {0}: {1}" -f $Name, $count)
    return $result
}

Initialize-Logger -LogPath $LogPath
Write-CollectorLog -Message 'Collector started.'

try {
    $config = Read-CollectorConfig -Path $ConfigPath
    $session = Connect-VeeamApi -Config $config
    Write-CollectorLog -Message 'Authenticated to Veeam REST API.'
    $lines = [System.Collections.Generic.List[string]]::new()

    $jobs = @(Invoke-CollectorStep -Name 'jobs' -ScriptBlock { Get-VeeamJobs -Session $session })
    $sessions = @(Invoke-CollectorStep -Name 'sessions' -ScriptBlock { Get-VeeamSessions -Session $session })
    $taskSessions = @(Invoke-CollectorStep -Name 'task sessions' -ScriptBlock { Get-VeeamTaskSessions -Session $session })
    $vms = @(Invoke-CollectorStep -Name 'VM inventory' -ScriptBlock { Get-VeeamVMInventory -Session $session })
    $restorePoints = @(Invoke-CollectorStep -Name 'restore points' -ScriptBlock { Get-VeeamRestorePoints -Session $session })
    $repositories = @(Invoke-CollectorStep -Name 'repositories' -ScriptBlock { Get-VeeamRepositories -Session $session })
    $sobr = @(Invoke-CollectorStep -Name 'scale-out repositories' -ScriptBlock { Get-VeeamSOBR -Session $session })
    $replicas = @(Invoke-CollectorStep -Name 'replication jobs' -ScriptBlock { Get-VeeamReplicationJobs -Session $session })
    $tape = @(Invoke-CollectorStep -Name 'tape resources' -ScriptBlock { Get-VeeamTapeResources -Session $session })
    $infrastructure = Invoke-CollectorStep -Name 'infrastructure' -ScriptBlock { Get-VeeamInfrastructure -Session $session }

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

    Write-CollectorLog -Message ("Writing {0} metric lines to InfluxDB..." -f $lines.Count)
    Write-InfluxMetrics -Config $config -Lines $lines.ToArray()
    Write-CollectorLog -Message ("Collector completed. Wrote {0} metric lines." -f $lines.Count)
}
catch {
    Write-CollectorLog -Message $_.Exception.Message -Level ERROR
    throw
}
