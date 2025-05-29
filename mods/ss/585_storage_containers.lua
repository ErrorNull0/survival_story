print("- loading storage_containers.lua")

-- cache global functions for faster access
local math_random = math.random
local table_concat = table.concat
local table_insert = table.insert
local string_format = string.format
local mt_show_formspec = core.show_formspec
local mt_add_item = core.add_item
local mt_get_node = core.get_node
local mt_remove_node = core.remove_node
local mt_get_meta = core.get_meta
local mt_serialize = core.serialize
local mt_get_gametime = core.get_gametime
local mt_pos_to_string = core.pos_to_string
local debug = ss.debug
local round = ss.round
local pos_to_key = ss.pos_to_key
local key_to_pos = ss.key_to_pos
local notify = ss.notify
local play_sound = ss.play_sound
local get_itemstack_weight = ss.get_itemstack_weight
local get_fs_weight = ss.get_fs_weight
local update_crafting_ingred_and_grid = ss.update_crafting_ingred_and_grid
local build_fs = ss.build_fs
local exceeds_inv_weight_max = ss.exceeds_inv_weight_max
local do_stat_update_action = ss.do_stat_update_action
local drop_all_items = ss.drop_all_items
local remove_formspec_viewer = ss.remove_formspec_viewer
local remove_formspec_all_viewers = ss.remove_formspec_all_viewers
local is_variable_height_node_supportive = ss.is_variable_height_node_supportive
local update_fs_weight = ss.update_fs_weight
local refresh_meta_and_description = ss.refresh_meta_and_description
local player_control_fix = ss.player_control_fix

-- cache global variables for faster access
local SLOT_COLOR_BG = ss.SLOT_COLOR_BG
local SLOT_COLOR_HOVER = ss.SLOT_COLOR_HOVER
local SLOT_COLOR_BORDER = ss.SLOT_COLOR_BORDER
local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local SPILLABLE_ITEM_NAMES = ss.SPILLABLE_ITEM_NAMES
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local WEAR_VALUE_MAX = ss.WEAR_VALUE_MAX
local NOTIFICATIONS = ss.NOTIFICATIONS
local NOTIFY_DURATION = ss.NOTIFY_DURATION
local NODE_NAMES_SOLID_CUBE = ss.NODE_NAMES_SOLID_CUBE
local NODE_NAMES_SOLID_VARIABLE_HEIGHT = ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT
local formspec_viewers = ss.formspec_viewers
local player_data = ss.player_data

local BAG_SLOT_ROW_COUNT = {
	["ss:bag_fiber_small"] = 1,
	["ss:bag_fiber_medium"] = 2,
	["ss:bag_fiber_large"] = 3,
	["ss:bag_cloth_small"] = 1,
	["ss:bag_cloth_medium"] = 2,
	["ss:bag_cloth_large"] = 3
}

BAG_WEIGHT_MAX = {
	["ss:bag_fiber_small"] = 100,
	["ss:bag_fiber_medium"] = 200,
	["ss:bag_fiber_large"] = 300,
	["ss:bag_cloth_small"] = 125,
	["ss:bag_cloth_medium"] = 250,
	["ss:bag_cloth_large"] = 375
}

local flag4 = false
-- returns all formspec elements that displays the storage UI.
local function get_fs_storage(player, pos)
	debug(flag4, "\n    get_fs_storage()")
	debug(flag4, "      pos: " .. mt_pos_to_string(pos))
	local player_meta = player:get_meta()
	local storage_node = mt_get_node(pos)
	local node_meta = mt_get_meta(pos)
	local pos_string = string_format("%.2f,%.2f,%.2f", pos.x, pos.y, pos.z)

	debug(flag4, "      node name: " .. storage_node.name)

	local formspec = ""
	local fs_output = {}

	-- get player inventory weight
	local curr_weight = player_meta:get_float("weight_current")
    local max_weight = player_meta:get_float("weight_max")
    curr_weight = round(curr_weight, 2)

	-- get storage weight
	local weight_current = node_meta:get_float("weight_current")
	local weight_max = node_meta:get_float("weight_max")
	debug(flag4, "      weight_current: " .. weight_current)
	debug(flag4, "      weight_max: " .. weight_max)
	weight_current = round(weight_current, 2)

	-- get storage item condition and determine weight icon texture
	local condition = node_meta:get_float("condition")
	debug(flag4, "      condition: " .. condition)
	if condition == 0 then
		debug(flag4, "      this is an unused storage item. condition intialized to: " .. WEAR_VALUE_MAX)
		condition = WEAR_VALUE_MAX
	end
	local condition_percentage = round(condition / WEAR_VALUE_MAX * 100, 1)
	debug(flag4, "      condition_percentage: " .. condition_percentage)

	local condition_icon, condition_color
	if condition_percentage > 75 then
		condition_icon = "ss_ui_storage_condition_bag_1.png"
		condition_color = "#999999"
	elseif condition_percentage <= 75 and condition_percentage > 50 then
		condition_icon = "ss_ui_storage_condition_bag_2.png"
		condition_color = "#99995f"
	elseif condition_percentage <= 50 and condition_percentage > 25 then
		condition_icon = "ss_ui_storage_condition_bag_3.png"
		condition_color = "#a89354"
	elseif condition_percentage <= 25 then
		condition_icon = "ss_ui_storage_condition_bag_4.png"
		condition_color = "#994c4c"
	end

	local inventory_elements = table_concat({

		-- core formspec properties for storage UI
		"formspec_version[7]",
		"size[16.2,7.7,true]",
		"position[0.5,0.4]",
		"listcolors[",
			SLOT_COLOR_BG, ";",
			SLOT_COLOR_HOVER, ";",
			SLOT_COLOR_BORDER, ";",
			TOOLTIP_COLOR_BG, ";",
			TOOLTIP_COLOR_TEXT, "]",

		-- hotbar background
		"box[0.2,0.2;1,1;#000000]",
		"box[1.3,0.2;1,1;#000000]",
		"box[2.4,0.2;1,1;#000000]",
		"box[3.5,0.2;1,1;#000000]",
		"box[4.6,0.2;1,1;#000000]",
		"box[5.7,0.2;1,1;#000000]",
		"box[6.8,0.2;1,1;#000000]",
		"box[7.9,0.2;1,1;#000000]",

		-- hotbar and main inventory slots
		"style_type[list;spacing=0.1,0.1]",
		"list[current_player;main;0.2,0.2;8,1;]",
		"list[current_player;main;0.2,1.3;8,6;8]",

		-- inventory weight display
		"image[0.2,6.95;0.6,0.6;ss_ui_iteminfo_attrib_weight.png;]",
		"hypertext[0.9,7.15;4.0,2;inventory_weight;<b>",
		"<style color=#999999 size=16>", curr_weight, "</style>",
			"<style color=#666666 size=16> / ", max_weight, "</style>",
		"</b>]",
		"tooltip[0.2,7.0;2.4,0.5;inventory weight (current / max)]",

		-- dark gray background box behind storage slots
		"box[9.1,0.0;7.1,8.0;#181818]",

		-- storage slots
		"style_type[list;spacing=0.1,0.1]",
		"list[nodemeta:", pos_string, ";items;9.4,0.2;6," .. BAG_SLOT_ROW_COUNT[storage_node.name] .. ";]",
		"listring[nodemeta:", pos_string, ";items]",
		"listring[current_player;main]",

		-- storage condition display
		"image[11.6,6.9;0.6,0.6;" .. condition_icon .. ";]",
		"hypertext[12.3,7.15;4.0,2;storage_condition;<b>",
			"<style color=" .. condition_color .. " size=16>", condition_percentage, "%</style>",
		"</b>]",
		"tooltip[11.8,7.0;2.1,0.5;storage condition]",

		-- storage weight values display
		"image[13.5,6.9;0.6,0.6;ss_ui_iteminfo_attrib_weight.png;]",
		"hypertext[14.2,7.15;4.0,2;storage_weight;<b>",
			"<style color=#999999 size=16>", weight_current, "</style>",
			"<style color=#666666 size=16> / ", weight_max, "</style>",
		"</b>]",
		"tooltip[13.5,7.0;2.1,0.5;storage weight (current / max)]"

	})
	table_insert(fs_output, inventory_elements)

	-- combine all formspec elements
	formspec = table_concat(fs_output)

	debug(flag4, "    get_fs_storage() end *** " .. mt_get_gametime() .. " ***")
	return formspec
end


local flag13 = false
local function update_weight_dislay(player, player_meta, p_data, fs, weight_change)
	debug(flag13, "  update_weight_dislay()")
	debug(flag13, "    weight_change: " .. weight_change)

	-- update HUD vertical stat bars
	do_stat_update_action(player, p_data, player_meta, "normal", "weight", weight_change, "curr", "add", true)

	-- update formspec weight values
	fs.center.weight = get_fs_weight(player)
	player_meta:set_string("fs", mt_serialize(fs))
	local formspec = build_fs(fs)
	player:set_inventory_formspec(formspec)

	local pos = key_to_pos(p_data.storage_pos_key)
	formspec = get_fs_storage(player, pos)
	mt_show_formspec(player:get_player_name(), "ss:ui_storage", formspec)
	debug(flag13, "  update_weight_dislay() END")
end


local flag14 = false
-- Decrease the 'condition' of the storage item node. If it drops to zero, the item
-- node is destroyed and any contents drop to the ground. This function is typically
-- called when item node receives wear by the item being dug, or while player moves
-- items in and out of the item node inventory.
--- @param node_meta NodeMetaRef the storage node's metadata
--- @param item_weight number total weight of the itemstack
local function decrease_storage_condition(player, pos, node_meta, item_weight)
	debug(flag14, "  decrease_storage_condition()")

		-- decrease storage condition
		local condition = node_meta:get_float("condition")
		debug(flag14, "    condition: " .. condition)
		if condition == 0 then
			debug(flag14, "    this is an unsued storage item. condition set to: " .. WEAR_VALUE_MAX)
			condition = WEAR_VALUE_MAX
		end
		local wear = item_weight * 10
		debug(flag14, "    wear: " .. wear)
		local random_modifier = wear * math_random(-15,15) * 0.01
		debug(flag14, "    random_modifier: " .. random_modifier)
		wear = wear + random_modifier
		debug(flag14, "    wear + random_modifier: " .. wear)

		local new_condition = condition - wear
		debug(flag14, "    new_condition: " .. new_condition)
		node_meta:set_float("condition", new_condition)

		if new_condition > 0 then
			debug(flag14, "    storage is still usable")

			-- refresh formspec for all viewers --
			local pos_key = pos_to_key(pos)
			for i, viewer_name in ipairs(formspec_viewers[pos_key]) do
				debug(flag14, "    refreshing formspec for: " .. viewer_name)
				local formspec = get_fs_storage(player, pos)
				mt_show_formspec(viewer_name, "ss:ui_storage", formspec)
			end
		else
			debug(flag14, "    storage is worn out")
			node_meta:set_float("condition", -1)
			mt_remove_node(pos)
		end

	debug(flag14, "  decrease_storage_condition() END")
end


local flag1 = false
local function storage_on_construct(pos)
	debug(flag1, "\nstorage_on_construct() STORAGE")

	local bottom_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
	local bottom_node = mt_get_node(bottom_pos)
	local bottom_node_name = bottom_node.name
	debug(flag1, "  bottom_node_name: " .. bottom_node_name)

	-- storage can only be placed on top of a solid/walkable node. but some solid nodes
	-- are not full height and have a gap above it. ensure storage cannot be placed
	-- above these nodes.
	local is_bottom_supportive
	if NODE_NAMES_SOLID_CUBE[bottom_node_name] then
		debug(flag1, "  bottom node is solid cube. ok to place")
		is_bottom_supportive = true
	elseif NODE_NAMES_SOLID_VARIABLE_HEIGHT[bottom_node_name] then
		debug(flag1, "  bottom node is variable height. inspecting further..")
		is_bottom_supportive = is_variable_height_node_supportive(bottom_node, bottom_node_name)
	else
		debug(flag1, "  node below is not a valid support")
		is_bottom_supportive = false
	end

	if is_bottom_supportive then
		debug(flag1, "  bag node spawned")
		local bag_node = mt_get_node(pos)
		local node_name = bag_node.name
		debug(flag1, "  node_name: " .. node_name)

		debug(flag1, "  initializing node metadata")
		local node_meta = mt_get_meta(pos)
		local weight_max = BAG_WEIGHT_MAX[node_name]
		node_meta:set_float("weight_current", 0)
		node_meta:set_float("weight_max", weight_max)

		debug(flag1, "  creating unique pos_key for this bag node")
		local pos_key = pos_to_key(pos)
		node_meta:set_string("pos_key", tostring(pos_key))
		debug(flag1, "  pos_key: " .. pos_key)

		debug(flag1, "  initializing node inventory lists")
		local node_inv = node_meta:get_inventory()
		node_inv:set_size("items", 36)

		-- initialize subtable in campfire_users table for this campfire node to
		-- track the players currently viewing this campfire's formspec/ui
		formspec_viewers[pos_key] = {}
	else

		debug(flag1, "  removing storage node from the world..")
		mt_remove_node(pos)
	end

	debug(flag1, "storage_on_construct() END ")
end



-- ensure that bag cannot be placed above a non-solid node. if placement is successful,
-- reduce the player's inventory weight.
local flag3 = false
local function storage_after_place_node(pos, player, item, pointed_thing)
    debug(flag3, "\nstorage_after_place_node()")
    --debug(flag12, "  pos: " .. mt_pos_to_string(pos))

    local node = mt_get_node(pos)
    local node_name = node.name
    debug(flag3, "  node_name: " .. node_name)

	if node_name == "air" then
		debug(flag3, "  storage bag placement was cancelled")
		notify(player, "inventory", "Area below is not solid or stable", 3, 0.5, 0, 3)
		debug(flag3, "storage_after_place_node() END")
		return true

	else
		debug(flag3, "  storage bag was placed successfully")

		debug(flag3, "  transfer 'condition' and 'heated' properties to node")
		local item_meta = item:get_meta()
		local condition = item_meta:get_float("condition")
		debug(flag3, "  condition: " .. condition)
		local heat_progress = item_meta:get_float("heat_progress")
		debug(flag3, "  heat_progress: " .. heat_progress)
		local node_meta = mt_get_meta(pos)
		node_meta:set_float("condition", condition)
		node_meta:set_float("heat_progress", heat_progress)

		debug(flag3, "  reducing inventory weight..")
        local player_meta = player:get_meta()
        local item_name = item:get_name()
        debug(flag3, "  item name: " .. item_name)
        local weight = ITEM_WEIGHTS[item_name]
        debug(flag3, "  weight: " .. weight)
		local p_data = ss.player_data[player:get_player_name()]
		do_stat_update_action(player, p_data, player_meta, "normal", "weight", -weight, "curr", "add", true)

        update_fs_weight(player, player_meta)
	end

    debug(flag3, "storage_after_place_node() END")
end



local flag2 = false
local function storage_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	debug(flag2, "\nstorage_on_rightclick()")

	local player_name = clicker:get_player_name()
	local p_data = player_data[player_name]
	local node_meta = mt_get_meta(pos)
	local pos_key = node_meta:get_string("pos_key")
	debug(flag2, "  pos_key: " .. pos_key)

	-- save hash of storage pos for use by register_on_player_receive_fields() and
	-- register_on_player_inventory_action()
	p_data.storage_pos_key = pos_key
	p_data.formspec_mode = "storage"

	-- show the storage formspec ui
	mt_show_formspec(player_name, "ss:ui_storage", get_fs_storage(clicker, pos))

	-- add the player's name to the formspec_viewers table to signify that the player
	-- is currently viewing/using this storage
	formspec_viewers[pos_key] = formspec_viewers[pos_key] or {}
	table_insert(formspec_viewers[pos_key], player_name)
	debug(flag2, "  formspec_viewers: " .. dump(formspec_viewers))

	-- workaround to ensure LMB/RMB player control input is released so that stamina
	-- doesn't keep draining for being in DIG/SWING state
	player_control_fix(clicker)

	play_sound("bag_open", {pos = pos})

	debug(flag2, "storage_on_rightclick() end *** " .. mt_get_gametime() .. " ***")
end


local flag10 = false
local function storage_allow_metadata_inventory_put(pos, listname, index, stack, player)
	debug(flag10, "\nstorage_allow_metadata_inventory_put()")
	local node_meta = mt_get_meta(pos)
	local node_inv = node_meta:get_inventory()
	local item_name = stack:get_name()
	local item_count = stack:get_count()
	local quantity_allowed = item_count

	debug(flag10, "  RECEIVED " .. item_name .. " into " .. listname .. "[" .. index .. "]")

	if SPILLABLE_ITEM_NAMES[item_name] then
		notify(player, "inventory", NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
		quantity_allowed = 0

	else
		-- check total weight of item stack and if it exceeds storage weight max,
		-- reduce the stack quantity until it's below the weight max
		local item_weight = get_itemstack_weight(stack)
		debug(flag10, "  item_weight: " .. item_weight)
		local storage_weight_current = node_meta:get_float("weight_current")
		debug(flag10, "  storage_weight_current: " .. storage_weight_current)
		local total_weight = item_weight + storage_weight_current
		debug(flag10, "  total_weight: " .. total_weight)
		local weight_max = node_meta:get_float("weight_max")
		debug(flag10, "  weight_max: " .. weight_max)

		if total_weight > weight_max then
			debug(flag10, "  storage weight exceeded")
			if item_count > 1 then
				local weight_overage = total_weight - weight_max
				debug(flag10, "  weight_overage: " .. weight_overage)
				local quantity_overage = math.ceil(weight_overage / ITEM_WEIGHTS[item_name])
				debug(flag10, "  quantity_overage: " .. quantity_overage)
				quantity_allowed = item_count - quantity_overage
				debug(flag10, "  quantity_allowed: " .. quantity_allowed)
				if quantity_allowed > 0 then
					notify(player, "inventory", "Weight exceeded - only " .. quantity_allowed .. " could be moved", NOTIFY_DURATION, 0.5, 0, 3)
				else
					notify(player, "inventory", "Exceeded storage weight", NOTIFY_DURATION, 0, 0.5, 2)
				end

			else
				debug(flag10, "  new item exceeds storage weight")
				notify(player, "inventory", "Exceeded storage weight", NOTIFY_DURATION, 0, 0.5, 2)
				quantity_allowed = 0
			end
		end
	end

	debug(flag10, "storage_allow_metadata_inventory_put() END")
	return quantity_allowed
end


local flag11 = false
local function storage_on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	debug(flag11, "\nstorage_on_metadata_inventory_move()")
	debug(flag11, "  MOVED ")
	local node_meta = mt_get_meta(pos)
	local inventory = node_meta:get_inventory()
	local item = inventory:get_stack(to_list, to_index)
    local item_name = item:get_name()
	play_sound("item_move", {item_name = item_name, player_name = player:get_player_name()})
	debug(flag11, "storage_on_metadata_inventory_move() end *** " .. mt_get_gametime() .. " ***")
end


local flag11 = false
local function storage_on_metadata_inventory_put(pos, listname, index, stack, player)
	debug(flag11, "\nstorage_on_metadata_inventory_put()")
	debug(flag11, "  RECEIVED " .. stack:get_name() .. " into " .. listname .. "[" .. index .. "]")
	local node_meta = mt_get_meta(pos)

	-- increase storage weight value
	local item_weight = get_itemstack_weight(stack)
	debug(flag11, "  item_weight: " .. item_weight)
	local storage_weight_current = node_meta:get_float("weight_current")
	debug(flag11, "  storage_weight_current: " .. storage_weight_current)
	local total_weight = storage_weight_current + item_weight
	debug(flag11, "  total_weight: " .. total_weight)
	node_meta:set_float("weight_current", total_weight)
	decrease_storage_condition(player, pos, node_meta, item_weight)

	debug(flag11, "storage_on_metadata_inventory_put() end *** " .. mt_get_gametime() .. " ***")
end


local flag12 = false
local function storage_on_metadata_inventory_take(pos, listname, index, stack, player)
	debug(flag12, "\nstorage_on_metadata_inventory_take()")
	debug(flag12, "  REMOVED " .. stack:get_name() .. " from " .. listname .. "[" .. index .. "]")
	local node_meta = mt_get_meta(pos)
	play_sound("item_move", {item_name = stack:get_name(), player_name = player:get_player_name()})

	-- decrease storage weight
	local item_weight = get_itemstack_weight(stack)
	debug(flag11, "  item_weight: " .. item_weight)
	local storage_weight_current = node_meta:get_float("weight_current")
	debug(flag11, "  storage_weight_current: " .. storage_weight_current)
	local total_weight = storage_weight_current - item_weight
	debug(flag11, "  total_weight: " .. total_weight)
	node_meta:set_float("weight_current", total_weight)
	decrease_storage_condition(player, pos, node_meta, item_weight)

	debug(flag12, "storage_on_metadata_inventory_take() end *** " .. mt_get_gametime() .. " ***")
end


local flag7 = false
-- triggered only when items moved within player:get_inventory() object which is
-- also the 'inventory' parameter below
core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    debug(flag7, "\nregister_allow_player_inventory_action() STORAGE")
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

	if p_data.formspec_mode ~= "storage" then
		debug(flag7, "  not using storage. skip.")
		debug(flag7, "  register_allow_player_inventory_action() end *** "
			.. mt_get_gametime() .. " ***")
		return
	end

    local player_meta = player:get_meta()
    local block_action = false

	debug(flag7, "  action: " .. action)
    if action == "move" then

		local to_list = inventory_info.to_list
        local to_index = inventory_info.to_index
        local from_list = inventory_info.from_list
        local from_index = inventory_info.from_index
        local item = inventory:get_stack(from_list, from_index)
        local item_name = item:get_name()

        debug(flag7, "  item_name: " .. item_name)
        debug(flag7, "  to_list: " .. to_list)

		if to_list == "main" then
			debug(flag7, "  Moved any item to another slot within main inventory: Allowed")
			if SPILLABLE_ITEM_NAMES[item_name] then
                debug(flag2, "  this is a filled cup!")
                if to_index > 8 then
                    debug(flag2, "  cannot be placed in main inventory")
                    notify(player, "inventory", NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
                    block_action = true
                end
            end

		else

			debug(flag7, "  ERROR - Unexpected 'to_list' value: " .. to_list)
			block_action = true
		end

	elseif action == "take" then
        debug(flag7, "  Action TAKE not implemented.")

	elseif action == "put" then
		local listname = inventory_info.listname
        local item = inventory_info.stack
        local to_index = inventory_info.index
        local item_name = item:get_name()

        debug(flag7, "  PUT " .. item_name .. " into " .. listname .. " at index " .. to_index)

		-- main inventory grid
		if listname == "main" then
			debug(flag7, "  PUT any item to main inventory: ALLOWED")

			if SPILLABLE_ITEM_NAMES[item_name] then
				debug(flag7, "  this is a filled cup!")
				if to_index > 8 then
					debug(flag7, "  cannot be placed in main inventory")
					notify(player, "inventory", NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
					block_action = true
				else
					debug(flag7, "  placing into hotbar")
					if exceeds_inv_weight_max(item, player_meta) then
						notify(player, "inventory", NOTIFICATIONS.inv_weight_max, NOTIFY_DURATION, 0, 0.5, 3)
						block_action = true
					end
				end
			else
				debug(flag7, "  not a filled cup")
				if exceeds_inv_weight_max(item, player_meta) then
					notify(player, "inventory", NOTIFICATIONS.inv_weight_max, NOTIFY_DURATION, 0, 0.5, 3)
					block_action = true
				end
			end

		else
			debug(flag7, "  ERROR - Unexpected 'listname' value: " .. listname)
			block_action = true
		end

	else
        debug(flag7, "  UNEXPECTED ACTION: " .. action)
    end

    debug(flag7, "register_allow_player_inventory_action() end *** " .. mt_get_gametime() .. " ***")
	if block_action then return 0 end
end)


local flag8 = false
-- triggered only when items moved within player:get_inventory() object which is
-- also the 'inventory' parameter below
core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    debug(flag8, "\nregister_on_player_inventory_action() storage_containers.lua")
	local player_name = player:get_player_name()
    local p_data = player_data[player_name]

	if p_data.formspec_mode ~= "storage" then
		debug(flag8, "  not using storage. skip.")
		debug(flag8, "register_allow_player_inventory_action() end *** " .. mt_get_gametime() .. " ***")
		return
	end

	local player_meta = player:get_meta()
    local fs = player_data[player_name].fs

	if action == "move" then
		local to_list = inventory_info.to_list
		local to_index = inventory_info.to_index
		local item = inventory:get_stack(to_list, to_index)
		local item_name = item:get_name()
		debug(flag8, "  MOVED " .. item_name)
		play_sound("item_move", {item_name = item_name, player_name = player_name})

	elseif action == "take" then
		local item = inventory_info.stack
		local item_name = item:get_name()
		local listname = inventory_info.listname
        local from_index = inventory_info.index

        debug(flag8, "  listname: " .. listname)
        debug(flag8, table_concat({ "  >> * REMOVED * ", item_name, " from player inventory. Took from ", listname, "[", from_index, "]" }) )
		play_sound("item_move", {item_name = item_name, player_name = player_name})

		debug(flag8, "  formspec_mode: " .. p_data.formspec_mode)
		debug(flag8, "  Removed item while in storage")

		local weight = get_itemstack_weight(item)
		update_weight_dislay(player, player_meta, p_data, fs, -weight)
		update_crafting_ingred_and_grid(player_name, inventory, p_data, fs)
		player_meta:set_string("fs", mt_serialize(fs))
		player:set_inventory_formspec(build_fs(fs))

	elseif action == "put" then
		local item = inventory_info.stack
		local item_name = item:get_name()
		debug(flag8, "  PLACED " .. item_name)

		debug(flag8, "  formspec_mode: " .. p_data.formspec_mode)
		debug(flag8, "  Placed item into inventory while in storage")

		local weight = get_itemstack_weight(item)
		update_weight_dislay(player, player_meta, p_data, fs, weight)
		update_crafting_ingred_and_grid(player_name, inventory, p_data, fs)
		player_meta:set_string("fs", mt_serialize(fs))
		player:set_inventory_formspec(build_fs(fs))

	else
        debug(flag8, "  ERROR - Unimplemented 'action': " .. action)
    end

    debug(flag8, "register_on_player_inventory_action() end *** " .. mt_get_gametime() .. " ***")
end)


local flag9 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag9, "\nregister_on_player_receive_fields() STORAGE")
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]
	local pos_key = p_data.storage_pos_key

	debug(flag9, "  p_data.formspec_mode: " .. p_data.formspec_mode)
    if p_data.formspec_mode ~= "storage" then
        debug(flag9, "  interaction not from storage formspec. NO FURTHER ACTION.")
        debug(flag9, "register_on_player_receive_fields() end " .. mt_get_gametime())
        return
    else
        debug(flag9, "  interaction from campstoragefire formspec. inspecting fields..")
    end

	debug(flag9, "  fields: " .. dump(fields))

	if fields.quit then
        debug(flag9, "  player quit from storage formspec ui")
		p_data.formspec_mode = "main_formspec"

		debug(flag2, "  removing player name from campfire users table")
		remove_formspec_viewer(formspec_viewers[pos_key], player_name)
		--debug(flag9, "  formspec_viewers: " .. dump(formspec_viewers))
	end

    debug(flag9, "register_on_player_receive_fields() end")
end)


local flag15 = false
local function storage_on_destruct(pos)
	debug(flag15, "\nstorage_on_destruct()")
	local storage_meta = mt_get_meta(pos)

	local pos_key = pos_to_key(pos)
	if formspec_viewers[pos_key] == nil then
		debug(flag15, "  storage is above a non solid node. NO FURTHER ACTION.")
		debug(flag15, "storage_on_destruct() END")
		return
	end

	local condition = storage_meta:get_float("condition")
	debug(flag15, "  condition: " .. condition)
	if condition == 0 then
		debug(flag4, "      this is an unused storage bag. condition intialized to: " .. WEAR_VALUE_MAX)
		condition = WEAR_VALUE_MAX
	end

	if condition > 0 then
		debug(flag15, "  storage was dug or was falling")
		local storage_node = mt_get_node(pos)
		local storage_node_name = storage_node.name
		debug(flag15, "  storage_node_name: " .. storage_node_name)

		-- transfer the node's condition value to the itemstack while depleting approx
		-- 10% - 15% condition due to the bags destruction
		debug(flag15, "  applying 10% - 15% wear to storage")
		local wear = WEAR_VALUE_MAX * math_random(10, 15) * 0.01
		debug(flag15, "  wear: " .. wear)
		local new_condition = condition - wear
		if new_condition > 0 then
			debug(flag15, "  storage item still usable")
			local item_drop = ItemStack(storage_node_name)
			local item_meta = item_drop:get_meta()

			-- transfer condition to dropped storage bag
			item_meta:set_float("condition", new_condition)

			-- transfer heat_progress to dropped storage bag
			local heat_progress = storage_meta:get_float("heat_progress")
			item_meta:set_float("heat_progress", heat_progress)

			local tooltip = refresh_meta_and_description(storage_node_name, item_meta)
			debug(flag15, "  tooltip: " .. tooltip)
			item_meta:set_string("description", tooltip)

			-- drop the storage item to the ground
			mt_add_item({
				x = pos.x + math_random(-2, 2)/10,
				y = pos.y,
				z = pos.z + math_random(-2, 2)/10}, item_drop
			)

		else
			debug(flag15, "  storage is now worn out. not dropping it as an item.")
		end

	else
		debug(flag15, "  storage node will be removed due to being worn out from use or burned up by nearby campfire")
	end

	-- drop all items from all campfire slots
	debug(flag15, "  dropping all storage slot items..")
	drop_all_items(storage_meta:get_inventory(), pos)

	-- close formspec for any viewing players
	remove_formspec_all_viewers(pos, "ss:ui_storage")

	debug(flag15, "storage_on_destruct() END")
end


core.override_item("ss:bag_fiber_small", {
	on_construct = storage_on_construct,
	after_place_node = storage_after_place_node,
    on_rightclick = storage_on_rightclick,
	allow_metadata_inventory_put = storage_allow_metadata_inventory_put,
	on_metadata_inventory_move = storage_on_metadata_inventory_move,
	on_metadata_inventory_put = storage_on_metadata_inventory_put,
	on_metadata_inventory_take = storage_on_metadata_inventory_take,
	on_destruct = storage_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		storage_on_destruct(pos)
	end,
})

core.override_item("ss:bag_fiber_medium", {
	on_construct = storage_on_construct,
	after_place_node = storage_after_place_node,
    on_rightclick = storage_on_rightclick,
	allow_metadata_inventory_put = storage_allow_metadata_inventory_put,
	on_metadata_inventory_move = storage_on_metadata_inventory_move,
	on_metadata_inventory_put = storage_on_metadata_inventory_put,
	on_metadata_inventory_take = storage_on_metadata_inventory_take,
	on_destruct = storage_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		storage_on_destruct(pos)
	end,
})

core.override_item("ss:bag_fiber_large", {
	on_construct = storage_on_construct,
	after_place_node = storage_after_place_node,
    on_rightclick = storage_on_rightclick,
	allow_metadata_inventory_put = storage_allow_metadata_inventory_put,
	on_metadata_inventory_move = storage_on_metadata_inventory_move,
	on_metadata_inventory_put = storage_on_metadata_inventory_put,
	on_metadata_inventory_take = storage_on_metadata_inventory_take,
	on_destruct = storage_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		storage_on_destruct(pos)
	end,
})

core.override_item("ss:bag_cloth_small", {
	on_construct = storage_on_construct,
	after_place_node = storage_after_place_node,
    on_rightclick = storage_on_rightclick,
	allow_metadata_inventory_put = storage_allow_metadata_inventory_put,
	on_metadata_inventory_move = storage_on_metadata_inventory_move,
	on_metadata_inventory_put = storage_on_metadata_inventory_put,
	on_metadata_inventory_take = storage_on_metadata_inventory_take,
	on_destruct = storage_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		storage_on_destruct(pos)
	end,
})

core.override_item("ss:bag_cloth_medium", {
	on_construct = storage_on_construct,
	after_place_node = storage_after_place_node,
    on_rightclick = storage_on_rightclick,
	allow_metadata_inventory_put = storage_allow_metadata_inventory_put,
	on_metadata_inventory_move = storage_on_metadata_inventory_move,
	on_metadata_inventory_put = storage_on_metadata_inventory_put,
	on_metadata_inventory_take = storage_on_metadata_inventory_take,
	on_destruct = storage_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		storage_on_destruct(pos)
	end,
})

core.override_item("ss:bag_cloth_large", {
	on_construct = storage_on_construct,
	after_place_node = storage_after_place_node,
    on_rightclick = storage_on_rightclick,
	allow_metadata_inventory_put = storage_allow_metadata_inventory_put,
	on_metadata_inventory_move = storage_on_metadata_inventory_move,
	on_metadata_inventory_put = storage_on_metadata_inventory_put,
	on_metadata_inventory_take = storage_on_metadata_inventory_take,
	on_destruct = storage_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		storage_on_destruct(pos)
	end,
})