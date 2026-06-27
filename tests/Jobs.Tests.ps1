BeforeAll {
    Import-Module "$PSScriptRoot/../src/Jobs.psm1" -Force
}

Describe 'ConvertTo-JobMetrics' {
    It 'creates job info metrics with normalized category' {
        $config = [pscustomobject]@{ Customer = 'A'; Site = 'B'; ServerName = 'C' }
        $jobs = @([pscustomobject]@{ name = 'Tape Weekly'; type = 'Tape'; isEnabled = $true; priority = 1 })
        $metric = ConvertTo-JobMetrics -Jobs $jobs -Config $config
        $metric.Measurement | Should -Be 'veeam_job_info'
        $metric.Tags.job_category | Should -Be 'Tape'
        $metric.Fields.enabled | Should -BeTrue
    }
}
