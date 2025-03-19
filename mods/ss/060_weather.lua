print("- loading weather.lua")

-- cache global functions for faster access
local math_random = math.random
local mt_get_modpath = core.get_modpath
local mt_after = core.after
local mt_serialize = core.serialize
local mt_deserialize = core.deserialize
local mt_get_node = core.get_node
local mt_get_biome_name = core.get_biome_name
local mt_get_biome_data = core.get_biome_data
local debug = ss.debug
local hide_stat_effect = ss.hide_stat_effect
local show_stat_effect = ss.show_stat_effect
local play_sound = ss.play_sound
local notify = ss.notify
local recover_drained_stat = ss.recover_drained_stat
local key_to_pos = ss.key_to_pos

-- cache global variables for faster access
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local HP_DRAIN_VAL_HOT_3 = ss.HP_DRAIN_VAL_HOT_3
local HP_DRAIN_VAL_HOT_4 = ss.HP_DRAIN_VAL_HOT_4
local HP_DRAIN_VAL_COLD_3 = ss.HP_DRAIN_VAL_COLD_3
local HP_DRAIN_VAL_COLD_4 = ss.HP_DRAIN_VAL_COLD_4

local COMFORT_DRAIN_VAL_HOT_2 = ss.COMFORT_DRAIN_VAL_HOT_2
local COMFORT_DRAIN_VAL_HOT_3 = ss.COMFORT_DRAIN_VAL_HOT_3
local COMFORT_DRAIN_VAL_HOT_4 = ss.COMFORT_DRAIN_VAL_HOT_4
local COMFORT_DRAIN_VAL_COLD_1 = ss.COMFORT_DRAIN_VAL_COLD_1
local COMFORT_DRAIN_VAL_COLD_2 = ss.COMFORT_DRAIN_VAL_COLD_2
local COMFORT_DRAIN_VAL_COLD_3 = ss.COMFORT_DRAIN_VAL_COLD_3
local COMFORT_DRAIN_VAL_COLD_4 = ss.COMFORT_DRAIN_VAL_COLD_4

local job_handles = ss.job_handles
local player_data = ss.player_data
local mod_storage = ss.mod_storage

local ENABLE_WEATHER_MONITOR = true


local STAT_EFFECT_TEXTS = {
    cold_1_up = "feeling a bit chilly",
    cold_2_up = "feeling pretty cold",
    cold_3_up = "it's frigid",
    cold_4_up = "it's freezing",
    cold_3_down = "still frigid",
    cold_2_down = "still feeling cold",
    cold_1_down = "still a bit chilly",
    cold_0_down = "temperature is nicer now",
    hot_1_up = "feeling a bit warm",
    hot_2_up = "feeling hot",
    hot_3_up = "it's sweltering",
    hot_4_up = "it's scorching",
    hot_3_down = "still sweltering",
    hot_2_down = "still feels hot",
    hot_1_down = "still a bit warm",
    hot_0_down = "temperature is nicer now",
}

-- ss.radiant_sources = {
--     <pos_key> = { name = <source item name>, temperature = <source temperature>, max_distance = <number>},
--     ["101,12,-25"] = {name = "ss:torch", temperature = 150, max_distance = 2.0},
--     ["-5,122,76"] = {name = "ss:portable_cooler", temperature = 35, max_distance = 4.0}
-- }
ss.radiant_sources = {}
local radiant_sources = ss.radiant_sources

-- active_biomes = {
--     savanna = true,
--     rainforest = true
-- }
local active_biomes = {}

-- ss.wind_conditions = {
--     savanna = {wind_speed = 5, shift_timer = ?, shift_threshold = ?},
--     rainforest = {wind_speed = 1, shift_timer = ?, shift_threshold = ?}
-- }
ss.wind_conditions = mt_deserialize(mod_storage:get_string("wind_conditions"))
if ss.wind_conditions == nil then ss.wind_conditions = {} end  -- occurs on new game initial start up
local wind_conditions = ss.wind_conditions
if wind_conditions == nil then print("### ERROR - ss.wind_conditions is NIL") end
--print("\n### wind_conditions: " .. dump(wind_conditions))
--print("\n### ss.wind_conditions: " .. dump(ss.wind_conditions))


-- contains all the biome data that the 'update_feels_like_temp()' function uses to
-- calculate the player's 'feels like' temperature. BIOME_DATA values can be modified
-- during gameplay, by the 'weather_wand' admin tool and by seasonal change mechanisms.
-- BIOME_DATA_DEFAULTS provides the way to restore BIOME_DATA to defaults.
--[[
BIOME_DATA = {
    grassland = {
        temp_min = 55, temp_max = 70,    
        humidity_min = 40, humidity_max = 50,
        wind_speed_min = 4, wind_speed_max = 12,
        wind_shift_time = {18,45}, temp_time_shift = 0.4
    },
    desert = {
        temp_min = 75, temp_max = 95,
        humidity_min = 20, humidity_max = 30,
        wind_speed_min = 6, wind_speed_max = 18,
        wind_shift_time = {15,40}, temp_time_shift = -0.2,
    },
    etc....
}
--]]
ss.BIOME_DATA = {}
ss.BIOME_DATA_DEFAULTS = {}

local file_path = mt_get_modpath("ss") .. "/biome_data.txt"
local file = io.open(file_path, "r")
if not file then
    print("### Could not open file: " .. file_path)
    return
end
local current_biome_name = nil
for line in file:lines() do
    line = line:match("^%s*(.-)%s*$")
    if line ~= "" and not line:match("^#") then
        if not line:find(",") then
            current_biome_name = line
        else
            if current_biome_name then
                local fields = {}
                for val in line:gmatch("([^,]+)") do
                    val = val:match("^%s*(.-)%s*$")
                    if val == "" then
                        table.insert(fields, nil)
                    else
                        local num = tonumber(val)
                        if num then
                            table.insert(fields, num)
                        else
                            table.insert(fields, val)
                        end
                    end
                end
                ss.BIOME_DATA[current_biome_name] = {
                    temp_min = fields[1],
                    temp_max = fields[2],
                    humidity_min = fields[3],
                    humidity_max = fields[4],
                    wind_speed_min = fields[5],
                    wind_speed_max = fields[6],
                    wind_shift_time = { fields[7], fields[8] },
                    temp_time_shift = fields[9],
                }
                current_biome_name = nil
            end
        end
    end
end
file:close()
local BIOME_DATA = ss.BIOME_DATA
ss.BIOME_DATA_DEFAULTS = table.copy(ss.BIOME_DATA)



-- helper function mostly used in 'update_feels_like_temp()'
local function clamp(val, min_val, max_val)
    if val < min_val then return min_val end
    if val > max_val then return max_val end
    return val
end


local flag6 = false
local function wind_simulator()
    debug(flag6, "\nwind_simulator()")
    debug(flag6, "  wind_conditions (before): " .. dump(wind_conditions))

    for biome_name in pairs(active_biomes) do
        debug(flag6, "  simulating winds for biome: " .. biome_name)

        local biome_data = BIOME_DATA[biome_name]
        local current_condition = wind_conditions[biome_name]

        if current_condition then
            debug(flag6, "  wind simulation data exists")
            local shift_threshold = current_condition.shift_threshold
            local current_timer = current_condition.shift_timer
            debug(flag6, "  shift_timer: " .. current_condition.shift_timer)

            if current_timer < shift_threshold then
                debug(flag6, "  shift timer not reached. wind speed unchanged: " .. current_condition.wind_speed)
                current_condition.shift_timer = current_timer + 1

            else
                debug(flag6, "  timer reached. changing wind speed..")
                current_condition.shift_timer = 0
                local new_shift_threshold = math_random(biome_data.wind_shift_time[1], biome_data.wind_shift_time[2])
                current_condition.shift_threshold = new_shift_threshold
                --current_condition.shift_threshold = 10  -- for testing purposes
                debug(flag6, "  new_shift_threshold: " .. new_shift_threshold)

                local current_speed = current_condition.wind_speed
                debug(flag6, "  current_speed: " .. current_speed)

                local lower_bound = biome_data.wind_speed_min - current_speed
                local upper_bound = biome_data.wind_speed_max - current_speed
                local new_speed = current_speed + math_random(lower_bound, upper_bound)
                current_condition.wind_speed = new_speed
                debug(flag6, "  new_speed: " .. new_speed)
            end

        else
            debug(flag6, "  wind not yet simulated for this biome. initializing winds..")
            wind_conditions[biome_name] = {
                wind_speed = math_random(biome_data.wind_speed_min, biome_data.wind_speed_max),
                shift_timer = 0,
                shift_threshold = math_random(biome_data.wind_shift_time[1], biome_data.wind_shift_time[2])
                --shift_threshold = 10 -- for testing purposes
            }
        end

    end
    mod_storage:set_string("wind_conditions", mt_serialize(wind_conditions))
    debug(flag6, "  wind_conditions (after): " .. dump(wind_conditions))

    -- reset table for next cycle
    active_biomes = {}
    debug(flag6, "wind_simulator END")
    mt_after(1, wind_simulator)
end




local flag9 = false
local function get_radiant_effect(p_data, player_pos)
    debug(flag9, "    get_radiant_effect()")

    if not radiant_sources or next(radiant_sources) == nil then
        debug(flag9, "      no nearby radiant sources. no further action.")
        debug(flag9, "    get_radiant_effect() END")
        return 0
    end

    local total_radiant_effect = 0
    for pos_key, source_data in pairs(radiant_sources) do
        local src_pos = key_to_pos(pos_key)

        -- Decide waist height based on crouch
        local waist_height
        if string.sub(p_data.current_anim_state, 1, 6) == "crouch" then
            debug(flag9, "      player crouched")
            waist_height = 0.9
        else
            debug(flag9, "      player not crouched")
            waist_height = 1.6
        end

        -- Radiant source offset for more accurate distance
        local offset = source_data.pos_offset

        local distance = vector.distance(
            {x = player_pos.x + 0.5, y = player_pos.y + waist_height, z = player_pos.z + 0.5},
            {x = src_pos.x + offset.x, y = src_pos.y + offset.y, z = src_pos.z + offset.z}
        )

        debug(flag9, "      " .. source_data.name .. ", distance = " .. distance)

        local max_distance = source_data.max_distance
        local min_distance = source_data.min_distance

        if distance <= max_distance then
            debug(flag9, "      within effective distance")

            -- calculate distance_factor based on distance between player and radiant object,
            -- and how distance_factor relates to min_distance and max_distance
            local distance_factor
            if distance < min_distance then
                distance_factor = 1 + (min_distance - distance)
            elseif distance > max_distance then
                distance_factor = 0
            else
                distance_factor = 1 - ((distance - min_distance) / (max_distance - min_distance))
            end

            -- Final source effect is the source temperature modifier, scaled by distance_factor
            local source_effect = source_data.temp_modifier * distance_factor
            debug(flag9, "      source_temp " .. source_data.temp_modifier ..
                              ", distance_factor " .. distance_factor ..
                              ", effect " .. source_effect)

            total_radiant_effect = total_radiant_effect + source_effect
        else
            debug(flag9, "      too far from player. no radiant temp effect.")
        end
    end

    debug(flag9, "    total_radiant_effect: " .. total_radiant_effect)
    debug(flag9, "    get_radiant_effect() END")
    return total_radiant_effect
end


local flag7 = false
local function update_feels_like_temp(player, pos, biome_name, wind_speed, humidity_modifier, wind_modifier, p_data)
    debug(flag7, "  update_feels_like_temp()")

    -- get biome data
    local biome_data = BIOME_DATA[biome_name]
    local TEMP_MIN  = biome_data.temp_min  -- Fahrenheit
    local TEMP_MAX  = biome_data.temp_max  -- Fahrenheit
    local HUMID_MIN = biome_data.humidity_min
    local HUMID_MAX = biome_data.humidity_max

    --[[
    0.0 → 12:00 AM (midnight)
    0.25 → 6:00 AM (sunrise)
    0.5 → 12:00 PM (noon)
    0.75 → 6:00 PM (sunset)
    1.0 → 12:00 AM of the next day
    --]]
    local time_of_day = core.get_timeofday()

    -- get 'time_shift' which will adjust the timing of when the hottest and
    -- coldest temp of the day will occur
    local shift_hours = BIOME_DATA[biome_name].temp_time_shift
    local time_shift = shift_hours / 24.0
    --debug(flag7, "    time_shift: " .. time_shift)

    -- calculate time of day fraction. use simple sine wave so hottest and coldest
    -- temperature occurs at 4pm and 4am respectively. the actual timing is modified
    -- by 'time_shift' which is based on the biome's climate characteristics
    local day_angle = ((time_of_day - 0.4167) - time_shift) * (2.0 * math.pi)
    local day_fraction = 0.5 * (math.sin(day_angle) + 1.0)
    --debug(flag7, "    day_fraction: " .. day_fraction)

    -- calculate baseline air temp from time of day
    local base_air_temp = TEMP_MIN + (TEMP_MAX - TEMP_MIN) * day_fraction
    p_data.thermal_air_temp = base_air_temp
    debug(flag7, "    air temp range: " .. TEMP_MIN .. " to " .. TEMP_MAX)
    debug(flag7, "    base_air_temp: " .. base_air_temp)

    -- calculate elevation effect by subtracting ~1.8 °F per 1000 meters of altitude
    local ELEVATION_LAPSE_PER_1000FT = 1.8
    local elev_factor = (pos.y / 1000.0) * ELEVATION_LAPSE_PER_1000FT
    p_data.thermal_factor_elevation = elev_factor
    debug(flag7, "    elev_factor: " .. -elev_factor)

    -- calculate humidity fraction, shifting with time of day
    local current_humidity = HUMID_MIN + (HUMID_MAX - HUMID_MIN) * day_fraction
    current_humidity = clamp(current_humidity, 0, 100)
    p_data.thermal_humidity = current_humidity
    debug(flag7, "    humidity range: " .. HUMID_MIN .. " to " .. HUMID_MAX)
    debug(flag7, "    current_humidity: " .. current_humidity)

    -- calculate humidity effect
    local humidity_effect = 0
    if base_air_temp >= 50.0 then
      humidity_effect = current_humidity / 10  -- e.g. up to +10 °F at 100% humidity
      humidity_effect = humidity_effect * humidity_modifier
    else
        debug(flag7, "    air temp too low for humidity effect")
    end
    p_data.thermal_factor_humidity = humidity_effect
    debug(flag7, "    humidity_effect: " .. humidity_effect)

    -- calculate wind effect
    local chill_amount = 0
    if base_air_temp < 60.0 and wind_speed > 0 then
      -- wind drops temperature down by 12 °F for strong wind
      local wind_factor = clamp(wind_speed / 10.0, 0, 1)  -- up to 1 for >=10 m/s
      chill_amount = 12.0 * wind_factor
      chill_amount = chill_amount * wind_modifier
    else
        debug(flag7, "    air temp too high for wind chill effect")
    end
    p_data.thermal_factor_wind = chill_amount
    debug(flag7, "    wind_speed: " .. wind_speed)
    debug(flag7, "    wind chill_amount: " .. -chill_amount)

    -- calculate sun exposure effect
    local cloud_density = player:get_clouds().density or 0
    local sun_factor = 0
    if time_of_day > 0.25 and time_of_day < 0.75 then
      local no_cloud_factor = (1.0 - cloud_density)
      sun_factor = 3.0 * no_cloud_factor

    end
    p_data.thermal_factor_sun = sun_factor
    debug(flag7, "    sun_factor: " .. sun_factor)

    local is_underwater = p_data.underwater
    if is_underwater then
        debug(flag7, "    player is underwater")

        -- get water depth of the player
        local water_depth = 0
        local overhead_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
        local overhead_node = mt_get_node(overhead_pos)
        while NODE_NAMES_WATER[overhead_node.name] do
            water_depth = water_depth + 1
            overhead_pos.y = overhead_pos.y + 1
            overhead_node = mt_get_node(overhead_pos)
        end
        debug(flag7, "      water_depth: " .. water_depth)

        -- calculate base water temp and clamp to prevent freeze or boil
        local base_water_temp = clamp(base_air_temp * 0.9, 33, 211)
        debug(flag7, "      base_water_temp: " .. base_water_temp)

        -- calculate depth-based cooling of water, down to a 50 meter limit
        local safe_depth = clamp(water_depth, 0, 50)
        local depth_cooling = safe_depth * 1.25
        debug(flag7, "      depth_cooling: " .. depth_cooling)

        -- add sunlight influence, diminishes with depth
        local sun_influence = sun_factor * 0.2  -- water dampens sunlight
        local depth_factor = clamp(water_depth / 10.0, 0, 1)
        local water_sun_factor = sun_influence * (1 - depth_factor)
        debug(flag7, "      water_sun_factor: " .. water_sun_factor)

        -- calculate wind influence. up to ~2 °F cooling from wind at surface,
        -- diminishing by depth.
        local wind_factor = clamp(wind_speed / 10.0, 0, 1)
        local wind_cooling = 2.0 * wind_factor * (1 - depth_factor)
        debug(flag7, "      wind_cooling: " .. wind_cooling)

        -- calculate humidity influence. dryness = how strong evaporation might be
        local dryness = clamp(1.0 - current_humidity, 0, 1)
        local humidity_cooling = 1.0 * dryness * (1 - depth_factor)
        debug(flag7, "      humidity_cooling: " .. humidity_cooling)

        local water_temp = base_water_temp
                        - depth_cooling
                        + water_sun_factor
                        - wind_cooling
                        - humidity_cooling

        -- calculate water temp, which is essentially the 'feels like' temp
        water_temp = clamp(water_temp, 33, 211)
        p_data.thermal_water_temp = water_temp
        debug(flag7, "      water_temp: " .. water_temp)

        -- get radiant sources effect
        local radiant_effect = get_radiant_effect(p_data, pos)
        p_data.thermal_radiant_temp = radiant_effect
        debug(flag7, "    radiant_effect: " .. radiant_effect)

        -- calculate feels_like_temp
        p_data.thermal_feels_like = water_temp + radiant_effect
        debug(flag7, "    thermal_feels_like: " .. p_data.thermal_feels_like)

    else
        debug(flag7, "    player is on dry land")

        -- calculate feels_like_temp so far
        local feels_like_temp = base_air_temp
                        - elev_factor
                        + humidity_effect
                        - chill_amount
                        + sun_factor

        -- calculate radiant sources effect
        local radiant_effect = get_radiant_effect(p_data, pos)
        p_data.thermal_radiant_temp = radiant_effect
        debug(flag7, "    radiant_effect: " .. radiant_effect)

        -- calculate feels_like_temp
        p_data.thermal_feels_like = feels_like_temp + radiant_effect
        debug(flag7, "    thermal_feels_like: " .. p_data.thermal_feels_like)
    end

    debug(flag7, "  update_feels_like_temp() END")
end


local flag2 = false
local function monitor_weather(player, p_data, player_meta)
    debug(flag2, "\nmonitor_weather()")
    if not player:is_player() then
        debug(flag2, "  player no longer exists. function skipped.")
        debug(flag2, "monitor_weather() END")
        return
    end

    local player_name = player:get_player_name()
    local pos = player:get_pos()
    local biome_name = mt_get_biome_name(mt_get_biome_data(pos).biome)
    p_data.biome_name = biome_name
    debug(flag2, "  biome name: " .. biome_name)

    -- update 'active_biomes' table to indicate a player currently exists in this biome
    active_biomes[biome_name] = true

    if not wind_conditions[biome_name] then
        debug(flag2, "  wind conditions not yet initialized. waiting for next cycle..")
        debug(flag2, "monitor_weather() END")
        local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
        job_handles[player_name].monitor_weather = job_handle
        return
    end

    -- get current wind speed which is different for each biome
    local wind_speed = wind_conditions[biome_name].wind_speed

    -- updates the 'feels like' temperature experienced by the player, based on factors
    -- like time of day, elevation, humidity, wind, sun exposure, being underwater,
    -- and cumulative effects from nearby heating or cooling radiant sources
    update_feels_like_temp(player, pos, biome_name, wind_speed, 1.0, 1.0, p_data)
    local feels_like_temp = p_data.thermal_feels_like

    local prior_thermal_status = p_data.thermal_status

    -- activate cold_4 'FREEZING'
    if feels_like_temp < 11 then

        -- prior status effect 'cold_4'
        if prior_thermal_status == "freezing" then
            debug(flag2, "  prior thermal status was already cold_4 'freezing'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            debug(flag2, "  going from cold_3 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            debug(flag2, "  going from cold_2 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            debug(flag2, "  going from cold_1 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            debug(flag2, "  going to cold_4")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "cold", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            debug(flag2, "  going from hot_1 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            debug(flag2, "  going from hot_2 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_4_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 2, COMFORT_DRAIN_VAL_HOT_2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            debug(flag2, "  going from hot_3 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_4_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 3, HP_DRAIN_VAL_HOT_3)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 3, COMFORT_DRAIN_VAL_HOT_3)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            debug(flag2, "  going from hot_4 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_4_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 4, HP_DRAIN_VAL_HOT_4)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 4, COMFORT_DRAIN_VAL_HOT_4)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    -- activate cold_3 'FRIGID'
    elseif feels_like_temp < 31 then

        -- prior status effect 'cold_3'
        if prior_thermal_status == "frigid" then
            debug(flag2, "  prior thermal status was already cold_3 'frigid'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

            -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            debug(flag2, "  going from cold_4 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_3_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 4, COMFORT_DRAIN_VAL_COLD_4)
            recover_drained_stat(player, p_data, player_meta, "health", "cold", 4, HP_DRAIN_VAL_COLD_4)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            debug(flag2, "  going from cold_2 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            debug(flag2, "  going from cold_1 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            debug(flag2, "  going to cold_3")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "cold", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            debug(flag2, "  going from hot_1 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            debug(flag2, "  going from hot_2 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_3_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 2, COMFORT_DRAIN_VAL_HOT_2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            debug(flag2, "  going from hot_3 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_3_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 3, HP_DRAIN_VAL_HOT_3)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 3, COMFORT_DRAIN_VAL_HOT_3)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            debug(flag2, "  going from hot_4 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_3_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 4, HP_DRAIN_VAL_HOT_4)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 4, COMFORT_DRAIN_VAL_HOT_4)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    -- activate cold_2 'COLD'
    elseif feels_like_temp < 46 then

        -- prior status effect 'cold_2'
        if prior_thermal_status == "cold" then
            debug(flag2, "  prior thermal status was already cold_2 'cold'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            debug(flag2, "  going from cold_4 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_2_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 4, COMFORT_DRAIN_VAL_COLD_4)
            recover_drained_stat(player, p_data, player_meta, "health", "cold", 4, HP_DRAIN_VAL_COLD_4)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            debug(flag2, "  going from cold_3 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_2_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 3, COMFORT_DRAIN_VAL_COLD_3)
            recover_drained_stat(player, p_data, player_meta, "health", "cold", 3, HP_DRAIN_VAL_COLD_3)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            debug(flag2, "  going from cold_1 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_2_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            debug(flag2, "  going to cold_2")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "cold", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_2_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            debug(flag2, "  going from hot_1 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_2_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            debug(flag2, "  going from hot_2 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_2_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 2, COMFORT_DRAIN_VAL_HOT_2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            debug(flag2, "  going from hot_3 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_2_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 3, HP_DRAIN_VAL_HOT_3)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 3, COMFORT_DRAIN_VAL_HOT_3)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            debug(flag2, "  going from hot_4 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_2_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 4, HP_DRAIN_VAL_HOT_4)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 4, COMFORT_DRAIN_VAL_HOT_4)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    -- activate cold_1 'COOL'
    elseif feels_like_temp < 61 then

        -- prior status effect 'cold_1'
        if prior_thermal_status == "cool" then
            debug(flag2, "  prior thermal status was already cold_1 'cool'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            debug(flag2, "  going from cold_4 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_1_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 4, COMFORT_DRAIN_VAL_COLD_4)
            recover_drained_stat(player, p_data, player_meta, "health", "cold", 4, HP_DRAIN_VAL_COLD_4)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            debug(flag2, "  going from cold_3 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_1_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 3, COMFORT_DRAIN_VAL_COLD_3)
            recover_drained_stat(player, p_data, player_meta, "health", "cold", 3, HP_DRAIN_VAL_COLD_3)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            debug(flag2, "  going from cold_2 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_1_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 2, COMFORT_DRAIN_VAL_COLD_2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            debug(flag2, "  going to cold_1")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "cold", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_1_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            debug(flag2, "  going from hot_1 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_1_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            debug(flag2, "  going from hot_2 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_1_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 2, COMFORT_DRAIN_VAL_HOT_2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            debug(flag2, "  going from hot_3 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_1_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 3, HP_DRAIN_VAL_HOT_3)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 3, COMFORT_DRAIN_VAL_HOT_3)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            debug(flag2, "  going from hot_4 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_1_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 4, HP_DRAIN_VAL_HOT_4)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 4, COMFORT_DRAIN_VAL_HOT_4)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    -- activate 'NICE'
    elseif feels_like_temp < 81 then

        -- no status effect
        if prior_thermal_status == "nice" then
            debug(flag2, "  prior thermal status was already 'nice'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- new player startup into 'nice'
        elseif prior_thermal_status == "" then
            debug(flag2, "  new player spawned into world at 'nice' temperature")
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            debug(flag2, "  going from cold_4 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_0_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 4, COMFORT_DRAIN_VAL_COLD_4)
            recover_drained_stat(player, p_data, player_meta, "health", "cold", 4, HP_DRAIN_VAL_COLD_4)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            debug(flag2, "  going from cold_3 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_0_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 3, COMFORT_DRAIN_VAL_COLD_3)
            recover_drained_stat(player, p_data, player_meta, "health", "cold", 3, HP_DRAIN_VAL_COLD_3)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            debug(flag2, "  going from cold_2 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_0_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 2, COMFORT_DRAIN_VAL_COLD_2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            debug(flag2, "  going from cold_1 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["cold_0_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "cold", 1, COMFORT_DRAIN_VAL_COLD_1)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            debug(flag2, "  going from hot_1 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_0_down"], 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            debug(flag2, "  going from hot_2 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_0_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 2, COMFORT_DRAIN_VAL_HOT_2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            debug(flag2, "  going from hot_3 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_0_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 3, HP_DRAIN_VAL_HOT_3)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 3, COMFORT_DRAIN_VAL_HOT_3)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            debug(flag2, "  going from hot_4 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_0_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 4, HP_DRAIN_VAL_HOT_4)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 4, COMFORT_DRAIN_VAL_HOT_4)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end


    -- activate hot_1 'WARM'
    elseif feels_like_temp < 96 then

        -- prior status effect 'hot_1'
        if prior_thermal_status == "warm" then
            debug(flag2, "  prior thermal status was already hot_1 'warm'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            debug(flag2, "  going from cold_4 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_1_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            debug(flag2, "  going from cold_3 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_1_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            debug(flag2, "  going from cold_2 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_1_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            debug(flag2, "  going from cold_1 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_1_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            debug(flag2, "  going to hot_1")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "hot", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_1_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            debug(flag2, "  going from hot_2 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_1_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 2, COMFORT_DRAIN_VAL_HOT_2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            debug(flag2, "  going from hot_3 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_1_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 3, HP_DRAIN_VAL_HOT_3)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 3, COMFORT_DRAIN_VAL_HOT_3)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            debug(flag2, "  going from hot_4 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_1_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 4, HP_DRAIN_VAL_HOT_4)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 4, COMFORT_DRAIN_VAL_HOT_4)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end


    -- activate hot_2 'HOT'
    elseif feels_like_temp < 106 then

        -- prior status effect 'hot_2'
        if prior_thermal_status == "hot" then
            debug(flag2, "  prior thermal status was already hot_2 'hot'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            debug(flag2, "  going from cold_4 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_2_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            debug(flag2, "  going from cold_3 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_2_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            debug(flag2, "  going from cold_2 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_2_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            debug(flag2, "  going from cold_1 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_2_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            debug(flag2, "  going to hot_2")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "hot", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_2_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            debug(flag2, "  going from hot_1 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_2_up"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 2, COMFORT_DRAIN_VAL_HOT_2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            debug(flag2, "  going from hot_3 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_2_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 3, HP_DRAIN_VAL_HOT_3)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 3, COMFORT_DRAIN_VAL_HOT_3)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            debug(flag2, "  going from hot_4 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_2_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 4, HP_DRAIN_VAL_HOT_4)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 4, COMFORT_DRAIN_VAL_HOT_4)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end


    -- activate hot_3 'SWELTERING'
    elseif feels_like_temp < 121 then

        -- prior status effect 'hot_3'
        if prior_thermal_status == "sweltering" then
            debug(flag2, "  prior thermal status was already hot_3 'sweltering'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            debug(flag2, "  going from cold_4 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            debug(flag2, "  going from cold_3 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            debug(flag2, "  going from cold_2 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            debug(flag2, "  going from cold_1 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            debug(flag2, "  going to hot_3")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "hot", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            debug(flag2, "  going from hot_1 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            debug(flag2, "  going from hot_2 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_3_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            debug(flag2, "  going from hot_4 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_3_down"], 2, 1.5, 0, 2)
            recover_drained_stat(player, p_data, player_meta, "health", "hot", 4, HP_DRAIN_VAL_HOT_4)
            recover_drained_stat(player, p_data, player_meta, "comfort", "hot", 4, COMFORT_DRAIN_VAL_HOT_4)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end


    -- activate hot_4 'SCORCHING'
    else

        -- prior status effect 'hot_4'
        if prior_thermal_status == "scorching" then
            debug(flag2, "  prior thermal status was already hot_4 'scorching'. no further aciton.")
            debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            debug(flag2, "  going from cold_4 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            debug(flag2, "  going from cold_3 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            debug(flag2, "  going from cold_2 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            debug(flag2, "  going from cold_1 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            debug(flag2, "  going to hot_4")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "hot", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            debug(flag2, "  going from hot_1 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            debug(flag2, "  going from hot_2 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            debug(flag2, "  going from hot_3 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "warning", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, STAT_EFFECT_TEXTS["hot_4_up"], 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    end

    debug(flag2, "monitor_weather() END")
    local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
    job_handles[player_name].monitor_weather = job_handle
end


-- start wind simulator
wind_simulator()




local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() WEATHER")
    local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local player_status = player_meta:get_int("player_status")
    local p_data = player_data[player_name]

    p_data.thermal_radiant_temp = 0
    p_data.thermal_status = ""

	if player_status == 0 then
		debug(flag1, "  new player")

        p_data.thermal_units = 1
        player_meta:set_int("thermal_units", p_data.thermal_units)

            -- use 1.5 second delay to allow world and player to spawn, and for
            -- wind_monitor() to activate before accessing necessary environment data
        if ENABLE_WEATHER_MONITOR then
            local job_handle = mt_after(1.0, monitor_weather, player, player_data[player_name], player_meta)
            job_handles[player_name].monitor_weather = job_handle
            debug(flag1, "  started weather monitor")
        end

	elseif player_status == 1 then
		debug(flag1, "  existing player")

        p_data.thermal_units = player_meta:get_int("thermal_units")

        if ENABLE_WEATHER_MONITOR then
            local job_handle = mt_after(1, monitor_weather, player, player_data[player_name], player_meta)
            job_handles[player_name].monitor_weather = job_handle
            debug(flag1, "  started weather monitor")
        end

    elseif player_status == 2 then
		debug(flag1, "  dead player")

	end

	debug(flag1, "\nregister_on_joinplayer() end")
end)




local flag3 = false
core.register_on_dieplayer(function(player)
    debug(flag3, "\nregister_on_dieplayer() WEATHER")
    local player_name = player:get_player_name()

    debug(flag3, "  cancel monitor_weather() loop..")
    local job_handle = job_handles[player_name].monitor_weather
    job_handle:cancel()
    job_handles[player_name].monitor_weather = nil

	debug(flag3, "register_on_dieplayer() end")
end)


local flag4 = false
core.register_on_respawnplayer(function(player)
    debug(flag4, "\nregister_on_respawnplayer() WEATHER")
    local player_name = player:get_player_name()

    -- not resetting any of the weather/thermal properties as it continue with existing
    -- values after player respawn

    debug(flag4, "  start weather monitor")
    if ENABLE_WEATHER_MONITOR then
        local job_handle = mt_after(1, monitor_weather, player, player_data[player_name], player:get_meta())
        job_handles[player_name].monitor_weather = job_handle
        debug(flag4, "  enabled weather monitor")
    end

	debug(flag4, "register_on_respawnplayer() end")
end)


local flag5 = false
core.register_on_leaveplayer(function(player)
    debug(flag5, "\nregister_on_leaveplayer() WEATHER")
    local player_name = player:get_player_name()
    local job_handle = job_handles[player_name].monitor_weather
    if job_handle then
        job_handle:cancel()
        job_handles[player_name].monitor_weather = nil
        debug(flag5, "  cancel monitor_weather() loop..")
    end
    debug(flag5, "register_on_leaveplayer() END")
end)

