# Changelog

## 2.1.0 - The Dry Run

- SAMPLE receipt: `windows/src/New-NetForgeSampleReceipt.ps1` writes a four-beat dry-run JSON. No system changes.
- Linux/macOS `netforge-status.sh --sample` prints the same honesty receipt.
- Version files lockstep at 2.1.0.

## 2.0.0 - monorepo

- Merged `netforge-windows`, `netforge-linux`, and `netforge-macos` into one repository (`Pitchfork-and-Torch/netforge`).
- Platform code lives under `windows/`, `linux/`, and `macos/`.
- Install bootstrap scripts clone the monorepo and target the platform subtree.

Platform-specific history prior to the merge lived in the former per-OS repositories.
