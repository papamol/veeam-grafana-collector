# Contributing

Thank you for helping improve Veeam Grafana Collector.

## Development Rules

- Use PowerShell 7.
- Keep collectors modular.
- Do not add direct connections to VMware, Hyper-V, Nutanix, storage, or other infrastructure platforms.
- Use Veeam REST API data only.
- Add or update Pester tests for behavioral changes.
- Run PSScriptAnalyzer before opening a pull request.

## Pull Requests

Pull requests should include:

- A clear problem statement.
- A summary of the implementation.
- Tests or a clear reason tests are not applicable.
- Any dashboard or measurement changes.
