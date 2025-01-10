print("- loading node_overrides.lua")

-- cache global functions for faster access
local math_pi = math.pi
local vector_distance = vector.distance
local mt_get_node = minetest.get_node
local mt_dig_node = minetest.dig_node
local mt_remove_node = minetest.remove_node
local mt_add_entity = minetest.add_entity
local mt_get_pointed_thing_position = minetest.get_pointed_thing_position
local mt_sound_play = minetest.sound_play
local debug = ss.debug
local notify = ss.notify
local set_stat = ss.set_stat
local update_fs_weight = ss.update_fs_weight
local get_itemstack_weight = ss.get_itemstack_weight
local add_item_to_itemdrop_bag = ss.add_item_to_itemdrop_bag
local is_variable_height_node_supportive = ss.is_variable_height_node_supportive

local NODE_NAMES_SOLID_CUBE = ss.NODE_NAMES_SOLID_CUBE
local NODE_NAMES_SOLID_VARIABLE_HEIGHT = ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT
local NODE_NAMES_GAPPY_ALL = ss.NODE_NAMES_GAPPY_ALL
local NODE_NAMES_NONSOLID_ALL = ss.NODE_NAMES_NONSOLID_ALL
local NODE_DROPS_FLATTENED = ss.NODE_DROPS_FLATTENED
local ITEM_POINTING_RANGES = ss.ITEM_POINTING_RANGES
local ITEM_SOUNDS_INV = ss.ITEM_SOUNDS_INV



-- ############################################## --
-- ######### Individual Node Overrides ########## --
-- ############################################## --


--[[
Note: Custom pointing ranges for 'default:' nodes are applied below. Custom
pointing ranges for 'ss:' nodes are unnecessary since these nodes will only drop
'ss:' craftitems, and not the node item themselves. All craftitems are registered
via global_vars_init.lua, with their custom pointing ranges already applied.
--]]

local NODE_NAMES = {
	"default:ladder_wood",
	"default:ladder_steel",
	"default:fence_wood",
	"default:sign_wall_wood",
	"default:sign_wall_steel",
	"default:dirt",
	"default:tree",
	"default:leaves",
	"default:blueberry_bush_leaves_with_berries",
	"default:papyrus",
	"default:sapling",
	"default:acacia_sapling",
	"default:junglesapling",
	"default:emergent_jungle_sapling",
	"default:pine_sapling",
	"default:aspen_sapling",
	"default:bush_sapling",
	"default:acacia_bush_sapling",
	"default:pine_bush_sapling",
	"default:blueberry_bush_sapling",
	"default:large_cactus_seedling"
}

for i = 1, #NODE_NAMES do
	local node_name = NODE_NAMES[i]
	minetest.override_item(node_name, {
		range = ITEM_POINTING_RANGES[node_name]
	})
end



-- use custom icon images for default wooden fence
minetest.override_item("default:fence_wood", {
	inventory_image = "ss_fence_wood.png",
	wield_image = "ss_fence_wood.png"
})


-- use custom icon images for default torch
minetest.override_item("default:torch", {
	inventory_image = "ss_torch.png",
	wield_image = "ss_torch.png"
})


-- STONE 
minetest.override_item("ss:stone", {
    drawtype = "mesh",
    tiles = { "ss_stone_node.png" },
	mesh = "ss_stone.obj",
	wield_image = "ss_stone.png",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {dig_immediate=3, attached_node = 3},
	selection_box = {
		type = "fixed",
		fixed = {-0.15, -0.50, -0.15, 0.15, -0.40, 0.15}
			 -- {rght,   botm,  back, lft,   top,  frnt}
	},
	collision_box = {
		type = "fixed",
		fixed = {-0.15, -0.50, -0.15, 0.15, -0.40, 0.15}
			-- {rght, botm, back, lft,  top, frnt}
	},
    sounds = {
        dug = "ss_break_stone",
		place = ITEM_SOUNDS_INV["ss:stone"]
    },
	drop = "ss:stone",
	floodable = true,
	on_flood = function(pos, oldnode, newnode)
		minetest.add_item(pos, ItemStack("ss:stone"))
	end,
	on_punch = function(pos, node, puncher, pointed_thing)
		mt_dig_node(pos, puncher)
		mt_sound_play("ss_break_stone", {
			object = puncher,
			max_hear_distance = 10
		}, true)
	end
})


-- STICK
minetest.override_item("ss:stick", {
    drawtype = "mesh",
    tiles = { "ss_stick_node.png" },
	mesh = "ss_stick.obj",
	wield_image = "ss_stick.png",
	paramtype = "light",
	paramtype2 = "facedir",
	groups = {dig_immediate=3, attached_node = 1, enFuel_3 = 1, stick = 1},
	selection_box = {
		type = "fixed",
		fixed = {-0.45, -0.50, -0.15, 0.45, -0.45, 0.15}
			 -- {rght,  botm,  back,  lft,  top,  frnt}
	},
	collision_box = {
		type = "fixed",
		fixed = {-0.25, -0.50, -0.35, 0.40, -0.45, -0.15}
			-- {rght, botm, back, lft,  top, frnt}
	},
    sounds = {
        dug = "ss_inv_wood",
		place = ITEM_SOUNDS_INV["ss:stick"]
    },
	drop = "ss:stick",
	floodable = true,
	on_flood = function(pos, oldnode, newnode)
		minetest.add_item(pos, ItemStack("ss:stick"))
	end,
	on_punch = function(pos, node, puncher, pointed_thing)
		mt_dig_node(pos, puncher)
		mt_sound_play("ss_inv_wood", {
			object = puncher,
			max_hear_distance = 10
		}, true)
	end
})


-- BOULDER
--[[
minetest.register_node("ss:boulder", {
	description = "Boulder",
    drawtype = "mesh",
    tiles = { "ss_boulder.png" },
	mesh = "ss_boulder.obj",
	paramtype = "light", 		
	paramtype2 = "facedir", 	
	groups = {oddly_breakable_by_hand=1},
	drop = "ss:stone 6",
	selection_box = {
		type = "fixed",
		fixed = {-0.45, -0.50, -0.45, 0.45, -0.10, 0.45}
	},
	collision_box = {
		type = "fixed",
		fixed = {-0.45, -0.50, -0.45, 0.45, -0.10, 0.45}
	},

})
--]]

-- WOOD FRAME
--[[
minetest.register_node("ss:wall_wood_half_frame", {
	description = "Wood Wall Frame (0.5m)",
    drawtype = "mesh",
    tiles = { "ss_color_gray.png" },
	mesh = "ss_wall_wood_half_frame.obj",
	paramtype = "light", 		
	paramtype2 = "facedir", 	
	range = newRangeValue,
	groups = {dig_immediate=3},
	drop = "ss:wood_plank 2",
	selection_box = {
		type = "fixed",
		fixed = {-0.50, -0.50, -0.0, 0.50, 0.50, 0.50}
	},
	collision_box = {
		type = "fixed",
		fixed = {-0.50, -0.50, -0.0, 0.50, 0.50, 0.50}
	},
	buildable_to = true
})
--]]


--[[ ##### Storage Bags ##### --]]

minetest.override_item("ss:bag_fiber_small", {
    drawtype = "plantlike",
    tiles = { "ss_bag_fiber_small_node.png" },
	sunlight_propagates = true,
	floodable = true,
	walkable = false,
	collision_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, -0.10, 0.25},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, -0.10, 0.25},
	},
	wield_image = "ss_bag_fiber_small.png",
	groups = {snappy = 9, attached_node = 3, en_bag = 1},
	drop = "",
	sounds = default.node_sound_leaves_defaults()
})

minetest.override_item("ss:bag_fiber_medium", {
    drawtype = "plantlike",
    tiles = { "ss_bag_fiber_medium_node.png" },
	sunlight_propagates = true,
	floodable = true,
	walkable = false,
	collision_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
	},
	wield_image = "ss_bag_fiber_medium.png",
	groups = {snappy = 9, attached_node = 3, en_bag = 1},
	drop = "",
	sounds = default.node_sound_leaves_defaults()
})

minetest.override_item("ss:bag_fiber_large", {
    drawtype = "plantlike",
    tiles = { "ss_bag_fiber_large_node.png" },
	sunlight_propagates = true,
	floodable = true,
	walkable = false,
	collision_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.20, 0.25},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.20, 0.25},
	},
	wield_image = "ss_bag_fiber_large.png",
	groups = {snappy = 9, attached_node = 3, en_bag = 1},
	drop = "",
	sounds = default.node_sound_leaves_defaults()
})

minetest.override_item("ss:bag_cloth_small", {
    drawtype = "plantlike",
    tiles = { "ss_bag_cloth_small_node.png" },
	sunlight_propagates = true,
	floodable = true,
	walkable = false,
	collision_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, -0.10, 0.25},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, -0.10, 0.25},
	},
	wield_image = "ss_bag_cloth_small.png",
	groups = {snappy = 9, attached_node = 3, en_bag = 1},
	drop = "",
	sounds = default.node_sound_leaves_defaults()
})

minetest.override_item("ss:bag_cloth_medium", {
    drawtype = "plantlike",
    tiles = { "ss_bag_cloth_medium_node.png" },
	sunlight_propagates = true,
	floodable = true,
	walkable = false,
	collision_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.1, 0.25},
	},
	wield_image = "ss_bag_cloth_medium.png",
	groups = {snappy = 9, attached_node = 3, en_bag = 1},
	drop = "",
	sounds = default.node_sound_leaves_defaults()
})

minetest.override_item("ss:bag_cloth_large", {
    drawtype = "plantlike",
    tiles = { "ss_bag_cloth_large_node.png" },
	sunlight_propagates = true,
	floodable = true,
	walkable = false,
	collision_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.20, 0.25},
	},
	selection_box = {
		type = "fixed",
		fixed = {-0.25, -0.5, -0.25, 0.25, 0.20, 0.25},
	},
	wield_image = "ss_bag_cloth_large.png",
	groups = {snappy = 9, attached_node = 3, en_bag = 1},
	drop = "",
	sounds = default.node_sound_leaves_defaults()
})




--[[ ##### Campfires #####

There are four types of campfires, each representing a specific operational state:
new (unlit), burning (lit), used (unlit), and spent (unlit). These campfire nodes
are registered here first with just the basic properties, without implementation of
their custom node functions.

This way, the campfire nodes will exist within the minetest 'registered_nodes' and
'registered_items' tables for other mod functions to access their basic properties
like description, drawtype, groups, walkable, etc. 

Then 'cooking_stations.lua' will override these campfire nodes with the custom node
functions to ensure the full campfire behavior. -]]

local campfire_box = {
	type = "fixed",
	fixed = {-0.25, -0.5, -0.25, 0.25, 0.0, 0.25},
}

local campfire_box_spent = {
	type = "fixed",
	fixed = {-0.25, -0.5, -0.25, 0.25, -0.20, 0.25},
}

minetest.override_item("ss:campfire_small_new", {
	drawtype = "plantlike",
    tiles = {"ss_campfire_small_new.png"},
	paramtype = "light",
	sunlight_propagates = true,
	floodable = true,
	collision_box = campfire_box,
	selection_box = campfire_box,
	wield_image = "ss_campfire_small_inv.png",
	groups = {snappy = 9, attached_node = 3},
	drop = "",
	sounds = default.node_sound_wood_defaults()
})

minetest.override_item("ss:campfire_small_burning", {
	drawtype = "plantlike",
    tiles = {"ss_campfire_small_burning.png"},
	paramtype = "light",
	sunlight_propagates = true,
	floodable = true,
	light_source = 6,
	walkable = true,
	collision_box = campfire_box,
	selection_box = campfire_box,
	wield_image = "ss_campfire_small_burning.png",
	damage_per_second = 5,
	groups = {snappy = 9, attached_node = 3},
	drop = "",
	sounds = default.node_sound_wood_defaults()
})

minetest.override_item("ss:campfire_small_used", {
	drawtype = "plantlike",
    tiles = {"ss_campfire_small_used.png"},
	paramtype = "light",
	sunlight_propagates = true,
	floodable = true,
	walkable = true,
	collision_box = campfire_box,
	selection_box = campfire_box,
	wield_image = "ss_campfire_small_used.png",
	groups = {snappy = 9, attached_node = 3},
	drop = "",
	sounds = default.node_sound_wood_defaults()
})

minetest.override_item("ss:campfire_small_spent", {
	drawtype = "plantlike",
    tiles = {"ss_campfire_small_spent.png"},
	paramtype = "light",
	sunlight_propagates = true,
	floodable = true,
	walkable = true,
	collision_box = campfire_box_spent,
	selection_box = campfire_box_spent,
	wield_image = "ss_campfire_small_spent.png",
	groups = {snappy = 9, attached_node = 3},
	drop = "",
	sounds = default.node_sound_wood_defaults()
})

--[[ ##### Itemgrop Bags #####

There are three types of itemdrop bags, one that spawn on land, another for spawning
under water, and the third that only spawns if no available or diggable node is found.
These bag nodes are registered here first with just the basic properties, without
implementation of their custom node functions.

This way, these bag nodes will exist within the minetest 'registered_nodes' and
'registered_items' tables for other mod functions to access their basic properties
like description, drawtype, groups, walkable, etc. 

Then 'itemdrop_bag.lua' will override these bag nodes further with the custom node
functions to ensure the full bag behavior. -]]

-- on land
minetest.override_item("ss:itemdrop_bag", {
	drawtype = "plantlike",
    tiles = {"ss_itemdrop_bag.png"},
	sunlight_propagates = true,
	floodable = true,
	walkable = false,
	selection_box = {
		type = "fixed",
		fixed = {-0.20, -0.5, -0.20, 0.20, -0.10, 0.20}
	},
	groups = {snappy = 9, attached_node = 3},
	sounds = default.node_sound_leaves_defaults(),
	drop = "",
})

-- underwater
minetest.override_item("ss:itemdrop_bag_in_water", {
	drawtype = "plantlike_rooted",
    tiles = {"ss_itemdrop_bag_dirt.png"},
	special_tiles = {{name = "ss_itemdrop_bag.png"}},
	sunlight_propagates = true,
	floodable = false,
	walkable = true,
	selection_box = {
		type = "fixed",
		fixed = {
				{-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
				{-4/16, 0.5, -4/16, 4/16, 1.0, 4/16},
		},
	},
	groups = {snappy = 9},
	sounds = default.node_sound_leaves_defaults(),
	drop = "",
})

-- when no available pos is nearby
minetest.override_item("ss:itemdrop_box", {
	tiles = {
		"ss_itemdrop_box_top.png",
		"ss_itemdrop_box_bottom.png",
		"ss_itemdrop_box_side_1.png",
		"ss_itemdrop_box_side_3.png",
		"ss_itemdrop_box_side_2.png",
		"ss_itemdrop_box_side_2.png"
	},
	paramtype2 = "4dir",
	groups = {snappy = 9},
	sounds = default.node_sound_leaves_defaults(),
	drop = "",
})




-- ##### MAKE SNOWBALLS THROWABLE #####

local snow_groups = minetest.registered_items["default:snow"].groups
snow_groups.crumbly = 9
minetest.override_item("default:snow", {
	inventory_image = "ss_snowball.png",
	wield_image = "ss_snowball.png",
    groups = snow_groups,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type ~= "nothing" then
			local pointed = mt_get_pointed_thing_position(pointed_thing)
			if vector_distance(user:getpos(), pointed) < 8 then
				return itemstack
			end
		end
		local pos = user:get_pos()
		local dir = user:get_look_dir()
		local yaw = user:get_look_horizontal()
		if pos and dir then
			pos.y = pos.y + 1.5
			local object = mt_add_entity(pos, "ss:ammo_snowball")
			if object then
				object:set_velocity({x=dir.x * 25, y=dir.y * 25, z=dir.z * 25})
				object:set_acceleration({x=dir.x * -5, y=-20, z=dir.z * -5})
				object:set_yaw(yaw + math_pi)
				local entity = object:get_luaentity()
				if entity then
					entity.player = entity.player or user
				end
			end
		end
        itemstack:take_item()
        local player_meta = user:get_meta()
        local weight = get_itemstack_weight(ItemStack("default:snow"))
        set_stat(user, player_meta, "weight", "down", weight)
        update_fs_weight(user, player_meta)
		return itemstack
	end,
    drop = {
		items = {
			{ items = {"default:snow 2"}, },
            { items = {"default:snow 1"}, rarity = 2 },
			{ items = {"ss:stone"}, rarity = 15, },
		}
	}
})

-- SNOWBALL ITEM ENTITY
minetest.register_entity("ss:ammo_snowball", {
	initial_properties = {
		physical = false,
		visual = "sprite",
		visual_size = {x=1.0, y=1.0,},
		textures = {"ss_snowball.png"},
		collisionbox = {0, 0, 0, 0, 0, 0}
	}
})









-- ############################################ --
-- ######### Multiple Node Overrides ########## --
-- ############################################ --


-- Define custom flower nodes for use by player instead of using flower nodes from
-- default "flowers" mod
local nodeNames = {
	"rose", "tulip", "dandelion_yellow", "chrysanthemum_green",
	"geranium", "viola", "dandelion_white", "tulip_black"
}
local flower_selection_boxes = {
	{-2 / 16, -0.5, -2 / 16, 2 / 16, 5 / 16, 2 / 16},
	{-2 / 16, -0.5, -2 / 16, 2 / 16, 3 / 16, 2 / 16},
	{-4 / 16, -0.5, -4 / 16, 4 / 16, -2 / 16, 4 / 16},
	{-4 / 16, -0.5, -4 / 16, 4 / 16, -1 / 16, 4 / 16},
	{-2 / 16, -0.5, -2 / 16, 2 / 16, 2 / 16, 2 / 16},
	{-5 / 16, -0.5, -5 / 16, 5 / 16, -1 / 16, 5 / 16},
	{-5 / 16, -0.5, -5 / 16, 5 / 16, -2 / 16, 5 / 16},
	{-2 / 16, -0.5, -2 / 16, 2 / 16, 3 / 16, 2 / 16}
}
for i, flower_name in ipairs(nodeNames) do
	minetest.override_item("ss:flower_" .. flower_name, {
		drawtype = "plantlike",
		waving = 1,
		tiles = {"ss_flower_" .. flower_name .. ".png"},
		sunlight_propagates = true,
		paramtype = "light",
		groups = {flower = 1, flora = 1, attached_node = 1, flammable = 1},
		sounds = default.node_sound_leaves_defaults(),
		selection_box = {
			type = "fixed",
			fixed = flower_selection_boxes[i]
		}
	})
end



-- make movement in water slower
for i, node_name in ipairs({"water_source", "water_flowing", "river_water_source", "river_water_flowing"}) do
	minetest.override_item("default:" .. node_name, { 
		move_resistance = 2,
	})
end


-- DISALLOW NODE PLACEMENT ON LARGER GRASS AND PLANTS
-- if this list is modified, also update node_drops_flattened.txt
local LARGER_PLANTLIFE_NODE_NAMES = {
	"default:grass_4",
	"default:grass_5",
	"default:grass_4",
	"default:grass_5",
	"default:dry_grass_4",
	"default:dry_grass_5",
	"default:dry_grass_4",
	"default:dry_grass_5",
	"default:dry_shrub",
	"default:fern_2",
	"default:fern_3",
	"default:junglegrass",
	"default:marram_grass_2",
	"default:marram_grass_3",
	"farming:cotton_5",
	"farming:cotton_6",
	"farming:cotton_7",
	"farming:cotton_8",
	"farming:cotton_wild",
	"farming:wheat_5",
	"farming:wheat_6",
	"farming:wheat_7",
	"farming:wheat_8",
	"flowers:waterlily",
	"flowers:waterlily_waving"
}
for i, node_name in ipairs(LARGER_PLANTLIFE_NODE_NAMES) do
	minetest.override_item(node_name, { buildable_to = false })
end


local DONOT_OVERRIDE_NODES = {

	-- can be place above nonsolid or gappy nodes
	["default:torch_wall"] = true,
	["default:torch_ceiling"] = true,

	-- player will never handle these nodes
	ignore = true,
	air = true,
	["default:cloud"] = true,

	-- deal with later :)
	["default:water_source"] = true,
    ["default:water_flowing"] = true,
    ["default:river_water_source"] = true,
    ["default:river_water_flowing"] = true,
	["default:lava_source"] = true,
    ["default:lava_flowing"] = true,

	-- storage bags and campfires already have custom after_place_node that handles
	-- the placement checks (via custom on_construct) and inventory weight reduction
	--[[
	["ss:bag_fiber_small"] = true,
    ["ss:bag_fiber_medium"] = true,
    ["ss:bag_fiber_large"] = true,
    ["ss:bag_cloth_small"] = true,
    ["ss:bag_cloth_medium"] = true,
    ["ss:bag_cloth_large"] = true,
	["ss:campfire_small_new"] = true,
	["ss:campfire_small_burning"] = true,
	["ss:campfire_small_used"] = true,
	["ss:campfire_small_spent"] = true,
	--]]
}

-- override after_place_node() on all nodes to check the node below to determine
-- if it can support the placed node. if so, reduce the player's inventory weight
-- of the placed node.

-- ensure that a node cannot be placed above a non-solid node, like many plants
-- or small gappy nodes. if node CAN be place, ensure to reduce the player's
-- inventory weight.

local flag1 = false
debug(flag1, "Overriding after_place_node() for nodes..")
for node_name in pairs(minetest.registered_nodes) do
	debug(flag1, "  node_name: " .. node_name)
	if DONOT_OVERRIDE_NODES[node_name] then
		debug(flag1, "    node excluded from override")
	else
		minetest.override_item(node_name, { after_place_node = function(pos, player, item, pointed_thing)
			debug(flag1, "\nafter_place_node() node_overrides.lua")
			--debug(flag12, "  pos: " .. minetest.pos_to_string(pos))

			local node = mt_get_node(pos)
			debug(flag1, "  node.name: " .. node.name)

			-- node has been placed at 'pos'. check if node below can visually support it
			local bottom_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
			local bottom_node = mt_get_node(bottom_pos)
			local bottom_node_name = bottom_node.name
			debug(flag1, "  node name at bottom pos: " .. bottom_node_name)

			local is_bottom_supportive = false
			if NODE_NAMES_SOLID_CUBE[bottom_node_name] then
				debug(flag1, "  node is fully solid. node placement allowed.")
				is_bottom_supportive = true
			elseif NODE_NAMES_SOLID_VARIABLE_HEIGHT[bottom_node_name] then
				debug(flag1, "  this is likely stairs or slab. inspecting further..")
				is_bottom_supportive = is_variable_height_node_supportive(bottom_node, bottom_node_name)
			elseif NODE_NAMES_GAPPY_ALL[bottom_node_name] then
				debug(flag1, "  node is gappy. cannot place node above.")
			elseif NODE_NAMES_NONSOLID_ALL[bottom_node_name] then
			debug(flag1, "  node is not solid. cannot place node above.")
			else
				debug(flag1, "  ERROR - Unhandled bottom_node_name: " .. bottom_node_name)
			end

			if is_bottom_supportive then
				debug(flag1, "  reducing inventory weight..")
				local player_meta = player:get_meta()
				local item_name = item:get_name()

				-- extract only one item from the stack since player only letting go of
				-- one quantity of the item from inventory
				item = ItemStack(item_name)
				debug(flag1, "  item name: " .. item_name)

				-- reduce player's inventory weight after placing the node
				local weight = get_itemstack_weight(item)
				--debug(flag12, "  weight: " .. weight)
				ss.set_stat(player, player_meta, "weight", "down", weight)
				ss.update_fs_weight(player, player_meta)

			else
				debug(flag1, "  below is NOT a supportive node. node placement prevented.")
				notify(player,"Cannot be placed there", 3, "message_box_2")
				mt_remove_node(pos)
			end

			debug(flag1, "after_place_node() END")
			return not is_bottom_supportive
		end })
		debug(flag1, "    node after_place_node() overrided")
	end
end
debug(flag1, "Overriding done.")


local flag2 = false
-- ensure when a node is dug by a player, falls as a falling block, or replaced
-- by another node, that its drop item (if any) is handled properly. this is done
-- by overriding the 'after_destruct' function. Note: in the default minetest game,
-- leaf nodes also have custom 'after_destruct' code to handle leaf decay. the
-- override code below will not impact leaf nodes since they are not included in
-- the NODE_DROPS_FLATTENED table.
for node_name, item_drop in pairs(NODE_DROPS_FLATTENED) do
	minetest.override_item(node_name, {
		after_destruct = function(pos, oldnode)
			local prev_node_name = oldnode.name
			debug(flag2, "\n### after_destruct() for " .. prev_node_name)
			debug(flag2, "  pos: " .. minetest.pos_to_string(pos))
			local node = minetest.get_node(pos)
			local nodename = node.name
			debug(flag2, "  curr nodename at pos: " .. nodename)
			if nodename == "air" then
				debug(flag2, "  " .. prev_node_name .. " got dug up or fell")
			elseif ss.NODE_NAMES_WATER[nodename] then
				debug(flag2, "  " .. prev_node_name .. " got flooded by water")
			elseif ss.NODE_NAMES_LAVA[nodename] then
				debug(flag2, "  " .. prev_node_name .. " got destroyed by lava")
			elseif ss.ITEMDROP_BAGS_ALL[nodename] then
				debug(flag2, "  " .. prev_node_name .. " got flattened by an itemdrop bag")
				add_item_to_itemdrop_bag(pos, item_drop)
			else
				debug(flag2, "  " .. prev_node_name .. " got flattened by " .. nodename)
				minetest.add_item(pos, item_drop)
			end
			debug(flag2, "after_destruct() END")
		end
	})
end
