print("- loading weather.lua")

-- cache global functions for faster access
local math_min = math.min
local math_sin = math.sin
local math_random = math.random
local string_sub = string.sub
local table_insert = table.insert
local table_copy = table.copy
local mt_get_modpath = core.get_modpath
local mt_get_timeofday = core.get_timeofday
local mt_after = core.after
local mt_sound_play = core.sound_play
local mt_serialize = core.serialize
local mt_deserialize = core.deserialize
local mt_get_node = core.get_node
local mt_get_biome_name = core.get_biome_name
local mt_get_biome_data = core.get_biome_data
local debug = ss.debug
local lerp = ss.lerp
local after_player_check = ss.after_player_check
local hide_stat_effect = ss.hide_stat_effect
local do_stat_update_action = ss.do_stat_update_action
local show_stat_effect = ss.show_stat_effect
local play_sound = ss.play_sound
local notify = ss.notify
local key_to_pos = ss.key_to_pos

-- cache global variables for faster access
local math_pi = math.pi
local STATUS_EFFECT_INFO = ss.STATUS_EFFECT_INFO
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local job_handles = ss.job_handles
local player_data = ss.player_data
local mod_storage = ss.mod_storage


local ENABLE_WEATHER_MONITOR = true

-- ss.radiant_sources = {
--     <pos_key> = { name = <source item name>, temperature = <source temperature>, max_distance = <number>},
--     ["101,12,-25"] = {name = "ss:torch", temperature = 150, max_distance = 2.0},
--     ["-5,122,76"] = {name = "ss:portable_cooler", temperature = 35, max_distance = 4.0}
-- }
ss.radiant_sources = {}
local radiant_sources = ss.radiant_sources



--[[
ss.current_climates = {
    savanna = {
        air_temp = ?,
        humidity = ?,
        humidity_factor = ?,
        wind_factor = ?, 
        water_temp = ?,
        wind_speed = ?,
        wind_shift_limit = ?,
        wind_shift_timer = ?
    },
}
--]]
ss.current_climates = mt_deserialize(mod_storage:get_string("current_climates"))
if ss.current_climates == nil then ss.current_climates = {} end  -- occurs on new game initial start up
local current_climates = ss.current_climates
if current_climates == nil then print("### ERROR - ss.current_climates is NIL") end



-- active_biomes = {
--     savanna = true,
--     rainforest = true
-- }
local active_biomes = {}

local function refresh_active_biomes()
    -- Keep a reference to the old table so we know which biomes were active before
    local old_active = active_biomes

    -- Build a new table for fresh data
    local new_active = {}

    -- Check each connected player
    for _, player in ipairs(core.get_connected_players()) do
        local pos = player:get_pos()
        local biome_data = mt_get_biome_data(pos)
        if biome_data then
            local biome_name = mt_get_biome_name(biome_data.biome)
            if biome_name then
                new_active[biome_name] = true
            end
        end
    end

    -- Any biome that was active but isn't in new_active is now inactive,
    -- so remove it from current_climates
    for biome_name in pairs(old_active) do
        if not new_active[biome_name] then
            current_climates[biome_name] = nil
        end
    end

    active_biomes = new_active
end



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
                        table_insert(fields, nil)
                    else
                        local num = tonumber(val)
                        if num then
                            table_insert(fields, num)
                        else
                            table_insert(fields, val)
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
ss.BIOME_DATA_DEFAULTS = table_copy(ss.BIOME_DATA)



-- helper function mostly used in 'update_feels_like_temp()'
local function clamp(val, min_val, max_val)
    if val < min_val then return min_val end
    if val > max_val then return max_val end
    return val
end


local flag8 = false
local function climate_simulator()
    debug(flag8, "\nclimate_simulator()")
    --debug(flag8, "  current_climates (before): " .. dump(current_climates))

    refresh_active_biomes()

    for biome_name in pairs(active_biomes) do
        --debug(flag8, "  simulating climate for biome: " .. biome_name)

        local biome_data = BIOME_DATA[biome_name]
        local biome_climate = current_climates[biome_name]

        if not biome_climate then
            --debug(flag8, "  biome_climate is NIL from new game start. initializing for: " .. biome_name)
            current_climates[biome_name] = {}
            biome_climate = current_climates[biome_name]
        end

        -- 0.0 → 12:00 AM (midnight)
        -- 0.25 → 6:00 AM (sunrise)
        -- 0.5 → 12:00 PM (noon)
        -- 0.75 → 6:00 PM (sunset)
        -- 1.0 → 12:00 AM of the next day
        local time_of_day = mt_get_timeofday()

        -- get 'time_shift' which will adjust the timing of when the hottest and
        -- coldest temp of the day will occur
        local shift_hours = BIOME_DATA[biome_name].temp_time_shift
        local time_shift = shift_hours / 24.0

        -- calculate time of day fraction. use simple sine wave so hottest and coldest
        -- temperature occurs at 4pm and 4am respectively. the actual timing is modified
        -- by 'time_shift' which is based on the biome's climate characteristics
        local day_angle = ((time_of_day - 0.4167) - time_shift) * (2.0 * math_pi)
        local day_fraction = 0.5 * (math_sin(day_angle) + 1.0)
        --debug(flag8, "  day_fraction: " .. day_fraction)

        -- calculate baseline air temperature from time of day
        local TEMP_MIN  = biome_data.temp_min  -- Fahrenheit
        local TEMP_MAX  = biome_data.temp_max  -- Fahrenheit
        local base_air_temp = TEMP_MIN + (TEMP_MAX - TEMP_MIN) * day_fraction
        biome_climate.air_temp = base_air_temp
        --debug(flag8, "  base_air_temp: " .. base_air_temp)

        -- calculate relative humidity value, shifting with time of day
        local HUMID_MIN = biome_data.humidity_min
        local HUMID_MAX = biome_data.humidity_max
        local humidity = HUMID_MIN + (HUMID_MAX - HUMID_MIN) * day_fraction
        humidity = clamp(humidity, 0, 100)
        biome_climate.humidity = humidity
        --debug(flag8, "  humidity: " .. humidity)

        -- calculate humidity factor
        local humidity_factor = 0
        if base_air_temp >= 50.0 then
            humidity_factor = humidity / 10  -- e.g. up to +10 °F at 100% humidity
        end
        biome_climate.humidity_factor = humidity_factor
        --debug(flag8, "  humidity_factor: " .. humidity_factor)

        if biome_climate.wind_shift_timer then
            --debug(flag8, "  prior wind data exists. continue with existing data..")
            local current_timer = biome_climate.wind_shift_timer
            local shift_limit = biome_climate.wind_shift_limit
            --debug(flag8, "    current_timer: " .. current_timer)
            --debug(flag8, "    shift_limit: " .. shift_limit)

            if current_timer < shift_limit then
                --debug(flag8, "    shift timer not reached. wind speed unchanged: " .. biome_climate.wind_speed .. " m/s")
                biome_climate.wind_shift_timer = current_timer + 1

            else
                --debug(flag8, "    timer reached. changing wind speed..")
                biome_climate.wind_shift_timer = 0
                local new_shift_limit = math_random(biome_data.wind_shift_time[1], biome_data.wind_shift_time[2])
                biome_climate.wind_shift_limit = new_shift_limit
                --biome_climate.wind_shift_limit = 5  -- for testing purposes
                --debug(flag8, "    new_shift_limit: " .. new_shift_limit)

                local current_wind_speed = biome_climate.wind_speed
                --debug(flag8, "    current_wind_speed: " .. current_wind_speed)

                local lower_bound = biome_data.wind_speed_min - current_wind_speed
                local upper_bound = biome_data.wind_speed_max - current_wind_speed
                local new_wind_speed = current_wind_speed + math_random(lower_bound, upper_bound)
                biome_climate.wind_speed = new_wind_speed
                --debug(flag8, "    new_wind_speed: " .. new_wind_speed)
                if new_wind_speed == nil then print("### new_wind_speed is NIL") end -- for testing purposes
            end

        else
            --debug(flag8, "  wind data uninitialized. setting new values..")
            biome_climate.wind_speed = math_random(biome_data.wind_speed_min, biome_data.wind_speed_max)
            biome_climate.wind_shift_limit = math_random(biome_data.wind_shift_time[1], biome_data.wind_shift_time[2])
            --biome_climate.wind_shift_limit = 5  -- for testing purposes
            biome_climate.wind_shift_timer = 0
        end

    end
    mod_storage:set_string("current_climates", mt_serialize(current_climates))
    --debug(flag8, "  current_climates (after): " .. dump(current_climates))

    debug(flag8, "climate_simulator END")
    mt_after(1, climate_simulator)
end


local sound_handles = {}

local flag6 = false
local function simulate_wind_sounds(player, p_data, player_name, biome_climate)
    debug(flag6, "  simulate_wind_sounds()")

    local wind_speed = biome_climate.wind_speed -- m/s
    debug(flag6, "    wind_speed: " .. wind_speed)

    if wind_speed > 18 then
        debug(flag6, "    steady loudest sounds")
        -- play looped sound, loudest volume

    elseif wind_speed > 16 then
        debug(flag6, "    gale force winds")
        -- play looped sound, louder volume

    elseif wind_speed > 12 then
        debug(flag6, "    near gale force winds")
        -- play looped sound, medium volume

    elseif wind_speed > 8 then
        debug(flag6, "    breezy winds")
        -- play looped sound, soft volume

    elseif wind_speed > 4 then
        debug(flag6, "    moderate breeze")
        -- play non looped sound, softest volume
        -- 70% to play immediately after current sound ends

    elseif wind_speed > 2 then
        debug(flag6, "    light breeze")
        -- play non looped sound, softest volume
        -- 30% to play immediately after current sound ends

        -- do random roll
        -- if success, play sound with fade in and no fade out
        -- play looped sound immediately after
        -- if failed, player sound with fade out
        -- with each succesful sound play, do a random roll

    else
        debug(flag6, "    calm")
    end



    if p_data.wind_sound_timer < 8 then
        debug(flag6, "    wind sound playing..")
        p_data.wind_sound_timer = p_data.wind_sound_timer + 1
        debug(flag6, "    wind_sound_timer: " .. p_data.wind_sound_timer)

    else
        debug(flag6, "    fading out existing wind sound..")
        local handle = sound_handles[player_name]
        if handle then
            core.sound_fade(handle, p_data.wind_sound_fade, 0)
            sound_handles[player_name] = nil
            debug(flag6, "    sound fade out successful")
        else
            debug(flag6, "    no existing sounds")
        end
        debug(flag6, "    attempting to play new sound..")
        if math_random(1,4) < 4 then
            debug(flag6, "    actually, wind silent for now..")
            p_data.wind_sound_timer = 8
        else
            debug(flag6, "    wind will continue")
            local random_num = math_random(-1,1)/100
            local gain = p_data.wind_sound_gain + random_num
            if random_num > 0 then
                debug(flag6, "    increasing gain")
                if gain > 0.07 then gain = 0.07 end
            elseif random_num < 0 then
                debug(flag6, "    decreasing gain")
                if gain < 0.03 then gain = 0.03 end
            end
            p_data.wind_sound_gain = gain
            debug(flag6, "    final gain: " .. gain)
            local fade = gain / 3
            p_data.wind_sound_fade = fade
            sound_handles[player_name] = mt_sound_play("ss_wind", {gain = gain, pitch = 1, fade = fade, loop = false})
            p_data.wind_sound_timer = 0
        end

    end









end




local flag9 = false
local function get_radiant_effect(p_data, player_pos)
    debug(flag9, "    get_radiant_effect()")

    if not radiant_sources or next(radiant_sources) == nil then
        --debug(flag9, "      no nearby radiant sources. no further action.")
        --debug(flag9, "    get_radiant_effect() END")
        return 0
    end

    local total_radiant_effect = 0
    for pos_key, source_data in pairs(radiant_sources) do
        local src_pos = key_to_pos(pos_key)

        -- Decide waist height based on crouch
        local waist_height
        if string_sub(p_data.current_anim_state, 1, 6) == "crouch" then
            --debug(flag9, "      player crouched")
            waist_height = 0.9
        else
            --debug(flag9, "      player not crouched")
            waist_height = 1.6
        end

        -- Radiant source offset for more accurate distance
        local offset = source_data.pos_offset

        local distance = vector.distance(
            {x = player_pos.x + 0.5, y = player_pos.y + waist_height, z = player_pos.z + 0.5},
            {x = src_pos.x + offset.x, y = src_pos.y + offset.y, z = src_pos.z + offset.z}
        )

        --debug(flag9, "      " .. source_data.name .. ", distance = " .. distance)

        local max_distance = source_data.max_distance
        local min_distance = source_data.min_distance

        if distance <= max_distance then
            --debug(flag9, "      within effective distance")

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
            --debug(flag9, "      source_temp " .. source_data.temp_modifier ..
            --                  ", distance_factor " .. distance_factor ..
            --                  ", effect " .. source_effect)

            total_radiant_effect = total_radiant_effect + source_effect
        else
            --debug(flag9, "      too far from player. no radiant temp effect.")
        end
    end

    --debug(flag9, "    total_radiant_effect: " .. total_radiant_effect)
    debug(flag9, "    get_radiant_effect() END")
    return total_radiant_effect
end


local flag7 = false
-- updates the 'feels like' temperature experienced by the player, based on factors
-- like time of day, elevation, humidity, wind, sun exposure, being underwater,
-- and cumulative effects from nearby heating or cooling radiant sources
local function update_feels_like_temp(player, pos, biome_climate, humidity_modifier, wind_modifier, p_data)
    debug(flag7, "  update_feels_like_temp()")

    local base_air_temp = biome_climate.air_temp
    local wind_speed = biome_climate.wind_speed

    p_data.thermal_air_temp = base_air_temp
    p_data.thermal_humidity = biome_climate.humidity

    -- elevation lapse-rate: −1.8 °F per 1000 ft
    local elev_factor = (pos.y / 1000.0) * 1.8
    p_data.thermal_factor_elevation = -elev_factor
    --debug(flag7, "    elev_factor: " .. -elev_factor)

    -- calculate humidity factor
    local humidity_factor = biome_climate.humidity_factor * humidity_modifier
    p_data.thermal_factor_humidity = humidity_factor
    --debug(flag7, "    humidity_factor: " .. humidity_factor)
    --debug(flag7, "    biome_climate.humidity: " .. biome_climate.humidity)

    -- calculate wind effect
    local chill_amount = 0
    if base_air_temp < 60.0 and wind_speed > 0 then
      -- wind drops temperature down by 12 °F for strong wind
      local wind_factor = clamp(wind_speed / 10.0, 0, 1)  -- up to 1 for >=10 m/s
      chill_amount = 12.0 * wind_factor * wind_modifier
    else
        --debug(flag7, "    air temp too high for wind chill effect")
    end
    p_data.thermal_factor_wind = -chill_amount
    --debug(flag7, "    wind_speed: " .. wind_speed)
    --debug(flag7, "    wind chill_amount: " .. -chill_amount)

    -- calculate sun exposure effect
    local cloud_density = player:get_clouds().density or 0
    local sun_factor = 0
    local time_of_day = core.get_timeofday()
    if time_of_day > 0.25 and time_of_day < 0.75 then
      local no_cloud_factor = (1.0 - cloud_density)
      sun_factor = 3.0 * no_cloud_factor
    end
    p_data.thermal_factor_sun = sun_factor
    --debug(flag7, "    sun_factor: " .. sun_factor)

    ------------------------------------------------------------------
    -- *** REVISED: Gradual wetness cooling factor ***
    ------------------------------------------------------------------
    local wet_ratio = p_data.wetness_ratio

    -- STEP A · Find the “baseline max-cooling” for this dry-bulb air temperature
    -- We interpolate through these keyframes:
    --   (  0°F → -18)  (32°F → -12)  (60°F → -10)  (70°F → -8)
    --   ( 80°F →  -6)  (100°F → -6)
    local t = base_air_temp
    local max_cool

    if     t <= 32 then                                 -- 0 → 32°F
        -- linear 0 → -18  ···  32 → -12
        local k = (t - 0) / (32 - 0)
        max_cool = lerp(-18, -12, k)

    elseif t <= 60 then                                 -- 32 → 60°F
        -- 32 → -12  ···  60 → -10
        local k = (t - 32) / (60 - 32)
        max_cool = lerp(-12, -10, k)

    elseif t <= 70 then                                 -- 60 → 70°F
        -- 60 → -10  ···  70 → -8
        local k = (t - 60) / (70 - 60)
        max_cool = lerp(-10, -8, k)

    elseif t <= 80 then                                 -- 70 → 80°F
        -- 70 → -8  ···  80 → -6
        local k = (t - 70) / (80 - 70)
        max_cool = lerp(-8, -6, k)

    else                                                -- ≥ 80°F
        max_cool = -6                                   -- plateau in heat
    end

    -- STEP B · Scale by wetness ratio (evaporation / soaked clothing)
    local wetness_factor = max_cool * wet_ratio

    -- STEP C · Extra freezing penalty if liquid turns to ice on skin.
    -- Below 32 °F we fade-in an additional cooling of up to −6 °F at 0 °F.
    if t < 32 then
        local freeze_k       = clamp((32 - t) / 32, 0, 1)   -- 0 at 32°F → 1 at 0°F
        local freeze_cooling = -6 * freeze_k * wet_ratio
        wetness_factor       = wetness_factor + freeze_cooling
    end

    p_data.thermal_factor_wetness = wetness_factor
    --debug(flag7, "    thermal_factor_wetness: " .. p_data.thermal_factor_wetness)

    local feels_like_so_far
    if p_data.water_level == 100 then
        --debug(flag7, "    player is completely underwater")

        -- get water depth of the player
        local water_depth = 0
        local overhead_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
        local overhead_node = mt_get_node(overhead_pos)
        while NODE_NAMES_WATER[overhead_node.name] do
            water_depth = water_depth + 1
            overhead_pos.y = overhead_pos.y + 1
            overhead_node = mt_get_node(overhead_pos)
        end
        --debug(flag7, "      water_depth: " .. water_depth)

        -- calculate base water temp and clamp to prevent freeze or boil
        local base_water_temp = clamp(base_air_temp * 0.9, 33, 211)
        p_data.thermal_water_temp = base_water_temp
        --debug(flag7, "      base_water_temp: " .. base_water_temp)

        -- calculate depth-based cooling of water, down to a 50 meter limit
        local safe_depth = clamp(water_depth, 0, 50)
        local depth_cooling = safe_depth * 1.25
        p_data.thermal_factor_elevation = -depth_cooling
        --debug(flag7, "      depth_cooling: " .. depth_cooling)

        -- add sunlight influence, diminishes with depth
        local sun_influence = sun_factor * 0.2  -- water dampens sunlight
        local depth_factor = clamp(water_depth / 10.0, 0, 1)
        local water_sun_factor = sun_influence * (1 - depth_factor)
        p_data.thermal_factor_sun = water_sun_factor
        --debug(flag7, "      water_sun_factor: " .. water_sun_factor)

        -- calculate wind influence. up to ~2 °F cooling from wind at surface,
        -- diminishing by depth.
        local wind_factor = clamp(wind_speed / 10.0, 0, 1)
        local wind_cooling = 2.0 * wind_factor * (1 - depth_factor)
        p_data.thermal_factor_wind = -wind_cooling
        --debug(flag7, "      wind_cooling: " .. wind_cooling)

        -- calculate humidity influence. dryness = how strong evaporation might be
        local dryness = clamp(1.0 - (biome_climate.humidity / 100), 0, 1)
        local humidity_cooling = 1.0 * dryness * (1 - depth_factor)
        p_data.thermal_factor_humidity = -humidity_cooling
        --debug(flag7, "      humidity_cooling: " .. humidity_cooling)

        local water_temp = base_water_temp
                        - depth_cooling
                        + water_sun_factor
                        - wind_cooling
                        - humidity_cooling

        -- calculate water temp, which is essentially the 'feels like' temp
        water_temp = clamp(water_temp, 33, 211)
        --debug(flag7, "      water_temp: " .. water_temp)

        local equipment_factor = p_data.equip_buff_water
        p_data.thermal_factor_equipment = equipment_factor
        --debug(flag7, "    equipment_factor: " .. equipment_factor)

        -- get radiant sources effect
        local radiant_effect = get_radiant_effect(p_data, pos)
        p_data.thermal_factor_radiant = radiant_effect
        --debug(flag7, "    radiant_effect: " .. radiant_effect)

        -- calculate feels like temp so far
        feels_like_so_far = water_temp + equipment_factor + radiant_effect

    elseif p_data.water_level > 0 then
        --debug(flag7, "    water depth between 0.5 and 1.0 meters")

        -- calculate feels_like_temp so far
        local feels_like_temp_dry = base_air_temp
                        - elev_factor
                        + humidity_factor
                        - chill_amount
                        + sun_factor
        --debug(flag7, "      feels_like_temp_dry: " .. feels_like_temp_dry)

        -- calculate base water temp and clamp to prevent freeze or boil
        local base_water_temp = clamp(base_air_temp * 0.9, 33, 211)
        p_data.thermal_water_temp = base_water_temp
        --debug(flag7, "      base_water_temp: " .. base_water_temp)

        -- calculate depth-based cooling of water, down to a 50 meter limit
        local depth_cooling = (p_data.water_level/100) * 1.25
        p_data.thermal_factor_elevation = -depth_cooling
        --debug(flag7, "      depth_cooling: " .. depth_cooling)

        -- add sunlight influence, diminishes with depth
        local sun_influence = sun_factor * 0.2  -- water dampens sunlight
        local water_sun_factor = sun_influence * 0.9
        p_data.thermal_factor_sun = water_sun_factor
        --debug(flag7, "      water_sun_factor: " .. water_sun_factor)

        -- calculate wind influence. up to ~1.8 °F cooling from wind at surface,
        -- diminishing by depth.
        local wind_factor = clamp(wind_speed / 10.0, 0, 1)
        local wind_cooling = wind_factor * 1.8
        p_data.thermal_factor_wind = -wind_cooling
        --debug(flag7, "      wind_cooling: " .. wind_cooling)

        -- calculate humidity influence. dryness = how strong evaporation might be
        local dryness = clamp(1.0 - (biome_climate.humidity / 100), 0, 1)
        local humidity_cooling = 1.0 * dryness * 0.9
        p_data.thermal_factor_humidity = -humidity_cooling
        --debug(flag7, "      humidity_cooling: " .. humidity_cooling)

        local water_temp = base_water_temp
                    - depth_cooling
                    + water_sun_factor
                    - wind_cooling
                    - humidity_cooling

        -- calculate water temp, which is essentially the 'feels like' temp
        water_temp = clamp(water_temp, 33, 211)
        --debug(flag7, "      water_temp: " .. water_temp)

        local equipment_factor = p_data.equip_buff_water
        p_data.thermal_factor_equipment = equipment_factor
        --debug(flag7, "    equipment_factor: " .. equipment_factor)

        -- get radiant sources effect
        local radiant_effect = get_radiant_effect(p_data, pos)
        p_data.thermal_factor_radiant = radiant_effect
        --debug(flag7, "    radiant_effect: " .. radiant_effect)

        -- calculate feels like temp so far
        local feels_like_temp_wet = water_temp + equipment_factor + radiant_effect
        --debug(flag7, "    feels_like_temp_wet: " .. feels_like_temp_wet)

        local feels_like_temp_delta = feels_like_temp_dry - feels_like_temp_wet
        local water_level_ratio = p_data.water_level / 100
        local thermal_factor_wetness = -feels_like_temp_delta * water_level_ratio
        p_data.thermal_factor_wetness = thermal_factor_wetness
        --debug(flag7, "    thermal_factor_wetness: " .. thermal_factor_wetness)
        feels_like_so_far = feels_like_temp_dry + thermal_factor_wetness

    else
        --debug(flag7, "    player is not underwater")

        -- calculate feels_like_temp so far
        local feels_like_temp = base_air_temp
                        - elev_factor
                        + humidity_factor
                        - chill_amount
                        + sun_factor
                        + wetness_factor

        --debug(flag7, "      thermal_feels_like (before): " .. feels_like_temp)

        -- use the midpoint of the 'feels like' temperature scale (70 F) to determine
        -- if the clothing or armor will provide cooling or heating effect. and if
        -- temp is within the 60 F to 80F 'nice' range, only apply half of the effect.
        local equipment_factor
        if feels_like_temp > 80 then
            -- apply full heat proection by reducing the temp
            equipment_factor = p_data.equip_buff_heat

        elseif feels_like_temp > 70 then
            -- apply 50% heat proection by reducing the temp
            equipment_factor = p_data.equip_buff_heat/2

        elseif feels_like_temp > 61 then
            -- apply 50% cooling proection by increasing the temp
            equipment_factor = p_data.equip_buff_cold/2

        else
            -- apply full cooling proection by increasing the temp
            equipment_factor = p_data.equip_buff_cold
        end
        p_data.thermal_factor_equipment = equipment_factor
        --debug(flag7, "      equipment_factor: " .. equipment_factor)

        -- calculate radiant sources effect
        local radiant_effect = get_radiant_effect(p_data, pos)
        p_data.thermal_factor_radiant = radiant_effect
        --debug(flag7, "      radiant_effect: " .. radiant_effect)

        -- calculate feels like temp so far
        feels_like_so_far = feels_like_temp + equipment_factor + radiant_effect

    end

    --debug(flag7, "    feels_like_so_far: " .. feels_like_so_far)

    -- apply skill modifiers to the feels like temp
    local feels_like_so_far_2
    if feels_like_so_far > 70 then
        feels_like_so_far_2 = feels_like_so_far - p_data.temperature_mod_crispy_crusader
        if feels_like_so_far_2 < 70 then
            p_data.thermal_factor_skill = -(feels_like_so_far - 70)
            feels_like_so_far_2 = 70
        else
            p_data.thermal_factor_skill = -p_data.temperature_mod_crispy_crusader
        end
        --debug(flag7, "    checking crispy_crusader mod: " .. p_data.temperature_mod_crispy_crusader)

    elseif feels_like_so_far < 70 then
        feels_like_so_far_2 = feels_like_so_far + p_data.temperature_mod_coolossus
        if feels_like_so_far_2 > 70 then
            p_data.thermal_factor_skill = ( 70 - feels_like_so_far)
            feels_like_so_far_2 = 70
        else
            p_data.thermal_factor_skill = p_data.temperature_mod_coolossus
        end
        --debug(flag7, "    checking coolossus mod: " .. p_data.temperature_mod_coolossus)

    else
        --debug(flag7, "    feels like temp is exactly 70F. no further action.")
        feels_like_so_far_2 = 70
    end

    --debug(flag7, "    actual temp mod value applied: " .. p_data.thermal_factor_skill)
    --debug(flag7, "    final feels like temp: " .. feels_like_so_far_2)
    p_data.thermal_feels_like = feels_like_so_far_2

    debug(flag7, "  update_feels_like_temp() END")
end


local flag2 = false
local function monitor_weather(player, p_data, player_meta)
    debug(flag2, "\nmonitor_weather()")
    after_player_check(player)

    local player_name = player:get_player_name()
    local pos = player:get_pos()
    local biome_name = mt_get_biome_name(mt_get_biome_data(pos).biome)
    p_data.biome_name = biome_name
    --debug(flag2, "  biome name: " .. biome_name)

    if not current_climates[biome_name] then
        --debug(flag2, "  current_climates table not yet initialized. waiting for next cycle..")
        --debug(flag2, "monitor_weather() END")
        local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
        job_handles[player_name].monitor_weather = job_handle
        return
    end

    local biome_climate = current_climates[biome_name]

    --simulate_wind_sounds(player, p_data, player_name, biome_climate)

    update_feels_like_temp(player, pos, biome_climate, 1.0, 1.0, p_data)
    local feels_like_temp = p_data.thermal_feels_like

    -- UPDATE WETNESS LEVEL --
    local water_level = p_data.water_level
    local wetness_current = player_meta:get_float("wetness_current")
    --debug(flag2, "  wetness_current: " .. wetness_current)

    if water_level > wetness_current then
        --debug(flag2, "  increase wetness level")
        do_stat_update_action(player, p_data, player_meta, "normal", "wetness", water_level, "curr", "set", true)

    elseif water_level < wetness_current then
        if wetness_current > 0 then
            --debug(flag2, "  decrease wetness level")

            -- calculate how much wetness is reduced in this cycle based on current
            -- feels like temp, wetness level, wind speed, and relative humidity
            local drying_rate
            local wind_speed = biome_climate.wind_speed -- m/s
            local humidity = biome_climate.humidity   -- % RH

            -- wetness is only reduced if temp is above freezing
            if feels_like_temp > 33 then
                -- Normalize temp to [0.0, 1.0] across [34, 150]
                local temp_norm = math_min((feels_like_temp - 34) / (150 - 34), 1)
                local max_rate = lerp(0, 3, temp_norm ^ 1.2) -- slightly nonlinear

                -- slower drying as wetness nears zero
                local wetness_factor = math.sqrt(wetness_current / 100)

                -- faster drying with more wind
                local wind_norm = math_min(wind_speed / 18, 2) -- allow above-normal boost
                local wind_factor = lerp(0.8, 1.4, math_min(wind_norm, 1)) -- 80% to 140% boost

                -- slower drying with higher relative humidity. 120% boost when dry,
                -- slowdown to 60% when near saturated
                local humidity_norm = math_min(humidity / 100, 1)
                local humidity_factor = lerp(1.2, 0.6, humidity_norm)

                drying_rate = max_rate
                    * wetness_factor
                    * wind_factor
                    * humidity_factor
                    * p_data.wetness_drain_mod_equip
                --debug(flag2, "  drying_rate: " .. drying_rate)

                do_stat_update_action(player, p_data, player_meta, "normal", "wetness", -drying_rate, "curr", "add", true)
            else
                --debug(flag2, "  temperature is freezing. no drying possible.")
            end
        else
            --debug(flag2, "  not wet. no further action.")
        end
    else
        --debug(flag2, "  water_level and current wetness is the same. no drying.")
    end

    local prior_thermal_status = p_data.thermal_status

    -- activate cold_4 'FREEZING'
    if feels_like_temp < 11 then

        -- prior status effect 'cold_4'
        if prior_thermal_status == "freezing" then
            --debug(flag2, "  prior thermal status was already cold_4 'freezing'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            --debug(flag2, "  going from cold_3 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            --debug(flag2, "  going from cold_2 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            --debug(flag2, "  going from cold_1 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            --debug(flag2, "  going to cold_4")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "cold", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            --debug(flag2, "  going from hot_1 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            --debug(flag2, "  going from hot_2 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            --debug(flag2, "  going from hot_3 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            --debug(flag2, "  going from hot_4 to cold_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "freezing"
            player_meta:set_string("thermal_status", "freezing")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    -- activate cold_3 'FRIGID'
    elseif feels_like_temp < 31 then

        -- prior status effect 'cold_3'
        if prior_thermal_status == "frigid" then
            --debug(flag2, "  prior thermal status was already cold_3 'frigid'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

            -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            --debug(flag2, "  going from cold_4 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_3.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            --debug(flag2, "  going from cold_2 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            --debug(flag2, "  going from cold_1 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            --debug(flag2, "  going to cold_3")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "cold", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            --debug(flag2, "  going from hot_1 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            --debug(flag2, "  going from hot_2 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            --debug(flag2, "  going from hot_3 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            --debug(flag2, "  going from hot_4 to cold_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "frigid"
            player_meta:set_string("thermal_status", "frigid")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    -- activate cold_2 'COLD'
    elseif feels_like_temp < 46 then

        -- prior status effect 'cold_2'
        if prior_thermal_status == "cold" then
            --debug(flag2, "  prior thermal status was already cold_2 'cold'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            --debug(flag2, "  going from cold_4 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_2.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            --debug(flag2, "  going from cold_3 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_2.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            --debug(flag2, "  going from cold_1 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            --debug(flag2, "  going to cold_2")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "cold", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            --debug(flag2, "  going from hot_1 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            --debug(flag2, "  going from hot_2 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            --debug(flag2, "  going from hot_3 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            --debug(flag2, "  going from hot_4 to cold_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cold"
            player_meta:set_string("thermal_status", "cold")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    -- activate cold_1 'COOL'
    elseif feels_like_temp < 61 then

        -- prior status effect 'cold_1'
        if prior_thermal_status == "cool" then
            --debug(flag2, "  prior thermal status was already cold_1 'cool'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            --debug(flag2, "  going from cold_4 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_1.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            --debug(flag2, "  going from cold_3 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_1.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            --debug(flag2, "  going from cold_2 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_1.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            --debug(flag2, "  going to cold_1")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "cold", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            --debug(flag2, "  going from hot_1 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            --debug(flag2, "  going from hot_2 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            --debug(flag2, "  going from hot_3 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            --debug(flag2, "  going from hot_4 to cold_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "cold", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "cool"
            player_meta:set_string("thermal_status", "cool")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end

    -- activate 'NICE'
    elseif feels_like_temp < 81 then

        -- no status effect
        if prior_thermal_status == "nice" then
            --debug(flag2, "  prior thermal status was already 'nice'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- new player startup into 'nice'
        elseif prior_thermal_status == "" then
            --debug(flag2, "  new player spawned into world at 'nice' temperature")
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            --debug(flag2, "  going from cold_4 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_0.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            --debug(flag2, "  going from cold_3 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_0.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            --debug(flag2, "  going from cold_2 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_0.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            --debug(flag2, "  going from cold_1 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.cold_0.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            --debug(flag2, "  going from hot_1 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_0.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            --debug(flag2, "  going from hot_2 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_0.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            --debug(flag2, "  going from hot_3 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_0.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            --debug(flag2, "  going from hot_4 to (none)")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_0.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "nice"
            player_meta:set_string("thermal_status", "nice")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end


    -- activate hot_1 'WARM'
    elseif feels_like_temp < 96 then

        -- prior status effect 'hot_1'
        if prior_thermal_status == "warm" then
            --debug(flag2, "  prior thermal status was already hot_1 'warm'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            --debug(flag2, "  going from cold_4 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            --debug(flag2, "  going from cold_3 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            --debug(flag2, "  going from cold_2 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            --debug(flag2, "  going from cold_1 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            --debug(flag2, "  going to hot_1")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "hot", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_1.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            --debug(flag2, "  going from hot_2 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_1.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            --debug(flag2, "  going from hot_3 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_1.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            --debug(flag2, "  going from hot_4 to hot_1")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 1, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_1.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "warm"
            player_meta:set_string("thermal_status", "warm")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end


    -- activate hot_2 'HOT'
    elseif feels_like_temp < 106 then

        -- prior status effect 'hot_2'
        if prior_thermal_status == "hot" then
            --debug(flag2, "  prior thermal status was already hot_2 'hot'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            --debug(flag2, "  going from cold_4 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            --debug(flag2, "  going from cold_3 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            --debug(flag2, "  going from cold_2 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            --debug(flag2, "  going from cold_1 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            --debug(flag2, "  going to hot_2")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "hot", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            --debug(flag2, "  going from hot_1 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_2.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            --debug(flag2, "  going from hot_3 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_2.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            --debug(flag2, "  going from hot_4 to hot_2")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 2, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_2.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "hot"
            player_meta:set_string("thermal_status", "hot")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end


    -- activate hot_3 'SWELTERING'
    elseif feels_like_temp < 121 then

        -- prior status effect 'hot_3'
        if prior_thermal_status == "sweltering" then
            --debug(flag2, "  prior thermal status was already hot_3 'sweltering'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            --debug(flag2, "  going from cold_4 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            --debug(flag2, "  going from cold_3 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            --debug(flag2, "  going from cold_2 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            --debug(flag2, "  going from cold_1 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            --debug(flag2, "  going to hot_3")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "hot", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            --debug(flag2, "  going from hot_1 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            --debug(flag2, "  going from hot_2 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_3.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        -- prior status effect 'hot_4'
        elseif prior_thermal_status == "scorching" then
            --debug(flag2, "  going from hot_4 to hot_3")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 3, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "down", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_3.notify_down, 2, 1.5, 0, 2)
            p_data.thermal_status = "sweltering"
            player_meta:set_string("thermal_status", "sweltering")

        else
            debug(flag2, "  ERROR - Unexpected 'prior_thermal_status' value: " .. prior_thermal_status)
        end


    -- activate hot_4 'SCORCHING'
    else

        -- prior status effect 'hot_4'
        if prior_thermal_status == "scorching" then
            --debug(flag2, "  prior thermal status was already hot_4 'scorching'. no further aciton.")
            --debug(flag2, "monitor_weather() END")
            local job_handle = mt_after(1, monitor_weather, player, p_data, player_meta)
            job_handles[player_name].monitor_weather = job_handle
            return

        -- prior status effect 'cold_4'
        elseif prior_thermal_status == "freezing" then
            --debug(flag2, "  going from cold_4 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_4")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'cold_3'
        elseif prior_thermal_status == "frigid" then
            --debug(flag2, "  going from cold_3 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'cold_2'
        elseif prior_thermal_status == "cold" then
            --debug(flag2, "  going from cold_2 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'cold_1'
        elseif prior_thermal_status == "cool" then
            --debug(flag2, "  going from cold_1 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "cold_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- no status effect
        elseif prior_thermal_status == "nice" or prior_thermal_status == "" then
            --debug(flag2, "  going to hot_4")
            show_stat_effect(player, player:get_meta(), player_name, p_data, "hot", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'hot_1'
        elseif prior_thermal_status == "warm" then
            --debug(flag2, "  going from hot_1 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_1")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'hot_2'
        elseif prior_thermal_status == "hot" then
            --debug(flag2, "  going from hot_2 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_2")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_4.notify_up, 2, 1.5, 0, 2)
            p_data.thermal_status = "scorching"
            player_meta:set_string("thermal_status", "scorching")

        -- prior status effect 'hot_3'
        elseif prior_thermal_status == "sweltering" then
            --debug(flag2, "  going from hot_3 to hot_4")
            hide_stat_effect(player, player_meta, player_name, p_data, p_data.status_effects, "hot_3")
            show_stat_effect(player, player_meta, player_name, p_data, "hot", 4, "weather", 0)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1})
            notify(player, "stat_effect", STATUS_EFFECT_INFO.hot_4.notify_up, 2, 1.5, 0, 2)
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


local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() WEATHER")
    local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local player_status = player_meta:get_int("player_status")
    local p_data = player_data[player_name]

    sound_handles = {}

    -- the player's current feels like temperature conveyed in short text:
    -- nice, cold, freezing, hot, scorching, etc
    p_data.thermal_status = ""

    -- the amount of extra temperature to add (or subtract) due to nearby radiant
    -- sources. currently only campfires exists as sources.
    p_data.thermal_factor_radiant = 0

    p_data.wind_sound_timer = 8
    p_data.wind_sound_gain = 0.05

	if player_status == 0 then
		--debug(flag1, "  new player")

        p_data.thermal_units = 1
        player_meta:set_int("thermal_units", p_data.thermal_units)

            -- use 1.0 second delay to allow world and player to spawn, and for
            -- wind_monitor() to activate before accessing necessary environment data
        if ENABLE_WEATHER_MONITOR then
            local job_handle = mt_after(0, monitor_weather, player, player_data[player_name], player_meta)
            job_handles[player_name].monitor_weather = job_handle
            --debug(flag1, "  started weather monitor")
        end

	elseif player_status == 1 then
		--debug(flag1, "  existing player")

        p_data.thermal_units = player_meta:get_int("thermal_units")

        if ENABLE_WEATHER_MONITOR then
            local job_handle = mt_after(0, monitor_weather, player, player_data[player_name], player_meta)
            job_handles[player_name].monitor_weather = job_handle
            --debug(flag1, "  started weather monitor")
        end

    elseif player_status == 2 then
		--debug(flag1, "  dead player")

	end

	debug(flag1, "\nregister_on_joinplayer() end")
end)




local flag3 = false
core.register_on_dieplayer(function(player)
    debug(flag3, "\nregister_on_dieplayer() WEATHER")
    local player_name = player:get_player_name()

    --debug(flag3, "  cancel monitor_weather() loop..")
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

    --debug(flag4, "  start weather monitor")
    if ENABLE_WEATHER_MONITOR then
        local job_handle = mt_after(0, monitor_weather, player, player_data[player_name], player:get_meta())
        job_handles[player_name].monitor_weather = job_handle
        --debug(flag4, "  enabled weather monitor")
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
        --debug(flag5, "  cancel monitor_weather() loop..")
    end
    debug(flag5, "register_on_leaveplayer() END")
end)


core.register_on_mods_loaded(function()
    -- ensure climate_simulator loop starts after mod load time
    mt_after(0, climate_simulator)
end)