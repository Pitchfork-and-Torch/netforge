# Changelog

## 2.1.1

- RespectVpn now applies to captive-portal recovery (Windows / Linux / macOS). Relaxing DNS no longer clobbers a live VPN.
- Captive recovery uses configured captive DNS (plaintext) and turns DoT/DoH fallback off so hotel/portal login can complete.
- Linux installer logs to `/var/lib/netforge` (same dir as apply). It no longer claims `/root/.local/share/NetForge`.
- Status as a normal user reads the system last-run/log when those files exist.
- macOS `DISABLE_AWDL=false` (the default) keeps AWDL up. Wired Ethernet no longer forces `awdl0` down.
- Unix uninstall `--revert` best-effort DNS/sysctl restore. VPN connections stay skipped when RespectVpn is on.
- Shared Windows adapter classifier so status and apply agree (NordLynx, Fortinet, ZeroTier, Outline).
- Version files lockstep at 2.1.1.

## 2.1.0 - The Dry Run

- SAMPLE receipt: `windows/src/New-NetForgeSampleReceipt.ps1` writes a four-beat dry-run JSON. No system changes.
- Linux/macOS `netforge-status.sh --sample` prints the same honesty receipt.
- Version files lockstep at 2.1.0.

## 2.0.0 - monorepo

- Merged `netforge-windows`, `netforge-linux`, and `netforge-macos` into one repository (`Pitchfork-and-Torch/netforge`).
- Platform code lives under `windows/`, `linux/`, and `macos/`.
- Install bootstrap scripts clone the monorepo and target the platform subtree.

Platform-specific history prior to the merge lived in the former per-OS repositories.
