BeforeAll {
    Import-Module "$PSScriptRoot/../src/Utilities.psm1" -Force
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
