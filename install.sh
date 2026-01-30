#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Post-Install Setup - Root Phase
# ==============================================================================
# Run this as root on a freshly installed base Arch system.
# Assumes: base system installed, btrfs, booted into the system, internet up.
#
# Usage:
#   sudo ./install.sh
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }
info() { echo -e "${CYAN}[*]${NC} $*"; }
section() { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}\n"; }

# ==============================================================================
# Pre-flight checks
# ==============================================================================
preflight() {
    section "Pre-flight Checks"

    if [[ $EUID -ne 0 ]]; then
        err "This script must be run as root."
        exit 1
    fi

    if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
        err "No internet connection."
        exit 1
    fi

    log "Root: OK | Internet: OK"
}

# ==============================================================================
# Enable multilib + parallel downloads
# ==============================================================================
configure_pacman() {
    section "Configuring pacman"

    # Enable ParallelDownloads
    if grep -q "^#ParallelDownloads" /etc/pacman.conf; then
        sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
        log "Enabled parallel downloads (10)"
    fi

    # Enable Color
    if grep -q "^#Color" /etc/pacman.conf; then
        sed -i 's/^#Color/Color/' /etc/pacman.conf
        log "Enabled color output"
    fi

    # Enable multilib
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log "Enabling multilib repository..."
        sed -i '/^#\[multilib\]/,/^#Include/ s/^#//' /etc/pacman.conf
    else
        log "multilib already enabled"
    fi

    pacman -Syyu --noconfirm
    log "pacman configured and synced."
}

# ==============================================================================
# CachyOS optimized repositories (x86-64-v3/v4 rebuilds)
# ==============================================================================
configure_cachyos_repos() {
    section "CachyOS Repositories"

    read -rp "Add CachyOS optimized repositories? (x86-64-v3/v4 rebuilds) [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        warn "Skipping CachyOS repositories."
        CACHYOS_REPOS_ENABLED=false
        return
    fi

    # Detect CPU instruction set level
    local march
    march=$(/lib/ld-linux-x86-64.so.2 --help 2>/dev/null | grep -oP 'x86-64-v\d' | sort -V | tail -1 || true)

    if [[ -z "$march" ]]; then
        warn "Could not detect CPU instruction set level. Skipping CachyOS repos."
        CACHYOS_REPOS_ENABLED=false
        return
    fi

    # Convert x86-64-v3 -> v3, x86-64-v4 -> v4
    local level="${march##*-}"

    if [[ "$level" != "v3" && "$level" != "v4" ]]; then
        warn "CPU supports ${march} — CachyOS repos require at least x86-64-v3. Skipping."
        CACHYOS_REPOS_ENABLED=false
        return
    fi

    # Use v3 repos even for v4 CPUs (v4 repo availability is limited)
    local repo_level="v3"
    local arch_path="x86_64_v3"
    if [[ "$level" == "v4" ]]; then
        info "CPU supports x86-64-v4 — using v3 repos (broader package availability)"
    fi

    log "Detected CPU level: ${march}, using CachyOS ${repo_level} repositories"

    # Import CachyOS signing key
    info "Importing CachyOS GPG key..."
    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key F3B607488DB35A47
    log "CachyOS GPG key imported and locally signed."

    # Create mirrorlist with hardcoded arch path (standard pacman lacks $arch_v3)
    local mirrorlist="/etc/pacman.d/cachyos-${repo_level}-mirrorlist"
    cat > "${mirrorlist}" << EOF
# CachyOS ${repo_level} mirrors
Server = https://cdn77.cachyos.org/repo/${arch_path}/\$repo
Server = https://cdn.cachyos.org/repo/${arch_path}/\$repo
Server = https://mirror.cachyos.org/repo/${arch_path}/\$repo
EOF
    log "Created mirrorlist: ${mirrorlist}"

    # Insert CachyOS repo sections before [core] in pacman.conf
    # Skip [cachyos] repo (contains forked pacman we want to avoid)
    local tmpconf
    tmpconf=$(mktemp)
    awk -v level="${repo_level}" -v mirrorlist="${mirrorlist}" '
    /^\[core\]/ {
        print "[cachyos-" level "]"
        print "Include = " mirrorlist
        print ""
        print "[cachyos-core-" level "]"
        print "Include = " mirrorlist
        print ""
        print "[cachyos-extra-" level "]"
        print "Include = " mirrorlist
        print ""
    }
    { print }
    ' /etc/pacman.conf > "${tmpconf}"
    mv "${tmpconf}" /etc/pacman.conf
    chmod 644 /etc/pacman.conf
    log "Added CachyOS repo sections to pacman.conf (before [core])"

    # Sync new repos
    info "Syncing CachyOS repositories..."
    pacman -Sy
    log "CachyOS repositories synced."

    CACHYOS_REPOS_ENABLED=true
}

# ==============================================================================
# Locale, timezone, hostname
# ==============================================================================
configure_system() {
    section "System Configuration"

    # Timezone
    ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
    hwclock --systohc
    log "Timezone: ${TIMEZONE}"

    # Locale
    sed -i "s/^#${LOCALE}/${LOCALE}/" /etc/locale.gen
    # Also enable en_US.UTF-8 as fallback
    sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=${LOCALE}" > /etc/locale.conf
    log "Locale: ${LOCALE}"

    # Keymap
    echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf
    log "Keymap: ${KEYMAP}"

    # Hostname
    echo "${HOSTNAME}" > /etc/hostname
    cat > /etc/hosts << EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
    log "Hostname: ${HOSTNAME}"
}

# ==============================================================================
# Install GRUB
# ==============================================================================
configure_grub() {
    section "GRUB Bootloader"

    if command -v grub-install &>/dev/null; then
        grub-install --target="${GRUB_TARGET}" --efi-directory="${EFI_DIRECTORY}" --bootloader-id=GRUB
        log "GRUB installed (EFI)"
    else
        warn "grub not found, will install it with packages first"
        pacman -S --noconfirm --needed grub efibootmgr os-prober
        grub-install --target="${GRUB_TARGET}" --efi-directory="${EFI_DIRECTORY}" --bootloader-id=GRUB
        log "GRUB installed (EFI)"
    fi

    # Enable os-prober
    if ! grep -q "^GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
        echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
    fi

    grub-mkconfig -o /boot/grub/grub.cfg
    log "GRUB config generated with os-prober enabled."
}

# ==============================================================================
# Create user
# ==============================================================================
configure_user() {
    section "User Configuration"

    if id "${USERNAME}" &>/dev/null; then
        log "User ${USERNAME} already exists, updating groups..."
        usermod -aG "${USER_GROUPS}" "${USERNAME}"
    else
        log "Creating user ${USERNAME}..."
        useradd -m -G "${USER_GROUPS}" -s "${USER_SHELL}" "${USERNAME}"
        log "Set a password for ${USERNAME}:"
        passwd "${USERNAME}"
    fi

    # Ensure wheel group has sudo
    if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        log "Enabled sudo for wheel group"
    fi

    log "User ${USERNAME} configured."
}

# ==============================================================================
# Install packages
# ==============================================================================
build_package_list() {
    local packages=()

    packages+=("${BASE_PACKAGES[@]}")
    packages+=("${AUDIO_PACKAGES[@]}")
    packages+=("${BLUETOOTH_PACKAGES[@]}")
    packages+=("${NETWORK_PACKAGES[@]}")
    packages+=("${FONT_PACKAGES[@]}")
    packages+=("${CLI_PACKAGES[@]}")
    packages+=("${BROWSER_PACKAGES[@]}")
    packages+=("${MEDIA_PACKAGES[@]}")
    packages+=("${APP_PACKAGES[@]}")
    packages+=("${MISC_PACKAGES[@]}")
    packages+=("${GREETD_PACKAGES[@]}")

    case "${GPU_DRIVER}" in
        amd)    packages+=("${AMD_PACKAGES[@]}") ;;
        nvidia) packages+=("${NVIDIA_PACKAGES[@]}") ;;
    esac

    [[ "$INSTALL_HYPRLAND" == true ]] && packages+=("${HYPRLAND_PACKAGES[@]}")
    [[ "$INSTALL_DEV_TOOLS" == true ]] && packages+=("${DEV_PACKAGES[@]}")
    [[ "$INSTALL_DOCKER" == true ]] && packages+=("${DOCKER_PACKAGES[@]}")
    [[ "$INSTALL_GAMING" == true ]] && packages+=("${GAMING_PACKAGES[@]}")
    [[ "$INSTALL_VIRTUALIZATION" == true ]] && packages+=("${VIRT_PACKAGES[@]}")
    [[ "$CACHYOS_REPOS_ENABLED" == true ]] && packages+=("${CACHYOS_PACKAGES[@]}")

    # Deduplicate
    printf '%s\n' "${packages[@]}" | sort -u
}

install_packages() {
    section "Installing Packages"

    mapfile -t ALL_PACKAGES < <(build_package_list)
    info "Installing ${#ALL_PACKAGES[@]} packages..."

    pacman -S --noconfirm --needed "${ALL_PACKAGES[@]}"

    log "All pacman packages installed."
}

# ==============================================================================
# Enable services
# ==============================================================================
enable_services() {
    section "Enabling Services"

    # Core
    systemctl enable NetworkManager
    log "NetworkManager enabled"

    systemctl enable bluetooth
    log "Bluetooth enabled"

    systemctl enable sshd
    log "SSH enabled"

    systemctl enable fwupd
    log "fwupd enabled"

    # Display
    systemctl enable greetd
    log "greetd login manager enabled"

    # Flatpak
    systemctl enable flatpak-system-helper
    log "Flatpak enabled"

    # Power
    systemctl enable power-profiles-daemon
    log "power-profiles-daemon enabled"

    # Docker
    if [[ "$INSTALL_DOCKER" == true ]]; then
        systemctl enable docker
        log "Docker enabled"
    fi

    # Virtualization
    if [[ "$INSTALL_VIRTUALIZATION" == true ]]; then
        systemctl enable libvirtd
        log "libvirtd enabled"
    fi

    # udisks2
    systemctl enable udisks2
    log "udisks2 enabled"
}

# ==============================================================================
# Configure greetd (tuigreet -> Hyprland)
# ==============================================================================
configure_greetd() {
    section "Configuring greetd"

    mkdir -p /etc/greetd
    cat > /etc/greetd/config.toml << EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --cmd Hyprland"
user = "${USERNAME}"
EOF

    log "greetd configured to launch Hyprland via tuigreet"
}

# ==============================================================================
# Configure SSH
# ==============================================================================
configure_ssh() {
    section "Configuring SSH"

    cat > /etc/ssh/sshd_config.d/99-custom.conf << EOF
PasswordAuthentication yes
AllowUsers ${USERNAME}
UseDNS yes
X11Forwarding yes
PermitRootLogin no
EOF

    log "SSH configured (password auth, ${USERNAME} only, no root login)"
}

# ==============================================================================
# Configure firewall
# ==============================================================================
configure_firewall() {
    section "Configuring Firewall"

    systemctl enable firewalld
    # firewalld will be running after reboot; add rules then
    # For now, write a helper script

    cat > /usr/local/bin/setup-firewall.sh << 'EOF'
#!/usr/bin/env bash
# Run after first boot to configure firewall rules
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload
echo "Firewall configured: SSH allowed"
EOF
    chmod +x /usr/local/bin/setup-firewall.sh

    log "Firewall enabled. Run 'sudo setup-firewall.sh' after first boot."
}

# ==============================================================================
# Swap file (64GB to match NixOS config)
# ==============================================================================
configure_swap() {
    section "Swap Configuration"

    if [[ -f /swapfile ]]; then
        log "Swapfile already exists, skipping."
        return
    fi

    read -rp "Create a 64GB swapfile at /swapfile? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        info "Creating 64GB swapfile (this may take a moment)..."
        btrfs filesystem mkswapfile --size 64G /swapfile
        mkswap /swapfile
        swapon /swapfile

        # Add to fstab if not present
        if ! grep -q "/swapfile" /etc/fstab; then
            echo '/swapfile none swap defaults 0 0' >> /etc/fstab
        fi
        log "Swapfile created and enabled."
    else
        warn "Skipping swapfile creation."
    fi
}

# ==============================================================================
# Set up Rust toolchain
# ==============================================================================
configure_rust() {
    section "Rust Toolchain"

    if [[ "$INSTALL_DEV_TOOLS" == true ]]; then
        # rustup needs to run as the user
        su - "${USERNAME}" -c 'rustup default stable'
        log "Rust stable toolchain installed for ${USERNAME}"
    fi
}

# ==============================================================================
# Copy post-install script to user home
# ==============================================================================
prepare_post_install() {
    section "Preparing Post-Install"

    local target="/home/${USERNAME}/arch_install"

    if [[ "$(realpath "${SCRIPT_DIR}")" == "$(realpath "${target}")" ]]; then
        log "Already running from ${target}, skipping copy."
    else
        mkdir -p "${target}"
        cp "${SCRIPT_DIR}/config.sh" "${target}/"
        cp "${SCRIPT_DIR}/post-install.sh" "${target}/"
        cp "${SCRIPT_DIR}/tmux-setup.sh" "${target}/"
        log "Post-install scripts copied to ~${USERNAME}/arch_install/"
    fi

    chmod +x "${target}"/*.sh
    chown -R "${USERNAME}:${USERNAME}" "${target}"
}

# ==============================================================================
# Summary
# ==============================================================================
print_summary() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Root Setup Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "  Hostname:  ${CYAN}${HOSTNAME}${NC}"
    echo -e "  User:      ${CYAN}${USERNAME}${NC}"
    echo -e "  Shell:     ${CYAN}${USER_SHELL}${NC}"
    echo -e "  GPU:       ${CYAN}${GPU_DRIVER}${NC}"
    echo -e "  CachyOS:   ${CYAN}${CACHYOS_REPOS_ENABLED}${NC}"
    echo -e "  Desktop:   ${CYAN}Hyprland (via greetd + tuigreet)${NC}"
    echo ""
    echo -e "${YELLOW}  Next steps:${NC}"
    echo -e "  1. Reboot"
    echo -e "  2. Log in as ${USERNAME}"
    echo -e "  3. Run: ${CYAN}~/arch_install/post-install.sh${NC}"
    echo -e "     (installs AUR helper, AUR packages, configures dotfiles)"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    CACHYOS_REPOS_ENABLED=false

    echo ""
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}  Arch Linux Post-Install Setup${NC}"
    echo -e "${CYAN}  (Based on NixOS probird5 config)${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""

    preflight
    configure_pacman
    configure_cachyos_repos
    configure_system
    install_packages
    configure_grub
    configure_user
    configure_greetd
    configure_ssh
    configure_firewall
    configure_swap
    enable_services
    configure_rust
    prepare_post_install
    print_summary
}

main "$@"
