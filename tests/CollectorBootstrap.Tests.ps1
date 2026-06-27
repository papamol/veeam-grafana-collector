Describe 'Collector bootstrap' {
    It 'loads required collector commands with the same import options used by Collector.ps1' {
        $moduleNames = @(
            'Logging',
            'Utilities',
            'Authentication',
            'InfluxWriter'
        )

        foreach ($moduleName in $moduleNames) {
            $modulePath = Join-Path $PSScriptRoot "../src/$moduleName.psm1"
            Import-Module $modulePath -Force -Global
        }

        foreach ($commandName in @('Initialize-Logger', 'Read-CollectorConfig', 'Connect-VeeamApi', 'ConvertTo-InfluxLine')) {
            Get-Command -Name $commandName -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }
}
