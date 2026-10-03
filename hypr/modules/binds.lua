-- Set programs that you use
local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "rofi -show drun"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local alt = "ALT"
local ctrl = "CTRL"
local shift = "SHIFT"

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(alt .. " + Q", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- closeWindowBind:set_enabled(false)
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.resize({ exact = true, x = 1200, y = 800 }))
end)
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
-- hl.bind(alt .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind(alt .. " + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
-- hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd("qs ipc call control toggle"))
-- hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("qs kill | qs"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only
-- hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout -b 6 -m 400 -r 20 -c 20 --buttons-per-row 5"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("qs ipc call power toggle"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("qs ipc call menu toggle"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m region && satty --filename -"))
-- hl.bind(alt .. " + TAB", hl.dsp.exec_cmd("snappy-switcher toggle"))
-- hl.bind(alt .. " + TAB", hl.dsp.exec_cmd("snappy-switcher next"))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("swaync-client -t"))
hl.bind(mainMod .. " + H", hl.dsp.exec_cmd("brave"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("~/.config/hypr/scripts/lutgen.sh"))
hl.bind(alt .. " + Z", hl.dsp.exec_cmd("gsr-ui"))
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd("kitty --class yazi -e yazi"))
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.exec_cmd("kitty --class btop -e btop"))
hl.bind(alt .. " + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind(mainMod .. " + PERIOD", hl.dsp.exec_cmd("qs ipc call control toggle"))
hl.bind("CTRL + SUPER + SPACE", hl.dsp.exec_cmd("rofimoji --action copy"))
hl.bind(alt .. " + TAB", function()
    hl.plugin.scrolloverview.overview("toggle all")
end)
hl.bind(mainMod .. " +L", hl.dsp.exec_cmd("~/.local/share/quickshell-lockscreen/lock.sh"))

-- Move windows
hl.bind("ALT + UP", hl.dsp.window.move( { direction = "up" } ))
hl.bind("ALT + DOWN", hl.dsp.window.move( { direction = "down" } ))
hl.bind("ALT + LEFT", hl.dsp.window.move( { direction = "left" } ))
hl.bind("ALT + RIGHT", hl.dsp.window.move( { direction = "right" } ))

-- Change the focus on of Windows
hl.bind("SUPER + RIGHT", hl.dsp.focus( { direction = "right" } ))
hl.bind("SUPER + LEFT", hl.dsp.focus( { direction = "left" } ))
hl.bind("SUPER + UP", hl.dsp.focus( { direction = "up" } ))
hl.bind("SUPER + DOWN", hl.dsp.focus( { direction = "down" } ))

-- For waybar
-- hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/waybar/scripts/waybar.sh"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))
-- hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind(ctrl .. " + UP", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),        { locked = true, repeating = true })
hl.bind(ctrl .. " + DOWN", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
-- hl.bind(ctrl .. " + UP", hl.dsp.exec_cmd("swayosd-client --output-volume raise --max-volume 150"),        { locked = true, repeating = true })
-- hl.bind(ctrl .. " + DOWN", hl.dsp.exec_cmd("swayosd-client --output-volume lower --max-volume 150"),        { locked = true, repeating = true })
-- hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
-- hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind(shift .. " + UP",  hl.dsp.exec_cmd("brightnessctl set 5%+"),                  { locked = true, repeating = true })
hl.bind(shift .. " + DOWN",hl.dsp.exec_cmd("brightnessctl set 5%-"),                  { locked = true, repeating = true })
-- hl.bind(shift .. " + UP",  hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh --inc"),                  { locked = true, repeating = true })
-- hl.bind(shift .. " + DOWN",  hl.dsp.exec_cmd("~/.config/hypr/scripts/brightness.sh --dec"),                  { locked = true, repeating = true })


-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
