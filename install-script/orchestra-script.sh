#!/usr/bin/env bash
# orchestra-script.sh — main entry point for the Flake OS installer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMP_DIR="$SCRIPT_DIR/installer-components"
source "$COMP_DIR/common.sh"

# ═════════════════════════════════ CONFIGURE ═════════════════════════════════
# Steps run (in this order) by the menu and by "Run full installation".
# Format:  "Menu label|Title|script inside installer-components/"
STEPS=(
    "Install packages|Package Installation|package-install.sh"
    "Deploy dotfiles|Dotfiles Deployment|dotfile.sh"
    "Make scripts executable|Executable Scripts|executable.sh"
    "Refresh configs|Refreshing Configs|refresher.sh"
)
# ═════════════════════════════════════════════════════════════════════════════

: > "$FLAKE_LOG"

# ── Preflight ─────────────────────────────────────────────────────────────────
preflight_check() {
    clear_screen; print_banner
    section "Preflight"
    ensure_sudo || exit 1

    has pacman && log_ok "pacman found" || { log_err "pacman not found — this installer is for Arch Linux"; exit 1; }

    if has git; then log_ok "git is installed"
    else
        log_info "git not found — installing…"
        sudo pacman -S --needed --noconfirm git
        has git && log_ok "git installed" || { log_err "failed to install git"; exit 1; }
    fi

    if has yay; then log_ok "yay is installed"
    else
        log_info "yay not found — installing…"
        sudo pacman -S --needed --noconfirm base-devel
        local tmp; tmp=$(mktemp -d)
        git clone --depth=1 https://aur.archlinux.org/yay.git "$tmp/yay" \
            && (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
        has yay && log_ok "yay installed" || { log_err "failed to install yay"; exit 1; }
    fi

    if [[ -d "$REPO_DIR" ]]; then log_ok "$FLAKE_REPO_NAME found at $REPO_DIR"
    else
        log_err "$FLAKE_REPO_NAME not found at $REPO_DIR"
        printf '\n  %sClone your repo first:%s\n  %sgit clone <your-repo-url> ~/%s%s\n\n' "$GOLD" "$RESET" "$SLATE" "$FLAKE_REPO_NAME" "$RESET"
        exit 1
    fi

    echo; printf '  %s❄  All checks passed!%s\n' "$AQUA$BOLD" "$RESET"
    sleep 0.8
}

# ── Runners ───────────────────────────────────────────────────────────────────
run_component() {  # run_component <script>
    local f="$COMP_DIR/$1"
    [[ -f "$f" ]] || { log_err "script not found: $f"; return 1; }
    bash "$f"
}

run_step() {  # run_step <index>
    local label title file
    IFS='|' read -r label title file <<< "${STEPS[$1]}"
    clear_screen; print_banner
    run_component "$file"
    press_enter
}

run_full_install() {
    local n=${#STEPS[@]} i label title file failed=()
    clear_screen; print_banner
    section "Full installation"
    for i in "${!STEPS[@]}"; do
        IFS='|' read -r label title file <<< "${STEPS[$i]}"
        printf '    %s%d%s  %s\n' "$SKY" $((i + 1)) "$RESET" "$label"
    done
    echo
    confirm "Run all $n steps?" || return

    for ((i = 0; i < n; i++)); do
        IFS='|' read -r label title file <<< "${STEPS[$i]}"
        clear_screen; print_banner
        printf '  %sStep %d of %d%s\n' "$BOLD$ICE" $((i + 1)) "$n" "$RESET"
        progress "$i" "$n"
        run_component "$file" || failed+=("$title")
        sleep 0.6
    done

    clear_screen; print_banner
    progress "$n" "$n"; echo
    if (( ${#failed[@]} == 0 )); then
        box "$AQUA" "" "Installation Complete!" "" "Reboot your system so all" "changes take effect." ""
    else
        box "$ROSE" "" "Finished with errors" "" "${failed[@]}" "" "Log: $FLAKE_LOG" ""
    fi
    press_enter
}

# ── Entry point ───────────────────────────────────────────────────────────────
preflight_check

labels=()
for s in "${STEPS[@]}"; do labels+=("${s%%|*}"); done
FULL=${#STEPS[@]}; EXIT=$((FULL + 1))

while true; do
    clear_screen; print_banner
    menu_select "What would you like to do?" "${labels[@]}" "Run full installation" "Exit"
    choice=$MENU_RESULT
    if   (( choice == -1 || choice == EXIT )); then
        clear_screen; print_banner
        printf '  %s❄  Stay frosty. Goodbye!%s\n\n' "$ICE" "$RESET"; exit 0
    elif (( choice == FULL )); then run_full_install
    else run_step "$choice"; fi
done
