#!/usr/bin/env bash
# refresher.sh — refreshes misc configs / settings after deployment

source "${BASH_SOURCE[0]%/*}/common.sh"

component_banner "         Refresh Configs"

header "GNOME / GTK settings"
if has gsettings; then
    gsettings set org.gnome.desktop.wm.preferences button-layout ':' \
        && log_ok "window button layout cleared" \
        || log_err "gsettings failed (is a dbus session running?)"
else
    log_skip "gsettings not installed"
fi
