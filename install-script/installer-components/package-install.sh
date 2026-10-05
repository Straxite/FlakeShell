#!/usr/bin/env bash
# package-install.sh — installs everything for the Flake Hyprland setup

source "${BASH_SOURCE[0]%/*}/common.sh"

# ═════════════════════════════════ CONFIGURE ═════════════════════════════════

# ── Toggles ───────────────────────────────────────────────────────────────────
INSTALL_PACMAN_CONF=true      # replace /etc/pacman.conf with the one from the repo (backed up)
INSTALL_MOMOISAY=true
INSTALL_OH_MY_ZSH=true
INSTALL_POWERLEVEL10K=true

# ── Official repo packages (pacman) ───────────────────────────────────────────
# If a name isn't in the repos it is automatically tried via the AUR instead.
PACMAN_PACKAGES=(
    # Hyprland & desktop
    awww
    hyprlock
    hyprshot
    xdg-desktop-portal-gnome
    quickshell
    swaync
    swayosd
    waybar-cava
    wl-clipboard
    cliphist
    brightnessctl
    rofi
    rofimoji
    matugen
    nwg-look
    wf-recorder

    # Terminal & tools
    neovim
    zsh
    eza
    yazi
    btop
    fastfetch
    curl
    perl
    perl-file-mimeinfo
    cargo
    flatpak

    # Apps & media
    cava
    libcava
    satty
    pavucontrol
    gpu-screen-recorder-ui
    zed
    nemo-fileroller

    # Fonts
    ttf-jetbrains-mono-nerd
    otf-font-awesome
)

# ── AUR packages (yay) ────────────────────────────────────────────────────────
AUR_PACKAGES=(
    lutgen-studio-bin
    peaclock
    cmatrix-git
    nitch
    wlogout
    bluetuith
    adw-gtk-theme-git
    vscodium-bin
    fetch-git
    brave-bin
)

# ── Cargo crates ──────────────────────────────────────────────────────────────
CARGO_PACKAGES=(
    impala-nm
)

# ── Hyprland plugins (hyprpm) ─────────────────────────────────────────────────
HYPR_PLUGIN_REPOS=(
    https://github.com/yayuuu/hyprland-scroll-overview.git
)
HYPR_PLUGINS_ENABLE=(
    scrolloverview
)

# ═════════════════════════════════════════════════════════════════════════════

component_banner "Package Installation"
has yay || { log_err "yay not found — run the installer from orchestra-script.sh"; finish "Package install aborted"; }
ensure_sudo

# install_list <label> <installer-cmd…> -- pkgs…   (one transaction, then verify)
install_list() {
    local label="$1"; shift
    local -a cmd=() pkgs=() todo=()
    while [[ "$1" != "--" ]]; do cmd+=("$1"); shift; done; shift
    pkgs=("$@")
    (( ${#pkgs[@]} )) || { log_skip "$label: nothing listed"; return; }

    mapfile -t todo < <(pacman -T "${pkgs[@]}")
    if (( ${#todo[@]} == 0 )); then
        log_skip "all ${#pkgs[@]} $label packages already installed"; return
    fi
    log_info "installing ${#todo[@]} of ${#pkgs[@]} $label packages"
    printf '%s' "$SLATE"; printf '%s ' "${todo[@]}" | fold -s -w 62 | sed 's/^/       /'; printf '%s\n' "$RESET"
    "${cmd[@]}" "${todo[@]}"

    mapfile -t todo < <(pacman -T "${pkgs[@]}")
    if (( ${#todo[@]} == 0 )); then log_ok "all $label packages installed"
    else for p in "${todo[@]}"; do log_err "$p failed to install"; done; fi
}

# ── pacman.conf ───────────────────────────────────────────────────────────────
if $INSTALL_PACMAN_CONF; then
    section "pacman.conf"
    if [[ -f "$REPO_DIR/pacman.conf" ]]; then
        sudo cp -f /etc/pacman.conf /etc/pacman.conf.flake-backup
        sudo install -m644 "$REPO_DIR/pacman.conf" /etc/pacman.conf
        log_ok "installed (backup: /etc/pacman.conf.flake-backup)"
    else
        log_skip "no pacman.conf in $FLAKE_REPO_NAME"
    fi
fi
sudo pacman -Syy --noconfirm >> "$FLAKE_LOG" 2>&1 && log_ok "package databases synced"

# ── Official repos ────────────────────────────────────────────────────────────
section "Official repositories"
declare -A IN_REPO=()
while read -r p; do IN_REPO[$p]=1; done < <(pacman -Slq)
found=(); missing=()
for p in "${PACMAN_PACKAGES[@]}"; do
    [[ -n "${IN_REPO[$p]:-}" ]] && found+=("$p") || missing+=("$p")
done
(( ${#missing[@]} )) && { log_warn "not in repos, trying AUR: ${missing[*]}"; AUR_PACKAGES+=("${missing[@]}"); }
install_list "repo" sudo pacman -S --needed --noconfirm -- "${found[@]}"

# ── AUR ───────────────────────────────────────────────────────────────────────
section "AUR"
install_list "AUR" yay -S --needed --noconfirm -- "${AUR_PACKAGES[@]}"

# ── Cargo ─────────────────────────────────────────────────────────────────────
if (( ${#CARGO_PACKAGES[@]} )); then
    section "Cargo crates"
    installed_crates="$(cargo install --list 2>/dev/null)"
    for crate in "${CARGO_PACKAGES[@]}"; do
        if [[ "$installed_crates" == *"$crate v"* ]]; then log_skip "$crate (already installed)"
        else spin "$crate" cargo install "$crate"; fi
    done
fi

# ── Momoisay ──────────────────────────────────────────────────────────────────
if $INSTALL_MOMOISAY; then
    section "Momoisay"
    if has momoisay; then
        log_skip "already installed"
    else
        tmp=$(mktemp -d)
        if spin "cloning Momoisay" git clone --depth=1 https://github.com/Mon4sm/Momoisay.git "$tmp/Momoisay"; then
            (cd "$tmp/Momoisay" && sudo sh ./install/linux.sh) && log_ok "Momoisay installed" || log_err "Momoisay install failed"
        fi
        rm -rf "$tmp"
    fi
fi

# ── Hyprland plugins ──────────────────────────────────────────────────────────
if (( ${#HYPR_PLUGIN_REPOS[@]} )); then
    section "Hyprland plugins"
    if has hyprpm; then
        {
            hyprpm update
            for r in "${HYPR_PLUGIN_REPOS[@]}"; do hyprpm add "$r"; done
            hyprpm update
            for pl in "${HYPR_PLUGINS_ENABLE[@]}"; do hyprpm enable "$pl"; done
        } && log_ok "plugins ready" || log_warn "hyprpm failed — re-run this step from inside a Hyprland session"
    else
        log_skip "hyprpm not found"
    fi
fi

# ── Shell ─────────────────────────────────────────────────────────────────────
install_omz() {
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

if $INSTALL_OH_MY_ZSH || $INSTALL_POWERLEVEL10K; then section "Shell"; fi
if $INSTALL_OH_MY_ZSH; then
    if [[ -d "$HOME/.oh-my-zsh" ]]; then log_skip "Oh My Zsh (already installed)"; else spin "Oh My Zsh" install_omz; fi
fi
if $INSTALL_POWERLEVEL10K; then
    if [[ -d "$P10K_DIR" ]]; then log_skip "Powerlevel10k (already installed)"
    else spin "Powerlevel10k" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"; fi
fi

finish "Packages done"
