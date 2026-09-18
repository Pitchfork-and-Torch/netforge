#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
CONFIG_FILE="${REPO_ROOT}/config/defaults.conf"; RESTORE=false; PROBE_ONLY=false
while [[ $# -gt 0 ]]; do case "$1" in --restore) RESTORE=true; shift;; --probe-only) PROBE_ONLY=true; shift;; --config) CONFIG_FILE="$2"; shift 2;; *) shift;; esac; done
netforge_load_config "$CONFIG_FILE"
# systemd-resolved applies drop-ins in lexicographic order; later wins on the same key.
# netforge.conf (from apply) sorts after netforge-captive.conf, so a captive DoT=no
# file with that older name was ignored while apply's DNSOverTLS=yes stayed active.
CAPTIVE_DROPIN="/etc/systemd/resolved.conf.d/zz-netforge-captive.conf"
LEGACY_CAPTIVE_DROPIN="/etc/systemd/resolved.conf.d/netforge-captive.conf"
echo "NetForge captive-portal recovery"
for u in http://captive.apple.com/hotspot-detect.html http://connectivitycheck.gstatic.com/generate_204 http://www.msftconnecttest.com/connecttest.txt; do
  code=$(curl -sS -o /dev/null -w "%{http_code}" --max-time 5 -L --max-redirs 0 "$u" 2>/dev/null || echo 000)
  echo "  [$code] $u"
done
if [[ "$RESTORE" == true ]]; then
  [[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Need sudo --restore" >&2; exit 1; }
  rm -f "$CAPTIVE_DROPIN" "$LEGACY_CAPTIVE_DROPIN"
  "$SCRIPT_DIR/network-auto.sh" --trigger captive-restore --config "$CONFIG_FILE"; exit 0
fi
[[ "$PROBE_ONLY" == true ]] && { echo "Probe-only"; exit 0; }
[[ "${EUID:-$(id -u)}" -eq 0 ]] || { echo "Need sudo (or --probe-only)" >&2; exit 1; }
if command -v nmcli >/dev/null 2>&1; then
  while IFS= read -r CON; do
    [[ -z "$CON" ]] && continue
    kind=$(netforge_classify_nm_type "$(nmcli -g connection.type connection show "$CON" 2>/dev/null || true)")
    if [[ "$kind" == vpn && "${RESPECT_VPN:-true}" == true ]]; then
      echo "  skip VPN: $CON"
      continue
    fi
    nmcli connection modify "$CON" ipv4.dns "" ipv4.ignore-auto-dns no 2>/dev/null || true
    nmcli connection modify "$CON" ipv4.dns-over-tls no 2>/dev/null || true
    nmcli connection up "$CON" 2>/dev/null || true
    echo "  relaxed: $CON"
  done < <(nmcli -g NAME connection show --active 2>/dev/null)
fi
if command -v resolvectl >/dev/null 2>&1; then
  mkdir -p /etc/systemd/resolved.conf.d
  # zz- prefix sorts after netforge.conf so DNSOverTLS=no wins over apply's yes.
  printf '[Resolve]\nDNSOverTLS=no\nDNS=%s\n' "${CAPTIVE_PORTAL_DNS:-1.1.1.1 8.8.8.8}" >"$CAPTIVE_DROPIN"
  rm -f "$LEGACY_CAPTIVE_DROPIN"
  systemctl restart systemd-resolved 2>/dev/null || true
fi
echo "After portal login: sudo $0 --restore"
