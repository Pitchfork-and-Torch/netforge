# NetForge

**Cross-platform automatic network performance tuning and security hardening.**

Windows 10/11 · Linux (NetworkManager) · macOS 12+

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-informational)](VERSION)

Local-first. Zero telemetry. Prefer Ethernet, resilient DNS, TCP tuning, optional hardening.

**Suite landing:** [netforge.jonbailey.xyz](https://netforge.jonbailey.xyz)

## Repository layout

```
netforge/
  windows/   PowerShell NetworkAuto + scheduled tasks
  linux/     bash + NetworkManager / systemd-resolved
  macos/     bash + networksetup
```

This monorepo replaces the former split repos (`netforge-windows`, `netforge-linux`, `netforge-macos`).

## Quick install

### Windows (Admin PowerShell)

```powershell
git clone https://github.com/Pitchfork-and-Torch/netforge.git
cd netforge\windows
.\src\Get-NetForgeStatus.ps1
.\src\NetworkAuto.ps1 -DryRun
.\src\Install-NetworkAuto.ps1
```

Bootstrap (clones monorepo, installs Windows platform):

```powershell
irm https://raw.githubusercontent.com/Pitchfork-and-Torch/netforge/main/windows/install.ps1 | iex
```

### Linux (root)

```bash
git clone https://github.com/Pitchfork-and-Torch/netforge.git
cd netforge/linux
sudo ./src/install-network-auto.sh
./src/netforge-status.sh
```

### macOS (root)

```bash
git clone https://github.com/Pitchfork-and-Torch/netforge.git
cd netforge/macos
sudo ./src/install-network-auto.sh
./src/netforge-status.sh
```

## Shared design

- Discover adapters/services at runtime — no hard-coded NIC names
- Prefer Ethernet over Wi-Fi when both are up
- DNS toward resilient public resolvers (DoH on Windows; DoT/resolved on Linux; networksetup on macOS)
- Optional hardening behind config flags
- Triggers on boot/logon and network connect
- Lock + log so concurrent runs do not clobber each other

See [SUITE.md](SUITE.md) for platform edge cases and related tools.

## Related Pitchfork-and-Torch tools

| Tool | Role |
|------|------|
| [trench-coat](https://github.com/Pitchfork-and-Torch/trench-coat) | Multi-hop privacy cloak |
| [ghost-continuum](https://github.com/Pitchfork-and-Torch/ghost-continuum) | Defense / deception / forensics |

## License

MIT — see [LICENSE](LICENSE).

## Support

Bug reports via [GitHub Issues](https://github.com/Pitchfork-and-Torch/netforge/issues).
