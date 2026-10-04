#!/usr/bin/env bash
# packages.sh
# Installs all required packages for the Hyprland setup

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Pacman.conf ───────────────────────────────────────────────────────────────
sudo rm -rf /etc/pacman.conf
sudo cp -r ~/FlowFiles/pacman.conf /etc/
sudo pacman -Syy

# ── Paru helper ───────────────────────────────────────────────────────────────
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd

# ── Package lists ─────────────────────────────────────────────────────────────
PACMAN_PACKAGES=(
    nvim
    awww
    hyprlock
    xdg-desktop-portal-gnome
    matugen
    cava
    rofi
    curl
    perl
    brightnessctl
    swaync
    swayosd
    wl-clipboard
    cargo
    hyprshot
    cliphist
    rofimoji
    quickshell
    eza
    flatpak
    yazi
    satty
    pavucontrol
    btop
    nwg-look
    gpu-screen-recorder-ui
    zsh
    libcava
    waybar-cava
    fastfetch
    ttf-jetbrains-mono-nerd
    perl-file-mimeinfo
    otf-font-awesome
    zed
    nemo-fileroller
    wf-recorder
)

AUR_PACKAGES=(
    lutgen-studio-bin
    peaclock
    cmatrix-git
    nitch
    wlogout
    bluetuith
    adw-gtk-theme-git
)

# ── Helpers ───────────────────────────────────────────────────────────────────
print_header() {
    echo -e "\n${BOLD}${BLUE}==> $1${RESET}"
}

is_installed() {
    pacman -Qi "$1" &>/dev/null
}

install_pacman() {
    local pkg="$1"
    if is_installed "$pkg"; then
        echo -e "  ${YELLOW}[SKIP]${RESET}  $pkg (already installed)"
    else
        echo -e "  ${BLUE}[INSTALLING]${RESET}  $pkg"
        sudo pacman -S --noconfirm "$pkg"
        if is_installed "$pkg"; then
            echo -e "  ${GREEN}[OK]${RESET}  $pkg"
        else
            echo -e "  ${RED}[FAILED]${RESET}  $pkg"
        fi
    fi
}

install_aur() {
    local pkg="$1"
    if is_installed "$pkg"; then
        echo -e "  ${YELLOW}[SKIP]${RESET}  $pkg (already installed)"
    else
        echo -e "  ${BLUE}[INSTALLING]${RESET}  $pkg"
        yay -S --noconfirm "$pkg"
        if is_installed "$pkg"; then
            echo -e "  ${GREEN}[OK]${RESET}  $pkg"
        else
            echo -e "  ${RED}[FAILED]${RESET}  $pkg"
        fi
    fi
}

# ── Preflight ─────────────────────────────────────────────────────────────────
echo -e "${BOLD}${BLUE}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║           FLOW-OS Installer          ║"
echo "  ║          Package Installation        ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${RESET}"

# Check yay is available
if ! command -v yay &>/dev/null; then
    echo -e "${RED}[ERROR]${RESET} yay not found. Please install yay first."
    exit 1
fi

# ── Install ───────────────────────────────────────────────────────────────────
print_header "Installing pacman packages"
for pkg in "${PACMAN_PACKAGES[@]}"; do
    install_pacman "$pkg"
done

print_header "Installing AUR packages"
for pkg in "${AUR_PACKAGES[@]}"; do
    install_aur "$pkg"
done


# ── Momoisay ──────────────────────────────────────────────────────────────────
git clone https://github.com/Mon4sm/Momoisay.git
cd Momoisay
sudo sh ./install/linux.sh

# ── Impala-NM ─────────────────────────────────────────────────────────────────
cargo install impala-nm

# ── Hyprland-Plugins ──────────────────────────────────────────────────────────

hyprpm update
hyprpm add https://github.com/yayuuu/hyprland-scroll-overview.git
hyprpm update
hyprpm enable scrolloverview

# ── Paru-Packs ────────────────────────────────────────────────────────────────
paru -S vscodium-bin
paru -S fetch-git
paru -S brave-bin

# ── Oh My ZSH ─────────────────────────────────────────────────────────────────
cd
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# ── Power Level 10K ───────────────────────────────────────────────────────────
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# ── Summary ───────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}==> All done!${RESET}"
