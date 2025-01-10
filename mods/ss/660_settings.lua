print("- loading settings.lua")

-- cache global functions for faster access
local table_concat = table.concat
local mt_show_formspec = minetest.show_formspec
local mt_get_gametime = minetest.get_gametime
local mt_serialize = minetest.serialize
local debug = ss.debug
local play_item_sound = ss.play_item_sound
local get_fs_player_stats = ss.get_fs_player_stats
local get_fs_bag_slots = ss.get_fs_bag_slots
local get_fs_ingred_box = ss.get_fs_ingred_box
local get_fs_crafting_grid = ss.get_fs_crafting_grid
local build_fs = ss.build_fs


-- the position on the 'settings' formspec of each color swatch/box. this info is
-- used to position the white box that highlights the currently selected color.
local color_swatch_pos = {
    ui_green_opt1 = "0.46,1.76",
    ui_green_opt2 = "0.96,1.76",
    ui_green_opt3 = "1.46,1.76",
    ui_green_opt4 = "1.96,1.76",

    ui_orange_opt1 = "0.46,2.46",
    ui_orange_opt2 = "0.96,2.46",
    ui_orange_opt3 = "1.46,2.46",
    ui_orange_opt4 = "1.96,2.46",

    ui_red_opt1 = "0.46,3.16",
    ui_red_opt2 = "0.96,3.16",
    ui_red_opt3 = "1.46,3.16",
    ui_red_opt4 = "1.96,3.16"
}


local flag3 = false
local function get_settings_formspec(player_name)
    debug(flag3, "\nget_settings_formspec()")

    local p_data = ss.player_data[player_name]
    local formspec = table_concat({
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.45]",
        "tabheader[0,0;inv_tabs;Main,Bundle,Skills,Settings,?,*;4;true;true]",
        "hypertext[0.2,0.2;5,1.5;settings_title;<style color=#AAAAAA size=16><b>GAME SETTINGS</b></style>]",

        "box[0.2,0.9;7.0,3.4;#111111]",
        "hypertext[0.5,1.1;7,1.5;settings_text_green;<style color=#CCCCCC size=15><b>Icon, tooltip, and text highlights:</b></style>]",

        "box[", color_swatch_pos[p_data.ui_green_selected], ";0.5,0.6;#ffffff]",
        "image_button[0.5,1.8;0.4,0.5;[fill:1x1:#008000;ui_green_opt1;;false;false;[fill:1x1:#00C000]",
        "image_button[1.0,1.8;0.4,0.5;[fill:1x1:#00C000;ui_green_opt2;;false;false;[fill:1x1:#00FF00]",
        "image_button[1.5,1.8;0.4,0.5;[fill:1x1:#00FF00;ui_green_opt3;;false;false;[fill:1x1:#60ff60]",
        "image_button[2.0,1.8;0.4,0.5;[fill:1x1:#60ff60;ui_green_opt4;;false;false;[fill:1x1:#FFFFFF]",
        "style[settings_icon_green;bgcolor=", p_data.ui_green, "]",
        "item_image_button[2.8,1.77;0.6,0.6;ss:stick;settings_icon_green;]",
        "tooltip[settings_icon_green;tooltip background example;", p_data.ui_green, ";white]",
        "hypertext[3.6,1.95;5,1.5;settings_text_green;<style font=mono color=", p_data.ui_green, " size=15><b>\"Sample Green Text\"</b></style>]",

        "box[", color_swatch_pos[p_data.ui_orange_selected], ";0.5,0.6;#ffffff]",
        "image_button[0.5,2.5;0.4,0.5;[fill:1x1:#c63d00;ui_orange_opt1;;false;false;[fill:1x1:#c63d00]",
        "image_button[1.0,2.5;0.4,0.5;[fill:1x1:#ef4f00;ui_orange_opt2;;false;false;[fill:1x1:#ef4f00]",
        "image_button[1.5,2.5;0.4,0.5;[fill:1x1:#ff8000;ui_orange_opt3;;false;false;[fill:1x1:#ff8000]",
        "image_button[2.0,2.5;0.4,0.5;[fill:1x1:#ffae12;ui_orange_opt4;;false;false;[fill:1x1:#ffae12]",
        "style[settings_icon_orange;bgcolor=", p_data.ui_orange, "]",
        "item_image_button[2.8,2.45;0.6,0.6;ss:stick;settings_icon_orange;]",
        "tooltip[settings_icon_orange;tooltip background example;", p_data.ui_orange, ";white]",
        "hypertext[3.6,2.55;5,1.5;settings_text_orange;<style font=mono color=", p_data.ui_orange, " size=15><b>\"Sample Orange Text\"</b></style>]",

        "box[", color_swatch_pos[p_data.ui_red_selected], ";0.5,0.6;#ffffff]",
        "image_button[0.5,3.2;0.4,0.5;[fill:1x1:#800000;ui_red_opt1;;false;false;[fill:1x1:#C00000]",
        "image_button[1.0,3.2;0.4,0.5;[fill:1x1:#C00000;ui_red_opt2;;false;false;[fill:1x1:#FF0000]",
        "image_button[1.5,3.2;0.4,0.5;[fill:1x1:#FF0000;ui_red_opt3;;false;false;[fill:1x1:#ff6060]",
        "image_button[2.0,3.2;0.4,0.5;[fill:1x1:#ff6060;ui_red_opt4;;false;false;[fill:1x1:#FFFFFF]",
        "style[settings_icon_red;bgcolor=", p_data.ui_red, "]",
        "item_image_button[2.8,3.15;0.6,0.6;ss:stick;settings_icon_red;]",
        "tooltip[settings_icon_red;tooltip background example;", p_data.ui_red, ";white]",
        "hypertext[3.6,3.25;5,1.5;settings_text_red;<style font=mono color=", p_data.ui_red, " size=15><b>\"Sample Red Text\"</b></style>]",

    })

    debug(flag3, "get_settings_formspec()")
    return formspec
end



local flag1 = false
minetest.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() SETTINGS.lua")
    --debug(flag1, "  fields: " .. dump(fields))
    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
    debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag1, "  active_tab: " .. p_data.active_tab)

    if fields.inv_tabs == "4" then
        debug(flag1, "  clicked on 'SETTINGS' tab! showing settings formspec..")
        play_item_sound("button", {player_name = player_name})
        p_data.active_tab = "settings"
        local formspec = get_settings_formspec(player_name)
        mt_show_formspec(player_name, "ss:ui_settings", formspec)
        debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
        return

    else
        debug(flag1, "  did not click on main SETTINGS tab")
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
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6" then
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

    debug(flag1, "  clicked on a settings element. checking additional fields..")
    play_item_sound("button", {player_name = player_name})

    local player_meta = player:get_meta()
    local update_ui_colors = true
    if fields.ui_green_opt1 then
        debug(flag1, "  clicked on ui_green_opt1")
        if p_data.ui_green_selected == "ui_green_opt1" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_green = "#008000"
            p_data.ui_green_selected = "ui_green_opt1"
            player_meta:set_string("ui_green", "#008000")
            player_meta:set_string("ui_green_selected", "ui_green_opt1")
        end

    elseif fields.ui_green_opt2 then
        debug(flag1, "  clicked on ui_green_opt2")
        if p_data.ui_green_selected == "ui_green_opt2" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_green = "#00C000"
            p_data.ui_green_selected = "ui_green_opt2"
            player_meta:set_string("ui_green", "#00C000")
            player_meta:set_string("ui_green_selected", "ui_green_opt2")
        end

    elseif fields.ui_green_opt3 then
        debug(flag1, "  clicked on ui_green_opt3")
        if p_data.ui_green_selected == "ui_green_opt3" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_green = "#00FF00"
            p_data.ui_green_selected = "ui_green_opt3"
            player_meta:set_string("ui_green", "#00FF00")
            player_meta:set_string("ui_green_selected", "ui_green_opt3")
        end

    elseif fields.ui_green_opt4 then
        debug(flag1, "  clicked on ui_green_opt4")
        if p_data.ui_green_selected == "ui_green_opt4" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_green = "#60ff60"
            p_data.ui_green_selected = "ui_green_opt4"
            player_meta:set_string("ui_green", "#60ff60")
            player_meta:set_string("ui_green_selected", "ui_green_opt4")
        end





    elseif fields.ui_orange_opt1 then
        debug(flag1, "  clicked on ui_orange_opt1")
        if p_data.ui_orange_selected == "ui_orange_opt1" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_orange = "#c63d00"
            p_data.ui_orange_selected = "ui_orange_opt1"
            player_meta:set_string("ui_orange", "#c63d00")
            player_meta:set_string("ui_orange_selected", "ui_orange_opt1")
        end

    elseif fields.ui_orange_opt2 then
        debug(flag1, "  clicked on ui_orange_opt2")
        if p_data.ui_orange_selected == "ui_orange_opt2" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_orange = "#ef4f00"
            p_data.ui_orange_selected = "ui_orange_opt2"
            player_meta:set_string("ui_orange", "#ef4f00")
            player_meta:set_string("ui_orange_selected", "ui_orange_opt2")
        end

    elseif fields.ui_orange_opt3 then
        debug(flag1, "  clicked on ui_orange_opt3")
        if p_data.ui_orange_selected == "ui_orange_opt3" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_orange = "#ff8000"
            p_data.ui_orange_selected = "ui_orange_opt3"
            player_meta:set_string("ui_orange", "#ff8000")
            player_meta:set_string("ui_orange_selected", "ui_orange_opt3")
        end

    elseif fields.ui_orange_opt4 then
        debug(flag1, "  clicked on ui_orange_opt4")
        if p_data.ui_orange_selected == "ui_orange_opt4" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_orange = "#ffae12"
            p_data.ui_orange_selected = "ui_orange_opt4"
            player_meta:set_string("ui_orange", "#ffae12")
            player_meta:set_string("ui_orange_selected", "ui_orange_opt4")
        end





    elseif fields.ui_red_opt1 then
        debug(flag1, "  clicked on ui_red_opt1")
        if p_data.ui_red_selected == "ui_red_opt1" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_red = "#800000"
            p_data.ui_red_selected = "ui_red_opt1"
            player_meta:set_string("ui_red", "#800000")
            player_meta:set_string("ui_red_selected", "ui_red_opt1")
        end

    elseif fields.ui_red_opt2 then
        debug(flag1, "  clicked on ui_red_opt2")
        if p_data.ui_red_selected == "ui_red_opt2" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_red = "#C00000"
            p_data.ui_red_selected = "ui_red_opt2"
            player_meta:set_string("ui_red", "#C00000")
            player_meta:set_string("ui_red_selected", "ui_red_opt2")
        end

    elseif fields.ui_red_opt3 then
        debug(flag1, "  clicked on ui_red_opt3")
        if p_data.ui_red_selected == "ui_red_opt3" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_red = "#FF0000"
            p_data.ui_red_selected = "ui_red_opt3"
            player_meta:set_string("ui_red", "#FF0000")
            player_meta:set_string("ui_red_selected", "ui_red_opt3")
        end

    elseif fields.ui_red_opt4 then
        debug(flag1, "  clicked on ui_red_opt4")
        if p_data.ui_red_selected == "ui_red_opt4" then
            debug(flag1, "  option already selected. no action.")
            update_ui_colors = false
        else
            p_data.ui_red = "#ff6060"
            p_data.ui_red_selected = "ui_red_opt4"
            player_meta:set_string("ui_red", "#ff6060")
            player_meta:set_string("ui_red_selected", "ui_red_opt4")
        end

    else
        debug(flag1, "  unimplemented interaction")
        update_ui_colors = false
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
            local item = ItemStack(recipe.icon)
            fs.right.ingredients_box = get_fs_ingred_box(player_name, item, player_inv, recipe_id)
        end

        debug(flag1, "  refreshing 'main' > crafting grid icon bg colors...")
        local recipe_category = p_data.recipe_category
        debug(flag1, "  recipe_category: " .. recipe_category)
        fs.right.craft_grid = get_fs_crafting_grid(player_name, player_inv, recipe_category)

        debug(flag1, "  saving new formspec changes..")
        player_meta:set_string("fs", mt_serialize(fs))
        player:set_inventory_formspec(build_fs(fs))

        debug(flag1, "  refreshing 'settings' tab formspec..")
        mt_show_formspec(player_name, "ss:ui_settings", get_settings_formspec(player_name))
    end



    debug(flag1, "register_on_player_receive_fields() end " .. mt_get_gametime())
end)