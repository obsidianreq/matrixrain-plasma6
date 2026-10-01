#!/usr/bin/env bash
set -euo pipefail

# Install (or upgrade) the wallpaper package from this checkout.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ID="obsidianreq.plasma.wallpaper.matrixrain"
PACKAGE_DIR="${SCRIPT_DIR}/${PACKAGE_ID}"
PACKAGE_TYPE="Plasma/Wallpaper"

if ! command -v kpackagetool6 >/dev/null 2>&1; then
    echo "Error: kpackagetool6 is not installed or not in PATH." >&2
    echo "Install the kpackage tools for your distro (kpackage / kf6-kpackage)." >&2
    exit 1
fi

if [[ ! -f "${PACKAGE_DIR}/metadata.json" ]]; then
    echo "Error: package directory not found at ${PACKAGE_DIR}" >&2
    exit 1
fi

if kpackagetool6 --type "${PACKAGE_TYPE}" --list 2>/dev/null | grep -qx "${PACKAGE_ID}"; then
    echo "Package already installed; upgrading..."
    kpackagetool6 --type "${PACKAGE_TYPE}" --upgrade "${PACKAGE_DIR}"
else
    echo "Installing wallpaper package..."
    kpackagetool6 --type "${PACKAGE_TYPE}" --install "${PACKAGE_DIR}"
fi

echo "Done. Restart plasmashell to pick up the change:"
echo "  kquitapp6 plasmashell && kstart plasmashell"
