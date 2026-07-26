# NetForge for Windows

**Automatic network performance tuning and security hardening for Windows 10/11.**

Part of the [NetForge monorepo](https://github.com/Pitchfork-and-Torch/netforge). See [../SUITE.md](../SUITE.md).

## Quick install (Admin PowerShell)

```powershell
git clone https://github.com/Pitchfork-and-Torch/netforge.git
cd netforge\windows
.\src\Get-NetForgeStatus.ps1
.\src\NetworkAuto.ps1 -DryRun
.\src\Install-NetworkAuto.ps1
```

Bootstrap:

```powershell
irm https://raw.githubusercontent.com/Pitchfork-and-Torch/netforge/main/windows/install.ps1 | iex
```

## Captive portals

```powershell
.\src\Clear-CaptivePortal.ps1 -ProbeOnly
.\src\Clear-CaptivePortal.ps1
.\src\Clear-CaptivePortal.ps1 -Restore
```

## License

MIT — see [../LICENSE](../LICENSE).
