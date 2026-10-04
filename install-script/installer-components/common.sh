#!/usr/bin/env bash
# common.sh — shared colors, paths and helpers (sourced by every component)

[[ -n "${FLAKE_COMMON_LOADED:-}" ]] && return 0
FLAKE_COMMON_LOADED=1

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────────────────
REPO_DIR="${REPO_DIR:-$HOME/FlakeShell}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_DIR="$HOME/.local"

# ── Logging ───────────────────────────────────────────────────────────────────
header()   { echo -e "\n${BOLD}${BLUE}==> $1${RESET}"; }
log_ok()   { echo -e "  ${GREEN}[OK]${RESET}  $1"; }
log_err()  { echo -e "  ${RED}[FAIL]${RESET}  $1"; }
log_skip() { echo -e "  ${YELLOW}[SKIP]${RESET}  $1"; }
log_info() { echo -e "  ${BLUE}[..]${RESET}  $1"; }

component_banner() {
    echo -e "${BOLD}${BLUE}"
    echo "  ╔══════════════════════════════════════╗"
    printf "  ║ %-36s ║\n" "          FLAKE-OS Installer"
    printf "  ║ %-36s ║\n" "$1"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${RESET}"
}

# y/n prompt — returns 0 on yes
confirm() {
    local a
    while true; do
        read -rp "$(echo -e "  ${YELLOW}$1 [y/n]${RESET} ")" a
        case "$a" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo -e "  ${RED}Please answer y or n${RESET}" ;;
        esac
    done
}

has() { command -v "$1" &>/dev/null; }
