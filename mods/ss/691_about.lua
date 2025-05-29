print("- loading about.lua")

-- cache global functions for faster access
local table_concat = table.concat
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local debug = ss.debug
local play_sound = ss.play_sound



local flag1 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() ABOUT.lua")
	--debug(flag1, "  fields: " .. dump(fields))
    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
    debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag1, "  active_tab: " .. p_data.active_tab)


    if fields.inv_tabs == "8" then
        debug(flag1, "  clicked on 'ABOUT' tab!")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "about"

        local forum_link = "https://forum.luanti.org/viewtopic.php?t=30117&sid=15aea0f136f19ae32cbe1111dd1e8720"
        local youtube_link = "https://www.youtube.com/channel/UCQbKPmRQXBTuhEPYr_G68fA"

        local formspec = table_concat({
            "formspec_version[7]",
            "size[22.2,10.5,true]",
            "position[0.5,0.4]",
            "tabheader[0,0;inv_tabs;Main,Equipment,Status,Skills,Bundle,Settings,?,*;8;true;true]",
            "hypertext[0.2,0.2;4,1.5;about_title;",
            "<style color=#AAAAAA size=16><b>ABOUT</b></style>]",

            "hypertext[0.5,1.0;5,1;game_title;",
            "<style color=#AAAAAA size=17><b>Survival Story v0.0.3</b></style>]",

            "hypertext[0.5,1.6;3,1;game_creator;",
            "<style color=#AAAAAA size=15><b>by ErrorNull</b></style>]",

            "button_url[0.5,2.7;2.8,0.7;forum_link;Luanti Forum;", forum_link, "]",
            "button_url[0.5,3.6;2.8,0.7;forum_link;Youtube Devlog;", youtube_link, "]"
        })
        mt_show_formspec(player_name, "ss:ui_about", formspec)

    else
        debug(flag1, "  did not click on ABOUT tab")
        if p_data.formspec_mode ~= "main_formspec" then
            debug(flag1, "  interaction not from main formspec. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif p_data.active_tab ~= "about" then
            debug(flag1, "  interaction from main formspec, but not ABOUT tab. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "2"
            or fields.inv_tabs == "3"
            or fields.inv_tabs == "4"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6"
            or fields.inv_tabs == "7" then
            debug(flag1, "  clicked on a tab other than ABOUT. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.quit then
            debug(flag1, "  exited formspec. NO FURTHER ACTION.")
            p_data.active_tab = "main"
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        else
            debug(flag1, "  clicked on a ABOUT formspec element")
        end
    end

    debug(flag1, "  clicked on a ABOUT setting element. checking additional fields..")

    -- check for further ABOUT related form interaction here

    debug(flag1, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)