# Operations

## Install

Run from an elevated PowerShell session:

```powershell
pwsh -ExecutionPolicy Bypass -File .\installer\Install.ps1
```

The installer validates configuration by running an initial collection, checks that InfluxDB can read back recent metrics, and then creates a scheduled task that runs every 15 minutes. If Windows PowerShell starts the installer and `pwsh.exe` exists, the installer relaunches itself under PowerShell 7. If PowerShell 7 is missing and `winget.exe` is available, the installer attempts to install Microsoft PowerShell first.

## Firewall

Each Veeam server connects outbound only:

- Veeam REST API: local server, usually `https://localhost:9419/api`.
- InfluxDB v2: the configured `Influx.Url`, usually TCP `8086` for direct InfluxDB access.

Grafana reads from InfluxDB server-side. The collector does not require inbound access from Grafana, VMware, Hyper-V, Nutanix, or storage systems.

## Upgrade

```powershell
pwsh -ExecutionPolicy Bypass -File .\installer\Upgrade.ps1
```

The upgrade script backs up `config.json` and `collector.log`, copies the new release, restores the existing configuration, and runs a collection.

Use `-SkipValidation` only when staging files before repairing connectivity:

```powershell
pwsh -ExecutionPolicy Bypass -File .\installer\Upgrade.ps1 -SkipValidation
```

## Uninstall

```powershell
pwsh -ExecutionPolicy Bypass -File .\installer\Uninstall.ps1
```

Use `-KeepConfig` to preserve configuration and logs under ProgramData.
