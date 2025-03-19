print("- loading equipment_buffs.lua")

-- cache global functions for faster access
local table_concat = table.concat
local table_insert = table.insert
local string_split = string.split
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local mt_serialize = core.serialize
local debug = ss.debug
local play_sound = ss.play_sound
local get_fs_equipment_buffs = ss.get_fs_equipment_buffs
local build_fs = ss.build_fs

-- cache global variables for faster access
local ITEM_TOOLTIP = ss.ITEM_TOOLTIP
local player_data = ss.player_data


local flag6 = false
local function get_equip_buff_item_elements(p_data, buff_type, subtable_name, buff_unit_symbol)
    debug(flag6, "get_equip_buff_item_elements()")

    local tokenized_data = string_split(p_data[subtable_name], " ")
	debug(flag6, "  tokenized_data: " .. dump(tokenized_data))
    local tokenized_buff_data = string_split(tokenized_data[3], ",")
    debug(flag6, "  tokenized_buff_data: " .. dump(tokenized_buff_data))
	local item_name = tokenized_data[1]
	debug(flag6, "  item_name: " .. item_name)

    local fs_elements = ""

    debug(flag6, "  analyzing each buff data..")
    for i, buff_data in ipairs(tokenized_buff_data) do
        local t_data = string_split(buff_data, "=")
        debug(flag6, "    checking " .. t_data[1])
        if buff_type == t_data[1] then
            local pos_index = p_data.equip_buff_item_index
            local x_pos
            local multiplier = pos_index / 2
            if pos_index % 2 == 0 then
                x_pos = 3.6
                multiplier = multiplier - 1
            else
                x_pos = 0.7
                multiplier = multiplier - 0.5
            end

            local y_pos = 2.7
            local y_inc = 0.96 * multiplier

            fs_elements = table_concat({
                "image[", x_pos, ",", y_pos + y_inc, ";1.0,1.0;", tokenized_data[2], "]",
				"tooltip[", x_pos, ",", y_pos + y_inc, ";1.4,0.7;", ITEM_TOOLTIP[item_name], "]",
                "hypertext[", x_pos + 1.2, ",", y_pos + 0.2 + y_inc, ";2,1;dummy_item;",
                "<style color=#cccccc size=22><b>", t_data[2], "</b></style>",
                "<style color=#888888 size=20><b>", buff_unit_symbol, "</b></style>]",
            })
            break
        end
    end

    debug(flag6, "get_equip_buff_item_elements() end")
    return fs_elements
end


local flag5 = false
local function show_equip_buff_details_window(player_name, p_data, buff_type, buff_label, buff_description, buff_unit_symbol)
	debug(flag5, "show_equip_buff_details_window()")

	local equip_buff_items = {}
	p_data.equip_buff_item_index = 1

	p_data.viewing_equipbuff_window = true

	if p_data.equipped_clothing_eyes ~= "" then
		debug(flag5, "clothing eyes slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_eyes", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_clothing_neck ~= "" then
		debug(flag5, "clothing neck slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_neck", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_clothing_chest ~= "" then
		debug(flag5, "clothing chest slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_chest", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_clothing_hands ~= "" then
		debug(flag5, "clothing hands slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_hands", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

		if p_data.equipped_clothing_legs ~= "" then
		debug(flag5, "clothing legs slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_legs", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_clothing_feet ~= "" then
		debug(flag5, "clothing feet slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_feet", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_head ~= "" then
		debug(flag5, "armor head slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_head", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_face ~= "" then
		debug(flag5, "armor face slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_face", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_chest ~= "" then
		debug(flag5, "armor chest slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_chest", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_arms ~= "" then
		debug(flag5, "armor arms slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_arms", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_legs ~= "" then
		debug(flag5, "armor legs slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_legs", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_feet ~= "" then
		debug(flag5, "armor feet slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_feet", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	local equip_buff_items_elements
	local equip_buff_items_count = #equip_buff_items
	debug(flag5, "equip_buff_items_count: " .. equip_buff_items_count)
	if equip_buff_items_count == 0 then
		equip_buff_items_elements = table_concat({
			"hypertext[2.3,5.0;5,2;no_items_description;",
			"<style color=#404040 size=24><b>(no items)</b></style>]",
		})
	else
		equip_buff_items_elements = table_concat(equip_buff_items)
	end

	local formspec = table_concat({
		"formspec_version[7]",
		"size[7.0,11.0,true]",
		"position[0.0,0.40]",
		"image[0.5,0.2;1.0,1.0;ss_ui_equip_buffs_", buff_type, "2.png]",

		"hypertext[1.8,0.5;6,1;buff_label;",
		"<style color=#ffffff size=20><b>", buff_label, "</b></style>]",

		"hypertext[0.4,1.4;6,2;buff_description;",
		"<style color=#aaaaaa size=18>", buff_description, "</style>]",

		"box[0.4,2.6;6.0,6.0;#111111]",

		equip_buff_items_elements,

		"hypertext[2.2,9.0;5,2;buff_total;",
		"<style color=#cccccc size=24><b>Total: ", p_data["equip_buff_" .. buff_type], "</b></style>",
		"<style color=#888888 size=22><b>", buff_unit_symbol, "</b></style>]",
		"button_exit[2.0,9.7;3,1;equipbuff_exit;BACK]"
	})
	mt_show_formspec(player_name, "ss:equip_buffs", formspec)

	debug(flag5, "show_equip_buff_details_window() end")
end



local flag7 = false
core.register_on_joinplayer(function(player)
	debug(flag7, "\nregister_on_joinplayer() equipment_buffs.lua")
	local player_name = player:get_player_name()
    local p_data = player_data[player_name]
	p_data.equipbuffs_changed = false
	debug(flag7, "\nregister_on_joinplayer() END *** " .. mt_get_gametime() .. " ***")
end)



local flag2 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag2, "\nregister_on_player_receive_fields() EQUIP_BUFFS")
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]
	debug(flag2, "  p_data.formspec_mode: " .. p_data.formspec_mode)
	debug(flag2, "  active_tab: " .. p_data.active_tab)
	debug(flag2, "  formname: " .. formname)
	debug(flag2, "  equipbuffs_changed: " .. dump(p_data.equipbuffs_changed))
	--debug(flag2, "  fields: " .. dump(fields))

	if fields.equipbuff_exit then
		debug(flag2, "  clicked on BACK button from equip buff window")

		play_sound("button", {player_name = player_name})
		mt_show_formspec(player_name, "ss:ui_main", player:get_inventory_formspec())
		p_data.viewing_equipbuff_window = false
		debug(flag2, "register_on_player_receive_fields() END *** " .. mt_get_gametime() .. " ***")
		return

	elseif fields.quit then
		debug(flag2, "  exitted by clicking away from window or pressing ESC")

		local fs = player_data[player_name].fs
		if p_data.viewing_equipbuff_window then
			debug(flag2, "  quit from equip buff window")
			debug(flag2, "  showing main inv formspec, not refreshed")
			mt_show_formspec(player_name, "ss:ui_main", build_fs(fs))
			p_data.viewing_equipbuff_window = false

		elseif p_data.equipbuffs_changed then
			debug(flag2, "  equip buff values were modified. resetting colorization..")
			fs.left.equipment_stats = get_fs_equipment_buffs(player_name)
			local formspec = build_fs(fs)
			player:set_inventory_formspec(formspec)
			local player_meta = player:get_meta()
			player_meta:set_string("fs", mt_serialize(fs))
			p_data.equipbuffs_changed = false

		else
			debug(flag2, "  was not viewing equip buffs window nor had any buff values changed")
		end

		debug(flag2, "register_on_player_receive_fields() END *** " .. mt_get_gametime() .. " ***")
		return

	elseif p_data.active_tab ~= "main" then
		debug(flag2, "  clicked onto another tab away from Main")

		if formname ~= "ss:ui_main" then
			debug(flag2, "  interaction not from main formspec. NO FURTHER ACTION.")
			debug(flag2, "register_on_player_receive_fields() end " .. mt_get_gametime())
        	return

		elseif p_data.equipbuffs_changed then
			debug(flag2, "  equip buff values were modified. resetting colorization..")
			local fs = player_data[player_name].fs
			fs.left.equipment_stats = get_fs_equipment_buffs(player_name)
			local formspec = build_fs(fs)
			player:set_inventory_formspec(formspec)
			local player_meta = player:get_meta()
			player_meta:set_string("fs", mt_serialize(fs))
			p_data.equipbuffs_changed = false
		else
			debug(flag2, "  no equip buff values were modified")
		end

	else
		debug(flag2, "  did not exit formspec. inspecting fields..")
	end


	local field_name
    for key, value in pairs(fields) do
        if key == "enScrollbar_crafting" then
            field_name = key
        else
            field_name = key
            break
        end
    end
    debug(flag2, "  field_name: " .. field_name)

    local field_tokens = string_split(field_name, "_")
    local field_type = field_tokens[1]
	debug(flag2, "  field_type: " .. field_type)
	if field_type ~= "equipbuff" then
        debug(flag2, "  did not click on an Equip Buff button. NO FURTHER ACTION.")
		debug(flag2, "register_on_player_receive_fields() END *** " .. mt_get_gametime() .. " ***")
		return
	end

	debug(flag2, "  clicked on an Equip Buff button..")

	if fields.equipbuff_damage then
		debug(flag2, "  click on Damage buff button")
		local buff_description = "Resistance from physical damage, like attacks and falls."
		show_equip_buff_details_window(player_name, p_data, "damage", "Damage Protection", buff_description, "%")

	elseif fields.equipbuff_cold then
		debug(flag2, "  clicked on Cold buff button")
		local buff_description = "Resistance from cold environments and hypothermia."
		show_equip_buff_details_window(player_name,  p_data, "cold", "Cold Protection", buff_description, "%")

	elseif fields.equipbuff_heat then
		debug(flag2, "  clicked on Heat buff button")
		local buff_description = "Restistance from hot environments and heat stroke."
		show_equip_buff_details_window(player_name,  p_data, "heat", "Heat Protection", buff_description, "%")

	elseif fields.equipbuff_wetness then
		debug(flag2, "  clicked on Wetness buff button")
		local buff_description = "Resistance from getting wet from rain or from wet envronments."
		show_equip_buff_details_window(player_name,  p_data, "wetness", "Wetness Protection", buff_description, "%")

	elseif fields.equipbuff_disease then
		debug(flag2, "  clicked on Disease buff button")
		local buff_description = "Resistance from airborne disease like bacteria, viruses, and mold."
		show_equip_buff_details_window(player_name,  p_data, "disease", "Disease Protection", buff_description, "%")

	elseif fields.equipbuff_radiation then
		debug(flag2, "  clicked on Radiation buff button")
		local buff_description = "Resistance from radioactive materials or environments."
		show_equip_buff_details_window(player_name,  p_data, "radiation", "Radiation Protection", buff_description, "%")

	elseif fields.equipbuff_noise then
		debug(flag2, "  clicked on Noise buff button")
		local buff_description = "The amount of noise caused by all equipped clothing and armor."
		show_equip_buff_details_window(player_name,  p_data, "noise", "Noise Level", buff_description, "dB")

	elseif fields.equipbuff_weight then
		debug(flag2, "  clicked on Weight buff button")
		local buff_description = "The total weight from all equipped clothing and armor."
		show_equip_buff_details_window(player_name,  p_data, "weight", "Weight Total", buff_description, "")

	end

    debug(flag2, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)
