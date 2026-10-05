#!/usr/bin/env bash
# executable.sh — makes scripts in ~/.config executable (recursively)

source "${BASH_SOURCE[0]%/*}/common.sh"

# ═════════════════════════════════ CONFIGURE ═════════════════════════════════
SCAN_DIR="$CONFIG_DIR"
# Files with these extensions are always made executable
EXTENSIONS=(
    sh
    bash
    zsh
    fish
    py
    rb
    pl
    lua
)
# Extensionless files are made executable only if they start with a shebang (#!)
# ═════════════════════════════════════════════════════════════════════════════

component_banner "Executable Scripts"
log_info "scanning $SCAN_DIR"

# Build:  \( -name '*.sh' -o -name '*.py' … \)
find_args=()
for e in "${EXTENSIONS[@]}"; do find_args+=(-o -name "*.$e"); done
unset 'find_args[0]'

mapfile -d '' by_ext < <(find "$SCAN_DIR" -type f \( "${find_args[@]}" \) -print0)

by_shebang=()
while IFS= read -r -d '' f; do
    magic=""; IFS= read -r -n2 magic < "$f" 2>/dev/null || true
    [[ "$magic" == '#!' ]] && by_shebang+=("$f")
done < <(find "$SCAN_DIR" -type f ! -name '*.*' -print0)

all=("${by_ext[@]}" "${by_shebang[@]}")
section "Scripts"
if (( ${#all[@]} )); then
    chmod +x "${all[@]}"
    for f in "${all[@]}"; do printf '  %s+%s  %s%s%s\n' "$AQUA" "$RESET" "$ICE" "${f#"$SCAN_DIR"/}" "$RESET"; done
else
    log_skip "no scripts found"
fi

echo; log_info "${#all[@]} file(s) made executable"
finish "Scripts are executable"
