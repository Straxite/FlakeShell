-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
  hl.exec_cmd("hyprpm reload -n")
  hl.exec_cmd("qs")
  hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("snappy-switcher --daemon")
  hl.exec_cmd("swaync")
  hl.exec_cmd("~/.config/hypr/scripts/battery-check.sh")
  hl.exec_cmd("/usr/lib/xdg-desktop-portal-gnome")
  hl.exec_cmd("/usr/lib/xdg-desktop-portal")
  hl.exec_cmd("hyprsunset -t 4800")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
