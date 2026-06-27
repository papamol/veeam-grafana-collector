# Measurements

Common tags:

- `customer`
- `site`
- `server`

## veeam_server_summary

Fields: `jobs`, `sessions`, `vms`, `repositories`, `restore_points`.

## veeam_job_info

Tags: `job_name`, `job_type`, `job_category`.

Fields: `enabled`, `priority`.

## veeam_vm_task_session

Tags: `job_name`, `job_category`, `vm`, `result`, `status`.

Fields: `duration_seconds`, `failure_message`.

## veeam_vm_protection

Tags: `vm`, `protection_status`.

Fields: `protected`, `restore_point_count`, `latest_restore_point_age_hours`, `stale_backup`, `stale_replication`.
