#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/scripts/lxc-install.sh"

PACKAGES=(grafana prometheus loki alloy nginx apache2-utils)
CONFIG_ONLY=0
NO_RESTART=0
SKIP_PACKAGE_UPGRADE=0

usage() {
  cat <<'USAGE'
Usage:
  scripts/lxc-update.sh [--config-only] [--skip-package-upgrade] [--no-restart]

Updates a direct LXC monitoring install created by scripts/lxc-install.sh.

What it does:
  - Upgrades Grafana, Prometheus, Loki, and Alloy packages unless skipped.
  - Re-syncs Grafana dashboards/provisioning from this repository.
  - Re-renders Prometheus, Loki, and Alloy configs for the LXC layout.
  - Restarts services unless --no-restart is used.

Options:
  --config-only           Do not upgrade packages; only sync config.
  --skip-package-upgrade  Same as --config-only for package handling.
  --no-restart           Write config but do not restart services.
USAGE
}

log() {
  printf '[lxc-update] %s\n' "$*"
}

fail() {
  printf '[lxc-update] ERROR: %s\n' "$*" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_root() {
  [[ "${EUID}" -eq 0 ]] || fail "Run this script as root inside the LXC."
  has_cmd apt-get || fail "apt-get is required. Use a Debian/Ubuntu LXC."
  has_cmd dpkg || fail "dpkg is required. Use a Debian/Ubuntu LXC."
  has_cmd systemctl || fail "systemctl is required. Use a systemd-based LXC."
  [[ -x "$INSTALL_SCRIPT" ]] || fail "Missing executable installer: $INSTALL_SCRIPT"
}

require_installed_packages() {
  local package
  for package in "${PACKAGES[@]}"; do
    dpkg -s "$package" >/dev/null 2>&1 || fail "$package is not installed. Run scripts/lxc-install.sh first."
  done
}

upgrade_packages() {
  export DEBIAN_FRONTEND=noninteractive

  require_installed_packages
  log "Upgrading monitoring packages."
  apt-get update
  apt-get install --only-upgrade -y "${PACKAGES[@]}"
}

sync_configs() {
  local args=(--config-only --no-start)

  log "Re-syncing LXC configs and dashboards from repository."
  "$INSTALL_SCRIPT" "${args[@]}"
}

restart_services() {
  if [[ "$NO_RESTART" -eq 1 ]]; then
    log "Services were not restarted because --no-restart was used."
    return
  fi

  log "Restarting monitoring services."
  systemctl restart prometheus loki grafana-server alloy nginx
}

main() {
  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --config-only) CONFIG_ONLY=1 ;;
      --skip-package-upgrade) SKIP_PACKAGE_UPGRADE=1 ;;
      --no-restart) NO_RESTART=1 ;;
      -h|--help) usage; exit 0 ;;
      *) usage; fail "Unknown option: $1" ;;
    esac
    shift
  done

  require_root
  cd "$ROOT_DIR"

  if [[ "$CONFIG_ONLY" -eq 0 && "$SKIP_PACKAGE_UPGRADE" -eq 0 ]]; then
    upgrade_packages
  fi

  sync_configs
  restart_services
  log "LXC monitoring stack update complete."
}

main "$@"
