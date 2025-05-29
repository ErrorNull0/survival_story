print("- loading tool_overrides.lua")
-- cache global functions and variables for faster access
local table_copy = table.copy
local table_remove = table.remove
local mt_get_meta = core.get_meta
local mt_add_item = core.add_item
local debug = ss.debug
local round = ss.round
local get_itemstack_weight = ss.get_itemstack_weight
local play_sound = ss.play_sound
local do_stat_update_action = ss.do_stat_update_action
local update_fs_weight = ss.update_fs_weight
local notify = ss.notify
local pickup_item = ss.pickup_item

local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local COOK_THRESHOLD = ss.COOK_THRESHOLD
local ITEM_DESTRUCT_PATH = ss.ITEM_DESTRUCT_PATH
local ITEM_POINTING_RANGES = ss.ITEM_POINTING_RANGES
local POINTING_RANGE_DEFAULT = ss.POINTING_RANGE_DEFAULT


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



local flag3 = false
-- alter tool wear mechansim so it also includes deducting the weight of the destroyed
-- tool from the player's total inventory weight
local after_use_tool = function(itemstack, user, node, digparams)
    debug(flag3, "### after_use_tool() TOOLS")
    local item_name = itemstack:get_name()
	local tool_wear_value = itemstack:get_wear()
	local wear_received = digparams.wear
	--wear_received = 10000  -- for testing purposes

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
			play_sound("item_break", {item_name = item_name, pos = user:get_pos()})

			local weight_change
			local broken_items = ITEM_DESTRUCT_PATH[item_name]
			debug(flag3, "    broken_items: " .. dump(broken_items))
			if broken_items then
				debug(flag3, "    resulted in scrap items")

				-- replace wielded tool with main scrap item
				local broken_items_copy = table_copy(broken_items)
				local wield_item_name = table_remove(broken_items_copy, 1)
				debug(flag3, "    scrap wield_item_name: " .. wield_item_name)
				itemstack = ItemStack(wield_item_name)

				-- drop to ground any additional scrap items
				local extra_broken_item_count = 0
				for i, broken_item_name in ipairs(broken_items_copy) do
					debug(flag3, "    extra broken_item_name: " .. broken_item_name)
					mt_add_item(user:get_pos(), ItemStack(broken_item_name))
					extra_broken_item_count = extra_broken_item_count + 1
				end

				if extra_broken_item_count > 0 then
					notify(user, "inventory", "Tool broke. Scraps dropped to ground.", 3, 0.5, 0, 2)
				else
					notify(user, "inventory", "Tool broke", 2, 0.5, 0, 2)
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
				notify(user, "inventory", "Tool broke", 2, 0.5, 0, 2)

				-- assuming the original tool being wielded never has itemstack
				-- quantity greater than 1
				weight_change = ITEM_WEIGHTS[item_name]
			end

			local p_data = ss.player_data[user:get_player_name()]
			do_stat_update_action(user, p_data, player_meta, "normal", "weight", -weight_change, "curr", "add", true)

			update_fs_weight(user, player_meta)

		end
	end

    debug(flag3, "### after_use_tool() end")
    return itemstack
end


-- HANDS
core.override_item("", {
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
core.override_item("ss:stone_sharpened", {
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
core.override_item("ss:hammer_wood", {
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
		--print("pointed_thing: " .. dump(pointed_thing))
		local type = pointed_thing.type
		if type == "node" then
			local pos = pointed_thing.under
			local meta = mt_get_meta(pos)
			local heat_progress = meta:get_float("heat_progress")
			local heat_ratio = round(heat_progress / COOK_THRESHOLD * 100, 1)
			local text = "heated  " .. core.get_color_escape_sequence("yellow") .. heat_ratio .. "%"

			notify(user, "hammer", text, 2, 0.5, 0, 2)
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
core.override_item("default:axe_stone", {
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
core.override_item("default:pick_stone", {
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
core.override_item("default:sword_stone", {
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
core.override_item("default:shovel_stone", {
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
core.override_item("ss:sword_admin", {
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

