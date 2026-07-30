#!/usr/bin/env bash
# Bootstrap installer — clone NetForge monorepo and run linux platform installer
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Pitchfork-and-Torch/netforge.git}"
CLONE_DIR="${CLONE_DIR:-/opt/netforge-src}"
BRANCH="${BRANCH:-main}"
PLATFORM="linux"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "NetForge requires root. Run: sudo $0" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Git is required. Install git and re-run." >&2
  exit 1
fi

mkdir -p "$(dirname "$CLONE_DIR")"
if [[ -d "$CLONE_DIR/.git" ]]; then
  echo "Updating $CLONE_DIR ..."
  if ! git -C "$CLONE_DIR" fetch --depth 1 origin "$BRANCH"; then
    echo "WARN: fetch failed (offline?). Using existing tree." >&2
  else
    if ! git -C "$CLONE_DIR" pull --ff-only origin "$BRANCH"; then
      echo "WARN: fast-forward pull failed (local edits?). Re-cloning clean copy." >&2
      rm -rf "$CLONE_DIR"
      git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$CLONE_DIR"
    fi
  fi
else
  rm -rf "$CLONE_DIR"
  echo "Cloning $REPO_URL (branch $BRANCH) ..."
  git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$CLONE_DIR"
fi

PLATFORM_ROOT="$CLONE_DIR/$PLATFORM"
INSTALLER="$PLATFORM_ROOT/src/install-network-auto.sh"
if [[ ! -f "$INSTALLER" ]]; then
  echo "Installer missing after clone: $INSTALLER" >&2
  exit 1
fi
chmod +x "$INSTALLER" \
  "$PLATFORM_ROOT/src/netforge-status.sh" \
  "$PLATFORM_ROOT/src/network-auto.sh" \
  "$PLATFORM_ROOT/src/uninstall-network-auto.sh" \
  "$PLATFORM_ROOT/src/lib/common.sh" 2>/dev/null || true

exec "$INSTALLER"
