#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Post-Install Setup - User Phase
# ==============================================================================
# Run this as your normal user AFTER rebooting into the new system.
# This installs the AUR helper, AUR packages, and configures dotfiles/theming.
#
# Usage:
#   ./post-install.sh
#
# Do NOT run as root — the script will use sudo when needed.
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
# Pre-flight
# ==============================================================================
preflight() {
    section "Pre-flight Checks"

    if [[ $EUID -eq 0 ]]; then
        err "Do NOT run this script as root. Run as your normal user."
        exit 1
    fi

    if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
        err "No internet connection."
        exit 1
    fi

    log "User: $(whoami) | Internet: OK"
}

# ==============================================================================
# Install AUR helper (paru or yay)
# ==============================================================================
install_aur_helper() {
    section "AUR Helper (${AUR_HELPER})"

    if command -v "${AUR_HELPER}" &>/dev/null; then
        log "${AUR_HELPER} already installed."
        return
    fi

    local build_dir
    build_dir="$(mktemp -d)"

    log "Building ${AUR_HELPER} from source..."
    git clone "https://aur.archlinux.org/${AUR_HELPER}.git" "${build_dir}/${AUR_HELPER}"
    (cd "${build_dir}/${AUR_HELPER}" && makepkg -si --noconfirm)

    rm -rf "${build_dir}"
    log "${AUR_HELPER} installed."
}

# ==============================================================================
# Install AUR packages
# ==============================================================================
install_aur_packages() {
    section "AUR Packages"

    if [[ "$INSTALL_AUR_PACKAGES" != true ]]; then
        warn "AUR packages disabled in config. Skipping."
        return
    fi

    local to_install=()

    for pkg in "${AUR_PACKAGES[@]}"; do
        # Skip comments and empty lines
        [[ -z "$pkg" || "$pkg" == \#* ]] && continue

        # Skip if already installed
        if ! "${AUR_HELPER}" -Qi "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log "All AUR packages already installed."
        return
    fi

    info "Installing ${#to_install[@]} AUR packages..."
    "${AUR_HELPER}" -S --noconfirm --needed "${to_install[@]}"

    log "AUR packages installed."
}

# ==============================================================================
# Configure Git
# ==============================================================================
configure_git() {
    section "Git Configuration"

    git config --global user.name "probird5"
    git config --global user.email "52969604+probird5@users.noreply.github.com"

    log "Git configured (probird5)"
}

# ==============================================================================
# Zsh as default shell
# ==============================================================================
configure_shell() {
    section "Shell Configuration"

    if [[ "$SHELL" != "/usr/bin/zsh" ]]; then
        log "Changing default shell to zsh..."
        chsh -s /usr/bin/zsh
        log "Shell changed to zsh (takes effect on next login)"
    else
        log "Shell already set to zsh"
    fi

    # Source zsh-autosuggestions and syntax highlighting from arch paths
    local zshrc="${HOME}/.zshrc"
    if [[ -f "$zshrc" ]]; then
        if ! grep -q "zsh-autosuggestions.zsh" "$zshrc"; then
            cat >> "$zshrc" << 'EOF'

# Arch zsh plugins
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Zoxide
eval "$(zoxide init zsh)"
EOF
            log "Added zsh plugin sources to .zshrc"
        fi
    fi
}

# ==============================================================================
# GTK / Qt / Cursor Theming
# ==============================================================================
configure_theming() {
    section "Theming (GTK, Qt, Cursors)"

    # GTK 3
    mkdir -p "${HOME}/.config/gtk-3.0"
    cat > "${HOME}/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Nordzy
gtk-cursor-theme-name=Nordzy-cursors
gtk-cursor-theme-size=32
gtk-font-name=Inter 11
gtk-application-prefer-dark-theme=1
EOF
    log "GTK 3 theme: Dracula / Nordzy icons / Nordzy cursors"

    # GTK 4
    mkdir -p "${HOME}/.config/gtk-4.0"
    cat > "${HOME}/.config/gtk-4.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=Dracula
gtk-icon-theme-name=Nordzy
gtk-cursor-theme-name=Nordzy-cursors
gtk-cursor-theme-size=32
gtk-font-name=Inter 11
gtk-application-prefer-dark-theme=1
EOF
    log "GTK 4 theme configured"

    # GTK 2
    cat > "${HOME}/.gtkrc-2.0" << 'EOF'
gtk-theme-name="Dracula"
gtk-icon-theme-name="Nordzy"
gtk-cursor-theme-name="Nordzy-cursors"
gtk-cursor-theme-size=32
gtk-font-name="Inter 11"
EOF
    log "GTK 2 theme configured"

    # Qt environment
    mkdir -p "${HOME}/.config/environment.d"
    cat > "${HOME}/.config/environment.d/qt.conf" << 'EOF'
QT_QPA_PLATFORMTHEME=gtk2
EOF
    log "Qt set to follow GTK theme"

    # Cursor theme (for Wayland / Hyprland)
    mkdir -p "${HOME}/.icons/default"
    cat > "${HOME}/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=Nordzy-cursors
EOF
    log "Default cursor theme: Nordzy-cursors"

    # X resources
    cat > "${HOME}/.Xresources" << 'EOF'
Xcursor.size: 24
Xft.dpi: 120
Xcursor.theme: Nordzy-cursors
EOF
    log "Xresources configured (DPI 120, cursor 24)"

    # dconf for GNOME apps
    if command -v dconf &>/dev/null; then
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
        dconf write /org/gnome/desktop/interface/gtk-theme "'Dracula'"
        dconf write /org/gnome/desktop/interface/icon-theme "'Nordzy'"
        log "dconf dark theme applied"
    fi
}

# ==============================================================================
# Environment variables
# ==============================================================================
configure_environment() {
    section "Environment Variables"

    mkdir -p "${HOME}/.config/environment.d"

    cat > "${HOME}/.config/environment.d/wayland.conf" << 'EOF'
MOZ_ENABLE_WAYLAND=1
XCURSOR_SIZE=24
XCURSOR_THEME=Nordzy-cursors
GTK_THEME=Dracula
EDITOR=nvim
EOF

    cat > "${HOME}/.config/environment.d/steam.conf" << 'EOF'
STEAM_EXTRA_COMPAT_TOOLS_PATHS=${HOME}/.steam/root/compatibilitytools.d
EOF

    log "Environment variables configured"
}

# ==============================================================================
# XDG user directories
# ==============================================================================
configure_xdg() {
    section "XDG Directories"

    if command -v xdg-user-dirs-update &>/dev/null; then
        xdg-user-dirs-update
        log "XDG user directories created"
    fi
}

# ==============================================================================
# Flatpak setup
# ==============================================================================
configure_flatpak() {
    section "Flatpak"

    if command -v flatpak &>/dev/null; then
        flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        log "Flathub remote added"
    fi
}

# ==============================================================================
# Firewall (deferred from root phase)
# ==============================================================================
configure_firewall() {
    section "Firewall Rules"

    if command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --reload
        log "Firewall: SSH allowed"
    else
        warn "firewalld not running yet. Run 'sudo setup-firewall.sh' manually."
    fi
}

# ==============================================================================
# PipeWire user services
# ==============================================================================
enable_user_services() {
    section "User Services"

    # PipeWire (runs as user service)
    local -a user_services=(pipewire.socket pipewire-pulse.socket wireplumber)
    for svc in "${user_services[@]}"; do
        if systemctl --user enable --now "$svc" 2>/dev/null; then
            log "$svc enabled"
        else
            warn "Could not enable $svc (may need a graphical session), skipping"
        fi
    done
}

# ==============================================================================
# Dotfiles (stow)
# ==============================================================================
setup_dotfiles() {
    section "Dotfiles (GNU Stow)"

    # Clone if not present
    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        log "Cloning dotfiles repo..."
        mkdir -p "$(dirname "${DOTFILES_DIR}")"
        git clone "${DOTFILES_REPO}" "${DOTFILES_DIR}"
    else
        log "Dotfiles repo already exists at ${DOTFILES_DIR}"
        info "Pulling latest changes..."
        git -C "${DOTFILES_DIR}" pull --ff-only || warn "Could not pull (not on a tracking branch?)"
    fi

    # Clean up any existing configs (symlinks or directories) before stowing
    log "Removing conflicting configs..."
    local config_dirs=(alacritty ghostty hypr i3 nvim rofi starship waybar wlogout)
    for dir in "${config_dirs[@]}"; do
        [ -L "${HOME}/.config/$dir" ] && rm -f "${HOME}/.config/$dir"
        [ -d "${HOME}/.config/$dir" ] && rm -rf "${HOME}/.config/$dir"
    done
    rm -f "${HOME}/.tmux.conf"
    rm -f "${HOME}/.zshrc"

    # Stow all dotfiles packages directly
    # tmux is excluded — managed by tmux-setup.sh instead
    local stow_dirs=(
        alacritty ghostty hypr i3 librewolf nvim
        picom rofi starship waybar wezterm wlogout zsh
    )

    for dir in "${stow_dirs[@]}"; do
        if [[ -d "${DOTFILES_DIR}/$dir" ]]; then
            info "Stowing $dir..."
            stow -v -d "${DOTFILES_DIR}" -t "${HOME}" "$dir" || warn "Failed to stow $dir"
        fi
    done

    # Copy backgrounds and fonts (not stowed)
    if [[ -d "${DOTFILES_DIR}/backgrounds" ]]; then
        mkdir -p "${HOME}/Pictures/backgrounds"
        cp -r "${DOTFILES_DIR}/backgrounds/"* "${HOME}/Pictures/backgrounds/" 2>/dev/null || true
        log "Backgrounds copied"
    fi
    if [[ -d "${DOTFILES_DIR}/fonts" ]]; then
        mkdir -p "${HOME}/.local/share/fonts"
        cp -r "${DOTFILES_DIR}/fonts/"* "${HOME}/.local/share/fonts/" 2>/dev/null || true
        fc-cache -fv 2>/dev/null || true
        log "Fonts installed"
    fi

    log "Dotfiles stowed."
}

# ==============================================================================
# Rust toolchain verification
# ==============================================================================
verify_rust() {
    section "Rust Verification"

    if command -v rustup &>/dev/null; then
        if ! rustup show active-toolchain &>/dev/null; then
            rustup default stable
            log "Rust stable toolchain installed"
        else
            log "Rust toolchain: $(rustup show active-toolchain)"
        fi
    fi
}

# ==============================================================================
# Tmux (TPM + config)
# ==============================================================================
setup_tmux() {
    section "Tmux Setup"

    if [[ -x "${SCRIPT_DIR}/tmux-setup.sh" ]]; then
        "${SCRIPT_DIR}/tmux-setup.sh"
    else
        warn "tmux-setup.sh not found in ${SCRIPT_DIR}, skipping."
    fi
}

# ==============================================================================
# Summary
# ==============================================================================
print_summary() {
    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Post-Install Setup Complete!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo -e "  ${BOLD}What was configured:${NC}"
    echo -e "    - AUR helper: ${CYAN}${AUR_HELPER}${NC}"
    echo -e "    - AUR packages: ${CYAN}${#AUR_PACKAGES[@]} packages${NC}"
    echo -e "    - Git: ${CYAN}probird5${NC}"
    echo -e "    - Shell: ${CYAN}zsh + starship + fzf + zoxide${NC}"
    echo -e "    - Theme: ${CYAN}Dracula / Nordzy icons / Nordzy cursors${NC}"
    echo -e "    - Audio: ${CYAN}PipeWire user services${NC}"
    echo -e "    - Flatpak: ${CYAN}Flathub remote${NC}"
    echo ""
    echo -e "  ${BOLD}Dotfiles:${NC}"
    echo -e "    - Repo: ${CYAN}${DOTFILES_DIR}${NC}"
    echo -e "    - Stowed via GNU Stow"
    echo ""
    echo -e "  ${YELLOW}Reboot recommended to pick up all changes.${NC}"
    echo ""
}

# ==============================================================================
# Main
# ==============================================================================
main() {
    echo ""
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}  Arch Linux Post-Install (User Phase)${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""

    preflight
    install_aur_helper
    install_aur_packages
    configure_git
    setup_dotfiles
    setup_tmux
    configure_shell
    configure_theming
    configure_environment
    configure_xdg
    configure_flatpak
    configure_firewall
    enable_user_services
    verify_rust
    print_summary
}

main "$@"
