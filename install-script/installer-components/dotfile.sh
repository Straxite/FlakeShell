#!/usr/bin/env bash
# dotfile.sh — deploys dotfiles from ~/FlakeShell to their locations

source "${BASH_SOURCE[0]%/*}/common.sh"

# ═════════════════════════════════ CONFIGURE ═════════════════════════════════

# Folders copied from <repo>/<name>  →  ~/.config/<name>
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

# Folder copied from <repo>/<name>  →  ~/.local
LOCAL_FOLDER=".local"

# Files copied from <repo>/<file>  →  ~/<file>
HOME_FILES=(
    .zshrc
    .p10k.zsh
)

# System folders ("repo-folder|destination") — needs sudo
SYSTEM_FOLDERS=(
    "etc|/etc"
    "usr|/usr"
)

# ═════════════════════════════════════════════════════════════════════════════

component_banner "Dotfiles Deployment"
[[ -d "$REPO_DIR" ]] || { log_err "Repo not found at $REPO_DIR"; echo "      git clone $FLAKE_REPO_URL ~/$FLAKE_REPO_NAME"; finish "Dotfiles aborted"; }

DEPLOYED=0; MISSING=0

# deploy <src> <dest> [sudo]
deploy() {
    local src="$1" dest="$2" s="${3:-}" name; name="$(basename "$src")"
    if [[ -d "$src" ]]; then
        $s mkdir -p "$dest" && $s cp -rf "$src/." "$dest/"
    elif [[ -f "$src" ]]; then
        $s mkdir -p "$(dirname "$dest")" && $s cp -f "$src" "$dest"
    else
        printf '  %s!%s  %s%s  (not in repo)%s\n' "$GOLD" "$RESET" "$SLATE" "$name" "$RESET"
        MISSING=$((MISSING + 1)); return
    fi
    printf '  %s✓%s  %-18s %s→%s %s%s%s\n' "$AQUA" "$RESET" "$name" "$SLATE" "$RESET" "$ICE" "$dest" "$RESET"
    DEPLOYED=$((DEPLOYED + 1))
}

# ── ~/.config ─────────────────────────────────────────────────────────────────
section "~/.config"
if confirm "Copy ${#CONFIG_FOLDERS[@]} config folders?"; then
    for f in "${CONFIG_FOLDERS[@]}"; do deploy "$REPO_DIR/$f" "$CONFIG_DIR/$f"; done
else log_skip ".config skipped"; fi

# ── ~/.local ──────────────────────────────────────────────────────────────────
section "~/.local"
if confirm "Copy $LOCAL_FOLDER?"; then deploy "$REPO_DIR/$LOCAL_FOLDER" "$LOCAL_DIR"
else log_skip ".local skipped"; fi

# ── Home dotfiles ─────────────────────────────────────────────────────────────
section "Home dotfiles"
if confirm "Copy ${HOME_FILES[*]}?"; then
    for f in "${HOME_FILES[@]}"; do deploy "$REPO_DIR/$f" "$HOME/$f"; done
else log_skip "home dotfiles skipped"; fi

# ── System files ──────────────────────────────────────────────────────────────
section "System files"
has_sys=false
for e in "${SYSTEM_FOLDERS[@]}"; do [[ -d "$REPO_DIR/${e%%|*}" ]] && has_sys=true; done
if $has_sys; then
    if confirm "Copy system folders (needs sudo)?"; then
        ensure_sudo
        for e in "${SYSTEM_FOLDERS[@]}"; do deploy "$REPO_DIR/${e%%|*}" "${e##*|}" sudo; done
    else log_skip "system files skipped"; fi
else log_skip "no system folders in repo"; fi

echo; hr
log_info "$DEPLOYED deployed"
(( MISSING > 0 )) && { log_warn "$MISSING not found in repo (skipped)"; }
finish "Dotfiles deployed"
