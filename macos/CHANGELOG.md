# Changelog

## 2.1.1 - 2026-09-18

- Captive-portal recovery skips VPN services when `RESPECT_VPN=true`
- Captive recovery clears DNS to DHCP on non-VPN services (portal can inject its resolver)
- `DISABLE_AWDL=false` (default) keeps AWDL up; wired Ethernet no longer forces `awdl0` down
- Status as a non-root user reads `/var/log/netforge` last-run/log when present
- `uninstall-network-auto.sh --revert` restores DHCP DNS on non-VPN services

## 2.0.0 - 2026-07-24

- Captive portal probe / clear DNS / `--restore`
- Status `--json` / `--html` / last-run
- `RESPECT_VPN`, `--dry-run`
- Config profiles
- Landing: https://github.com/Pitchfork-and-Torch/netforge

## 1.0.3

Prior stable.
