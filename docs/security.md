# Security Notes

This stack is designed for a trusted LAN or lab network. Do not expose it directly to the public internet.

## Required Hardening

- Set a strong `GRAFANA_ADMIN_PASSWORD` in `.env` before starting the stack.
- Restrict access to ports `3000`, `9090`, and `3100` with a firewall or reverse proxy ACLs.
- Keep `12345` local-only; the central compose maps Alloy debug UI to `127.0.0.1` and the VM collector compose does not publish it.
- Run collectors only on machines you control.

## Privileged Collector

Alloy runs with privileged host access so it can collect accurate host, Docker, cgroup, disk, and journal telemetry. That means the collector has sensitive host visibility.

Reduce risk by:

- Running it only on trusted hosts.
- Keeping Docker and host OS packages updated.
- Avoiding public exposure of the Docker socket or Alloy debug UI.
- Limiting who can edit `alloy/config.alloy` and compose files.

## Remote Collector Traffic

Remote VM collectors push metrics to Prometheus on `9090` and logs to Loki on `3100`. If your network is not trusted, put the central stack behind TLS and authentication using a reverse proxy before adding remote collectors.
