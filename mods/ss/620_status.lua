print("- loading status.lua")

-- cache global functions for faster access
local math_round = math.round

local string_len = string.len
local string_sub = string.sub
local string_upper = string.upper
local string_split = string.split
local table_concat = table.concat
local mt_after = core.after
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local debug = ss.debug
local notify = ss.notify
local round = ss.round
local after_player_check = ss.after_player_check
local play_sound = ss.play_sound
local convert_to_celcius = ss.convert_to_celcius

local SLOT_COLOR_BG = ss.SLOT_COLOR_BG
local SLOT_COLOR_HOVER = ss.SLOT_COLOR_HOVER
local SLOT_COLOR_BORDER = ss.SLOT_COLOR_BORDER
local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local STATUS_EFFECT_INFO = ss.STATUS_EFFECT_INFO
local job_handles = ss.job_handles
local current_climates = ss.current_climates


-- duplicate STATUS_EFFECT_INFO table from player_stats.lua, but swap any instances
-- of white text into red. we won't display white text onto the status effect info
-- area of the Status tab
local SE_HUD_COLOR_TEXT = {}
for effect_name, effect_info in pairs(ss.STATUS_EFFECT_INFO) do
    local text_color = effect_info.text_color
    if text_color then
        text_color = string_sub(text_color, 3)
        if text_color == "FFFFFF" then
            SE_HUD_COLOR_TEXT[effect_name] = "#FF0000"
        else
            SE_HUD_COLOR_TEXT[effect_name] = "#" .. text_color
        end
    end
end
--print("SE_HUD_COLOR_TEXT: " .. dump(SE_HUD_COLOR_TEXT))


local flag4 = false
-- get font color for temperature value based on fahrenheit
local function get_temperature_color(temperature)
    debug(flag4, "    get_temperature_color()")
    --debug(flag4, "      temperature: " .. temperature)
    local color
    if temperature < 32 then
        color = "#c0ffff"  -- bluish white
    elseif temperature < 51 then
        color = "#00ffff"  -- light blue
    elseif temperature < 66 then
        color = "#00ffc0"  -- bluish green
    elseif temperature < 81 then
        color = "#00e000"  -- green
    elseif temperature < 96 then
        color = "#ffff00"  -- yellow
    elseif temperature < 106 then
        color = "#ffc000"  -- light orange
    elseif temperature < 121 then
        color = "#ff8000"  -- orange
    else
        color = "#ff0000"  -- red
    end

    debug(flag4, "    get_temperature_color() END")
    return color
end


local flag5 = false
local function get_stat_value_color(p_data, stat)
    debug(flag5, "    get_stat_value_color()")

    local color
    if stat == "health" then
        if p_data.health_ratio > 0.30 then
            color = "#FFFFFF" -- normal range
        elseif p_data.health_ratio > 0.10 then
            color = "#FFA800" -- health_1
        elseif p_data.health_ratio > 0 then
            color = "#FF0000" -- health_2
        else
            color = "#AAAAAA" -- full health
        end

    elseif stat == "weight" then
        if p_data.weight_ratio == 0 then
            color = "#AAAAAA" -- zero weight
        elseif p_data.weight_ratio < 0.30 then
            color = "#FFFFFF" -- normal range
        elseif p_data.weight_ratio < 0.45 then
            color = "#FFA800" -- weight_1
        elseif p_data.weight_ratio < 0.60 then
            color = "#FFA800" -- weight_2
        elseif p_data.weight_ratio < 0.75 then
            color = "#FFA800" -- weight_3
        else
            color = "#FF0000" -- weight_4 or weight_5
        end

    -- all other stats like thirst, hunger, alertness, stamina, etc
    else
        local stat_ratio = p_data[stat .. "_ratio"]
        if stat_ratio == 1 then
            color = "#AAAAAA" -- full stat
        elseif stat_ratio > 0.50 then
            color = "#FFFFFF" -- normal range
        elseif stat_ratio > 0.30 then
            color = "#FFA800" -- severity 1
        elseif stat_ratio > 0.10 then
            color = "#FFA800" -- severity 2
        else
            color = "#FF0000" -- severity 3
        end
    end

    debug(flag5, "    get_stat_value_color() END")
    return color
end


local STAT_NAMES = {"health", "thirst", "hunger", "alertness", "hygiene", "comfort",
    "immunity", "sanity", "happiness", "legs", "hands", "breath", "stamina", "weight"}

local flag2 = false
local function get_fs_tab_status(player, player_name, player_meta, p_data)
    debug(flag2, "\n  get_fs_tab_status()")
    after_player_check(player)

    local formspec

    local x_pos = 0.4
    local y_pos = 0.2
    local fs_part1 = table_concat({
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.4]",
        "listcolors[",
			SLOT_COLOR_BG, ";",
			SLOT_COLOR_HOVER, ";",
			SLOT_COLOR_BORDER, ";",
			TOOLTIP_COLOR_BG, ";",
			TOOLTIP_COLOR_TEXT,
		"]",
        "tabheader[0,0;inv_tabs;Main,Equipment,Status,Skills,Bundle,Settings,?,*;3;true;true]",
        "hypertext[0.2,0.2;4,1.5;status_title;",
        "<style color=#AAAAAA size=16><b>PLAYER STATUS</b></style>]",

        -- black background box for main player stats
        "box[0.2,1.0;5.5,8.0;#111111]",
        "hypertext[0.3,1.2;4,1.5;label_stats;",
        "<style color=#AAAAAA size=14><b>Stat Values:</b></style>]",

        -- black background box for status effects
        "box[6.0,1.0;7.5,9.0;#111111]",
        "hypertext[6.2,1.2;4,1.5;label_condition;",
        "<style color=#AAAAAA size=14><b>Status Effects:</b></style>]",
    })

    -----------------------
    -- SHOW STATS VALUES --
    -----------------------

    local fs_part2 = ""
    local status_effects = p_data.status_effects
    local stat_current, stat_max, stat_current_color, stat_max_color
    for i, stat in ipairs(STAT_NAMES) do
        stat_current = round(player_meta:get_float(stat .. "_current"), 1)
        stat_max = round(player_meta:get_float(stat .. "_max"), 1)
        stat_current_color = get_stat_value_color(p_data, stat)
        local y_offset = y_pos + 1.1 + (i/2)
        fs_part2 = fs_part2 .. table_concat({
            "image[" , x_pos, ",", y_offset - 0.1, ";0.5,0.5;ss_statbar_icon_", stat, ".png;]",
            "hypertext[", x_pos + 0.6, ",", y_offset, ";6,1;stat_label;",
            "<style color=#CCCCCC size=15><b>", stat, "  </b></style>]",
            "hypertext[", x_pos + 2.5, ",", y_offset, ";6,1;", stat, "_current;",
            "<style color=", stat_current_color, " size=15><b>", stat_current, "</b></style>]",
            "hypertext[", x_pos + 3.6, ",", y_offset, ";1,1;stat_value_divider;",
            "<style color=#999999 size=15><b> / </b></style>]",
            "hypertext[", x_pos + 4.0, ",", y_offset, ";6,1;", stat, "_max;",
            "<style color=#AAAAAA size=15><b>", stat_max, "</b></style>]"
        })
    end

    ----------------------------
    -- SHOW THERMAL CONDITION --
    ----------------------------

    local thermal_status = p_data.thermal_status
    local thermal_feels_like = p_data.thermal_feels_like
    local thermal_air_temp = p_data.thermal_air_temp
    local thermal_humidity = p_data.thermal_humidity
    local thermal_water_temp = p_data.thermal_water_temp

    local thermal_radiant_factor = p_data.thermal_factor_radiant
    local thermal_sun_factor = p_data.thermal_factor_sun
    local thermal_elevation_factor = p_data.thermal_factor_elevation
    local thermal_humidity_factor = p_data.thermal_factor_humidity
    local thermal_wind_factor = p_data.thermal_factor_wind
    local thermal_wetness_factor = p_data.thermal_factor_wetness
    local thermal_equipment_factor = p_data.thermal_factor_equipment
    local thermal_skill_factor = p_data.thermal_factor_skill


    local thermal_wind
    if current_climates == nil then
        thermal_wind = 0
        print("### current_climates table was NIL ### get_fs_tab_status()")
        notify(player, "error", "current_climates table is NIL", 5, 0, 0, 2)
    elseif current_climates[p_data.biome_name] == nil then
        thermal_wind = 0
        notify(player, "error", p_data.biome_name .. " missing from current_climates table", 5, 0, 0, 2)
        print("### current_climates table did not contain " .. p_data.biome_name .. " ### get_fs_tab_status()")
    else
        thermal_wind = current_climates[p_data.biome_name].wind_speed
    end

    local thermal_units = p_data.thermal_units

    local status_elements
    status_elements = table_concat({
    "<style color=", get_temperature_color(thermal_feels_like), " size=14><b> ",
        string_upper(thermal_status), "</b></style>]"})

    local feels_like_elements
    if thermal_units == 1 then
        feels_like_elements = table_concat({
            "<style color=", get_temperature_color(thermal_feels_like), " size=14><b>",
                round(thermal_feels_like, 1), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        feels_like_elements = table_concat({
            "<style color=", get_temperature_color(thermal_feels_like), " size=14><b>",
                convert_to_celcius(thermal_feels_like, 1), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end

    local air_temp_elements
    if p_data.water_level < 100 then
        if thermal_units == 1 then
            air_temp_elements = table_concat({
                "<style color=", get_temperature_color(thermal_air_temp), " size=14><b>",
                    round(thermal_air_temp, 1), "</b></style>",
                "<style color=#EEEEEE size=14> °F</style>]"
            })
        else
            air_temp_elements = table_concat({
                "<style color=", get_temperature_color(thermal_air_temp), " size=14><b>",
                    convert_to_celcius(thermal_air_temp, 1), "</b></style>",
                "<style color=#EEEEEE size=14> °C</style>]"
            })
        end
    else
        air_temp_elements = table_concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    end

    local water_element_color = "#CCCCCC"
    local water_temp_elements
    if p_data.water_level > 0 then
        water_element_color = "#66ccff"
        if thermal_units == 1 then
            water_temp_elements = table_concat({
                "<style color=", get_temperature_color(thermal_water_temp), " size=14><b>",
                    round(thermal_water_temp, 1), "</b></style>",
                "<style color=#EEEEEE size=14> °F</style>]"
            })
        else
            water_temp_elements = table_concat({
                "<style color=", get_temperature_color(thermal_water_temp), " size=14><b>",
                    convert_to_celcius(thermal_water_temp, 1), "</b></style>",
                "<style color=#EEEEEE size=14> °C</style>]"
            })
        end
    else
        water_temp_elements = table_concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    end

    local text_color, number_sign

    local radiant_factor_elements
    if thermal_radiant_factor == 0 then
        radiant_factor_elements = ""
    else
        if thermal_radiant_factor > 0 then
            text_color = "#ffc000"
            number_sign = "+"
        else
            text_color = "#00ffff"
            number_sign = "-"
        end
        local elements
        if thermal_units == 1 then
            elements = table_concat({
                "<style color=", text_color, " size=14><b>",
                    number_sign, round(thermal_radiant_factor, 1), "</b></style>",
                "<style color=#EEEEEE size=14> °F</style>]"
            })
        else
            elements = table_concat({
                "<style color=", text_color, " size=14><b>",
                    number_sign, convert_to_celcius(thermal_radiant_factor, 1, true), "</b></style>",
                "<style color=#EEEEEE size=14> °C</style>]"
            })
        end
        radiant_factor_elements = table_concat({
            "hypertext[18.8,1.3;5.5,1.0;label_radiant_factor;<style color=#CCCCCC size=14>Radiant</style>]",
            "hypertext[20.5,1.3;5.5,1.0;label_radiant_factor_value;", elements
        })
    end


    local sun_factor_elements
    if thermal_sun_factor > 0 then
        text_color = "#ffc000"
        number_sign = "+"
    else
        text_color = "#AAAAAA"
        number_sign = ""
    end
    if thermal_units == 1 then
        sun_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, round(thermal_sun_factor, 1), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        sun_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, convert_to_celcius(thermal_sun_factor, 1, true), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end

    local elevation_factor_elements
    if thermal_elevation_factor > 0 then
        text_color = "#ffc000"
        number_sign = "+"
    elseif thermal_elevation_factor < 0 then
        text_color = "#00ffff"
        number_sign = ""
    else
        text_color = "#AAAAAA"
        number_sign = ""
    end
    if thermal_units == 1 then
        elevation_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, round(thermal_elevation_factor, 1), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        elevation_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, convert_to_celcius(thermal_elevation_factor, 1, true), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end

    local humidity_factor_elements
    if thermal_humidity_factor > 0 then
        text_color = "#ffc000"
        number_sign = "+"
    elseif thermal_humidity_factor < 0 then
        text_color = "#00ffff"
        number_sign = ""
    else
        text_color = "#AAAAAA"
        number_sign = ""
    end
    if thermal_units == 1 then
        humidity_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, round(thermal_humidity_factor, 1), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        humidity_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, convert_to_celcius(thermal_humidity_factor, 1, true), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end

    local wind_factor_elements
    if thermal_wind_factor < 0 then
        text_color = "#00ffff"
    else
        text_color = "#AAAAAA"
    end
    if thermal_units == 1 then
        wind_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                round(thermal_wind_factor, 1), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        wind_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                convert_to_celcius(thermal_wind_factor, 1, true), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end

    local wetness_factor_elements
    if p_data.water_level < 100 then
        if thermal_wetness_factor < 0 then
            text_color = "#00ffff"
        else
            text_color = "#AAAAAA"
        end
        if thermal_units == 1 then
            wetness_factor_elements = table_concat({
                "<style color=", text_color, " size=14><b>",
                    round(thermal_wetness_factor, 1), "</b></style>",
                "<style color=#EEEEEE size=14> °F</style>]"
            })
        else
            wetness_factor_elements = table_concat({
                "<style color=", text_color, " size=14><b>",
                    convert_to_celcius(thermal_wetness_factor, 1, true), "</b></style>",
                "<style color=#EEEEEE size=14> °C</style>]"
            })
        end
    else
        wetness_factor_elements = table_concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    end


    local equipmnet_factor_elements
    if thermal_equipment_factor > 0 then
        text_color = "#ffc000"
        number_sign = "+"
    elseif thermal_equipment_factor < 0 then
        text_color = "#00ffff"
        number_sign = ""
    else
        text_color = "#AAAAAA"
        number_sign = ""
    end
    if thermal_units == 1 then
        equipmnet_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, round(thermal_equipment_factor, 1), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        equipmnet_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, convert_to_celcius(thermal_equipment_factor, 1, true), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end

    local skill_factor_elements
    if thermal_skill_factor > 0 then
        text_color = "#ffc000"
        number_sign = "+"
    elseif thermal_skill_factor < 0 then
        text_color = "#00ffff"
        number_sign = ""
    else
        text_color = "#AAAAAA"
        number_sign = ""
    end
    if thermal_units == 1 then
        skill_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, round(thermal_skill_factor, 1), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        skill_factor_elements = table_concat({
            "<style color=", text_color, " size=14><b>",
                number_sign, convert_to_celcius(thermal_skill_factor, 1, true), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end

    local humidity_elements
    if p_data.water_level > 0 then
        humidity_elements = table_concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    else
        local humidity_color
        if thermal_humidity < 10 then
            humidity_color = "#ff0000"
        elseif thermal_humidity < 30 then
            humidity_color = "#ffc000"
        elseif thermal_humidity < 60 then
            humidity_color = "#eeeeee"
        elseif thermal_humidity < 80 then
            humidity_color = "#ffc000"
        else
            humidity_color = "#ff0000"
        end
        humidity_elements = table_concat({
        "<style color=", humidity_color, " size=14><b>", math_round(thermal_humidity), "</b></style>",
        "<style color=#EEEEEE size=14> %</style>]"})
    end

    local wind_elements, wind_text_color
    if thermal_wind > 17 then -- near storm
        wind_text_color = "#c00000"

    elseif thermal_wind > 14 then -- gale force
        wind_text_color = "#ff8000"

    elseif thermal_wind > 11 then -- near gale
        wind_text_color = "#ffc000"

    elseif thermal_wind > 8 then -- strong breeze
        wind_text_color = "#e6e600"

    elseif thermal_wind > 5 then -- fresh breeze
        wind_text_color = "#ffff77"

    elseif thermal_wind > 2 then -- moderate breeze
        wind_text_color = "#ffffba"

    else -- light breeze
        wind_text_color = "#eeeeee"
    end
    if thermal_wind and p_data.water_level == 0 then
        wind_elements = table_concat({
        "<style color=", wind_text_color, " size=14><b>", thermal_wind, "</b></style><style color=#EEEEEE size=14> m/s</style>]"})
    else
        wind_elements = table_concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    end


    local fs_part3 = table_concat({

        -- black background box for player thermals and biome climate
        "box[13.8,1.0;8.1,3.3;#111111]",
        "hypertext[13.9,1.2;6,1.5;label_thermal;",
        "<style color=#FFFFFF size=14><b>Thermal Status: ", status_elements, "</b></style>]",

        "image[14.2,1.55;1.3,1.3;ss_thermal_status_", thermal_status, ".png;]",

        "hypertext[15.8,1.7;5.5,1.0;label_feels_like;",
        "<style color=#FFFFFF size=14>Feels like</style>]",
        "hypertext[17.5,1.7;5.5,1.0;label_feels_like_value;",
        feels_like_elements,

        "hypertext[15.8,2.1;5.5,1.0;label_air_temp_value;",
        "<style color=#CCCCCC size=14>Air Temp</style>]",
        "hypertext[17.5,2.1;5.5,1.0;label_air_temp_value;",
        air_temp_elements,

        "hypertext[15.8,2.5;5.5,1.0;label_humidity_value;",
        "<style color=#CCCCCC size=14>Humidity</style>]",
        "hypertext[17.5,2.5;5.5,1.0;label_humidity_value;",
        humidity_elements,

        "hypertext[15.8,2.9;5.5,1.0;label_wind_value;",
        "<style color=#CCCCCC size=14>Wind</style>]",
        "hypertext[17.5,2.9;5.5,1.0;label_wind_value;",
        wind_elements,

        "hypertext[15.8,3.3;6.3,1.0;label_equipment_factor;",
        "<style color=#CCCCCC size=14>Equipment</style>]",
        "hypertext[17.5,3.3;6.3,1.0;label_equipment_factor_value;",
        equipmnet_factor_elements,

        "hypertext[15.8,3.7;6.3,1.0;label_skill_factor;",
        "<style color=#CCCCCC size=14>Survival Skill</style>]",
        "hypertext[17.5,3.7;6.3,1.0;label_skill_factor_value;",
        skill_factor_elements,

        ----- next column -----

        radiant_factor_elements,

        "hypertext[18.8,1.7;5.5,1.0;label_water_temp_value;",
        "<style color=", water_element_color, " size=14>Water Temp</style>]",
        "hypertext[20.5,1.7;5.5,1.0;label_water_temp_value;",
        water_temp_elements,

        "hypertext[18.8,2.1;5.5,1.0;label_sun_factor;",
        "<style color=", water_element_color, " size=14>Sun Light</style>]",
        "hypertext[20.5,2.1;5.5,1.0;label_sun_factor_value;",
        sun_factor_elements,

        "hypertext[18.8,2.5;5.5,1.0;label_elevation_factor;",
        "<style color=", water_element_color, " size=14>Elevation</style>]",
        "hypertext[20.5,2.5;5.5,1.0;label_elevation_factor_value;",
        elevation_factor_elements,

        "hypertext[18.8,2.9;5.9,1.0;label_humidity_factor;",
        "<style color=", water_element_color, " size=14>Humidity</style>]",
        "hypertext[20.5,2.9;5.9,1.0;label_humidity_factor_value;",
        humidity_factor_elements,

        "hypertext[18.8,3.3;6.3,1.0;label_wind_factor;",
        "<style color=", water_element_color, " size=14>Wind</style>]",
        "hypertext[20.5,3.3;6.3,1.0;label_wind_factor_value;",
        wind_factor_elements,

        "hypertext[18.8,3.7;6.3,1.0;label_wetness_factor;",
        "<style color=", water_element_color, " size=14>Wetness</style>]",
        "hypertext[20.5,3.7;6.3,1.0;label_wetness_factor_value;",
        wetness_factor_elements,

        

    })


    -------------------------
    -- SHOW STATUS EFFECTS --
    -------------------------

    if p_data.status_effect_count > 0 then
        --debug(flag2, "    status effects exists")
        local stat_effects_counter = 0
        local y_offset = 1.7
        local fs_part5 = table_concat({
            "scroll_container[6.3,", y_offset, ";7,8;scrollbar_stat_effects;vertical;0.05;]"
        })

        local fs_part6 = ""
        for effect_name, effect_data in pairs(status_effects) do
            local type = effect_data[1]
            --debug(flag2, "    effect_name: " .. effect_name .. " (" .. type .. ")")
            local tokens = string_split(effect_name, "_")
            local stat = tokens[1]

            local stat_effect_color = "#FFA800" -- orange
            local stat_effect_icon

            if type == "percentage" or type == "basic_3" then
                stat_effect_icon = "ss_statbar_icon_" .. stat .. ".png"
                stat_effect_color = SE_HUD_COLOR_TEXT[effect_name]

            elseif type == "weather" or type == "basic"
                or type == "wetness" or type == "timed" then
                --debug(flag2, "    'weather' stat effect")
                stat_effect_icon = "ss_stat_effect_" .. effect_name .. ".png"
                stat_effect_color = SE_HUD_COLOR_TEXT[effect_name]

            else
                --debug(flag2, "    ERROR - Unexpected 'stat' value: " .. stat)
            end

            --debug(flag2, "    stat_effect_color: " .. stat_effect_color)
            local effect_info = STATUS_EFFECT_INFO[effect_name]
            local effect_description = effect_info.desc
            --debug(flag2, "    effect_description: " .. effect_description)
            local effect_fix_text = effect_info.fix
            local description_offset = 0
            if string_len(effect_fix_text) > 50 then
                description_offset = 0.40
            end
            --debug(flag2, "    effect_fix_text: " .. effect_fix_text)

            local effect_impact = core.wrap_text(effect_info.tooltip, 60)
            local tooltip_width = string.len(effect_description) / 5

            y_offset = 0 + (stat_effects_counter * 0.9)
            fs_part6 = fs_part6 .. table_concat({
            "tooltip[0,", y_offset - 0.3, ";", tooltip_width, ",0.6;" , effect_impact, "]",
            "image[0,", y_offset - 0.1, ";0.5,0.5;" .. stat_effect_icon .. ";]",
            "hypertext[0.6,", y_offset, ";6,1;stat_effect_desc_label;",
                "<style color=", stat_effect_color, " size=15><b>", effect_description, "</b></style>]",
            "hypertext[0.8,", y_offset + 0.4, ";5.8,2;stat_effect_info_label;",
                "<style color=#BBBBBB size=14>", effect_fix_text, "</style>]"
            })
            stat_effects_counter = stat_effects_counter + 1 + description_offset
        end
        local fs_part7 = "scroll_container_end[]"

        local fs_part4 = ""
        local scroll_pos = p_data.stat_effects_scroll_pos or 0
        if stat_effects_counter > 9 then
            --debug(flag2, "    more than 9 status effects active. added scrollbar..")
            local total_scroll_distance = (stat_effects_counter - 9) * 20
            fs_part4 = table_concat({
                "scrollbaroptions[min=0;max=", total_scroll_distance, ";smallstep=20;largestep=100;thumbsize=20;arrows=hide]",
                "scrollbar[13.1,1.75;0.3,8;vertical;scrollbar_stat_effects;", scroll_pos, "]"
            })
        end
        formspec = table_concat({fs_part1, fs_part2, fs_part3, fs_part4, fs_part5, fs_part6, fs_part7})

    else
        --debug(flag2, "    no active status effects")
        local fs_part4 = table_concat({
            "hypertext[7.8,4.0;6,1;stat_effect_desc_label;",
                "<style color=#666666 size=18><b>(no health conditions)</b></style>]"
            })

        formspec = table_concat({fs_part1, fs_part2, fs_part3, fs_part4})
    end

    mt_show_formspec(player_name, "ss:ui_status", formspec)

    debug(flag2, "  get_fs_tab_status() END *** " .. mt_get_gametime())
    local job_handle = mt_after(1, get_fs_tab_status, player, player_name, player_meta, p_data)
    job_handles[player_name].refresh_status_tab = job_handle
end



local flag1 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() STATUS")
	--debug(flag1, "  fields: " .. dump(fields))
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local p_data = ss.player_data[player_name]
    --debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    --debug(flag1, "  active_tab: " .. p_data.active_tab)


    if fields.inv_tabs == "3" then
        --debug(flag1, "  clicked on 'STATUS' tab!")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "status"
        get_fs_tab_status(player, player_name, player_meta, p_data)

    else
        --debug(flag1, "  did not click on STATUS tab")
        if p_data.formspec_mode ~= "main_formspec" then
            --debug(flag1, "  interaction not from main formspec. NO FURTHER ACTION.")
            --debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif p_data.active_tab ~= "status" then
            --debug(flag1, "  interaction from main formspec, but not STATUS tab. NO FURTHER ACTION.")
            p_data.stat_effects_scroll_pos = 0
            local job_handle = job_handles[player_name].refresh_status_tab
            if job_handle then
                --debug(flag1, "  refresh loop still running. stopping now..")
                job_handle:cancel()
                job_handles[player_name].refresh_status_tab = nil
            end
            --debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "2"
            or fields.inv_tabs == "4"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6"
            or fields.inv_tabs == "7"
            or fields.inv_tabs == "8" then
            --debug(flag1, "  clicked on a tab that was not STATUS")
            p_data.stat_effects_scroll_pos = 0
            local job_handle = job_handles[player_name].refresh_status_tab
            if job_handle then
                --debug(flag1, "  refresh loop still running. stopping now..")
                job_handle:cancel()
                job_handles[player_name].refresh_status_tab = nil
            end
            --debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.quit then
            --debug(flag1, "  exited formspec. NO FURTHER ACTION.")
            p_data.active_tab = "main"
            p_data.stat_effects_scroll_pos = 0
            --debug(flag1, "  cancel Status tab refresh loop")
            local job_handle = job_handles[player_name].refresh_status_tab
            if job_handle then
                --debug(flag1, "  refresh loop still running. stopping now..")
                job_handle:cancel()
                job_handles[player_name].refresh_status_tab = nil
            end
            --debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.scrollbar_stat_effects then
            --debug(flag1, "  ** ACTIVATED SCROLLBAR ** ")
            --debug(flag1, "  fields.scrollbar_stat_effects: " .. dump(fields.scrollbar_stat_effects))
            p_data.stat_effects_scroll_pos = string_sub(fields.scrollbar_stat_effects, 5)

        else
            --debug(flag1, "  clicked on a STATUS formspec element")
        end
    end

    --debug(flag1, "  clicked on a status setting element. checking additional fields..")

    -- check for further status related form interaction here

    debug(flag1, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)


local flag3 = false
core.register_on_dieplayer(function(player)
    debug(flag3, "\nregister_on_dieplayer() STATUS TAB")
    local player_name = player:get_player_name()

    if job_handles[player_name].refresh_status_tab then
        --debug(flag1, "  refresh status tab loop was running")
        --debug(flag1, "  cancel get_fs_tab_status() loop..")
        local job_handle = job_handles[player_name].refresh_status_tab
        job_handle:cancel()
        job_handles[player_name].refresh_status_tab = nil
    else
        --debug(flag3, "  refresh status tab loop was not running")
    end

    debug(flag3, "register_on_dieplayer() end")
end)