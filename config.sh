#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Install - Configuration
# ==============================================================================
# Package lists and default values. User-specific settings are prompted
# interactively by install.sh — no need to edit this file.
# ==============================================================================

# --- Defaults (overridden by interactive prompts) ---
DEFAULT_USERNAME="probird5"
DEFAULT_HOSTNAME="archlinux"
DEFAULT_TIMEZONE="America/Toronto"
DEFAULT_LOCALE="en_CA.UTF-8"
DEFAULT_KEYMAP="us"
DEFAULT_GPU="amd"
DEFAULT_AUR_HELPER="paru"
DEFAULT_DOTFILES_REPO="https://github.com/probird5/dotfiles.git"

# --- Static config (rarely changes) ---
USER_SHELL="/usr/bin/zsh"
USER_GROUPS="wheel,network,audio,video,render,kvm"
GRUB_TARGET="x86_64-efi"
EFI_DIRECTORY="/boot"

# ==============================================================================
# Package Lists
# ==============================================================================

# --- Base system ---
BASE_PACKAGES=(
  base
  base-devel
  linux
  linux-firmware
  linux-headers
  btrfs-progs
  grub
  efibootmgr
  os-prober
  networkmanager
  sudo
  vim
  git
  wget
  curl
  stow
)

# --- AMD GPU ---
AMD_PACKAGES=(
  mesa
  lib32-mesa
  vulkan-radeon
  lib32-vulkan-radeon
  vulkan-tools
  vulkan-icd-loader
  lib32-vulkan-icd-loader
  libva-mesa-driver
  lib32-libva-mesa-driver
  xf86-video-amdgpu
  amd-ucode
  amdgpu_top
  rocm-smi-lib
)

CACHYOS_PACKAGES=(
  topgrade
)

# --- NVIDIA GPU (if needed) ---
NVIDIA_PACKAGES=(
  nvidia-dkms
  nvidia-utils
  lib32-nvidia-utils
  nvidia-settings
  vulkan-icd-loader
  lib32-vulkan-icd-loader
  egl-wayland
  libva-nvidia-driver
)

# --- Audio (PipeWire) ---
AUDIO_PACKAGES=(
  pipewire
  pipewire-alsa
  pipewire-pulse
  pipewire-jack
  lib32-pipewire
  wireplumber
  pavucontrol
  pamixer
  pulsemixer
)

# --- Bluetooth ---
BLUETOOTH_PACKAGES=(
  bluez
  bluez-utils
  blueman
)

# --- Networking ---
NETWORK_PACKAGES=(
  networkmanager
  openssh
  firewalld
  cifs-utils
  nfs-utils
  samba
)

# --- Hyprland & Desktop ---
HYPRLAND_PACKAGES=(
  hyprland
  hyprpaper
  hyprlock
  hypridle
  hyprcursor
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk
  xdg-desktop-portal
  waybar
  grim
  slurp
  wl-clipboard
  xorg-xwayland
  wayland-utils
  brightnessctl
  playerctl
  libnotify
  polkit-kde-agent
  thunar
  thunar-archive-plugin
  thunar-volman
  tumbler
  gvfs
  xarchiver
  dconf
  xdg-utils
  xdg-user-dirs
  wlr-randr
  nwg-look
  lxappearance
  qt5-wayland
  qt6-wayland
  qt5ct
  qt6ct
)

# --- Login manager ---
GREETD_PACKAGES=(
  greetd
  greetd-tuigreet
)

# --- Fonts ---
FONT_PACKAGES=(
  ttf-firacode-nerd
  ttf-jetbrains-mono-nerd
  ttf-fira-sans
  otf-font-awesome
  ttf-nerd-fonts-symbols
  ttf-nerd-fonts-symbols-mono
  inter-font
  noto-fonts
  noto-fonts-emoji
)

# --- CLI tools ---
CLI_PACKAGES=(
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  tmux
  starship
  fzf
  zoxide
  ripgrep
  fd
  bat
  jq
  tree
  fastfetch
  openssl
  trash-cli
  p7zip
  unzip
  lz4
  btop
  sysstat
  lm_sensors
  ethtool
  pciutils
  usbutils
  man-db
  man-pages
  less
  htop
  swww # don't need aur
  rofi
  swappy # no need for aur
  swaync # no need aur
  nwg-displays
  ghostty
  obsidian
  spotify-launcher
  yazi
  lazydocker
  eza
)

# --- Development ---
DEV_PACKAGES=(
  neovim
  go
  rustup
  python
  python-pip
  nodejs
  npm
  lua
  gcc
  make
  cmake
  pkg-config
  bind
  lazygit
  sshfs
  freerdp
  remmina
)

# --- Docker ---
DOCKER_PACKAGES=(
  docker
  docker-compose
)

# --- Gaming ---
GAMING_PACKAGES=(
  steam
  lutris
  gamescope
  gamemode
  lib32-gamemode
  wine
  wine-mono
  wine-gecko
  winetricks
  lib32-gnutls
  lib32-sdl2
)

# --- CachyOS Gaming (requires CachyOS repos) ---
CACHYOS_GAMING_PACKAGES=(
  cachyos-gaming-meta
  cachyos-gaming-applications
  proton-cachyos-slr
  wine-cachyos
  umu-launcher
)

# --- Virtualization ---
VIRT_PACKAGES=(
  qemu-full
  virt-manager
  virt-viewer
  libvirt
  swtpm
  dnsmasq
  spice-vdagent
)

# --- Browsers ---
BROWSER_PACKAGES=(
  firefox
)

# --- Media ---
MEDIA_PACKAGES=(
  mpv
  feh
  imagemagick
)

# --- Applications (pacman) ---
APP_PACKAGES=(
  libreoffice-fresh
  discord
  flatpak
  android-tools
  hashcat
  fwupd
)

# --- Misc system ---
MISC_PACKAGES=(
  udisks2
  power-profiles-daemon
  ntfs-3g
  dosfstools
  alacritty
)

# ==============================================================================
# AUR Packages (installed via paru/yay after first boot)
# ==============================================================================
AUR_PACKAGES=(
  # 1password
  # protonup-qt  # in cachy
  # bottles      # flatpak
)
