#!/usr/bin/env bash
# orchestra-script.sh — main entry point for the Flake OS installer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMP_DIR="$SCRIPT_DIR/installer-components"
source "$COMP_DIR/common.sh"

# ── Steps: label|script (single source of truth for menu + full install) ──────
STEPS=(
    "Installing Packages|package-install.sh"
    "Deploying Dotfiles|dotfile.sh"
    "Making Scripts Executable|executable.sh"
    "Refreshing Configs|refresher.sh"
)
MENU_LABELS=("Install packages" "Deploy dotfiles" "Make scripts executable" "Refresh Configs")

# ── UI ────────────────────────────────────────────────────────────────────────
print_banner() {
    printf '\033[2J\033[H'
    echo -e "${BOLD}${BLUE}"
    echo "      ███████╗██╗      █████╗ ██╗  ██╗███████╗"
    echo "      ██╔════╝██║     ██╔══██╗██║ ██╔╝██╔════╝"
    echo "      █████╗  ██║     ███████║█████╔╝ █████╗  "
    echo "      ██╔══╝  ██║     ██╔══██║██╔═██╗ ██╔══╝  "
    echo "      ██║     ███████╗██║  ██║██║  ██╗███████╗"
    echo "      ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝"
    echo -e "${RESET}"
    echo -e "${DIM}              OS Installer v1.0${RESET}"
    echo -e "${BLUE}      ──────────────────────────────────────${RESET}\n"
}

print_header() {
    echo -e "\n${BOLD}${CYAN}  ┌─ $1 ${RESET}"
    echo -e "${CYAN}  └────────────────────────────────────${RESET}\n"
}

prompt_enter() { echo -e "\n  ${DIM}Press Enter to return to menu...${RESET}"; read -r; }

# ── Preflight ─────────────────────────────────────────────────────────────────
preflight_check() {
    print_banner
    print_header "Preflight Check"
    sudo -v || exit 1   # cache sudo once up front

    if has git; then log_ok "git is installed"
    else
        log_info "git not found — installing..."
        sudo pacman -S --needed --noconfirm git
        has git && log_ok "git installed" || { log_err "Failed to install git"; exit 1; }
    fi

    if has yay; then log_ok "yay is installed"
    else
        log_info "yay not found — installing..."
        sudo pacman -S --needed --noconfirm base-devel
        local tmp; tmp=$(mktemp -d)
        git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay" \
            && (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
        has yay && log_ok "yay installed" || { log_err "Failed to install yay"; exit 1; }
    fi

    if [[ -d "$REPO_DIR" ]]; then
        log_ok "FlakeShell repo found at $REPO_DIR"
    else
        log_err "FlakeShell not found at $REPO_DIR"
        echo -e "\n  ${YELLOW}Please clone your repo first:${RESET}"
        echo -e "  ${DIM}git clone <your-repo-url> ~/FlakeShell${RESET}\n"
        exit 1
    fi

    echo -e "\n  ${GREEN}${BOLD}All checks passed!${RESET}"
    prompt_enter
}

# ── Runners ───────────────────────────────────────────────────────────────────
run_script() {  # run_script <label> <file>  → returns component exit code
    local label="$1" file="$COMP_DIR/$2"
    if [[ ! -f "$file" ]]; then log_err "Script not found: $file"; return 1; fi
    bash "$file"
}

run_step() {
    local label="${STEPS[$1]%%|*}" file="${STEPS[$1]##*|}"
    print_banner; print_header "$label"
    run_script "$label" "$file"; local code=$?
    echo -e "\n  ${BLUE}─────────────────────────────────────────${RESET}"
    if (( code == 0 )); then echo -e "  ${GREEN}${BOLD}✓ $label completed.${RESET}"
    else echo -e "  ${RED}${BOLD}✗ $label finished with errors.${RESET}"; fi
    prompt_enter
}

run_full_install() {
    print_banner; print_header "Full Installation"
    echo -e "  This will run all steps in order:\n"
    local i=1 s
    for s in "${STEPS[@]}"; do echo -e "    ${CYAN}$i.${RESET} ${s%%|*}"; ((i++)); done
    echo -ne "\n  ${BOLD}Continue? [y/N]:${RESET} "
    read -r confirm_ans
    [[ "$confirm_ans" =~ ^[Yy]$ ]] || return

    local n=${#STEPS[@]}
    for ((i = 0; i < n; i++)); do
        print_banner; print_header "Step $((i + 1)) of $n — ${STEPS[$i]%%|*}"
        run_script "${STEPS[$i]%%|*}" "${STEPS[$i]##*|}"
    done

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

show_menu() {
    print_banner
    echo -e "  ${BOLD}What would you like to do?${RESET}\n"
    local i
    for i in "${!MENU_LABELS[@]}"; do echo -e "    ${CYAN}[$((i + 1))]${RESET}  ${MENU_LABELS[$i]}"; done
    local full=$(( ${#MENU_LABELS[@]} + 1 ))
    echo -e "    ${CYAN}[$full]${RESET}  Run full installation"
    echo -e "    ${CYAN}[$((full + 1))]${RESET}  Exit\n"
    echo -e "  ${BLUE}─────────────────────────────────────────${RESET}"
    echo -ne "\n  ${BOLD}Choose an option [1-$((full + 1))]:${RESET} "
}

# ── Entry point ───────────────────────────────────────────────────────────────
preflight_check

while true; do
    show_menu
    read -r choice
    full=$(( ${#MENU_LABELS[@]} + 1 ))
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#STEPS[@]} )); then
        run_step $((choice - 1))
    elif [[ "$choice" == "$full" ]]; then
        run_full_install
    elif [[ "$choice" == "$((full + 1))" ]]; then
        print_banner; echo -e "  ${DIM}Goodbye!${RESET}\n"; exit 0
    else
        echo -e "\n  ${RED}Invalid option.${RESET}"; sleep 1
    fi
done
