#!/usr/bin/env bash
# deploy-files.sh
# Deploys all dotfiles from ~/FlowFiles to their designated locations

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
REPO_DIR="$HOME/FlowFiles"
CONFIG_DIR="$HOME/.config"
LOCAL_DIR="$HOME/.local"
HOME_DIR="$HOME"

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
    echo -e "\n${BOLD}${BLUE}==> $1${RESET}"
}

deploy_dir() {
    local src="$1"
    local dest="$2"
    local name="$(basename "$src")"

    if [ ! -d "$src" ]; then
        echo -e "  ${RED}[MISSING]${RESET}  $name (not found in repo, skipping)"
        return
    fi

    mkdir -p "$dest"
    cp -rf "$src/." "$dest/"
    echo -e "  ${GREEN}[OK]${RESET}  $name  →  $dest"
}

deploy_file() {
    local src="$1"
    local dest="$2"
    local name="$(basename "$src")"

    if [ ! -f "$src" ]; then
        echo -e "  ${RED}[MISSING]${RESET}  $name (not found in repo, skipping)"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    cp -f "$src" "$dest"
    echo -e "  ${GREEN}[OK]${RESET}  $name  →  $dest"
}

deploy_root_dir() {
    local src="$1"
    local dest="$2"
    local name="$(basename "$src")"

    if [ ! -d "$src" ]; then
        echo -e "  ${RED}[MISSING]${RESET}  $name (not found in repo, skipping)"
        return
    fi

    sudo mkdir -p "$dest"
    sudo cp -rf "$src/." "$dest/"
    echo -e "  ${GREEN}[OK]${RESET}  $name  →  $dest ${YELLOW}(sudo)${RESET}"
}

confirm_copy() {
    local label="$1"
    local answer

    while true; do
        read -rp "$(echo -e "  ${YELLOW}Do you want to copy the contents for ${label}? [y/n]${RESET} ")" answer
        case "$answer" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "  ${RED}Please answer y or n${RESET}" ;;
        esac
    done
}

# ── Preflight ─────────────────────────────────────────────────────────────────
echo -e "${BOLD}${BLUE}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║           FLOW-OS Installer          ║"
echo "  ║          Dotfiles Deployment         ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${RESET}"

if [ ! -d "$REPO_DIR" ]; then
    echo -e "${RED}[ERROR]${RESET} Repo not found at $REPO_DIR"
    echo -e "        Please clone it first:  git clone <your-repo-url> ~/FlowFiles"
    exit 1
fi

# ── Deploy ~/.config folders ──────────────────────────────────────────────────
print_header "Deploying ~/.config folders"

CONFIG_FOLDERS=(
    backgrounds
    cava
    colorschemes
    gtk-3.0
    gtk-4.0
    hypr
    kitty
    matugen
    nvim
    rofi
    swaync
    waybar
    wlogout
    fastfetch
    quickshell
    quickshell-test
)

if confirm_copy ".config"; then
    for folder in "${CONFIG_FOLDERS[@]}"; do
        deploy_dir "$REPO_DIR/$folder" "$CONFIG_DIR/$folder"
    done
else
    echo -e "  ${YELLOW}[SKIP]${RESET}  Skipped .config deployment"
fi

# ── Deploy ~/.local ───────────────────────────────────────────────────────────
print_header "Deploying ~/.local"
if confirm_copy ".local"; then
    deploy_dir "$REPO_DIR/.local" "$LOCAL_DIR"
else
    echo -e "  ${YELLOW}[SKIP]${RESET}  Skipped .local deployment"
fi

# ── Deploy home dotfiles ──────────────────────────────────────────────────────
print_header "Deploying home dotfiles"
if confirm_copy "home dotfiles (.zshrc, .p10k.zsh)"; then
    deploy_file "$REPO_DIR/.p10k.zsh" "$HOME_DIR/.p10k.zsh"
    deploy_file "$REPO_DIR/.zshrc"    "$HOME_DIR/.zshrc"
else
    echo -e "  ${YELLOW}[SKIP]${RESET}  Skipped home dotfiles deployment"
fi

# ── Deploy system files (SDDM theme etc.) ──────────────────────────────────────
print_header "Deploying system files (requires sudo)"
if [ -d "$REPO_DIR/etc" ] || [ -d "$REPO_DIR/usr" ]; then
    if confirm_copy "/"; then
        echo -e "  ${YELLOW}[SUDO]${RESET}  Root-owned paths ahead, you may be prompted for your password"
        deploy_root_dir "$REPO_DIR/etc" "/etc"
        deploy_root_dir "$REPO_DIR/usr" "/usr"
    else
        echo -e "  ${YELLOW}[SKIP]${RESET}  Skipped / deployment"
    fi
else
    echo -e "  ${YELLOW}[SKIP]${RESET}  No etc/ or usr/ folders found in repo, skipping system deploy"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}==> All files deployed successfully!${RESET}\n"
