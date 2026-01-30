#!/usr/bin/env bash
# ==============================================================================
# Arch Linux Install - Configuration
# ==============================================================================
# Shared variables for all install phases. Edit these before running install.sh.
# ==============================================================================

# --- User ---
USERNAME="probird5"
USER_SHELL="/usr/bin/zsh"
USER_GROUPS="wheel,networkmanager,audio,video,render,kvm,libvirt,docker,flatpak"
HOSTNAME="messmer"

# --- Locale & Time ---
TIMEZONE="America/Toronto"
LOCALE="en_CA.UTF-8"
KEYMAP="us"

# --- Boot ---
# Set to the disk device for GRUB install (e.g., /dev/sda or /dev/nvme0n1)
# GRUB will be installed in EFI mode — this is only used for fallback/MBR.
GRUB_TARGET="x86_64-efi"
EFI_DIRECTORY="/boot"

# --- GPU ---
# Options: "amd", "nvidia", "intel", "none"
GPU_DRIVER="amd"

# --- Feature toggles ---
INSTALL_GAMING=true
INSTALL_VIRTUALIZATION=true
INSTALL_DOCKER=true
INSTALL_HYPRLAND=true
INSTALL_DEV_TOOLS=true
INSTALL_AUR_PACKAGES=true

# --- AUR helper ---
# Options: "paru", "yay"
AUR_HELPER="paru"

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
  mesa-vdpau
  lib32-mesa-vdpau
  xf86-video-amdgpu
  amd-ucode
)

# --- NVIDIA GPU (if needed) ---
NVIDIA_PACKAGES=(
  nvidia
  nvidia-utils
  lib32-nvidia-utils
  nvidia-settings
  vulkan-icd-loader
  lib32-vulkan-icd-loader
  egl-wayland
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
  xwayland
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

# --- Virtualization ---
VIRT_PACKAGES=(
  qemu-full
  virt-manager
  virt-viewer
  libvirt
  swtpm
  dnsmasq
  spice-vdp-agent
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
  # Desktop
  swww
  rofi-wayland
  swappy
  swaync
  greetd-tuigreet-bin
  nwg-displays

  # Terminals
  ghostty

  # Applications
  obsidian
  1password
  spotify

  # Gaming
  protonup-qt
  bottles

  # Theming
  dracula-gtk-theme
  nordzy-icon-theme-git
  nordzy-cursors

  # GPU tools
  amdgpu_top
  rocm-smi-lib

  # CLI
  yazi
  lf

  # Dev
  lazydocker
)
