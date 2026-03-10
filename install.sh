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
# Helper: yes/no prompt (defaults to $2: y or n)
# ==============================================================================
ask_yn() {
    local prompt="$1"
    local default="${2:-n}"
    local hint="y/N"
    [[ "$default" == "y" ]] && hint="Y/n"

    local response
    read -rp "  ${prompt} [${hint}] " response
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy]$ ]]
}

# ==============================================================================
# Interactive configuration — all prompts up front
# ==============================================================================
gather_config() {
    section "System Configuration"

    # --- Username ---
    read -rp "  Username [${DEFAULT_USERNAME}]: " input
    USERNAME="${input:-$DEFAULT_USERNAME}"

    # --- Hostname ---
    read -rp "  Hostname [${DEFAULT_HOSTNAME}]: " input
    HOSTNAME="${input:-$DEFAULT_HOSTNAME}"

    # --- Timezone ---
    echo -e "  Current timezone default: ${CYAN}${DEFAULT_TIMEZONE}${NC}"
    read -rp "  Timezone [${DEFAULT_TIMEZONE}]: " input
    TIMEZONE="${input:-$DEFAULT_TIMEZONE}"
    if [[ ! -f "/usr/share/zoneinfo/${TIMEZONE}" ]]; then
        warn "Timezone '${TIMEZONE}' not found, falling back to UTC"
        TIMEZONE="UTC"
    fi

    # --- Locale ---
    read -rp "  Locale [${DEFAULT_LOCALE}]: " input
    LOCALE="${input:-$DEFAULT_LOCALE}"

    # --- Keymap ---
    read -rp "  Keymap [${DEFAULT_KEYMAP}]: " input
    KEYMAP="${input:-$DEFAULT_KEYMAP}"

    # --- GPU driver ---
    echo ""
    echo -e "  GPU driver options: ${CYAN}amd${NC}, ${CYAN}nvidia${NC}, ${CYAN}intel${NC}, ${CYAN}none${NC}"
    read -rp "  GPU driver [${DEFAULT_GPU}]: " input
    GPU_DRIVER="${input:-$DEFAULT_GPU}"
    case "$GPU_DRIVER" in
        amd|nvidia|intel|none) ;;
        *) warn "Unknown GPU driver '${GPU_DRIVER}', defaulting to none"; GPU_DRIVER="none" ;;
    esac

    # --- Feature toggles ---
    echo ""
    echo -e "  ${BOLD}Feature toggles:${NC}"
    ask_yn "Install Hyprland desktop?" "y" && INSTALL_HYPRLAND=true || INSTALL_HYPRLAND=false
    ask_yn "Install development tools? (neovim, go, rust, node, etc.)" "y" && INSTALL_DEV_TOOLS=true || INSTALL_DEV_TOOLS=false
    ask_yn "Install Docker?" "y" && INSTALL_DOCKER=true || INSTALL_DOCKER=false
    ask_yn "Install virtualization? (QEMU/KVM, virt-manager)" "y" && INSTALL_VIRTUALIZATION=true || INSTALL_VIRTUALIZATION=false
    ask_yn "Install gaming packages? (Steam, Wine, Lutris, etc.)" "y" && INSTALL_GAMING=true || INSTALL_GAMING=false

    # --- CachyOS repos ---
    echo ""
    ask_yn "Add CachyOS repositories? (v3 optimized packages, gaming meta, proton)" "n" && INSTALL_CACHYOS=true || INSTALL_CACHYOS=false

    # --- AUR helper ---
    echo ""
    echo -e "  AUR helper options: ${CYAN}paru${NC}, ${CYAN}yay${NC}"
    read -rp "  AUR helper [${DEFAULT_AUR_HELPER}]: " input
    AUR_HELPER="${input:-$DEFAULT_AUR_HELPER}"
    case "$AUR_HELPER" in
        paru|yay) ;;
        *) warn "Unknown AUR helper '${AUR_HELPER}', defaulting to paru"; AUR_HELPER="paru" ;;
    esac
    INSTALL_AUR_PACKAGES=true

    # --- Dotfiles ---
    echo ""
    read -rp "  Dotfiles git repo URL [${DEFAULT_DOTFILES_REPO}]: " input
    DOTFILES_REPO="${input:-$DEFAULT_DOTFILES_REPO}"
    DOTFILES_DIR="/home/${USERNAME}/Documents/Repos/dotfiles"

    # --- Swap ---
    echo ""
    local ram_gb
    ram_gb=$(awk '/MemTotal/ {printf "%d", $2/1024/1024}' /proc/meminfo)
    echo -e "  Detected RAM: ${CYAN}${ram_gb}GB${NC}"
    echo "  Recommended: 8GB (general use) or ${ram_gb}GB+ (hibernation)"
    read -rp "  Swapfile size in GB (0 to skip) [8]: " input
    SWAP_SIZE="${input:-8}"

    # --- Summary ---
    echo ""
    echo -e "${BOLD}${CYAN}=== Configuration Summary ===${NC}"
    echo ""
    echo -e "  Username:        ${CYAN}${USERNAME}${NC}"
    echo -e "  Hostname:        ${CYAN}${HOSTNAME}${NC}"
    echo -e "  Timezone:        ${CYAN}${TIMEZONE}${NC}"
    echo -e "  Locale:          ${CYAN}${LOCALE}${NC}"
    echo -e "  Keymap:          ${CYAN}${KEYMAP}${NC}"
    echo -e "  GPU:             ${CYAN}${GPU_DRIVER}${NC}"
    echo -e "  Hyprland:        ${CYAN}${INSTALL_HYPRLAND}${NC}"
    echo -e "  Dev tools:       ${CYAN}${INSTALL_DEV_TOOLS}${NC}"
    echo -e "  Docker:          ${CYAN}${INSTALL_DOCKER}${NC}"
    echo -e "  Virtualization:  ${CYAN}${INSTALL_VIRTUALIZATION}${NC}"
    echo -e "  Gaming:          ${CYAN}${INSTALL_GAMING}${NC}"
    echo -e "  CachyOS repos:   ${CYAN}${INSTALL_CACHYOS}${NC}"
    echo -e "  AUR helper:      ${CYAN}${AUR_HELPER}${NC}"
    echo -e "  Dotfiles:        ${CYAN}${DOTFILES_REPO}${NC}"
    echo -e "  Swap:            ${CYAN}${SWAP_SIZE}GB${NC}"
    echo ""

    if ! ask_yn "Proceed with this configuration?" "y"; then
        err "Aborted by user."
        exit 1
    fi

    # Save gathered config so post-install.sh can source it
    cat > "${SCRIPT_DIR}/user-config.sh" << EOF
# Auto-generated by install.sh — do not edit
USERNAME="${USERNAME}"
HOSTNAME="${HOSTNAME}"
TIMEZONE="${TIMEZONE}"
LOCALE="${LOCALE}"
KEYMAP="${KEYMAP}"
GPU_DRIVER="${GPU_DRIVER}"
INSTALL_HYPRLAND=${INSTALL_HYPRLAND}
INSTALL_DEV_TOOLS=${INSTALL_DEV_TOOLS}
INSTALL_DOCKER=${INSTALL_DOCKER}
INSTALL_VIRTUALIZATION=${INSTALL_VIRTUALIZATION}
INSTALL_GAMING=${INSTALL_GAMING}
INSTALL_CACHYOS=${INSTALL_CACHYOS}
AUR_HELPER="${AUR_HELPER}"
INSTALL_AUR_PACKAGES=${INSTALL_AUR_PACKAGES}
DOTFILES_REPO="${DOTFILES_REPO}"
DOTFILES_DIR="${DOTFILES_DIR}"
SWAP_SIZE="${SWAP_SIZE}"
EOF
    log "Configuration saved to ${SCRIPT_DIR}/user-config.sh"
}

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

    # Remove any existing CachyOS repos from previous runs
    if grep -q "^\[cachyos" /etc/pacman.conf; then
        warn "Found leftover CachyOS repos in pacman.conf, cleaning up..."
        sed -i '/^\[cachyos.*\]/,/^Include.*cachyos/d' /etc/pacman.conf
        sed -i '/^IgnorePkg.*pacman/d' /etc/pacman.conf
        # Clean up blank lines left behind
        sed -i '/^$/N;/^\n$/d' /etc/pacman.conf
        log "Removed leftover CachyOS repo entries"
    fi

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
# CachyOS repositories (includes forked pacman for v3 architecture support)
# ==============================================================================
configure_cachyos_repos() {
    section "CachyOS Repositories"

    if [[ "$INSTALL_CACHYOS" != true ]]; then
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

    local level="${march##*-}"

    if [[ "$level" != "v3" && "$level" != "v4" ]]; then
        warn "CPU supports ${march} — CachyOS repos require at least x86-64-v3. Skipping."
        CACHYOS_REPOS_ENABLED=false
        return
    fi

    local repo_level="v3"
    local arch_path="x86_64_v3"
    if [[ "$level" == "v4" ]]; then
        info "CPU supports x86-64-v4 — using v3 repos (broader package availability)"
    fi

    log "Detected CPU level: ${march}, using CachyOS ${repo_level} repositories"

    # Import CachyOS signing key
    info "Importing CachyOS GPG key..."
    local keyservers=(keyserver.ubuntu.com keys.openpgp.org pgp.mit.edu)
    local key_imported=false
    for ks in "${keyservers[@]}"; do
        if pacman-key --recv-keys F3B607488DB35A47 --keyserver "$ks" 2>/dev/null; then
            key_imported=true
            log "GPG key received from $ks"
            break
        fi
        warn "Keyserver $ks failed, trying next..."
    done
    if [[ "$key_imported" != true ]]; then
        err "Could not import CachyOS GPG key from any keyserver. Skipping CachyOS repos."
        CACHYOS_REPOS_ENABLED=false
        return
    fi
    pacman-key --lsign-key F3B607488DB35A47
    log "CachyOS GPG key locally signed."

    # Create mirrorlist for v3 repos
    local v3_mirrorlist="/etc/pacman.d/cachyos-v3-mirrorlist"
    cat > "${v3_mirrorlist}" << EOF
# CachyOS v3 mirrors
Server = https://cdn77.cachyos.org/repo/${arch_path}/\$repo
Server = https://cdn.cachyos.org/repo/${arch_path}/\$repo
Server = https://mirror.cachyos.org/repo/${arch_path}/\$repo
EOF
    log "Created mirrorlist: ${v3_mirrorlist}"

    # Create mirrorlist for main [cachyos] repo (x86_64)
    local main_mirrorlist="/etc/pacman.d/cachyos-mirrorlist"
    cat > "${main_mirrorlist}" << 'EOF'
# CachyOS main mirrors
Server = https://cdn77.cachyos.org/repo/x86_64/$repo
Server = https://cdn.cachyos.org/repo/x86_64/$repo
Server = https://mirror.cachyos.org/repo/x86_64/$repo
EOF
    log "Created mirrorlist: ${main_mirrorlist}"

    # Step 1: Add only [cachyos] repo first (x86_64, works with standard pacman)
    if ! grep -q "^\[cachyos\]" /etc/pacman.conf; then
        local tmpconf
        tmpconf=$(mktemp)
        awk -v main_mirrorlist="${main_mirrorlist}" '
        /^\[core\]/ {
            print "[cachyos]"
            print "Include = " main_mirrorlist
            print ""
        }
        { print }
        ' /etc/pacman.conf > "${tmpconf}"
        mv "${tmpconf}" /etc/pacman.conf
        chmod 644 /etc/pacman.conf
        log "Added [cachyos] repo to pacman.conf"
    else
        log "[cachyos] repo already in pacman.conf, skipping insertion"
    fi

    # Step 2: Sync and install CachyOS pacman (adds v3/v4 architecture support)
    info "Syncing [cachyos] repo..."
    pacman -Sy
    info "Installing CachyOS pacman (adds v3/v4 architecture support)..."
    pacman -S --noconfirm --needed cachyos/pacman
    log "CachyOS pacman installed."

    # Step 3: Now add v3 repos (CachyOS pacman can handle v3 architecture)
    if ! grep -q "^\[cachyos-${repo_level}\]" /etc/pacman.conf; then
        tmpconf=$(mktemp)
        awk -v level="${repo_level}" -v v3_mirrorlist="${v3_mirrorlist}" '
        /^\[cachyos\]/ {
            print "[cachyos-" level "]"
            print "Include = " v3_mirrorlist
            print ""
            print "[cachyos-core-" level "]"
            print "Include = " v3_mirrorlist
            print ""
            print "[cachyos-extra-" level "]"
            print "Include = " v3_mirrorlist
            print ""
        }
        { print }
        ' /etc/pacman.conf > "${tmpconf}"
        mv "${tmpconf}" /etc/pacman.conf
        chmod 644 /etc/pacman.conf
        log "Added v3 repos to pacman.conf"
    else
        log "v3 repos already in pacman.conf, skipping insertion"
    fi

    # Step 4: Final sync with all repos
    info "Syncing all CachyOS repositories..."
    pacman -Sy
    log "CachyOS repositories fully configured."

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
# NVIDIA driver configuration (blacklist nouveau, DRM modeset, initramfs)
# ==============================================================================
configure_nvidia() {
    if [[ "$GPU_DRIVER" != "nvidia" ]]; then
        return
    fi

    section "NVIDIA Driver Configuration"

    # --- Blacklist nouveau ---
    log "Blacklisting nouveau driver..."
    cat > /etc/modprobe.d/nouveau-blacklist.conf << 'EOF'
blacklist nouveau
options nouveau modeset=0
EOF
    log "nouveau blacklisted via /etc/modprobe.d/nouveau-blacklist.conf"

    # --- Enable early KMS (DRM kernel modesetting) ---
    log "Configuring NVIDIA kernel modules for early KMS..."
    cat > /etc/modprobe.d/nvidia.conf << 'EOF'
options nvidia_drm modeset=1
options nvidia_drm fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF
    log "NVIDIA DRM modeset and framebuffer device enabled"

    # --- Add NVIDIA modules to mkinitcpio ---
    if grep -q "^MODULES=" /etc/mkinitcpio.conf; then
        local current_modules
        current_modules=$(grep "^MODULES=" /etc/mkinitcpio.conf | sed 's/MODULES=(\(.*\))/\1/')
        local nvidia_modules="nvidia nvidia_modeset nvidia_uvm nvidia_drm"

        # Only add modules that aren't already present
        local new_modules="$current_modules"
        for mod in $nvidia_modules; do
            if ! echo "$current_modules" | grep -qw "$mod"; then
                new_modules="$new_modules $mod"
            fi
        done
        # Trim leading/trailing whitespace
        new_modules=$(echo "$new_modules" | xargs)

        sed -i "s/^MODULES=.*/MODULES=($new_modules)/" /etc/mkinitcpio.conf
        log "Added NVIDIA modules to mkinitcpio: $nvidia_modules"
    fi

    # --- Regenerate initramfs ---
    info "Regenerating initramfs..."
    mkinitcpio -P
    log "Initramfs regenerated with NVIDIA modules"

    # --- Add NVIDIA kernel parameters to GRUB ---
    local grub_file="/etc/default/grub"
    local nvidia_params="nvidia_drm.modeset=1 nvidia_drm.fbdev=1"

    if ! grep -q "nvidia_drm.modeset=1" "$grub_file"; then
        sed -i "s/\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)/\1 ${nvidia_params}/" "$grub_file"
        log "Added NVIDIA kernel parameters to GRUB: $nvidia_params"

        # Regenerate GRUB config
        info "Regenerating GRUB config..."
        grub-mkconfig -o /boot/grub/grub.cfg
        log "GRUB config regenerated with NVIDIA parameters"
    else
        log "NVIDIA kernel parameters already in GRUB config"
    fi

    # --- Enable NVIDIA suspend/resume services ---
    systemctl enable nvidia-suspend.service 2>/dev/null || true
    systemctl enable nvidia-hibernate.service 2>/dev/null || true
    systemctl enable nvidia-resume.service 2>/dev/null || true
    log "NVIDIA suspend/hibernate/resume services enabled"

    log "NVIDIA driver configuration complete (nouveau is blacklisted)"
}

# ==============================================================================
# Create user
# ==============================================================================
configure_user() {
    section "User Configuration"

    # Build groups dynamically — only add groups that exist
    local groups="${USER_GROUPS}"
    [[ "$INSTALL_DOCKER" == true ]] && getent group docker &>/dev/null && groups+=",docker"
    [[ "$INSTALL_VIRTUALIZATION" == true ]] && getent group libvirt &>/dev/null && groups+=",libvirt"

    if id "${USERNAME}" &>/dev/null; then
        log "User ${USERNAME} already exists, updating groups..."
        usermod -aG "${groups}" "${USERNAME}"
    else
        log "Creating user ${USERNAME}..."
        useradd -m -G "${groups}" -s "${USER_SHELL}" "${USERNAME}"
        log "Set a password for ${USERNAME}:"
        passwd "${USERNAME}"
    fi

    # Ensure wheel group has sudo
    if ! grep -q "^%wheel ALL=(ALL:ALL) ALL" /etc/sudoers; then
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
        log "Enabled sudo for wheel group"
    fi

    log "User ${USERNAME} configured (groups: ${groups})."
}

# ==============================================================================
# Gaming configuration
# ==============================================================================
configure_gaming() {
    section "Gaming Configuration"

    if [[ "$INSTALL_GAMING" != true ]]; then
        warn "Skipping gaming packages."
        INSTALL_CACHYOS_GAMING=false
        return
    fi

    if [[ "$CACHYOS_REPOS_ENABLED" == true ]]; then
        log "CachyOS repos detected — CachyOS gaming meta packages will be installed."
        INSTALL_CACHYOS_GAMING=true
    else
        log "No CachyOS repos — installing standard gaming packages (wine, steam, lutris, etc.)."
        INSTALL_CACHYOS_GAMING=false
    fi
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
        nvidia)
            if [[ "$CACHYOS_REPOS_ENABLED" == true ]]; then
                packages+=("${CACHYOS_NVIDIA_PACKAGES[@]}")
            else
                packages+=("${NVIDIA_PACKAGES[@]}")
            fi
            ;;
    esac

    [[ "$INSTALL_HYPRLAND" == true ]] && packages+=("${HYPRLAND_PACKAGES[@]}")
    [[ "$INSTALL_DEV_TOOLS" == true ]] && packages+=("${DEV_PACKAGES[@]}")
    [[ "$INSTALL_DOCKER" == true ]] && packages+=("${DOCKER_PACKAGES[@]}")
    if [[ "$INSTALL_GAMING" == true ]]; then
        if [[ "$INSTALL_CACHYOS_GAMING" == true ]]; then
            packages+=("${CACHYOS_GAMING_PACKAGES[@]}")
        else
            packages+=("${GAMING_PACKAGES[@]}")
        fi
    fi
    [[ "$INSTALL_VIRTUALIZATION" == true ]] && packages+=("${VIRT_PACKAGES[@]}")
    [[ "$CACHYOS_REPOS_ENABLED" == true ]] && packages+=("${CACHYOS_PACKAGES[@]}")

    # When CachyOS repos are enabled, their mesa-git packages replace standard
    # mesa packages. Requesting both causes unresolvable conflicts.
    if [[ "$CACHYOS_REPOS_ENABLED" == true ]]; then
        local cachyos_skip=(
            lib32-mesa lib32-vulkan-radeon lib32-libva-mesa-driver
            mesa vulkan-radeon libva-mesa-driver
        )
        local filtered=()
        local skip_set
        skip_set=$(printf '%s\n' "${cachyos_skip[@]}")
        for pkg in "${packages[@]}"; do
            if ! echo "$skip_set" | grep -qxF "$pkg"; then
                filtered+=("$pkg")
            fi
        done
        packages=("${filtered[@]}")
    fi

    # Deduplicate
    printf '%s\n' "${packages[@]}" | sort -u
}

install_packages() {
    section "Installing Packages"

    # Remove packages that conflict with CachyOS replacements
    # Use pacman -Q (exact name match) instead of -Qi (which matches virtual provides)
    if [[ "$INSTALL_CACHYOS_GAMING" == true ]]; then
        local conflicts=(wine wine-gecko wine-mono)
        for pkg in "${conflicts[@]}"; do
            if pacman -Q "$pkg" &>/dev/null 2>&1; then
                info "Removing $pkg (conflicts with CachyOS gaming packages)..."
                pacman -Rdd --noconfirm "$pkg" || warn "Could not remove $pkg, continuing anyway..."
            fi
        done
    fi

    mapfile -t ALL_PACKAGES < <(build_package_list)
    info "Installing ${#ALL_PACKAGES[@]} packages..."

    # --ask 4 auto-accepts removal of conflicting packages (e.g. CachyOS replacements)
    # Pipe `yes ""` to auto-accept default provider choices (e.g. "Enter a number (default=1):")
    # --noconfirm alone does not handle provider selection prompts.
    yes "" | pacman -Syu --noconfirm --needed --ask 4 "${ALL_PACKAGES[@]}"

    log "All pacman packages installed."
}

# ==============================================================================
# Enable services
# ==============================================================================
enable_services() {
    section "Enabling Services"

    local -a services=(
        NetworkManager
        bluetooth
        sshd
        fwupd
        greetd
        flatpak-system-helper
        power-profiles-daemon
        udisks2
    )

    [[ "$INSTALL_DOCKER" == true ]] && services+=(docker)
    [[ "$INSTALL_VIRTUALIZATION" == true ]] && services+=(libvirtd)

    for svc in "${services[@]}"; do
        if systemctl enable "$svc" 2>/dev/null; then
            log "$svc enabled"
        else
            warn "Could not enable $svc (unit not found?), skipping"
        fi
    done
}

# ==============================================================================
# Configure libvirt default network
# ==============================================================================
configure_libvirt_network() {
    if [[ "$INSTALL_VIRTUALIZATION" != true ]]; then
        return
    fi

    section "Libvirt Default Network"

    # libvirtd must be running to configure networks via virsh
    if ! systemctl is-active libvirtd &>/dev/null; then
        info "Starting libvirtd temporarily to configure default network..."
        systemctl start libvirtd
    fi

    # Wait briefly for libvirtd socket to be ready
    sleep 2

    # Define the default network if it doesn't exist
    if ! virsh net-info default &>/dev/null; then
        if [[ -f /usr/share/libvirt/networks/default.xml ]]; then
            virsh net-define /usr/share/libvirt/networks/default.xml
            log "Defined default NAT network"
        else
            warn "default.xml not found, skipping network definition"
            return
        fi
    fi

    # Enable auto-start and start the network
    virsh net-autostart default 2>/dev/null || warn "Could not set default network to autostart"
    virsh net-start default 2>/dev/null || log "Default network already active"

    log "Libvirt default NAT network configured and set to auto-start"
}

# ==============================================================================
# Configure greetd (tuigreet with session selection)
# ==============================================================================
configure_greetd() {
    section "Configuring greetd"

    # Create Hyprland wayland session entry
    mkdir -p /usr/share/wayland-sessions
    cat > /usr/share/wayland-sessions/hyprland.desktop << 'EOF'
[Desktop Entry]
Name=Hyprland
Comment=An intelligent dynamic tiling Wayland compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
Keywords=wayland;compositor;tiling;
EOF
    log "Created Hyprland wayland session entry"

    # Configure greetd with session discovery
    mkdir -p /etc/greetd
    cat > /etc/greetd/config.toml << EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --sessions /usr/share/wayland-sessions"
user = "${USERNAME}"
EOF

    log "greetd configured with session selection (F3 to switch)"
}

# ==============================================================================
# Configure Steam Gamescope session (couch gaming)
# ==============================================================================
configure_steam_session() {
    if [[ "$INSTALL_CACHYOS_GAMING" != true ]]; then
        return
    fi

    section "Steam Gamescope Session"

    # Create wrapper script that stops containers/VMs before launching Steam
    cat > /usr/local/bin/steam-session << 'EOF'
#!/usr/bin/env bash
# Steam Gamescope Session — stops containers and VMs, then launches Steam Big Picture

# Stop all running Docker containers
if command -v docker &>/dev/null; then
    running=$(docker ps -q)
    if [[ -n "$running" ]]; then
        echo "Stopping Docker containers..."
        docker stop $running
    fi
fi

# Shut down all running libvirt VMs
if command -v virsh &>/dev/null; then
    virsh list --name 2>/dev/null | while read -r vm; do
        [[ -z "$vm" ]] && continue
        echo "Shutting down VM: $vm"
        virsh shutdown "$vm"
    done
fi

# Launch gamescope with Steam Big Picture
exec gamescope -e -- steam -gamepadui -steamdeck
EOF
    chmod +x /usr/local/bin/steam-session
    log "Created /usr/local/bin/steam-session wrapper script"

    # Create wayland session entry
    cat > /usr/share/wayland-sessions/steam-gamepadui.desktop << 'EOF'
[Desktop Entry]
Name=Steam Big Picture
Comment=Steam Gamepad UI via Gamescope (stops containers/VMs)
Exec=/usr/local/bin/steam-session
Type=Application
DesktopNames=gamescope
Keywords=wayland;gaming;steam;gamescope;
EOF
    log "Created Steam Big Picture wayland session entry"
}

# ==============================================================================
# Battery saver toggle script
# ==============================================================================
configure_battery_saver() {
    section "Battery Saver"

    cat > /usr/local/bin/battery-saver << 'EOF'
#!/usr/bin/env bash
# Toggle battery saver mode for Hyprland
# Bind this to a key in your Hyprland config, e.g.:
#   bind = SUPER, F12, exec, battery-saver

STATE_FILE="${HOME}/.cache/battery-saver-active"

enable_battery_saver() {
    powerprofilesctl set power-saver
    brightnessctl set 20%

    if command -v docker &>/dev/null; then
        sudo systemctl stop docker
    fi

    if command -v virsh &>/dev/null; then
        sudo systemctl stop libvirtd
    fi

    mkdir -p "$(dirname "$STATE_FILE")"
    touch "$STATE_FILE"
    notify-send "Battery Saver" "Enabled — power-saver profile, screen dimmed, services stopped"
}

disable_battery_saver() {
    powerprofilesctl set balanced
    brightnessctl set 60%

    if command -v docker &>/dev/null; then
        sudo systemctl start docker
    fi

    if command -v virsh &>/dev/null; then
        sudo systemctl start libvirtd
    fi

    rm -f "$STATE_FILE"
    notify-send "Battery Saver" "Disabled — balanced profile, screen restored, services started"
}

if [[ -f "$STATE_FILE" ]]; then
    disable_battery_saver
else
    enable_battery_saver
fi
EOF
    chmod +x /usr/local/bin/battery-saver
    log "Created /usr/local/bin/battery-saver toggle script"
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
# Swap file
# ==============================================================================
configure_swap() {
    section "Swap Configuration"

    if [[ -f /swapfile ]]; then
        log "Swapfile already exists, skipping."
        return
    fi

    if [[ "$SWAP_SIZE" == "0" ]]; then
        warn "Skipping swapfile creation."
        return
    fi

    if ! [[ "$SWAP_SIZE" =~ ^[0-9]+$ ]] || [[ "$SWAP_SIZE" -lt 1 ]]; then
        warn "Invalid swap size '${SWAP_SIZE}', skipping swapfile."
        return
    fi

    info "Creating ${SWAP_SIZE}GB swapfile (this may take a moment)..."

    # Try btrfs-native method first, fall back to manual creation
    if btrfs filesystem mkswapfile --size "${SWAP_SIZE}G" /swapfile 2>/dev/null; then
        log "Swapfile created via btrfs mkswapfile."
    else
        warn "btrfs mkswapfile failed, falling back to manual creation..."
        rm -f /swapfile
        truncate -s 0 /swapfile
        chattr +C /swapfile 2>/dev/null || true
        # dd is required for btrfs — fallocate creates sparse files that are invalid for swap
        dd if=/dev/zero of=/swapfile bs=1G count="${SWAP_SIZE}" status=progress
        chmod 600 /swapfile
        mkswap /swapfile
    fi

    if swapon /swapfile; then
        # Add to fstab if not present
        if ! grep -q "/swapfile" /etc/fstab; then
            echo '/swapfile none swap defaults 0 0' >> /etc/fstab
        fi
        log "Swapfile (${SWAP_SIZE}GB) created and enabled."
    else
        err "Failed to enable swapfile. You may need to configure swap manually."
        rm -f /swapfile
    fi
}

# ==============================================================================
# Set up Rust toolchain
# ==============================================================================
configure_rust() {
    section "Rust Toolchain"

    if [[ "$INSTALL_DEV_TOOLS" == true ]] && command -v rustup &>/dev/null; then
        # rustup needs to run as the user
        su - "${USERNAME}" -c 'rustup default stable' || warn "Failed to set Rust toolchain (can be done manually later)"
        log "Rust stable toolchain installed for ${USERNAME}"
    elif [[ "$INSTALL_DEV_TOOLS" == true ]]; then
        warn "rustup not found, skipping Rust toolchain setup"
    fi
}

# ==============================================================================
# Copy post-install script to user home
# ==============================================================================
prepare_post_install() {
    section "Preparing Post-Install"

    # Ensure scripts are executable and owned by the user
    chmod +x "${SCRIPT_DIR}"/*.sh
    chown -R "${USERNAME}:${USERNAME}" "${SCRIPT_DIR}"
    log "Post-install scripts ready at ${SCRIPT_DIR}"
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
    echo -e "  3. Run: ${CYAN}${SCRIPT_DIR}/post-install.sh${NC}"
    echo -e "     (installs AUR helper, AUR packages, configures dotfiles)"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    CACHYOS_REPOS_ENABLED=false
    INSTALL_CACHYOS_GAMING=false

    echo ""
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}  Arch Linux Post-Install Setup${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""

    preflight
    gather_config
    configure_pacman
    configure_cachyos_repos
    configure_gaming
    configure_system
    install_packages
    configure_grub
    configure_nvidia
    configure_user
    configure_greetd
    configure_steam_session
    configure_battery_saver
    configure_ssh
    configure_firewall
    configure_swap
    enable_services
    configure_libvirt_network
    configure_rust
    prepare_post_install
    print_summary
}

main "$@"
