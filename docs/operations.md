# Operations

## Start and Stop

```bash
docker compose up -d
docker compose ps
docker compose down
```

Use `docker compose down` to stop containers while keeping Docker volumes. Do not use `--volumes` unless you want to delete monitoring history.

## Logs

```bash
docker compose logs -f grafana
docker compose logs -f prometheus
docker compose logs -f loki
docker compose logs -f collector
```

## Health Checks

```bash
curl http://localhost:3000/api/health
curl http://localhost:9090/-/ready
curl http://localhost:3100/ready
curl http://localhost:12345/-/ready
```

The Alloy debug UI is bound to `127.0.0.1:12345` in the central stack.

## Query Smoke Tests

```bash
curl 'http://localhost:9090/api/v1/query' --data-urlencode 'query=node_uname_info'
curl 'http://localhost:9090/api/v1/query' --data-urlencode 'query=up{job="host-unix"}'
```

In Grafana Explore, use Loki queries like:

```logql
{source="journal"}
{source="docker"}
{host="main-server"} |~ "(?i)(error|failed|fatal|panic)"
```

## Retention

- Prometheus: set `PROMETHEUS_RETENTION` in `.env`, for example `30d` or `90d`.
- Loki: edit `limits_config.retention_period` in `loki/loki-config.yml`.

Restart the stack after retention config changes:

```bash
docker compose up -d
```
