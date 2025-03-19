<<<<<<< HEAD
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
=======
print("- loading execute_last.lua")
-- cache global functions for faster access
local debug = ss.debug
local player_data = ss.player_data


local flag1 = false
core.register_on_joinplayer(function(player)
    debug(flag1, "\nregister_on_joinplayer() execute_last.lua")

    -- this represents a new player
    if player_data[player:get_player_name()].player_status == 0 then

        -- all lua files have now exectued code relevant to a new player joining.
        -- set status to signify player is now an 'existing' player.
        local player_meta = player:get_meta()
        player_meta:set_int("player_status", 1)
        local player_name = player:get_player_name()
        player_data[player_name].player_status = 1
    end

    debug(flag1, "register_on_joinplayer() end " .. core.get_gametime())
>>>>>>> 7965987 (update to version 0.0.3)
end)