-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
local C = require("colors")
hl.config({
    general = {
        gaps_in  = 8,
        gaps_out = 15,

        border_size = 0,

        col = {
            active_border   = { colors = {C.surface, C.surface}, angle = 45 },
            inactive_border = C.surface_dim,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,
    },

    decoration = {
        rounding       = 8,
        rounding_power = 16,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 0.7,

        shadow = {
            enabled      = true,
            range        = 30,
            render_power = 2,
            color        = C.surface,
        },

        blur = {
            enabled   = true,
            size      = 10,
            passes    = 2,
            vibrancy  = 1,
        },
    },

    animations = {
        enabled = true,
    }
})
