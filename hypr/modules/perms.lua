-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

hl.config({
  ecosystem = {
    enforce_permissions = false,
  },
})

hl.permission({
  binary = "/usr/bin/hyprlock",  -- regex supported
  type   = "screencopy",       -- permission type
  mode   = "allow"             -- allow | ask | deny
})

hl.permission({
  binary = "/usr/bin/hyprpicker",  -- regex supported
  type   = "screencopy",       -- permission type
  mode   = "allow"             -- allow | ask | deny
})

hl.permission({
  binary = "/usr/bin/quickshell",
  type   = "screencopy",
  mode   = "allow"
})

hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")
