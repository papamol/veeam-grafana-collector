# Veeam Grafana Collector

PowerShell 7 collector for MSP-friendly Veeam reporting with InfluxDB v2 and Grafana.

This project is intended as an open-source alternative reporting layer for environments where each Veeam Backup & Replication server exports its own data. The collector talks only to the local Veeam REST API and sends metrics outbound to InfluxDB over HTTPS. It never connects directly to VMware, Hyper-V, Nutanix, storage arrays, or other infrastructure APIs.

## Status

Initial production scaffold, version `0.1.0`. API endpoint coverage is intentionally modular so new Veeam REST resources can be added without turning the collector into one giant script.

## Features

- PowerShell 7 collector entry point
- Veeam REST authentication with retry, logging, and optional certificate bypass
- InfluxDB v2 line protocol writer
- JSON configuration with validation
- Normalized job categories: `Backup`, `Backup Copy`, `Replication`, `Tape`, `SureBackup`, `NAS`, `Agent`, `Other`
- Collectors for jobs, sessions, task sessions, VM inventory, protection analysis, restore points, repositories, SOBR, backup copy, replication, tape, infrastructure, server summary, license, and version information
- Windows installer, upgrade, and uninstaller scripts
- Windows Scheduled Task support
- Grafana dashboard bundle with variables and drill-down links
- Pester tests
- GitHub Actions for lint, test, package, and release
- WiX packaging skeleton for MSI builds

## Architecture

```mermaid
flowchart LR
  VBR["Veeam Backup Server"] --> REST["Local Veeam REST API"]
  REST --> Collector["PowerShell 7 Collector"]
  Collector -->|Outbound HTTPS| Influx["InfluxDB v2"]
  Influx --> Grafana["Grafana Dashboards"]
```

The collector uses only Veeam as the source of truth. VM inventory, protection state, repository capacity, tape, replication, and infrastructure data are collected through Veeam REST API endpoints.

## Quick Start

1. Install PowerShell 7 on the Veeam Backup Server.
2. Extract a release ZIP to `C:\Program Files\VeeamGrafanaCollector`.
3. Run the installer from an elevated PowerShell 7 session:

```powershell
pwsh -ExecutionPolicy Bypass -File .\installer\Install.ps1
```

4. Import dashboards from `dashboards/` into Grafana.
5. Confirm data arrives in the InfluxDB bucket.

## Configuration

The installer creates `config.json`.

```json
{
  "Customer": "Example MSP Customer",
  "Site": "Primary",
  "ServerName": "VBR01",
  "Veeam": {
    "BaseUrl": "https://localhost:9419/api",
    "Username": "DOMAIN\\svc-veeam-api",
    "Password": "replace-me",
    "IgnoreCertificateErrors": false,
    "ApiVersion": "1.3-rev1"
  },
  "Collection": {
    "PageSize": 1,
    "MaxPages": 1,
    "RequestTimeoutSeconds": 30,
    "EndpointMaxPages": {
      "/v1/sessions": 10,
      "/v1/taskSessions": 10
    }
  },
  "Influx": {
    "Url": "https://influx.example.com",
    "Org": "msp",
    "Bucket": "veeam",
    "Token": "replace-me"
  }
}
```

`Collection` is optional. Defaults are conservative because some Veeam REST endpoints can be slow or hang when deeply paged. Increase `PageSize`, `MaxPages`, or `EndpointMaxPages` after validating endpoint behavior in your environment.

## Run Manually

```powershell
pwsh -File .\src\Collector.ps1 -ConfigPath .\config.json
```

## Measurements

- `veeam_server_summary`
- `veeam_job_info`
- `veeam_job_session`
- `veeam_job_category_summary`
- `veeam_vm_inventory`
- `veeam_vm_task_session`
- `veeam_vm_protection`
- `veeam_restore_points`
- `veeam_repository`
- `veeam_sobr`
- `veeam_replication`
- `veeam_tape`
- `veeam_proxy`
- `veeam_gateway`
- `veeam_mount_server`

## Development

```powershell
pwsh -NoLogo -NoProfile -Command "Invoke-Pester ./tests"
```

Run lint locally with PSScriptAnalyzer:

```powershell
Install-Module PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path ./src,./installer -Recurse
```

## GitHub Setup

If `gh` is installed and authenticated:

```bash
gh repo create veeam-grafana-collector --public --source=. --remote=origin --push
git tag v0.1.0
git push origin v0.1.0
```

Without `gh`, create an empty repository on GitHub, then:

```bash
git remote add origin git@github.com:YOUR_ORG/veeam-grafana-collector.git
git push -u origin main
git tag v0.1.0
git push origin v0.1.0
```
