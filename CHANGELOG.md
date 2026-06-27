# Changelog

All notable changes to this project will be documented in this file.

This project follows Semantic Versioning.

## [0.1.10] - 2026-06-27

### Fixed

- Used Veeam's `skip` paging parameter instead of `offset`.

## [0.1.9] - 2026-06-27

### Fixed

- Added after-response logging and a hard page cap for Veeam REST collection paging.

## [0.1.8] - 2026-06-27

### Fixed

- Reduced Veeam REST page size to one item for slow job endpoints.
- Logged each paged Veeam request during collection.

## [0.1.7] - 2026-06-27

### Fixed

- Paged Veeam REST collection calls to avoid unbounded endpoint requests timing out.

## [0.1.6] - 2026-06-27

### Fixed

- Added the Veeam API version header to REST calls.
- Added Veeam REST request timeouts and endpoint-specific error context.
- Added collector progress logging for each Veeam collection stage.

## [0.1.5] - 2026-06-27

### Fixed

- Added the required password grant type to Veeam REST API token requests.

## [0.1.4] - 2026-06-27

### Fixed

- Honored `Veeam.IgnoreCertificateErrors` with PowerShell 7 REST calls.

## [0.1.3] - 2026-06-27

### Fixed

- Prevented config validation output from being returned alongside the collector configuration.

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
