#!/usr/bin/env bash
# refresher.sh — refreshes settings and configs after deployment

source "${BASH_SOURCE[0]%/*}/common.sh"

# ═════════════════════════════════ CONFIGURE ═════════════════════════════════

# gsettings ("schema|key|value")
GSETTINGS=(
    "org.gnome.desktop.wm.preferences|button-layout|:"
)

# Extra commands ("Label|command") — uncomment or add your own
REFRESH_COMMANDS=(
    # "Rebuild initramfs|sudo mkinitcpio -P"
    # "Regenerate GRUB config|sudo grub-mkconfig -o /boot/grub/grub.cfg"
    # "Rebuild font cache|fc-cache -f"
)

# ═════════════════════════════════════════════════════════════════════════════

component_banner "Refreshing Configs"

section "GNOME / GTK settings"
if has gsettings; then
    for entry in "${GSETTINGS[@]}"; do
        IFS='|' read -r schema key value <<< "$entry"
        if gsettings set "$schema" "$key" "$value" 2>/dev/null; then log_ok "$key"
        else log_err "$key (is a dbus session running?)"; fi
    done
else
    log_skip "gsettings not installed"
fi

if (( ${#REFRESH_COMMANDS[@]} )); then
    section "Commands"
    ensure_sudo
    for entry in "${REFRESH_COMMANDS[@]}"; do
        spin "${entry%%|*}" bash -c "${entry#*|}"
    done
fi

finish "Configs refreshed"
