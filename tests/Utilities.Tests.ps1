BeforeAll {
    Import-Module "$PSScriptRoot/../src/Utilities.psm1" -Force
}

Describe 'Read-CollectorConfig' {
    It 'returns only the configuration object' {
        $configPath = Join-Path $TestDrive 'config.json'
        @{
            Customer = 'Elevated-DFW-Customers'
            Site = 'DFW'
            ServerName = 'DFW-Veeam-Server'
            Veeam = @{
                BaseUrl = 'https://localhost:9419/api'
                Username = 'svc_veeam_grafana'
                Password = 'secret'
                IgnoreCertificateErrors = $true
            }
            Influx = @{
                Url = 'http://veeam.elevated.net:8086'
                Org = 'Elevated'
                Bucket = 'veeam_grafana_collector'
                Token = 'token'
            }
        } | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath

        $config = Read-CollectorConfig -Path $configPath

        $config | Should -Not -BeOfType ([array])
        $config.Veeam.BaseUrl | Should -Be 'https://localhost:9419/api'
        $config.Influx.Bucket | Should -Be 'veeam_grafana_collector'
    }
}

Describe 'Get-JobCategory' {
    It 'normalizes backup copy jobs' {
        Get-JobCategory -Type 'BackupCopy' -Name 'Copy to DR' | Should -Be 'Backup Copy'
    }

    It 'normalizes replication jobs' {
        Get-JobCategory -Type 'Replica' -Name 'Replicate SQL' | Should -Be 'Replication'
    }

    It 'normalizes agent jobs' {
        Get-JobCategory -Type 'Windows Agent Backup' -Name 'Endpoint' | Should -Be 'Agent'
    }

    It 'falls back to Other' {
        Get-JobCategory -Type 'Custom' -Name 'Unknown' | Should -Be 'Other'
    }
}

Describe 'Test-CollectorConfig' {
    It 'accepts valid config' {
        $config = [pscustomobject]@{
            Customer = 'Customer'
            Site = 'Site'
            ServerName = 'VBR01'
            Veeam = [pscustomobject]@{
                BaseUrl = 'https://localhost:9419/api'
                Username = 'user'
                Password = 'pass'
                IgnoreCertificateErrors = $false
            }
            Influx = [pscustomobject]@{
                Url = 'https://influx.example.com'
                Org = 'org'
                Bucket = 'bucket'
                Token = 'token'
            }
        }

        Test-CollectorConfig -Config $config | Should -BeTrue
    }
}

Describe 'Invoke-WithRetry' {
    It 'does not retry non-retryable 404 REST failures' {
        $script:attempts = 0

        { Invoke-WithRetry -MaxAttempts 3 -InitialDelaySeconds 1 -ScriptBlock {
            $script:attempts++
            throw 'Response status code does not indicate success: 404 (Not Found).'
        } } | Should -Throw

        $script:attempts | Should -Be 1
    }

    It 'retries retryable 500 REST failures' {
        $script:attempts = 0

        { Invoke-WithRetry -MaxAttempts 2 -InitialDelaySeconds 0 -ScriptBlock {
            $script:attempts++
            throw 'Response status code does not indicate success: 500 (Internal Server Error).'
        } } | Should -Throw

        $script:attempts | Should -Be 2
    }
}
