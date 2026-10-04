#!/usr/bin/env bash
# executable.sh — makes every script in ~/.config executable (recursively)

source "${BASH_SOURCE[0]%/*}/common.sh"

component_banner "     Make Scripts Executable"
echo "Scanning: $CONFIG_DIR"

# Known script extensions — one find, one chmod
mapfile -d '' by_ext < <(find "$CONFIG_DIR" -type f \
    \( -name '*.sh' -o -name '*.bash' -o -name '*.zsh' -o -name '*.fish' \
       -o -name '*.py' -o -name '*.rb' -o -name '*.pl' -o -name '*.lua' \) -print0)

# Extensionless files — only if they start with a shebang
by_shebang=()
while IFS= read -r -d '' f; do
    magic=""
    IFS= read -r -n2 magic < "$f" 2>/dev/null || true
    [[ "$magic" == '#!' ]] && by_shebang+=("$f")
done < <(find "$CONFIG_DIR" -type f ! -name '*.*' -print0)

all=("${by_ext[@]}" "${by_shebang[@]}")
if (( ${#all[@]} )); then
    chmod +x "${all[@]}"
    printf '  [+] %s\n' "${all[@]}"
fi

echo "---"
echo "Done. Made ${#all[@]} file(s) executable."
