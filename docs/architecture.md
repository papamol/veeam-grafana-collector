# Architecture

Each Veeam Backup Server runs one collector instance. The collector authenticates to the local Veeam REST API and exports normalized metrics to InfluxDB v2.

## Boundaries

The collector must never call platform-specific infrastructure APIs. Veeam is the only source of truth for:

- VM inventory
- Job and session history
- Protection status
- Repository capacity
- Proxy, gateway, mount server, and WAN accelerator inventory
- Tape and replication status

## Metric Flow

1. `Collector.ps1` loads configuration and modules.
2. `Authentication.psm1` obtains a Veeam API token.
3. Collector modules request Veeam resources.
4. Conversion functions normalize Veeam objects into measurement, tags, and fields.
5. `InfluxWriter.psm1` serializes line protocol and writes to InfluxDB.
6. Grafana dashboards query InfluxDB.
