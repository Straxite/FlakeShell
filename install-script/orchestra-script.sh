#!/usr/bin/env bash
# orchestra-script.sh
# Main entry point for the Flow OS installer

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
SCRIPT_DIR="${BASH_SOURCE[0]%/*}"
REPO_DIR="$HOME/FlakeShell"

# ── Helpers ───────────────────────────────────────────────────────────────────
clear_screen() { printf '\033[2J\033[H'; }

print_banner() {
    clear_screen
    echo -e "${BOLD}${BLUE}"
    echo "      ███████╗██╗      ██████╗ ██╗    ██╗"
    echo "      ██╔════╝██║     ██╔═══██╗██║    ██║"
    echo "      █████╗  ██║     ██║   ██║██║ █╗ ██║"
    echo "      ██╔══╝  ██║     ██║   ██║██║███╗██║"
    echo "      ██║     ███████╗╚██████╔╝╚███╔███╔╝"
    echo "      ╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝ "
    echo -e "${RESET}"
    echo -e "${DIM}              OS Installer v1.0${RESET}"
    echo -e "${BLUE}      ─────────────────────────────────${RESET}"
    echo ""
}

print_header() {
    echo -e "\n${BOLD}${CYAN}  ┌─ $1 ${RESET}"
    echo -e "${CYAN}  └────────────────────────────────────${RESET}\n"
}

log_ok()   { echo -e "    ${GREEN}✓${RESET}  $1"; }
log_err()  { echo -e "    ${RED}✗${RESET}  $1"; }
log_skip() { echo -e "    ${YELLOW}~${RESET}  $1"; }
log_info() { echo -e "    ${BLUE}·${RESET}  $1"; }

prompt_enter() {
    echo ""
    echo -e "  ${DIM}Press Enter to return to menu...${RESET}"
    read -r
}

# ── Preflight check ───────────────────────────────────────────────────────────
preflight_check() {
    print_banner
    print_header "Preflight Check"

    # git
    if command -v git &>/dev/null; then
        log_ok "git is installed"
    else
        log_info "git not found — installing..."
        sudo pacman -S --noconfirm git
        if command -v git &>/dev/null; then
            log_ok "git installed successfully"
        else
            log_err "Failed to install git — cannot continue"
            exit 1
        fi
    fi

    # yay
    if command -v yay &>/dev/null; then
        log_ok "yay is installed"
    else
        log_info "yay not found — installing..."
        sudo pacman -S --noconfirm --needed base-devel
        local tmp_dir
        tmp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
        (cd "$tmp_dir/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp_dir"
        if command -v yay &>/dev/null; then
            log_ok "yay installed successfully"
        else
            log_err "Failed to install yay — cannot continue"
            exit 1
        fi
    fi

    # FlowFiles repo
    if [ -d "$REPO_DIR" ]; then
        log_ok "FlowFiles repo found at $REPO_DIR"
    else
        log_err "FlowFiles not found at $REPO_DIR"
        echo ""
        echo -e "  ${YELLOW}Please clone your repo first:${RESET}"
        echo -e "  ${DIM}git clone <your-repo-url> ~/FlowFiles${RESET}"
        echo ""
        exit 1
    fi

    echo ""
    echo -e "  ${GREEN}${BOLD}All checks passed!${RESET}"
    prompt_enter
}

# ── Step runner ───────────────────────────────────────────────────────────────
run_step() {
    local label="$1"
    local script="$2"

    print_banner
    print_header "$label"

    if [ ! -f "$script" ]; then
        log_err "Script not found: $script"
        prompt_enter
        return 1
    fi

    bash "$script"
    local code=$?

    echo ""
    echo -e "  ${BLUE}─────────────────────────────────────────${RESET}"
    if [ $code -eq 0 ]; then
        echo -e "  ${GREEN}${BOLD}✓ $label completed.${RESET}"
    else
        echo -e "  ${RED}${BOLD}✗ $label finished with errors.${RESET}"
    fi

    prompt_enter
}

# ── Full install ──────────────────────────────────────────────────────────────
run_full_install() {
    print_banner
    print_header "Full Installation"

    echo -e "  This will run all steps in order:\n"
    echo -e "    ${CYAN}1.${RESET} Install all packages"
    echo -e "    ${CYAN}2.${RESET} Deploy dotfiles"
    echo -e "    ${CYAN}3.${RESET} Make scripts executable"
    echo -e "    ${CYAN}4.${RESET} Refresh configs"
    echo ""
    echo -e -n "  ${BOLD}Continue? [y/N]:${RESET} "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    # Step 1
    print_banner
    print_header "Step 1 of 4 — Installing Packages"
    bash "$SCRIPT_DIR/packages.sh"

    # Step 2
    print_banner
    print_header "Step 2 of 4 — Deploying DotFiles"
    bash "$SCRIPT_DIR/setup.sh"

    # Step 3
    print_banner
    print_header "Step 3 of 4 — Making Scripts Executable"
    bash "$SCRIPT_DIR/executable-maker.sh"

    # Step 3
    print_banner
    print_header "Step 4 of 4 — Refreshing Configs"
    bash "$SCRIPT_DIR/refresher.sh"

    # Done
    print_banner
    echo -e "  ${GREEN}${BOLD}"
    echo "      ╔══════════════════════════════════════╗"
    echo "      ║                                      ║"
    echo "      ║     ✓  Installation Complete!        ║"
    echo "      ║                                      ║"
    echo "      ║   Please reboot your system for      ║"
    echo "      ║   all changes to take effect.        ║"
    echo "      ║                                      ║"
    echo "      ╚══════════════════════════════════════╝"
    echo -e "  ${RESET}"
    prompt_enter
}

# ── Menu ──────────────────────────────────────────────────────────────────────
show_menu() {
    print_banner
    echo -e "  ${BOLD}What would you like to do?${RESET}\n"
    echo -e "    ${CYAN}[1]${RESET}  Install packages"
    echo -e "    ${CYAN}[2]${RESET}  Deploy dotfiles"
    echo -e "    ${CYAN}[3]${RESET}  Make scripts executable"
    echo -e "    ${CYAN}[4]${RESET}  Refresh Configs"
    echo -e "    ${CYAN}[5]${RESET}  Run full installation"
    echo -e "    ${CYAN}[6]${RESET}  Exit"
    echo ""
    echo -e "  ${BLUE}─────────────────────────────────────────${RESET}"
    echo -e -n "\n  ${BOLD}Choose an option [1-6]:${RESET} "
}

# ── Entry point ───────────────────────────────────────────────────────────────
preflight_check

while true; do
    show_menu
    read -r choice

    case "$choice" in
        1) run_step "Installing Packages"       "$SCRIPT_DIR/packages.sh" ;;
        2) run_step "Deploying Dotfiles"        "$SCRIPT_DIR/setup.sh" ;;
        3) run_step "Making Scripts Executable" "$SCRIPT_DIR/executable-maker.sh" ;;
        4) run_step "Refreshing Configs"        "$SCRIPT_DIR/refresher.sh" ;;
        5) run_full_install ;;
        6)
            print_banner
            echo -e "  ${DIM}Goodbye!${RESET}\n"
            exit 0
            ;;
        *)
            echo -e "\n  ${RED}Invalid option. Please choose 1-6.${RESET}"
            sleep 1
            ;;
    esac
done
