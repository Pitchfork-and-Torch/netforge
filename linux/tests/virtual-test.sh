#!/usr/bin/env bash
# Virtual tests - no root, no network changes. Run: bash tests/virtual-test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

ok() { echo "  OK: $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "NetForge Linux virtual tests"
echo "Root: $ROOT"
chmod +x "$ROOT"/install.sh "$ROOT"/src/*.sh "$ROOT"/src/lib/*.sh "$ROOT"/tests/*.sh 2>/dev/null || true

# --- syntax ---
for f in install.sh src/network-auto.sh src/install-network-auto.sh src/uninstall-network-auto.sh src/lib/common.sh src/netforge-status.sh src/clear-captive-portal.sh; do
  if bash -n "$ROOT/$f" 2>/dev/null; then ok "syntax $f"; else bad "syntax $f"; fi
done

# --- required files ---
for f in config/defaults.conf config/defaults.example.conf README.md SECURITY.md LICENSE VERSION; do
  [[ -f "$ROOT/$f" ]] && ok "exists $f" || bad "missing $f"
done

# --- config load ---
# shellcheck source=src/lib/common.sh
source "$ROOT/src/lib/common.sh"
netforge_load_config "$ROOT/config/defaults.conf"
[[ "$APP_NAME" == "NetForge" ]] && ok "APP_NAME" || bad "APP_NAME"
[[ "$DNS_SERVERS" == *"1.1.1.1"* ]] && ok "DNS_SERVERS" || bad "DNS_SERVERS"
[[ "$ETHERNET_METRIC" -lt "$WIFI_METRIC_ALONE" ]] && ok "metrics order" || bad "metrics order"
[[ "$RESPECT_VPN" == true ]] && ok "RESPECT_VPN" || bad "RESPECT_VPN"

# --- congestion control helper ---
cc=$(pick_cc)
[[ "$cc" == "bbr" || "$cc" == "cubic" ]] && ok "pick_cc=$cc" || bad "pick_cc"

# --- NM type classification (production helper) ---
[[ "$(netforge_classify_nm_type 802-11-wireless)" == "wifi" ]] && ok "nm wifi type" || bad "nm wifi type"
[[ "$(netforge_classify_nm_type 802-3-ethernet)" == "ethernet" ]] && ok "nm eth type" || bad "nm eth type"
[[ "$(netforge_classify_nm_type wireguard)" == "vpn" ]] && ok "nm wireguard vpn" || bad "nm wireguard vpn"
[[ "$(netforge_classify_nm_type vpn)" == "vpn" ]] && ok "nm vpn type" || bad "nm vpn type"
netforge_is_vpn_type tun && ok "tun is vpn" || bad "tun is vpn"
netforge_is_vpn_type ethernet && bad "ethernet is not vpn" || ok "ethernet is not vpn"

# --- data dir: root vs user vs leftover system state ---
tmp=$(mktemp -d)
sys="$tmp/system"
usr="$tmp/user"
mkdir -p "$sys" "$usr"
[[ "$(netforge_pick_data_dir "$sys" "$usr" 0)" == "$sys" ]] && ok "root uses system data dir" || bad "root uses system data dir"
[[ "$(netforge_pick_data_dir "$sys" "$usr" 1000)" == "$usr" ]] && ok "user uses user data dir when empty" || bad "user uses user data dir when empty"
printf '{}\n' >"$sys/last-run.json"
[[ "$(netforge_pick_data_dir "$sys" "$usr" 1000)" == "$sys" ]] && ok "user reads system last-run" || bad "user reads system last-run"
rm -rf "$tmp"

# --- profiles ---
netforge_load_config "$ROOT/config/profiles/corporate.conf"
[[ "$DISABLE_SSHD" == false ]] && ok "corporate keeps sshd" || bad "corporate keeps sshd"
[[ "$ETHERNET_METRIC" -lt "$WIFI_METRIC_ALONE" ]] && ok "corporate metrics" || bad "corporate metrics"
netforge_load_config "$ROOT/config/profiles/privacy-max.conf"
[[ "$DISABLE_MDNS" == true ]] && ok "privacy-max disables mdns" || bad "privacy-max disables mdns"
netforge_load_config "$ROOT/config/defaults.conf"

# --- sample receipt (no probes) ---
sample=$(bash "$ROOT/src/netforge-status.sh" --sample)
[[ "$sample" == *netforge-sample-receipt* ]] && ok "sample kind" || bad "sample kind"
[[ "$sample" == *'"sample":true'* || "$sample" == *'"sample": true'* ]] && ok "sample flag" || bad "sample flag"
[[ "$sample" == *"No settings were changed"* ]] && ok "sample honesty" || bad "sample honesty"

json=$(bash "$ROOT/src/netforge-status.sh" --json --skip-dns-probe)
[[ "$json" == *'"tool":"NetForge"'* ]] && ok "status json tool" || bad "status json tool"

# --- captive / install / uninstall product holes ---
grep -q 'netforge_classify_nm_type' "$ROOT/src/clear-captive-portal.sh" && ok "captive classifies NM type" || bad "captive classifies NM type"
grep -q 'skip VPN' "$ROOT/src/clear-captive-portal.sh" && ok "captive skips VPN" || bad "captive skips VPN"
if grep -q '/root/.local/share' "$ROOT/src/install-network-auto.sh"; then
  bad "install DATA_DIR override"
else
  ok "install does not override DATA_DIR"
fi
grep -q '\*\.sh' "$ROOT/src/install-network-auto.sh" && ok "install chmods all src scripts" || bad "install chmods all src scripts"
grep -q -- '--revert' "$ROOT/src/uninstall-network-auto.sh" && ok "uninstall --revert" || bad "uninstall --revert"
grep -q 'LOG_FILE' "$ROOT/src/install-network-auto.sh" && ok "install logs to LOG_FILE" || bad "install logs to LOG_FILE"
grep -q '/var/lib/netforge' "$ROOT/src/lib/common.sh" && ok "system data dir /var/lib/netforge" || bad "system data dir /var/lib/netforge"
grep -q 'CAPTIVE_PORTAL_DNS' "$ROOT/src/clear-captive-portal.sh" && ok "captive uses CAPTIVE_PORTAL_DNS" || bad "captive uses CAPTIVE_PORTAL_DNS"
grep -q 'DNSOverTLS=no' "$ROOT/src/clear-captive-portal.sh" && ok "captive disables DoT" || bad "captive disables DoT"

# --- no personal data in repo ---
if grep -rEi 'knock|jonbailey|gmail|192\.168\.|password\s*=|api[_-]?key' \
  --include='*.sh' --include='*.conf' --include='*.md' "$ROOT" \
  --exclude-dir=tests --exclude-dir=.git 2>/dev/null; then
  bad "personal/secret pattern found"
else
  ok "no personal/secret patterns"
fi

# --- install paths ---
grep -q 'Pitchfork-and-Torch/netforge' "$ROOT/install.sh" && ok "install.sh repo URL" || bad "install.sh repo URL"
grep -q 'netforge-network-auto' "$ROOT/src/install-network-auto.sh" && ok "systemd unit name" || bad "systemd unit"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
