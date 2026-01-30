#!/usr/bin/env bash
# ==============================================================================
# Tmux Setup Script
# ==============================================================================
# Installs TPM, writes .tmux.conf (matching nixos-pb/modules/tmux.nix),
# and installs plugins.
#
# Usage:
#   ./tmux-setup.sh
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[+]${NC} $*"; }
info() { echo -e "${CYAN}[*]${NC} $*"; }
err()  { echo -e "${RED}[ERROR]${NC} $*" >&2; }

TPM_DIR="${HOME}/.tmux/plugins/tpm"
TMUX_CONF="${HOME}/.tmux.conf"

# --- Install TPM ---
if [[ -d "${TPM_DIR}" ]]; then
    log "TPM already installed."
else
    info "Cloning TPM..."
    git clone https://github.com/tmux-plugins/tpm "${TPM_DIR}"
    log "TPM installed."
fi

# --- Write .tmux.conf ---
log "Writing ${TMUX_CONF}..."
cat > "${TMUX_CONF}" << 'EOF'
# Shell & terminal
set -g default-shell /usr/bin/zsh
set -g default-terminal "tmux-256color"
set -g history-limit 100000

# True color
set -ag terminal-overrides ",xterm-256color:RGB"

# Mouse
set -g mouse on

# Vim style pane selection
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# Use Alt-arrow keys without prefix key to switch panes
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R

# Alt+1-9 to switch windows
bind -n M-1 select-window -t 1
bind -n M-2 select-window -t 2
bind -n M-3 select-window -t 3
bind -n M-4 select-window -t 4
bind -n M-5 select-window -t 5
bind -n M-6 select-window -t 6
bind -n M-7 select-window -t 7
bind -n M-8 select-window -t 8
bind -n M-9 select-window -t 9

# Shift arrow to switch windows
bind -n S-Left  previous-window
bind -n S-Right next-window

# Plugins (TPM)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'christoomey/vim-tmux-navigator'
set -g @plugin 'janoamaral/tokyo-night-tmux'
set -g @plugin 'nhdaly/tmux-better-mouse-mode'

# Initialize TPM (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
EOF
log ".tmux.conf written."

# --- Install plugins via TPM ---
info "Installing tmux plugins..."
"${TPM_DIR}/bin/install_plugins"
log "Plugins installed."

echo ""
log "Tmux setup complete. Start a new tmux session to use."
