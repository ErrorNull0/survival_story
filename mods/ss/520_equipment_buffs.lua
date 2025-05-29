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
local EQUIPMENT_BUFFS = ss.EQUIPMENT_BUFFS
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local player_data = ss.player_data


local flag6 = false
local function get_equip_buff_item_elements(p_data, buff_type, subtable_name, buff_unit_symbol)
    debug(flag6, "  get_equip_buff_item_elements()")

    local tokenized_data = string_split(p_data[subtable_name], " ")
	debug(flag6, "    tokenized_data: " .. dump(tokenized_data))
	local item_name = tokenized_data[1]
	debug(flag6, "    item_name: " .. item_name)

	local equip_buff_data = EQUIPMENT_BUFFS[item_name]
	debug(flag6, "    equip_buff_data: " .. dump(equip_buff_data))
    local fs_elements = ""

    debug(flag6, "    buff_type: " .. buff_type)
	local buff_value
	if buff_type == "weight" then
		buff_value = ITEM_WEIGHTS[item_name]
	else
		buff_value = equip_buff_data[buff_type]
	end

	if buff_value ~= 0 then
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

		local sign = ""
		if buff_type == "cold" or buff_type == "heat" or buff_type == "water" then
			if buff_value > 0 then sign = "+" end
		end
		fs_elements = table_concat({
			"image[", x_pos, ",", y_pos + y_inc, ";1.0,1.0;", tokenized_data[2], "]",
			"tooltip[", x_pos, ",", y_pos + y_inc, ";1.4,0.7;", ITEM_TOOLTIP[item_name], "]",
			"hypertext[", x_pos + 1.2, ",", y_pos + 0.2 + y_inc, ";2,1;dummy_item;",
			"<style color=#cccccc size=22><b>", sign, buff_value, "</b></style>",
			"<style color=#888888 size=20><b>", buff_unit_symbol, "</b></style>]",
		})

	else
		debug(flag6, "      this buff is zero. skipping..")
	end

    debug(flag6, "  get_equip_buff_item_elements() end")
    return fs_elements
end


local flag5 = false
local function show_equip_buff_details_window(player_name, p_data, buff_type, buff_label, buff_description, buff_unit_symbol)
	debug(flag5, "show_equip_buff_details_window()")

	local equip_buff_items = {}
	p_data.equip_buff_item_index = 1

	p_data.viewing_equipbuff_window = true

	if p_data.equipped_clothing_eyes ~= "" then
		debug(flag5, "  clothing eyes slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_eyes", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_clothing_neck ~= "" then
		debug(flag5, "  clothing neck slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_neck", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_clothing_chest ~= "" then
		debug(flag5, "  clothing chest slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_chest", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_clothing_hands ~= "" then
		debug(flag5, "  clothing hands slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_hands", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

		if p_data.equipped_clothing_legs ~= "" then
		debug(flag5, "  clothing legs slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_legs", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_clothing_feet ~= "" then
		debug(flag5, "  clothing feet slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_clothing_feet", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_head ~= "" then
		debug(flag5, "  armor head slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_head", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_face ~= "" then
		debug(flag5, "  armor face slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_face", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_chest ~= "" then
		debug(flag5, "  armor chest slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_chest", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_arms ~= "" then
		debug(flag5, "  armor arms slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_arms", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_legs ~= "" then
		debug(flag5, "  armor legs slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_legs", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	if p_data.equipped_armor_feet ~= "" then
		debug(flag5, "  armor feet slot equipped")
		local fs_elements = get_equip_buff_item_elements(p_data, buff_type, "equipped_armor_feet", buff_unit_symbol)
		if fs_elements ~= "" then
			table_insert(equip_buff_items, fs_elements)
			p_data.equip_buff_item_index = p_data.equip_buff_item_index + 1
		end
	end

	local equip_buff_items_elements
	local equip_buff_items_count = #equip_buff_items
	debug(flag5, "  equip_buff_items_count: " .. equip_buff_items_count)
	if equip_buff_items_count == 0 then
		equip_buff_items_elements = table_concat({
			"hypertext[2.3,5.0;5,2;no_items_description;",
			"<style color=#404040 size=24><b>(no items)</b></style>]",
		})
	else
		equip_buff_items_elements = table_concat(equip_buff_items)
	end

	local equipbuff_value = p_data["equip_buff_" .. buff_type]
	local sign = ""
	if buff_type == "cold" or buff_type == "heat" or buff_type == "water" then
		if equipbuff_value > 0 then sign = "+" end
	end
	local formspec = table_concat({
		"formspec_version[7]",
		"size[7.0,11.0,true]",
		"position[0.0,0.40]",
		"image[0.5,0.2;1.0,1.0;ss_ui_equip_buffs_", buff_type, ".png]",

		"hypertext[1.8,0.5;6,1;buff_label;",
		"<style color=#ffffff size=20><b>", buff_label, "</b></style>]",

		"hypertext[0.4,1.4;6,2;buff_description;",
		"<style color=#aaaaaa size=18>", buff_description, "</style>]",

		"box[0.4,2.6;6.0,6.0;#111111]",

		equip_buff_items_elements,

		"hypertext[2.2,9.0;5,2;buff_total;",
		"<style color=#cccccc size=24><b>Total: ", sign, equipbuff_value, "</b></style>",
		"<style color=#888888 size=22><b>", buff_unit_symbol, "</b></style>]",
		"button_exit[2.0,9.7;3,1;equipbuff_exit;BACK]"
	})
	mt_show_formspec(player_name, "ss:equip_buffs", formspec)

	debug(flag5, "show_equip_buff_details_window() end")
end



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
		local buff_description = "Resistance from physical damage, like attacks and projectiles."
		show_equip_buff_details_window(player_name, p_data, "damage", "Damage Protection", buff_description, "%")

	elseif fields.equipbuff_cold then
		debug(flag2, "  clicked on Cold buff button")
		local units = "°F"
		if p_data.thermal_units == 2 then units = "°C" end
		local buff_description = "Resistance to cold temperatures."
		show_equip_buff_details_window(player_name,  p_data, "cold", "Cold Weather Factor", buff_description, units)

	elseif fields.equipbuff_heat then
		debug(flag2, "  clicked on Heat buff button")
		local units = "°F"
		if p_data.thermal_units == 2 then units = "°C" end
		local buff_description = "Resistance to hot temperatures."
		show_equip_buff_details_window(player_name,  p_data, "heat", "Hot Weather Factor", buff_description, units)

	elseif fields.equipbuff_wetness then
		debug(flag2, "  clicked on Wetness buff button")
		local buff_description = "Resistant to moisture like rain but not partial or full submersion in water."
		show_equip_buff_details_window(player_name,  p_data, "wetness", "Wetness Protection", buff_description, "%")

	elseif fields.equipbuff_water then
		debug(flag2, "  clicked on Water buff button")
		local units = "°F"
		if p_data.thermal_units == 2 then units = "°C" end
		local buff_description = "Resistance to cold water temperatures."
		show_equip_buff_details_window(player_name,  p_data, "water", "Water Temperature Factor", buff_description, units)

	elseif fields.equipbuff_sun then
		debug(flag2, "  clicked on Sun buff button")
		local buff_description = "Resistance to harmful effects from sun exposure."
		show_equip_buff_details_window(player_name,  p_data, "sun", "Sun Protection", buff_description, "%")

	elseif fields.equipbuff_disease then
		debug(flag2, "  clicked on Disease buff button")
		local buff_description = "Resistance from airborne disease like bacteria, viruses, mold, and parasites."
		show_equip_buff_details_window(player_name,  p_data, "disease", "Disease Protection", buff_description, "%")

	elseif fields.equipbuff_electrical then
		debug(flag2, "  clicked on Electrical buff button")
		local buff_description = "Resistance from electric shock or electrocution."
		show_equip_buff_details_window(player_name,  p_data, "electrical", "Electrical Protection", buff_description, "%")

	elseif fields.equipbuff_radiation then
		debug(flag2, "  clicked on Radiation buff button")
		local buff_description = "Resistance from radioactive materials or environments."
		show_equip_buff_details_window(player_name,  p_data, "radiation", "Radiation Protection", buff_description, "%")

	elseif fields.equipbuff_gas then
		debug(flag2, "  clicked on Gas buff button")
		local buff_description = "Resistance from poisonous gas or fumes."
		show_equip_buff_details_window(player_name,  p_data, "gas", "Gas Protection", buff_description, "%")

	elseif fields.equipbuff_noise then
		debug(flag2, "  clicked on Noise buff button")
		local buff_description = "The amount of noise caused by all equipped clothing and armor."
		show_equip_buff_details_window(player_name,  p_data, "noise", "Noise Level", buff_description, "dB")

	elseif fields.equipbuff_weight then
		debug(flag2, "  clicked on Weight buff button")
		local buff_description = "The total weight from equipped clothing and armor."
		show_equip_buff_details_window(player_name,  p_data, "weight", "Weight Total", buff_description, "")

	end

    debug(flag2, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)



local flag7 = false
core.register_on_joinplayer(function(player)
	debug(flag7, "\nregister_on_joinplayer() EQUIPMENT BUFFS")
	local player_name = player:get_player_name()
    local p_data = player_data[player_name]

	-- whether or not player is viewing the equipment buff details window
    p_data.viewing_equipbuff_window = false

	p_data.equipbuffs_changed = false
	debug(flag7, "\nregister_on_joinplayer() END *** " .. mt_get_gametime() .. " ***")
end)


local flag1 = false
core.register_on_dieplayer(function(player)
    debug(flag1, "\nregister_on_dieplayer() EQUIPMENT BUFFS")
    local p_data = player_data[player:get_player_name()]
	p_data.viewing_equipbuff_window = false
	debug(flag1, "register_on_dieplayer() END")
end)


local flag3 = false
core.register_on_respawnplayer(function(player)
    debug(flag3, "\nregister_on_respawnplayer() global_variables_init.lua")
	local p_data = player_data[player:get_player_name()]
	p_data.viewing_equipbuff_window = false
	debug(flag3, "register_on_respawnplayer() END")
end)