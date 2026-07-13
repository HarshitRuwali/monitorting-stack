# Persistent VM Monitoring Stack

Self-hosted monitoring for a Proxmox host, Linux VMs, and Docker-based applications. The stack uses Grafana for dashboards, Prometheus for metrics, Loki for logs, and Grafana Alloy as the collector agent.

## Stack

- `grafana`: dashboards and Explore UI on port `3000`.
- `prometheus`: persistent metrics storage on port `9090`.
- `loki`: persistent log storage on port `3100`.
- `collector`: Grafana Alloy agent for host metrics, systemd state, Docker metrics, journal logs, and Docker logs.

Prometheus, Loki, Grafana, and Alloy state are stored in Docker volumes so data survives container restarts.

## Quick Start

1. Create a local environment file:

```bash
cp .env.example .env
```

2. Edit `.env` and set at least:

```bash
GRAFANA_ADMIN_PASSWORD=<strong-password>
MONITOR_HOSTNAME=<central-server-name>
```

3. Start the central stack:

```bash
docker compose up -d
```

4. Open Grafana:

```text
http://<central-server-ip>:3000
```

The default Grafana user is `admin` unless you change `GRAFANA_ADMIN_USER`.

## Add VM Collectors

Copy this repository, or at least `docker-compose.collector.yml` and `alloy/config.alloy`, to each VM. Then run:

```bash
export MONITORING_SERVER=<central-server-ip-or-dns>
export MONITOR_HOSTNAME=<vm-name>
export MONITOR_ROLE=vm
docker compose -f docker-compose.collector.yml up -d
```

After one or two minutes, the VM should appear in the dashboard host selector.

## Dashboards

Grafana automatically loads dashboards from `grafana/dashboards`:

- `System Overview`: CPU, memory, disk, network, uptime, and host count.
- `Services and Logs`: systemd unit state, Docker metrics, journal logs, and Docker logs.
- `VM Fleet Overview`: fleet health, top resource consumers, and warnings/errors.

## Repo Layout

```text
alloy/                         Collector pipeline config
docs/                          Architecture, rollout, security, and operations notes
grafana/dashboards/            Provisioned Grafana dashboards
grafana/provisioning/          Grafana datasource and dashboard provisioning
loki/                          Loki local filesystem storage config
prometheus/                    Prometheus scrape/storage config
docker-compose.yml             Central monitoring stack
docker-compose.collector.yml   Collector-only stack for each VM
```

## More Docs

- [Architecture](docs/architecture.md)
- [VM Collector Rollout](docs/vm-collector.md)
- [Operations](docs/operations.md)
- [Security Notes](docs/security.md)

## Validation

```bash
GRAFANA_ADMIN_PASSWORD=validate-only docker compose config
MONITORING_SERVER=127.0.0.1 MONITOR_HOSTNAME=test-vm docker compose -f docker-compose.collector.yml config
jq empty grafana/dashboards/*.json
```
