#!/usr/bin/env bash
# Virtual tests - no root, no network changes. Run: bash tests/virtual-test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

ok() { echo "  OK: $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

echo "NetForge macOS virtual tests"
echo "Root: $ROOT"

for f in install.sh src/network-auto.sh src/install-network-auto.sh src/uninstall-network-auto.sh src/lib/common.sh src/netforge-status.sh src/clear-captive-portal.sh; do
  if bash -n "$ROOT/$f" 2>/dev/null; then ok "syntax $f"; else bad "syntax $f"; fi
done

for f in config/defaults.conf config/defaults.example.conf README.md SECURITY.md LICENSE VERSION; do
  [[ -f "$ROOT/$f" ]] && ok "exists $f" || bad "missing $f"
done

# shellcheck source=src/lib/common.sh
source "$ROOT/src/lib/common.sh"
netforge_load_config "$ROOT/config/defaults.conf"
[[ "$APP_NAME" == "NetForge" ]] && ok "APP_NAME" || bad "APP_NAME"
[[ "$DNS_SERVERS" == *"1.1.1.1"* ]] && ok "DNS_SERVERS" || bad "DNS_SERVERS"
[[ "${DISABLE_AWDL:-false}" == false ]] && ok "default DISABLE_AWDL=false" || bad "default DISABLE_AWDL=false"

[[ "$(service_type 'Wi-Fi')" == "wifi" ]] && ok "service_type Wi-Fi" || bad "service_type Wi-Fi"
[[ "$(service_type 'USB 10/100/1000 LAN')" == "ethernet" ]] && ok "service_type USB LAN" || bad "service_type USB LAN"
[[ "$(service_type 'Thunderbolt Bridge')" == "ethernet" ]] && ok "service_type Thunderbolt" || bad "service_type Thunderbolt"
[[ "$(service_type 'VPN')" == "vpn" ]] && ok "service_type VPN" || bad "service_type VPN"
[[ "$(service_type 'WireGuard')" == "vpn" ]] && ok "service_type WireGuard" || bad "service_type WireGuard"
[[ "$(service_type 'Tailscale')" == "vpn" ]] && ok "service_type Tailscale" || bad "service_type Tailscale"
[[ "$(service_type 'Cisco AnyConnect')" == "vpn" ]] && ok "service_type AnyConnect" || bad "service_type AnyConnect"

DISABLE_AWDL=false
netforge_should_disable_awdl true && bad "AWDL stays up when flag false" || ok "AWDL stays up when flag false"
DISABLE_AWDL=true
netforge_should_disable_awdl true && ok "AWDL down when flag true + eth" || bad "AWDL down when flag true + eth"
netforge_should_disable_awdl false && bad "AWDL stays up without eth" || ok "AWDL stays up without eth"
DISABLE_AWDL=false

tmp=$(mktemp -d)
sys="$tmp/system"
usr="$tmp/user"
mkdir -p "$sys" "$usr"
[[ "$(netforge_pick_data_dir "$sys" "$usr" 0)" == "$sys" ]] && ok "root uses system data dir" || bad "root uses system data dir"
[[ "$(netforge_pick_data_dir "$sys" "$usr" 1000)" == "$usr" ]] && ok "user uses user data dir when empty" || bad "user uses user data dir when empty"
printf '{}\n' >"$sys/last-run.json"
[[ "$(netforge_pick_data_dir "$sys" "$usr" 1000)" == "$sys" ]] && ok "user reads system last-run" || bad "user reads system last-run"
rm -rf "$tmp"

sample=$("$ROOT/src/netforge-status.sh" --sample)
[[ "$sample" == *netforge-sample-receipt* ]] && ok "sample kind" || bad "sample kind"
[[ "$sample" == *"No settings were changed"* ]] && ok "sample honesty" || bad "sample honesty"

grep -q 'skip VPN' "$ROOT/src/clear-captive-portal.sh" && ok "captive skips VPN" || bad "captive skips VPN"
grep -q 'netforge_should_disable_awdl' "$ROOT/src/network-auto.sh" && ok "apply honors DISABLE_AWDL" || bad "apply honors DISABLE_AWDL"
grep -q '\*\.sh' "$ROOT/src/install-network-auto.sh" && ok "install chmods all src scripts" || bad "install chmods all src scripts"
grep -q -- '--revert' "$ROOT/src/uninstall-network-auto.sh" && ok "uninstall --revert" || bad "uninstall --revert"

netforge_load_config "$ROOT/config/profiles/privacy-max.conf"
[[ "${DISABLE_AWDL:-false}" == true ]] && ok "privacy-max DISABLE_AWDL" || bad "privacy-max DISABLE_AWDL"

if grep -rEi 'knock|jonbailey|gmail|192\.168\.|password\s*=|api[_-]?key' \
  --include='*.sh' --include='*.conf' --include='*.md' "$ROOT" \
  --exclude-dir=tests --exclude-dir=.git 2>/dev/null; then
  bad "personal/secret pattern found"
else
  ok "no personal/secret patterns"
fi

grep -q 'Pitchfork-and-Torch/netforge' "$ROOT/install.sh" && ok "install.sh repo URL" || bad "install.sh repo URL"
grep -q 'com.netforge.network-auto' "$ROOT/src/install-network-auto.sh" && ok "LaunchDaemon label" || bad "LaunchDaemon label"
grep -q 'defaults.conf' "$ROOT/src/install-network-auto.sh" && ok "plist config path" || bad "plist config path"

if grep -q '<plist version="1.0">' "$ROOT/src/install-network-auto.sh"; then
  ok "plist template present"
else
  bad "plist template"
fi

grep -q 'order_svcs' "$ROOT/src/network-auto.sh" && ok "bash 3.2 service order fix" || bad "bash 3.2 service order fix"
grep -q 'apply_awdl' "$ROOT/src/network-auto.sh" && ok "apply_awdl wired" || bad "apply_awdl wired"
grep -q '\$TRIGGER" != "daemon"' "$ROOT/src/network-auto.sh" && ok "daemon skips systemsetup" || bad "daemon skips systemsetup"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" -eq 0 ]]
