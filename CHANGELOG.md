# Changelog

All notable changes to this project will be documented in this file.

This project follows Semantic Versioning.

## [0.1.2] - 2026-06-27

### Fixed

- Made collector module loading explicit and fail-fast during startup.
- Made installer and upgrade scripts stop when validation collection fails.

## [0.1.1] - 2026-06-26

### Fixed

- Fixed GitHub Actions ScriptAnalyzer invocation so CI passes on Windows runners.

## [0.1.0] - 2026-06-26

### Added

- Initial PowerShell 7 collector architecture.
- Veeam REST API authentication, retry, logging, and endpoint wrappers.
- InfluxDB v2 line protocol writer.
- Modular collectors for Veeam jobs, sessions, task sessions, VM inventory, protection, restore points, repositories, SOBR, backup copy, replication, tape, and infrastructure.
- Installer, upgrade, and uninstaller scripts.
- Grafana dashboard bundle.
- Pester tests and GitHub Actions.
- WiX MSI packaging skeleton.
