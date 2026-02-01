# Arch Linux Post-Install Setup

Automated post-install configuration for Arch Linux, derived from a NixOS flake config. Sets up a full Hyprland Wayland desktop with development tools, gaming, virtualization, and power management utilities.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Configuration](#configuration)
  - [Feature Toggles](#feature-toggles)
  - [Hardware Options](#hardware-options)
  - [Dotfiles](#dotfiles)
- [Installation Phases](#installation-phases)
  - [Phase 1: Root Setup](#phase-1-root-setup-installsh)
  - [Phase 2: User Setup](#phase-2-user-setup-post-installsh)
- [Interactive Prompts](#interactive-prompts)
- [CachyOS Repositories](#cachyos-repositories)
- [Gaming](#gaming)
  - [CachyOS Gaming Packages](#cachyos-gaming-packages)
  - [Steam Big Picture Session](#steam-big-picture-session)
- [Battery Saver Mode](#battery-saver-mode)
- [Desktop Stack](#desktop-stack)
- [Package Lists](#package-lists)
- [Post-Install Summary](#post-install-summary)

---

## Prerequisites

- Base Arch Linux installed on btrfs
- Booted into the system
- Internet connection
- Root access

---

## Quick Start

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

---

## Repository Structure

| File | Run as | Purpose |
|---|---|---|
| `config.sh` | sourced | All variables, feature toggles, and package lists |
| `install.sh` | root | System setup, packages, GRUB, services, session configuration |
| `post-install.sh` | user | AUR helper, theming, dotfiles, user services |
| `tmux-setup.sh` | user | TPM bootstrap, `.tmux.conf`, plugin installation |

---

## Configuration

Edit `config.sh` before running. All variables and package lists are centralized here.

### Feature Toggles

```bash
INSTALL_GAMING=true
INSTALL_VIRTUALIZATION=true
INSTALL_DOCKER=true
INSTALL_HYPRLAND=true
INSTALL_DEV_TOOLS=true
INSTALL_AUR_PACKAGES=true
```

> **Note:** Gaming packages are only installed through [CachyOS Gaming](#cachyos-gaming-packages) and require CachyOS repos to be enabled. The `INSTALL_GAMING` toggle is overridden by the interactive gaming prompt during installation.

### Hardware Options

```bash
# GPU driver: "amd", "nvidia", "intel", "none"
GPU_DRIVER="amd"

# Target machine
HOSTNAME="messmer"
USERNAME="probird5"

# Locale
TIMEZONE="America/Toronto"
LOCALE="en_CA.UTF-8"
KEYMAP="us"
```

### Dotfiles

Dotfiles are managed via [GNU Stow](https://www.gnu.org/software/stow/) and deployed during `post-install.sh`. The script clones the repo and stows all packages into `~/.config/` and `~/`.

```bash
DOTFILES_REPO="https://github.com/probird5/dotfiles.git"
DOTFILES_DIR="${HOME}/Documents/Repos/dotfiles"
```

Stowed packages: `alacritty`, `ghostty`, `hypr`, `i3`, `librewolf`, `nvim`, `picom`, `rofi`, `starship`, `tmux`, `waybar`, `wezterm`, `wlogout`, `zsh`

---

## Installation Phases

### Phase 1: Root Setup (`install.sh`)

Run as root on a freshly installed base Arch system. Performs the following in order:

1. **Pre-flight checks** — verifies root access and internet
2. **Pacman configuration** — parallel downloads, color, multilib
3. **CachyOS repositories** — optional v3 optimized packages + CachyOS gaming/tools (interactive prompt)
4. **Gaming configuration** — optional CachyOS gaming packages (interactive prompt)
5. **System configuration** — timezone, locale, keymap, hostname
6. **Package installation** — all packages from config.sh based on feature toggles
7. **GRUB bootloader** — EFI install with os-prober for dual-boot
8. **User creation** — user account, sudo, groups
9. **greetd login manager** — tuigreet with session selection (F3 to switch)
10. **Steam Gamescope session** — couch gaming session entry (if gaming enabled)
11. **Battery saver script** — toggle script at `/usr/local/bin/battery-saver`
12. **SSH configuration** — password auth, user-only, no root login
13. **Firewall** — firewalld with deferred SSH rule
14. **Swap file** — optional 64GB btrfs swapfile (interactive prompt)
15. **Services** — NetworkManager, Bluetooth, SSH, Docker, libvirtd, greetd, etc.
16. **Rust toolchain** — stable toolchain via rustup
17. **Post-install prep** — copies scripts to user home

### Phase 2: User Setup (`post-install.sh`)

Run as your normal user after rebooting. Handles:

1. **AUR helper** — builds and installs paru (or yay) from source
2. **AUR packages** — installs any packages listed in `AUR_PACKAGES`
3. **Git** — global user/email configuration
4. **Shell** — sets zsh as default, adds plugin sources
5. **Theming** — GTK 2/3/4, Qt, cursor themes (Dracula + Nordzy)
6. **Environment variables** — Wayland, editor, cursor, Steam compat paths
7. **XDG directories** — standard user directories
8. **Flatpak** — adds Flathub remote
9. **Firewall rules** — enables SSH in firewalld
10. **PipeWire** — enables user-mode audio services
11. **Dotfiles** — clones repo and stows all configs via GNU Stow
12. **Rust verification** — ensures toolchain is ready
13. **Tmux** — TPM install, config, plugins

---

## Interactive Prompts

The install script asks three questions during execution:

| Prompt | Default | Effect |
|---|---|---|
| Add CachyOS repositories? | No | Enables CachyOS repos with v3 optimized packages, gaming meta, proton, etc. |
| Will you be gaming on this install? | No | Installs CachyOS gaming meta packages (requires CachyOS repos) |
| Create a 64GB swapfile? | No | Creates btrfs swapfile at `/swapfile` |

---

## CachyOS Repositories

When enabled, the script:

1. Detects your CPU instruction set level (x86-64-v3 or v4)
2. Imports the CachyOS GPG signing key
3. Creates mirrorlists for both the main and v3 repos
4. Adds `[cachyos]`, `[cachyos-v3]`, `[cachyos-core-v3]`, and `[cachyos-extra-v3]` repos before `[core]` in `pacman.conf`
5. Installs the CachyOS forked pacman (required for v3 architecture support)

This provides x86-64-v3 optimized rebuilds of Arch packages and access to CachyOS-specific packages (gaming meta, topgrade, proton-cachyos, wine-cachyos, etc.). The CachyOS pacman is a minimal fork that adds v3/v4 architecture recognition — without it, standard pacman rejects v3 packages.

---

## Gaming

### CachyOS Gaming Packages

Gaming packages are **exclusively** sourced from CachyOS repositories. If you answer yes to the gaming prompt but CachyOS repos are not enabled, no gaming packages will be installed.

When both CachyOS repos and gaming are enabled, the following are installed:

| Package | Description |
|---|---|
| `cachyos-gaming-meta` | Meta package with gaming libraries and Proton-CachyOS |
| `cachyos-gaming-applications` | Steam, Heroic, Lutris, Gamescope, Goverlay, MangoHud |
| `proton-cachyos-slr` | Proton-CachyOS Steam Linux Runtime variant |
| `wine-cachyos` | CachyOS optimized Wine |
| `umu-launcher` | Required for running Proton-CachyOS in Lutris and Heroic |

### Steam Big Picture Session

When gaming is enabled, a **Steam Big Picture** session is registered as a Wayland session option in the tuigreet login screen. Press **F3** at the login screen to switch between sessions.

**Available sessions:**

| Session | Description |
|---|---|
| Hyprland | Default tiling Wayland compositor desktop |
| Steam Big Picture | Gamescope + Steam GamepadUI (couch gaming mode) |

**What the Steam session does before launching:**

1. Stops all running Docker containers
2. Shuts down all running libvirt VMs
3. Launches `gamescope -e -- steam -gamepadui -steamdeck`

The wrapper script is installed at `/usr/local/bin/steam-session`. It gracefully handles cases where Docker or libvirt are not installed or no containers/VMs are running.

**Controller support:** Bluetooth is enabled system-wide. Pair your controller once from Hyprland (via blueman or `bluetoothctl`), and it will auto-reconnect when powered on in the Steam session.

---

## Battery Saver Mode

A toggle script is installed at `/usr/local/bin/battery-saver`. Run it once to enable battery saver, run it again to disable it.

**Bind it to a key in your Hyprland config:**

```
bind = SUPER, F12, exec, battery-saver
```

### What it does

| | Enable | Disable |
|---|---|---|
| Power profile | `power-saver` | `balanced` |
| Screen brightness | 20% | 60% |
| Docker | stopped | started |
| libvirtd | stopped | started |

The script tracks state via `~/.cache/battery-saver-active` and sends a desktop notification on each toggle. Docker and libvirt operations use `sudo systemctl` and are skipped if the respective tools aren't installed.

---

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
| Audio | PipeWire + WirePlumber |
| Theme | Dracula / Nordzy / Tokyo Night |

---

## Package Lists

All package arrays are defined in `config.sh`. The `build_package_list()` function in `install.sh` assembles them based on feature toggles and deduplicates before installing.

| Category | Toggle | Contents |
|---|---|---|
| Base | always | base, base-devel, linux, firmware, btrfs-progs, grub, git, stow |
| AMD GPU | `GPU_DRIVER="amd"` | mesa, vulkan-radeon, libva-mesa-driver, amd-ucode |
| NVIDIA GPU | `GPU_DRIVER="nvidia"` | nvidia, nvidia-utils, egl-wayland |
| Audio | always | pipewire, wireplumber, pavucontrol, pamixer |
| Bluetooth | always | bluez, bluez-utils, blueman |
| Networking | always | networkmanager, openssh, firewalld, samba |
| Hyprland | `INSTALL_HYPRLAND` | hyprland, waybar, thunar, grim, slurp, polkit-kde-agent, qt5/6-wayland |
| Fonts | always | FiraCode Nerd, JetBrains Mono Nerd, Inter, Noto |
| CLI | always | zsh, tmux, starship, fzf, zoxide, ripgrep, fd, bat, btop, yazi, ghostty |
| Development | `INSTALL_DEV_TOOLS` | neovim, go, rustup, python, nodejs, lua, lazygit |
| Docker | `INSTALL_DOCKER` | docker, docker-compose |
| CachyOS Gaming | interactive prompt | cachyos-gaming-meta, cachyos-gaming-applications, proton-cachyos-slr, wine-cachyos, umu-launcher |
| Virtualization | `INSTALL_VIRTUALIZATION` | qemu-full, virt-manager, libvirt, swtpm |
| CachyOS | CachyOS repos enabled | topgrade |
| Browsers | always | firefox |
| Media | always | mpv, feh, imagemagick |
| Apps | always | libreoffice-fresh, discord, flatpak, android-tools, hashcat, fwupd |
| Misc | always | udisks2, power-profiles-daemon, ntfs-3g, alacritty |
| Login | always | greetd, greetd-tuigreet |

---

## Post-Install Summary

After both phases complete, you'll have:

- Hyprland desktop accessible via tuigreet login (with optional Steam Big Picture session)
- PipeWire audio with PulseAudio and JACK compatibility
- Bluetooth with auto-reconnect for paired devices
- Development environment with Neovim, Go, Rust, Python, Node.js
- Docker and QEMU/KVM virtualization
- GNU Stow-managed dotfiles
- Battery saver toggle at `/usr/local/bin/battery-saver`
- Firewall with SSH allowed
- Flatpak with Flathub
