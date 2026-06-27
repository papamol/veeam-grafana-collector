BeforeAll {
    Import-Module "$PSScriptRoot/../src/InfluxWriter.psm1" -Force
}

Describe 'ConvertTo-InfluxLine' {
    It 'escapes tags and fields' {
        $line = ConvertTo-InfluxLine -Measurement 'veeam job' -Tags @{ job_name = 'Backup Job' } -Fields @{ enabled = $true; count = 2; message = 'ok' } -Timestamp ([datetime]'2026-01-01T00:00:00Z')
        $line | Should -Match '^veeam\\ job,job_name=Backup\\ Job '
        $line | Should -Match 'enabled=true'
        $line | Should -Match 'count=2i'
        $line | Should -Match 'message="ok"'
    }
}
