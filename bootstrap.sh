#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Install - Bootstrap
# ==============================================================================
# One-liner to clone and run the install script from a fresh Arch system.
# The install script will prompt for all configuration interactively.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/probird5/arch-install/main/bootstrap.sh)
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

REPO_URL="https://github.com/probird5/arch-install.git"
INSTALL_DIR="/tmp/arch-install"

echo -e "${CYAN}=== Arch Linux Install Bootstrap ===${NC}"

# Must be root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root (sudo)."
    exit 1
fi

# Ensure git is available
if ! command -v git &>/dev/null; then
    echo -e "${GREEN}[+]${NC} Installing git..."
    pacman -Sy --noconfirm git
fi

# Clone or update the repo
if [[ -d "$INSTALL_DIR" ]]; then
    echo -e "${GREEN}[+]${NC} Repo already exists, pulling latest..."
    git -C "$INSTALL_DIR" pull --ff-only || {
        echo -e "${RED}[!]${NC} Pull failed, re-cloning..."
        rm -rf "$INSTALL_DIR"
        git clone "$REPO_URL" "$INSTALL_DIR"
    }
else
    echo -e "${GREEN}[+]${NC} Cloning arch-install repo..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR"/*.sh

echo -e "${GREEN}[+]${NC} Repository ready at ${CYAN}${INSTALL_DIR}${NC}"
echo -e "${GREEN}[+]${NC} Launching installer..."
echo ""

exec "$INSTALL_DIR/install.sh"
