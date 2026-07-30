# Security

## Scope

NetForge runs with elevated privileges to change host network settings. Treat install and config changes as high trust.

## Reporting

Please open a private security advisory or GitHub Issue on [Pitchfork-and-Torch/netforge](https://github.com/Pitchfork-and-Torch/netforge) for vulnerabilities. Do not include secrets in public issues.

## Hardening notes

- Review config profiles under each platform `config/` before enabling privacy-max or corporate profiles  
- Captive-portal helpers temporarily relax DNS privacy — restore after login  
- Uninstall scripts are provided per platform  

## Supported versions

Current `VERSION` on `main` is the supported release line.
