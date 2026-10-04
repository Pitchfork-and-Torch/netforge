# Changelog

## 2.1.2 - 2026-10-01

- `netforge-status.sh --sample` names the captive plan (skip VPN, captive DNS, then restore) and does not say fail closed.

## 2.1.1 - 2026-09-18

- Captive-portal recovery skips VPN connections when `RESPECT_VPN=true`
- Captive recovery writes plaintext `CAPTIVE_PORTAL_DNS` to systemd-resolved (DoT off)
- Installer logs to `/var/lib/netforge` (same as apply), not `/root/.local/share/NetForge`
- Status as a non-root user reads the system last-run/log when present
- `uninstall-network-auto.sh --revert` drops sysctl/resolved drop-ins and restores NM DHCP DNS (VPN skipped)

## 2.0.0 - 2026-07-24

- Captive portal probe / relax / `--restore`
- Status `--json` / `--html` / last-run
- `RESPECT_VPN`, `--dry-run`
- Config profiles
- Landing: https://github.com/Pitchfork-and-Torch/netforge

## 1.0.2

Prior stable.
