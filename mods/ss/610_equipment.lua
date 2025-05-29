print("- loading equipment.lua")

-- cache global functions for faster access
local math_round = math.round
local table_concat = table.concat
local mt_after = core.after
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local debug = ss.debug
local notify = ss.notify
local round = ss.round
local play_sound = ss.play_sound


local player_data = ss.player_data


local flag2 = false
local function get_fs_tab_equipment(player, player_name, player_meta, p_data)
    debug(flag2, "\n  get_fs_tab_equipment()")

    local formspec = table_concat({
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.4]",
        "tabheader[0,0;inv_tabs;Main,Equipment,Status,Skills,Bundle,Settings,?,*;2;true;true]",
        "hypertext[0.2,0.2;4,1.5;skills_title;",
        "<style color=#AAAAAA size=16><b>EQUIPMENT</b></style>]",

        "hypertext[0.4,0.9;3,1;player_level;",
        "<style color=#AAAAAA size=15><b>(in progress..)</b></style>]",
    })

    debug(flag2, "  get_fs_tab_equipment() END")
    return formspec
end



local flag1 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() EQUIPMENT")
	debug(flag1, "  fields: " .. dump(fields))
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local p_data = ss.player_data[player_name]
    debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag1, "  active_tab: " .. p_data.active_tab)


    if fields.inv_tabs == "2" then
        debug(flag1, "  clicked on 'EQUIPMENT' tab!")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "equipment"

        local formspec = get_fs_tab_equipment(player, player_name, player_meta, p_data)
        mt_show_formspec(player_name, "ss:ui_equipment", formspec)
    else
        debug(flag1, "  did not click on EQUIPMENT tab")
        if p_data.formspec_mode ~= "main_formspec" then
            debug(flag1, "  interaction not from main inventory formspec. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif p_data.active_tab ~= "equipment" then
            debug(flag1, "  interaction from main formspec, but not EQUIPMENT tab. no further action.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "3"
            or fields.inv_tabs == "4"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6"
            or fields.inv_tabs == "7"
            or fields.inv_tabs == "8" then
            debug(flag1, "  clicked on a tab that was not EQUIPMENT")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.quit then
            debug(flag1, "  exited formspec. no further action.")
            p_data.active_tab = "main"
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        else
            debug(flag1, "  clicked on an EQUIPMENT formspec element")
        end
    end

    debug(flag1, "  clicked on an equipment setting element. checking additional fields..")

    -- check for further equipment related form interaction here

    debug(flag1, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)
