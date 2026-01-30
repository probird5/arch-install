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
| `post-install.sh` | user | AUR helper (paru), AUR packages, theming, dotfiles, tmux |
| `tmux-setup.sh` | user | Installs TPM, writes `.tmux.conf`, installs plugins |

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
- **Tmux**: TPM bootstrap, `.tmux.conf` with vim-tmux-navigator, tokyo-night-tmux, better-mouse-mode

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

Dotfiles are managed via [GNU Stow](https://www.gnu.org/software/stow/) and deployed automatically during `post-install.sh`. The script clones your dotfiles repo and runs `setup.sh --stow-only`, which symlinks all configs into `~/.config/` and `~/`.

Configure the repo URL in `config.sh`:

```bash
DOTFILES_REPO="https://github.com/probird5/dotfiles.git"
DOTFILES_DIR="${HOME}/Documents/Repos/dotfiles"
```

Stowed packages: `alacritty`, `ghostty`, `hypr`, `nvim`, `rofi`, `starship`, `tmux`, `waybar`, `zsh` (plus backgrounds and fonts copied separately).

To re-stow or update after changing dotfiles:

```bash
cd ~/Documents/Repos/dotfiles
git pull
./setup.sh --stow-only
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
