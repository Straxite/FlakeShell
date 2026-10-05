#!/usr/bin/env bash
# orchestra-install.sh — run ONCE after cloning the repo:
#   bash ~/FlakeShell/install-script/orchestra-install.sh
# Makes every installer script executable and adds the Flake commands.

DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
find "$DIR" -type f -name '*.sh' -exec chmod +x {} +
source "$DIR/installer-components/common.sh"

# ═════════════════════════════════ CONFIGURE ═════════════════════════════════
BIN_DIR="${FLAKE_BIN_DIR:-/usr/local/bin}"
# Commands to add ("command|script, relative to install-script/")
COMMANDS=(
    "flakeinstall|orchestra-script.sh"
    "flakeupdate|installer-components/flakeupdate.sh"
)
# ═════════════════════════════════════════════════════════════════════════════

component_banner "Setup"

section "Making scripts executable"
n=$(find "$DIR" -type f -name '*.sh' | wc -l)
log_ok "$n installer scripts are executable"

# chmod +x would otherwise show up as local changes in git and block updates
git -C "$REPO_DIR" config core.fileMode false 2>/dev/null

section "Adding commands"
s=""; [[ -w "$BIN_DIR" ]] || { s=sudo; ensure_sudo; }
for entry in "${COMMANDS[@]}"; do
    name="${entry%%|*}"; target="$DIR/${entry##*|}"
    if [[ -f "$target" ]] && $s ln -sf "$target" "$BIN_DIR/$name"; then log_ok "$name  →  $BIN_DIR/$name"
    else log_err "$name (couldn't link $target)"; fi
done

echo; hr
if (( ERR_COUNT == 0 )); then
    printf '  %s❄  Ready!%s  Run %sflakeinstall%s to start the installer.\n\n' "$AQUA$BOLD" "$RESET" "$BOLD$SNOW" "$RESET"
else
    printf '  %s!  Setup finished with errors.%s\n\n' "$ROSE$BOLD" "$RESET"
fi
exit $(( ERR_COUNT > 0 ))
