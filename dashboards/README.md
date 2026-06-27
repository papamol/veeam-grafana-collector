# Grafana Dashboards

Import the JSON files into Grafana and select the InfluxDB datasource.

Included dashboards:

- `veeam-grafana-collector-overview.json`
- `veeam-grafana-collector-executive.json`
- `veeam-grafana-collector-backup.json`
- `veeam-grafana-collector-replication.json`
- `veeam-grafana-collector-tape.json`
- `veeam-grafana-collector-infrastructure.json`
- `veeam-grafana-collector-repositories.json`
- `veeam-grafana-collector-protection.json`
- `veeam-grafana-collector-vm.json`
- `veeam-grafana-collector-repository.json`
- `veeam-grafana-collector-failed-jobs.json`

The JSON includes variables for customer, site, server, job category, VM, and repository. Dashboards include drill-down links so Grafana can navigate between related Veeam Collector dashboards while preserving variables and time range.
