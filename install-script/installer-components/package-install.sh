#!/usr/bin/env bash
# package-install.sh — installs everything for the Flake Hyprland setup

source "${BASH_SOURCE[0]%/*}/common.sh"

component_banner "      Package Installation"

has yay || { log_err "yay not found. Run the installer from orchestra-script.sh."; exit 1; }

# ── Package lists ─────────────────────────────────────────────────────────────
PACMAN_PACKAGES=(
    neovim awww hyprlock xdg-desktop-portal-gnome matugen cava rofi curl perl
    brightnessctl swaync swayosd wl-clipboard cargo hyprshot cliphist rofimoji
    quickshell eza flatpak yazi satty pavucontrol btop nwg-look
    gpu-screen-recorder-ui zsh libcava waybar-cava fastfetch
    ttf-jetbrains-mono-nerd perl-file-mimeinfo otf-font-awesome zed
    nemo-fileroller wf-recorder
)

AUR_PACKAGES=(
    lutgen-studio-bin peaclock cmatrix-git nitch wlogout bluetuith
    adw-gtk-theme-git vscodium-bin fetch-git brave-bin
)

# ── pacman.conf (backed up, not nuked) ────────────────────────────────────────
header "Installing pacman.conf"
if [[ -f "$REPO_DIR/pacman.conf" ]]; then
    sudo cp -f /etc/pacman.conf /etc/pacman.conf.flake-backup
    sudo install -m644 "$REPO_DIR/pacman.conf" /etc/pacman.conf
    log_ok "pacman.conf installed (backup: pacman.conf.flake-backup)"
else
    log_skip "no pacman.conf in repo"
fi
sudo pacman -Syy --noconfirm

# ── Official repo packages: ONE transaction ───────────────────────────────────
# Anything not found in the repos is bumped over to the AUR list, so one bad
# name can't abort the whole install.
header "Installing pacman packages"
mapfile -t repo_pkgs < <(pacman -Slq | sort -u)
found=(); missing=()
for p in "${PACMAN_PACKAGES[@]}"; do
    if printf '%s\n' "${repo_pkgs[@]}" | grep -qx -- "$p"; then found+=("$p"); else missing+=("$p"); fi
done
(( ${#missing[@]} )) && { log_info "not in repos, trying AUR: ${missing[*]}"; AUR_PACKAGES+=("${missing[@]}"); }
sudo pacman -S --needed --noconfirm "${found[@]}" || log_err "some pacman packages failed"

# ── AUR packages: ONE yay call ────────────────────────────────────────────────
header "Installing AUR packages"
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}" || log_err "some AUR packages failed"

# ── Source / cargo extras ─────────────────────────────────────────────────────
header "Momoisay"
if has momoisay; then
    log_skip "already installed"
else
    tmp=$(mktemp -d)
    git clone --depth=1 https://github.com/Mon4sm/Momoisay.git "$tmp/Momoisay" \
        && (cd "$tmp/Momoisay" && sudo sh ./install/linux.sh)
    rm -rf "$tmp"
fi

header "Impala-NM"
if has impala; then log_skip "already installed"; else cargo install impala-nm; fi

header "Hyprland plugins"
if has hyprpm; then
    hyprpm update
    hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git
    hyprpm enable scrolloverview
else
    log_skip "hyprpm not found"
fi

# ── Oh My Zsh + Powerlevel10k ─────────────────────────────────────────────────
header "Oh My Zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_skip "already installed"
else
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

header "Powerlevel10k"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ -d "$P10K_DIR" ]]; then
    log_skip "already installed"
else
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

echo -e "\n${BOLD}${GREEN}==> Packages done!${RESET}"
