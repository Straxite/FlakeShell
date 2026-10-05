#!/usr/bin/env bash
# common.sh — Flake theme, helpers and arrow-key menus (sourced by every script)

[[ -n "${FLAKE_COMMON_LOADED:-}" ]] && return 0
FLAKE_COMMON_LOADED=1

# ═════════════════════════════════ CONFIGURE ═════════════════════════════════
FLAKE_VERSION="1.0"
FLAKE_REPO_NAME="FlakeShell"                      # repo folder in $HOME
FLAKE_LOG="${FLAKE_LOG:-/tmp/flake-install.log}"  # output of quiet/spinner tasks
RULE_W=46                                         # width of rules / headers
# ═════════════════════════════════════════════════════════════════════════════

# Repo location: auto-detected from where these scripts live (works through
# the flakeinstall/flakeupdate symlinks), else ~/$FLAKE_REPO_NAME
_here="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
[[ "$_here" == */install-script/installer-components ]] && REPO_DIR="${_here%/install-script/installer-components}"
REPO_DIR="${REPO_DIR:-$HOME/$FLAKE_REPO_NAME}"
export REPO_DIR
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/flakeshell"   # install record + backups
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_DIR="$HOME/.local"

# ── Winter palette (truecolor) ────────────────────────────────────────────────
rgb() { printf '\e[38;2;%s;%s;%sm' "$1" "$2" "$3"; }
SNOW=$(rgb 245 250 255)    # snow white
FROST=$(rgb 214 236 255)   # frost
ICE=$(rgb 165 216 255)     # ice blue
SKY=$(rgb 116 185 255)     # winter sky
DEEP=$(rgb 74 144 217)     # deep glacier
SLATE=$(rgb 112 136 166)   # muted slate
AQUA=$(rgb 142 240 214)    # success (aurora mint)
ROSE=$(rgb 255 143 163)    # error (winter berry)
GOLD=$(rgb 255 224 150)    # warning (candlelight)
BOLD=$'\e[1m'; DIM=$'\e[2m'; RESET=$'\e[0m'

ERR_COUNT=0

hide_cursor() { printf '\e[?25l'; }
show_cursor() { printf '\e[?25h'; }
trap show_cursor EXIT
trap 'show_cursor; echo; exit 130' INT TERM

# ── Logging ───────────────────────────────────────────────────────────────────
log_ok()   { printf '  %s✓%s  %s\n' "$AQUA" "$RESET" "$1"; }
log_err()  { printf '  %s✗%s  %s\n' "$ROSE" "$RESET" "$1"; ERR_COUNT=$((ERR_COUNT + 1)); }
log_warn() { printf '  %s!%s  %s\n' "$GOLD" "$RESET" "$1"; }
log_skip() { printf '  %s~%s  %s%s%s\n' "$GOLD" "$RESET" "$SLATE" "$1" "$RESET"; }
log_info() { printf '  %s·%s  %s\n' "$SKY" "$RESET" "$1"; }

# ── Layout ────────────────────────────────────────────────────────────────────
clear_screen() { printf '\e[2J\e[H'; }

hr() {  # hr [color]
    local s; printf -v s '%*s' "$RULE_W" ''
    printf '  %s%s%s\n' "${1:-$SLATE}" "${s// /─}" "$RESET"
}

section() {  # section "Title"  →  ❄  Title ────────
    local t="$1" pad s
    pad=$(( RULE_W - ${#t} - 4 )); (( pad < 3 )) && pad=3
    printf -v s '%*s' "$pad" ''
    printf '\n  %s❄%s  %s%s%s %s%s%s\n' "$SKY" "$RESET" "$BOLD$FROST" "$t" "$RESET" "$SLATE" "${s// /─}" "$RESET"
}

snow_line() {
    local i out="" f=(❄ ❅ ❆ · ✦ '*' ·)
    for ((i = 0; i < RULE_W + 6; i++)); do
        if (( RANDOM % 8 == 0 )); then out+="${f[RANDOM % ${#f[@]}]}"; else out+=" "; fi
    done
    printf '%s%s%s%s\n' "$DIM" "$ICE" "$out" "$RESET"
}

BANNER_ART=(
"███████╗██╗      █████╗ ██╗  ██╗███████╗"
"██╔════╝██║     ██╔══██╗██║ ██╔╝██╔════╝"
"█████╗  ██║     ███████║█████╔╝ █████╗  "
"██╔══╝  ██║     ██╔══██║██╔═██╗ ██╔══╝  "
"██║     ███████╗██║  ██║██║  ██╗███████╗"
"╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝"
)
BANNER_GRAD=("245;250;255" "214;236;255" "180;222;255" "145;202;255" "110;176;245" "74;144;217")

print_banner() {
    local i
    echo; snow_line; snow_line; echo
    for i in "${!BANNER_ART[@]}"; do
        printf '        \e[38;2;%sm%s%s\n' "${BANNER_GRAD[i]}" "${BANNER_ART[i]}" "$RESET"
    done
    echo
    printf '          %s❄  %sOS Installer%s  ·  v%s  %s❄%s\n\n' "$SKY" "$BOLD$ICE" "$RESET$ICE" "$FLAKE_VERSION" "$SKY" "$RESET"
    hr "$DEEP"; snow_line; echo
}

component_banner() {  # component_banner "Title"
    echo; hr "$DEEP"
    printf '  %s❄%s  %s%sFLAKE-OS%s  %s·%s  %s%s%s\n' "$SKY" "$RESET" "$BOLD" "$SNOW" "$RESET" "$SLATE" "$RESET" "$ICE" "$1" "$RESET"
    hr "$DEEP"
}

box() {  # box <color> lines…   (ASCII text only so it stays aligned)
    local c="$1" w=44 l pad s; shift
    printf -v s '%*s' "$w" ''
    printf '  %s╭%s╮%s\n' "$c" "${s// /─}" "$RESET"
    for l in "$@"; do
        pad=$(( (w - ${#l}) / 2 ))
        printf '  %s│%s%*s%s%*s%s│%s\n' "$c" "$RESET" "$pad" '' "$FROST$l" $(( w - pad - ${#l} )) '' "$c" "$RESET"
    done
    printf '  %s╰%s╯%s\n' "$c" "${s// /─}" "$RESET"
}

progress() {  # progress <done> <total>   →  ● ● ○ ○
    local i out=""
    for ((i = 1; i <= $2; i++)); do
        if (( i <= $1 )); then out+="${AQUA}●${RESET} "; else out+="${SLATE}○${RESET} "; fi
    done
    printf '  %s\n' "$out"
}

press_enter() { printf '\n  %sPress Enter to continue…%s' "$SLATE" "$RESET"; read -r; }

finish() {  # finish "message" — prints summary and exits with 0/1
    echo; hr
    if (( ERR_COUNT == 0 )); then
        printf '  %s❄  %s%s\n\n' "$AQUA$BOLD" "$1" "$RESET"
    else
        printf '  %s!  %s — %d error(s), see %s%s\n\n' "$ROSE$BOLD" "$1" "$ERR_COUNT" "$FLAKE_LOG" "$RESET"
    fi
    exit $(( ERR_COUNT > 0 ))
}

# ── Interaction ───────────────────────────────────────────────────────────────
# read_key → sets KEY to: UP DOWN LEFT RIGHT ENTER ESC or the typed character
read_key() {
    local k rest
    IFS= read -rsn1 k || { KEY=ENTER; return; }
    if [[ $k == $'\e' ]]; then
        read -rsn2 -t 0.05 rest
        case "$rest" in
            '[A'|'OA') KEY=UP ;;   '[B'|'OB') KEY=DOWN ;;
            '[C'|'OC') KEY=RIGHT ;; '[D'|'OD') KEY=LEFT ;;
            *) KEY=ESC ;;
        esac
    elif [[ -z $k ]]; then KEY=ENTER
    else KEY="$k"; fi
}

# menu_select "Title" item… → MENU_RESULT = chosen index (-1 if q/Esc)
menu_select() {
    local title="$1"; shift
    local items=("$@") n=$# sel=0 i
    printf '  %s%s%s\n' "$BOLD$SNOW" "$title" "$RESET"
    printf '  %s↑/↓ move  ·  enter select  ·  q quit%s\n\n' "$SLATE" "$RESET"
    hide_cursor
    while true; do
        for ((i = 0; i < n; i++)); do
            if (( i == sel )); then
                printf '\e[2K\r    %s❯ ❄  %s%s\n' "$BOLD$SKY" "$SNOW${items[i]}" "$RESET"
            else
                printf '\e[2K\r      %s·  %s%s\n' "$SLATE" "${items[i]}" "$RESET"
            fi
        done
        read_key
        case "$KEY" in
            UP|k)   sel=$(( (sel - 1 + n) % n )) ;;
            DOWN|j) sel=$(( (sel + 1) % n )) ;;
            ENTER)  break ;;
            q|Q|ESC) sel=-1; break ;;
        esac
        printf '\e[%dA' "$n"
    done
    show_cursor
    MENU_RESULT=$sel
}

# confirm "Question?" — ←/→ + Enter (or y/n). Returns 0 for yes.
confirm() {
    local q="$1" sel=0 y n
    hide_cursor
    while true; do
        if (( sel == 0 )); then y="$BOLD$SKY❯ Yes$RESET"; n="${SLATE}  No$RESET"
        else y="${SLATE}  Yes$RESET"; n="$BOLD$SKY❯ No$RESET"; fi
        printf '\r\e[2K  %s?%s %s   %s   %s' "$SKY" "$RESET" "$q" "$y" "$n"
        read_key
        case "$KEY" in
            LEFT|RIGHT|UP|DOWN|h|l|j|k) sel=$(( 1 - sel )) ;;
            y|Y) sel=0; break ;;
            n|N) sel=1; break ;;
            ENTER) break ;;
        esac
    done
    show_cursor
    printf '\r\e[2K'
    return $sel
}

# ── Tasks ─────────────────────────────────────────────────────────────────────
ensure_sudo() { sudo -n true 2>/dev/null || sudo -v; }
has() { command -v "$1" &>/dev/null; }

# spin "label" cmd…  — runs quietly with a snowflake spinner; output → $FLAKE_LOG
spin() {
    local label="$1"; shift
    local frames=(❄ ❅ ❆ ❅) i=0 pid rc
    printf '\n--- %s ---\n' "$label" >> "$FLAKE_LOG"
    "$@" >> "$FLAKE_LOG" 2>&1 < /dev/null &
    pid=$!
    hide_cursor
    while kill -0 "$pid" 2>/dev/null; do
        printf '\r  %s%s%s  %s%s%s' "$ICE" "${frames[i++ % 4]}" "$RESET" "$SLATE" "$label…" "$RESET"
        sleep 0.12
    done
    wait "$pid"; rc=$?
    show_cursor
    printf '\r\e[2K'
    if (( rc == 0 )); then log_ok "$label"
    else log_err "$label"; tail -n 4 "$FLAKE_LOG" | sed "s/^/      ${SLATE}/;s/\$/${RESET}/"; fi
    return $rc
}

# ── Install record (lets flakeupdate know what is already applied) ────────────
record_applied() {  # record_applied [rev]  (default: current HEAD of the repo)
    local rev="${1:-$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null)}"
    [[ -n "$rev" ]] || return 0
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$rev" > "$STATE_DIR/applied"
    git -C "$REPO_DIR" remote get-url origin > "$STATE_DIR/remote" 2>/dev/null || true
}

# ── Packages (shared by package-install.sh and flakeupdate.sh) ────────────────
# split_repo_aur pkg…  → REPO_PKGS (found in official repos) / AUR_FALLBACK (not found)
split_repo_aur() {
    local -A in_repo=(); local p
    while read -r p; do in_repo[$p]=1; done < <(pacman -Slq)
    REPO_PKGS=(); AUR_FALLBACK=()
    for p in "$@"; do
        if [[ -n "${in_repo[$p]:-}" ]]; then REPO_PKGS+=("$p"); else AUR_FALLBACK+=("$p"); fi
    done
}

# install_list <label> <installer-cmd…> -- pkgs…   (one transaction, then verify)
install_list() {
    local label="$1" p; shift
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
