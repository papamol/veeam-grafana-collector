Describe 'Grafana dashboard bundle' {
    BeforeAll {
        $script:DashboardFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot '..' 'dashboards') -Filter '*.json'
    }

    It 'contains valid dashboard JSON files' {
        $script:DashboardFiles.Count | Should -BeGreaterThan 0

        foreach ($file in $script:DashboardFiles) {
            { Get-Content -Path $file.FullName -Raw | ConvertFrom-Json -Depth 100 } | Should -Not -Throw
        }
    }

    It 'defaults query variables to All so dashboards are not blank after import' {
        foreach ($file in $script:DashboardFiles) {
            $dashboard = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json -Depth 100
            $variables = @($dashboard.templating.list | Where-Object { $_.type -eq 'query' })

            foreach ($variable in $variables) {
                $variable.includeAll | Should -BeTrue -Because "$($file.Name) variable $($variable.name) should support All"
                $variable.allValue | Should -Be '.*'
                $variable.current.text | Should -Be 'All'
            }
        }
    }

    It 'defaults the datasource variable to the collector InfluxDB datasource UID' {
        foreach ($file in $script:DashboardFiles) {
            $dashboard = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json -Depth 100
            $datasource = $dashboard.templating.list | Where-Object { $_.name -eq 'datasource' }

            $datasource.current.text | Should -Be 'influxdb-veeam-grafana-collector'
            $datasource.current.value | Should -Be 'veeam-grafana-collector-influx'
        }
    }

    It 'includes the required operational drill-down dashboards' {
        $uids = @($script:DashboardFiles | ForEach-Object {
            (Get-Content -Path $_.FullName -Raw | ConvertFrom-Json -Depth 100).uid
        })

        $uids | Should -Contain 'veeam-grafana-collector-overview'
        $uids | Should -Contain 'veeam-grafana-collector-protection'
        $uids | Should -Contain 'veeam-operations-protection'
        $uids | Should -Contain 'veeam-grafana-collector-vm'
        $uids | Should -Contain 'veeam-grafana-collector-repository'
        $uids | Should -Contain 'veeam-grafana-collector-failed-jobs'
    }
}
