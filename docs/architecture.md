# Architecture

This repository contains one central monitoring stack and one reusable collector stack.

## Central Stack

`docker-compose.yml` runs four services:

- Grafana reads Prometheus and Loki as provisioned data sources.
- Prometheus stores metrics locally in the `prometheus-data` Docker volume.
- Loki stores logs locally in the `loki-data` Docker volume.
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

Docker volumes keep state across restarts:

- `grafana-data`: users, sessions, local Grafana state.
- `prometheus-data`: Prometheus TSDB blocks and WAL.
- `loki-data`: Loki chunks, indexes, rules, and compactor state.
- `alloy-data`: Alloy WAL/positions for reliable forwarding.

The default Prometheus and Loki retention is 30 days. Prometheus retention is controlled by `PROMETHEUS_RETENTION`; Loki retention is set in `loki/loki-config.yml`.

## Remote VMs

Each remote VM runs `docker-compose.collector.yml`. The VM collector pushes metrics and logs to the central server, so the central server does not need to scrape every VM directly.
