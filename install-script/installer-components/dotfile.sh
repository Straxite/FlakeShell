#!/usr/bin/env bash
# dotfile.sh — deploys dotfiles from ~/FlakeShell to their locations

source "${BASH_SOURCE[0]%/*}/common.sh"

component_banner "       Dotfiles Deployment"

[[ -d "$REPO_DIR" ]] || { log_err "Repo not found at $REPO_DIR"; exit 1; }

# deploy <src> <dest> [sudo]   — copies dir contents (or a single file)
deploy() {
    local src="$1" dest="$2" s="${3:-}" name
    name="$(basename "$src")"
    if [[ -d "$src" ]]; then
        $s mkdir -p "$dest" && $s cp -rf "$src/." "$dest/"
    elif [[ -f "$src" ]]; then
        $s mkdir -p "$(dirname "$dest")" && $s cp -f "$src" "$dest"
    else
        log_skip "$name (not found in repo)"; return
    fi
    log_ok "$name  →  $dest${s:+ ${YELLOW}(sudo)${RESET}}"
}

# ── ~/.config ─────────────────────────────────────────────────────────────────
CONFIG_FOLDERS=(
    backgrounds cava colorschemes gtk-3.0 gtk-4.0 hypr kitty matugen nvim
    rofi swaync waybar wlogout fastfetch quickshell quickshell-test
)

header "Deploying ~/.config folders"
if confirm "Copy contents for .config?"; then
    for f in "${CONFIG_FOLDERS[@]}"; do deploy "$REPO_DIR/$f" "$CONFIG_DIR/$f"; done
else
    log_skip ".config"
fi

# ── ~/.local ──────────────────────────────────────────────────────────────────
header "Deploying ~/.local"
if confirm "Copy contents for .local?"; then
    deploy "$REPO_DIR/.local" "$LOCAL_DIR"
else
    log_skip ".local"
fi

# ── Home dotfiles ─────────────────────────────────────────────────────────────
header "Deploying home dotfiles"
if confirm "Copy home dotfiles (.zshrc, .p10k.zsh)?"; then
    deploy "$REPO_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
    deploy "$REPO_DIR/.zshrc"    "$HOME/.zshrc"
else
    log_skip "home dotfiles"
fi

# ── System files ──────────────────────────────────────────────────────────────
header "Deploying system files (requires sudo)"
if [[ -d "$REPO_DIR/etc" || -d "$REPO_DIR/usr" ]]; then
    if confirm "Copy contents for / (etc, usr)?"; then
        deploy "$REPO_DIR/etc" /etc sudo
        deploy "$REPO_DIR/usr" /usr sudo
    else
        log_skip "system files"
    fi
else
    log_skip "no etc/ or usr/ in repo"
fi

echo -e "\n${BOLD}${GREEN}==> Dotfiles deployed!${RESET}\n"
