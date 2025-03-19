print("- loading help.lua")

-- cache global functions for faster access
local table_concat = table.concat
local mt_get_modpath = core.get_modpath
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local debug = ss.debug
local play_sound = ss.play_sound

local TOPICS = {}
local TOPIC_TEXTS = {}
local SUBTOPICS = {}
local SUBTOPIC_TEXTS = {}

local flag3 = false
debug(flag3, "Reading in file 'help_topics.txt'...")
local file_path = mt_get_modpath("ss") .. "/help_topics.txt"
local file = io.open(file_path,"r")
if not file then
    debug(flag3, "  Could not open file: " .. file_path)
    return
end
local current_topic = nil
local current_subtopic = nil
for line in file:lines() do
    line = line:match("^%s*(.-)%s*$") 
    if line == "" or line:sub(1,1) == "#" then
         goto continue
    end
    if line:sub(1,1) == "=" then
        current_topic = line:match("^=+%s*(.*)")
        TOPICS[#TOPICS+1] = current_topic
        SUBTOPICS[current_topic] = {}
        local topic_info_line = file:read("*l") or ""
        topic_info_line = topic_info_line:match("^%s*(.-)%s*$")

        -- <br> doesn't seem to force a line break within hypertext elements,
        -- using <left></left> instead, which does the job.
        topic_info_line = topic_info_line:gsub("<br>", "<left></left>")

        topic_info_line = topic_info_line:gsub(
            "<img float=left name=([%w_.-]+)>",
            "<img float=left name=%1.png>"
        )

        -- simply using <left></left> after an <img> doesn't seem to force a line break,
        -- but using a combination of <style> and <left> tags and an 'invisible' character
        -- seems to work
        topic_info_line = topic_info_line:gsub(
            "<img name=([%w_.-]+)>",
            "<img name=%1.png><style color=#333>.<left></left></style>"
        )

        TOPIC_TEXTS[current_topic] = topic_info_line
    elseif line:sub(1,1) == "-" then
        current_subtopic = line:match("^-+%s*(.*)")
        SUBTOPICS[current_topic][#SUBTOPICS[current_topic]+1] = current_subtopic
        local text = file:read("*l") or ""
        text = text:match("^%s*(.-)%s*$")

        -- <br> doesn't seem to force a line break within hypertext elements,
        -- using <left></left> instead, which does the job.
        text = text:gsub("<br>", "<left></left>")

        text = text:gsub(
            "<img float=left name=([%w_.-]+)>",
            "<img float=left name=%1.png>"
        )

        -- simply using <left></left> after an <img> doesn't seem to force a line break,
        -- but using a combination of <style> and <left> tags and an 'invisible' character
        -- seems to work
        text = text:gsub(
            "<img name=([%w_.-]+)>",
            "<img name=%1.png><style color=#333>.<left></left></style>"
        )
        SUBTOPIC_TEXTS[current_topic.." "..current_subtopic] = text
    end
    ::continue::
end
file:close()
--debug(flag3, "TOPICS: " .. dump(TOPICS))
--debug(flag3, "TOPIC_TEXTS: " .. dump(TOPIC_TEXTS))
--debug(flag3, "SUBTOPICS: " .. dump(SUBTOPICS))
--debug(flag3, "SUBTOPIC_TEXTS: " .. dump(SUBTOPIC_TEXTS))



local flag2 = false
local function get_fs_help(p_data)
    debug(flag2, "get_fs_help() HELP.lua")
    local formspec

    local fs_part_1 = table_concat({
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.4]",
        "tabheader[0,0;inv_tabs;Main,Status,Skills,Bundle,Settings,?,*;6;true;true]",
        "hypertext[0.2,0.2;4,1.5;help_title;",
        "<style color=#AAAAAA size=16><b>TOPICS</b></style>]",
        "box[8.9,0.0;13.3,10.5;#222222]",
    })

    local help_topic = p_data.help_topic
    local help_subtopic = p_data.help_subtopic
    local fs_part_2 = ""
    local fs_part_3 = ""
    local fs_part_4 = ""
    local x_offset = 0
    local y_pos = 1

    for i, topic in ipairs(TOPICS) do
        local button_element
        if topic == help_topic then
            button_element = table.concat({ fs_part_2,
                "style[topic_", topic, ";textcolor=#ffaa00;bgcolor=#000000]",
                "button[",
                    0.5 + (x_offset * 2.7), ",", (y_pos * 0.8),
                    ";2.6,0.57;topic_", topic, ";", topic, "]"
            })
        else
            button_element = table.concat({ fs_part_2,
                "button[",
                    0.5 + (x_offset * 2.7), ",", (y_pos * 0.8),
                    ";2.6,0.57;topic_", topic, ";", topic, "]"
            })
        end
        fs_part_2 = button_element

        if i % 15 == 0 then
            x_offset = x_offset + 1
            y_pos = 1
        else
            y_pos = y_pos + 0.78
        end
    end

    if help_topic == "" then
        debug(flag2, "  no existing topic selected")
        fs_part_3 = table.concat({
            "hypertext[12.5,4.5;10,2.0;no_topic;",
            "<style color=#666666 size=20><b><big>\u{21FD}</big> Choose a topic to learn more</b></style>]"
        })

    else
        debug(flag2, "  existing help topic: " .. help_topic)
        local subtopics = SUBTOPICS[help_topic]
        debug(flag2, "  subtopics: " .. dump(subtopics))

        fs_part_3 = table.concat({
            "hypertext[9.1,0.2;4,1.5;help_topic;",
            "<style color=#AAAAAA size=16><b>", help_topic, "</b></style>]",
        })

        local x_offset2 = 0
        local y_pos2 = 1
        for i, subtopic in ipairs(subtopics) do
            local button_element
            if subtopic == help_subtopic then
                button_element = table.concat({ fs_part_3,
                    "style[subtopic_", subtopic, ";textcolor=#ffaa00]",
                    "style[subtopic_", subtopic, ";bgcolor=#000000]",
                    "button[",
                        9.4 + (x_offset2 * 2.7), ",", (y_pos2 * 0.8),
                        ";2.6,0.57;subtopic_", subtopic, ";", subtopic,
                    "]"
                })
            else
                button_element = table.concat({ fs_part_3,
                    "button[",
                        9.4 + (x_offset2 * 2.7), ",", (y_pos2 * 0.8),
                        ";2.6,0.57;subtopic_", subtopic, ";", subtopic,
                    "]"
                })
            end
            fs_part_3 = button_element
            if i % 15 == 0 then
                x_offset2 = x_offset2 + 1
                y_pos2 = 1
            else
                y_pos2 = y_pos2 + 0.78
            end
        end

        -- the text info for the main topic
        if help_subtopic == "" then
            debug(flag2, "  no existing subtopic selected")
            fs_part_4 = table.concat({
                "hypertext[12.25,0.8;9.3,9;topic_text;",
                "<style color=#AAAAAA size=16>", TOPIC_TEXTS[help_topic], "</style>]"
            })

        else
            debug(flag2, "  existing help subtopic: " .. help_subtopic)
            local text = SUBTOPIC_TEXTS[help_topic .. " " .. help_subtopic]
            --debug(flag2, "  text: " .. text)

            fs_part_4 = table.concat({
                "hypertext[12.25,0.2;4,1.5;help_text;",
                "<style color=#777777 size=16><b>subtopic: </b></style>",
                "<style color=#AAAAAA size=16><b>", help_subtopic, "</b></style>]",

                -- the text info for the subtopic
                "hypertext[12.25,0.8;9.3,9;help_text;",
                "<style color=#AAAAAA size=16>", text, "</style>]",
            })

        end

    end

    formspec = fs_part_1 .. fs_part_2 .. fs_part_3 .. fs_part_4

    debug(flag2, "get_fs_help() END")
    return formspec
end


local flag1 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() HELP.lua")
	--debug(flag1, "  fields: " .. dump(fields))
    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
    debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag1, "  active_tab: " .. p_data.active_tab)


    if fields.inv_tabs == "6" then
        debug(flag1, "  clicked on 'HELP' tab!")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "help"
        local formspec = get_fs_help(p_data)
        mt_show_formspec(player_name, "ss:ui_help", formspec)

    else
        debug(flag1, "  did not click on HELP tab")
        if p_data.formspec_mode ~= "main_formspec" then
            debug(flag1, "  interaction not from main formspec. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif p_data.active_tab ~= "help" then
            debug(flag1, "  interaction from main formspec, but not HELP tab. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "2"
            or fields.inv_tabs == "3"
            or fields.inv_tabs == "4"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "7" then
            debug(flag1, "  clicked on a tab other than HELP. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.quit then
            debug(flag1, "  exited formspec. NO FURTHER ACTION.")
            p_data.active_tab = "main"
            local player_meta = player:get_meta()
            player_meta:set_string("help_topic", p_data.help_topic)
            player_meta:set_string("help_subtopic", p_data.help_subtopic)
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        else
            debug(flag1, "  clicked on a HELP formspec element")
        end

        local button_type
        local button_value
        for k, v in pairs(fields) do
            button_type = k
            button_value = v
        end
        debug(flag1, "  button_type: " .. button_type)

        --if button_type == "topic" then
        if string.sub(button_type, 1, 5) == "topic" then
            play_sound("button", {player_name = player_name})
            p_data.help_topic = button_value
            p_data.help_subtopic = ""
            debug(flag1, "  topic changed to: " .. button_value)

        --elseif button_type == "subtopic" then
        elseif string.sub(button_type, 1, 8) == "subtopic" then
            play_sound("button", {player_name = player_name})
            p_data.help_subtopic = button_value
            debug(flag1, "  subtopic changed to: " .. button_value)

        else
            debug(flag1, "  ERROR - Unexpected 'button_type' value: " .. button_type)
        end

        local formspec = get_fs_help(p_data)
        mt_show_formspec(player_name, "ss:ui_help", formspec)

    end

    debug(flag1, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)