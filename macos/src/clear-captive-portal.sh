#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
CONFIG_FILE="${REPO_ROOT}/config/defaults.conf"; RESTORE=false; PROBE_ONLY=false
while [[ $# -gt 0 ]]; do case "$1" in --restore) RESTORE=true; shift;; --probe-only) PROBE_ONLY=true; shift;; --config) CONFIG_FILE="$2"; shift 2;; *) shift;; esac; done
netforge_load_config "$CONFIG_FILE"
echo "NetForge captive-portal recovery (macOS)"
for u in http://captive.apple.com/hotspot-detect.html http://connectivitycheck.gstatic.com/generate_204; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 5 -L --max-redirs 0 "$u" 2>/dev/null || echo 000)
  echo "  [$code] $u"
done
if [[ "$RESTORE" == true ]]; then
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Need sudo" >&2; exit 1; }
  # Cancel a previously scheduled auto-restore.
  launchctl bootout system/com.netforge.captive-restore 2>/dev/null || true
  rm -f /Library/LaunchDaemons/com.netforge.captive-restore.plist 2>/dev/null || true
  rm -f /var/tmp/netforge-captive-restore.sh 2>/dev/null || true
  "$SCRIPT_DIR/network-auto.sh" --trigger captive-restore --config "$CONFIG_FILE"; exit 0
fi
[[ "$PROBE_ONLY" == true ]] && exit 0
[[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Need sudo" >&2; exit 1; }
while IFS= read -r svc; do
  [[ -z "$svc" || "$svc" == *"*"* ]] && continue
  stype=$(service_type "$svc")
  if [[ "$stype" == vpn && "${RESPECT_VPN:-true}" == true ]]; then
    echo "  skip VPN: $svc"
    continue
  fi
  networksetup -setdnsservers "$svc" Empty 2>/dev/null || true
  echo "  cleared DNS: $svc"
done < <(networksetup -listallnetworkservices 2>/dev/null | tail -n +2)
dscacheutil -flushcache 2>/dev/null || true
# Parity with Windows CaptiveAutoRestoreSeconds / Linux timer.
secs="${CAPTIVE_AUTO_RESTORE_SECONDS:-900}"
if [[ "$secs" =~ ^[0-9]+$ && "$secs" -gt 0 ]]; then
  restore_cmd="$(printf '%q' "$SCRIPT_DIR/clear-captive-portal.sh") --restore --config $(printf '%q' "$CONFIG_FILE")"
  cat >/var/tmp/netforge-captive-restore.sh <<EOS
#!/bin/bash
sleep ${secs}
${restore_cmd}
EOS
  chmod 700 /var/tmp/netforge-captive-restore.sh
  nohup /var/tmp/netforge-captive-restore.sh >/dev/null 2>&1 &
  echo "Auto-restore scheduled in ${secs}s."
fi
echo "After login: sudo $0 --restore"