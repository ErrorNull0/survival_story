print("- loading settings.lua")

-- cache global functions for faster access
local string_split = string.split
local string_sub = string.sub
local table_concat = table.concat
local table_copy = table.copy
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local mt_serialize = core.serialize
local debug = ss.debug
local play_sound = ss.play_sound
local notify = ss.notify
local get_fs_player_stats = ss.get_fs_player_stats
local get_fs_bag_slots = ss.get_fs_bag_slots
local get_fs_ingred_box = ss.get_fs_ingred_box
local get_fs_crafting_grid = ss.get_fs_crafting_grid
local build_fs = ss.build_fs
local initialize_hud_stats = ss.initialize_hud_stats
local update_tooltips = ss.update_tooltips
local update_base_stat_value = ss.update_base_stat_value
local shift_hud_stat_effects = ss.shift_hud_stat_effects

local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local PLAYER_SKILLS = ss.PLAYER_SKILLS
local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids



-- the position on the 'settings' formspec of each color swatch/box. this info is
-- used to position the white box that highlights the currently selected color.
local color_swatch_pos = {
    ui_green_opt1 = "0.26,0.86",
    ui_green_opt2 = "0.76,0.86",
    ui_green_opt3 = "1.26,0.86",
    ui_green_opt4 = "1.76,0.86",

    ui_orange_opt1 = "0.26,1.56",
    ui_orange_opt2 = "0.76,1.56",
    ui_orange_opt3 = "1.26,1.56",
    ui_orange_opt4 = "1.76,1.56",

    ui_red_opt1 = "0.26,2.26",
    ui_red_opt2 = "0.76,2.26",
    ui_red_opt3 = "1.26,2.26",
    ui_red_opt4 = "1.76,2.26"
}

local statbar_x_pos = {0.3, 1.03, 1.76, 2.49, 3.22, 3.95, 4.68, 5.41, 6.14, 6.87, 7.6}

-- set the transparency of the color background behind the statbars and the
-- status effect images. hex values from '00' to 'FF' where higher is more opaque,
-- representing 100%, 75%, 50%, 25%, and 0% opacity.
local STAT_BG_OPACITY = {"FF", "C0", "80", "40", "00"}

local flag3 = false
local function get_settings_formspec(player_name)
    debug(flag3, "\nget_settings_formspec()")
    local p_data = ss.player_data[player_name]

    local statbar_elements = ""
    for stat, stat_data in pairs(p_data.statbar_settings_pending) do
        debug(flag3, "  stat: " .. stat)
        local hud_pos = stat_data.hud_pos
        local checkbox_tooltip, checkbox_status
        if stat_data.active then
            checkbox_tooltip = "click to hide"
            checkbox_status = "true"
        else
            checkbox_tooltip = "click to show"
            checkbox_status = "false"
        end
        statbar_elements = table_concat({ statbar_elements,
            "image[", statbar_x_pos[hud_pos], ",0.8;0.6,0.6;ss_statbar_icon_", stat, ".png;]",
            "tooltip[", statbar_x_pos[hud_pos], ",0.5;0.6,0.7;", stat, ";",
                TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
            "checkbox[", statbar_x_pos[hud_pos] + 0.15, ",1.6;statbars_checkbox_", stat, ";;", checkbox_status, "]",
            "tooltip[", statbar_x_pos[hud_pos] + 0.15, ",1.3;0.4,0.5;", checkbox_tooltip, ";",
                TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
        })
    end

    local stat_bg_opacity_index
    for i = 1, 5 do
        if STAT_BG_OPACITY[i] == p_data.stats_bg_opacity then
            stat_bg_opacity_index = i
            break
        end
    end
    debug(flag3, "  stat_bg_opacity_index: " .. stat_bg_opacity_index)

    local notify_selected_inventory = "false"
    local notify_selected_cooldowns = "false"
    local notify_selected_stat_effects = "false"
    local notify_selected_mobs = "false"
    local notify_selected_errors = "false"
    if p_data.notify_active_inventory == 1 then
        notify_selected_inventory = "true"
    end
    if p_data.notify_active_cooldowns == 1 then
        notify_selected_cooldowns = "true"
    end
    if p_data.notify_active_stat_effects == 1 then
        notify_selected_stat_effects = "true"
    end
    if p_data.notify_active_mobs == 1 then
        notify_selected_mobs = "true"
    end
    if p_data.notify_active_errors == 1 then
        notify_selected_errors = "true"
    end

    local formspec = table_concat({
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.4]",
        "tabheader[0,0;inv_tabs;Main,Equipment,Status,Skills,Bundle,Settings,?,*;6;true;true]",
        "hypertext[0.2,0.2;5,1.5;settings_title;<style color=#AAAAAA size=16><b>GAME SETTINGS</b></style>]",

        -- statbar configuration
        "container[0.2,0.9]",
        "box[0,0;8.6,3.0;#111111]",
        "hypertext[0.3,0.2;7,0.6;statbars_label;<style color=#CCCCCC size=15><b>statbar configuration:</b></style>]",
        statbar_elements,
        "button[0.45,2.1;2.8,0.6;statbars_button_apply;Apply Changes]",
        "label[3.65,2.45;background opacity:]",
        "dropdown[6.65,2.2;1.5,0.5;statbars_dropdown_opacity;100%,75%,50%,25%,0%;", stat_bg_opacity_index, ";true]",
        "container_end[]",

        -- temperature units
        "container[9.1,0.9]",
        "box[0,0;3.7,1.7;#111111]",
        "hypertext[0.3,0.2;7,1.5;temperature_label;<style color=#CCCCCC size=15><b>thermal units:</b></style>]",
        "dropdown[0.3,0.85;3.0,0.5;temperature_dropdown_units;Fahrenheit (°F),Celcius (°C);", p_data.thermal_units, ";true]",
        "container_end[]",

        -- popup text notifications
        "container[0.2,4.2]",
        "box[0,0;8.6,2.3;#111111]",
        "hypertext[0.3,0.2;7,1.5;temperature_label;<style color=#CCCCCC size=15><b>popup text notifications:</b></style>]",
        "checkbox[0.3,0.95;notify_inventory;inventory actions;", notify_selected_inventory, "]",
        "checkbox[0.3,1.40;notify_cooldowns;action cooldowns;", notify_selected_cooldowns, "]",
        "checkbox[0.3,1.85;notify_errors;game errors;", notify_selected_errors, "]",
        "checkbox[4.5,0.95;notify_stat_effects;status effects;", notify_selected_stat_effects, "]",
        "checkbox[4.5,1.40;notify_mobs;mob actions;", notify_selected_mobs, "]",
        "container_end[]",

        -- highlight color settings
        "container[0.2,6.75]",
        "box[0,0;8.6,3.4;#111111]",
        "hypertext[0.3,0.2;7,1.5;settings_text_green;<style color=#CCCCCC size=15><b>Icon, tooltip, and text highlights:</b></style>]",

        "box[", color_swatch_pos[p_data.ui_green_selected], ";0.5,0.6;#ffffff]",
        "image_button[0.3,0.9;0.4,0.5;[fill:1x1:#008000;ui_green_opt1;;false;false;[fill:1x1:#00C000]",
        "image_button[0.8,0.9;0.4,0.5;[fill:1x1:#00C000;ui_green_opt2;;false;false;[fill:1x1:#00FF00]",
        "image_button[1.3,0.9;0.4,0.5;[fill:1x1:#00FF00;ui_green_opt3;;false;false;[fill:1x1:#60ff60]",
        "image_button[1.8,0.9;0.4,0.5;[fill:1x1:#60ff60;ui_green_opt4;;false;false;[fill:1x1:#FFFFFF]",
        "style[settings_icon_green;bgcolor=", p_data.ui_green, "]",
        "item_image_button[3.0,0.87;0.6,0.6;ss:stick;settings_icon_green;]",
        "tooltip[settings_icon_green;tooltip background example;", p_data.ui_green, ";white]",
        "hypertext[4.4,1.05;5,1.5;settings_text_green;<style font=mono color=", p_data.ui_green, " size=15><b>\"Sample Green Text\"</b></style>]",

        "box[", color_swatch_pos[p_data.ui_orange_selected], ";0.5,0.6;#ffffff]",
        "image_button[0.3,1.6;0.4,0.5;[fill:1x1:#c63d00;ui_orange_opt1;;false;false;[fill:1x1:#c63d00]",
        "image_button[0.8,1.6;0.4,0.5;[fill:1x1:#ef4f00;ui_orange_opt2;;false;false;[fill:1x1:#ef4f00]",
        "image_button[1.3,1.6;0.4,0.5;[fill:1x1:#ff8000;ui_orange_opt3;;false;false;[fill:1x1:#ff8000]",
        "image_button[1.8,1.6;0.4,0.5;[fill:1x1:#ffae12;ui_orange_opt4;;false;false;[fill:1x1:#ffae12]",
        "style[settings_icon_orange;bgcolor=", p_data.ui_orange, "]",
        "item_image_button[3.0,1.55;0.6,0.6;ss:stick;settings_icon_orange;]",
        "tooltip[settings_icon_orange;tooltip background example;", p_data.ui_orange, ";white]",
        "hypertext[4.4,1.65;5,1.5;settings_text_orange;<style font=mono color=", p_data.ui_orange, " size=15><b>\"Sample Orange Text\"</b></style>]",

        "box[", color_swatch_pos[p_data.ui_red_selected], ";0.5,0.6;#ffffff]",
        "image_button[0.3,2.3;0.4,0.5;[fill:1x1:#800000;ui_red_opt1;;false;false;[fill:1x1:#C00000]",
        "image_button[0.8,2.3;0.4,0.5;[fill:1x1:#C00000;ui_red_opt2;;false;false;[fill:1x1:#FF0000]",
        "image_button[1.3,2.3;0.4,0.5;[fill:1x1:#FF0000;ui_red_opt3;;false;false;[fill:1x1:#ff6060]",
        "image_button[1.8,2.3;0.4,0.5;[fill:1x1:#ff6060;ui_red_opt4;;false;false;[fill:1x1:#FFFFFF]",
        "style[settings_icon_red;bgcolor=", p_data.ui_red, "]",
        "item_image_button[3.0,2.25;0.6,0.6;ss:stick;settings_icon_red;]",
        "tooltip[settings_icon_red;tooltip background example;", p_data.ui_red, ";white]",
        "hypertext[4.4,2.35;5,1.5;settings_text_red;<style font=mono color=", p_data.ui_red, " size=15><b>\"Sample Red Text\"</b></style>]",
        "container_end[]",
    })

    debug(flag3, "get_settings_formspec()")
    return formspec
end



local flag1 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() SETTINGS.lua")
    debug(flag1, "  fields: " .. dump(fields))
    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
    debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag1, "  active_tab: " .. p_data.active_tab)

    if fields.inv_tabs == "6" then
        debug(flag1, "  clicked on 'SETTINGS' tab! showing settings formspec..")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "settings"
        local formspec = get_settings_formspec(player_name)
        mt_show_formspec(player_name, "ss:ui_settings", formspec)
        debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
        return

    else
        debug(flag1, "  did not click on SETTINGS tab")
        if p_data.formspec_mode ~= "main_formspec" then
            debug(flag1, "  interaction not from main formspec. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif p_data.active_tab ~= "settings" then
            debug(flag1, "  interaction from main formspec, but not SETTINGS tab. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "2"
            or fields.inv_tabs == "3"
            or fields.inv_tabs == "4"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "7"
            or fields.inv_tabs == "8" then
            debug(flag1, "  clicked on a tab that was not SETTINGS. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.quit then
            debug(flag1, "  exited formspec. NO FURTHER ACTION.")
            p_data.active_tab = "main"
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        else
            debug(flag1, "  clicked on a SETTINGS formspec element")
        end
    end

    play_sound("button", {player_name = player_name})

    debug(flag1, "  checking additional fields..")
    local player_meta = player:get_meta()

    local category, element, selection
    for key, value in pairs(fields) do
        local tokens = string_split(key, "_")
        category = tokens[1]
        element = tokens[2]
        selection = tokens[3]
        if element ~= "dropdown" then
            break
        end
    end

    ----------------------------
    -- statbars configuration --
    ----------------------------
    if category == "statbars" then
        debug(flag1, "  clicked on a 'statbars' element")

        if element == "checkbox" then
            debug(flag1, "  clicked on a checkbox")
            local stat_data = p_data.statbar_settings_pending[selection]
            if fields["statbars_checkbox_" .. selection] == "true" then
                debug(flag1, "  CHECKED box for " .. selection)
                stat_data.active = true
                for _, stat_data_2 in pairs(p_data.statbar_settings_pending) do
                    if stat_data_2.hud_pos < stat_data.hud_pos then
                        if not stat_data_2.active then
                            local hud_pos = stat_data.hud_pos
                            stat_data.hud_pos = stat_data_2.hud_pos
                            stat_data_2.hud_pos = hud_pos
                        end
                    end
                end
            else
                debug(flag1, "  UNCHECKED health checkbox")
                stat_data.active = false
                for _, stat_data_2 in pairs(p_data.statbar_settings_pending) do
                    if stat_data_2.hud_pos > stat_data.hud_pos then
                        stat_data_2.hud_pos = stat_data_2.hud_pos - 1
                    end
                end
                stat_data.hud_pos = p_data.total_statbar_count
            end
            p_data.unsaved_statbar_settings = true
            debug(flag1, "  statbar_settings_pending: " .. dump(p_data.statbar_settings_pending))
            mt_show_formspec(player_name, "ss:ui_settings", get_settings_formspec(player_name))

        elseif element == "button" then
            debug(flag1, "  clicked on 'apply' button")
            local any_settings_changed = false

            local new_active_count = p_data.active_statbar_count
            debug(flag1, "  set new_active_count to prev count: " .. p_data.active_statbar_count)

            debug(flag1, "  update statbar visibility and sort order if needed")
            if p_data.unsaved_statbar_settings then
                debug(flag1, "    visibility and sort order changed. applying changes..")
                p_data.unsaved_statbar_settings = false
                any_settings_changed = true

                -- temporarily mark all existing statbars as inactive to prevent any
                -- existing update_stat() calls from modifying the statbar huds for now
                for _, stat_data in pairs(p_data.statbar_settings) do
                    stat_data.active = false
                end

                -- temporarily remove all the vertical statbar huds as they will be
                -- re-added using new settings
                debug(flag1, "    removing all existing hud elements relating to statbars..")
                local p_huds = player_hud_ids[player_name]
                for stat in pairs(p_data.statbar_settings) do
                    local stat_hud_ids = p_huds[stat]
                    if stat_hud_ids then
                        player:hud_remove(stat_hud_ids.bg)
                        player:hud_remove(stat_hud_ids.icon)
                        player:hud_remove(stat_hud_ids.bar)
                        player:hud_remove(stat_hud_ids.base)
                        player_hud_ids[player_name][stat] = nil
                    end
                end

                -- replacing existing statbar settings with 'pending' one
                p_data.statbar_settings = table_copy(p_data.statbar_settings_pending)
                player_meta:set_string("statbar_settings", mt_serialize(p_data.statbar_settings))
                --debug(flag1, "  p_data.statbar_settings: " .. dump(p_data.statbar_settings))

                debug(flag1, "    re-initializing all statbars with selected statbar changes")
                new_active_count = 0
                for stat, stat_data in pairs(p_data.statbar_settings) do
                    if stat_data.active then
                        initialize_hud_stats(player, player_name, stat, stat_data,
                        player_meta:get_float(stat .. "_current"))
                        new_active_count = new_active_count + 1
                        update_base_stat_value(player, player_meta, player_name, p_data, {stat})
                    end
                end

            else
                debug(flag1, "    visibilitly and sort order unchanged. no further action.")
            end
            debug(flag1, "  new_active_count (so far): " .. new_active_count)

            debug(flag1, "  update statbar main bg box width and stat effect hud positions if needed")
            if new_active_count == p_data.active_statbar_count then
                debug(flag1, "    active statbar count unchanged. no further action.")

            elseif new_active_count == 0 then
                debug(flag1, "    hiding the statbar main bg box")
                any_settings_changed = true

                debug(flag1, "    hiding statbar main bg box by reducing width to zero")
                local p_huds = player_hud_ids[player_name]
                player:hud_change(p_huds.statbar_bg_box, "scale", {x = 0, y = 145})

                debug(flag1, "    move all status effect huds down..")
                shift_hud_stat_effects(player, p_data, player_name, false)

                -- save the new statbar active count for future reference
                p_data.active_statbar_count = new_active_count
                player_meta:set_int("active_statbar_count", new_active_count)

            else
                debug(flag1, "    active statbar count changed to a non-zero quantity")
                any_settings_changed = true

                -- at this point 'p_data.active_statbar_count' represents the previous
                -- active statbar count
                if p_data.active_statbar_count == 0 then
                    debug(flag1, "    prev active count was zero")
                    shift_hud_stat_effects(player, p_data, player_name, true)
                end

                debug(flag1, "    updating statbar main bg box width")
                local x_scale = (new_active_count * 30) + 15
                local p_huds = player_hud_ids[player_name]
                player:hud_change(p_huds.statbar_bg_box, "scale", {x = x_scale, y = 145})

                -- save the new statbar active count for future reference
                p_data.active_statbar_count = new_active_count
                player_meta:set_int("active_statbar_count", new_active_count)
            end

            debug(flag1, "  update opacity for statbar main bg box width and stat effect huds if needed")
            local new_opacity = STAT_BG_OPACITY[tonumber(fields.statbars_dropdown_opacity)]
            if new_opacity == p_data.stats_bg_opacity then
                debug(flag1, "    same opacity as before. no further action")
            else
                debug(flag1, "    selected opacity is different")
                any_settings_changed = true

                player_meta:set_string("stats_bg_opacity", new_opacity)
                p_data.stats_bg_opacity = new_opacity
                debug(flag1, "    new opacity value: " .. new_opacity)

                debug(flag1, "    updating opacity for statbar main bg box")
                local p_huds = player_hud_ids[player_name]
                player:hud_change(p_huds.statbar_bg_box, "text", "[fill:1x1:0,0:#000000" .. new_opacity)

                debug(flag1, "    updating opacity for status effect background..")
                for i = 1, p_data.on_screen_max do
                    local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. i]
                    local hud_def = player:hud_get(hud_id)
                    local colorstring = string_sub(hud_def.text, 1, -3) .. new_opacity
                    debug(flag1, "      bg " .. i .. " colorstring: " .. colorstring)
                    player:hud_change(hud_id, "text", colorstring)
                end
            end

            if any_settings_changed then
                notify(player, "system", "Statbar settings updated!", 2, 0.5, 0, 2)
            else
                notify(player, "system", "No statbar changes to save", 2, 0, 0.5, 3)
            end

        elseif element == "dropdown" then
            debug(flag1, "  clicked on 'background opacity' dropdown")
            --[[
            local new_opacity = STAT_BG_OPACITY[tonumber(fields.statbars_dropdown_opacity)]
            if new_opacity == p_data.stats_bg_opacity then
                debug(flag1, "  selected opacity is same as current. no further action.")
                p_data.unsaved_opacity_settings = false
            else
                p_data.unsaved_opacity_settings = true
            end
            --]]

        else
            debug(flag1, "  ERROR - Unexpected 'element' value: " .. element)
        end


    ------------------------------
    -- popup text notifications --
    ------------------------------
    elseif category == "notify" then
        debug(flag1, "  clicked on a 'notify' element")
        if fields.notify_inventory == "true" then
            notify(player, "system", "Popup text notifications ENABLED for inventory events", 4, 0.5, 0, 2)
            p_data.notify_active_inventory = 1
            player_meta:set_int("notify_active_inventory", 1)
        elseif fields.notify_inventory == "false" then
            notify(player, "system", "Popup text notifications DISABLED for inventory events", 4, 0.5, 0, 2)
            p_data.notify_active_inventory = 0
            player_meta:set_int("notify_active_inventory", 0)

        elseif fields.notify_stat_effects == "true" then
            notify(player, "system", "Popup text notifications ENABLED for status effects", 4, 0.5, 0, 2)
            p_data.notify_active_stat_effects = 1
            player_meta:set_int("notify_active_stat_effects", 1)
        elseif fields.notify_stat_effects == "false" then
            notify(player, "system", "Popup text notifications DISABLED for status effects", 4, 0.5, 0, 2)
            p_data.notify_active_stat_effects = 0
            player_meta:set_int("notify_active_stat_effects", 0)

        elseif fields.notify_cooldowns == "true" then
            notify(player, "system", "Popup text notifications ENABLED for item cooldowns", 4, 0.5, 0, 2)
            p_data.notify_active_cooldowns = 1
            player_meta:set_int("notify_active_cooldowns", 1)
        elseif fields.notify_cooldowns == "false" then
            notify(player, "system", "Popup text notifications DISABLED for item cooldowns", 4, 0.5, 0, 2)
            p_data.notify_active_cooldowns = 0
            player_meta:set_int("notify_active_cooldowns", 0)

        elseif fields.notify_mobs == "true" then
            notify(player, "system", "Popup text notifications ENABLED for mob interactions", 4, 0.5, 0, 2)
            p_data.notify_active_mobs = 1
            player_meta:set_int("notify_active_mobs", 1)
        elseif fields.notify_mobs == "false" then
            notify(player, "system", "Popup text notifications DISABLED for mob interactions", 4, 0.5, 0, 2)
            p_data.notify_active_mobs = 0
            player_meta:set_int("notify_active_mobs", 0)

        elseif fields.notify_errors == "true" then
            notify(player, "system", "Popup text notifications ENABLED for system errors", 4, 0.5, 0, 2)
            p_data.notify_active_errors = 1
            player_meta:set_int("notify_active_errors", 1)
        elseif fields.notify_errors == "false" then
            notify(player, "system", "Popup text notifications DISABLED for system errors", 4, 0.5, 0, 2)
            p_data.notify_active_errors = 0
            player_meta:set_int("notify_active_errors", 0)

        end


    -------------------------------
    -- temperature configuration --
    -------------------------------
    elseif category == "temperature" then
        debug(flag1, "  clicked on a 'temperature' element")
        local thermal_unit_option = tonumber(fields.temperature_dropdown_units)
        debug(flag1, "    thermal_unit_option: " .. thermal_unit_option)
        if thermal_unit_option ~= p_data.thermal_units then
            p_data.thermal_units = thermal_unit_option
            player_meta:set_int("thermal_units", thermal_unit_option)
            -- update temperature related subskill tooltips in Skills menu
            update_tooltips(p_data, "coolossus", PLAYER_SKILLS.survival[3])
            update_tooltips(p_data, "crispy_crusader", PLAYER_SKILLS.survival[5])
            notify(player, "system", "Temperature units updated!", 2, 0.5, 0, 2)
        end


    ----------------------------
    -- ui color configuration --
    ----------------------------
    elseif category == "ui" then
        debug(flag1, "  clicked on a 'ui' element")
        local update_ui_colors = false

        if fields.ui_green_opt1 then
            debug(flag1, "  clicked on ui_green_opt1")
            if p_data.ui_green_selected == "ui_green_opt1" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_green = "#008000"
                p_data.ui_green_selected = "ui_green_opt1"
                player_meta:set_string("ui_green", "#008000")
                player_meta:set_string("ui_green_selected", "ui_green_opt1")
                update_ui_colors = true
            end
        elseif fields.ui_green_opt2 then
            debug(flag1, "  clicked on ui_green_opt2")
            if p_data.ui_green_selected == "ui_green_opt2" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_green = "#00C000"
                p_data.ui_green_selected = "ui_green_opt2"
                player_meta:set_string("ui_green", "#00C000")
                player_meta:set_string("ui_green_selected", "ui_green_opt2")
                update_ui_colors = true
            end
        elseif fields.ui_green_opt3 then
            debug(flag1, "  clicked on ui_green_opt3")
            if p_data.ui_green_selected == "ui_green_opt3" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_green = "#00FF00"
                p_data.ui_green_selected = "ui_green_opt3"
                player_meta:set_string("ui_green", "#00FF00")
                player_meta:set_string("ui_green_selected", "ui_green_opt3")
                update_ui_colors = true
            end
        elseif fields.ui_green_opt4 then
            debug(flag1, "  clicked on ui_green_opt4")
            if p_data.ui_green_selected == "ui_green_opt4" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_green = "#60ff60"
                p_data.ui_green_selected = "ui_green_opt4"
                player_meta:set_string("ui_green", "#60ff60")
                player_meta:set_string("ui_green_selected", "ui_green_opt4")
                update_ui_colors = true
            end

        elseif fields.ui_orange_opt1 then
            debug(flag1, "  clicked on ui_orange_opt1")
            if p_data.ui_orange_selected == "ui_orange_opt1" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_orange = "#c63d00"
                p_data.ui_orange_selected = "ui_orange_opt1"
                player_meta:set_string("ui_orange", "#c63d00")
                player_meta:set_string("ui_orange_selected", "ui_orange_opt1")
                update_ui_colors = true
            end
        elseif fields.ui_orange_opt2 then
            debug(flag1, "  clicked on ui_orange_opt2")
            if p_data.ui_orange_selected == "ui_orange_opt2" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_orange = "#ef4f00"
                p_data.ui_orange_selected = "ui_orange_opt2"
                player_meta:set_string("ui_orange", "#ef4f00")
                player_meta:set_string("ui_orange_selected", "ui_orange_opt2")
                update_ui_colors = true
            end
        elseif fields.ui_orange_opt3 then
            debug(flag1, "  clicked on ui_orange_opt3")
            if p_data.ui_orange_selected == "ui_orange_opt3" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_orange = "#ff8000"
                p_data.ui_orange_selected = "ui_orange_opt3"
                player_meta:set_string("ui_orange", "#ff8000")
                player_meta:set_string("ui_orange_selected", "ui_orange_opt3")
                update_ui_colors = true
            end
        elseif fields.ui_orange_opt4 then
            debug(flag1, "  clicked on ui_orange_opt4")
            if p_data.ui_orange_selected == "ui_orange_opt4" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_orange = "#ffae12"
                p_data.ui_orange_selected = "ui_orange_opt4"
                player_meta:set_string("ui_orange", "#ffae12")
                player_meta:set_string("ui_orange_selected", "ui_orange_opt4")
                update_ui_colors = true
            end

        elseif fields.ui_red_opt1 then
            debug(flag1, "  clicked on ui_red_opt1")
            if p_data.ui_red_selected == "ui_red_opt1" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_red = "#800000"
                p_data.ui_red_selected = "ui_red_opt1"
                player_meta:set_string("ui_red", "#800000")
                player_meta:set_string("ui_red_selected", "ui_red_opt1")
                update_ui_colors = true
            end
        elseif fields.ui_red_opt2 then
            debug(flag1, "  clicked on ui_red_opt2")
            if p_data.ui_red_selected == "ui_red_opt2" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_red = "#C00000"
                p_data.ui_red_selected = "ui_red_opt2"
                player_meta:set_string("ui_red", "#C00000")
                player_meta:set_string("ui_red_selected", "ui_red_opt2")
                update_ui_colors = true
            end
        elseif fields.ui_red_opt3 then
            debug(flag1, "  clicked on ui_red_opt3")
            if p_data.ui_red_selected == "ui_red_opt3" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_red = "#FF0000"
                p_data.ui_red_selected = "ui_red_opt3"
                player_meta:set_string("ui_red", "#FF0000")
                player_meta:set_string("ui_red_selected", "ui_red_opt3")
                update_ui_colors = true
            end
        elseif fields.ui_red_opt4 then
            debug(flag1, "  clicked on ui_red_opt4")
            if p_data.ui_red_selected == "ui_red_opt4" then
                debug(flag1, "  option already selected. no action.")
            else
                p_data.ui_red = "#ff6060"
                p_data.ui_red_selected = "ui_red_opt4"
                player_meta:set_string("ui_red", "#ff6060")
                player_meta:set_string("ui_red_selected", "ui_red_opt4")
                update_ui_colors = true
            end

        else
            debug(flag1, "  ERROR - Unimplemented interaction for 'ui' category")
        end

        if update_ui_colors then
            local fs = p_data.fs
            local player_inv = player:get_inventory()

            debug(flag1, "  refreshing 'main' > avatar pane text colors..")
            fs.left.stats = get_fs_player_stats(player_name)

            debug(flag1, "  inspecting bag slots")
            if player_inv:is_empty("bag_slots") then
                debug(flag1, "    all slots empty. NO FURTHER ACTION.")
            else
                debug(flag1, "    bag(s) in use. force refresh to show updated bg colors")
                fs.center.bag_slots = get_fs_bag_slots(player_inv, player_name)
            end

            local recipe_id = p_data.prev_recipe_id
            if recipe_id == "" then
                debug(flag1, "  no prev recipes clicked yet. ingred box not refreshed.")
            else
                debug(flag1, "  refreshing 'main' > crafting ingredients box colors..")
                debug(flag1, "  recipe_id: " .. recipe_id)
                local recipe = ss.RECIPES[recipe_id]
                fs.right.ingredients_box = get_fs_ingred_box(player_name, ItemStack(recipe.icon), player_inv, recipe_id)
            end

            debug(flag1, "  update all crafting grid recipe icons for the currently display category")
            fs.right.craft_grid = get_fs_crafting_grid(player_name, player_inv, p_data.recipe_category)

            debug(flag1, "  save the updated formspec data")
            player_meta:set_string("fs", mt_serialize(fs))
            player:set_inventory_formspec(build_fs(fs))

            debug(flag1, "  refreshing 'settings' tab formspec..")
            mt_show_formspec(player_name, "ss:ui_settings", get_settings_formspec(player_name))
        end

    else
        debug(flag1, "  ERROR - Unexpected 'category' value: " .. category)
    end


    debug(flag1, "register_on_player_receive_fields() end " .. mt_get_gametime())
end)


local flag2 = false
core.register_on_joinplayer(function(player)
	debug(flag2, "\nregister_on_joinplayer() SETTINGS")
	local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local player_status = player_meta:get_int("player_status")
    local p_data = player_data[player_name]
    local metadata

    -- initialize the highlight color option that was chosen by the player
    metadata = player_meta:get_string("ui_green_selected")
    p_data.ui_green_selected = (metadata ~= "" and metadata) or "ui_green_opt1"
    metadata = player_meta:get_string("ui_orange_selected")
    p_data.ui_orange_selected = (metadata ~= "" and metadata) or "ui_orange_opt1"
    metadata = player_meta:get_string("ui_red_selected")
    p_data.ui_red_selected = (metadata ~= "" and metadata) or "ui_red_opt1"

	debug(flag2, "\nregister_on_joinplayer() end")
end)