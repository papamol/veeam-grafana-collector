# Changelog

All notable changes to this project will be documented in this file.

This project follows Semantic Versioning.

## [0.2.3] - 2026-06-27

### Fixed

- Rebuilt the Grafana dashboard bundle under the original dashboard UIDs instead of side-copy dashboards.
- Defaulted query variables to `All` so imported dashboards do not render blank when customer, site, server, VM, or repository variables are unset.
- Added consistent VM and repository drill-down links across operational tables.
- Reworked overview, executive, protection, backup, repository, VM, replication, tape, infrastructure, and failed-job dashboards around confirmed collector measurements.
- Added dashboard bundle tests for valid JSON, required drill-down dashboards, and safe default variables.

## [0.2.2] - 2026-06-27

### Changed

- Reworked the overview dashboard summary into large readable stat cards.
- Renamed endpoint coverage to Veeam API collection health and added a plain-language panel description.
- Added no-backup VM tables to the overview and protection dashboards.
- Added a protection drill-down layout with no-backup, stale-protection, and all-VM detail tables.

## [0.2.1] - 2026-06-27

### Fixed

- Derived `veeam_vm_inventory` from Veeam restore point, task session, and replication data when REST inventory endpoints are blocked or unavailable.
- Stopped retrying non-retryable Veeam REST `403`, `404`, and `405` endpoint failures to reduce slow optional endpoint probes.

## [0.2.0] - 2026-06-27

### Added

- Added the `v0.2.0` implementation checklist from the original project requirements.
- Added optional `Collection` configuration for page size, max pages, request timeout, and per-endpoint max page overrides.
- Added `veeam_endpoint_status` metrics so dashboards can distinguish skipped or unsupported Veeam endpoints from true no-data conditions.
- Added overview dashboard collector summary and endpoint coverage panels.
- Added Veeam version, license, and object storage metrics with graceful endpoint fallback.
- Added VM inventory, object storage, server info, and license endpoint fallback support for Veeam REST version differences.
- Added a complete dashboard suite for executive, backup, replication, tape, infrastructure, repository, protection, VM, and failed-job views.
- Added richer VM protection classification for backup, backup copy, replication, both backup and replication, no backup, and stale protection states.
- Added PSScriptAnalyzer settings and pinned WiX bootstrap in CI/CD release workflows.

### Changed

- Improved tape collection to gather tape jobs, libraries, pools, media, capacity, and errors when exposed by the Veeam REST API.
- Improved installer PowerShell 7 handling and added an InfluxDB read-back check after initial collection.
- Added an upgrade `-SkipValidation` option for staging files when connectivity must be repaired separately.

## [0.1.16] - 2026-06-27

### Fixed

- Let InfluxDB assign write timestamps by default to avoid future-dated points from local time conversion.

## [0.1.15] - 2026-06-27

### Fixed

- Allowed infrastructure metric conversion to continue when optional infrastructure endpoints are missing.

## [0.1.14] - 2026-06-27

### Fixed

- Allowed metric converters to accept empty collections after skipped Veeam endpoints.

## [0.1.13] - 2026-06-27

### Fixed

- Allowed metric aggregation to start with an empty metric line collection.

## [0.1.12] - 2026-06-27

### Fixed

- Limited Veeam REST collection to the first safe page by default to avoid servers that hang on subsequent pages.

## [0.1.11] - 2026-06-27

### Fixed

- Reduced Veeam REST timeouts for collection requests.
- Allowed the collector to skip slow or unsupported Veeam endpoints instead of blocking the whole run.
- Returned partial paged results when a later Veeam page times out.

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
