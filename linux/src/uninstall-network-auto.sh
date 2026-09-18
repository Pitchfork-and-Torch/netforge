#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$REPO_ROOT/config/defaults.conf"

# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
REVERT=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --revert) REVERT=true; shift ;;
    -h|--help) echo "Usage: $0 [--revert]"; exit 0 ;;
    *) shift ;;
  esac
done
netforge_load_config "$CONFIG_FILE"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

systemctl disable --now netforge-network-auto.service 2>/dev/null || true
rm -f /etc/systemd/system/netforge-network-auto.service
rm -f /etc/NetworkManager/dispatcher.d/99-netforge
systemctl daemon-reload

echo "${APP_NAME} systemd service and NM dispatcher removed."

if [[ "$REVERT" == true ]]; then
  rm -f /etc/sysctl.d/99-netforge.conf
  rm -f /etc/systemd/resolved.conf.d/netforge.conf /etc/systemd/resolved.conf.d/netforge-captive.conf /etc/systemd/resolved.conf.d/zz-netforge-captive.conf
  sysctl --system >/dev/null 2>&1 || true
  systemctl restart systemd-resolved 2>/dev/null || true
  if command -v nmcli >/dev/null 2>&1; then
    while IFS= read -r CON; do
      [[ -z "$CON" ]] && continue
      kind=$(netforge_classify_nm_type "$(nmcli -g connection.type connection show "$CON" 2>/dev/null || true)")
      if [[ "$kind" == vpn && "${RESPECT_VPN:-true}" == true ]]; then
        echo "  skip VPN DNS revert: $CON"
        continue
      fi
      nmcli connection modify "$CON" ipv4.dns "" ipv4.ignore-auto-dns no 2>/dev/null || true
      echo "  DNS DHCP: $CON"
    done < <(nmcli -g NAME connection show 2>/dev/null)
  fi
  echo "Best-effort revert finished (sysctl, resolved, NM DNS). Reboot recommended."
else
  echo "Files in ${INSTALL_DIR:-/opt/netforge}, sysctl, resolved, and NM settings were not reverted."
  echo "Use --revert to drop sysctl/resolved drop-ins and restore NM DHCP DNS. Or remove them manually."
fi