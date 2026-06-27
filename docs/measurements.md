# Measurements

Common tags:

- `customer`
- `site`
- `server`

## veeam_server_summary

Fields: `jobs`, `sessions`, `vms`, `repositories`, `object_storage_repositories`, `restore_points`.

## veeam_job_info

Tags: `job_name`, `job_type`, `job_category`.

Fields: `enabled`, `priority`.

## veeam_job_session

Tags: `job_name`, `job_category`, `result`, `status`.

Fields: `duration_seconds`, `transferred_bytes`.

## veeam_job_category_summary

Tags: `job_category`.

Fields: `count`.

## veeam_vm_inventory

Tags: `vm`, `platform`, `cluster`, `host`, `folder`, `datastore`, `power_state`.

Fields: `present`.

## veeam_vm_task_session

Tags: `job_name`, `job_category`, `vm`, `result`, `status`.

Fields: `duration_seconds`, `failure_message`.

## veeam_vm_protection

Tags: `vm`, `protection_status`.

Fields: `protected`, `backup`, `backup_copy`, `replication`, `no_backup`, `restore_point_count`, `latest_restore_point_age_hours`, `stale_backup`, `stale_replication`.

## veeam_restore_points

Tags: `vm`, `repository`.

Fields: `restore_point_count`, `latest_restore_point_age_hours`, `backup_copy_status`.

## veeam_endpoint_status

Tags: `collector`, `endpoint`, `status`.

Fields: `available`, `item_count`, `duration_ms`, `error`.

## veeam_repository

Tags: `repository`, `type`, `immutable`.

Fields: `capacity_bytes`, `free_bytes`, `used_bytes`.

## veeam_object_storage

Tags: `repository`, `type`, `immutable`.

Fields: `capacity_bytes`, `free_bytes`, `used_bytes`.

## veeam_sobr

Tags: `repository`, `policy`.

Fields: `extent_count`, `capacity_bytes`, `free_bytes`.

## veeam_replication

Tags: `replica_vm`, `target_host`, `source_host`.

Fields: `rpo_minutes`, `duration_seconds`, `failure_reason`.

## veeam_tape

Tags: `name`, `type`, `resource_kind`, `pool`.

Fields: `capacity_bytes`, `free_bytes`, `error_count`.

## veeam_proxy

Tags: `proxy`.

Fields: `enabled`, `max_tasks`.

## veeam_gateway

Tags: `gateway`.

Fields: `enabled`.

## veeam_mount_server

Tags: `mount_server`.

Fields: `enabled`.

## veeam_version_info

Tags: `version`, `edition`, `build`.

Fields: `present`.

## veeam_license_info

Tags: `edition`, `status`, `type`.

Fields: `instances_used`, `instances_total`, `days_remaining`.
