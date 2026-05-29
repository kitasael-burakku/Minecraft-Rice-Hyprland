-- .____                                __   
-- |    |   _____  ___.__. ____  __ ___/  |_ 
-- |    |   \__  \<   |  |/  _ \|  |  \   __\
-- |    |___ / __ \\___  (  <_> )  |  /|  |  
-- |_______ (____  / ____|\____/|____/ |__|  
--         \/    \/\/                        

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})