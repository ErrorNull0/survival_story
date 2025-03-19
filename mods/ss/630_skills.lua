print("- loading skills.lua")

-- cache global functions for faster access
local table_concat = table.concat
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local debug = ss.debug
local round = ss.round
local play_sound = ss.play_sound



local flag1 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() SKILLS.lua")
	--debug(flag1, "  fields: " .. dump(fields))
    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
    debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag1, "  active_tab: " .. p_data.active_tab)


    if fields.inv_tabs == "3" then
        debug(flag1, "  clicked on 'SKILLS' tab!")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "skills"
        local player_meta = player:get_meta()
        local xp_current = round(player_meta:get_float("experience_current"), 1)
        local xp_max = round(player_meta:get_float("experience_max"), 1)
        local x_pos = 0.2
        local y_pos = 0.2
        local formspec = table_concat({
            "formspec_version[7]",
            "size[22.2,10.5,true]",
            "position[0.5,0.4]",
            "tabheader[0,0;inv_tabs;Main,Status,Skills,Bundle,Settings,?,*;3;true;true]",
            "hypertext[0.2,0.2;4,1.5;skills_title;",
            "<style color=#AAAAAA size=16><b>PLAYER SKILLS</b></style>]",

            "hypertext[", x_pos, ",", y_pos + 0.5, ";3,1;player_level;",
            "<style color=#777777 size=15><b>Level:  </b></style>",
            "<style color=#AAAAAA size=15><b>", p_data.player_level, "</b></style>]",

            "hypertext[", x_pos + 3.0, ",", y_pos + 0.5, ";3,1;player_skill_points;",
            "<style color=#777777 size=15><b>Skill Points: </b></style>",
            "<style color=#AAAAAA size=15><b>", p_data.player_skill_points, "</b></style>]",

            "hypertext[", x_pos, ",", y_pos + 1.5, ";6,1;player_experience;",
            "<style color=#CCCCCC size=15><b>Experience  </b></style>]",
            "hypertext[", x_pos + 2.5, ",", y_pos + 1.5, ";6,1;player_experience_values;",
            "<style color=#AAAAAA size=15><b>", xp_current, "</b></style>",
            "<style color=#999999 size=15><b> / </b></style>",
            "<style color=#AAAAAA size=15><b>", xp_max, "</b></style>",
            "]"

        })
        mt_show_formspec(player_name, "ss:ui_skills", formspec)

    else
        debug(flag1, "  did not click on SKILLS tab")
        if p_data.formspec_mode ~= "main_formspec" then
            debug(flag1, "  interaction not from main formspec. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif p_data.active_tab ~= "skills" then
            debug(flag1, "  interaction from main formspec, but not SKILLS tab. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "2"
            or fields.inv_tabs == "4"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6"
            or fields.inv_tabs == "7" then
            debug(flag1, "  clicked on a tab that was not SKILLS. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.quit then
            debug(flag1, "  exited formspec. NO FURTHER ACTION.")
            p_data.active_tab = "main"
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        else
            debug(flag1, "  clicked on a SKILLS formspec element")
        end
    end

    debug(flag1, "  clicked on a skills setting element. checking additional fields..")

    -- check for further skills related form interaction here

    debug(flag1, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)