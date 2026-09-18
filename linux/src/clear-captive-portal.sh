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
  # Cancel a previously scheduled auto-restore (Windows parity).
  if command -v systemd-run >/dev/null 2>&1; then
    systemctl stop netforge-captive-restore.service 2>/dev/null || true
    systemctl reset-failed netforge-captive-restore.service 2>/dev/null || true
  fi
  rm -f /run/netforge-captive-restore.sh 2>/dev/null || true
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
# Windows schedules CaptiveAutoRestoreSeconds via schtasks; Linux listed the
# knob in every profile but never armed a timer, so hotel Wi-Fi stayed on
# plaintext DNS until a manual --restore.
secs="${CAPTIVE_AUTO_RESTORE_SECONDS:-900}"
if [[ "$secs" =~ ^[0-9]+$ && "$secs" -gt 0 ]]; then
  restore_cmd="$(printf '%q' "$SCRIPT_DIR/clear-captive-portal.sh") --restore --config $(printf '%q' "$CONFIG_FILE")"
  if command -v systemd-run >/dev/null 2>&1; then
    systemctl stop netforge-captive-restore.service 2>/dev/null || true
    systemd-run --unit=netforge-captive-restore --on-active="${secs}s" --timer-property=AccuracySec=1s       /bin/bash -c "$restore_cmd" >/dev/null 2>&1 \
      && echo "Auto-restore scheduled in ${secs}s (netforge-captive-restore)." \
      || echo "Auto-restore timer unavailable; run: sudo $0 --restore"
  else
    # Fallback when systemd-run is missing (containers / minimal images).
    cat >/run/netforge-captive-restore.sh <<EOS
#!/bin/bash
sleep ${secs}
${restore_cmd}
EOS
    chmod 700 /run/netforge-captive-restore.sh
    nohup /run/netforge-captive-restore.sh >/dev/null 2>&1 &
    echo "Auto-restore scheduled in ${secs}s (background sleep)."
  fi
fi
echo "After portal login: sudo $0 --restore"
