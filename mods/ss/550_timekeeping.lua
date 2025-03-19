<<<<<<< HEAD
print("- loading timekeeping.lua")

-- cache global functions for faster access
local math_floor = math.floor
local string_format = string.format
local mt_get_timeofday = minetest.get_timeofday
local mt_get_day_count = minetest.get_day_count
local mt_get_connected_players = minetest.get_connected_players
local debug = ss.debug
local mt_after = minetest.after

-- this value is the rate at which time passes in-game. Higher value is faster. this is
-- also used for calcuating how much thirst and hunger is depleted while idle.
-- 72: 24 hours in-game is 20 minutes real-world (default 'minecraft' style speed)
-- 24: 24 hours in-game is 60 minutes real-world
TIME_SPEED = 24

minetest.settings:set("time_speed", TIME_SPEED)

-- Function to convert game time to hours and minutes
local function game_time_to_hours_minutes(game_time)
    local hours = math_floor(game_time / 1000)
    local minutes = math_floor(((game_time % 1000) / 1000) * 60)
    return hours, minutes
end


-- Define a function to update the HUD for a player
local function update_time_hud(player)
    local player_name = player:get_player_name()
    local game_time = mt_get_timeofday() * 24000
    local hours, minutes = game_time_to_hours_minutes(game_time)
    local time_string = string_format("%02d:%02d", hours, minutes)

    -- Ensure day_count starts at 1 in a new game
    local day_count = mt_get_day_count() + 1
    local day_string = "Day " .. tostring(day_count)

    -- Remove existing hud for current day, if displayed
    local hud_id_day = ss.player_hud_ids[player_name].current_day
    if hud_id_day then
        player:hud_remove(hud_id_day)
    end

    -- display current day hud
    ss.player_hud_ids[player_name].current_day = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 0.0},
        offset = {x = 0, y = 50},
        text = day_string,
        size = {x = 1.0, y = 2.0},
        number = "0xCCCCCC",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        style = 1
    })

    -- Remove existing hud for current time, if displayed
    local hud_id_time = ss.player_hud_ids[player_name].current_time
    if hud_id_time then
        player:hud_remove(hud_id_time)
    end

    -- display current time hud
    ss.player_hud_ids[player_name].current_time = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 0.0},
        offset = {x = 0, y = 25},
        text = time_string,
        size = {x = 2.0, y = 1.0},
        number = "0xFFFFFF",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        style = 1
    })

end


-- refreshes the day and time HUD for all player at a regular interval
local function monitor_time()
    for _, player in ipairs(mt_get_connected_players()) do
        update_time_hud(player)
    end
    -- Schedule the next update
    mt_after(1, monitor_time)
end


local flag1 = false
minetest.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() timekeeping.lua")

	-- begin the day/time hud refresh loop
	monitor_time()

	debug(flag1, "\nregister_on_joinplayer() end")
=======
print("- loading timekeeping.lua")

-- cache global functions for faster access
local math_floor = math.floor
local string_format = string.format
local mt_get_timeofday = core.get_timeofday
local mt_get_day_count = core.get_day_count
local mt_get_connected_players = core.get_connected_players
local debug = ss.debug
local mt_after = core.after

local TIME_SPEED = ss.TIME_SPEED

core.settings:set("time_speed", TIME_SPEED)

-- Function to convert game time to hours and minutes
local function game_time_to_hours_minutes(game_time)
    local hours = math_floor(game_time / 1000)
    local minutes = math_floor(((game_time % 1000) / 1000) * 60)
    return hours, minutes
end


-- refreshes the day and time HUD for all player at a regular interval
local function monitor_time(player, player_name)
    if not player:is_player() then
        return
    end

    local game_time = mt_get_timeofday() * 24000
    local hours, minutes = game_time_to_hours_minutes(game_time)
    local time_string = string_format("%02d:%02d", hours, minutes)

    -- Ensure day_count starts at 1 in a new game
    local day_string = "Day " .. tostring(mt_get_day_count() + 1)

    -- update hud day and time data
    local hud_id
    hud_id = ss.player_hud_ids[player_name].current_day
    player:hud_change(hud_id, "text", day_string)
    hud_id = ss.player_hud_ids[player_name].current_time
    player:hud_change(hud_id, "text", time_string)

    -- Schedule the next update
    mt_after(1, monitor_time, player, player_name)
end


local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() timekeeping.lua")

    local player_name = player:get_player_name()
    local game_time = mt_get_timeofday() * 24000
    local hours, minutes = game_time_to_hours_minutes(game_time)
    local time_string = string_format("%02d:%02d", hours, minutes)

    -- Ensure day_count starts at 1 in a new game
    local day_string = "Day " .. tostring(mt_get_day_count() + 1)

    -- display current day hud
    ss.player_hud_ids[player_name].current_day = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 0.0},
        offset = {x = 0, y = 50},
        text = day_string,
        size = {x = 1.0, y = 2.0},
        number = "0xCCCCCC",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        style = 1
    })

    -- display current time hud
    ss.player_hud_ids[player_name].current_time = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 0.0},
        offset = {x = 0, y = 25},
        text = time_string,
        size = {x = 2.0, y = 1.0},
        number = "0xFFFFFF",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        style = 1
    })

	-- begin the day/time hud refresh loop
	monitor_time(player, player_name)

	debug(flag1, "\nregister_on_joinplayer() end")
>>>>>>> 7965987 (update to version 0.0.3)
end)