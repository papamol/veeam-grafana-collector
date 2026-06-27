BeforeAll {
    Import-Module "$PSScriptRoot/../src/Authentication.psm1" -Force
}

Describe 'Get-VeeamCollection' {
    It 'uses conservative collection defaults when config does not override them' {
        $requestedUris = [System.Collections.Generic.List[string]]::new()
        Mock Invoke-RestMethod {
            $requestedUris.Add($Uri)
            [pscustomobject]@{
                data = @([pscustomobject]@{ id = 'job-1' })
                pagination = [pscustomobject]@{
                    total = 10
                    count = 1
                    skip = 0
                    limit = 1
                }
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
            TimeoutSec = 30
        }

        $result = Get-VeeamCollection -Session $session -Path '/v1/jobs'

        $result.Count | Should -Be 1
        $requestedUris.Count | Should -Be 1
        $requestedUris[0] | Should -Be 'https://localhost:9419/api/v1/jobs?limit=1&skip=0'
    }

    It 'pages requests and preserves existing query strings' {
        $requestedUris = [System.Collections.Generic.List[string]]::new()
        Mock Invoke-RestMethod {
            $requestedUris.Add($Uri)
            if ($Uri -like '*skip=0') {
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

        $result = Get-VeeamCollection -Session $session -Path '/v1/jobs?type=Replication' -Limit 2 -MaxPages 2

        $result.Count | Should -Be 3
        $requestedUris[0] | Should -Be 'https://localhost:9419/api/v1/jobs?type=Replication&limit=2&skip=0'
        $requestedUris[1] | Should -Be 'https://localhost:9419/api/v1/jobs?type=Replication&limit=2&skip=2'
    }

    It 'uses collection settings from the session and honors endpoint max page overrides' {
        $requestedUris = [System.Collections.Generic.List[string]]::new()
        Mock Invoke-RestMethod {
            $requestedUris.Add($Uri)
            [pscustomobject]@{
                data = @(
                    [pscustomobject]@{ id = "session-$($requestedUris.Count)" },
                    [pscustomobject]@{ id = "session-$($requestedUris.Count)-b" }
                )
                pagination = [pscustomobject]@{
                    total = 20
                    count = 2
                    skip = ($requestedUris.Count - 1) * 2
                    limit = 2
                }
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
            TimeoutSec = 30
            Collection = [pscustomobject]@{
                PageSize = 2
                MaxPages = 1
                RequestTimeoutSeconds = 30
                EndpointMaxPages = @{
                    '/v1/sessions' = 3
                }
            }
        }

        $result = Get-VeeamCollection -Session $session -Path '/v1/sessions'

        $result.Count | Should -Be 6
        $requestedUris.Count | Should -Be 3
        $requestedUris[0] | Should -Be 'https://localhost:9419/api/v1/sessions?limit=2&skip=0'
        $requestedUris[1] | Should -Be 'https://localhost:9419/api/v1/sessions?limit=2&skip=2'
        $requestedUris[2] | Should -Be 'https://localhost:9419/api/v1/sessions?limit=2&skip=4'
    }
}
