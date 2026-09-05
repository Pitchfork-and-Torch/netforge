# NetForge for Linux

**Automatic network performance tuning and security hardening for Linux (NetworkManager + systemd-resolved).**

Part of the [NetForge monorepo](https://github.com/Pitchfork-and-Torch/netforge). See [../SUITE.md](../SUITE.md).

## Quick install

```bash
git clone https://github.com/Pitchfork-and-Torch/netforge.git
cd netforge/linux
./src/netforge-status.sh
sudo ./src/install-network-auto.sh
```

Bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/Pitchfork-and-Torch/netforge/main/linux/install.sh | sudo bash
```

## License

MIT â€” see [../LICENSE](../LICENSE).

<!-- CI: LICENSE gate covered by virtual-test.sh -->
