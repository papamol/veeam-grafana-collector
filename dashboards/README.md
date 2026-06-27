# Grafana Dashboards

Import `veeam-grafana-collector-overview.json` into Grafana and select the InfluxDB datasource.

The overview dashboard covers:

- Executive summary
- Backup jobs
- Replication
- Tape
- Infrastructure
- Repositories
- Protection
- VM drill-downs
- Failed jobs and failed VM task sessions

The JSON includes variables for customer, site, server, job category, VM, and repository. Additional persona-specific dashboards can reuse the same Flux queries and variables.
