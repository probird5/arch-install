# Arch Linux Post-Install Setup

Automated post-install configuration for Arch Linux, derived from a NixOS flake config. Sets up a full Hyprland Wayland desktop with AMD GPU drivers, PipeWire audio, development tools, gaming, and virtualization.

## Prerequisites

- Base Arch Linux installed on btrfs
- Booted into the system
- Internet connection
- Root access

## Usage

```bash
# 1. Clone this repo (or copy files to the machine)
git clone <repo-url> ~/arch_install
cd ~/arch_install

# 2. Edit config.sh to match your hardware/preferences
vim config.sh

# 3. Run the root phase
sudo ./install.sh

# 4. Reboot
reboot

# 5. Log in as your user and run the user phase
~/arch_install/post-install.sh
```

## Files

| File | Run as | What it does |
|---|---|---|
| `config.sh` | sourced | Variables, feature toggles, all package lists |
| `install.sh` | root | pacman config, system setup, GRUB, user, services |
| `post-install.sh` | user | AUR helper (paru), AUR packages, theming, dotfiles |

## What Gets Installed

### System (`install.sh`)

- **Bootloader**: GRUB (EFI + os-prober)
- **GPU**: AMD (mesa, vulkan-radeon, VAAPI, VDPAU, ROCm) — NVIDIA option in config
- **Audio**: PipeWire + WirePlumber (PulseAudio compat, ALSA, JACK)
- **Bluetooth**: bluez + blueman
- **Desktop**: Hyprland, Waybar, Thunar, grim/slurp, polkit-kde-agent
- **Login**: greetd + tuigreet -> Hyprland
- **Networking**: NetworkManager, SSH, firewalld
- **Docker**: docker, docker-compose, docker-buildx
- **Virtualization**: QEMU/KVM, virt-manager, libvirt, swtpm
- **Gaming**: Steam, Lutris, Gamescope, gamemode, Wine
- **Dev**: Neovim, Go, Rust (rustup), Python, Node.js, Lua, lazygit
- **CLI**: zsh, starship, fzf, zoxide, ripgrep, fd, bat, btop, tmux, yazi

### User (`post-install.sh`)

- **AUR helper**: paru
- **AUR packages**: ghostty, obsidian, 1password, spotify, protonup-qt, bottles, rofi-wayland, swww, swaync, dracula-gtk-theme, nordzy icons/cursors, amdgpu_top, lazydocker
- **Theming**: Dracula GTK, Nordzy icons, Nordzy cursors, dark mode
- **Environment**: Wayland variables, editor, cursor size, Steam compat paths
- **Services**: PipeWire user services, Flatpak (Flathub)
- **Git**: preconfigured user/email

## Configuration

Edit `config.sh` before running. Key options:

```bash
# Target machine
HOSTNAME="messmer"
USERNAME="probird5"

# GPU: "amd", "nvidia", "intel", "none"
GPU_DRIVER="amd"

# Feature toggles
INSTALL_GAMING=true
INSTALL_VIRTUALIZATION=true
INSTALL_DOCKER=true
INSTALL_HYPRLAND=true
INSTALL_DEV_TOOLS=true
INSTALL_AUR_PACKAGES=true

# AUR helper: "paru" or "yay"
AUR_HELPER="paru"
```

## Dotfiles

The scripts set up theming and environment but dotfiles need to be symlinked manually:

```bash
git clone <your-dotfiles-repo> ~/dotfiles

ln -sf ~/dotfiles/hypr      ~/.config/hypr
ln -sf ~/dotfiles/waybar    ~/.config/waybar
ln -sf ~/dotfiles/rofi      ~/.config/rofi
ln -sf ~/dotfiles/alacritty ~/.config/alacritty
ln -sf ~/dotfiles/starship  ~/.config/starship
ln -sf ~/dotfiles/nvim      ~/.config/nvim
ln -sf ~/dotfiles/btop      ~/.config/btop
ln -sf ~/dotfiles/fastfetch ~/.config/fastfetch
ln -sf ~/dotfiles/ghostty   ~/.config/ghostty
```

## Desktop Stack

| Component | Tool |
|---|---|
| Compositor | Hyprland |
| Bar | Waybar |
| Launcher | rofi (wayland fork) |
| Terminal | Ghostty / Alacritty |
| File Manager | Thunar |
| Notifications | swaync |
| Wallpaper | swww |
| Lock | hyprlock |
| Idle | hypridle |
| Screenshots | grim + slurp + swappy |
| Login | greetd + tuigreet |
| Audio | PipeWire |
| Theme | Dracula / Nordzy / Tokyo Night |
