# Contributing

Thanks for improving NetForge.

## Layout

- `windows/` — PowerShell (Windows 10/11)
- `linux/` — bash + NetworkManager
- `macos/` — bash + networksetup

Keep changes platform-scoped when possible. Shared design notes live in `SUITE.md`.

## Rules

1. **No telemetry**, no cloud accounts, no hard-coded secrets  
2. Prefer **idempotent** scripts and config-driven defaults  
3. Document new flags in the platform README and `docs/`  
4. Run linters: PSScriptAnalyzer (Windows), ShellCheck (Linux/macOS)  
5. Do not commit machine-specific paths or personal contact info  

## Pull requests

Open PRs against `main` on [Pitchfork-and-Torch/netforge](https://github.com/Pitchfork-and-Torch/netforge).
