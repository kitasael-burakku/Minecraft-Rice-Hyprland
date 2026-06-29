-- .____                                __   
-- |    |   _____  ___.__. ____  __ ___/  |_ 
-- |    |   \__  \<   |  |/  _ \|  |  \   __\
-- |    |___ / __ \\___  (  <_> )  |  /|  |  
-- |_______ (____  / ____|\____/|____/ |__|  
--         \/    \/\/                        

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    general = {
        layout = "scrolling"
    }
})

hl.config({
  dwindle = {
      force_split                  = 0,
      preserve_split               = false,
      smart_split                  = false,
      smart_resizing               = true,
      permanent_direction_override = false,
      special_scale_factor         = 1,
      split_width_multiplier       = 1.0,
      use_active_for_splits        = true,
      default_split_ratio          = 1.0,
      split_bias                   = 0,
      precise_mouse_move           = false,
  },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        mfact = 0.60,
        new_status = "slave",
        new_on_top = false,
        new_on_active = "none",
        orientation = "left",
        slave_count_for_center_master = 2,
        center_master_fallback = "left",
        smart_resizing = true,
        drop_at_cursor = true,
        always_keep_position = false,
        special_scale_factor = 0.92,
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.50,
        focus_fit_method = 1,
        follow_focus = true,
        follow_min_visible = 0.40,
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
        wrap_focus = true,
        wrap_swapcol = true,
        direction = "right",
    },
})