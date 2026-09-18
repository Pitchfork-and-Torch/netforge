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
netforge_require_root

launchctl bootout system/com.netforge.network-auto 2>/dev/null || true
launchctl unload /Library/LaunchDaemons/com.netforge.network-auto.plist 2>/dev/null || true
rm -f /Library/LaunchDaemons/com.netforge.network-auto.plist

echo "${APP_NAME} LaunchDaemon removed."

if [[ "$REVERT" == true ]]; then
  if command -v networksetup >/dev/null 2>&1; then
    while IFS= read -r svc; do
      [[ -z "$svc" || "$svc" == *"*"* ]] && continue
      stype=$(service_type "$svc")
      if [[ "$stype" == vpn && "${RESPECT_VPN:-true}" == true ]]; then
        echo "  skip VPN: $svc"
        continue
      fi
      networksetup -setdnsservers "$svc" Empty 2>/dev/null || true
      echo "  DNS DHCP: $svc"
    done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)
  fi
  echo "Best-effort revert finished (DNS). Files in ${INSTALL_DIR:-/opt/netforge} kept."
else
  echo "Files in ${INSTALL_DIR:-/opt/netforge} and DNS/service settings were not reverted."
  echo "Use --revert to restore DHCP DNS on non-VPN services."
fi