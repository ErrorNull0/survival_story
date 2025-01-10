print("- loading execute_last.lua")
-- cache global functions for faster access
local debug = ss.debug


local flag1 = false
minetest.register_on_joinplayer(function(player)
    debug(flag1, "\nregister_on_joinplayer() execute_last.lua")
    local player_meta = player:get_meta()

    -- this represents a new player
    if player_meta:get_int("player_status") == 0 then

        -- all lua files have now exectued code relevant to a new player joining.
        -- now set status to signify player is not 'new' but an 'existing' player.
        player_meta:set_int("player_status", 1)
    end

    debug(flag1, "register_on_joinplayer() end " .. minetest.get_gametime())
end)