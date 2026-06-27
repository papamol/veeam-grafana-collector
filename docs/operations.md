# Operations

## Install

Run from an elevated PowerShell 7 session:

```powershell
pwsh -ExecutionPolicy Bypass -File .\installer\Install.ps1
```

The installer validates configuration by running an initial collection and then creates a scheduled task that runs every 15 minutes.

## Upgrade

```powershell
pwsh -ExecutionPolicy Bypass -File .\installer\Upgrade.ps1
```

The upgrade script backs up `config.json` and `collector.log`, copies the new release, restores the existing configuration, and runs a collection.

## Uninstall

```powershell
pwsh -ExecutionPolicy Bypass -File .\installer\Uninstall.ps1
```

Use `-KeepConfig` to preserve configuration and logs under ProgramData.
