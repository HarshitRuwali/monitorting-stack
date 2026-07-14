# Persistent VM Monitoring Stack

Self-hosted monitoring for a Proxmox host, Linux VMs, and Docker-based applications. The stack uses Grafana for dashboards, Prometheus for metrics, Loki for logs, and Grafana Alloy as the collector agent.

## Stack

- `grafana`: dashboards and Explore UI on port `3000`.
- `prometheus`: persistent metrics storage on port `9090`.
- `loki`: persistent log storage on port `3100`.
- `collector`: Grafana Alloy agent for host metrics, systemd state, Docker metrics, journal logs, and Docker logs.

Prometheus, Loki, Grafana, and Alloy state are stored in external Docker volumes. External volumes survive container restarts and are not removed by `docker compose down -v`.

## Quick Start

1. Create a local environment file:

```bash
cp .env.example .env
```

2. Edit `.env` and set at least:

```bash
GRAFANA_ADMIN_PASSWORD=<strong-password>
COLLECTOR_BASIC_AUTH_PASSWORD=<strong-collector-password>
MONITOR_HOSTNAME=<central-server-name>
```

For a public domain, also set:

```bash
GRAFANA_ROOT_URL=https://monitor.example.com
GRAFANA_COOKIE_SECURE=true
PUBLIC_DOMAIN=monitor.example.com
```

3. Start the central stack:

```bash
scripts/monitoring.sh central up
```

The script creates the external Docker volumes, validates the Compose config, and starts the services.

4. Open Grafana:

```text
http://127.0.0.1:3000
```

For a public domain, put a TLS reverse proxy in front of Grafana and expose only the proxy. The default Grafana user is `admin` unless you change `GRAFANA_ADMIN_USER`.

## Public Domain Setup

Do not expose raw Grafana, Prometheus, Loki, or Alloy ports directly to the internet. The secure public shape is:

```text
https://monitor.example.com/                    -> Grafana login UI
https://monitor.example.com/prometheus/api/v1/write -> Basic Auth collector metrics ingest
https://monitor.example.com/loki/api/v1/push         -> Basic Auth collector log ingest
```

The direct-LXC installer writes an nginx reverse proxy for those paths. For Docker Compose, the service ports bind to `127.0.0.1` by default so you can put your own TLS reverse proxy in front.

## Add VM Collectors

Copy this repository, or at least `docker-compose.collector.yml`, `alloy/config.alloy`, and `scripts/monitoring.sh`, to each VM. Then run:

```bash
export PROMETHEUS_REMOTE_WRITE_URL=https://monitor.example.com/prometheus/api/v1/write
export LOKI_WRITE_URL=https://monitor.example.com/loki/api/v1/push
export COLLECTOR_BASIC_AUTH_USER=collector
export COLLECTOR_BASIC_AUTH_PASSWORD=<strong-collector-password>
export MONITOR_HOSTNAME=<vm-name>
export MONITOR_ROLE=vm
scripts/monitoring.sh collector up
```

The script creates the collector external volume, validates the collector Compose config, and starts Alloy. After one or two minutes, the VM should appear in the dashboard host selector.

## Useful Commands

```bash
scripts/monitoring.sh central status
scripts/monitoring.sh central logs
scripts/monitoring.sh central down
scripts/monitoring.sh collector status
```

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
scripts/monitoring.sh          Docker setup and lifecycle automation
scripts/lxc-install.sh         Direct LXC installer with nginx auth proxy
scripts/lxc-update.sh          Direct LXC update and config sync helper
docker-compose.yml             Central monitoring stack
docker-compose.collector.yml   Collector-only stack for each VM
```

## Docs

- [Architecture](docs/architecture.md)
- [VM Collector Rollout](docs/vm-collector.md)
- [Operations](docs/operations.md)
- [Security Notes](docs/security.md)
