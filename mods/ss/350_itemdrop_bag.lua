print("- loading itemdrop_bag.lua")

-- cache global functions for faster access
local table_concat = table.concat
local table_insert = table.insert
local table_remove = table.remove
local vector_add = vector.add
local vector_distance = vector.distance
local math_round = math.round
local math_ceil = math.ceil
local mt_show_formspec = minetest.show_formspec
local mt_after = minetest.after
local mt_get_meta = minetest.get_meta
local mt_get_node = minetest.get_node
local mt_set_node = minetest.set_node
local mt_add_item = minetest.add_item
local mt_get_gametime = minetest.get_gametime
local mt_pos_to_string = minetest.pos_to_string
local mt_hash_node_position = minetest.hash_node_position
local mt_remove_node = minetest.remove_node
local mt_get_node_drops = minetest.get_node_drops
local debug = ss.debug
local drop_all_items = ss.drop_all_items
local pos_to_key = ss.pos_to_key
local remove_formspec_viewer = ss.remove_formspec_viewer
local remove_formspec_all_viewers = ss.remove_formspec_all_viewers
local play_item_sound = ss.play_item_sound
local is_variable_height_node_supportive = ss.is_variable_height_node_supportive
local add_item_to_itemdrop_bag = ss.add_item_to_itemdrop_bag
local player_control_fix = ss.player_control_fix

-- cache global variables for faster access
local SLOT_COLOR_BG = ss.SLOT_COLOR_BG
local SLOT_COLOR_HOVER = ss.SLOT_COLOR_HOVER
local SLOT_COLOR_BORDER = ss.SLOT_COLOR_BORDER
local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local NODE_NAMES_LAVA = ss.NODE_NAMES_LAVA
local NODE_NAMES_NONSOLID_NONDIGGABLE = ss.NODE_NAMES_NONSOLID_NONDIGGABLE
local NODE_NAMES_NONSOLID_DIGGABLE = ss.NODE_NAMES_NONSOLID_DIGGABLE
local NODE_NAMES_SOLID_CUBE = ss.NODE_NAMES_SOLID_CUBE
local NODE_NAMES_SOLID_VARIABLE_HEIGHT = ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT
local NODE_NAMES_DIGGABLE_ALL = ss.NODE_NAMES_DIGGABLE_ALL
local NODE_NAMES_GAPPY_ALL = ss.NODE_NAMES_GAPPY_ALL
local NODE_NAMES_NONDIGGABLE_EVER = ss.NODE_NAMES_NONDIGGABLE_EVER
local ITEMDROP_BAGS_ALL = ss.ITEMDROP_BAGS_ALL
local NODE_NAMES_PLANTLIKE_ROOTED = ss.NODE_NAMES_PLANTLIKE_ROOTED
local NODE_DROPS_FLATTENED = ss.NODE_DROPS_FLATTENED
local formspec_viewers = ss.formspec_viewers
local player_data = ss.player_data
local itemdrop_bag_pos = ss.itemdrop_bag_pos

-- time in seconds until dropped item turns into an itemdrop bag. default 300 = 5 minutes.
local TRANSFORM_THRESHOLD_TIME = 300



local flag4 = false
--- @param pos table position of where the itemdrop bag will spawn
-- The itemdrop bag is initially set with one item slot, which dynamically increases
-- as more nearby dropped items get 'absorbed' into it, and decreases as player removes
-- items from the bag.
local function bag_on_construct(pos)
	debug(flag4, "bag_on_construct() ITEMDROP BAG")
	local node_meta = mt_get_meta(pos)

	debug(flag4, "  creating unique pos_key for this bag node")
	local pos_key = pos_to_key(pos)
	debug(flag4, "  pos_key: " .. pos_key)

	debug(flag4, "  initializing node inventory list")
	local node_inv = node_meta:get_inventory()
	node_inv:set_size("items", 1)

	-- initialize subtable in formspec_viewers table for this bag node to
	-- track the players currently viewing this bag's formspec/ui
	formspec_viewers[pos_key] = {}

	debug(flag4, "bag_on_construct() END ")
end


local flag5 = false
-- returns all formspec elements that displays the campfire UI. checks the campfire
-- status and campfire fuel levels to dynamically display the correct campfire visuals.
local function get_fs_bag(pos, pos_key)
	debug(flag5, "    get_fs_bag()")
	debug(flag5, "      pos: " .. dump(pos))
	local node_meta = mt_get_meta(pos)
    local bag_inv = node_meta:get_inventory()
	local bag_items_list = bag_inv:get_list("items")
	debug(flag5, "      bag_items_list: " .. dump(bag_items_list))

	local slot_count = bag_inv:get_size("items")
	local row_count = math_ceil(slot_count / 8)
	local column_count
	if slot_count > 7 then
		column_count = 8
	else
		column_count = slot_count
	end
	debug(flag5, "      slot_count: " .. slot_count)
	debug(flag5, "      row_count: " .. row_count)
	debug(flag5, "      column_count: " .. column_count)

	local list_element_padding = 0.2  -- padding around the entire grid / 'list' element
	local list_slot_padding = 0.1  -- padding between each slot
	local x_size = column_count + (list_element_padding * 2) + ((column_count - 1) * list_slot_padding)
	local y_size = row_count + (list_element_padding * 2) + ((row_count - 1) * list_slot_padding)

	local formspec = ""
	local fs_output = {}
	local inventory_elements = table_concat({
		"formspec_version[7]",
		"size[" .. x_size .. "," .. y_size .. ",true]",
		"position[0.5,0.5]",
		"listcolors[",
			SLOT_COLOR_BG, ";",
			SLOT_COLOR_HOVER, ";",
			SLOT_COLOR_BORDER, ";",
			TOOLTIP_COLOR_BG, ";",
			TOOLTIP_COLOR_TEXT, "]",
		"style_type[list;spacing=" .. list_slot_padding .. "," .. list_slot_padding .. "]",
		"list[nodemeta:", pos_key, ";items;" .. list_element_padding .. "," .. list_element_padding .. ";8,8;]"
	})
	table_insert(fs_output, inventory_elements)
	formspec = table_concat(fs_output)

	debug(flag5, "    get_fs_bag() end *** " .. mt_get_gametime() .. " ***")
	return formspec
end


local flag6 = false
local function bag_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	debug(flag6, "\nbag_on_rightclick() ITEMDROP_BAG")

	local player_name = clicker:get_player_name()
	local p_data = player_data[player_name]
	local pos_key = pos_to_key(pos)
	debug(flag6, "  pos_key: " .. pos_key)

	-- save hash of bag pos for use by register_on_player_receive_fields()
	p_data.bag_pos_key = pos_key
	p_data.formspec_mode = "itemdrop_bag"

	-- show the itemdrop bag formspec ui
	mt_show_formspec(player_name, "ss:ui_itemdrop_bag", get_fs_bag(pos, pos_key))

	-- add the player's name to the formspec_viewers table to signify that the player
	-- is currently viewing/using this storage

	--formspec_viewers[pos_key] = formspec_viewers[pos_key] or {}
	table_insert(formspec_viewers[pos_key], player_name)
	debug(flag6, "  formspec_viewers: " .. dump(formspec_viewers))

	-- workaround to ensure LMB/RMB player control input is released so that stamina
	-- doesn't keep draining for being in DIG/SWING state
	player_control_fix(clicker)

	play_item_sound("bag_open", {pos = pos})

	debug(flag6, "bag_on_rightclick() end *** " .. mt_get_gametime() .. " ***")
end


local flag15 = false
local function bag_on_destruct(pos)
	debug(flag15, "\nbag_on_destruct() ITEMDROP_BAG")
	local bag_node = mt_get_node(pos)
	local bag_name = bag_node.name
	local node_meta = mt_get_meta(pos)

	local node_inv = node_meta:get_inventory()
	if node_inv:is_empty("items") then
		debug(flag15, "  bag empty since player dropped last item")

	else
		debug(flag15, "  dropping bag contents")
		local item_spawn_pos
		if bag_name == "ss:itemdrop_bag_in_water" then
			debug(flag15, "  this bag is under water")
			item_spawn_pos = {x = pos.x, y = pos.y + 1.5, z = pos.z}
		else
			debug(flag15, "  this bag is on land")
			item_spawn_pos = {x = pos.x, y = pos.y + 0.5, z = pos.z}
		end
		drop_all_items(node_inv, item_spawn_pos)

		-- close formspec for any viewing players
		remove_formspec_all_viewers(pos, "ss:ui_itemdrop_bag")
	end

	debug(flag15, "bag_on_destruct() END")
end


-- prevent abililty to move items around within bag
local flag10 = false
local function bag_allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	debug(flag10, "\nbag_allow_metadata_inventory_move() ITEMDROP BAG")
	debug(flag10, "  count: " .. count)
	debug(flag10, "bag_allow_metadata_inventory_move() end *** " .. mt_get_gametime() .. " ***")
	return 0
end


local flag12 = false
local function bag_allow_metadata_inventory_take(pos, listname, index, stack, player)
	debug(flag12, "\nbag_allow_metadata_inventory_take() ITEMDROP BAG")

	local item_count = stack:get_count()
	debug(flag12, "  item_count: " .. item_count)

	local node = mt_get_node(pos)
	local node_name = node.name
	debug(flag12, "  node_name: " .. node_name)

	-- itemdrop bags in the water are plantlike_rooted type nodes, and so the pos for
	-- the item to drop should be 1 block higher
	if node_name == "ss:itemdrop_bag_in_water" then
		debug(flag12, "  updating pos for water based bag..")
		pos = {x = pos.x, y = pos.y + 1, z = pos.z}
	end

	local player_pos = player:get_pos()
	-- add 1.2 to the player's height since this seems to be what core.spawn_item()
	-- expects within its 'pos' parameter
	player_pos = {x = player_pos.x, y = player_pos.y + 1.2, z = player_pos.z}
	debug(flag12, "  player_pos: " .. mt_pos_to_string(player_pos))

	-- save the itemdrop bag's position into a table that is indexed by player's pos hash
	local pos_hash = mt_hash_node_position(player_pos)
	itemdrop_bag_pos[pos_hash] = pos
	debug(flag12, "  itemdrop_bag_pos: " .. dump(itemdrop_bag_pos))

	debug(flag12, "bag_allow_metadata_inventory_take() end *** " .. mt_get_gametime() .. " ***")

	-- since an amount greater than zero is being returned here, core.spawn_item() is called
	-- to perform the actually dropping of the item at the player's pos, immediately followed
	-- by on_metadata_inventory_take(). however, since core.spawn_item() will see that
	-- ss.itemdrop_bag_pos is not NIL, it will instead drop the item at this bag pos.
	return item_count
end


local flag1 = false
local function bag_on_metadata_inventory_take(pos, listname, index, stack, player)
	debug(flag1, "\nbag_on_metadata_inventory_take() ITEMDROP BAG")
	local player_name = player:get_player_name()
	local item_name = stack:get_name()

	debug(flag1, "  REMOVED " .. item_name)
	play_item_sound("item_move", {item_name = item_name, player_name = player_name})

	local node_meta = mt_get_meta(pos)
	local bag_inv = node_meta:get_inventory()
	local bag_items_list = bag_inv:get_list("items")
	debug(flag1, "  bag_items_list: " .. dump(bag_items_list))
	debug(flag1, "  removing any empty slots..")
	for i, bag_item in ipairs(bag_items_list) do
		local bag_item_name = bag_item:get_name()
		debug(flag1, "  bag_item_name: " .. bag_item_name)
		if bag_item_name == "" then
			debug(flag1, "    empty slot")
			table_remove(bag_items_list, i)
			bag_inv:set_size("items", bag_inv:get_size("items") - 1)
			debug(flag1, "    reduced bag inventory slots by 1")
		else
			debug(flag1, "    contains an item. no action.")
		end
	end
	debug(flag1, "  finished removing any empty slots")
	debug(flag1, "  bag_items_list: " .. dump(bag_items_list))

	local bag_slot_count = bag_inv:get_size("items")
	debug(flag1, "  bag_slot_count: " .. bag_slot_count)
	if bag_slot_count > 0 then
		debug(flag1, "  slots still remain in bag. no action.")
		bag_inv:set_list("items", bag_items_list)

		-- refresh formspec for all viewers of itemdrop bag
		local pos_key = pos_to_key(pos)
		local viewer_list = formspec_viewers[pos_key]
		debug(flag1, "  formspec_viewers: " .. dump(formspec_viewers))
		debug(flag1, "  viewer_list: " .. dump(viewer_list))
		for i, viewer_name in ipairs(viewer_list) do
			debug(flag1, "  refreshing formspec for: " .. viewer_name)
			local formspec = get_fs_bag(pos, pos_key)
			mt_show_formspec(viewer_name, "ss:ui_itemdrop_bag", formspec)
		end

	else
		debug(flag1, "  no slots remain in bag")
		remove_formspec_all_viewers(pos, "ss:ui_itemdrop_bag")
		mt_remove_node(pos)
		debug(flag1, "  removed itemdrop bag node")
	end

	debug(flag1, "bag_on_metadata_inventory_take() end *** " .. mt_get_gametime() .. " ***")
end



local flag2 = false
minetest.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag2, "\nregister_on_player_receive_fields() ITEMDROP BAG")
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

	debug(flag2, "  p_data.formspec_mode: " .. p_data.formspec_mode)
    if p_data.formspec_mode ~= "itemdrop_bag" then
        debug(flag2, "  interaction not from itemdrop bag formspec. NO FURTHER ACTION.")
        debug(flag2, "register_on_player_receive_fields() end " .. mt_get_gametime())
        return
    else
        debug(flag2, "  interaction from itemdrop bag formspec. inspecting fields..")
    end

	if fields.quit then
		debug(flag2, "  player quit from itemdrop bag formspec")
		p_data.formspec_mode = "main_formspec"

		debug(flag2, "  removing player name from formspec viewers table")
		remove_formspec_viewer(formspec_viewers[p_data.bag_pos_key], player_name)
		debug(flag2, "  formspec_viewers (after): " .. dump(formspec_viewers))
	end

    debug(flag2, "register_on_player_receive_fields() end")
end)


-- spawns on land
minetest.override_item("ss:itemdrop_bag", {
	on_construct = bag_on_construct,
	on_rightclick = bag_on_rightclick,
	allow_metadata_inventory_move = bag_allow_metadata_inventory_move,
	allow_metadata_inventory_take = bag_allow_metadata_inventory_take,
	on_metadata_inventory_take = bag_on_metadata_inventory_take,
	on_destruct = bag_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		bag_on_destruct(pos)
	end,
})

-- spawns in water
minetest.override_item("ss:itemdrop_bag_in_water", {
	on_construct = bag_on_construct,
	on_rightclick = bag_on_rightclick,
	allow_metadata_inventory_move = bag_allow_metadata_inventory_move,
	allow_metadata_inventory_take = bag_allow_metadata_inventory_take,
	on_metadata_inventory_take = bag_on_metadata_inventory_take,
	on_destruct = bag_on_destruct,
	after_destruct = function(pos, oldnode)
		mt_set_node(pos, {name="default:dirt"})
	end
})

-- force-spawns into a solid node when no open spawn pos was available
minetest.override_item("ss:itemdrop_box", {
	on_construct = bag_on_construct,
	on_rightclick = bag_on_rightclick,
	allow_metadata_inventory_move = bag_allow_metadata_inventory_move,
	allow_metadata_inventory_take = bag_allow_metadata_inventory_take,
	on_metadata_inventory_take = bag_on_metadata_inventory_take,
	on_destruct = bag_on_destruct,
})


local bag_search_vectors = {
	{x = 0, y = 0, z = 0},  -- CURRENT
	{x = 0, y = 0, z = 1},  -- N
	{x = 1, y = 0, z = 1},  -- NE
	{x = 1, y = 0, z = 0},  -- E
	{x = 1, y = 0, z = -1}, -- SE
	{x = 0, y = 0, z = -1}, -- S
	{x = -1, y = 0, z = -1},-- SW
	{x = -1, y = 0, z = 0}, -- W
	{x = -1, y = 0, z = 1}, -- NW
	{x = 0, y = 1, z = 0},  -- TOP
	{x = 0, y = -1, z = 0},  -- botom
}

local flag3 = false
local function find_nearby_bag_pos(itemdrop_pos)
	debug(flag3, "    find_nearby_bag_pos()")
    for i, add_vector in ipairs(bag_search_vectors) do
        local adj_pos = vector_add(itemdrop_pos, add_vector)
        local adj_node_name = mt_get_node(adj_pos).name
		debug(flag3, "      " .. adj_node_name .. " " .. mt_pos_to_string(adj_pos))
        if ITEMDROP_BAGS_ALL[adj_node_name] then
			debug(flag3, "        ** existing itemdrop bag found **")
			debug(flag3, "      find_nearby_bag_pos() END")
            return adj_pos
		end
    end
	debug(flag3, "      no existing itemdrop bag found")
	debug(flag3, "    find_nearby_bag_pos() END")
    return nil
end


local node_search_vectors = {
	-- clockwise from north at current elevation y = 0
	{x = 0, y = 0, z = 0}, -- origin
	{x = 0, y = 0, z = 1}, -- N
	{x = 1, y = 0, z = 1}, -- NE
	{x = 1, y = 0, z = 0}, -- E
	{x = 1, y = 0, z = -1}, -- SE
	{x = 0, y = 0, z = -1}, -- S
	{x = -1, y = 0, z = -1}, -- SW
	{x = -1, y = 0, z = 0}, -- W
	{x = -1, y = 0, z = 1}, -- NW
	-- clockwise from north at lower elevation y = -1
	{x = 0, y = -1, z = 1}, -- N
	{x = 1, y = -1, z = 1}, -- NE
	{x = 1, y = -1, z = 0}, -- E
	{x = 1, y = -1, z = -1}, -- SE
	{x = 0, y = -1, z = -1}, -- S
	{x = -1, y = -1, z = -1}, -- SW
	{x = -1, y = -1, z = 0}, -- W
	{x = -1, y = -1, z = 1}, -- NW
	{x = 0, y = -1, z = 0}, -- directly below
	-- clockwise from north at higher elevation y = +1
	{x = 0, y = 1, z = 1}, -- N
	{x = 1, y = 1, z = 1}, -- NE
	{x = 1, y = 1, z = 0}, -- E
	{x = 1, y = 1, z = -1}, -- SE
	{x = 0, y = 1, z = -1}, -- S
	{x = -1, y = 1, z = -1}, -- SW
	{x = -1, y = 1, z = 0}, -- W
	{x = -1, y = 1, z = 1}, -- NW
	{x = 0, y = 1, z = 0}, -- directly above
}
 local search_vector_labels = {
	"origin pos",
	"N at Elevation 0",
	"NE at Elevation 0",
	"E at Elevation 0",
	"SE at Elevation 0",
	"S at Elevation 0",
	"WE at Elevation 0",
	"WE at Elevation 0",
	"NW at Elevation 0",

	"directly below origin pos",
	"N at Elevation -1",
	"NE at Elevation -1",
	"E at Elevation -1",
	"SE at Elevation -1",
	"S at Elevation -1",
	"WE at Elevation -1",
	"WE at Elevation -1",
	"NW at Elevation -1",

	"directly above origin pos",
	"N at Elevation 1",
	"NE at Elevation +1",
	"E at Elevation +1",
	"SE at Elevation +1",
	"S at Elevation +1",
	"WE at Elevation +1",
	"WE at Elevation +1",
	"NW at Elevation +1",
 }


local flag14 = false
-- this function searches 'pos' and all adjacent positions starting clockwise at
-- North direction and at at the current elevation. if no existing bag nor suitable
-- pos is found, it will search clockwise again start at North but at 1 meter
-- elevation down. if no suitable pos is found, it will search again at at 1 meter
-- elevation above the original pos. if no suitable pos found, it will pick the
-- nearest non-suitable node and forcable replace that with a special box/chest
-- container to hold the dropped items.
--- @param itemdrop_pos table position of where the dropped item was in the world
--- @return string search_result 'bag', 'success', 'drop', 'despawn', or 'failed'
--- @return table spawn_pos pos within the context of the 'search_result'. for
--- 'despawn' and 'failed', the returned spawn_pos is an empty table
local function get_valid_bag_pos(itemdrop_pos)
	debug(flag14, "  get_valid_bag_pos()")
	local spawn_pos = {}
	local search_result = "failed"
	local nearest_allowed_pos
	local previous_distance = 0

    for i, add_vector in ipairs(node_search_vectors) do
        local search_pos = vector_add(itemdrop_pos, add_vector)
        local node_name = mt_get_node(search_pos).name
		debug(flag14, "    pos #" .. i .. " " .. search_vector_labels[i] .. ": "
			.. node_name .. " " .. mt_pos_to_string(search_pos))

		-- itemdrop bags that are underwater is a 'plantlike_rooted' node in which
		-- the node below the drawn bag texture is the actual bag node to look for
		local existing_bag_pos
		if NODE_NAMES_WATER[node_name] then
			debug(flag14, "    this pos is underwater")
			existing_bag_pos = find_nearby_bag_pos({
				x = search_pos.x,
				y = search_pos.y - 1,
				z = search_pos.z
			})
		else
			debug(flag14, "    this pos is on dry land")
			existing_bag_pos = find_nearby_bag_pos(search_pos)
		end

		if existing_bag_pos then
			debug(flag14, "    this pos contains an itemdrop bag. no need to spawn new bag.")
			search_result = "bag"
			spawn_pos = existing_bag_pos
			break

		elseif NODE_NAMES_LAVA[node_name] then
			debug(flag14, "    this pos is lava. no itemdrop bag can be spawned here.")
			search_result = "despawn"
			break

		elseif NODE_NAMES_NONSOLID_NONDIGGABLE[node_name] then
			debug(flag14, "    this pos has a nonsolid non-diggable node. bag cannot be spawned here.")

		elseif NODE_NAMES_DIGGABLE_ALL[node_name] or NODE_NAMES_WATER[node_name] then
			debug(flag14, "    this pos contains a replaceable node. checking node below..")

			-- check node below
			local below_pos = {x = search_pos.x, y = search_pos.y - 1, z = search_pos.z}
			local below_node = mt_get_node(below_pos)
			local below_node_name = below_node.name
			debug(flag14, "    below_node_name: " .. below_node_name)

			if ITEMDROP_BAGS_ALL[below_node_name] then
				debug(flag14, "    pos below contains an itemdrop bag. no need to spawn new bag.")
				search_result = "bag"
				spawn_pos = below_pos
				break

			elseif NODE_NAMES_LAVA[below_node_name] then
				debug(flag14, "    pos below contains lava. bag cannot spawn above it.")

			elseif NODE_NAMES_PLANTLIKE_ROOTED[below_node_name] then
				debug(flag14, "    pos below is the souce node for an underwater stuff. bag cannot spawn above it.")

			elseif NODE_NAMES_GAPPY_ALL[below_node_name] then
				debug(flag14, "    node below is gappy so bag cannot spawn above it")

			elseif NODE_NAMES_SOLID_VARIABLE_HEIGHT[below_node_name] then
				debug(flag14, "    pos below contains a node with variable height. inspecting its orientation..")
				if is_variable_height_node_supportive(below_node, below_node_name) then
					debug(flag14, "    this variable node is supportive. bag can spawn above it.")
					search_result = "success"
					spawn_pos = search_pos
					break
				else
					debug(flag14, "    this variable node is not supportive")
				end

			elseif NODE_NAMES_NONSOLID_DIGGABLE[below_node_name] then
				debug(flag14, "    node below is nonsolid but diggable so bag can spawn above it")
				search_result = "drop"
				spawn_pos = search_pos
				break
				-- bag will spawn above, detect no solid node below, and because
				-- bag is of group 'attached_node', its contents will drop and
				-- fall onto this nonsolid node, then spawn on it, replacing
				-- it and triggering it's after_destruct() which will drop items
				-- based NODE_DROPS_FLATTENED table

			elseif NODE_NAMES_NONSOLID_NONDIGGABLE[below_node_name] then
				debug(flag14, "    node below is nonsolid but nondiggable. bag cnnot spawn above it.")

			elseif NODE_NAMES_SOLID_CUBE[below_node_name] then
				debug(flag14, "    pos below is solid. bag can spawn above it.")
				search_result = "success"
				spawn_pos = search_pos
				break

			else
				debug(flag14, "    bag not allowed to spawn above this node since it is unacounted for: " .. below_node_name)
			end
		else
			debug(flag14, "    bag not allowed to spawn here since pos has unaccounted for node: " .. node_name)
		end

		-- at this point, current search pos is not suitable for bag spawn. check
		-- if the node here can still be replaced as a final resort and track its
		-- distance. we want the 'last-resort' position to be nearest to the original
		-- position of the dropped item
		if not NODE_NAMES_NONDIGGABLE_EVER[node_name] then
			debug(flag14, "    node at this pos can be replaced as last resort")
			local distance = vector_distance(itemdrop_pos, search_pos)
			debug(flag14, "    distance: " .. distance)
			debug(flag14, "    previous_distance: " .. previous_distance)

			if nearest_allowed_pos == nil then
				debug(flag14, "    this is the first last_resort pos found")
				previous_distance = distance
				debug(flag14, "    set distance to: " .. distance)
				nearest_allowed_pos = search_pos
				debug(flag14, "    set nearest_allowed_pos to: " .. mt_pos_to_string(nearest_allowed_pos))

			else
				if distance > previous_distance then
					debug(flag14, "    but distance to far. discarding this pos.")
				else
					nearest_allowed_pos = search_pos
					debug(flag14, "    updated nearest_allowed_pos: " .. mt_pos_to_string(nearest_allowed_pos))
				end
			end

		else
			debug(flag14, "    node at this pos cannot be replaced ever")
		end

		if i == 27 then
			debug(flag14, "    searched all positions. none are valid.")
			if nearest_allowed_pos then
				debug(flag14, "    found a pos that is ok to replace as last resort: "
					.. mt_pos_to_string(nearest_allowed_pos))
				local last_resort_node = mt_get_node(nearest_allowed_pos)
				debug(flag14, "    last_resort_node name: " .. last_resort_node.name)
				search_result = "failed"
				spawn_pos = nearest_allowed_pos
			else
				debug(flag14, "    no 'last-resort' pos found either. letting item despawn.")
				search_result = "despawn"
			end
		end
    end

	debug(flag14, "  get_valid_bag_pos() END")
	return search_result, spawn_pos
end


local flag7 = false
local function transform_to_bag(self)
	debug(flag7, "\ntransform_to_bag()")

	local itemdrop_pos = self.object:get_pos()
	if itemdrop_pos then
		debug(flag7, "  itemdrop_pos:" .. mt_pos_to_string(itemdrop_pos))

		-- remove the dropped item entity object from the world
		local itemstring = self.itemstring
		local dropped_item = ItemStack(itemstring)
		debug(flag7, "  removing " .. itemstring)
		self.itemstring = ""
		self.object:remove()

		-- horizontally center pos and get node info at that position
		itemdrop_pos = {
			x = math_round(itemdrop_pos.x),
			y = math_round(itemdrop_pos.y),
			z = math_round(itemdrop_pos.z)
		}
		debug(flag7, "  updated itemdrop_pos:" .. mt_pos_to_string(itemdrop_pos))

		local search_result, spawn_pos = get_valid_bag_pos(itemdrop_pos)

		if search_result == "bag" then
			debug(flag7, "  existing bag found. adding dropped items there..")

			local node_meta = mt_get_meta(spawn_pos)
			local node_inv = node_meta:get_inventory()
			debug(flag7, "  trying to add " .. dropped_item:get_name() .. " into bag..")

			if node_inv:room_for_item("items", dropped_item) then
				local leftover_items = node_inv:add_item("items", dropped_item)
				debug(flag7, "  successfully added " .. itemstring .. " into slot")
				debug(flag7, "  leftover_items (should be 0): " .. leftover_items:get_count())

			else
				debug(flag7, "  does not fit in slot. adding an extra slot.. " .. itemstring)
				node_inv:set_size("items", node_inv:get_size("items") + 1)
				local leftover_items = node_inv:add_item("items", dropped_item)
				debug(flag7, "  item successfully added to bag")
				debug(flag7, "  leftover_items (should be 0): " .. leftover_items:get_count())

				local pos_key = pos_to_key(spawn_pos)
				--formspec_viewers[pos_key] = formspec_viewers[pos_key] or {}
				local viewer_list = formspec_viewers[pos_key]
				--debug(flag7, "  formspec_viewers: " .. dump(formspec_viewers))
				--debug(flag7, "  viewer_list: " .. dump(viewer_list))
				for i, viewer_name in ipairs(viewer_list) do
					debug(flag7, "  refreshing formspec for: " .. viewer_name)
					local formspec = get_fs_bag(spawn_pos, pos_key)
					mt_show_formspec(viewer_name, "ss:ui_itemdrop_bag", formspec)
				end
			end

		elseif search_result == "success" then
			debug(flag7, "  valid pos found. spawning itemdrop bag")
			local spawn_pos_node = mt_get_node(spawn_pos)
			local spawn_pos_node_name = spawn_pos_node.name
			debug(flag7, "    spawn_pos_node_name: " .. spawn_pos_node_name)
			if NODE_NAMES_WATER[spawn_pos_node_name] then
				debug(flag7, "    spawning bag in water. using plantlike rooted variant..")
				local bottom_pos = {x = spawn_pos.x, y = spawn_pos.y - 1, z = spawn_pos.z}
				mt_set_node(bottom_pos, {name="ss:itemdrop_bag_in_water"})
				add_item_to_itemdrop_bag(bottom_pos, dropped_item)
			else
				debug(flag7, "    spawning normal plantlike style bag..")
				mt_set_node(spawn_pos, {name="ss:itemdrop_bag"})
				add_item_to_itemdrop_bag(spawn_pos, dropped_item)
			end

		elseif search_result == "drop" then
			debug(flag7, "  potentially valid pos found over non-solid node. dropping items to retry bag spawn there..")
			mt_add_item(spawn_pos, dropped_item)

		elseif search_result == "despawn" then
			debug(flag7, "  dropped item is despawned")

		elseif search_result == "failed" then
			debug(flag7, "  no valid pos found. will force-spawn special itemdrop 'box' instead")

			local node = mt_get_node(spawn_pos)
			local node_name = node.name

			debug(flag7, "  force-spawning itemdrop box and replacing " .. node_name
				.. " at " .. mt_pos_to_string(spawn_pos))
			mt_set_node(spawn_pos, {name="ss:itemdrop_box"})

			-- prepare all items that will go into the itemdrop box into this table
			local items_for_box = {}
			table_insert(items_for_box, dropped_item)

			-- if the flattened node was a diggable node, retrieve its node drops
			-- from NODE_DROPS_FLATTENED table. if not, pull node drops from
			-- its node defintion's 'drop' property
			local node_drop = NODE_DROPS_FLATTENED[node_name]
			if node_drop then

				-- 'node_drop' is a string representing a single item
				debug(flag7, "  replaced node was diggable")
				debug(flag7, "  node_drop: " .. node_drop)
				table_insert(items_for_box, ItemStack(node_drop))

			else
				debug(flag7, "  replaced node was non-diggable")
				-- 'node_drops' is a table and can be multiple items
				local node_drops = mt_get_node_drops(node)
				debug(flag7, "  node drops: " .. dump(node_drops))
				for i, item in ipairs(node_drops) do
					table_insert(items_for_box, ItemStack(item))
				end
			end

			-- insert all the drops into the box
			for i, item in ipairs(items_for_box) do
				debug(flag7, "  adding to box: " .. item:get_name())
				add_item_to_itemdrop_bag(spawn_pos, item)
			end

		else
			debug(flag7, "  ERROR - Unexpected 'search_result' value: " .. search_result)
			debug(flag7, "  dropped item is despawned")
		end

	else
		debug(flag7, "  ** dropped item was picked up **")
	end

	debug(flag7, "transform_to_bag() end")
end





local flag9 = false
-- ensure the global formspec_viewers table has an entry for this itemdrop bag,
-- consisting of the pos_key as the index. the 'remove_formspec_all_viewers' global
-- table relies on all itemdrop bag nodes in the world to have an entry.
minetest.register_lbm({
    name = "ss:add_bag_pos_formspec_viewers",
    nodenames = {"ss:itemdrop_bag", "ss:itemdrop_bag_in_water", "ss:itemdrop_box",},
    run_at_every_load = true,
    action = function(pos, node)
		debug(flag9, "\nregister_lbm() add_bag_pos_formspec_viewers")
		local pos_key = pos_to_key(pos)
		local viewers = formspec_viewers[pos_key]
		if viewers then
			debug(flag9, "  itemdrop bag pos " .. pos_key .. " already exists in formspec_viewers" )
		else
			formspec_viewers[pos_key] = {}
			debug(flag9, "  itemdrop bag pos " .. pos_key .. " added to formspec_viewers" )
		end
		debug(flag9, "  formspec_viewers: " .. dump(formspec_viewers))
		debug(flag9, "register_lbm() END")
    end,
})




-- override all dropped item entities to have this new mechanic of turning into an
-- itemdrop bag after a pre-determined amount of time
local builtin_item = minetest.registered_entities["__builtin:item"]
local item = {
	on_activate = function(self, staticdata, dtime_s)
		local flag8 = false
		debug(flag8, "on_activate()")
		debug(flag8, "  staticdata: " .. dump(staticdata))
        builtin_item.on_activate(self, staticdata, dtime_s)

		if self.age > TRANSFORM_THRESHOLD_TIME then
			debug(flag8, "  transform time reached!")
			transform_to_bag(self)
		else
			local remaining_time = TRANSFORM_THRESHOLD_TIME - self.age
			debug(flag8, "  remaining_time: " .. remaining_time)
			mt_after(remaining_time, transform_to_bag, self)
		end

		debug(flag8, "on_activate() end")
    end
}

-- set newly define 'item' as new __builtin:item, with the old one as fallback table
setmetatable(item, { __index = builtin_item })
minetest.register_entity(":__builtin:item", item)


--[[

NOTES

Main Itemdrop Bag Mechanics:

when an item is dropped to the ground, the item enitity has a default lifespan (or time
to live "TTL") of 900 seconds, which is 15 minutes. this is defined in the Server Gameplay
settings from the main Minetest settings page.

the global '__builtin:item' is overridden so that after reaching TRANSFORM_THRESHOLD_TIME,
the item entity turns into an item drop bag which then contains the dropped item(s). if
there is an existing bag nearby, the item entity is absorbed by that existing bag. the
default TRANSFORM_THRESHOLD_TIME is 300 seconds (or 5 min). so the item entity will always
transform into a bag before the default 15 minutes lifespan.

when a new item drop bag is spawned, its meta inventory size is set to 1. this size is
dynamiclly increased as any nearby dropped items are added to the bag.

each time a player removes an time from the bag, the resulting empty slot is removed. when
the last item is removed, the bag disappears completely. it is not possible to add items 
into the itemdrop bag.

right click on the bag to view its contents, which are displayed in 8 slots per row. for
now, there is no limit to how many rows of items can be stored in the bag. if more than
8 rows, the extra rows may fall outside the boundary of the ui window and cannot be seen.
a vertical scrollbar mechanism can be added later.

Valid Spawn Locations:

the item drop bag only spawns on solid walkable nodes. if the potentional spawn position of
the bag is non-walkable like air, plants, etc. it will search out adjacent positions for a
better node to spawn on. the item drop bag also will not spawn on solid nodeboxes that
have air on the upper half of the node, like bottom slabs.

Bag Spawning in Water:

if the potential spawn position is in water, a bag node with 'plantlike_rooted' drawtype is
spawned to avoid air pockets. if the potential spawn position is in water AND above a some
sea life, like kelp and coral, an alternate underwater position will be searched for.

Bag on a Falling Block:

if a falling block like sand falls from underneath an itemdrop bag, the contents of the bag
are dropped.

--]]