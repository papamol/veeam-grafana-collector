BeforeAll {
    Import-Module "$PSScriptRoot/../src/Sessions.psm1" -Force
    Import-Module "$PSScriptRoot/../src/TaskSessions.psm1" -Force
    Import-Module "$PSScriptRoot/../src/InfluxWriter.psm1" -Force
}

Describe 'ConvertTo-SessionMetrics' {
    It 'normalizes structured Veeam result objects before writing line protocol tags' {
        $config = [pscustomobject]@{ Customer = 'A'; Site = 'B'; ServerName = 'C' }
        $sessions = @(
            [pscustomobject]@{
                jobName = 'Backup Job'
                jobType = 'Backup'
                result = [pscustomobject]@{
                    result = 'Failed'
                    message = "Unable to allocate processing resources.`r`nImport snapshot task has failed."
                }
                state = 'Stopped'
            }
        )

        $metric = ConvertTo-SessionMetrics -Sessions $sessions -Config $config
        $line = ConvertTo-InfluxLine -Measurement $metric.Measurement -Tags $metric.Tags -Fields $metric.Fields

        $metric.Tags.result | Should -Be 'Failed'
        $line | Should -Match 'result=Failed'
        $line | Should -Not -Match "`r|`n"
        $line | Should -Not -Match '@\\{'
    }
}

Describe 'ConvertTo-TaskSessionMetrics' {
    It 'flattens multiline task failure messages before writing line protocol fields' {
        $config = [pscustomobject]@{ Customer = 'A'; Site = 'B'; ServerName = 'C' }
        $tasks = @(
            [pscustomobject]@{
                jobName = 'Backup Job'
                jobType = 'Backup'
                vmName = 'vm01'
                result = [pscustomobject]@{
                    result = 'Failed'
                    message = "Processing vm01 Error: The system cannot find the path specified.`r`nFailed to open file."
                }
                state = 'Stopped'
                message = "Processing vm01 Error.`r`nFailed to open file."
            }
        )

        $metric = ConvertTo-TaskSessionMetrics -TaskSessions $tasks -Config $config
        $line = ConvertTo-InfluxLine -Measurement $metric.Measurement -Tags $metric.Tags -Fields $metric.Fields

        $metric.Tags.result | Should -Be 'Failed'
        $metric.Fields.failure_message | Should -Be 'Processing vm01 Error. Failed to open file.'
        $line | Should -Not -Match "`r|`n"
        $line | Should -Not -Match '@\\{'
    }
}
