# Security Policy

## Supported Versions

| Version | Supported |
| --- | --- |
| 0.1.x | Yes |

## Reporting a Vulnerability

Please report security issues privately through GitHub Security Advisories when the repository is published. Do not open a public issue for credential disclosure, authentication bypass, or data exposure bugs.

## Credential Handling

The installer writes Veeam and InfluxDB credentials to `config.json`. Operators should restrict file permissions to the collector service account and local administrators. A future release will add optional Windows Credential Manager and SecretManagement providers.
