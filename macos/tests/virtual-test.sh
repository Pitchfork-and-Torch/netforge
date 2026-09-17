#!/usr/bin/env bash
# Virtual tests - no root, no network changes. Run: bash tests/virtual-test.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

ok() { echo "  OK: $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL: $1"; bad_msg="$1"; FAIL=$((FAIL + 1)); }

echo "NetForge macOS virtual tests"
echo "Root: $ROOT"

for f in install.sh src/network-auto.sh src/install-network-auto.sh src/uninstall-network-auto.sh src/lib/common.sh; do
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

# log rotation must not abort an errexit caller (regression)
tmp_log_dir="$(mktemp -d)"
printf 'a\nb\nc\n' >"$tmp_log_dir/short.log"
# Separate process: bash ignores set -e inside an if/&&/|| context, so a subshell here would not reproduce the caller.
rotate_out="$(bash -c 'set -euo pipefail; source "$1"; LOG_FILE="$2"; MAX_LOG_LINES=2000; netforge_rotate_log; echo reached' \
  _ "$ROOT/src/lib/common.sh" "$tmp_log_dir/short.log" 2>/dev/null || true)"
[[ "$rotate_out" == "reached" ]] && ok "rotate_log short log returns 0" || bad "rotate_log short log aborts errexit caller"
seq 1 10 >"$tmp_log_dir/long.log"
(LOG_FILE="$tmp_log_dir/long.log"; MAX_LOG_LINES=4; netforge_rotate_log)
[[ "$(wc -l <"$tmp_log_dir/long.log" | tr -d ' ')" == "4" && "$(tail -n 1 "$tmp_log_dir/long.log")" == "10" ]] \
  && ok "rotate_log trims long log" || bad "rotate_log trims long log"
rm -rf "$tmp_log_dir"

# service_type (copy from network-auto.sh)
service_type() {
  local svc="$1"
  if [[ "$svc" =~ [Ww][Ii][-[:space:]]?[Ff][Ii] ]]; then echo wifi
  elif [[ "$svc" =~ [Ee]thernet|[Tt]hunderbolt|[Dd]ock|[Uu][Ss][Bb] ]]; then echo ethernet
  else echo other
  fi
}
[[ "$(service_type 'Wi-Fi')" == "wifi" ]] && ok "service_type Wi-Fi" || bad "service_type Wi-Fi"
[[ "$(service_type 'USB 10/100/1000 LAN')" == "ethernet" ]] && ok "service_type USB LAN" || bad "service_type USB LAN"
[[ "$(service_type 'Thunderbolt Bridge')" == "ethernet" ]] && ok "service_type Thunderbolt" || bad "service_type Thunderbolt"
[[ "$(service_type 'VPN')" == "other" ]] && ok "service_type VPN" || bad "service_type VPN"

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

# LaunchDaemon plist well-formed XML
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
