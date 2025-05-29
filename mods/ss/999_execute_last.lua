print("- loading execute_last.lua")
-- cache global functions for faster access
local debug = ss.debug
local player_data = ss.player_data


local flag1 = false
core.register_on_joinplayer(function(player)
    debug(flag1, "\nregister_on_joinplayer() execute_last.lua")
    local p_data = player_data[player:get_player_name()]
    local player_meta = player:get_meta()

    p_data.death_pos = core.deserialize(player_meta:get_string("death_pos")) or player:get_pos()
    debug(flag1, "  p_data.death_pos: " .. dump(p_data.death_pos))

    -- this represents a new player
    if p_data.player_status == 0 then

        -- all lua files have now exectued code relevant to a new player joining.
        -- set status to signify player is now an 'existing' player.
        player_meta:set_int("player_status", 1)
        p_data.player_status = 1
    end

    debug(flag1, "register_on_joinplayer() end " .. core.get_gametime())
end)


local flag3 = false
core.register_on_dieplayer(function(player)
    debug(flag3, "\nregister_on_dieplayer() EXECUTE LAST")
    local player_meta = player:get_meta()
    local p_data = player_data[player:get_player_name()]

    -- save the position where player died
    local pos = player:get_pos()
    p_data.death_pos = pos
    player_meta:set_string("death_pos", core.serialize(pos))

    debug(flag3, "register_on_dieplayer() end")
end)


local flag2 = false
core.register_on_respawnplayer(function(player)
    debug(flag2, "\nregister_on_respawnplayer() EXECUTE LAST")
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local p_data = ss.player_data[player_name]

    --debug(flag16, "  set player_status = 1")
    player_meta:set_int("player_status", 1)
    p_data.player_status = 1

	debug(flag2, "register_on_respawnplayer() end")
end)