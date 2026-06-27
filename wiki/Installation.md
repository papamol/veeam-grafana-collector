# Installation

Run `installer/Install.ps1` from an elevated PowerShell session on each Veeam Backup Server. The collector creates a local configuration file and scheduled task.

The collector sends metrics outbound to InfluxDB v2. Open outbound TCP `8086` from each Veeam server to the InfluxDB endpoint unless your InfluxDB URL uses a different port or is published through HTTPS on `443`.
