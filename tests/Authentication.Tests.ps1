BeforeAll {
    Import-Module "$PSScriptRoot/../src/Authentication.psm1" -Force
}

Describe 'Get-VeeamCollection' {
    It 'pages requests and preserves existing query strings' {
        $requestedUris = [System.Collections.Generic.List[string]]::new()
        Mock Invoke-RestMethod {
            $requestedUris.Add($Uri)
            if ($Uri -like '*offset=0') {
                return [pscustomobject]@{
                    data = @(
                        [pscustomobject]@{ id = 'job-1' },
                        [pscustomobject]@{ id = 'job-2' }
                    )
                }
            }

            return [pscustomobject]@{
                data = @(
                    [pscustomobject]@{ id = 'job-3' }
                )
            }
        } -ModuleName Authentication

        $session = [pscustomobject]@{
            BaseUrl = 'https://localhost:9419/api'
            Headers = @{
                Authorization = 'Bearer token'
                Accept = 'application/json'
                'x-api-version' = '1.3-rev1'
            }
            SkipCertificateCheck = $true
            TimeoutSec = 120
        }

        $result = Get-VeeamCollection -Session $session -Path '/v1/jobs?type=Replication' -Limit 2

        $result.Count | Should -Be 3
        $requestedUris[0] | Should -Be 'https://localhost:9419/api/v1/jobs?type=Replication&limit=2&offset=0'
        $requestedUris[1] | Should -Be 'https://localhost:9419/api/v1/jobs?type=Replication&limit=2&offset=2'
    }
}
