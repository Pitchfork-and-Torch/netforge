#!/usr/bin/env bash
set -euo pipefail

# Pick system data dir when root, or when a previous root apply left readable state.
# netforge_pick_data_dir SYSTEM_DIR USER_DIR [EUID]
netforge_pick_data_dir() {
  local system_dir="$1"
  local user_dir="$2"
  local euid="${3:-${EUID:-$(id -u)}}"
  if [[ "$euid" -eq 0 ]]; then
    printf '%s\n' "$system_dir"
    return 0
  fi
  if [[ -r "${system_dir}/last-run.json" || -r "${system_dir}/network-auto.log" ]]; then
    printf '%s\n' "$system_dir"
    return 0
  fi
  printf '%s\n' "$user_dir"
}

netforge_classify_nm_type() {
  case "${1:-}" in
    802-3-ethernet|ethernet) echo ethernet ;;
    802-11-wireless|wifi) echo wifi ;;
    vpn|wireguard|wg-quick|wg|tun|tap|pptp|l2tp|ipsec|openvpn) echo vpn ;;
    *) echo other ;;
  esac
}

netforge_is_vpn_type() {
  [[ "$(netforge_classify_nm_type "${1:-}")" == vpn ]]
}

pick_cc() {
  if [[ -r /proc/sys/net/ipv4/tcp_available_congestion_control ]] \
    && grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
    echo bbr
  else
    echo cubic
  fi
}

netforge_load_config() {
  local config_file="${1:-}"
  APP_NAME="NetForge"; DNS_SERVERS="1.1.1.1 1.0.0.1 8.8.8.8"; DNS_OVER_TLS="yes"
  ETHERNET_METRIC=100; WIFI_METRIC_ALONE=600; WIFI_METRIC_WITH_ETH=700
  LOCK_SECONDS=90; MAX_LOG_LINES=2000; DISABLE_SSHD=true; DISABLE_FILE_SHARE=true
  DISABLE_LLMNR=true; DISABLE_MDNS=false; HIGH_PERFORMANCE_POWER=true
  RESPECT_VPN=true; CAPTIVE_PORTAL_DNS="1.1.1.1 8.8.8.8"; CAPTIVE_AUTO_RESTORE_SECONDS=900
  if [[ -n "$config_file" && -f "$config_file" ]]; then source "$config_file"; fi
  local user_dir="${XDG_DATA_HOME:-$HOME/.local/share}/${APP_NAME}"
  DATA_DIR="$(netforge_pick_data_dir /var/lib/netforge "$user_dir")"
  LOG_FILE="${DATA_DIR}/network-auto.log"; LOCK_FILE="${DATA_DIR}/network-auto.lock"; LAST_RUN_FILE="${DATA_DIR}/last-run.json"
}

netforge_log() { mkdir -p "$(dirname "$LOG_FILE")"; printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >>"$LOG_FILE"; }
netforge_rotate_log() {
  [[ -f "$LOG_FILE" ]] || return 0
  local count; count=$(wc -l <"$LOG_FILE" | tr -d ' ')
  (( count > MAX_LOG_LINES )) && { tail -n "$MAX_LOG_LINES" "$LOG_FILE" >"${LOG_FILE}.tmp"; mv "${LOG_FILE}.tmp" "$LOG_FILE"; }
}
netforge_acquire_lock() {
  if [[ -f "$LOCK_FILE" ]]; then
    local now mtime age; now=$(date +%s); mtime=$(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE"); age=$((now-mtime))
    (( age < LOCK_SECONDS )) && exit 0
  fi
  mkdir -p "$(dirname "$LOCK_FILE")"; : >"$LOCK_FILE"
}
netforge_release_lock() { rm -f "$LOCK_FILE"; }
netforge_require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then echo "Need root (or --dry-run): sudo $0 $*" >&2; exit 1; fi
}
netforge_write_last_run() {
  local trigger="${1:-manual}" ver="unknown"
  mkdir -p "$(dirname "$LAST_RUN_FILE")"
  [[ -n "${REPO_ROOT:-}" && -f "$REPO_ROOT/VERSION" ]] && ver=$(tr -d '\r\n' <"$REPO_ROOT/VERSION")
  printf '{"timestamp":"%s","trigger":"%s","version":"%s"}\n' "$(date -Iseconds 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" "$trigger" "$ver" >"$LAST_RUN_FILE"
}
