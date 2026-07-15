# Architecture

This repository contains one central monitoring stack and one reusable collector stack.

## Central Stack

`docker-compose.yml` runs four services:

- Grafana reads Prometheus and Loki as provisioned data sources.
- Prometheus stores metrics in the external `monitoring-prometheus-data` Docker volume.
- Loki stores logs in the external `monitoring-loki-data` Docker volume.
- Alloy collects telemetry for the central server and sends it to Prometheus and Loki.

## Collector Flow

```text
Linux host / VM
  Alloy
    prometheus.exporter.unix      -> host metrics
    prometheus.exporter.cadvisor  -> Docker container metrics
    loki.source.journal           -> systemd journal logs
    loki.source.docker            -> Docker container logs
      |
      | metrics remote_write
      v
    Prometheus
      |
      | logs push
      v
    Loki
      |
      v
    Grafana dashboards
```

## Persistence

External Docker volumes keep state across restarts and survive `docker compose down -v`:

- `monitoring-grafana-data`: users, sessions, local Grafana state.
- `monitoring-prometheus-data`: Prometheus TSDB blocks and WAL.
- `monitoring-loki-data`: Loki chunks, indexes, rules, and compactor state.
- `monitoring-alloy-data`: Alloy WAL/positions for reliable forwarding.

The default Prometheus and Loki retention is 30 days. Prometheus retention is controlled by `PROMETHEUS_RETENTION`; Loki retention is set in `loki/loki-config.yml`.

## Remote Collectors

Remote Docker-based VMs run `docker-compose.collector.yml`. Debian/Ubuntu LXC collectors can install Alloy directly with `scripts/lxc-install.sh collector`. Each collector pushes metrics and logs to the central server, so the central server does not need to scrape every host directly.
