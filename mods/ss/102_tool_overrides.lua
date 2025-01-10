print("- loading tool_overrides.lua")

-- cache global functions for faster access
local math_sin = math.sin
local math_cos = math.cos
local math_random = math.random
local math_pi = math.pi
local table_insert = table.insert
local table_concat = table.concat
local table_sort = table.sort
local vector_add = vector.add

local mt_get_meta = minetest.get_meta
local mt_get_gametime = minetest.get_gametime
local mt_get_objects_inside_radius = minetest.get_objects_inside_radius
local mt_close_formspec = minetest.close_formspec
local mt_show_formspec = minetest.show_formspec
local mt_add_item = minetest.add_item
local mt_add_entity = minetest.add_entity
local mt_yaw_to_dir = minetest.yaw_to_dir

local debug = ss.debug
local round = ss.round
local get_itemstack_weight = ss.get_itemstack_weight
local play_item_sound = ss.play_item_sound
local set_stat = ss.set_stat
local update_fs_weight = ss.update_fs_weight
local notify = ss.notify
local pickup_item = ss.pickup_item

-- cache global variables for faster access
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local COOK_THRESHOLD = ss.COOK_THRESHOLD
local ITEM_DESTRUCT_PATH = ss.ITEM_DESTRUCT_PATH
local ITEM_POINTING_RANGES = ss.ITEM_POINTING_RANGES
local POINTING_RANGE_DEFAULT = ss.POINTING_RANGE_DEFAULT
local mt_registered_items = minetest.registered_items


--[[
GROUP VALUES FOR NODES:
SNAPPY		plant stuff			[sword]		sapling, leaves, pine needles, papyrus, shrub, bush, grass, fern, kelp, coral (green, pink, cyan)
CRUMBLY		dirt/sand/snow		[shovel]	dirt, sand, sandstone, gravel, clay, snow, snow block
CHOPPY		wood/furniture		[axe]		tree, wood, cactus, bush stem, wooden furniture and constructions
CRACKY		rock/ice/metals		[pickaxe]	stone, cobble, brick, block, sandstone, permafrost, ice, coral (brown, orange, skeleton), steel, glass, mese lamp
DIG_IMMEDIATE					[n/a]		saplings and apple
ODDLY_BREAKABLE_BY_HAND			[n/a] 		tree, wood, bush stem, wooden furniture and constructions, glass, mese lamp

Note: Custom pointing ranges for 'default:' tools are defined in this file. Custom
pointing ranges for 'ss:' tools were already applied via global_vars_init.lua.
--]]



local flag3 = true
-- alter tool wear mechansim so it also includes deducting the weight of the destroyed
-- tool from the player's total inventory weight
local after_use_tool = function(itemstack, user, node, digparams)
    debug(flag3, "### after_use_tool() TOOLS")
    local item_name = itemstack:get_name()
	local tool_wear_value = itemstack:get_wear()
	local wear_received = digparams.wear
	-- wear_received = 10000  -- for testing purposes

	debug(flag3, "  item_name: " .. item_name)
	debug(flag3, "  node.name: " .. node.name)
	debug(flag3, "  wear_received: " .. wear_received)
	debug(flag3, "  tool_wear_value: " .. tool_wear_value)

	if wear_received == 0 then
		debug(flag3, "  no wear received. no actions taken.")
	else
		debug(flag3, "  tool wear received!")
		local new_tool_wear_value = tool_wear_value + wear_received
		debug(flag3, "  new_tool_wear_value: " .. new_tool_wear_value)
		if new_tool_wear_value < 65535 then
			debug(flag3, "  tool still usable. adding wear to tool..")
			itemstack:add_wear(wear_received)
			tool_wear_value = itemstack:get_wear()

		else
			debug(flag3, "  tool is broken!")
			local player_meta = user:get_meta()
			play_item_sound("item_break", {item_name = item_name, pos = user:get_pos()})

			local weight_change
			local broken_items = ITEM_DESTRUCT_PATH[item_name]
			if broken_items then
				debug(flag3, "    resulted in scrap items")

				-- replace wielded tool with main scrap item
				local wield_item_name = table.remove(broken_items, 1)
				debug(flag3, "    scrap wield_item_name: " .. wield_item_name)
				itemstack = ItemStack(wield_item_name)

				-- drop to ground any additional scrap items
				local extra_broken_item_count = 0
				for i, broken_item_name in ipairs(broken_items) do
					debug(flag3, "    extra broken_item_name: " .. broken_item_name)
					mt_add_item(user:get_pos(), ItemStack(broken_item_name))
					extra_broken_item_count = extra_broken_item_count + 1
				end

				if extra_broken_item_count > 0 then
					notify(user, "Tool broke. Scraps dropped to ground.", 3, "message_box_2")
				else
					notify(user, "Tool broke", 2, "message_box_2")
				end

				-- reduce inventory weight. assuming the original tool being wielded
				-- never has itemstack quantity greater than 1, and its weight is
				-- always heavier than the resulting scrap item weight.
				local tool_weight = ITEM_WEIGHTS[item_name]
				local scrap_item_weight = get_itemstack_weight(itemstack) -- can be more than single count
				weight_change = tool_weight - scrap_item_weight
				debug(flag3, "    tool_weight: " .. tool_weight)
				debug(flag3, "    scrap_item_weight: " .. scrap_item_weight)
				debug(flag3, "    weight_change: " .. weight_change)

			else
				debug(flag3, "    no scrap items")
				itemstack = ItemStack("")
				notify(user, "Tool broke", 2, "message_box_2")

				-- assuming the original tool being wielded never has itemstack
				-- quantity greater than 1
				weight_change = ITEM_WEIGHTS[item_name]
			end

			set_stat(user, player_meta, "weight", "down", weight_change)
			update_fs_weight(user, player_meta)

		end
	end

    debug(flag3, "### after_use_tool() end")
    return itemstack
end


-- HANDS
minetest.override_item("", {
	tool_capabilities = {
		full_punch_interval = 0.5,
		groupcaps={
			glassy =  {times={ [1]=99, [2]=99,   [3]=99,   [4]=20,   [5]=16.0, [6]=12.0, [7]=8.0,  [8]=4.0,  [9]=1.0,  [10]=0.5 }, uses=0, maxlevel=1,},
            snappy =  {times={ [1]=99, [2]=10.0, [3]=9.0,  [4]=8.0,  [5]=7.0,  [6]=6.0,  [7]=5.0,  [8]=4.0,  [9]=3.0,  [10]=0.5 }, uses=0, maxlevel=1,},
            crumbly = {times={ [1]=99, [2]=99,   [3]=24.2, [4]=21.0, [5]=17.8, [6]=14.6, [7]=11.4, [8]=8.2,  [9]=5.0,  [10]=0.5 }, uses=0, maxlevel=1,},
            choppy =  {times={ [1]=99, [2]=99,   [3]=99,   [4]=99,   [5]=99,   [6]=22.0, [7]=18.0, [8]=14.0, [9]=10.0, [10]=0.5 }, uses=0, maxlevel=1,},
            cracky =  {times={ [1]=99, [2]=99,   [3]=99,   [4]=99,   [5]=99,   [6]=99,   [7]=99,   [8]=99,   [9]=99,   [10]=99 }, uses=0, maxlevel=1,}
		}
	},
	range = POINTING_RANGE_DEFAULT,
	sound = {
		punch_use_air = "ss_swoosh_faint"
	}
})


-- SHARPENED STONE
minetest.override_item("ss:stone_sharpened", {
	tool_capabilities = {
		full_punch_interval = 1.0,
		groupcaps={
			glassy =  {times={ [1]=99, [2]=11.5, [3]=10.0, [4]=8.5,  [5]=7.0,  [6]=5.5,  [7]=4.0,  [8]=2.5,  [9]=1.0,  [10]=0.5 }, uses=2, maxlevel=1,},
            snappy =  {times={ [1]=99, [2]=5.5,  [3]=5.0,  [4]=4.5,  [5]=4.0,  [6]=3.5,  [7]=3.0,  [8]=2.5,  [9]=2.0,  [10]=0.5 }, uses=3, maxlevel=1,},
            crumbly = {times={ [1]=99, [2]=20.0, [3]=17.5, [4]=15.0, [5]=12.5, [6]=10.0, [7]=7.5, [8]=5.0,   [9]=2.5,  [10]=0.5 }, uses=2, maxlevel=1,},
            choppy =  {times={ [1]=99, [2]=21.4, [3]=19.2, [4]=17.0, [5]=14.8, [6]=12.6, [7]=10.4, [8]=8.2,  [9]=6.0,  [10]=0.5 }, uses=2, maxlevel=1,},
            cracky =  {times={ [1]=99, [2]=99,   [3]=99,   [4]=99,   [5]=26.0, [6]=24.5, [7]=23.0, [8]=21.5, [9]=20.0, [10]=0.5 }, uses=1, maxlevel=1,}
		}
	},
	sound = {
		punch_use_air = "ss_swoosh_faint"
	},
	after_use = after_use_tool
})


-- WOODEN HAMMER
minetest.override_item("ss:hammer_wood", {
	tool_capabilities = {
		full_punch_interval = 2.0,
		groupcaps={
			glassy =  {times={ [1]=99, [2]=99, [3]=99,   [4]=20,   [5]=16.0, [6]=12.0, [7]=8.0,  [8]=4.0,  [9]=1.0,  [10]=0.5 }, uses=0, maxlevel=1},
            snappy =  {times={ [1]=99, [2]=10, [3]=9.0,  [4]=8.0,  [5]=7.0,  [6]=6.0,  [7]=5.0,  [8]=4.0,  [9]=3.0,  [10]=0.5 }, uses=0, maxlevel=1},
            crumbly = {times={ [1]=99, [2]=99, [3]=24.2, [4]=21.0, [5]=17.8, [6]=14.6, [7]=11.4, [8]=8.2,  [9]=5.0,  [10]=0.5 }, uses=0, maxlevel=1},
            choppy =  {times={ [1]=99, [2]=99, [3]=99,   [4]=99,   [5]=99,   [6]=22.0, [7]=18.0, [8]=14.0, [9]=10.0, [10]=0.5 }, uses=0, maxlevel=1},
            cracky =  {times={ [1]=99, [2]=99, [3]=99,   [4]=99,   [5]=99,   [6]=99,   [7]=99,   [8]=99,   [9]=99,   [10]=99 }, uses=0, maxlevel=1}
		}
	},
	on_use = function(itemstack, user, pointed_thing)
		print("pointed_thing: " .. dump(pointed_thing))
		local type = pointed_thing.type
		if type == "node" then
			local pos = pointed_thing.under
			local meta = mt_get_meta(pos)
			local heat_progress = meta:get_float("heat_progress")
			local heat_ratio = round(heat_progress / COOK_THRESHOLD * 100, 1)
			notify(user, "heated " .. heat_ratio .. "%", 2, "message_box_1")
		else
			pickup_item(user, pointed_thing)
		end
	end,
	sound = {
		punch_use = "ss_swoosh_large_thud",
		punch_use_air = "ss_swoosh_medium"
	},
	after_use = after_use_tool
})


-- STONE AXE
minetest.override_item("default:axe_stone", {
	tool_capabilities = {
		full_punch_interval = 1.5,
		groupcaps = {
			snappy =  {times={[1]=6.5, 	[2]=5.5,  [3]=4.5, 	[4]=3.5, [5]=2.5, [6]=1.5, [7]=0.5,	[8]=0.5, [9]=0.5}, uses=18, maxlevel=1},
			crumbly = {times={[1]=11.0, [2]=10.0, [3]=9.0,	[4]=8.0, [5]=7.0, [6]=6.0, [7]=5.0,	[8]=4.0, [9]=3.0}, uses=15, maxlevel=1},
			choppy =  {times={[1]=10.0, [2]=8.0,  [3]=6.0, 	[4]=5.0, [5]=4.0, [6]=3.0, [7]=2.0,	[8]=1.0, [9]=0.5}, uses=13, maxlevel=1},
			cracky =  {times={[1]=99.0, [2]=99.0, [3]=99.0,	[4]=9.5, [5]=7.6, [6]=5.5, [7]=4.5,	[8]=3.5, [9]=2.5}, uses=1, maxlevel=1}
		}
	},
	sound = {
		punch_use_air = "ss_swoosh_medium"
	},
	range = ITEM_POINTING_RANGES["default:axe_stone"],
	after_use = after_use_tool
})


-- STONE PICKAXE
minetest.override_item("default:pick_stone", {
	tool_capabilities = {
		full_punch_interval = 2.0,
		groupcaps = {
			snappy = 	{times={[1]=9.0, 	[2]=8.0, 	[3]=7.0, 	[4]=6.0,	[5]=5.0,	[6]=4.0,	[7]=3.0,	[8]=2.0,	[9]=1.0},	uses=18, maxlevel=1},
			crumbly = 	{times={[1]=9.0, 	[2]=8.0, 	[3]=7.0,	[4]=6.0,	[5]=5.0,	[6]=4.0,	[7]=3.0,	[8]=2.0,	[9]=1.0}, 	uses=15, maxlevel=1},
			choppy = 	{times={[1]=99.0, 	[2]=12.0, 	[3]=10.0, 	[4]=8.0,	[5]=6.0,	[6]=5.0,	[7]=4.0,	[8]=3.0,	[9]=2.0},	uses=10, maxlevel=1},
			cracky = 	{times={[1]=12.0, 	[2]=10.0, 	[3]=8.0,	[4]=6.0,	[5]=5.0,	[6]=4.0,	[7]=3.0,	[8]=2.0,	[9]=1.0}, 	uses=15, maxlevel=1}
		}
	},
	range = ITEM_POINTING_RANGES["default:pick_stone"],
	sound = {
		punch_use_air = "ss_swoosh_medium"
	},
	after_use = after_use_tool
})


-- STONE SWORD
minetest.override_item("default:sword_stone", {
	tool_capabilities = {
		full_punch_interval = 1.5,
		groupcaps = {
			snappy = 	{times={[1]=6.5, 	[2]=5.5, 	[3]=4.5, 	[4]=3.5,	[5]=2.5,	[6]=1.5,	[7]=0.5,	[8]=0.5,	[9]=0.5},	uses=18, maxlevel=1},
			crumbly = 	{times={[1]=11.0, 	[2]=10.0, 	[3]=9.0,	[4]=8.0,	[5]=7.0,	[6]=6.0,	[7]=5.0,	[8]=4.0,	[9]=3.0}, 	uses=15, maxlevel=1},
			choppy = 	{times={[1]=99.0, 	[2]=12.0, 	[3]=10.0, 	[4]=8.0,	[5]=6.0,	[6]=5.0,	[7]=4.0,	[8]=3.0,	[9]=2.0},	uses=10, maxlevel=1},
			cracky = 	{times={[1]=99.0, 	[2]=99.0, 	[3]=99.0,	[4]=10.0,	[5]=8.0,	[6]=6.0,	[7]=5.0,	[8]=4.0,	[9]=3.0}, 	uses=1, maxlevel=1}
		}
	},
	range = ITEM_POINTING_RANGES["default:sword_stone"],
	sound = {
		punch_use_air = "ss_swoosh_medium"
	},
	after_use = after_use_tool
})


-- STONE SHOVEL
minetest.override_item("default:shovel_stone", {
	tool_capabilities = {
		full_punch_interval = 2.0,
		groupcaps = {
			snappy = 	{times={[1]=9.0, 	[2]=8.0, 	[3]=7.0, 	[4]=6.0,	[5]=5.0,	[6]=4.0,	[7]=3.0,	[8]=2.0,	[9]=1.0},	uses=18, maxlevel=1},
			crumbly = 	{times={[1]=7.0, 	[2]=6.0, 	[3]=5.0,	[4]=4.0,	[5]=3.0,	[6]=2.0,	[7]=1.0,	[8]=0.5,	[9]=0.5}, 	uses=15, maxlevel=1},
			choppy = 	{times={[1]=99.0, 	[2]=12.0, 	[3]=10.0, 	[4]=8.0,	[5]=6.0,	[6]=5.0,	[7]=4.0,	[8]=3.0,	[9]=2.0},	uses=10, maxlevel=1},
			cracky = 	{times={[1]=99.0, 	[2]=99.0, 	[3]=99.0,	[4]=9.5,	[5]=7.6,	[6]=5.5,	[7]=4.5,	[8]=3.5,	[9]=2.5}, 	uses=1, maxlevel=1}
		}
	},
	range = ITEM_POINTING_RANGES["default:shovel_stone"],
	sound = {
		punch_use_air = "ss_swoosh_medium"
	},
	after_use = after_use_tool
})



-- ADMIN HOE
minetest.override_item("ss:sword_admin", {
	tool_capabilities = {
		full_punch_interval = 0.5,
		groupcaps = {
			snappy = 	{times={[1]=0.5, 	[2]=0.5, 	[3]=0.5, 	[4]=0.5,	[5]=0.5,	[6]=0.5,	[7]=0.5,	[8]=0.5,	[9]=0.5},	uses=0, maxlevel=1},
			crumbly = 	{times={[1]=0.5, 	[2]=0.5, 	[3]=0.5,	[4]=0.5,	[5]=0.5,	[6]=0.5,	[7]=0.5,	[8]=0.5,	[9]=0.5}, 	uses=0, maxlevel=1},
			choppy = 	{times={[1]=0.5, 	[2]=0.5, 	[3]=0.5, 	[4]=0.5,	[5]=0.5,	[6]=0.5,	[7]=0.5,	[8]=0.5,	[9]=0.5},	uses=0, maxlevel=1},
			cracky = 	{times={[1]=0.5, 	[2]=0.5, 	[3]=0.5,	[4]=0.5,	[5]=0.5,	[6]=0.5,	[7]=0.5,	[8]=0.5,	[9]=0.5}, 	uses=0, maxlevel=1},
			oddly_breakable_by_hand = 	{times={[1]=0.5, 	[2]=0.5, 	[3]=0.5}, 	uses=0, maxlevel=1},
			dig_immediate =  			{times={[1]=0.5, 	[2]=0.5, 	[3]=0.5}, 	uses=0, maxlevel=1}
		}
	},
	sound = {
		punch_use_air = "ss_swoosh_medium"
	}
})




-- ###############################
-- ###### OTHER ADMIN TOOLS ######
-- ###############################

local default_item_spawner_item = "ss:stone"
local default_item_spawner_quantity = "1"
local default_entity_spawner_entity = "ss:zombie"

minetest.register_on_joinplayer(function(player)
    --print("  register_on_joinplayer() ADMIN.LUA")
	local player_meta = player:get_meta()

	if player_meta:get_string("item_spawner_item") == "" then
		player_meta:set_string("item_spawner_item", default_item_spawner_item)
	end

	if player_meta:get_string("item_spawner_quantity") == "" then
		player_meta:set_string("item_spawner_quantity", default_item_spawner_quantity)
	end

	if player_meta:get_string("entity_spawner_entity") == "" then
		player_meta:set_string("entity_spawner_entity", default_entity_spawner_entity)
	end
    --print("  register_on_joinplayer() end")
end)


local mob_names = {
    ["ss:boar1"] = true,
    ["ss:boar2"] = true,
    ["ss:boar3"] = true,
    ["ss:boar1_dead"] = true,
    ["ss:boar2_dead"] = true,
    ["ss:boar3_dead"] = true,
	["ss:test"] = true,
	["ss:blocky_mob"] = true,
	["ss:zombie"] = true,
	["ss:wield_item"] = true
}


-- Handle formspec fields
local flag1 = false
minetest.register_on_player_receive_fields(function(player, formname, fields)
	debug(flag1, "\nregister_on_player_receive_fields() tool_overrides.lua")
	local player_name = player:get_player_name()
	local p_data = ss.player_data[player_name]

	debug(flag1, "  p_data.formspec_mode: " .. p_data.formspec_mode)
    if p_data.formspec_mode ~= "item_sapwner" or p_data.formspec_mode ~= "mob_sapwner" then
        debug(flag1, "  interaction not from item or mob spawner formspec. NO FURTHER ACTION.")
        debug(flag1, "register_on_player_receive_fields() end " .. mt_get_gametime())
        return
    else
        debug(flag1, "  interaction from item or mob formspec. inspecting fields..")
    end

	debug(flag1, "  formname: " .. formname)


    if formname == "ss:item_spawner_form" then
		debug(flag1, "  used item spawner")
        local player_meta = player:get_meta()
        player_meta:set_string("item_spawner_item", fields.item_list)
        player_meta:set_string("item_spawner_quantity", fields.quantity_list)

		if fields.quit then
			debug(flag1, "  player quit from item_sapwner formspec")
			p_data.formspec_mode = "main_formspec"

		elseif fields.remove_all then
			debug(flag1, "  clicked on Remove All")
			local player_pos = player:get_pos()
			local all_objects = mt_get_objects_inside_radius(player_pos, 100)
			debug(flag1, "  all_objects: " .. dump(all_objects))

			for _, obj in ipairs(all_objects) do
				local lua_entity = obj:get_luaentity()
				if lua_entity and lua_entity.name == "__builtin:item" then
					obj:remove()
				end
			end
			debug(flag1, "  all items removed")

        elseif fields.save then
			player:get_meta():set_string("item_spawner_item", fields.item_list)
			debug(flag1, "  configuration saved")
		end

	elseif formname == "ss:mob_spawner_formspec" then
		debug(flag1, "  used entity spawner")

		if fields.quit then
			debug(flag1, "  player quit from mob_sapwner formspec")
			p_data.formspec_mode = "main_formspec"

		elseif fields.save and fields.mob_select then
			player:get_meta():set_string("entity_spawner_entity", fields.mob_select)
			debug(flag1, "  configuration saved")

			-- Add this line to close the formspec after saving
            mt_close_formspec(player:get_player_name(), "ss:mob_spawner_formspec")

		elseif fields.kill_all then

			local player_pos = player:get_pos()
			local found_entities = mt_get_objects_inside_radius(player_pos, 100)
			debug(flag1, "found_entities: " .. dump(found_entities))

			for _, obj in ipairs(found_entities) do
				if obj then
					local lua_entity = obj:get_luaentity()
					if lua_entity then
						local mob_name = lua_entity.name
						debug(flag1, "  mob_name: " .. mob_name)
						if mob_names[mob_name] then
							obj:remove()
							debug(flag1, "  removed " .. mob_name)
						else
							debug(flag1, "  Lua Entity not a mob")
						end
					else debug(flag1, "  ERROR: Lua Entity doesn't exist") end
				else
					debug(flag1, "  ERROR: Entity object not exist")
				end
			end
		end
	else
		debug(flag1, "  admin tool was not used")
	end

	debug(flag1, "register_on_player_receive_fields() end")
end)



minetest.override_item("ss:item_spawner", {

	-- Handle left-click action (Use item to spawn selected item)
	on_use = function(itemstack, user, pointed_thing)
		local player_meta = user:get_meta()
		local selected_item = player_meta:get_string("item_spawner_item")
		local selected_quantity = player_meta:get_string("item_spawner_quantity")

		if selected_item and selected_quantity then
			local pos = user:get_pos()
			local yaw = user:get_look_horizontal()

			-- Calculate the forward direction vector
			local dir = {
				x = -math_sin(yaw),
				y = 0,
				z = math_cos(yaw)
			}

			-- Offset the position 1 block in front of the player
			pos.x = pos.x + dir.x
			pos.z = pos.z + dir.z
			pos.y = pos.y + 1.0 -- Spawn item slightly above the player

			for i = 1, tonumber(selected_quantity) do
				mt_add_item(pos, selected_item)
			end
		end
		return itemstack -- Item is not consumed
	end,

	-- Handle right-click action (Place item to display formspec)
	on_secondary_use = function(itemstack, user, pointed_thing)
		local player_name = user:get_player_name()
		local player_meta = user:get_meta()

		local p_data = ss.player_data[player_name]
		p_data.formspec_mode = "item_spawner"

		-- Retrieve selections from player metadata
		local selected_item = player_meta:get_string("item_spawner_item")
		local selected_quantity = player_meta:get_string("item_spawner_quantity")

		-- Generate list of all registered items
		local items_list = {}
		for item, _ in pairs(mt_registered_items) do
			table_insert(items_list, item)
		end
		table_sort(items_list)

		-- Find the index of the currently selected item
		local selected_item_index = 1
		for i, item in ipairs(items_list) do
			if item == selected_item then
				selected_item_index = i
				break
			end
		end

		-- Define the formspec
		local formspec = "formspec_version[4]"
		formspec = formspec .. "size[8,4]"
		formspec = formspec .. "label[0.3,0.5;Item]"
		formspec = formspec .. "label[6.0,0.5;Quantity]"
		formspec = formspec .. "dropdown[0.3,1;5.5,0.6;item_list;" .. table_concat(items_list, ",") .. ";" .. selected_item_index .. "]"
		formspec = formspec .. "dropdown[6.0,1;1.5,0.6;quantity_list;1,5,10;" .. (selected_quantity == "1" and "1" or selected_quantity == "5" and "2" or "3") .. "]"
		formspec = formspec .. "button_exit[2,2.5;2,1;save;Save]"
		formspec = formspec .. "button[4.5,2.5;2,1;remove_all;Remove All]"

		-- Show the formspec to the player
		mt_show_formspec(player_name, "ss:item_spawner", formspec)
		return itemstack
	end
})



local function show_formspec(user)
    local entities = {
		"ss:boar1",
		"ss:boar2",
		"ss:boar3",
		"ss:test",
		"ss:blocky_mob",
		"ss:zombie"
	}

	    -- Get the currently selected entity from player metadata
    local selected_entity = user:get_meta():get_string("entity_spawner_entity")
    local selected_idx = 1  -- Default index if not found
    for i, name in ipairs(entities) do
        if name == selected_entity then
            selected_idx = i
            break
        end
    end

    local formspec = "formspec_version[4]size[7,4]" ..
		"label[0.5,0.5;Select Mob]" ..
		"dropdown[0.5,1.0;6;mob_select;" .. table_concat(entities, ",") .. ";" .. selected_idx .. "]" ..
		"button[0.5,2.5;3,1;save;Save]" ..
		"button[3.5,2.5;3,1;kill_all;Kill All]"
    mt_show_formspec(user:get_player_name(), "ss:mob_spawner", formspec)
end

local function get_look_ahead_pos(player, distance)
    local player_pos = player:get_pos()
    local eye_height = player:get_properties().eye_height or 1.625  -- Default eye height
    local player_yaw = player:get_look_horizontal()
    local player_pitch = player:get_look_vertical()

    -- Calculate the direction vector
    local dir_x = -math_sin(player_yaw) * math_cos(player_pitch)
    local dir_y = -math_sin(player_pitch)
    local dir_z = math_cos(player_yaw) * math_cos(player_pitch)

    -- Adjust for player's eye height
    player_pos.y = player_pos.y + eye_height

    -- Calculate the target position
    local target_pos = {
        x = player_pos.x + dir_x * distance,
        y = player_pos.y + dir_y * distance,
        z = player_pos.z + dir_z * distance
    }

    return target_pos
end


minetest.override_item("ss:mob_spawner", {
	on_use = function(itemstack, user, pointed_thing)
        local pos = get_look_ahead_pos(user, 3)
        local entity_to_spawn = user:get_meta():get_string("entity_spawner_entity")
        local spawned_mob = mt_add_entity(pos, entity_to_spawn)

        -- spawn with a random facing direction (yaw)
        if spawned_mob then
            local random_yaw = math_random() * 2 * math_pi
            spawned_mob:set_yaw(random_yaw)
        end
        return itemstack
    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
		local player_name = user:get_player_name()
		local p_data = ss.player_data[player_name]
		p_data.formspec_mode = "mob_spawner"
		show_formspec(user)
	end
})


minetest.register_entity("ss:player_dummy", {
    -- Basic entity properties
    hp_max = 20,
    physical = true,
    collisionbox = {-0.3, -0.1, -0.10, 0.2, 0.3, 1.60},  -- Adjusted for lying position
    visual = "mesh",
    visual_size = {x = 1, y = 1},
    mesh = "character.b3d",
    textures = {"character.png"}, -- This should be the player's texture
    makes_footstep_sound = false,
    static_save = false,

    -- Make it static (no movement, no rotation)
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        self.object:set_rotation({x = -math_pi / 2, y = 0, z = 0}) -- Rotate to lie flat
    end,
    on_rightclick = function(self, clicker)
        if clicker and clicker:is_player() then
            -- Example action: print a message to the player who clicked
            print("  searching corpse...")
        end
    end,
})


local function add_dummy(player)
    if not player or not player:is_player() then return end

    local pos = player:get_pos()
    local direction = mt_yaw_to_dir(player:get_look_horizontal())

    -- Calculate new position 3 blocks away from the player
    local new_pos = vector_add(pos, vector.multiply(direction, 3))

    -- Spawn the dummy entity
    mt_add_entity(new_pos, "ss:player_dummy")
end

