# VM Collector Rollout

Use `docker-compose.collector.yml` on every VM you want in the central dashboard.

## Requirements

- Docker and Docker Compose plugin installed on the VM.
- Network access from the VM to the central server on ports `9090` and `3100`.
- Linux host paths available for metrics/log collection: `/proc`, `/sys`, `/var/run`, `/var/log/journal`, and `/run/log/journal`.
- Docker socket access if the VM runs containers.

## Install

Copy these files to the VM:

```text
docker-compose.collector.yml
alloy/config.alloy
```

Start the collector:

```bash
export MONITORING_SERVER=<central-server-ip-or-dns>
export MONITOR_HOSTNAME=<stable-vm-name>
export MONITOR_ROLE=vm
docker compose -f docker-compose.collector.yml up -d
```

Use a stable `MONITOR_HOSTNAME`; changing it creates a new host identity in Prometheus and Loki.

## Verify

On the VM:

```bash
docker compose -f docker-compose.collector.yml ps
docker logs monitoring-collector --tail 100
```

On the central server:

```bash
curl 'http://localhost:9090/api/v1/query' --data-urlencode 'query=node_uname_info'
curl http://localhost:3100/ready
```

In Grafana, open any dashboard and select the VM from the `host` variable.

## Notes

- VMs without Docker still report host metrics and journal logs; Docker panels remain empty for those hosts.
- If journald persistent storage is disabled, Alloy can still read runtime logs from `/run/log/journal` when available.
- Collector debug UI is intentionally not published in `docker-compose.collector.yml`.
