print("- loading status.lua")

-- cache global functions for faster access
local math_round = math.round
local table_concat = table.concat
local mt_after = core.after
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local debug = ss.debug
local round = ss.round
local play_sound = ss.play_sound
local convert_to_celcius = ss.convert_to_celcius

local INTERNAL_STAT_EFFECTS = ss.INTERNAL_STAT_EFFECTS
local job_handles = ss.job_handles

local wind_conditions = ss.wind_conditions
if wind_conditions == nil then
    print("### ERROR - ss.wind_conditions is NIL")
end

local STAT_NAMES = {"health", "thirst", "hunger", "alertness", "hygiene", "comfort",
    "immunity", "sanity", "happiness", "breath", "stamina", "weight"}

local STAT_EFFECT_INFO = {
    -- 'internal' stat effects
    health_1 = "health is low",
    health_2 = "health is critical",
    thirst_1 = "feeling a bit thirsty",
    thirst_2 = "feeling very thirsty",
    thirst_3 = "completely dehydrated",
    hunger_1 = "feeling a bit hungry",
    hunger_2 = "feeling very hungry",
    hunger_3 = "completely starving",
    alertness_1 = "getting a bit sleepy",
    alertness_2 = "getting very sleepy",
    alertness_3 = "fighting to stay awake",
    hygiene_1 = "getting a bit dirty",
    hygiene_2 = "getting a bit smelly too",
    hygiene_3 = "completely dirty and stinky",
    comfort_1 = "feeling a bit tense",
    comfort_2 = "feeling restless",
    comfort_3 = "completely uncomfortable",
    immunity_1 = "feeling a bit week",
    immunity_2 = "feeling very weak",
    immunity_3 = "severely weak and sickly",
    sanity_1 = "feeling a bit unsettled",
    sanity_2 = "feeling more crazy",
    sanity_3 = "completely psychotic",
    happiness_1 = "feeling a bit down",
    happiness_2 = "feeling sad",
    happiness_3 = "completely depressed",
    breath_1 = "need a breath",
    breath_2 = "need a breath soon",
    breath_3 = "completely suffocating",
    stamina_1 = "getting a bit tired",
    stamina_2 = "getting exhausted",
    stamina_3 = "completely exhausted",
    weight_1 = "weight is getting heavy",
    weight_2 = "weight is very heavy",
    weight_3 = "weight is too much",

    -- 'external' stat effects
    hot_1 = "feeling a bit warm",
    hot_2 = "feeling hot",
    hot_3 = "completely sweltering",
    hot_4 = "completely scorching",
    cold_1 = "feeling a bit chilly",
    cold_2 = "feeling cold",
    cold_3 = "it's frigid",
    cold_4 = "completely freezing",
}



local STAT_EFFECT_FIX = {
    health = "Take care of your injuries.",
    thirst = "Drink water or eat food with liquid content.",
    hunger = "Eat food.",
    alertness = "Get some sleep.",
    hygiene = "Take a shower or a bath, or brush your teeth.",
    comfort = "Avoid extreme temperatures, carrying too much weight, or neglecting your well-being.",
    immunity = "Get some sleep, consume healthy foods, and maintain your well-being.",
    sanity = "Avoid disturbing or stressful situations, or get some sleep.",
    happiness = "Maintain your well-being.",
    breath = "Take a breath or find cleaner air to breath.",
    stamina = "Take a break from any physical activity.",
    weight = "Drop heavy items you are carrying.",

    hot = "Shelter from the heat, wear lighter clothing, or jump in some water.",
    cold = "Shelter from the cold, wear thicker clothing, or find a heat source."
}


local flag4 = false
-- get font color for temperature value based on fahrenheit
local function get_temperature_color(temperature)
    debug(flag4, "    get_temperature_color()")
    debug(flag4, "      temperature: " .. temperature)
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



local flag2 = false
local function get_fs_tab_status(player, player_name, player_meta, p_data)
    debug(flag2, "\n  get_fs_tab_status()")
    if not player:is_player() then
        debug(flag2, "    player no longer exists. function skipped.")
        return
    end

    local formspec

    local x_pos = 0.4
    local y_pos = 0.2
    local fs_part1 = table_concat({
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.4]",
        "tabheader[0,0;inv_tabs;Main,Status,Skills,Bundle,Settings,?,*;2;true;true]",
        "hypertext[0.2,0.2;4,1.5;status_title;",
        "<style color=#AAAAAA size=16><b>PLAYER STATUS</b></style>]",

        -- black background box for physical stats
        "box[0.2,1.0;5.5,7.0;#111111]",
        "hypertext[0.3,1.2;4,1.5;label_stats;",
        "<style color=#AAAAAA size=14><b>Stat Values:</b></style>]",

        -- black background box for current conditions (status effects)
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

        if status_effects[stat .. "_1"] then
            stat_current_color = "#FFA800"
            stat_max_color = "#AAAAAA"

        elseif status_effects[stat .. "_2"] then
            stat_current_color = "#FF0000"
            stat_max_color = "#AAAAAA"

        elseif status_effects[stat .. "_3"] then
            stat_current_color = "#FF0000"
            stat_max_color = "#AAAAAA"

        elseif stat_current == stat_max then
            stat_current_color = "#AAAAAA"
            stat_max_color = "#AAAAAA"

        else
            stat_current_color = "#FFFFFF"
            stat_max_color = "#AAAAAA"
        end

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
            "<style color=", stat_max_color, " size=15><b>", stat_max, "</b></style>]"
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
    local thermal_radiant = p_data.thermal_radiant_temp

    -- for testing purposes
    if wind_conditions == nil then
        print("### wind_conditions was nil. checking ss.wind_conditions: " .. dump(ss.wind_conditions))
    end

    local thermal_wind = wind_conditions[p_data.biome_name].wind_speed
    local thermal_units = p_data.thermal_units
    local is_underwater = p_data.underwater

    local status_elements
    status_elements = table.concat({
    "<style color=", get_temperature_color(thermal_feels_like), " size=14><b> ",
        string.upper(thermal_status), "</b></style>]"})

    local feels_like_elements
    if thermal_units == 1 then
        feels_like_elements = table.concat({
            "<style color=", get_temperature_color(thermal_feels_like), " size=14><b>",
                math_round(thermal_feels_like), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        feels_like_elements = table.concat({
            "<style color=", get_temperature_color(thermal_feels_like), " size=14><b>",
                convert_to_celcius(thermal_feels_like), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end

    local air_temp_elements
    if not is_underwater then
        if thermal_units == 1 then
            air_temp_elements = table.concat({
                "<style color=", get_temperature_color(thermal_air_temp), " size=14><b>",
                    math_round(thermal_air_temp), "</b></style>",
                "<style color=#EEEEEE size=14> °F</style>]"
            })
        else
            air_temp_elements = table.concat({
                "<style color=", get_temperature_color(thermal_air_temp), " size=14><b>",
                    convert_to_celcius(thermal_air_temp), "</b></style>",
                "<style color=#EEEEEE size=14> °C</style>]"
            })
        end
    else
        air_temp_elements = table.concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    end

    local water_temp_elements
    if is_underwater and thermal_water_temp then
        if thermal_units == 1 then
            water_temp_elements = table.concat({
                "<style color=", get_temperature_color(thermal_water_temp), " size=14><b>",
                    math_round(thermal_water_temp), "</b></style>",
                "<style color=#EEEEEE size=14> °F</style>]"
            })
        else
            water_temp_elements = table.concat({
                "<style color=", get_temperature_color(thermal_water_temp), " size=14><b>",
                    convert_to_celcius(thermal_water_temp), "</b></style>",
                "<style color=#EEEEEE size=14> °C</style>]"
            })
        end
    else
        water_temp_elements = table.concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    end

    local radiant_elements, radiant_color, sign
    if thermal_radiant > 0 then
        radiant_color = "#ffc000"
        sign = "+"
    elseif thermal_radiant < 0 then
        radiant_color = "#00ffff"
        sign = "-"
    end
    if thermal_radiant == 0 then
        radiant_elements = table.concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    elseif thermal_units == 1 then
        radiant_elements = table.concat({
            "<style color=", radiant_color, " size=14><b>",
                sign, math_round(thermal_radiant), "</b></style>",
            "<style color=#EEEEEE size=14> °F</style>]"
        })
    else
        radiant_elements = table.concat({
            "<style color=", radiant_color, " size=14><b>",
                sign, convert_to_celcius(thermal_radiant), "</b></style>",
            "<style color=#EEEEEE size=14> °C</style>]"
        })
    end


    local humidity_elements
    if not is_underwater then
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
        humidity_elements = table.concat({
        "<style color=", humidity_color, " size=14><b>", math_round(thermal_humidity), "</b></style>",
        "<style color=#EEEEEE size=14> %</style>]"})
    else
        humidity_elements = table.concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
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
    if thermal_wind and not is_underwater then
        wind_elements = table.concat({
        "<style color=", wind_text_color, " size=14><b>", thermal_wind, "</b></style><style color=#EEEEEE size=14> m/s</style>]"})
    else
        wind_elements = table.concat({"<style color=#AAAAAA size=14><b>--</b></style>]"})
    end


    local fs_part3 = table_concat({

        -- black background box for temperature / weather conditions
        "box[13.8,1.0;8.0,2.1;#111111]",
        "hypertext[13.9,1.2;6,1.5;label_thermal;",
        "<style color=#AAAAAA size=14><b>Thermal Status: ", status_elements, "</b></style>]",

        "image[14.2,1.55;1.3,1.3;ss_thermal_status_", thermal_status, ".png;]",

        "hypertext[15.8,1.7;5.5,1.0;label_feels_like;",
        "<style color=#CCCCCC size=14>Feels like</style>]",
        "hypertext[17.7,1.7;5.5,1.0;label_feels_like_value;",
        feels_like_elements,

        "hypertext[15.8,2.1;5.5,1.0;label_air_temp;",
        "<style color=#CCCCCC size=14>Air Temp</style>]",
        "hypertext[17.7,2.1;5.5,1.0;label_air_temp_value;",
        air_temp_elements,

        "hypertext[15.8,2.5;5.5,1.0;label_water_temp;",
        "<style color=#CCCCCC size=14>Water Temp</style>]",
        "hypertext[17.7,2.5;5.5,1.0;label_water_temp_value;",
        water_temp_elements,

        "hypertext[19.0,1.7;5.5,1.0;label_radiant;",
        "<style color=#CCCCCC size=14>Radiant</style>]",
        "hypertext[20.4,1.7;5.5,1.0;label_radiant_value;",
        radiant_elements,

        "hypertext[19.0,2.1;5.5,1.0;label_humidity;",
        "<style color=#CCCCCC size=14>Humidity</style>]",
        "hypertext[20.4,2.1;5.5,1.0;label_humidity_value;",
        humidity_elements,

        "hypertext[19.0,2.5;5.5,1.0;label_wind;",
        "<style color=#CCCCCC size=14>Wind</style>]",
        "hypertext[20.4,2.5;5.5,1.0;label_wind_value;",
        wind_elements
    })


    ----------------------------------------------
    -- SHOW STATUS EFFECTS (current conditions) --
    ----------------------------------------------

    if p_data.status_effect_count > 0 then
        debug(flag2, "    status effects exists")
        local stat_effects_counter = 0
        local y_offset = 1.7
        local fs_part5 = table.concat({
            "scroll_container[6.3,", y_offset, ";7,8;scrollbar_stat_effects;vertical;0.05;]"
        })

        local fs_part6 = ""
        for effect_name in pairs(status_effects) do
            y_offset = 0 + (stat_effects_counter * 0.9)
            debug(flag2, "    effect_name: " .. effect_name)
            local stat = string.sub(effect_name, 1, -3)
            debug(flag2, "    stat: " .. stat)


            local stat_effect_color, stat_effect_icon
            if INTERNAL_STAT_EFFECTS[effect_name] then
                debug(flag2, "    internal stat effect")
                stat_effect_icon = "ss_statbar_icon_" .. stat .. ".png"
                if status_effects[stat .. "_1"] then
                    stat_effect_color = "#FFA800"
                else
                    stat_effect_color = "#FF0000"
                end
            else
                debug(flag2, "    external stat effect")
                stat_effect_icon = "ss_stat_effect_" .. effect_name .. ".png"
                if stat == "hot" then
                    if status_effects[stat .. "_4"] then
                        stat_effect_color = "#FF0000"
                    else
                        stat_effect_color = "#FFA800"
                    end
                elseif stat == "cold" then
                    if status_effects[stat .. "_3"] then
                        stat_effect_color = "#FF0000"
                    else
                        stat_effect_color = "#FFA800"
                    end
                else
                    debug(flag2, "    ERROR - Unexpected 'stat' value: " .. stat)
                end
            end
            debug(flag2, "    stat_effect_color: " .. stat_effect_color)
            local effect_description = STAT_EFFECT_INFO[effect_name]
            debug(flag2, "    effect_description: " .. effect_description)
            local effect_fix_text = STAT_EFFECT_FIX[stat]
            local description_offset = 0
            if string.len(effect_fix_text) > 50 then
                description_offset = 0.40
            end
            debug(flag2, "    effect_fix_text: " .. effect_fix_text)

            fs_part6 = fs_part6 .. table_concat({
            "image[0,", y_offset - 0.1, ";0.5,0.5;" .. stat_effect_icon .. ";]",
            "hypertext[0.6,", y_offset, ";6,1;stat_effect_desc_label;",
                "<style color=", stat_effect_color, " size=15><b>", effect_description, "</b></style>]",
            "hypertext[0.8,", y_offset + 0.4, ";5.8,2;stat_effect_fix_label;",
                "<style color=#AAAAAA size=14><i>", effect_fix_text, "</i></style>]"
            })
            stat_effects_counter = stat_effects_counter + 1 + description_offset
        end
        local fs_part7 = "scroll_container_end[]"

        local fs_part4 = ""
        local scroll_pos = p_data.stat_effects_scroll_pos or 0
        if stat_effects_counter > 9 then
            debug(flag2, "    more than 9 status effects active. added scrollbar..")
            local total_scroll_distance = (stat_effects_counter - 9) * 20
            fs_part4 = table.concat({
                "scrollbaroptions[min=0;max=", total_scroll_distance, ";smallstep=20;largestep=100;thumbsize=20;arrows=hide]",
                "scrollbar[13.1,1.75;0.3,8;vertical;scrollbar_stat_effects;", scroll_pos, "]"
            })
        end
        formspec = table.concat({fs_part1, fs_part2, fs_part3, fs_part4, fs_part5, fs_part6, fs_part7})

    else
        debug(flag2, "    no active status effects")
        local fs_part4 = table_concat({
            "hypertext[7.8,4.0;6,1;stat_effect_desc_label;",
                "<style color=#666666 size=18><b>(no health conditions)</b></style>]"
            })

        formspec = table.concat({fs_part1, fs_part2, fs_part3, fs_part4})
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


    if fields.inv_tabs == "2" then
        debug(flag1, "  clicked on 'STATUS' tab!")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "status"
        get_fs_tab_status(player, player_name, player_meta, p_data)

    else
        debug(flag1, "  did not click on STATUS tab")
        if p_data.formspec_mode ~= "main_formspec" then
            --debug(flag1, "  interaction not from main formspec. NO FURTHER ACTION.")
            --debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif p_data.active_tab ~= "status" then
            debug(flag1, "  interaction from main formspec, but not STATUS tab. NO FURTHER ACTION.")
            p_data.stat_effects_scroll_pos = 0
            local job_handle = job_handles[player_name].refresh_status_tab
            if job_handle then
                --debug(flag1, "  refresh loop still running. stopping now..")
                job_handle:cancel()
                job_handles[player_name].refresh_status_tab = nil
            end
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "3"
            or fields.inv_tabs == "4"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6"
            or fields.inv_tabs == "7" then
            debug(flag1, "  clicked on a tab that was not STATUS")
            p_data.stat_effects_scroll_pos = 0
            local job_handle = job_handles[player_name].refresh_status_tab
            if job_handle then
                --debug(flag1, "  refresh loop still running. stopping now..")
                job_handle:cancel()
                job_handles[player_name].refresh_status_tab = nil
            end
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.quit then
            debug(flag1, "  exited formspec. NO FURTHER ACTION.")
            p_data.active_tab = "main"
            p_data.stat_effects_scroll_pos = 0
            --debug(flag1, "  cancel Status tab refresh loop")
            local job_handle = job_handles[player_name].refresh_status_tab
            if job_handle then
                --debug(flag1, "  refresh loop still running. stopping now..")
                job_handle:cancel()
                job_handles[player_name].refresh_status_tab = nil
            end
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.scrollbar_stat_effects then
            debug(flag1, "  ** ACTIVATED SCROLLBAR ** ")
            --debug(flag1, "  fields.scrollbar_stat_effects: " .. dump(fields.scrollbar_stat_effects))
            p_data.stat_effects_scroll_pos = string.sub(fields.scrollbar_stat_effects, 5)

        else
            debug(flag1, "  clicked on a STATUS formspec element")
        end
    end

    debug(flag1, "  clicked on a status setting element. checking additional fields..")

    -- check for further status related form interaction here

    debug(flag1, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)


local flag3 = false
core.register_on_dieplayer(function(player)
    debug(flag3, "\nregister_on_dieplayer() STATUS TAB")
    local player_name = player:get_player_name()

    if job_handles[player_name].refresh_status_tab then
        debug(flag1, "  refresh status tab loop was running")
        debug(flag1, "  cancel get_fs_tab_status() loop..")
        local job_handle = job_handles[player_name].refresh_status_tab
        job_handle:cancel()
        job_handles[player_name].refresh_status_tab = nil
    else
        debug(flag3, "  refresh status tab loop was not running")
    end

    debug(flag3, "register_on_dieplayer() end")
end)