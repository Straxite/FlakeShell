#!/usr/bin/env bash
# flakeupdate.sh — fetches the latest FlakeShell and applies ONLY what changed.
# Used through the `flakeupdate` command (symlinked by orchestra-install.sh).
#
#   flakeupdate            show what's new, ask, apply
#   flakeupdate -y         apply without asking
#   flakeupdate --check    only show what's new

source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/common.sh"

# ═════════════════════════════════ CONFIGURE ═════════════════════════════════
COMP_REL="install-script/installer-components"        # components folder inside the repo
UP_TO_DATE_MSG="FlakeShell is uptodate, you are good to go!"
NEVER_DEPLOY=( install-script .github docs )          # repo folders that are never deployed
# ═════════════════════════════════════════════════════════════════════════════
# What gets compared (between the last applied commit and the latest one):
#   package-install.sh  PACMAN_PACKAGES AUR_PACKAGES CARGO_PACKAGES HYPR_PLUGIN_REPOS HYPR_PLUGINS_ENABLE
#   dotfile.sh          CONFIG_FOLDERS LOCAL_FOLDER HOME_FILES SYSTEM_FOLDERS  (+ any changed file inside them)
#   refresher.sh        GSETTINGS REFRESH_COMMANDS
#   pacman.conf         re-installed if it changed
# Only NEW list entries / CHANGED files are applied. Nothing is ever deleted.

COMP_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
PKG_F="$COMP_REL/package-install.sh"; DOT_F="$COMP_REL/dotfile.sh"; REF_F="$COMP_REL/refresher.sh"
ASSUME_YES=false; DRY_RUN=false
OLD=""; NEW=""; STAGE=""
BACKUP_DIR="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"; BACKED_UP=0
trap 'show_cursor; [[ -n "$STAGE" ]] && rm -rf "$STAGE" "$STAGE.tar"' EXIT

rgit() { git -C "$REPO_DIR" "$@"; }

# ── Reading the repo at a given commit ────────────────────────────────────────
arr_from() {  # arr_from <rev> <repo-file> <ARRAY>  → one item per line
    local block
    block="$(rgit show "$1:$2" 2>/dev/null | sed -n "/^$3=(/,/^)/p")"
    [[ -n "$block" ]] || return 0
    ( eval "$block"; declare -n _arr="$3"; (( ${#_arr[@]} )) && printf '%s\n' "${_arr[@]}" )
}
scalar_from() {  # scalar_from <rev> <repo-file> <NAME>
    rgit show "$1:$2" 2>/dev/null | sed -n "s/^$3=//p" | head -n1 | sed 's/[[:space:]]*#.*//' | tr -d "\"'"
}
added() {  # added <repo-file> <ARRAY> → items present in NEW but not in OLD
    comm -13 <(arr_from "$OLD" "$1" "$2" | sort -u) <(arr_from "$NEW" "$1" "$2" | sort -u)
}
force_add() {  # mark every file under <path> (at NEW) as added
    local f
    while IFS= read -r -d '' f; do [[ -n "${CHG[$f]:-}" ]] || CHG[$f]=A; done \
        < <(rgit ls-tree -r --name-only -z "$NEW" -- "$1")
}

# ── repo path → where it gets deployed (uses the NEW dotfile.sh lists) ─────────
map_path() {  # map_path <repo-path> → sets DEST and USE_SUDO; returns 1 if not deployed
    local p="$1" top="${1%%/*}" e f; USE_SUDO=""
    if [[ "$p" == */* ]]; then
        for f in "${N_CFG[@]}"; do [[ "$top" == "$f" ]] && { DEST="$CONFIG_DIR/$p"; return 0; }; done
        [[ -n "$N_LOCAL" && "$top" == "$N_LOCAL" ]] && { DEST="$LOCAL_DIR/${p#"$N_LOCAL"/}"; return 0; }
        for e in "${N_SYS[@]}"; do
            [[ "$top" == "${e%%|*}" ]] && { DEST="${e##*|}/${p#"$top"/}"; USE_SUDO=sudo; return 0; }
        done
    else
        for f in "${N_HOME[@]}"; do [[ "$p" == "$f" ]] && { DEST="$HOME/$p"; return 0; }; done
    fi
    return 1
}

# apply_file <src> <dest> [sudo] → 0 copied · 2 already identical · 1 failed
apply_file() {
    local src="$1" dest="$2" s="${3:-}"
    if [[ -e "$dest" || -L "$dest" ]]; then
        cmp -s "$src" "$dest" 2>/dev/null && return 2
        $s mkdir -p "$BACKUP_DIR$(dirname "$dest")" && $s cp -a "$dest" "$BACKUP_DIR$dest" && BACKED_UP=$((BACKED_UP + 1))
    fi
    $s mkdir -p "$(dirname "$dest")" && $s cp -d --remove-destination --preserve=mode "$src" "$dest"
}

brief() {  # brief item…  → "a, b, c +2 more"
    local max=6 out="" i=0 x n=$#
    for x in "$@"; do (( i++ < max )) && out+="${out:+, }$x"; done
    (( n > max )) && out+=" +$((n - max)) more"
    printf '%s' "$out"
}
plan() { printf '  %s%s%s  %s%-14s%s %s%s%s\n' "$SKY" "$1" "$RESET" "$FROST" "$2" "$RESET" "$SLATE" "$3" "$RESET"; }

uptodate() { printf '\n  %s❄  %s%s\n\n' "$AQUA$BOLD" "$UP_TO_DATE_MSG" "$RESET"; exit 0; }

# ── 1. work out what changed ──────────────────────────────────────────────────
compute_changes() {
    local st p x top nl ol
    declare -gA CHG=() GROUP_NEW=() GROUP_UPD=() UNMAPPED=()
    DEPLOY=(); DELETED=(); PACMANCONF=false

    while IFS= read -r -d '' st && IFS= read -r -d '' p; do CHG[$p]="${st:0:1}"; done \
        < <(rgit diff --name-status --no-renames -z "$OLD" "$NEW")

    # new list entries ⇒ deploy their whole folder/file, even if the repo files themselves didn't change
    while read -r x; do [[ -n "$x" ]] && force_add "$x"; done < <(added "$DOT_F" CONFIG_FOLDERS)
    while read -r x; do [[ -n "$x" ]] && force_add "$x"; done < <(added "$DOT_F" HOME_FILES)
    while read -r x; do [[ -n "$x" ]] && force_add "${x%%|*}"; done < <(added "$DOT_F" SYSTEM_FOLDERS)
    nl="$(scalar_from "$NEW" "$DOT_F" LOCAL_FOLDER)"; ol="$(scalar_from "$OLD" "$DOT_F" LOCAL_FOLDER)"
    [[ -n "$nl" && "$nl" != "$ol" ]] && force_add "$nl"

    # deployment lists as of the NEW version
    mapfile -t N_CFG  < <(arr_from "$NEW" "$DOT_F" CONFIG_FOLDERS)
    mapfile -t N_HOME < <(arr_from "$NEW" "$DOT_F" HOME_FILES)
    mapfile -t N_SYS  < <(arr_from "$NEW" "$DOT_F" SYSTEM_FOLDERS)
    N_LOCAL="$(scalar_from "$NEW" "$DOT_F" LOCAL_FOLDER)"
    [[ "$(scalar_from "$NEW" "$PKG_F" INSTALL_PACMAN_CONF)" == false ]] && NO_PACMAN_CONF=true || NO_PACMAN_CONF=false

    for p in "${!CHG[@]}"; do
        st="${CHG[$p]}"; top="${p%%/*}"
        if [[ "$p" == install-script/* ]]; then continue; fi
        if [[ "$p" == pacman.conf ]]; then [[ "$st" != D ]] && ! $NO_PACMAN_CONF && PACMANCONF=true; continue; fi
        if map_path "$p"; then
            if [[ "$st" == D ]]; then DELETED+=("$p")
            else
                DEPLOY+=("$p")
                if [[ "$st" == A ]]; then GROUP_NEW[$top]=$(( ${GROUP_NEW[$top]:-0} + 1 ))
                else GROUP_UPD[$top]=$(( ${GROUP_UPD[$top]:-0} + 1 )); fi
            fi
        elif [[ "$p" == */* && "$st" != D ]]; then
            [[ " ${NEVER_DEPLOY[*]} " == *" $top "* ]] || UNMAPPED[$top]=1
        fi
    done
    mapfile -t DEPLOY < <(printf '%s\n' "${DEPLOY[@]}" | sed '/^$/d' | sort)

    # new package / refresh entries
    mapfile -t ADD_PACMAN    < <(added "$PKG_F" PACMAN_PACKAGES)
    mapfile -t ADD_AUR       < <(added "$PKG_F" AUR_PACKAGES)
    mapfile -t ADD_CARGO     < <(added "$PKG_F" CARGO_PACKAGES)
    mapfile -t ADD_PL_REPOS  < <(added "$PKG_F" HYPR_PLUGIN_REPOS)
    mapfile -t ADD_PL_ENABLE < <(added "$PKG_F" HYPR_PLUGINS_ENABLE)
    mapfile -t ADD_GSET      < <(added "$REF_F" GSETTINGS)
    mapfile -t ADD_CMDS      < <(added "$REF_F" REFRESH_COMMANDS)

    TOTAL=$(( ${#ADD_PACMAN[@]} + ${#ADD_AUR[@]} + ${#ADD_CARGO[@]} + ${#ADD_PL_REPOS[@]} + ${#ADD_PL_ENABLE[@]} \
            + ${#ADD_GSET[@]} + ${#ADD_CMDS[@]} + ${#DEPLOY[@]} ))
    $PACMANCONF && TOTAL=$((TOTAL + 1))
}

show_plan() {
    local t g n u line
    section "What's new"
    (( ${#ADD_PACMAN[@]} ))    && plan "+" "packages"   "$(brief "${ADD_PACMAN[@]}")"
    (( ${#ADD_AUR[@]} ))       && plan "+" "AUR"        "$(brief "${ADD_AUR[@]}")"
    (( ${#ADD_CARGO[@]} ))     && plan "+" "cargo"      "$(brief "${ADD_CARGO[@]}")"
    (( ${#ADD_PL_REPOS[@]} + ${#ADD_PL_ENABLE[@]} )) && plan "+" "hypr plugins" "$(brief "${ADD_PL_ENABLE[@]}" "${ADD_PL_REPOS[@]##*/}")"
    $PACMANCONF                && plan "↻" "pacman.conf" "updated"
    mapfile -t g < <(printf '%s\n' "${!GROUP_NEW[@]}" "${!GROUP_UPD[@]}" | sed '/^$/d' | sort -u)
    for t in "${g[@]}"; do
        n="${GROUP_NEW[$t]:-0}"; u="${GROUP_UPD[$t]:-0}"; line=""
        (( n )) && line+="$n new"; (( n && u )) && line+=", "; (( u )) && line+="$u updated"
        plan "↻" "$t" "$line file(s)"
    done
    (( ${#ADD_GSET[@]} ))      && plan "+" "gsettings"  "${#ADD_GSET[@]} new setting(s)"
    (( ${#ADD_CMDS[@]} ))      && plan "+" "commands"   "$(brief "${ADD_CMDS[@]%%|*}")"
    echo
    (( ${#DELETED[@]} ))       && log_skip "${#DELETED[@]} file(s) removed from the repo — left untouched on your system"
    if (( ${#UNMAPPED[@]} )); then
        log_warn "new in repo but not in dotfile.sh (not deployed): ${!UNMAPPED[*]}"
    fi
}

# ── 2. apply ──────────────────────────────────────────────────────────────────
apply_pacman_conf() {
    $PACMANCONF || return 0
    section "pacman.conf"
    ensure_sudo
    rgit show "$NEW:pacman.conf" > "$STAGE/pacman.conf"
    sudo cp -f /etc/pacman.conf /etc/pacman.conf.flake-backup
    sudo install -m644 "$STAGE/pacman.conf" /etc/pacman.conf && log_ok "installed (backup: /etc/pacman.conf.flake-backup)"
    sudo pacman -Syy --noconfirm >> "$FLAKE_LOG" 2>&1 && log_ok "package databases synced"
}

apply_packages() {
    local c r pl
    if (( ${#ADD_PACMAN[@]} + ${#ADD_AUR[@]} )); then
        section "New packages"
        ensure_sudo
        if (( ${#ADD_PACMAN[@]} )); then
            split_repo_aur "${ADD_PACMAN[@]}"
            ADD_AUR+=("${AUR_FALLBACK[@]}")
            install_list "repo" sudo pacman -S --needed --noconfirm -- "${REPO_PKGS[@]}"
        fi
        if (( ${#ADD_AUR[@]} )); then
            if has yay; then install_list "AUR" yay -S --needed --noconfirm -- "${ADD_AUR[@]}"
            else log_err "yay not found — can't install: ${ADD_AUR[*]}"; fi
        fi
    fi
    if (( ${#ADD_CARGO[@]} )); then
        section "New cargo crates"
        for c in "${ADD_CARGO[@]}"; do spin "$c" cargo install "$c"; done
    fi
    if (( ${#ADD_PL_REPOS[@]} + ${#ADD_PL_ENABLE[@]} )); then
        section "Hyprland plugins"
        if has hyprpm; then
            {
                if (( ${#ADD_PL_REPOS[@]} )); then
                    hyprpm update
                    for r in "${ADD_PL_REPOS[@]}"; do hyprpm add "$r"; done
                    hyprpm update
                fi
                for pl in "${ADD_PL_ENABLE[@]}"; do hyprpm enable "$pl"; done
            } && log_ok "plugins ready" || log_warn "hyprpm failed — run flakeupdate again from inside a Hyprland session"
        else log_skip "hyprpm not found"; fi
    fi
}

apply_deploy() {
    (( ${#DEPLOY[@]} )) || return 0
    section "Updating your files"
    local -a tops=() done_files=(); local p rc same=0 sudo_needed=false
    for p in "${DEPLOY[@]}"; do
        tops+=("${p%%/*}")
        map_path "$p" && [[ -n "$USE_SUDO" ]] && sudo_needed=true
    done
    $sudo_needed && ensure_sudo
    mapfile -t tops < <(printf '%s\n' "${tops[@]}" | sort -u)
    rgit archive "$NEW" -- "${tops[@]}" > "$STAGE.tar" && tar -xf "$STAGE.tar" -C "$STAGE" \
        || { log_err "couldn't export files from the repo"; return; }

    for p in "${DEPLOY[@]}"; do
        map_path "$p" || continue
        apply_file "$STAGE/$p" "$DEST" "$USE_SUDO"; rc=$?
        case $rc in
            0) done_files+=("$p") ;;
            2) same=$((same + 1)) ;;
            *) log_err "$p" ;;
        esac
    done

    if (( ${#done_files[@]} <= 15 )); then
        for p in "${done_files[@]}"; do log_ok "$p"; done
    else
        log_ok "${#done_files[@]} files updated (${#GROUP_NEW[@]} new / ${#GROUP_UPD[@]} changed folders)"
    fi
    (( same )) && log_skip "$same file(s) already identical"
    (( BACKED_UP )) && log_info "replaced files backed up to ${BACKUP_DIR/#$HOME/~}"

    # newly deployed scripts under ~/.config should be executable
    local x=false; for p in "${done_files[@]}"; do map_path "$p"; [[ "$DEST" == "$CONFIG_DIR"/* ]] && x=true; done
    $x && spin "making new scripts executable" bash "$COMP_DIR/executable.sh"
}

apply_refresh() {
    local e schema key value
    if (( ${#ADD_GSET[@]} )); then
        section "Settings"
        if has gsettings; then
            for e in "${ADD_GSET[@]}"; do
                IFS='|' read -r schema key value <<< "$e"
                gsettings set "$schema" "$key" "$value" 2>/dev/null && log_ok "$key" || log_err "$key"
            done
        else log_skip "gsettings not installed"; fi
    fi
    if (( ${#ADD_CMDS[@]} )); then
        section "Commands"; ensure_sudo
        for e in "${ADD_CMDS[@]}"; do spin "${e%%|*}" bash -c "${e#*|}"; done
    fi
}

sync_repo() {
    section "Finishing"
    if rgit -c core.fileMode=false merge --ff-only --quiet "$TARGET" >> "$FLAKE_LOG" 2>&1; then
        log_ok "$FLAKE_REPO_NAME is now at $(rgit rev-parse --short "$NEW")"
    else
        log_warn "couldn't fast-forward $REPO_DIR (local changes?) — run: git -C $REPO_DIR pull"
    fi
    find "$REPO_DIR/install-script" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null
}

# ── main ──────────────────────────────────────────────────────────────────────
main() {
    local a url n
    for a in "$@"; do
        case "$a" in
            -y|--yes) ASSUME_YES=true ;;
            -n|--check|--dry-run) DRY_RUN=true ;;
            -h|--help) sed -n '2,8p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
        esac
    done

    component_banner "FlakeShell Update"
    has git || { log_err "git not found"; finish "Update aborted"; }

    # 1. latest repo
    section "Checking for updates"
    if [[ ! -d "$REPO_DIR/.git" ]]; then
        url="$(cat "$STATE_DIR/remote" 2>/dev/null)"; url="${url:-$FLAKE_REPO_URL}"
        [[ -n "$url" ]] || { log_err "no $FLAKE_REPO_NAME clone at $REPO_DIR"; finish "Update aborted"; }
        log_info "cloning $url"
        git clone --quiet "$url" "$REPO_DIR" && log_ok "cloned" || { log_err "clone failed"; finish "Update aborted"; }
    else
        log_info "fetching latest changes"
        rgit fetch --quiet origin || { log_err "fetch failed (network / remote?)"; finish "Update aborted"; }
    fi

    TARGET="$(rgit rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)"
    [[ -n "$TARGET" ]] || TARGET="origin/$(rgit symbolic-ref --short -q HEAD)"
    rgit rev-parse -q --verify "$TARGET^{commit}" >/dev/null || TARGET="origin/HEAD"
    NEW="$(rgit rev-parse -q --verify "$TARGET^{commit}")" || { log_err "can't find the latest commit"; finish "Update aborted"; }

    OLD="$(cat "$STATE_DIR/applied" 2>/dev/null)"
    if ! rgit cat-file -e "${OLD:-x}^{commit}" 2>/dev/null; then
        OLD="$(rgit rev-parse HEAD)"
        log_warn "no install record found — using your current checkout as the baseline"
    fi

    if [[ "$OLD" == "$NEW" ]] || rgit merge-base --is-ancestor "$NEW" "$OLD"; then uptodate; fi
    if ! rgit merge-base --is-ancestor "$OLD" "$NEW"; then
        log_err "history diverged from what you installed — run flakeinstall again"; finish "Update aborted"
    fi

    n="$(rgit rev-list --count "$OLD..$NEW")"
    log_ok "$n new commit(s) — latest: $(rgit log -1 --format=%s "$NEW")"

    # 2. what changed
    compute_changes
    if (( TOTAL == 0 )); then
        $DRY_RUN || { sync_repo; (( ERR_COUNT == 0 )) && record_applied "$NEW"; }
        uptodate
    fi
    show_plan
    $DRY_RUN && { echo; log_info "check only — nothing was changed"; exit 0; }
    if ! $ASSUME_YES; then
        echo; confirm "Apply these updates?" || { log_skip "cancelled"; exit 0; }
    fi

    # 3. apply
    STAGE="$(mktemp -d)"
    apply_pacman_conf
    apply_packages
    apply_deploy
    apply_refresh
    sync_repo
    (( ERR_COUNT == 0 )) && record_applied "$NEW"
    finish "FlakeShell updated"
}

main "$@"
exit $?
