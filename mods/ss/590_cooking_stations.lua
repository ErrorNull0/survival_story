print("- loading cooking_stations.lua")

-- cache global functions for faster access
local math_ceil = math.ceil
local math_random = math.random
local math_floor = math.floor
local string_gmatch = string.gmatch
local string_format = string.format
local string_split = string.split
local table_insert = table.insert
local table_concat = table.concat
local table_remove = table.remove
local table_sort = table.sort
local vector_add = vector.add
local mt_pos_to_string = core.pos_to_string
local mt_get_gametime = core.get_gametime
local mt_get_player_by_name = core.get_player_by_name
local mt_show_formspec = core.show_formspec
local mt_add_item = core.add_item
local mt_get_node = core.get_node
local mt_set_node = core.set_node
local mt_remove_node = core.remove_node
local mt_swap_node = core.swap_node
local mt_check_for_falling = core.check_for_falling
local mt_get_meta = core.get_meta
local mt_get_node_timer = core.get_node_timer
local mt_hash_node_position = core.hash_node_position
local mt_add_particlespawner = core.add_particlespawner
local mt_delete_particlespawner = core.delete_particlespawner
local mt_after = core.after
local mt_serialize = core.serialize
local debug = ss.debug
local get_fs_weight = ss.get_fs_weight
local build_fs = ss.build_fs
local do_stat_update_action = ss.do_stat_update_action
local round = ss.round
local pos_to_key = ss.pos_to_key
local key_to_pos = ss.key_to_pos
local notify = ss.notify
local play_sound = ss.play_sound
local player_control_fix = ss.player_control_fix
local get_item_burn_time = ss.get_item_burn_time
local get_itemstack_weight = ss.get_itemstack_weight
local exceeds_inv_weight_max = ss.exceeds_inv_weight_max
local drop_all_items = ss.drop_all_items
local remove_formspec_viewer = ss.remove_formspec_viewer
local remove_formspec_all_viewers = ss.remove_formspec_all_viewers
local is_variable_height_node_supportive = ss.is_variable_height_node_supportive
local update_fs_weight = ss.update_fs_weight
local update_crafting_ingred_and_grid = ss.update_crafting_ingred_and_grid
local update_meta_and_description = ss.update_meta_and_description
local refresh_meta_and_description = ss.refresh_meta_and_description

-- cache global variables for faster access+
local CAMPFIRE_NODE_NAMES = ss.CAMPFIRE_NODE_NAMES
local CAMPFIRE_STAND_NAMES = ss.CAMPFIRE_STAND_NAMES
local CAMPFIRE_GRILL_NAMES = ss.CAMPFIRE_GRILL_NAMES
local FIRE_STARTER_NAMES = ss.FIRE_STARTER_NAMES
local NODE_NAMES_SOLID_CUBE = ss.NODE_NAMES_SOLID_CUBE
local NODE_NAMES_SOLID_VARIABLE_HEIGHT = ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT
local BAG_NODE_NAMES_ALL = ss.BAG_NODE_NAMES_ALL
local SPILLABLE_ITEM_NAMES = ss.SPILLABLE_ITEM_NAMES
local COOK_THRESHOLD = ss.COOK_THRESHOLD
local ITEM_HEAT_RATES = ss.ITEM_HEAT_RATES
local ITEM_BURN_TIMES = ss.ITEM_BURN_TIMES
local ITEM_MAX_USES = ss.ITEM_MAX_USES
local WEAR_VALUE_MAX = ss.WEAR_VALUE_MAX
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local CONTAINER_WEAR_RATES = ss.CONTAINER_WEAR_RATES
local CRAFTITEM_ICON = ss.CRAFTITEM_ICON
local ITEM_DESTRUCT_PATH = ss.ITEM_DESTRUCT_PATH
local SLOT_COLOR_BG = ss.SLOT_COLOR_BG
local SLOT_COLOR_HOVER = ss.SLOT_COLOR_HOVER
local SLOT_COLOR_BORDER = ss.SLOT_COLOR_BORDER
local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local RECIPES = ss.RECIPES
local NOTIFICATIONS = ss.NOTIFICATIONS
local NOTIFY_DURATION = ss.NOTIFY_DURATION
local formspec_viewers = ss.formspec_viewers
local player_data = ss.player_data
local radiant_sources = ss.radiant_sources
local mod_storage = ss.mod_storage



local ITEM_COOK_PATH = {

	["ss:apple"] = { "ss:apple_dried" },
	["ss:apple_dried"] = { "ss:ash" },

	["ss:mushroom_brown"] = { "ss:mushroom_brown_dried" },
	["ss:mushroom_brown_dried"] = { "ss:ash" },

	["ss:mushroom_red"] = { "ss:mushroom_red_dried" },
	["ss:mushroom_red_dried"] = { "ss:ash" },

	["ss:cactus"] = { "ss:cactus_dried" },
	["ss:cactus_dried"] = { "ss:charcoal 3" },

	["ss:blueberries"] = { "ss:blueberries_dried" },
	["ss:blueberries_dried"] = { "ss:ash" },

	["ss:cup_wood"] = { "ss:charcoal" },
	["ss:cup_wood_water_murky"] = { "ss:cup_wood_water_boiled" },
	["ss:cup_wood_water_boiled"] = { "ss:cup_wood" },

	["ss:bowl_wood"] = { "ss:charcoal" },
	["ss:bowl_wood_water_murky"] = { "ss:bowl_wood_water_boiled" },
	["ss:bowl_wood_water_boiled"] = { "ss:bowl_wood" },

	["ss:jar_glass_lidless"] = { "ss:scrap_glass" },
	["ss:jar_glass_lidless_water_murky"] = { "ss:jar_glass_lidless_water_boiled" },
	["ss:jar_glass_lidless_water_boiled"] = { "ss:jar_glass_lidless" },

	["ss:jar_glass"] = { "ss:scrap_glass" },
	["ss:jar_glass_water_murky"] = { "ss:jar_glass_water_boiled" },
	["ss:jar_glass_water_boiled"] = { "ss:jar_glass" },

	["ss:pot_iron"] = { "ss:scrap_iron" },
	["ss:pot_iron_water_murky"] = { "ss:pot_iron_water_boiled" },
	["ss:pot_iron_water_boiled"] = { "ss:pot_iron" },

	["ss:stick"] = { "ss:charcoal" },
	["ss:wood_plank"] = { "ss:charcoal 2" },
	["ss:wood"] = { "ss:charcoal 6" },
	["ss:scrap_wood"] = { "ss:ash" },

	["ss:plant_fiber"] = { "ss:ash 1" },
	["ss:string"] = { "ss:ash 1" },
	["ss:rope"] = { "ss:ash 2" },

	["ss:charcoal"] = { "ss:ash" },

	["ss:grass_clump"] = { "ss:dry_grass_clump" },
	["ss:dry_grass_clump"] = { "ss:ash" },
	["ss:marram_grass_clump"] = { "ss:ash" },
	["ss:jungle_grass_clump"] = { "ss:ash" },

	["ss:leaves_clump"] = { "ss:leaves_dry_clump" },
	["ss:leaves_dry_clump"] = { "ss:ash" },
	["ss:pine_needles"] = { "ss:ash" },
	["ss:leaves_fern"] = { "ss:ash" },

	["ss:flower_chrysanthemum_green"] = { "ss:ash" },
	["ss:flower_chrysanthemum_green_picked"] = { "ss:ash" },
	["ss:flower_dandelion_white"] = { "ss:ash" },
	["ss:flower_dandelion_white_picked"] = { "ss:ash" },
	["ss:flower_dandelion_yellow"] = { "ss:ash" },
	["ss:flower_dandelion_yellow_picked"] = { "ss:ash" },
	["ss:flower_geranium"] = { "ss:ash" },
	["ss:flower_geranium_picked"] = { "ss:ash" },
	["ss:flower_rose"] = { "ss:ash" },
	["ss:flower_rose_picked"] = { "ss:ash" },
	["ss:flower_tulip"] = { "ss:ash" },
	["ss:flower_tulip_picked"] = { "ss:ash" },
	["ss:flower_tulip_black"] = { "ss:ash" },
	["ss:flower_tulip_black_picked"] = { "ss:ash" },
	["ss:flower_viola"] = { "ss:ash" },
	["ss:flower_viola_picked"] = { "ss:ash" },

	["ss:flower_waterlily"] = { "ss:ash" },
	["ss:flower_waterlily_flower"] = { "ss:ash" },
	["ss:moss"] = { "ss:ash" },

	["ss:papyrus"] = { "ss:ash 4" },

	["default:axe_stone"] = { "ss:charcoal 2", "ss:stone 1" },
	["default:shovel_stone"] = { "ss:charcoal 2", "ss:stone 2" },
	["ss:hammer_wood"] = { "ss:charcoal 3" },

	["default:fence_wood"] = { "ss:charcoal 8" },

	["ss:bag_fiber_small"] = { "ss:ash" },
	["ss:bag_fiber_medium"] = { "ss:ash 2" },
	["ss:bag_fiber_large"] = { "ss:ash 3" },
	["ss:bag_cloth_small"] = { "ss:ash" },
	["ss:bag_cloth_medium"] = { "ss:ash 2" },
	["ss:bag_cloth_large"] = { "ss:ash 3" },

	["ss:campfire_small_new"] = { "ss:charcoal 12" },
	["ss:campfire_stand_wood"] = { "ss:charcoal 6" },
	["ss:campfire_grill_wood"] = { "ss:charcoal 2" },
	["ss:fire_drill"] = { "ss:charcoal 4" },
	["ss:match_book"] = { "ss:ash" },

	["ss:clothes_shirt_fiber"] = { "ss:ash 2" },
	["ss:clothes_pants_fiber"] = { "ss:ash 2" },
	["ss:clothes_gloves_fiber"] = { "ss:ash" },
	["ss:clothes_tshirt"] = { "ss:ash 2" },
	["ss:clothes_pants"] = { "ss:ash 2" },
	["ss:clothes_gloves_leather"] = { "ss:ash" },
	["ss:clothes_gloves_fingerless"] = { "ss:ash" },
	["ss:clothes_socks"] = { "ss:ash" },
	["ss:clothes_scarf"] = { "ss:ash 2" },
	["ss:clothes_sunglasses"] = { "ss:ash",  },
	["ss:clothes_necklace"] = { "ss:ash", "ss:scrap_glass" },
	["ss:clothes_shorts"] = { "ss:ash 2" },
	["ss:clothes_glasses"] = { "ss:ash" },

	["ss:armor_feet_fiber_1"] = { "ss:ash 2" },
	["ss:armor_feet_fiber_2"] = { "ss:ash 2" },
	["ss:armor_head_cloth_2"] = { "ss:ash 2" },
	["ss:armor_face_cloth_1"] = { "ss:ash 2" },
	["ss:armor_face_cloth_2"] = { "ss:ash" },
	["ss:armor_feet_cloth_2"] = { "ss:ash 2" },
	["ss:armor_head_wood_1"] = { "ss:charcoal 2" },
	["ss:armor_chest_wood_1"] = { "ss:charcoal 6" },
	["ss:armor_arms_wood_1"] = { "ss:charcoal 4" },
	["ss:armor_legs_wood_1"] = { "ss:charcoal 4" },
	["ss:armor_head_leather_1"] = { "ss:ash 2" },
	["ss:armor_head_leather_2"] = { "ss:ash" },
	["ss:armor_chest_leather_1"] = { "ss:ash 6" },
	["ss:armor_arms_leather_1"] = { "ss:ash 4" },
	["ss:armor_legs_leather_1"] = { "ss:ash 4" },
	["ss:armor_feet_leather_1"] = { "ss:ash 2" },

	["ss:bandages_basic"] = { "ss:ash" },
	["ss:bandages_medical"] = { "ss:ash" },
	["ss:pain_pills"] = { "ss:ash" },
	["ss:health_shot"] = { "ss:ash" },
	["ss:first_aid_kit"] = { "ss:ash 2" },
	["ss:splint"] = { "ss:charcoal" },
	["ss:cast"] = { "ss:ash" },

	-- items that will douse the fire. must be listed here as well as in the table
	-- 'FIRE_DOUSE_ITEMS' to allow cooking worm-up mechanic, but table element
	-- value is unused and set to empty string.
	["default:snow"] = "",
	["ss:snow_pile"] = "",
	["ss:ice"] = ""
}


-- lists empty containers that when cooked, break into scrap ingredients instead
-- of turning into ash, charcoal, or another resource.
local HEAT_DESTRUCT_CONTAINERS = {
	["ss:jar_glass"] = true,
	["ss:jar_glass_lidless"] = true,
	["ss:pot_iron"] = true
}

-- items placed in the ingredient slot that will 'melt' and douse the flames below.
-- the speed of this process is the COOK_WARM_UP_TIME value that normal items take
-- to start cooking. then the item is destroyed.
local FIRE_DOUSE_ITEMS = {
	["default:snow"] = true,
	["ss:snow_pile"] = true,
	["ss:ice"] = true,
}

-- items placed in the ingredient slot that will 'fall downward' and smother the
-- flames below. this occurs immediately and the item is dropped to the ground.
local FIRE_SMOTHER_ITEMS = {
	["ss:dirt_pile"] = true,
	["ss:dirt_permafrost_pile"] = true,
	["ss:ss_stone_pile"] = true,
	["ss:desert_stone_pile"] = true,
	["ss:sand_pile"] = true,
	["ss:desert_sand_pile"] = true,
	["ss:silver_sand_pile"] = true,
	["ss:sandstone_pile"] = true,
	["ss:desert_sandstone_pile"] = true,
	["ss:silver_sandstone_pile"] = true
}


local SLOT_TO_INSPECT = {
	["ss:campfire_stand_wood"] = "campfire_grill",
	["ss:campfire_grill_wood"] = "campfire_stand",
}


local RADIANT_SOURCES_DATA = {
	["ss:campfire_small_burning"] = {
		name = "ss:campfire_small_burning",
		temp_modifier = 15,
		min_distance = 1.0,
		max_distance = 2.0,
		pos_offset = {x = 0.5, y = 0.25, z = 0.5}
	}
}



-- table of vectors, where each one, when added to a given position represents
-- the various adjacent positions to the given position
local ADJACENT_POSITIONS = {
	N = {x = 0, y = 0, z = 1},  -- N
	NE = {x = 1, y = 0, z = 1},  -- NE
	E = {x = 1, y = 0, z = 0},  -- E
	SE = {x = 1, y = 0, z = -1}, -- SE
	S = {x = 0, y = 0, z = -1}, -- S
	SW = {x = -1, y = 0, z = -1},-- SW
	W = {x = -1, y = 0, z = 0}, -- W
	NW = {x = -1, y = 0, z = 1}, -- NW
	top = {x = 0, y = 1, z = 0},  -- TOP
	bottom = {x = 0, y = -1, z = 0},  -- BOTTOM
}


-- a short pause in seconds before an unheated item actually starts cooking/heating
-- when in the ingredient slot of a lit campfire
local COOK_WARM_UP_TIME = 3

-- campfire tool wear rates, applied during each burn cycle when campfire is on
local TOOL_WEAR_RATES = {
	campfire_stand = WEAR_VALUE_MAX / 975,
	campfire_grill = WEAR_VALUE_MAX / 645
	--campfire_stand = WEAR_VALUE_MAX / 10, -- for testing purposes
	--campfire_grill = WEAR_VALUE_MAX / 10
}

-- indexed by player name. stores the core.after job produced from turning on the
-- campfire. this job refreshes the campfire formspec ui for the player once per second.
-- the job object is needed for when player turns off campfire or exits campfire ui,
-- in order to cancel the job.
local campfire_jobs = {}

-- indexed by the hash of the campfire position, the matching element is the particle
-- id of the smoke effect when the campfire is on. helps ensure smoke particles properly
-- reactivate when map chunk is reloaded.
local particle_ids = {}

-- burntime of the core campfire iteself with no items in the fuel slots. when this value
-- reaches zero, the campfire is spent. this value can only be restore by rebuilding the
-- campfire and depletes only when the campfire is on with no items in the fuel slots.
local CAMPFIRE_CORE_BURNTIME = 1680  -- default:1680, approx 4x wood + 4x sticks

-- the duration in real world seconds for each unit of burn time. example: the burn time for
-- "ss:stick" is 10 units. thus, the total burn time in seconds is 10 x 3 seconds = 30 seconds.
-- burn times for items are expected to be no less than 1 unit.
local FUEL_BURN_INTERVAL = 1

local FUEL_WEIGHT_MAX = {50, 75}


-- table populated by 'cook_nodes.txt'. this table is indexed by node names that can be
-- 'cooked' due to being adjacent to a lit campfire. the corresponding element contains
-- data to allow proper handling of how the adjacent node reacts when fully cooked, like
-- being replaced by another node, being destroyed and dropping items, etc.
local COOK_NODES = {}
--[[ Example:
{
	["default:pine_sapling"] = {
			cook_time = "10",
			action_type = "drop",
			drops = {
				ItemStack("ss:stick_heated"),
				ItemStack("ss:ash")
			}
		},
	}
	["default:mossycobble"] = {
		cook_time = "5",
		action_type = "replace",
		node = {name = "default:cobble"}
	},
	["ss:itemdrop_bag"] = {
		cook_time = "10",
		action_type = "destruct"
	}
}
--]]

local flag40 = false
debug(flag40, "populating COOK_NODES table..")
local file_path = core.get_modpath("ss") .. "/cook_nodes.txt"
local file = io.open(file_path, "r")
if not file then
	debug(flag40, "  Could not open file: " .. file_path)
	return
end
for line in file:lines() do
	-- Trim whitespace from the line
	line = line:match("^%s*(.-)%s*$")
	debug(flag40, "  line: " .. line)
	-- Skip blank lines and lines that start with '#'
	if line == "" then
		debug(flag40, "    blank line. skipped.")
	elseif line:sub(1, 1) == "#" then
		debug(flag40, "    comment line. skipped.")
	else
		debug(flag40, "    data line. processing..")
		local tokenized_data = {}
		for data in string_gmatch(line, '([^,]+)') do
			table_insert(tokenized_data, data)
		end
		--debug(flag40, "  tokenized_data: " .. dump(tokenized_data))
		local item_name = table_remove(tokenized_data, 1)
		local cook_time = table_remove(tokenized_data, 1)
		--cook_time = 10  -- for testing
		local action_type = table_remove(tokenized_data, 1)
		if action_type == "replace" then
			debug(flag40, "    action type REPLACE")
			COOK_NODES[item_name] = {
				cook_time = cook_time,
				action_type = action_type,
				node = {name = tokenized_data[1]}
			}
		elseif action_type == "drop" then
			debug(flag40, "    action type DROP")
			local item_drops = {}
			for i, item in ipairs(tokenized_data) do
				local itemdrop = ItemStack(item)
				local itemdrop_name = itemdrop:get_name()
				debug(flag40, "    itemdrop_name: " .. itemdrop_name)
				table_insert(item_drops, itemdrop)
			end
			COOK_NODES[item_name] = {
				cook_time = cook_time,
				action_type = action_type,
				drops = item_drops
			}
		elseif action_type == "destruct" then
			debug(flag40, "    action type DESTRUCT")
			COOK_NODES[item_name] = {
				cook_time = cook_time,
				action_type = action_type
			}
		else
			debug(flag40, "  ERROR - Unexpected 'action_type': " .. action_type)
		end
	end
end
file:close()
debug(flag40, "  COOK_NODES[]: " .. dump(COOK_NODES))



local flag26 = false
-- given an itemstack, checks the player 'main' inventory if it contains the itemstack,
-- then returns an integer representing the amount that is missing. returns 0 if the
-- inventory contains equal amount or more of the target itemstack.
local function count_missing_items(player, itemstack)
    debug(flag26, "  count_missing_items()")

    -- Get the player's inventory
    local inv = player:get_inventory()
    local inv_list = inv:get_list("main")

    -- Extract item name and required count from the itemstack
    local item_name = itemstack:get_name()
    local target_count = itemstack:get_count()
    --debug(flag26, "    item_name: " .. item_name)
    --debug(flag26, "    target_count: " .. target_count)

    -- Calculate the total count of the item in the 'main' inventory
    local available_count = 0
    for i = 1, #inv_list do
        local stack = inv_list[i]
        if stack:get_name() == item_name then
            available_count = available_count + stack:get_count()
            if available_count >= target_count then
                break
            end
        end
    end
    --debug(flag26, "    available_count: " .. available_count)

    -- Calculate the amount missing
    local missing_count = target_count - available_count
    --debug(flag26, "    missing_count: " .. missing_count)

    local return_val = 0
    if missing_count > 0 then
        return_val = missing_count
    end
    --debug(flag26, "    return_val: " .. return_val)

    debug(flag26, "  count_missing_items() END")
    return return_val
end



local flag24 = false
-- cancels the looping core.after() calls that resfreshes and displays the campfire
-- UI formspec to the player. this occurs when the campfire is spent, the player manually
-- stops the campfire, or simply exits from the campfire formspec UI.
local function cancel_refresh_formspec_job(player_name)
	debug(flag24, "  cancel_refresh_formspec_job()")
	local job = campfire_jobs[player_name]
	if job then
		--debug(flag24, "    campfire job found: " .. dump(job))
		job:cancel()
		campfire_jobs[player_name] = nil
		--debug(flag24, "    campfire job cancelled!")
	else
		--debug(flag24, "    no campfire job found.")
	end
	debug(flag24, "  cancel_refresh_formspec_job() END")
end


local flag5 = false
-- returns all formspec elements that displays the campfire UI. checks the campfire
-- status and campfire fuel levels to dynamically display the correct campfire visuals.
local function get_fs_campfire(player, player_name, pos)
	debug(flag5, "\n    get_fs_campfire()")
	--debug(flag5, "      pos: " .. mt_pos_to_string(pos))
	local player_meta = player:get_meta()
	local node_meta = mt_get_meta(pos)
    local node_inv = node_meta:get_inventory()
	local campfire_status = node_meta:get_string("campfire_status")

	local formspec = ""
	local fs_output = {}
	local curr_weight = player_meta:get_float("weight_current")
    local max_weight = player_meta:get_float("weight_max")
    curr_weight = round(curr_weight, 2)
	local inventory_elements = table_concat({

		-- core formspec properties for campfire UI
		"formspec_version[7]",
		"size[14.0,7.7,true]",
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
		"box[9.1,0.0;4.9,8.0;#181818]",

	})
	table_insert(fs_output, inventory_elements)

	----------------------
	-- campfire ui pane --
	----------------------

	-- campfire stand image
	local slot_bg_campfire_stand, slot_tooltip_campfire_stand
	local campfire_stand_image = "ss_campfire_stand_wood_detailed.png"
	if node_inv:is_empty("campfire_stand") then
		--debug(flag5, "      no campfire stand")
		slot_bg_campfire_stand = "image[12.6,2.0;1,1;ss_ui_slot_campfire_stand.png;]"
		slot_tooltip_campfire_stand = "tooltip[12.6,2.0;1,1;campfire stand slot]"
	else
		--debug(flag5, "      campfire stand is in use")
		local campfire_stand_item = node_inv:get_stack("campfire_stand", 1)
		local campfire_stand_name = campfire_stand_item:get_name()
		--debug(flag5, "      campfire_stand_name: " .. campfire_stand_name)

		-- retrieve current condition info
		local item_meta = campfire_stand_item:get_meta()
		local condition = item_meta:get_float("condition")
		--debug(flag5, "      condition: " .. condition)
		if condition == 0 then
			condition = WEAR_VALUE_MAX
		elseif condition < 9000 then
			campfire_stand_image = "ss_campfire_stand_wood_used_detailed.png"
		end
		local condition_ratio = condition / WEAR_VALUE_MAX
		--debug(flag5, "      condition_ratio: " .. condition_ratio)

		-- display the campfire stand image
		table_insert(fs_output, "image[9.2,1.3;3.5,3.5;" .. campfire_stand_image .. ";]")

		-- display green slot bg for campfire stand's condition level
		local bar_yoffset = 1 - condition_ratio
		slot_bg_campfire_stand = table_concat({
			"image[12.6,", 2.0 + bar_yoffset, ";1,", condition_ratio,
				";[fill:1x1:", player_data[player_name].ui_green, "]"
		})
		slot_tooltip_campfire_stand = ""
	end

	-- campfire pile and flames image
	local campfire_icon, campfire_status_text
	local burn_time_campfire = node_meta:get_int("burn_time_campfire")
	if burn_time_campfire == CAMPFIRE_CORE_BURNTIME then
		campfire_icon = "ss_campfire_small_new.png"
		campfire_status_text = "new campfire"
	elseif burn_time_campfire == 0 then
		campfire_icon = "ss_campfire_small_spent.png"
		campfire_status_text = "spent campfire"
	else
		campfire_icon = "ss_campfire_small_used.png"
		campfire_status_text = "campfire (used)"
	end
	table_insert(fs_output, table_concat({
		"image[10.1,2.9;1.5,1.5;", campfire_icon, ";]",
		"tooltip[10.0,3.6;1.5,0.8;", campfire_status_text, "]"
	}))
	if campfire_status == "on" then
		table_insert(fs_output, "image[10.0,2.9;1.6,1.6;ss_campfire_small_flames_1.png;]")
	end

	-- campfire grill image
	local slot_bg_campfire_grill, slot_tooltip_campfire_grill
	local campfire_grill_image = "ss_campfire_grill_wood.png"
	if node_inv:is_empty("campfire_grill") then
		--debug(flag5, "      no campfire grill")
		slot_bg_campfire_grill = "image[12.6,3.5;1,1;ss_ui_slot_campfire_grill.png;]"
		slot_tooltip_campfire_grill = "tooltip[12.6,3.5;1,1;campfire grill slot]"
	else
		--debug(flag5, "      campfire grill is in use")
		local campfire_grill_item = node_inv:get_stack("campfire_grill", 1)
		local campfire_grill_name = campfire_grill_item:get_name()
		--debug(flag5, "      campfire_grill_name: " .. campfire_grill_name)

		-- retrieve current condition info
		local item_meta = campfire_grill_item:get_meta()
		local condition = item_meta:get_float("condition")
		--debug(flag5, "      condition: " .. condition)

		if condition == 0 then
			condition = WEAR_VALUE_MAX
		elseif condition < 9500 then
			campfire_grill_image = "ss_campfire_grill_wood_used.png"
		end

		local condition_ratio = condition / WEAR_VALUE_MAX
		--debug(flag5, "      condition_ratio: " .. condition_ratio)

		-- display the campfire grill image
		table_insert(fs_output, "image[9.95,2.8;1.8,1.8;" .. campfire_grill_image .. ";]")

		-- display green slot bg for campfire stand's condition level
		local bar_yoffset = 1 - condition_ratio
		slot_bg_campfire_grill = table_concat({
			"image[12.6,", 3.5 + bar_yoffset, ";1,", condition_ratio,
				";[fill:1x1:", player_data[player_name].ui_green, "]"
		})
		slot_tooltip_campfire_grill = ""
	end

	-- fire starter slot image
	local slot_bg_fire_starter, slot_tooltip_fire_starter
	if node_inv:is_empty("fire_starter") then
		--debug(flag5, "      no fire starter item present")
		slot_bg_fire_starter = "image[12.6,6.5;1,1;ss_ui_slot_fire_starter.png;]"
		slot_tooltip_fire_starter = "tooltip[12.6,6.5;1,1;fire starter slot]"
	else
		--debug(flag5, "      fire starter item is in use")
		local fire_starter_item = node_inv:get_stack("fire_starter", 1)
		local fire_starter_name = fire_starter_item:get_name()
		--debug(flag5, "      fire_starter_name: " .. fire_starter_name)

		local item_meta = fire_starter_item:get_meta()
		local remaining_uses = item_meta:get_int("remaining_uses")
		local remaining_uses_ratio = remaining_uses / ITEM_MAX_USES[fire_starter_name]
		local bar_height = 1 * remaining_uses_ratio
		local bar_yoffset = 1 - bar_height
		local bar_ypos = 6.5 + bar_yoffset
		slot_bg_fire_starter = table_concat({
			"image[12.6,", bar_ypos, ";1,", bar_height,
				";[fill:1x1:", player_data[player_name].ui_green, "]"
		})
		local tooltip_description = refresh_meta_and_description(fire_starter_name, item_meta)
		slot_tooltip_fire_starter = "tooltip[12.6,6.5;1,1;".. tooltip_description .. "]"
	end

	-- green icon bg image that conveys the fuel remaining of the currently-burning fuel item
	local current_fuel_item_name = node_meta:get_string("current_fuel_item_name")
	--debug(flag5, "      current_fuel_item_name: " .. current_fuel_item_name)
	if current_fuel_item_name ~= "" then
		local fuel_burn_time_max
		if current_fuel_item_name == "ss:item_bundle" then
			--debug(flag5, "      an item bundle")
			fuel_burn_time_max = node_meta:get_int("current_fuel_item_bundle_burn_time")
		else
			--debug(flag5, "      not an item bundle")
			fuel_burn_time_max = ITEM_BURN_TIMES[current_fuel_item_name]
		end
		--debug(flag5, "        fuel_burn_time_max: " .. fuel_burn_time_max)

		local fuel_burn_time_remaining = node_meta:get_int("burn_time_current_item")
		--debug(flag5, "        fuel_burn_time_remaining: " .. fuel_burn_time_remaining)
		local burn_time_remaining = fuel_burn_time_remaining / fuel_burn_time_max
		--debug(flag5, "        burn_time_remaining %: " .. burn_time_remaining * 100)

		local current_fuel_item_inv_image = node_meta:get_string("current_fuel_item_inv_image")
		--debug(flag5, "        current_fuel_item_inv_image: " .. current_fuel_item_inv_image)

		local image_size = 0.5
		local bar_height = image_size * burn_time_remaining
		--debug(flag5, "        green bar_height: " .. bar_height)
		--debug(flag5, "        green bar_height %: " .. bar_height / 0.5 * 100)
		local bar_yoffset = image_size - bar_height
		--debug(flag5, "        green bar_yoffset: " .. bar_yoffset)
		local bar_ypos = 4.6 + bar_yoffset
		--debug(flag5, "        green bar_ypos: " .. bar_ypos)

		table_insert(fs_output, table_concat({
			"image[10.6,4.6;", image_size, ",", image_size, ";[fill:1x1:#000000]",

			"image[10.6,", bar_ypos, ";", image_size, ",", bar_height,
				";[fill:1x1:", player_data[player_name].ui_green, "]",
			"box[10.6,4.6;", image_size, ",", image_size, ";#000000]",
			"image[10.6,4.6;", image_size, ",", image_size, ";", current_fuel_item_inv_image, ";]"
		}))
	end

	local pos_string = string_format("%.2f,%.2f,%.2f", pos.x, pos.y, pos.z)
	local slot_count_ingredients = node_meta:get_int("slot_count_ingredients")

	-- construct the orange progress bar box for each ingredient item slot
	local slot_bg_ingredients = ""
	for i = 1, slot_count_ingredients do
		local ingredient_item = node_inv:get_stack("ingredients", i)
		local item_meta = ingredient_item:get_meta()
		local heat_progress = item_meta:get_float("heat_progress")
		if heat_progress > 0 then
			local heat_progress_ratio = heat_progress / COOK_THRESHOLD
			local bar_height = heat_progress_ratio
			local bar_yoffset = 1 - bar_height
			local bar_xpos = 9.3 + (i - 1) + ((i -1) * 0.1)
			local bar_ypos = 0.2 + bar_yoffset
			slot_bg_ingredients = table_concat({
				slot_bg_ingredients, "image[", bar_xpos, ",", bar_ypos, ";1,", bar_height,
					";[fill:1x1:", player_data[player_name].ui_orange, "]"
			})
		end
	end

	-- slots for ingredients
	table_insert(fs_output, table_concat({
		slot_bg_ingredients,
		"list[nodemeta:", pos_string, ";ingredients;9.3,0.2;", slot_count_ingredients, ",1;]",
        "listring[nodemeta:", pos_string, ";ingredients]",
		"listring[current_player;main]"
	}))

	-- slots for campfire stand, campfire grill, and fire starter
	table_insert(fs_output, table_concat({
		slot_bg_campfire_stand,
		"list[nodemeta:", pos_string, ";campfire_stand;12.6,2.0;1,1;]",
		"listring[nodemeta:", pos_string, ";campfire_stand]",
		"listring[current_player;main]",
		slot_tooltip_campfire_stand,

		slot_bg_campfire_grill,
		"list[nodemeta:", pos_string, ";campfire_grill;12.6,3.5;1,1;]",
		"listring[nodemeta:", pos_string, ";campfire_grill]",
		"listring[current_player;main]",
		slot_tooltip_campfire_grill,

		slot_bg_fire_starter,
		"list[nodemeta:", pos_string, ";fire_starter;12.6,6.5;1,1;]",
		"listring[nodemeta:", pos_string, ";fire_starter]",
		"listring[current_player;main]",
		slot_tooltip_fire_starter
	}))

	-- ingredient slot tooltips
	for i = 1, slot_count_ingredients do
		table_insert(fs_output, table_concat({"tooltip[", 8.3 + i + ((i - 1) * 0.1), ",0.2;1,1;campfire ingredient slot]"}))
	end

	if campfire_status ~= "spent" then
		-- fuel slots
		local slot_count_fuel = node_meta:get_int("slot_count_fuel")
		table_insert(fs_output, table_concat({
			"list[nodemeta:", pos_string, ";fuel;9.3,5.3;", slot_count_fuel, ",1;]",
			"listring[nodemeta:", pos_string, ";fuel]",
			"listring[current_player;main]"
		}))

		-- fuel slot tooltips
		for i = 1, slot_count_fuel do
			table_insert(fs_output, table_concat({"tooltip[", 8.3 + i + ((i - 1) * 0.1), ",5.3;1,1;campfire 'extra' fuel slot]"}))
		end

		-- campfire fuel display
		local burn_time_extra = node_meta:get_int("burn_time_extra")
		--debug(flag5, "      burn_time_extra: " .. burn_time_extra)
		--debug(flag5, "      burn_time_campfire: " .. burn_time_campfire)
		burn_time_extra = round(burn_time_extra, 2)
		local burn_time_icon = "ss_ui_iteminfo_attrib_burn_time.png"
		local font_color_extra = "#999999"
		local font_color_campfire = "#666666"
		if campfire_status == "on" then
			burn_time_icon = "ss_ui_iteminfo_attrib_burn_time2.png"
			if burn_time_extra > 0 then
				font_color_extra = "#FFFFFF"
			else
				font_color_campfire = "#FFFFFF"
			end
		end
		table_insert(fs_output, table_concat({
				"image[11.5,5.1;0.6,0.6;", burn_time_icon, ";]",
				"hypertext[12.1,5.35;4.0,2;campfire_burn_time;<b>",
					"<style color=", font_color_extra, " size=16>", burn_time_extra, "</style>",
					"<style color=#666666 size=16> : </style>",
					"<style color=", font_color_campfire, " size=16>", burn_time_campfire, "</style>",
				"</b>]",
				"tooltip[11.5,5.1;1.5,0.5;campfire fuel (extra : core)]"
			})
		)

		-- campfire weight values display
		local weight_fuel_total = node_meta:get_float("weight_fuel_total")
		local weight_fuel_max = node_meta:get_float("weight_fuel_max")
		--debug(flag5, "      weight_fuel_total: " .. weight_fuel_total)
		--debug(flag5, "      weight_fuel_max: " .. weight_fuel_max)
		weight_fuel_total = round(weight_fuel_total, 2)
		table_insert(fs_output, table_concat({
				"image[11.5,5.7;0.6,0.6;ss_ui_iteminfo_attrib_weight.png;]",
				"hypertext[12.1,5.95;4.0,2;campfire_weight;<b>",
					"<style color=#999999 size=16>", weight_fuel_total, "</style>",
					"<style color=#666666 size=16> / ", weight_fuel_max, "</style>",
				"</b>]",
				"tooltip[11.4,5.7;1.5,0.5;campfire weight (current / max)]"
			})
		)
	end

	-- campfire buttons
	local campfire_button
	if campfire_status == "on" then
		--debug(flag5, "      campfire is ON")
		campfire_button = "button[9.3,6.5;3.0,1;campfire_stop;Stop Campfire]"
	elseif campfire_status == "off" then
		--debug(flag5, "      campfire is OFF")
		campfire_button = "button[9.3,6.5;3.0,1;campfire_start;Light Campfire]"
	elseif campfire_status == "spent" then
		--debug(flag5, "      campfire is SPENT")
		campfire_button = "button[9.3,6.5;3.0,1;campfire_rebuild;Rebuild Campfire]"
	else
		debug(flag5, "      ERROR: Unexpected 'campfire_status' value: " .. campfire_status)
	end
	table_insert(fs_output, table_concat({ campfire_button }))


	-- combine all formspec elements
	formspec = table_concat(fs_output)
	--debug(flag5, "      formspec: " .. formspec)
	debug(flag5, "    get_fs_campfire() end *** " .. mt_get_gametime() .. " ***")
	return formspec
end


local flag46 = false
-- this function removes metadata relating to 'cooker' and cook cooldown info,
-- in the event the item was removed from the campfire's ingredient slot while
-- the item was still in its cooking cooldown phase. this allows the item to be
-- stacked with other identical items in the player inventory again since the
-- custom metadata is removed.
local function reset_cook_data(item)
	debug(flag46, "  reset_cook_data()")
	--debug(flag46, "    item name: " .. item:get_name())

    local item_meta = item:get_meta()
    local in_cooldown = item_meta:get_int("in_cooldown")
    if in_cooldown > 0 then
        --debug(flag46, "    item was in cooldown. clearing cooking data..")
        item_meta:set_string("cooker", "")
        item_meta:set_string("in_cooldown", "")
        item_meta:set_string("cooldown_counter", "")
    else
        --debug(flag46, "    item not in cooldown")
    end

	debug(flag46, "  reset_cook_data() END")
end


local function update_weight_data(player, player_meta, p_data, fs, weight_change)
	-- update vertical statbar weight HUD
	do_stat_update_action(player, p_data, player_meta, "normal", "weight", weight_change, "curr", "add", true)

	-- update weight values display tied to inventory formspec
	fs.center.weight = get_fs_weight(player)
	player_meta:set_string("fs", mt_serialize(fs))
	local formspec = build_fs(fs)
	player:set_inventory_formspec(formspec)

	-- update fuel burntime/weight display values on campfire bottom right section
	local player_name = player:get_player_name()
	local pos = key_to_pos(p_data.campfire_pos_key)
	formspec = get_fs_campfire(player, player_name, pos)
	mt_show_formspec(player_name, "ss:ui_campfire", formspec)
end


local flag23 = false
local function refresh_formspec(pos, pos_key)
	debug(flag23, "\nrefresh_formspec()")
	--debug(flag23, "  formspec_viewers: " .. dump(formspec_viewers))
	for i, player_name in ipairs(formspec_viewers[pos_key]) do
		local player = mt_get_player_by_name(player_name)
		mt_show_formspec(player_name, "ss:ui_campfire", get_fs_campfire(player, player_name, pos))
		--debug(flag23, "  formspec refreshed for user: " .. player_name)
	end
	debug(flag23, "refresh_formspec() END *** " .. mt_get_gametime() .. " ***")
end


local flag14 = false
local function update_fuel_stats(node_meta, node_inv)
	debug(flag14, "update_fuel_stats()")

	local fuel_slots = node_inv:get_list("fuel")
	local fuel_slot_count = node_meta:get_int("slot_count_fuel")
	--debug(flag14, "  fuel_slot_count: " .. fuel_slot_count)

	local weight_total = 0
	local burn_time_extra = 0
	for i = 1, fuel_slot_count do
		local fuel_item = fuel_slots[i]
		--debug(flag14, "  checking slot #" .. i)

		if fuel_item:is_empty() then
			--debug(flag14, "    no fuel item exists there")

		else

			local item_burn_time, is_reduced = get_item_burn_time(fuel_item)
			--debug(flag14, "    item_burn_time: " .. item_burn_time)

			if is_reduced then
				--debug(flag14, "    this was a reduce burn time value")
				node_meta:set_int("burn_time_current_item_modded", item_burn_time)
			end

			-- calculate the total burn time for the campfire's 'extra fuel'
			burn_time_extra = burn_time_extra + (item_burn_time * fuel_item:get_count())
			--debug(flag14, "    burn_time_extra: " .. burn_time_extra)

			-- calculate campfire fuel weight total
			local item_weight = round(get_itemstack_weight(fuel_item),2)
			--debug(flag14, "    item_weight: " .. item_weight)
			weight_total = weight_total + item_weight
		end

	end
	--debug(flag14, "  burn_time_current_item: " .. node_meta:get_int("burn_time_current_item"))

	burn_time_extra = burn_time_extra + node_meta:get_int("burn_time_current_item")
	node_meta:set_int("burn_time_extra", burn_time_extra)
	--debug(flag14, "  burn_time_extra: " .. burn_time_extra)
	node_meta:set_float("weight_fuel_total", round(weight_total,2))

	debug(flag14, "update_fuel_stats() end")
end


local flag16 = false
local function reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, slot_to_reduce)
	debug(flag16, "  reduce_ingred_fuel_slots()")

	local metadata_label = "slot_count_" .. slot_to_reduce
	local slot_count = node_meta:get_int(metadata_label)
	--debug(flag16, "    checking " .. slot_to_reduce .. " slot #" .. slot_count)

	local slot_item = node_inv:get_stack(slot_to_reduce, slot_count)
	if slot_item:is_empty() then
		--debug(flag16, "    slot is empty")

	else
		local slot_item_name = slot_item:get_name()
		--debug(flag16, "    slot contains: " .. slot_item_name)

		-- remove item from ingred/fuel slot since it will be dropped to ground
		node_inv:set_stack(slot_to_reduce, slot_count, ItemStack(""))

		--debug(flag16, "    " .. slot_to_reduce .. " slots reduced due to removal/destruction of campfire tool")
		--debug(flag16, "    dropping item to ground: " .. slot_item_name)
		mt_add_item(pos, slot_item)

		if player then
			notify(player, "inventory", slot_to_reduce ..  " item dropped to ground.", NOTIFY_DURATION, 0.5, 0, 2)
		else
			-- this is when campfire tool is destroyed on its own due to being worn
			-- out in a lit campfire. there is no relevent player object in this
			-- scenario, thus no on-screen notification need be displayed.
		end

		-- update campfire formspec fuel weight and fuel burntime visuals if the
		-- item dropped was from a fuel slot
		if slot_to_reduce == "fuel" then
			update_fuel_stats(node_meta, node_inv)
		end

	end


	-- if fuel slot was reduced, this means the fuel weight max was also reduced.
	-- check the remaining fuel slot #1 and ensures the itemstack does not exceed
	-- the new reduced weight max. if so, the 'overage' quantity of that itemstack
	-- is dropped to the ground.
	if slot_to_reduce == "fuel" then
		--debug(flag16, "    fuel slot #2 was removed")
		node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[1])

		local fuel_item = node_inv:get_stack("fuel", 1)
		if fuel_item:is_empty() then
			--debug(flag16, "    fuel slot #1 is empty")
		else
			local fuel_item_name = fuel_item:get_name()
			--debug(flag16, "    fuel slot #1 contains: " .. fuel_item_name)
			local fuel_weight = get_itemstack_weight(fuel_item)
			--debug(flag16, "    fuel_weight: " .. fuel_weight)

			local fuel_weight_max = FUEL_WEIGHT_MAX[1]
			if fuel_weight > fuel_weight_max then
				--debug(flag16, "    ** exceeds the reduced fuel max weight **")
				local exceed_weight_amount = fuel_weight - fuel_weight_max

				local single_fuel_item_weight
				if fuel_item_name == "ss:item_bundle" then
					single_fuel_item_weight = fuel_weight
				else
					single_fuel_item_weight = ITEM_WEIGHTS[fuel_item_name]
				end
				--debug(flag16, "    single_fuel_item_weight: " .. single_fuel_item_weight)

				local fuel_count_to_remove = math_ceil(exceed_weight_amount / single_fuel_item_weight)
				--debug(flag16, "    fuel_count_to_remove: " .. fuel_count_to_remove)

				fuel_item:take_item(fuel_count_to_remove)
				node_inv:set_stack("fuel", 1, fuel_item)
				--debug(flag16, "    fuel item in slot #1 reduced by: " .. fuel_count_to_remove)

				update_fuel_stats(node_meta, node_inv)
				--debug(flag16, "    updated campfire formspec fuel values")

				--debug(flag16, "    fuel item in slot #1 reduced for exceeding max fuel weight")
				--debug(flag16, "    dropping the overage fuel quantity to ground..")
				local exceeded_item = ItemStack({name = fuel_item_name, count = fuel_count_to_remove})
				mt_add_item(pos, exceeded_item)

			else
				--debug(flag16, "    within acceptable fuel weight limit")
			end
		end

	end

	node_meta:set_int(metadata_label, slot_count - 1)
	refresh_formspec(pos, pos_to_key(pos))

	debug(flag16, "  reduce_ingred_fuel_slots() end")
end



local flag32 = false
-- Adds wear to the campfire tool indicated by 'tool_type' by deducting 'wear_rate'
-- from the tool's 'condition' property. Once the condition value reaches zero, the
-- tool is completely worn and removed from the game.
--- @param pos table position of the campfire node
--- @param node_meta NodeMetaRef the campfire metadata
--- @param node_inv InvRef the campfire inventory
--- @param tool_item ItemStack the campfire tool items that will receive the wear
--- @param tool_type string either 'campfire_stand' or 'campfire_grill'
--- @param duration number the time in seconds the tool is used/heated in the campfire
local function apply_wear_tool(pos, node_meta, node_inv, tool_item, tool_type, duration)
	debug(flag32, "      apply_wear_tool()")

	-- capture item name in case the tool is about to be destroyed/removed, and use it
	-- to retrieve 'cooked' tool result from ITEM_COOK_PATH table below
	local item_name = tool_item:get_name()
	--debug(flag32, "        item_name: " .. item_name)

	local tool_item_meta = tool_item:get_meta()
	local condition = tool_item_meta:get_float("condition")
	if condition == 0 then
		--debug(flag32, "        this is an unused campfire tool. condition intialized to: " .. WEAR_VALUE_MAX)
		condition = WEAR_VALUE_MAX
	end
	--debug(flag32, "        condition: " .. condition)

	local wear_rate = round(TOOL_WEAR_RATES[tool_type], 2)
	--debug(flag32, "        wear_rate: " .. wear_rate)
	--debug(flag32, "        duration: " .. duration)
	wear_rate = wear_rate * duration
	--debug(flag32, "        wear_rate x duration: " .. wear_rate)
	local random_modifier = wear_rate * math_random(-15,15) * 0.01
	--debug(flag32, "        random_modifier: " .. random_modifier)
	wear_rate = wear_rate + random_modifier
	--debug(flag32, "        wear_rate + random_modifier: " .. wear_rate)
	condition = condition - wear_rate
	--debug(flag32, "        new condition: " .. condition)

	if condition > 0 then
		--debug(flag32, "        " .. tool_type .. " still usable")
		update_meta_and_description(tool_item_meta, item_name, {"condition"}, {condition})
		node_inv:set_stack(tool_type, 1, tool_item)

	else
		--debug(flag32, "        " .. tool_type .. " destroyed")
		node_inv:set_stack(tool_type, 1, ItemStack(""))
		play_sound("item_break", {item_name = item_name, pos = pos})

		--debug(flag32, "        dropping heated tool result to ground..")
		local tool_result_item = ItemStack(ITEM_DESTRUCT_PATH[item_name][1])
		local tool_result_name = tool_result_item:get_name()
		--debug(flag32, "        tool_result: " .. tool_result_name .. " " .. tool_result_item:get_count())
		mt_add_item(pos, tool_result_item)

		reduce_ingred_fuel_slots(nil, node_meta, node_inv, pos, "ingredients")
		local slot_count_fuel = node_meta:get_int("slot_count_fuel")
		if slot_count_fuel == 2 then
			--debug(flag32, "        slot_count_fuel is 2")

			local slot_to_inspect = SLOT_TO_INSPECT[item_name]
			--debug(flag32, "        inspecting tool slot: " .. slot_to_inspect)

			if node_inv:is_empty(slot_to_inspect) then
				--debug(flag32, "        " .. slot_to_inspect .. " not used. removing fuel slot..")
				reduce_ingred_fuel_slots(nil, node_meta, node_inv, pos, "fuel")
			else
				--debug(flag32, "        " .. slot_to_inspect .. " currently used. fuel slots unmodified.")
			end

		else
			--debug(flag32, "        slot_count_fuel is not 2.")
		end
	end

	debug(flag32, "      apply_wear_tool() END")
end


local flag33 = false
-- apply wear to both campfire stand and campfire grill that is based on a common elapsed
-- burn time aka 'wear_duration'
--- @param campfire_pos table position of the campfire node
--- @param campfire_meta NodeMetaRef the campfire metadata
--- @param campfire_inv InvRef the campfire node inventory
--- @param wear_duration number the amount of time in seconds to heat/cook 'item'
local function add_wear_campfire_tools(campfire_pos, campfire_meta, campfire_inv, wear_duration)
	debug(flag33, "      add_wear_campfire_tools()")

	local tool_item = campfire_inv:get_stack("campfire_stand", 1)
	if tool_item:is_empty() then
		--debug(flag33, "        campfire_stand not in use. not adding wear.")
	else
		--debug(flag33, "        campfire_stand in use! adding wear..")
		apply_wear_tool(campfire_pos, campfire_meta, campfire_inv, tool_item, "campfire_stand", wear_duration)
	end

	tool_item = campfire_inv:get_stack("campfire_grill", 1)
	if tool_item:is_empty() then
		--debug(flag33, "        campfire_grill not in use. not adding wear.")
	else
		--debug(flag33, "        campfire_grill in use! adding wear..")
		apply_wear_tool(campfire_pos, campfire_meta, campfire_inv, tool_item, "campfire_grill", wear_duration)
	end

	debug(flag33, "      add_wear_campfire_tools() END")
end


local flag21 = false
-- simulate burn duration of 'elapsed_time' onto the campfire tool denoted by 'tool_type'.
-- the 'data' table is then updated to reflect whether or not the elapsed time was enough
-- to fully burn out that campfire tool to turn into its next form.
--- @param campfire_pos table position of the campfire node
--- @param campfire_meta NodeMetaRef the campfire metadata
--- @param campfire_inv InvRef the campfire inventory
--- @param burnout_time number how many seconds to fully burn/cook and turn into the next item
--- @param data table contains values for 'elapsed_time_remain' and 'elapsed_time_used'
--- @param elapsed_time number how many seconds of burn time to simulate upon the campfire tool
--- @param tool_type string can be either 'campfire_stand' or 'campfire_grill'
local function burnout_campfire_tool(campfire_pos, campfire_meta, campfire_inv, burnout_time, data, elapsed_time, tool_type)
	debug(flag21, "\n    burnout_campfire_tool()")
	--debug(flag21, "      tool_type: " .. tool_type)
	--debug(flag21, "      burnout_time: " .. burnout_time)

	if data.elapsed_time_used then
		--debug(flag21, "      this is a subsequent burnout action")
		elapsed_time = data.elapsed_time_used
		--debug(flag21, "      elapsed_time taken from prior burnout action: " .. elapsed_time)
	else
		--debug(flag21, "      this is the 1st running burnout action")
		--debug(flag21, "      elapsed_time taken from main context: " .. elapsed_time)
	end

	if elapsed_time == 0 then
		--debug(flag21, "      no 'current fuel item' was present. tool wear will be calculated at later phase.")
		data.elapsed_time_used = elapsed_time

	else
		--debug(flag21, "      'current fuel item' was present. applying campfire tool wear based on that state..")
		apply_wear_tool(
			campfire_pos,
			campfire_meta,
			campfire_inv,
			campfire_inv:get_stack(tool_type, 1),
			tool_type,
			elapsed_time
		)
		data.elapsed_time_used = elapsed_time
	end

	debug(flag21, "    burnout_campfire_tool() END")
end


local flag20 = false
-- simulate burn duration of 'elapsed_time' onto the fuel item that is currently burning.
-- this is the fuel item represented by the small icon with the green progress indicator
-- directly below the campfire image. the 'data' table is then updated to reflect whether
-- or not the elapsed time was enough to fully burn out that current fuel item.
--- @param campfire_pos table position of the campfire node
--- @param campfire_meta NodeMetaRef the campfire metadata
--- @param campfire_inv InvRef the campfire inventory
--- @param burnout_time number how many seconds to fully burn/cook and turn into the next item
--- @param data table contains values for 'elapsed_time_remain' and 'elapsed_time_used'
--- @param elapsed_time number how many seconds of burn time to simulate upon the campfire tool
--- @param item_type string should always be 'current_fuel_item'
local function burnout_current_fuel_item(campfire_pos, campfire_meta, campfire_inv, burnout_time, data, elapsed_time, item_type)
	debug(flag20, "\n    burnout_current_fuel_item()")
	--debug(flag20, "      burnout_time: " .. burnout_time)

	if data.elapsed_time_used then
		--debug(flag21, "      this is a subsequent burnout action")
		elapsed_time = data.elapsed_time_used
		--debug(flag21, "      elapsed_time value is taken from prior burnout action: " .. elapsed_time)
	else
		--debug(flag21, "      this is the 1st running burnout action")
		--debug(flag21, "      elapsed_time value is taken from main context: " .. elapsed_time)
	end

	local burnout_time_remaining = burnout_time - elapsed_time
	--debug(flag20, "      burnout_time_remaining: " .. burnout_time_remaining)

	if burnout_time_remaining > 0 then
		--debug(flag20, "      current fuel item still intact. updating burn time..")
		campfire_meta:set_int("burn_time_current_item", burnout_time_remaining)
		--debug(flag20, "      burn time reduced by " .. elapsed_time)
		local burn_time_extra = campfire_meta:get_int("burn_time_extra")
		--debug(flag20, "      burn_time_extra: " .. burn_time_extra)
		campfire_meta:set_int("burn_time_extra", burn_time_extra - elapsed_time)
		--debug(flag20, "      burn_time_extra_remaining: " .. campfire_meta:get_int("burn_time_extra"))

		data.elapsed_time_used = elapsed_time

	elseif burnout_time_remaining == 0 then
		--debug(flag20, "      current fuel item burned out, and all elapsed time now applied.")
		campfire_meta:set_int("burn_time_current_item", 0)
		campfire_meta:set_string("current_fuel_item_inv_image", "")
		campfire_meta:set_string("current_fuel_item_name", "")

		local burn_time_extra = campfire_meta:get_int("burn_time_extra")
		--debug(flag20, "      burn_time_extra: " .. burn_time_extra)
		campfire_meta:set_int("burn_time_extra", burn_time_extra - elapsed_time)
		--debug(flag20, "      burn_time_extra_remaining: " .. campfire_meta:get_int("burn_time_extra"))

		data.elapsed_time_used = burnout_time

	else
		--debug(flag20, "      current fuel item burned out, and elapsed time still remain..")
		campfire_meta:set_int("burn_time_current_item", 0)
		campfire_meta:set_string("current_fuel_item_inv_image", "")
		campfire_meta:set_string("current_fuel_item_name", "")

		local burn_time_extra = campfire_meta:get_int("burn_time_extra")
		--debug(flag20, "      burn_time_extra: " .. burn_time_extra)
		campfire_meta:set_int("burn_time_extra", burn_time_extra - burnout_time)
		--debug(flag20, "      burn_time_extra_remaining: " .. campfire_meta:get_int("burn_time_extra"))

		data.elapsed_time_remain = -burnout_time_remaining
		data.elapsed_time_used = burnout_time
	end

	debug(flag20, "    burnout_current_fuel_item() END")
end


local flag39 = false
-- This function simulates the heating / cooking of 'item' across 'duration' amount
-- of time, and ensures the ingredient item converts to its next form when fully
-- heated/cooked. during normal campfire execution, 'duration' is 1 as the heat/cook
-- cycle loops once per second. 'duration' is typically > 1 when this function is
-- called due to campfire reactivation: when player had travelled away from lit
-- campfire and then returned, reactivating the map chunk, requiring the full elapsed
-- time duration to be applied all at once.
--- @param item ItemStack the item to be heated/cooked
--- @param slot_index number the indredient slot index the item is in
--- @param node_inv InvRef the campfire node inventory
--- @param pos table position of the campfire node
--- @param duration number the amount of time in seconds to heat/cook 'item'
local function cook_ingredient(item, slot_index, node_inv, pos, duration)
	debug(flag39, "    cook_ingredient()")

	local item_name = item:get_name()
	--debug(flag39, "      item_name: " .. item_name)

	local item_meta = item:get_meta()
	--debug(flag39, "      item_meta: " .. dump(item_meta:to_table()))

	local heat_progress = item_meta:get_float("heat_progress")
	--debug(flag39, "      current heat_progress: " .. heat_progress)
	local heat_rate = ITEM_HEAT_RATES[item_name]
	--debug(flag39, "      heat_rate: " .. heat_rate)
	-- heat_rate = 1539  -- for testing

	-- charcoal is the only item that can result in quantity greater than 1 within
	-- ingredient slot due to cooking wooden items. ensure the heating rate/speed
	-- is decreased for the stack of charcol based on its count/quantity.
	local quantity = 1
	if item_name == "ss:charcoal" then
		--debug(flag39, "      this is charcoal")
		quantity = item:get_count()
		--debug(flag39, "      quantity: " .. quantity)
		if quantity > 1 then
			--debug(flag39, "      quantity is more than 1. reducing heat rate by quantity factor..")
			--debug(flag39, "      current heat_rate: " .. heat_rate)
			heat_rate = heat_rate / quantity
			--debug(flag39, "      new heat_rate: " .. heat_rate)
		end
	end

	-- during normal campfire use, 'duration' is 1 second, but can be much longer
	-- due to player returning to an lit campfire that was previously unloaded and
	-- thus it needs to apply all elapsed time since the campfire was unloaded
	--debug(flag39, "      duration: " .. duration)
	heat_rate = heat_rate * duration
	--debug(flag39, "      heat_rate x duration: " .. heat_rate)

	local random_modifier = heat_rate * math_random(-15,15) * 0.01
	--debug(flag39, "      random_modifier: " .. random_modifier)
	heat_rate = heat_rate + random_modifier
	--debug(flag39, "      heat_rate + random_modifier: " .. heat_rate)
	heat_progress = heat_progress + heat_rate
	--debug(flag39, "      new heat_progress: " .. heat_progress)

	if heat_progress < COOK_THRESHOLD then
		--debug(flag39, "      ingredient still cooking further..")
		update_meta_and_description(item_meta, item_name, {"heat_progress"}, {heat_progress})
		node_inv:set_stack("ingredients", slot_index, item)

	else
		--debug(flag39, "      ***** INGREDIENT COOKED *****")
		play_sound("campfire_cooked", {pos = pos})

		-- give experience to the player assigned as the 'cooker' for the item
		local cooker = item_meta:get_string("cooker")
		--debug(flag39, "      awarding xp to the cooker: " .. cooker)
		local p_data = player_data[cooker]
		local xp_gain_cooking = player_data[cooker].experience_gain_cooking * quantity * p_data.experience_rec_mod_fast_learner
		--debug(flag39, "      xp_gain_cooking: " .. xp_gain_cooking)

		-- store xp to mod storage if player is offline to ensure it is awarded
		-- once player reterns to game
		local player = mt_get_player_by_name(cooker)
		if player then
			do_stat_update_action(player, p_data, player:get_meta(), "normal", "experience", xp_gain_cooking, "curr", "add", true)
			--debug(flag39, "      player XP increased successfully")
		else
			--debug(flag39, "      player offline: " .. cooker)
			--debug(flag39, "      saving XP gain for when player returns..")
			local meta_key = "xp_cooking_" .. cooker
			local existing_xp_cooking_owed = mod_storage:get_float(meta_key)
			--debug(flag39, "      existing_xp_cooking_owed: " .. existing_xp_cooking_owed)
			local total_xp_owed = existing_xp_cooking_owed + xp_gain_cooking
			--debug(flag39, "      total_xp_owed: " .. total_xp_owed)
			mod_storage:set_float(meta_key, total_xp_owed)
		end

		--debug(flag39, "      current item_meta: " .. dump(item_meta:to_table()))

		--debug(flag39, "      getting next item variant in the cook path")
		local next_items = ITEM_COOK_PATH[item_name]
		local next_item = ItemStack(next_items[1] .. " " .. quantity)
		local next_item_name = next_item:get_name()
		--debug(flag39, "      next_item_name: " .. next_item_name)

		-- transfer metadata from prior ingred item to this next ingred item if
		-- appropriate. ash and charcoal receives no or limited metadata.

		local next_item_meta = next_item:get_meta()
		if next_item_name == "ss:ash" then
			--debug(flag39, "      this is ash. no metadata transferred.")

		elseif next_item_name == "ss:charcoal" then
			--debug(flag39, "      this is charcoal. transferring only 'cooker' metadata..")
			next_item_meta:set_string("cooker", cooker)
			--debug(flag39, "      transferred cooker: " .. cooker)

		elseif HEAT_DESTRUCT_CONTAINERS[item_name] then
			--debug(flag39, "      cooked an empty heat destructable container")
			mt_after(0.25, play_sound, "item_break", {item_name = item_name, pos = pos})

		else

			-- transfer 'cooker' data
			next_item_meta:set_string("cooker", cooker)
			--debug(flag39, "      transferred cooker: " .. cooker)

			-- transfer 'remaining_uses' if the next resulting item is a consumable
			-- item and if the prior cooked item had more uses to transfer
			if ITEM_MAX_USES[next_item_name] then
				local remaining_uses = item_meta:get_int("remaining_uses")
				if remaining_uses > 0 then
					update_meta_and_description(next_item_meta, next_item_name, {"remaining_uses"}, {remaining_uses})
				end
			end

			-- if the cooked item was a food container, decrease its condition and
			-- transfer it to the next item
			local condition = item_meta:get_float("condition")
			if CONTAINER_WEAR_RATES[item_name] then
				--debug(flag39, "      decreasing food container condition..")
				local wear_rate = CONTAINER_WEAR_RATES[item_name]
				--debug(flag39, "      wear_rate: " .. wear_rate)
				local random_mod = wear_rate * math_random(-15,15) * 0.01
				--debug(flag39, "      random_mod: " .. random_mod)
				wear_rate = wear_rate + random_mod
				--debug(flag39, "      wear_rate + random_mod: " .. wear_rate)
				if condition == 0 then
					--debug(flag39, "      this item has no wear. 'condition' intialized to: " .. WEAR_VALUE_MAX)
					condition = WEAR_VALUE_MAX
				end
				condition = condition - wear_rate
				--debug(flag39, "      new condition: " .. condition)
				if condition > 0 then
					--debug(flag39, "      food container still usable")
					update_meta_and_description(next_item_meta, next_item_name, {"condition"}, {condition})

				else
					--debug(flag39, "      food container worn out and destroyed")
					next_items = ITEM_DESTRUCT_PATH[item_name]
					next_item = ItemStack(next_items[1])
					--debug(flag39, "      resulting item name: " .. next_item:get_name())
					next_item_meta = next_item:get_meta()
					next_item_meta:set_string("cooker", cooker)
					mt_after(0.25, play_sound, "item_break", {item_name = item_name, pos = pos})
				end
			else
				--debug(flag39, "      not a food container")
				if condition > 0 then
					next_item_meta:set_float("condition", condition)
					--debug(flag39, "      transferred condition: " .. condition)
				end
			end
		end

		--debug(flag39, "      next_item_meta: " .. dump(next_item_meta:to_table()))
		node_inv:set_stack("ingredients", slot_index, next_item)

		-- drop secondary result item (if exists) to the ground
		local dropped_item = next_items[2]
		if dropped_item then
			--debug(flag39, "      dropping secondary item: " .. dropped_item)
			mt_add_item(pos, ItemStack(dropped_item))
		end

		-- if this cook cycle was triggered by player returning to a lit campfire
		-- where its residing mapchunk was reloaded, see if elapsed cook time was
		-- enough to heat/cook the item into its next item result in ITEM_COOK_PATH.
		if duration > 1 then
			--debug(flag39, "      ** this cook cycle due to mapchunk reload **")
			local overheat_amount = heat_progress - COOK_THRESHOLD
			--debug(flag39, "      overheat_amount: " .. overheat_amount)
			local overheat_duration = overheat_amount / heat_rate
			--debug(flag39, "      overheat_duration: " .. overheat_duration)
			if overheat_duration > 0 then
				--debug(flag39, "      there is leftover heat/cook time")
				if ITEM_COOK_PATH[next_item_name] then
					--debug(flag39, "      proceed to heat/cook the next item..")
					cook_ingredient(next_item, slot_index, node_inv, pos, overheat_duration)
				else
					--debug(flag39, "      next item is nonflammable. NO FURTHER ACTION.")
				end
			end
		else
			--debug(flag39, "      end of standard cook cycle")
		end

	end

	debug(flag39, "    cook_ingredient() end")
end


local flag45 = false
-- heat/cook ingredient items across all ingredient slot, applying the same heat/cook
-- 'duration' to each ingredient item
--- @param pos table position of the campfire node
--- @param node_inv InvRef the campfire node inventory
--- @param duration number the amount of time in seconds to heat/cook 'item'
local function cook_ingredient_all(pos, node_inv, duration)
	debug(flag45, "      cook_ingredient_all()")

	local node_meta = mt_get_meta(pos)
	local slot_count = node_meta:get_int("slot_count_ingredients")
	local ingredient_slots = node_inv:get_list("ingredients")
	--debug(flag45, "      ingredient_slots: " .. dump(ingredient_slots))
	for i = 1, slot_count do
		local ingred_item = ingredient_slots[i]
		if ingred_item:is_empty() then
			--debug(flag45, "    Ingred Slot #" .. i .. " is EMPTY")
		else
			local ingred_item_name = ingred_item:get_name()
			--debug(flag45, "    Ingred Item #" .. i .. ": " .. ingred_item_name)
			cook_ingredient(ingred_item, i, node_inv, pos, duration)
		end
	end
	debug(flag45, "      cook_ingredient_all() END")
end


local flag37 = false
-- simulate burn duration of 'elapsed_time' onto the an item in the ingredient slot.
-- the 'data' table is then updated to reflect whether or not the elapsed time was
-- enough to fully heat/cook that ingredient item to turn into its next form.
--- @param campfire_pos table position of the campfire node
--- @param campfire_meta NodeMetaRef the campfire metadata
--- @param campfire_inv InvRef the campfire inventory
--- @param burnout_time number how many seconds to fully burn/cook and turn into the next item
--- @param data table contains values for 'elapsed_time_remain' and 'elapsed_time_used'
--- @param elapsed_time number how many seconds of burn time to simulate upon the campfire tool
--- @param item_type string should always be 'ingredient_item'
local function burnout_ingredient_item(campfire_pos, campfire_meta, campfire_inv, burnout_time, data, elapsed_time, item_type)
	debug(flag37, "\n    burnout_ingredient_item()")
	--debug(flag37, "      item_type: " .. item_type)
	--debug(flag37, "      burnout_time: " .. burnout_time)

	local item_type_tokens = string_split(item_type)
	local slot_index = item_type_tokens[2]
	--debug(flag37, "      slot_index: " .. slot_index)
	local item = campfire_inv:get_stack("ingredients", slot_index)

	if item:is_empty() then
		-- the ingredient item was previously dropped to the ground because the slot
		-- was removed due to the campfire tool being worn out and destroyed
		--debug(flag37, "      empty slot due to item dropped to ground. NO FURTHER ACTION.")
		if data.elapsed_time_used then
			--debug(flag37, "      data.elapsed_time_used: " .. data.elapsed_time_used)
		else
			--debug(flag37, "      data.elapsed_time_used is NIL")
		end

	else
		local item_name = item:get_name()
		--debug(flag37, "      item_name: " .. item_name)

		if data.elapsed_time_used then
			--debug(flag37, "      this is a subsequent burnout action")
			elapsed_time = data.elapsed_time_used
			--debug(flag37, "      elapsed_time taken from prior burnout action: " .. elapsed_time)
		else
			--debug(flag37, "      this is the 1st running burnout action")
			--debug(flag37, "      elapsed_time taken from main context: " .. elapsed_time)
		end

		if elapsed_time == 0 then
			--debug(flag37, "      no 'current fuel item' was present. heating/cooking will be simulated at later phase.")
			data.elapsed_time_used = elapsed_time

		else
			--debug(flag37, "      'current fuel item' was present. heating/cooking based on that state..")
			cook_ingredient(item, slot_index, campfire_inv, campfire_pos, elapsed_time)
			data.elapsed_time_used = elapsed_time
		end
	end

	debug(flag37, "    burnout_ingredient_item() END")
end


local flag49 = false
local function heat_node(pos, location, duration)
	debug(flag49, "\n    heat_node()")

	local node = mt_get_node(pos)
	local node_name = node.name
	--debug(flag49, "      [" .. location .. "] " .. node_name .. " " .. mt_pos_to_string(pos))

	-- when a campfire burns out a node above, which above that is default:snow,
	-- the snow falls onto the campfire. code below ensures the snow turns into
	-- water and causes the campfire to get destroyed and drop its contents.
	if location == "top" then
		--debug(flag49, "      this is a top node")
		if node_name == "default:snow" then
			--debug(flag49, "      soft snow on top of the campfire. dropping snow/water and campfire..")
			mt_remove_node(pos)
			mt_remove_node(pos)
			mt_set_node(pos, {name = "default:water_flowing"})
		end
	end

	local node_cook_data = COOK_NODES[node_name]
	local cook_time = node_cook_data.cook_time
	-- cook_time = 10 -- for  ses
	--debug(flag49, "      cook_time: " .. cook_time)

	local node_meta = mt_get_meta(pos)
	local heat_progress = node_meta:get_float("heat_progress")
	--debug(flag49, "      curr heat_progress: " .. heat_progress)
	local heat_rate = COOK_THRESHOLD / cook_time
	--debug(flag49, "      heat_rate: " .. heat_rate)
	--debug(flag49, "      duration: " .. duration)
	heat_rate = heat_rate * duration
	--debug(flag49, "      heat_rate x duration: " .. heat_rate)

	local random_modifier = heat_rate * math_random(-15,15) * 0.01
	--debug(flag49, "      random_modifier: " .. random_modifier)
	heat_rate = heat_rate + random_modifier
	--debug(flag49, "      heat_rate + random_modifier: " .. heat_rate)
	heat_progress = heat_progress + heat_rate
	--debug(flag49, "      new heat_progress: " .. heat_progress)


	if heat_progress < COOK_THRESHOLD then
		--debug(flag49, "      node still heating and not yet destroyed..")
		node_meta:set_float("heat_progress", heat_progress)

	else
		--debug(flag49, "     *** NODE IS COOKED! ***")
		node_meta:set_float("heat_progress", 0)

		local action_type = node_cook_data.action_type
		--debug(flag49, "      action_type: " .. action_type)
		if action_type == "drop" then
			--debug(flag49, "      destroying node..")
			mt_remove_node(pos)
			for j, item_drop in ipairs(node_cook_data.drops) do
				local item_drop_name = item_drop:get_name()
				--debug(flag49, "      item drop #" .. j .. ": " .. item_drop_name)

				-- add random heat progress to the item drop only if it's
				-- a heatable/flammable item
				if ITEM_COOK_PATH[item_drop_name] then
					--debug(flag49, "        this item is flammable/cookable")
					local item_drop_count = item_drop:get_count()
					for k = 1, item_drop_count do
						local random_heat_progress = math_random(1, COOK_THRESHOLD)
						local heated_item = ItemStack(item_drop_name)
						local item_meta = heated_item:get_meta()

						-- if the item drop is consumable, add remaining_uses metadata
						if ITEM_MAX_USES[item_drop_name] then
							--debug(flag49, "        this item is also consumable")
							update_meta_and_description(
								item_meta,
								item_drop_name,
								{"remaining_uses", "heat_progress"},
								{ITEM_MAX_USES[item_drop_name], random_heat_progress}
							)
							--debug(flag49, "          count [#" .. k .. "] " .. item_drop_name
							--	.. ", new cook progres = " .. random_heat_progress
							--	.. ", new remaining uses = " .. ITEM_MAX_USES[item_drop_name])
						else
							update_meta_and_description(
								item_meta,
								item_drop_name,
								{"heat_progress"},
								{random_heat_progress}
							)
							--debug(flag49, "          count [#" .. k .. "] ".. item_drop_name
							--	.. ", new cook progres = " .. random_heat_progress)
						end

						mt_add_item({
							x = pos.x + math_random(-2, 2) * 0.1,
							y = pos.y,
							z = pos.z + math_random(-2, 2) * 0.1}, heated_item)
					end
				else
					--debug(flag49, "        this is nonflammable. no heat applied.")
					mt_add_item(pos, item_drop)
				end


			end

			--debug(flag49, "      inspecting adj top node..")
			local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
			local top_pos_node = mt_get_node(top_pos)
			local top_pos_node_name = top_pos_node.name
			--debug(flag49, "      top_pos_node_name: " .. top_pos_node_name)

			if CAMPFIRE_NODE_NAMES[top_pos_node_name] then
				--debug(flag49, "      ** it's a campfire **")
				mt_remove_node(top_pos)
				--debug(flag49, "      removed campfire")

			elseif top_pos_node_name == "default:snow" then
				--debug(flag49, "      it's soft snow")
				mt_check_for_falling(top_pos)

			else
				--debug(flag49, "      not a campfire or soft snow")
			end

		elseif action_type == "replace" then
			local target_node = node_cook_data.node
			local target_node_name = target_node.name
			--debug(flag49, "      replacing node with: " .. target_node_name)
			mt_set_node(pos, target_node)
			if target_node_name == "default:water_flowing" then

				--debug(flag49, "      inspecting adj top node..")
				local top_pos = {x = pos.x, y = pos.y + 1, z = pos.z}
				local top_pos_node = mt_get_node(top_pos)
				local top_pos_node_name = top_pos_node.name
				--debug(flag49, "      top_pos_node_name: " .. top_pos_node_name)

				if CAMPFIRE_NODE_NAMES[top_pos_node_name] then
					--debug(flag49, "      ** it's a campfire **")
					mt_remove_node(top_pos)
					--debug(flag49, "      removed campfire")

				elseif top_pos_node_name == "default:snow" then
					--debug(flag49, "      it's soft snow")
					mt_check_for_falling(top_pos)

				else
					--debug(flag49, "      inspecting adj bottom node..")
					local bottom_pos = {x = pos.x, y = pos.y - 1, z = pos.z}
					local bottom_pos_node = mt_get_node(bottom_pos)
					local bottom_pos_node_name = bottom_pos_node.name
					--debug(flag49, "      bottom_pos_node_name: " .. bottom_pos_node_name)

					if CAMPFIRE_NODE_NAMES[bottom_pos_node_name] then
						--debug(flag49, "      ** it's a campfire **")
						--debug(flag49, "      dropping water on campfire")
						mt_remove_node(bottom_pos)
						mt_set_node(bottom_pos, target_node)
					else
						--debug(flag49, "      not a campfire")
					end
				end

			else
				--debug(flag49, "      replacement node is not water")

				-- apply any heat_progress that went beyond that COOK_THRESHOLD
				-- into the replacement node
				local heat_overage = heat_progress - COOK_THRESHOLD
				--debug(flag49, "      heat_overage: " .. heat_overage)
				if heat_overage > 0 then
					local new_meta = mt_get_meta(pos)
					new_meta:set_float("heat_progress", heat_overage)
				end
			end

		elseif action_type == "destruct" then

			if BAG_NODE_NAMES_ALL[node_name] then
				--debug(flag49, "      this is a storage node. not dropping the storage item itself.")

				-- set storage node's condition to -1 to signify to its on_destruct()
				-- to not drop the storage item itself (since it was burn out from
				-- the nearby campfire)
				node_meta:set_float("condition", -1)

				-- drop the cook result of the storage item (for now, it's always ash)
				local storage_item_drop = ItemStack("ss:ash")
				mt_add_item(pos, storage_item_drop)
			end

			--debug(flag49, "      triggering node's on-destruct..")
			mt_remove_node(pos)

		else
			debug(flag49, "      ERROR - Unexpected 'action_type' value: " .. action_type)
		end

	end

	debug(flag49, "    heat_node() END")
end


local flag48 = false
-- simulate burn duration of 'elapsed_time' onto adjacent nodes in the world.
-- the 'data' table is then updated to reflect whether or not the elapsed time was
-- enough to fully heat/cook that node to turn into its next form or drop item.
--- @param campfire_pos table position of the campfire node
--- @param campfire_meta NodeMetaRef the campfire metadata
--- @param campfire_inv InvRef the campfire inventory
--- @param burnout_time number how many seconds to fully burn/cook and turn into the next item
--- @param data table contains values for 'elapsed_time_remain' and 'elapsed_time_used'
--- @param elapsed_time number how many seconds of burn time to simulate upon the campfire tool
--- @param item_type string should always be 'ingredient_item'
local function burnout_adjacent_node(campfire_pos, campfire_meta, campfire_inv, burnout_time, data, elapsed_time, item_type)
	debug(flag48, "\n    burnout_adjacent_node()")
	--debug(flag48, "      item_type: " .. item_type)
	--debug(flag48, "      burnout_time: " .. burnout_time)

	local item_type_tokens = string_split(item_type, " ")
	--debug(flag48, "      item_type_tokens: " .. dump(item_type_tokens))
	local location = item_type_tokens[2]
	--debug(flag48, "      location: " .. location)
	local pos_key = item_type_tokens[3]
	--debug(flag48, "      pos_key: " .. pos_key)
	local pos = key_to_pos(pos_key)
	--debug(flag48, "      pos: " .. mt_pos_to_string(pos))

	if data.elapsed_time_used then
		--debug(flag48, "      this is a subsequent burnout action")
		elapsed_time = data.elapsed_time_used
		--debug(flag48, "      elapsed_time taken from prior burnout action: " .. elapsed_time)
	else
		--debug(flag48, "      this is the 1st running burnout action")
		--debug(flag48, "      elapsed_time taken from main context: " .. elapsed_time)
	end

	if elapsed_time == 0 then
		--debug(flag48, "      no 'current fuel item' was present. heating/cooking will be simulated at later phase.")
		data.elapsed_time_used = elapsed_time

	else
		--debug(flag48, "      'current fuel item' was present. heating node based on that state..")
		heat_node(pos, location, elapsed_time)
		data.elapsed_time_used = elapsed_time
	end

	debug(flag48, "    burnout_adjacent_node() END")
end



local flag15 = false
local function get_fuel_item_count(player, node_meta, item)
	debug(flag15, "get_fuel_item_count()")
	local max_fuel_weight = node_meta:get_float("weight_fuel_max")
	local curr_fuel_weight = node_meta:get_float("weight_fuel_total")
	local available_weight = max_fuel_weight - curr_fuel_weight
	local item_name = item:get_name()

	local item_count, individual_item_weight
	if item_name == "ss:item_bundle" then
		--debug(flag15, "  this is an item bundle")
		local item_meta = item:get_meta()
		item_count = 1
		individual_item_weight = item_meta:get_float("bundle_weight")
	else
		--debug(flag15, "  this is a normal item stack")
		item_count = item:get_count()
		individual_item_weight = ITEM_WEIGHTS[item:get_name()]
	end

	-- take only the whole number result
	local item_count_that_fits = math_floor(available_weight / individual_item_weight)
	--debug(flag15, "  available_weight: " .. available_weight)
	--debug(flag15, "  item_count_that_fits: " .. item_count_that_fits)

	if item_count_that_fits < item_count then
		if item_count_that_fits > 0 then
			--debug(flag15, "  itemstack partial amount fit")
			notify(player, "inventory", "Only " .. item_count_that_fits
				.. " could be added due to max weight.", NOTIFY_DURATION, 0.5, 0, 2)
		else
			--debug(flag15, "  itemstack too heavy to fit")
			notify(player, "inventory", "Exceeds max fuel weight", NOTIFY_DURATION, 0, 0.5, 3)
		end
	else
		--debug(flag15, "  full itemstack amount fit")
	end

	debug(flag15, "get_fuel_item_count() end")
	return item_count_that_fits
end


local flag31 = false
local function start_smoke_particles(pos)
	debug(flag31, "  start_smoke_particles()")
	local particle_id = mt_add_particlespawner({
        amount = 5,
        time = 0,
        minpos = {x=pos.x-0.2, y=pos.y+0.0, z=pos.z-0.2},
        maxpos = {x=pos.x+0.2, y=pos.y+0.3, z=pos.z+0.2},
        minvel = {x=0, y=0.20, z=0},
        maxvel = {x=0, y=0.70, z=0},
        minacc = {x=0, y=0, z=0},
        maxacc = {x=0, y=0, z=0},
        minexptime = 1,
        maxexptime = 1.8,
        minsize = 0.5,
        maxsize = 1.0,
		texture = "[fill:1x1:#808080",
        glow = 0,
    })
	local node_id = mt_hash_node_position(pos)
	particle_ids[node_id] = particle_id
	--debug(flag31, "    particle_id: " .. particle_id)
	--debug(flag31, "    particle_ids table: " .. dump(particle_ids))
	debug(flag31, "  start_smoke_particles() END")
end


local flag30 = false
local function stop_smoke_particles(pos)
	debug(flag30, "  stop_smoke_particles()")
	local node_id = mt_hash_node_position(pos)
	local particle_id = particle_ids[node_id]
	--debug(flag30, "    particle_id: " .. particle_id)
    mt_delete_particlespawner(particle_id)
	particle_ids[node_id] = nil
	--debug(flag31, "    particle_ids table: " .. dump(particle_ids))
	debug(flag30, "  stop_smoke_particles() END")
end


local flag18 = false
local function stop_campfire(pos, pos_key, node_meta)
	debug(flag18, "    stop_campfire()")

	--debug(flag18, "      update campfire ui to reflect 'off' state")
	node_meta:set_string("campfire_status", "off")
	refresh_formspec(pos, pos_key)

	--debug(flag18, "      playing campfire off sound")
	play_sound("campfire_stop" , {pos = pos})

	--debug(flag18, "      checking cooking status of each ingred item..")
	local node_inv = node_meta:get_inventory()
	local ingredient_slots = node_inv:get_list("ingredients")
	for i, ingredient_item in ipairs(ingredient_slots) do
		--debug(flag18, "      slot #" .. i)
		if ingredient_item:is_empty() then
			--debug(flag18, "        empty slot")
		else
			local ingredient_item_name = ingredient_item:get_name()
			--debug(flag18, "        ingredient item found: " .. ingredient_item_name)
			reset_cook_data(ingredient_item)
			node_inv:set_stack("ingredients", i, ingredient_item)
		end
	end

	--debug(flag18, "      deactivating node timer...")
	local node_timer = mt_get_node_timer(pos)
	node_timer:stop()

	--debug(flag18, "      replace campfire node to ss:campfire_small_used...")
	mt_swap_node(pos, {name = "ss:campfire_small_used"})

	--debug(flag18, "      removing campfire smoke effect")
	stop_smoke_particles(pos)

	--debug(flag18, "      removing campfire from radiant sources")
	radiant_sources[pos_key] = nil

	debug(flag18, "    stop_campfire() END")
end




local flag36 = false
local function get_burnt_drops(item_name, count)
	debug(flag36, "  get_burnt_drops()")
	local burnt_items = {}

	for i = 1, count do
		--debug(flag36, "    item #" .. i)

		-- generate random heat progress
		local heat_progress = math_random(1, COOK_THRESHOLD)
		--debug(flag36, "      random heat_progress: " .. heat_progress)

		-- save heat progress value to item meta data
		local burnt_item = ItemStack(item_name)
		local item_meta = burnt_item:get_meta()
		update_meta_and_description(item_meta, item_name, {"heat_progress"}, {heat_progress})

		table_insert(burnt_items, burnt_item)
	end

	debug(flag36, "  get_burnt_drops() END")
	return burnt_items
end


local flag42 = false
-- drop.items{} property is nil for campfires. instead this function handles what items are
-- dropped when a campfire is dug, falls, or whatever instance that triggers on_destruct().
local function drop_campfire_drops(campfire_pos, campfire_name)
	debug(flag42, "  drop_campfire_drops()")

	if campfire_name == "ss:campfire_small_new" then
		local item_drops = {
			ItemStack("ss:wood 4"),
			ItemStack("ss:stick 4")
		}
		for i, item in ipairs(item_drops) do
			mt_add_item({
				x = campfire_pos.x + math_random(-2, 2) * 0.1,
				y = campfire_pos.y,
				z = campfire_pos.z + math_random(-2, 2) * 0.1}, item)
		end

	elseif campfire_name == "ss:campfire_small_spent" then
		local item_drops = {
			ItemStack("ss:charcoal " .. math_random(3,5)),
			ItemStack("ss:ash " .. math_random(3,5)),
		}

		for i, item in ipairs(item_drops) do
			mt_add_item({
				x = campfire_pos.x + math_random(-2, 2) * 0.1,
				y = campfire_pos.y,
				z = campfire_pos.z + math_random(-2, 2) * 0.1}, item)
		end

	-- either a burning or used campfire
	else

		if campfire_name == "ss:campfire_small_burning" then
			stop_smoke_particles(campfire_pos)
		end

		local item_drops = {
			ItemStack("ss:wood " .. math_random(1,2)),
			ItemStack("ss:stick " .. math_random(1,2)),
			ItemStack("ss:charcoal " .. math_random(2,3)),
		}
		local burnt_items = get_burnt_drops("ss:wood", math_random(1,2))
		for i, burnt_item in ipairs(burnt_items) do
			table_insert(item_drops, burnt_item)
		end
		burnt_items = get_burnt_drops("ss:stick", math_random(1,2))
		for i, burnt_item in ipairs(burnt_items) do
			table_insert(item_drops, burnt_item)
		end

		for i, item in ipairs(item_drops) do
			mt_add_item({
				x = campfire_pos.x + math_random(-2, 2) * 0.1,
				y = campfire_pos.y,
				z = campfire_pos.z + math_random(-2, 2) * 0.1}, item)
		end
	end
	debug(flag42, "  drop_campfire_drops() END")
end


local flag28 = false
local function check_timer_active_1(pos)
	debug(flag28, "\n  check_campfire #1()")

	local node_meta = mt_get_meta(pos)
	local is_timer_active = node_meta:get_int("is_timer_active")
	if is_timer_active == 1 then
		--debug(flag28, "    campfire still loaded")
		node_meta:set_int("is_timer_active", 0)
	else
		--debug(flag28, "    ** campfire NOT loaded **")
	end

	debug(flag28, "  check_campfire() END")
end


local flag29 = false
local function check_timer_active_2(pos)
	debug(flag29, "\n  check_timer_active_2")

	local campfire_meta = mt_get_meta(pos)
	local is_timer_active = campfire_meta:get_int("is_timer_active")

	if is_timer_active == 1 then
		--debug(flag29, "    campfire is loaded")
		local unload_time = campfire_meta:get_int("unload_time")

		if unload_time > 0 then
			--debug(flag29, "    ** campfire reloaded ** ")
			radiant_sources[pos_to_key(pos)] = RADIANT_SOURCES_DATA["ss:campfire_small_burning"]
			--debug(flag29, "    campfire added as radiant source")

			local campfire_inv = campfire_meta:get_inventory()

			-- determine the amount of elapsed time that the campfire was unloaded from
			-- the world and now needs to be applied retro-actively to campfire items
			-- like the campfire fuel, campfire tools, and cooking ingredients
			local current_time = mt_get_gametime()
			local elapsed_time = current_time - unload_time
			--debug(flag29, "    ELAPSED TIME: " .. elapsed_time .. " = " .. current_time .. " - " .. unload_time)

			-- stores burnout time and an action function relating to the campfire items:
			-- current fuel item, campfire stand, campfire grill, and ingredient items.
			local campfire_items_burnout_data = {}
			local burn_time_remaining

			-- get info on the current fuel item
			burn_time_remaining = campfire_meta:get_int("burn_time_current_item")
			table_insert(campfire_items_burnout_data, {
				item_type = "current_fuel_item",
				burnout_time = burn_time_remaining,
				burnout_action = burnout_current_fuel_item
			})

			-- get remaining burn time of campfire STAND tool
			local campfire_stand_item = campfire_inv:get_stack("campfire_stand", 1)
			if campfire_stand_item:is_empty() then
				--debug(flag29, "    Campfire Stand UNUSED")
			else
				--debug(flag29, "    Campfire Stand EQUIPPED")
				local item_meta = campfire_stand_item:get_meta()
				local condition = item_meta:get_float("condition")
				--debug(flag29, "      condition: " .. condition)
				if condition == 0 then
					--debug(flag29, "      this stand is unused. condition initialized to 10000")
					condition = WEAR_VALUE_MAX
				end
				burn_time_remaining = math_ceil(condition / TOOL_WEAR_RATES.campfire_stand)
				--debug(flag29, "      burn_time_remaining: " .. burn_time_remaining)
				table_insert(campfire_items_burnout_data, {
					item_type = "campfire_stand",
					burnout_time = burn_time_remaining,
					burnout_action = burnout_campfire_tool
				})
			end

			-- get remaining burn time of campfire GRILL tool
			local campfire_grill_item = campfire_inv:get_stack("campfire_grill", 1)
			if campfire_grill_item:is_empty() then
				--debug(flag29, "    Campfire Grill UNUSED")
			else
				--debug(flag29, "    Campfire Grill EQUIPPED")
				local item_meta = campfire_grill_item:get_meta()
				local condition = item_meta:get_float("condition")
				--debug(flag29, "      condition: " .. condition)
				if condition == 0 then
					--debug(flag29, "      this grill is unused. condition initialized to 10000")
					condition = WEAR_VALUE_MAX
				end
				burn_time_remaining = math_ceil(condition / TOOL_WEAR_RATES.campfire_grill)
				--debug(flag29, "      burn_time_remaining: " .. burn_time_remaining)
				table_insert(campfire_items_burnout_data, {
					item_type = "campfire_grill",
					burnout_time = burn_time_remaining,
					burnout_action = burnout_campfire_tool
				})
			end

			-- get remaining burn times of any items in ingredient slots
			local slot_count = campfire_meta:get_int("slot_count_ingredients")
			local ingredient_slots = campfire_inv:get_list("ingredients")
			for i = 1, slot_count do
				local ingred_item = ingredient_slots[i]
				if ingred_item:is_empty() then
					--debug(flag29, "    Ingred Slot #" .. i .. " is EMPTY")
				else
					local ingred_item_name = ingred_item:get_name()
					--debug(flag29, "    Ingred Slot #" .. i .. ": " .. ingred_item_name)
					local item_meta = ingred_item:get_meta()
					local heat_progress = item_meta:get_float("heat_progress")
					--debug(flag29, "      heat_progress: " .. heat_progress)
					local heat_rate = ITEM_HEAT_RATES[ingred_item_name]
					--debug(flag29, "      heat_rate: " .. heat_rate)
					burn_time_remaining = math_ceil((COOK_THRESHOLD - heat_progress) / heat_rate)
					--debug(flag29, "      burn_time_remaining: " .. burn_time_remaining)
					table_insert(campfire_items_burnout_data, {
						item_type = "ingredient_item," .. i,
						burnout_time = burn_time_remaining,
						burnout_action = burnout_ingredient_item
					})
				end
			end

			-- stores all the adjacent positions of nodes that are actually flammable
			local adj_positions_flammable = {}

			-- get remaining burn times of adjacent nodes
			for location, adj_pos in pairs(ADJACENT_POSITIONS) do
				adj_pos = vector_add(pos, adj_pos)
				local adj_node = mt_get_node(adj_pos)
				local adj_node_name = adj_node.name
				--debug(flag29, "    [" .. location .. "] " .. adj_node_name .. "  " .. mt_pos_to_string(adj_pos))
				local node_cook_data = COOK_NODES[adj_node_name]
				if node_cook_data then
					--debug(flag29, "      this node is cookable")
					table_insert(adj_positions_flammable, {adj_pos, location})
					local cook_time = node_cook_data.cook_time
					local heat_rate = COOK_THRESHOLD/cook_time
					--debug(flag29, "      heat_rate: " .. heat_rate)
					local node_meta = mt_get_meta(adj_pos)
					local heat_progress = node_meta:get_float("heat_progress")
					--debug(flag29, "      heat_progress: " .. heat_progress)
					local heat_progress_remaining = COOK_THRESHOLD - heat_progress
					burn_time_remaining = math_ceil(heat_progress_remaining / heat_rate)
					--debug(flag29, "      burn_time_remaining: " .. burn_time_remaining)
					table_insert(campfire_items_burnout_data, {
						item_type = "node " .. location .. " " .. pos_to_key(adj_pos),
						burnout_time = burn_time_remaining,
						burnout_action = burnout_adjacent_node
					})
				else
					--debug(flag29, "      nonflammable node. skipped.")
				end
			end

			-- sort the campfire items (current fuel item, campfire stand, and campfire grill) by
			-- their 'burnout_item' from least to greatest
			table_sort(campfire_items_burnout_data, function(a, b) return a.burnout_time < b.burnout_time end)
			--debug(flag29, "    campfire_items_burnout_data (sorted): " .. dump(campfire_items_burnout_data))

			local data = {
				elapsed_time_remain = nil,
				elapsed_time_used = nil
			}

			-- call the 'burnout' function referenced by 'burnout_action' for each corresponding item_type.
			-- the 'data' table is used to track the 'elapsed_time_remain' and 'elapsed_time_used' value
			-- between each call of the burnout function:
			--   item_type >> burnout function name
			--   'current_fuel_item' >> burnout_current_fuel_item()
			--   'campfire_stand' >> burnout_campfire_tool()
			--   'campfire_grill' >> burnout_campfire_tool()
			--   'ingredient_item,[slot index]' >> burnout_ingredient_item()
			for _, element in ipairs(campfire_items_burnout_data) do

				element.burnout_action(
					pos,
					campfire_meta,
					campfire_inv,
					element.burnout_time,
					data,
					elapsed_time,
					element.item_type
				)
			end

			--debug(flag29, "\n    Elapsed time now applied to current fuel item and to any campfire tools")
			--debug(flag29, "    data: " .. dump(data))

			local remaining_elapsed_time = data.elapsed_time_remain or 0
			--debug(flag29, "    REMAINING ELAPSED TIME: " .. remaining_elapsed_time .. "\n")

			if remaining_elapsed_time > 0 then
				--debug(flag29, "    current fuel item burned out with elapsed time remaining: " .. remaining_elapsed_time)
				--debug(flag29, "    proceed to burn fuel slot items..")

				local node_inv = campfire_meta:get_inventory()
				local fuel_slots = node_inv:get_list("fuel")
				local fuel_slot_count = campfire_meta:get_int("slot_count_fuel")
				--debug(flag29, "    fuel_slot_count: " .. fuel_slot_count)

				for i = 1, fuel_slot_count do
					--debug(flag29, "    checking slot #" .. i)

					local fuel_itemstack = fuel_slots[i]
					if fuel_itemstack:is_empty() then
						--debug(flag29, "      no fuel item exists there")

					else
						local fuel_item_name = fuel_itemstack:get_name()
						--debug(flag29, "      fuel item found: " .. fuel_item_name)

						local item_burn_time, fuel_item_count
						if fuel_item_name == "ss:item_bundle" then
							--debug(flag29, "      an item bundle")
							local fuel_item_meta = fuel_itemstack:get_meta()
							item_burn_time = fuel_item_meta:get_int("bundle_burn_time")
							local inventory_image = fuel_item_meta:get_string("inventory_image")
							--debug(flag29, "      inventory_image: " .. inventory_image)
							fuel_item_count = 1
						else
							--debug(flag29, "      not an item bundle")
							item_burn_time = ITEM_BURN_TIMES[fuel_item_name]
							fuel_item_count = fuel_itemstack:get_count()
						end

						local itemstack_burn_time = item_burn_time * fuel_item_count
						--debug(flag29, "      itemstack_burn_time: " .. itemstack_burn_time)
						--debug(flag29, "      remaining_elapsed_time: " .. remaining_elapsed_time)

						local itemstack_burn_time_leftover = itemstack_burn_time - remaining_elapsed_time
						--debug(flag29, "      itemstack_burn_time_leftover: " .. itemstack_burn_time_leftover)

						-- item in fuel slot absorbed all remaining elapsed time with
						-- some fuel/burn time remaining
						if itemstack_burn_time_leftover > 0 then
							--debug(flag29, "      fuel slot " .. i .. " still has some " .. fuel_item_name .. " un-burned")
							--debug(flag29, "      removing the whole-number burned portions of this stack..")
							local consumed_item_count_raw = remaining_elapsed_time / item_burn_time
							--debug(flag29, "        consumed_item_count_raw: " .. consumed_item_count_raw)
							local consumed_item_count_whole = math_floor(consumed_item_count_raw)
							--debug(flag29, "        consumed_item_count_whole: " .. consumed_item_count_whole)
							local consumed_burn_time_whole = consumed_item_count_whole * item_burn_time
							--debug(flag29, "        consumed_burn_time_whole: " .. consumed_burn_time_whole)
							local consumed_burn_time_partial =  remaining_elapsed_time - consumed_burn_time_whole
							--debug(flag29, "        consumed_burn_time_partial: " .. consumed_burn_time_partial)

							-- calculate the resulting reduced count of the fuel itemstack
							local reduce_amount = math_ceil(consumed_item_count_raw)
							--debug(flag29, "      reducing stack amount by " .. reduce_amount)
							local current_stack_amount = fuel_itemstack:get_count()
							--debug(flag29, "      current_stack_amount: " .. current_stack_amount)
							local new_stack_amount = current_stack_amount - reduce_amount

							--debug(flag29, "      updating campfire fuel weight..")
							local weight_fuel_total = campfire_meta:get_float("weight_fuel_total")
							--debug(flag29, "        current weight_fuel_total: " .. weight_fuel_total)

							local fuel_weight_to_remove
							if fuel_item_name == "ss:item_bundle" then
								local fuel_item_meta = fuel_itemstack:get_meta()
								fuel_weight_to_remove = reduce_amount * fuel_item_meta:get_float("bundle_weight")
							else
								fuel_weight_to_remove = reduce_amount * ITEM_WEIGHTS[fuel_item_name]
							end
							--debug(flag29, "        fuel_weight_to_remove: " .. fuel_weight_to_remove)

							local new_weight_fuel_total = weight_fuel_total - fuel_weight_to_remove
							--debug(flag29, "        new_weight_fuel_total: " .. new_weight_fuel_total)
							campfire_meta:set_float("weight_fuel_total", new_weight_fuel_total)

							-- any partially burnt fuel item in the stack turns into the 'current fuel item'
							local remaining_burn_time_partial = item_burn_time - consumed_burn_time_partial
							if remaining_burn_time_partial > 0 then
								--debug(flag29, "    set partial-burnt fuel as 'current_fuel_item'")
								campfire_meta:set_string("current_fuel_item_name", fuel_item_name)
								campfire_meta:set_int("burn_time_current_item", remaining_burn_time_partial)
								local fuel_item_meta = fuel_itemstack:get_meta()
								local fuel_item_inv_image = fuel_item_meta:get_string("inventory_image")
								if fuel_item_inv_image == "" then
									--debug(flag29, "      using vanilla item icon filename and colorization")
									fuel_item_inv_image = CRAFTITEM_ICON[fuel_item_name]
								end
								
								campfire_meta:set_string("current_fuel_item_inv_image", fuel_item_inv_image)
								--debug(flag29, "      fuel_item_inv_image: " .. fuel_item_inv_image)

							else
								--debug(flag29, "    no partially burned fuel item to show")
							end

							-- update the fuel itemstack to the reduced itemstack count
							fuel_itemstack:set_count(new_stack_amount)
							--debug(flag29, "      new_stack_amount: " .. new_stack_amount)
							node_inv:set_stack("fuel", i, fuel_itemstack)

							-- reduce campfire burn_time_extra time by remaining_elapsed_time
							campfire_meta:set_int("burn_time_extra", campfire_meta:get_int("burn_time_extra") - remaining_elapsed_time)

							-- add wear to all equipped campfire tools
							add_wear_campfire_tools(pos, campfire_meta, node_inv, remaining_elapsed_time)

							-- heat/cook all available ingredients items
							cook_ingredient_all(pos, node_inv, remaining_elapsed_time)

							-- heat all flammable adjacent nodes
							for j, pos_data in ipairs(adj_positions_flammable) do
								heat_node(pos_data[1], pos_data[2], remaining_elapsed_time)
							end

							remaining_elapsed_time = 0
							break

						-- item in fuel slot absorbed all remaining elapsed time with
						-- zero fuel/burn time remaining
						elseif itemstack_burn_time_leftover == 0 then
							--debug(flag29, "      " .. fuel_item_name .. " in fuel slot " .. i .. " is all used up")
							--debug(flag29, "      removing entire itemstack from slot..")

							node_inv:set_stack("fuel", i, ItemStack(""))

							--debug(flag29, "      updating campfire fuel weight..")
							local weight_fuel_total = campfire_meta:get_float("weight_fuel_total")
							--debug(flag29, "        current weight_fuel_total: " .. weight_fuel_total)

							local fuel_weight_to_remove
							if fuel_item_name == "ss:item_bundle" then
								local fuel_item_meta = fuel_itemstack:get_meta()
								fuel_weight_to_remove = fuel_item_count * fuel_item_meta:get_float("bundle_weight")
							else
								fuel_weight_to_remove = fuel_item_count * ITEM_WEIGHTS[fuel_item_name]
							end
							--debug(flag29, "        fuel_weight_to_remove: " .. fuel_weight_to_remove)

							local new_weight_fuel_total = weight_fuel_total - fuel_weight_to_remove
							--debug(flag29, "        new_weight_fuel_total: " .. new_weight_fuel_total)
							campfire_meta:set_float("weight_fuel_total", new_weight_fuel_total)

							-- reduce campfire burn_time_extra time by remaining_elapsed_time
							campfire_meta:set_int("burn_time_extra", campfire_meta:get_int("burn_time_extra") - remaining_elapsed_time)

							-- add wear to all equipped campfire tools
							add_wear_campfire_tools(pos, campfire_meta, node_inv, remaining_elapsed_time)

							-- heat/cook all available ingredients items
							cook_ingredient_all(pos, node_inv, remaining_elapsed_time)

							-- heat all flammable adjacent nodes
							for j, pos_data in ipairs(adj_positions_flammable) do
								heat_node(pos_data[1], pos_data[2], remaining_elapsed_time)
							end

							remaining_elapsed_time = 0
							break

						-- item in fuel slot was completely used up and there is
						-- still some elapsed time remaining
						else
							--debug(flag29, "      " .. fuel_item_name .. " in fuel slot " .. i .. " is all used up")
							--debug(flag29, "      remaining_elapsed_time of " .. remaining_elapsed_time .. " still remains")

							node_inv:set_stack("fuel", i, ItemStack(""))

							--debug(flag29, "      updating campfire fuel weight..")
							local weight_fuel_total = campfire_meta:get_float("weight_fuel_total")
							--debug(flag29, "        current weight_fuel_total: " .. weight_fuel_total)

							local fuel_weight_to_remove
							if fuel_item_name == "ss:item_bundle" then
								local fuel_item_meta = fuel_itemstack:get_meta()
								fuel_weight_to_remove = fuel_item_count * fuel_item_meta:get_float("bundle_weight")
							else
								fuel_weight_to_remove = fuel_item_count * ITEM_WEIGHTS[fuel_item_name]
							end
							--debug(flag29, "        fuel_weight_to_remove: " .. fuel_weight_to_remove)


							local new_weight_fuel_total = weight_fuel_total - fuel_weight_to_remove
							--debug(flag29, "        new_weight_fuel_total: " .. new_weight_fuel_total)
							campfire_meta:set_float("weight_fuel_total", new_weight_fuel_total)

							-- reduce campfire burn_time_extra time by itemstack_burn_time
							campfire_meta:set_int("burn_time_extra", campfire_meta:get_int("burn_time_extra") - itemstack_burn_time)

							-- add wear to all equipped campfire tools
							add_wear_campfire_tools(pos, campfire_meta, node_inv, itemstack_burn_time)

							-- heat/cook all available ingredients items
							cook_ingredient_all(pos, node_inv, itemstack_burn_time)

							-- heat all flammable adjacent nodes
							for j, pos_data in ipairs(adj_positions_flammable) do
								heat_node(pos_data[1], pos_data[2], itemstack_burn_time)
							end

							remaining_elapsed_time = -itemstack_burn_time_leftover
						end
					end
				end

				--debug(flag29, "      finished applying elapsed time to fuel slots, along with campfire tools/ingredients/adj nodes")
				--debug(flag29, "      remaining_elapsed_time: " .. remaining_elapsed_time)
				--debug(flag29, "      burn_time_extra: " ..campfire_meta:get_int("burn_time_extra"))
				--debug(flag29, "      burn_time_campfire: " ..campfire_meta:get_int("burn_time_campfire"))

				if remaining_elapsed_time > 0 then
					--debug(flag29, "\n      applying elapsed time to core campfire fuel..")
					local burn_time_campfire = campfire_meta:get_int("burn_time_campfire")
					local burn_time_campfire_leftover = burn_time_campfire - remaining_elapsed_time
					if burn_time_campfire_leftover > 0 then
						--debug(flag29, "      core campfire fuel still remains")
						campfire_meta:set_int("burn_time_campfire", burn_time_campfire_leftover)
						--debug(flag29, "      burn_time_campfire_leftover: " .. burn_time_campfire_leftover)

						--debug(flag29, "\n      applying remaining elapsed time to campfire tools, ingredients, and adj nodes..")
						add_wear_campfire_tools(pos, campfire_meta, node_inv, remaining_elapsed_time)
						cook_ingredient_all(pos, node_inv, remaining_elapsed_time)
						for j, pos_data in ipairs(adj_positions_flammable) do
							heat_node(pos_data[1], pos_data[2], remaining_elapsed_time)
						end

						--debug(flag29, "    ** all remaining elapsed_time now accounted for **")
						--debug(flag29, "    SUMMARY: All fuel items used up, and some core campfire fuel was used.")

					else
						--debug(flag29, "      ** core campfire fuel depleted **")

						--debug(flag29, "\n      applying remaining campfire core burn time to campfire tools, ingredients, and adj nodes..")
						add_wear_campfire_tools(pos, campfire_meta, node_inv, burn_time_campfire)
						cook_ingredient_all(pos, node_inv, remaining_elapsed_time)
						for j, pos_data in ipairs(adj_positions_flammable) do
							heat_node(pos_data[1], pos_data[2], remaining_elapsed_time)
						end

						--debug(flag29, "    ** core campfire fuel all used up **")
						--debug(flag29, "    SUMMARY: All fuel items and core campfire fuel used up. Campfire Spent.")
						campfire_meta:set_int("burn_time_campfire", 0)
						-- in this scenario burn_time_extra and burn_time_campfire are zero,
						-- so on the next campfire_burn_loop, the campfire will automatically
						-- shut off and be set to 'spent' status
					end

				else
					--debug(flag29, "      fuel items absorbed all elapsed time. core campfire fuel untouched.")
				end

			else
				--debug(flag29, "    current fuel item absorbed all elapsed time. NO FURTHER ACTION.")
			end

			campfire_meta:set_int("unload_time", 0)
		end
	else
		--debug(flag29, "    ** campfire NOT loaded **")
		radiant_sources[pos_to_key(pos)] = nil
		--debug(flag29, "    campfire removed as radiant source")


		-- campfire status is usually 'on' status. it can become 'spent' when core fuel
		-- is used up while campfire was unloaded. don't save unload_time when campfire
		-- becomes spent, because then the elpased time value is no longer needed.
		local campfire_status = campfire_meta:get_string("campfire_status")
		--debug(flag29, "    campfire_status: " .. campfire_status)
		if campfire_status == "" then
			--debug(flag29, "    campfire no longer exists")
			--debug(flag29, "  check_campfire() END")
			return
		elseif campfire_status == "spent" then
			--debug(flag29, "    campfire is spent. not saving unload time")
		else
			local current_time = mt_get_gametime()
			campfire_meta:set_int("unload_time", current_time)
			--debug(flag29, "    saving unload_time: " .. current_time)
		end
	end

	local current_fuel_item_name = campfire_meta:get_string("current_fuel_item_name")
	local burn_time_current_item = campfire_meta:get_int("burn_time_current_item")
	local burn_time_extra = campfire_meta:get_int("burn_time_extra")
	local burn_time_campfire = campfire_meta:get_int("burn_time_campfire")
	--debug(flag29, "    campfire fuel stats:")
	--debug(flag29, "      current fuel item: " .. current_fuel_item_name .. " [" .. burn_time_current_item .. "]")
	--debug(flag29, "      campfire burn time: " .. burn_time_extra .. " | " .. burn_time_campfire)

	debug(flag29, "  check_timer_active_2() END")
end


local flag22 = false
local function check_ingredient_slots(node_meta, node_inv, pos)
	debug(flag22, "\n  check_ingredient_slots()")
	local continue_burn = true
	local ingredient_slot_items = node_inv:get_list("ingredients")
	local slot_count = node_meta:get_int("slot_count_ingredients")
	for i = 1, slot_count do
		--debug(flag22, "    checking slot #" .. i)
		local item = ingredient_slot_items[i]

		if item:is_empty() then
			--debug(flag22, "    no ingredient item exists there")

		else
			local item_name = item:get_name()
			--debug(flag22, "    ingredient item found: " .. item_name)
			local item_meta = item:get_meta()

			if ITEM_COOK_PATH[item_name] then
				--debug(flag22, "    ***** Item is cookable ***** ")

				local cooker = item_meta:get_string("cooker")
				--debug(flag22, "    cooker: " .. cooker)
				local heat_progress = item_meta:get_float("heat_progress")
				--debug(flag22, "    heat_progress: " .. heat_progress)

				if heat_progress > 0 then
					--debug(flag22, "    item currently cooking")
					cook_ingredient(item, i, node_inv, pos, 1)
				else
					--debug(flag22, "    item hasn't begun cooking")
					local in_cooldown = item_meta:get_int("in_cooldown")
					if in_cooldown == 0 then
						--debug(flag22, "    ***** STARTING COOLDOWN PHASE *****")
						item_meta:set_int("in_cooldown", 1)
						item_meta:set_int("cooldown_counter", COOK_WARM_UP_TIME)
						node_inv:set_stack("ingredients", i, item)

					else
						local cooldown_counter = item_meta:get_int("cooldown_counter")
						if cooldown_counter > 0 then
							--debug(flag22, "    currently in cooldown. counter value: " .. cooldown_counter)
							cooldown_counter = cooldown_counter - 1
							item_meta:set_int("cooldown_counter", cooldown_counter)
							--debug(flag22, "    new counter value: " .. cooldown_counter)
							node_inv:set_stack("ingredients", i, item)

						else
							--debug(flag22, "    ***** COOLDOWN COMPLETE *****")
							if FIRE_DOUSE_ITEMS[item_name] then
								--debug(flag22, "    this item will douse the flames")
								node_inv:set_stack("ingredients", i, ItemStack(""))
								stop_campfire(pos, pos_to_key(pos), node_meta)
								continue_burn = false
							else
								-- remove cooldown metadata
								item_meta:set_string("cooldown_counter", "")
								item_meta:set_string("in_cooldown", "")
								--debug(flag22, "      metadata: " .. dump(item_meta:to_table()))
								node_inv:set_stack("ingredients", i, item)
								cook_ingredient(item, i, node_inv, pos, 1)
							end
						end
					end
				end

			else
				--debug(flag22, "    item not cookable")
				--debug(flag22, "    item_meta: " .. dump(item_meta:to_table()))

				local cooker = item_meta:get_string("cooker")
				--debug(flag22, "    cooker: " .. cooker)
				if cooker ~= "" then
					item_meta:set_string("cooker", "")
					node_inv:set_stack("ingredients", i, item)
					--debug(flag22, "    removed 'cooker' data")
				end

				if item_name == "ss:ash" then
					--debug(flag22, "    item is ash. dropping to ground..")
					node_inv:set_stack("ingredients", i, ItemStack(""))
					mt_add_item(pos, item)

				elseif FIRE_SMOTHER_ITEMS[item_name] then
					--debug(flag22, "    item will smother the flames")
					stop_campfire(pos, pos_to_key(pos), node_meta)
					node_inv:set_stack("ingredients", i, ItemStack(""))
					mt_add_item(pos, item)
					continue_burn = false

				else
					--debug(flag22, "    item remains unaffected")
				end
			end
		end
	end

	debug(flag22, "  check_ingredient_slots() END")
	return continue_burn
end


local flag41 = false
local function heat_adjacent_nodes(pos)
	debug(flag41, "\n  heat_adjacent_nodes()")
	for location, adj_pos in pairs(ADJACENT_POSITIONS) do
        adj_pos = vector_add(pos, adj_pos)
		local adj_node = mt_get_node(adj_pos)
		local node_cook_data = COOK_NODES[adj_node.name]
		if node_cook_data then
			--debug(flag41, "    this node is cookable")
			heat_node(adj_pos, location, 1)
		end
	end
	debug(flag41, "  heat_adjacent_nodes() END")
end


local flag43 = false
local function check_ingredient_status(item, node_inv, index, player)
	debug(flag43, "  check_ingredient_status()")
	--debug(flag43, "    item name: " .. item:get_name())

	local item_meta = item:get_meta()
	local cooker = item_meta:get_string("cooker")
	--debug(flag43, "    cooker: " .. cooker)

	if cooker == "" then
		--debug(flag43, "    no cooker assigned")
		local player_name = player:get_player_name()
		item_meta:set_string("cooker", player_name)
		--debug(flag43, "    assigned new cooker: " .. player_name)
		node_inv:set_stack("ingredients", index, item)

	else
		--debug(flag43, "    cooker already assigned")
		reset_cook_data(item)
		node_inv:set_stack("ingredients", index, item)
	end

	debug(flag43, "  check_ingredient_status() END")
end


local flag19 = false
local function campfire_on_construct(pos)
	debug(flag19, "\ncampfire_on_construct() CAMPFIRE")

	local bottom_node = mt_get_node({x = pos.x, y = pos.y - 1, z = pos.z})
	local bottom_node_name = bottom_node.name
	--debug(flag19, "  bottom_node_name: " .. bottom_node_name)

	-- campfire can only be placed on top of a solid/walkable node. but some solid nodes
	-- are not full height and have a gap above it. ensure campfire cannot be placed
	-- above these nodes.
	local is_bottom_supportive
	if NODE_NAMES_SOLID_CUBE[bottom_node_name] then
		--debug(flag19, "  bottom node is solid cube. ok to place")
		is_bottom_supportive = true
	elseif NODE_NAMES_SOLID_VARIABLE_HEIGHT[bottom_node_name] then
		--debug(flag19, "  bottom node is variable height. inspecting further..")
		is_bottom_supportive = is_variable_height_node_supportive(bottom_node, bottom_node_name)
	else
		--debug(flag19, "  node below is not a valid support")
		is_bottom_supportive = false
	end

	if is_bottom_supportive then
		--debug(flag19, "  campfire node spawned")
		--debug(flag19, "  initializing node metadata")
		local node_meta = mt_get_meta(pos)
		node_meta:set_int("slot_count_ingredients", 1)
		node_meta:set_int("slot_count_fuel", 1)
		node_meta:set_float("weight_fuel_total", 0)
		node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[1])
		node_meta:set_int("burn_time_extra", 0)
		node_meta:set_int("burn_time_campfire", CAMPFIRE_CORE_BURNTIME)
		node_meta:set_int("burn_time_current_item", 0)
		node_meta:set_int("max_burn_time_current_item", 0)
		node_meta:set_string("current_fuel_item_name", "")
		node_meta:set_string("current_fuel_item_inv_image", "")
		node_meta:set_string("campfire_status", "off")
		node_meta:set_int("is_cooking", 0)
		node_meta:set_int("is_timer_active", 1)
		node_meta:set_int("unload_time", 0)

		--debug(flag19, "  creating unique pos_key for this campfire node")
		local pos_key = pos_to_key(pos)
		--debug(flag19, "  pos_key: " .. pos_key)

		--debug(flag19, "  initializing node inventory lists")
		local node_inv = node_meta:get_inventory()
		node_inv:set_size("ingredients", 3)
		node_inv:set_size("campfire_stand", 1)
		node_inv:set_size("campfire_grill", 1)
		node_inv:set_size("fire_starter", 1)
		node_inv:set_size("fuel", 2)

		-- initialize subtable in formspec_viewers table for this campfire node to
		-- track the players currently viewing this campfire's formspec/ui
		formspec_viewers[pos_key] = {}

	else

		--debug(flag19, "  removing campfire node from the world..")
		mt_remove_node(pos)
	end

	debug(flag19, "campfire_on_construct() END ")
end



-- ensure that camfire cannot be placed above a non-solid node. if placement is
-- successful, reduce the player's inventory weight.
local flag38 = false
local function campfire_after_place_node(pos, player, item, pointed_thing)
    debug(flag38, "\ncampfire_after_place_node()")
    --debug(flag12, "  pos: " .. mt_pos_to_string(pos))

    local node = mt_get_node(pos)
    local node_name = node.name
    --debug(flag38, "  node_name: " .. node_name)

	if node_name == "air" then
		--debug(flag38, "  campfire placement was cancelled")
		notify(player, "inventory", "Area below is not solid or stable", 3, 0.5, 0, 3)
		--debug(flag38, "campfire_after_place_node() END")
		return true

	else
		--debug(flag38, "  campfire was placed successfully")
		--debug(flag38, "  reducing inventory weight..")
        local player_meta = player:get_meta()
        local item_name = item:get_name()
        --debug(flag38, "  item name: " .. item_name)
        local weight = ITEM_WEIGHTS[item_name]
        --debug(flag38, "  weight: " .. weight)
		local player_name = player:get_player_name()
		do_stat_update_action(player, player_data[player_name], player_meta, "normal", "weight", -weight, "curr", "add", true)
        update_fs_weight(player, player_meta)
	end

    debug(flag38, "campfire_after_place_node() END")
end



local flag17 = false
local function campfire_burn_loop(pos, elapsed)
	debug(flag17, "\ncampfire_burn_loop() CAMPFIRE")

	local node_meta = mt_get_meta(pos)
	local node_inv = node_meta:get_inventory()
	node_meta:set_int("is_timer_active", 1)

	-- retrieve current fuel data
	local current_fuel_item_name = node_meta:get_string("current_fuel_item_name")
	--debug(flag17, "  current_fuel_item_name: " .. current_fuel_item_name)
	local inv_image = node_meta:get_string("inventory_image")
	--debug(flag17, "  inv_image: " .. inv_image)
	local burn_time_current_item = node_meta:get_int("burn_time_current_item")
	local burn_time_extra = node_meta:get_int("burn_time_extra")
	local burn_time_campfire = node_meta:get_int("burn_time_campfire")
	--debug(flag17, "  burn time: item " .. burn_time_current_item ..
	--	" / extra " .. burn_time_extra ..
	--	" / campfire " .. burn_time_campfire)

	-- burn any fuel in campfire, and repeat cycle while fuel exists
	local continue_burn = true
	if burn_time_extra > 0 then
		-- burning EXTRA fuel
		play_sound("campfire_start", {pos = pos})

		if burn_time_current_item > 0 then
			--debug(flag17, "  fuel remains from current item")

		else
			-- no fuel from current item. burning next fuel item
			local fuel_slots = node_inv:get_list("fuel")
			local fuel_slot_count = node_meta:get_int("slot_count_fuel")
			--debug(flag17, "  fuel_slot_count: " .. fuel_slot_count)

			for i = 1, fuel_slot_count do

				--debug(flag17, "  checking slot #" .. i)
				local fuel_itemstack = fuel_slots[i]
				if fuel_itemstack:is_empty() then
					--debug(flag17, "    no fuel item exists there")

				else
					-- save fuel item name
					local fuel_item_name = fuel_itemstack:get_name()
					node_meta:set_string("current_fuel_item_name", fuel_item_name)
					--debug(flag17, "    fuel item found: " .. fuel_item_name)

					local fuel_item_meta = fuel_itemstack:get_meta()
					if fuel_item_name == "ss:item_bundle" then
						local bundle_burn_time = fuel_item_meta:get_int("bundle_burn_time")
						node_meta:set_int("current_fuel_item_bundle_burn_time", bundle_burn_time)
					end

					-- save fuel item inventory image data. used for displaying burn progress image
					-- icon in the proper custom color (for clothing/armor)
					local fuel_item_inv_image = fuel_item_meta:get_string("inventory_image")
					if fuel_item_inv_image == "" then
						-- using vanilla item icon filename and colorization
						fuel_item_inv_image = CRAFTITEM_ICON[fuel_item_name]
					end
					node_meta:set_string("current_fuel_item_inv_image", fuel_item_inv_image)
					--debug(flag17, "    fuel_item_inv_image: " .. fuel_item_inv_image)

					local heat_progress = fuel_item_meta:get_float("heat_progress")
					--debug(flag17, "    item_meta: " .. dump(fuel_item_meta:to_table()))

					-- 'top up' current fuel item burn time
					if heat_progress > 0 then
						-- this is partially heated item
						burn_time_current_item = node_meta:get_int("burn_time_current_item_modded")
					else
						-- item not partially heated
						if fuel_item_name == "ss:item_bundle" then
							burn_time_current_item = fuel_item_meta:get_int("bundle_burn_time")
						else
							burn_time_current_item = ITEM_BURN_TIMES[fuel_item_name]
						end
					end
					--debug(flag17, "    burn_time_current_item: " .. burn_time_current_item)

					-- burn/remove the next fuel item
					fuel_itemstack:set_count(fuel_itemstack:get_count() - 1)
					node_inv:set_stack("fuel", i, fuel_itemstack)

					-- reduce total campfire fuel weight
					local item_weight
					if fuel_item_name == "ss:item_bundle" then
						item_weight = fuel_item_meta:get_float("bundle_weight")
					else
						item_weight = ITEM_WEIGHTS[fuel_item_name]
					end
					local new_fuel_weight = node_meta:get_float("weight_fuel_total") - item_weight
					node_meta:set_float("weight_fuel_total", new_fuel_weight)
					--debug(flag17, "    new_fuel_weight: " .. new_fuel_weight)

					break
					-- no need to call show_formspec() to refresh campfire ui for players here
					-- since campfire is currently 'on' and any users/viewers will already have
					-- refresh_formspec() activated on a loop.			
				end
			end
		end

		node_meta:set_int("burn_time_current_item", burn_time_current_item - 1)
		node_meta:set_int("burn_time_extra", burn_time_extra - 1)
		add_wear_campfire_tools(pos, node_meta, node_inv, 1)
		continue_burn = check_ingredient_slots(node_meta, node_inv, pos)
		heat_adjacent_nodes(pos)

	else
		--debug(flag17, "  no EXTRA fuel exists.")

		if current_fuel_item_name ~= "" then
			node_meta:set_string("current_fuel_item_name", "")
			node_meta:set_string("current_fuel_item_inv_image", "")
		end

		if burn_time_campfire > 0 then
			--debug(flag17, "  burning CORE fuel..")
			play_sound("campfire_start", {pos = pos})
			node_meta:set_int("burn_time_campfire", burn_time_campfire - 1)
			add_wear_campfire_tools(pos, node_meta, node_inv, 1)
			continue_burn = check_ingredient_slots(node_meta, node_inv, pos)
			heat_adjacent_nodes(pos)

		else
			-- no CORE fuel exists. campfire is spent.

			-- this alerts any calls to refresh_formspec() that are looping to stop
			node_meta:set_string("campfire_status", "spent")

			--debug(flag17, "    replace campfire node to ss:campfire_small_spent")
			mt_swap_node(pos, {name = "ss:campfire_small_spent"})

			--debug(flag17, "    removing campfire smoke effect")
			stop_smoke_particles(pos)

			--debug(flag17, "  playing flame stop sound")
			play_sound("campfire_stop" , {pos = pos})

			--debug(flag17, "  removing campfire from radiant sources")
			radiant_sources[pos_to_key(pos)] = nil

			-- stop looping of node timer
			continue_burn = false
		end
	end

	-- refresh formspec to all current users
	--debug(flag17, "  formspec_viewers: " .. dump(formspec_viewers))
	local pos_key = pos_to_key(pos)
	if formspec_viewers[pos_key] then
		if #formspec_viewers[pos_key] > 0 then
			refresh_formspec(pos, pos_to_key(pos))
		else
			--debug(flag17, "  campfire on, but no viewers")
			mt_after(0.9, check_timer_active_1, pos)
			mt_after(1.7, check_timer_active_2, pos)
		end
	else
		--debug(flag17, "  campfire was destroyed. NO FURTHER ACTION.")
	end

	--debug(flag17, "campfire_burn_loop() END")
	return continue_burn
end


local flag35 = false
local function campfire_on_destruct(pos)
	debug(flag35, "\ncampfire_on_destruct()")
	--debug(flag35, "  pos: " .. mt_pos_to_string(pos))
	--debug(flag35, "  formspec_viewers: " .. dump(formspec_viewers))

	local pos_key = pos_to_key(pos)
	if formspec_viewers[pos_key] == nil then
		--debug(flag35, "  attempting to place campfire above a non-solid node. NO FURTHER ACTION.")

	else
		--debug(flag35, "  campfire destruct due to being dug or falling..")

		local campfire_node = mt_get_node(pos)
		local campfire_name = campfire_node.name
		--debug(flag35, "  campfire_name: " .. campfire_name)

		-- drop the campfire core ingredients
		drop_campfire_drops(pos, campfire_name)

		-- drop all campfire slot items
		--debug(flag35, "  dropping all slot items..")
		local campfire_meta = mt_get_meta(pos)
		drop_all_items(campfire_meta:get_inventory(), pos)

		-- close formspec for any viewing players
		remove_formspec_all_viewers(pos, "ss:ui_campfire")

		if campfire_name == "ss:campfire_small_burning" then
			radiant_sources[pos_key] = nil
		end
	end

	debug(flag35, "campfire_on_destruct() END")
end


local flag6 = false
local function campfire_on_rightclick(pos, node, clicker, itemstack, pointed_thing)
	debug(flag6, "\non_rightclick() CAMPFIRE")

	local player_name = clicker:get_player_name()
	local p_data = player_data[player_name]
	local pos_key = pos_to_key(pos)
	--debug(flag6, "  pos_key: " .. pos_key)

	--debug(flag6, "  formspec_viewers: " .. dump(formspec_viewers))
	--formspec_viewers[pos_key] = formspec_viewers[pos_key] or {}
	--debug(flag6, "  updated formspec_viewers: " .. dump(formspec_viewers))

	-- save hash of campfire pos for use by register_on_player_receive_fields() and
	-- register_on_player_inventory_action()
	p_data.campfire_pos_key = pos_key
	p_data.formspec_mode = "campfire"

	-- show the campfire formspec ui
	mt_show_formspec(player_name, "ss:ui_campfire", get_fs_campfire(clicker, player_name, pos))

	-- add the player's name to the formspec_viewers table to signify that the player
	-- is currently viewing/using this campfire
	table_insert(formspec_viewers[pos_key], player_name)
	--debug(flag6, "  final formspec_viewers: " .. dump(formspec_viewers))

	-- workaround to ensure LMB/RMB player control input is released so that stamina
	-- doesn't keep draining for being in DIG/SWING state
	player_control_fix(clicker)

	play_sound("campfire_open", {pos = pos})

	debug(flag6, "on_rightclick() end *** " .. mt_get_gametime() .. " ***")
end


local flag13 = false
local function campfire_allow_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	debug(flag13, "\nallow_metadata_inventory_move() CAMPFIRE")
	--debug(flag13, "  count: " .. count)

	local node_meta = mt_get_meta(pos)
	local node_inv = node_meta:get_inventory()
	local item = node_inv:get_stack(from_list, from_index)
	local item_name = item:get_name()
	--debug(flag13, "  item_name: " .. item_name)

	local move_count = count

	if from_list == "ingredients" then
		if to_list == "ingredients" then
			--debug(flag13, "  moving item from ingred slot " .. from_index .. " to ingred slot " .. to_index)
			local to_item = node_inv:get_stack("ingredients", to_index)
			if to_item:is_empty() then
				--debug(flag13, "  target slot is empty")
			else
				local to_item_name = to_item:get_name()
				--debug(flag13, "  target slot has item: " .. to_item_name)
				if to_item_name == item_name then
					--debug(flag13, "  item in slot and item being moved are the SAME")
					--debug(flag13, "  prevent the move action as it would increase the stack count")
					move_count = 0
					notify(player, "inventory", "Only 1 item can fit there", NOTIFY_DURATION, 0, 0.5, 3)
				else
					--debug(flag13, "  item in slot and item being moved are DIFFERENT")
					move_count = 1
				end
			end

		elseif to_list == "campfire_stand" then
			--debug(flag13, "  moving item from ingred slot " .. from_index .. " to campfire stand slot " .. to_index)

			local campfire_status = node_meta:get_string("campfire_status")
			if campfire_status == "on" then
				--debug(flag13, "  campfire is ON")
				move_count = 0
				notify(player, "inventory", "Cannot place while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
			else
				if CAMPFIRE_STAND_NAMES[item_name] then
					--debug(flag13, "  item is a campfire stand!")

					local to_item = node_inv:get_stack("campfire_stand", to_index)
					if to_item:is_empty() then
						--debug(flag13, "  target slot is empty")
						move_count = 1
					else
						local to_item_name = to_item:get_name()
						--debug(flag13, "  target slot has item: " .. to_item_name)
						if to_item_name == item_name then
							--debug(flag13, "  item in slot and item being moved are the SAME")
							--debug(flag13, "  prevent the move action as it would increase the stack count")
							move_count = 0
							notify(player, "inventory", "Only 1 stand can fit there", NOTIFY_DURATION, 0, 0.5, 3)
						else
							--debug(flag13, "  item in slot and item being moved are DIFFERENT")
							move_count = 1
						end
					end

				else
					local to_item = node_inv:get_stack("campfire_stand", to_index)
					if to_item:is_empty() then
						--debug(flag13, "  target slot is empty")
						notify(player, "inventory", "Item not a campfire stand", NOTIFY_DURATION, 0, 0.5, 3)
					else
						local to_item_name = to_item:get_name()
						--debug(flag13, "  target slot has item: " .. to_item_name)
						notify(player, "inventory", "Cannot swap with non-stand item", 3, 0, 0.5, 3)
					end
					move_count = 0
				end
			end

		elseif to_list == "campfire_grill" then
			--debug(flag13, "  moving item from ingred slot " .. from_index .. " to campfire grill slot " .. to_index)

			local campfire_status = node_meta:get_string("campfire_status")
			if campfire_status == "on" then
				--debug(flag13, "  campfire is ON")
				move_count = 0
				notify(player, "inventory", "Cannot place while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
			else

				if CAMPFIRE_GRILL_NAMES[item_name] then
					--debug(flag13, "  item is a campfire grill!")

					local to_item = node_inv:get_stack("campfire_grill", to_index)
					if to_item:is_empty() then
						--debug(flag13, "  target slot is empty")
						move_count = 1
					else
						local to_item_name = to_item:get_name()
						--debug(flag13, "  target slot has item: " .. to_item_name)
						if to_item_name == item_name then
							--debug(flag13, "  item in slot and item being moved are the SAME")
							--debug(flag13, "  prevent the move action as it would increase the stack count")
							move_count = 0
							notify(player, "inventory", "Only 1 grill can fit there", NOTIFY_DURATION, 0, 0.5, 3)
						else
							--debug(flag13, "  item in slot and item being moved are DIFFERENT")
							move_count = 1
						end
					end

				else
					local to_item = node_inv:get_stack("campfire_grill", to_index)
					if to_item:is_empty() then
						--debug(flag13, "  target slot is empty")
						notify(player, "inventory", "Item not a campfire grill", NOTIFY_DURATION, 0, 0.5, 3)
					else
						local to_item_name = to_item:get_name()
						--debug(flag13, "  target slot has item: " .. to_item_name)
						notify(player, "inventory", "Cannot swap with non-grill item", 3, 0, 0.5, 3)
					end
					move_count = 0
				end
			end

		elseif to_list == "fire_starter" then
			--debug(flag13, "  moving item from ingred slot " .. from_index .. " to fire starter slot " .. to_index)
			if FIRE_STARTER_NAMES[item_name] then
				--debug(flag13, "  item is a fire starter!")
				move_count = 1
			else
				--debug(flag13, "  item is not a fire starter")
				move_count = 0
				notify(player, "inventory", "Item not a fire starter", NOTIFY_DURATION, 0, 0.5, 3)
			end

		elseif to_list == "fuel" then
			--debug(flag13, "  moving item from ingred slot " .. from_index .. " to fuel slot " .. to_index)
			if ITEM_BURN_TIMES[item_name] > 0 then
				--debug(flag13, "  item is campfire fuel!")
				move_count = get_fuel_item_count(player, node_meta, item)
			else
				--debug(flag13, "  item is not a campfire fuel")
				move_count = 0
				notify(player, "inventory", "Item not burnable as fuel.", NOTIFY_DURATION, 0, 0.5, 3)
			end

		else
			debug(flag13, "  ERROR: Unexpected 'to_list' value: " .. to_list)
		end

	elseif from_list == "campfire_stand" then

		local campfire_status = node_meta:get_string("campfire_status")
		if campfire_status == "on" then
			--debug(flag13, "  campfire is ON")
			move_count = 0
			notify(player, "inventory", "Cannot remove stand while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
		else
			if to_list == "ingredients" then
				--debug(flag13, "  moving item from campfire stand slot " .. from_index .. " to ingred slot " .. to_index)
				local to_item = node_inv:get_stack("ingredients", to_index)
				if to_item:is_empty() then
					--debug(flag13, "  target slot is empty")
				else
					local to_item_name = to_item:get_name()
					--debug(flag13, "  target slot has item: " .. to_item_name)
					if to_item_name == item_name then
						--debug(flag13, "  item in slot and item being moved are the SAME")
						--debug(flag13, "  prevent the move action as it would increase the stack count")
						move_count = 0
						notify(player, "inventory", "Only 1 stand can fit there", NOTIFY_DURATION, 0, 0.5, 3)
					else
						--debug(flag13, "  item in slot and item being moved are DIFFERENT")
						move_count = 1
					end
				end

			elseif to_list == "campfire_grill" then
				--debug(flag13, "  moving item from campfire stand slot " .. from_index .. " to campfire grill slot " .. to_index)
				--debug(flag13, "  campfire stand never allowed to campfire grill slot")
					move_count = 0
					notify(player, "inventory", "Cannot swap with campfire grill", NOTIFY_DURATION, 0, 0.5, 3)

			elseif to_list == "fire_starter" then
				--debug(flag13, "  moving item from campfire stand slot " .. from_index .. " to fire starter slot " .. to_index)
				--debug(flag13, "  campfire stand never allowed to fire starter slot")
					move_count = 0
					notify(player, "inventory", "Item not a fire starter", NOTIFY_DURATION, 0, 0.5, 3)

			elseif to_list == "fuel" then
				--debug(flag13, "  moving item from campfire stand slot " .. from_index .. " to fuel slot " .. to_index)
				if ITEM_BURN_TIMES[item_name] > 0 then
					--debug(flag13, "  item is campfire fuel!")
					move_count = get_fuel_item_count(player, node_meta, item)
				else
					--debug(flag13, "  item is not a campfire fuel")
					move_count = 0
					notify(player, "inventory", "Item not burnable as fuel.", NOTIFY_DURATION, 0, 0.5, 3)
				end

			else
				debug(flag13, "  ERROR: Unexpected 'to_list' value: " .. to_list)
			end
		end

	elseif from_list == "campfire_grill" then

		local campfire_status = node_meta:get_string("campfire_status")
		if campfire_status == "on" then
			--debug(flag13, "  campfire is ON")
			move_count = 0
			notify(player, "inventory", "Cannot remove grill while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
		else
			if to_list == "ingredients" then
				--debug(flag13, "  moving item from campfire grill slot " .. from_index .. " to ingred slot " .. to_index)
				local to_item = node_inv:get_stack("ingredients", to_index)
				if to_item:is_empty() then
					--debug(flag13, "  target slot is empty")
				else
					local to_item_name = to_item:get_name()
					--debug(flag13, "  target slot has item: " .. to_item_name)
					if to_item_name == item_name then
						--debug(flag13, "  item in slot and item being moved are the SAME")
						--debug(flag13, "  prevent the move action as it would increase the stack count")
						move_count = 0
						notify(player, "inventory", "Only 1 grill can fit there", NOTIFY_DURATION, 0, 0.5, 3)
					else
						--debug(flag13, "  item in slot and item being moved are DIFFERENT")
						move_count = 1
					end
				end

			elseif to_list == "campfire_stand" then
				--debug(flag13, "  moving item from campfire grill slot " .. from_index .. " to campfire stand slot " .. to_index)
				--debug(flag13, "  campfire grill never allowed into campfire stand slot")
					move_count = 0
					notify(player, "inventory", "Cannot swap with campfire stand", NOTIFY_DURATION, 0, 0.5, 3)

			elseif to_list == "fire_starter" then
				--debug(flag13, "  moving item from campfire grill slot " .. from_index .. " to fire starter slot " .. to_index)
				--debug(flag13, "  campfire grill never allowed to fire starter slot")
					move_count = 0
					notify(player, "inventory", "Item not a fire starter", NOTIFY_DURATION, 0, 0.5, 3)

			elseif to_list == "fuel" then
				--debug(flag13, "  moving item from campfire grill slot " .. from_index .. " to fuel slot " .. to_index)
				if ITEM_BURN_TIMES[item_name] > 0 then
					--debug(flag13, "  item is campfire fuel!")
					move_count = get_fuel_item_count(player, node_meta, item)
				else
					--debug(flag13, "  item is not a campfire fuel")
					move_count = 0
					notify(player, "inventory", "Item not burnable as fuel.", NOTIFY_DURATION, 0, 0.5, 3)
				end

			else
				debug(flag13, "  ERROR: Unexpected 'to_list' value: " .. to_list)
			end
		end

	elseif from_list == "fire_starter" then
		if to_list == "ingredients" then
			--debug(flag13, "  moving item from fire starter slot " .. from_index .. " to ingred slot " .. to_index)
			local to_item = node_inv:get_stack("ingredients", to_index)
			if to_item:is_empty() then
				--debug(flag13, "  target slot is empty")
			else
				local to_item_name = to_item:get_name()
				--debug(flag13, "  target slot has item: " .. to_item_name)
				if to_item_name == item_name then
					--debug(flag13, "  item in slot and item being moved are the SAME")
					--debug(flag13, "  prevent the move action as it would increase the stack count")
					move_count = 0
					notify(player, "inventory", "Only 1 item can fit there", NOTIFY_DURATION, 0, 0.5, 3)
				else
					--debug(flag13, "  item in slot and item being moved are DIFFERENT")
					move_count = 1

					if FIRE_STARTER_NAMES[to_item_name] then
						--debug(flag13, "  item is a fire starter!")
					else
						--debug(flag13, "  item is not a fire starter")
						notify(player, "inventory", "Cannot swap with non fire starter tool.", NOTIFY_DURATION, 0, 0.5, 3)
					end
				end
			end

		elseif to_list == "campfire_stand" then
			--debug(flag13, "  moving item from fire starter slot " .. from_index .. " to campfire stand slot " .. to_index)
			--debug(flag13, "  fire starter never allowed into campfire stand slot")
				move_count = 0
				notify(player, "inventory", "Cannot swap with campfire stand", NOTIFY_DURATION, 0, 0.5, 3)

		elseif to_list == "campfire_grill" then
			--debug(flag13, "  moving item from fire starter slot " .. from_index .. " to campfire grill slot " .. to_index)
			--debug(flag13, "  fire starter never allowed into campfire grill slot")
				move_count = 0
				notify(player, "inventory", "Cannot swap with campfire grill", NOTIFY_DURATION, 0, 0.5, 3)

		elseif to_list == "fuel" then
			--debug(flag13, "  moving item from fire starter slot " .. from_index .. " to fuel slot " .. to_index)
			if ITEM_BURN_TIMES[item_name] > 0 then
				--debug(flag13, "  item is campfire fuel!")
				move_count = get_fuel_item_count(player, node_meta, item)
			else
				--debug(flag13, "  item is not a campfire fuel")
				move_count = 0
				notify(player, "inventory", "Item not burnable as fuel.", NOTIFY_DURATION, 0, 0.5, 3)
			end

		end


	elseif from_list == "fuel" then
		if to_list == "ingredients" then
			--debug(flag13, "  moving item from fuel slot " .. from_index .. " to ingred slot " .. to_index)
			local to_item = node_inv:get_stack("ingredients", to_index)
			if item_name == "ss:item_bundle" then
				notify(player, "inventory", "Cannot cook items while bundled", NOTIFY_DURATION, 0, 0.5, 3)
				move_count = 0
			elseif to_item:is_empty() then
				--debug(flag13, "  target slot is empty")
				if count > 1 then
					notify(player, "inventory", "only 1 was added", NOTIFY_DURATION, 0.5, 0, 2)
					move_count = 1
				end
			else
				local to_item_name = to_item:get_name()
				--debug(flag13, "  target slot has item: " .. to_item_name)
				if to_item_name == item_name then
					--debug(flag13, "  item in slot and item being moved are the SAME")
					--debug(flag13, "  prevent the move action as it would increase the stack count")
					move_count = 0
					notify(player, "inventory", "Only 1 item can fit there", NOTIFY_DURATION, 0, 0.5, 3)
				else
					--debug(flag13, "  item in slot and item being moved are DIFFERENT")
					if ITEM_BURN_TIMES[to_item_name] > 0 then
						--debug(flag13, "  item is campfire fuel!")
						if count > 1 then
							notify(player, "inventory", "only 1 was added", NOTIFY_DURATION, 0.5, 0, 2)
							move_count = 1
						end
					else
						--debug(flag13, "  item is not a campfire fuel")
						notify(player, "inventory", "Cannot swap with non-burnable item.", NOTIFY_DURATION, 0, 0.5, 3)
					end
				end
			end

		elseif to_list == "campfire_stand" then
			--debug(flag13, "  moving item from fuel slot " .. from_index .. " to campfire stand slot " .. to_index)

			local campfire_status = node_meta:get_string("campfire_status")
			if campfire_status == "on" then
				--debug(flag13, "  campfire is ON")
				move_count = 0
				notify(player, "inventory", "Cannot place while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
			else
				if CAMPFIRE_STAND_NAMES[item_name] then
					--debug(flag13, "  item is a campfire stand!")

					local to_item = node_inv:get_stack("campfire_stand", to_index)
					if to_item:is_empty() then
						--debug(flag13, "  target slot is empty")
						move_count = 1
					else
						local to_item_name = to_item:get_name()
						--debug(flag13, "  target slot has item: " .. to_item_name)
						if to_item_name == item_name then
							--debug(flag13, "  item in slot and item being moved are the SAME")
							--debug(flag13, "  prevent the move action as it would increase the stack count")
							move_count = 0
							notify(player, "inventory", "Only 1 stand can fit there", NOTIFY_DURATION, 0, 0.5, 3)
						else
							--debug(flag13, "  item in slot and item being moved are DIFFERENT")
							move_count = 1
						end
					end

				else
					--debug(flag13, "  item is not a campfire stand")
					move_count = 0
					notify(player, "inventory", "Fuel item is not a campfire stand", NOTIFY_DURATION, 0, 0.5, 3)
				end
			end

		elseif to_list == "campfire_grill" then
			--debug(flag13, "  moving item from fuel slot " .. from_index .. " to campfire grill slot " .. to_index)

			local campfire_status = node_meta:get_string("campfire_status")
			if campfire_status == "on" then
				--debug(flag13, "  campfire is ON")
				move_count = 0
				notify(player, "inventory", "Cannot place while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
			else
				if CAMPFIRE_GRILL_NAMES[item_name] then
					--debug(flag13, "  item is a campfire grill!")

					local to_item = node_inv:get_stack("campfire_grill", to_index)
					if to_item:is_empty() then
						--debug(flag13, "  target slot is empty")
						move_count = 1
					else
						local to_item_name = to_item:get_name()
						--debug(flag13, "  target slot has item: " .. to_item_name)
						if to_item_name == item_name then
							--debug(flag13, "  item in slot and item being moved are the SAME")
							--debug(flag13, "  prevent the move action as it would increase the stack count")
							move_count = 0
							notify(player, "inventory", "Only 1 grill can fit there", NOTIFY_DURATION, 0, 0.5, 3)
						else
							--debug(flag13, "  item in slot and item being moved are DIFFERENT")
							move_count = 1
						end
					end

				else
					--debug(flag13, "  item is not a campfire grill")
					move_count = 0
					notify(player, "inventory", "Fuel item is not a campfire grill", NOTIFY_DURATION, 0, 0.5, 3)
				end
			end

		elseif to_list == "fire_starter" then
			--debug(flag13, "  moving item from fuel slot " .. from_index .. " to fire starter slot " .. to_index)

			if FIRE_STARTER_NAMES[item_name] then
				--debug(flag13, "  item is a fire starter item!")

				local to_item = node_inv:get_stack("fire_starter", to_index)
				if to_item:is_empty() then
					--debug(flag13, "  target slot is empty")
					if count > 1 then
						notify(player, "inventory", "only 1 was added", NOTIFY_DURATION, 0.5, 0, 2)
						move_count = 1
					end
				else
					local to_item_name = to_item:get_name()
					--debug(flag13, "  target slot has item: " .. to_item_name)
					if to_item_name == item_name then
						--debug(flag13, "  item in slot and item being moved are the SAME")
						--debug(flag13, "  prevent the move action as it would increase the stack count")
						move_count = 0
						notify(player, "inventory", "Only 1 item can fit there", NOTIFY_DURATION, 0, 0.5, 3)
					else
						--debug(flag13, "  item in slot and item being moved are DIFFERENT")
						notify(player, "inventory", "only 1 was added", NOTIFY_DURATION, 0.5, 0, 2)
						move_count = 1
					end
				end

			else
				--debug(flag13, "  item is not a fire starter item")
				move_count = 0
				notify(player, "inventory", "Item not a fire starter", NOTIFY_DURATION, 0, 0.5, 3)
			end

		elseif to_list == "fuel" then
		else
			debug(flag13, "  ERROR: Unexpected 'to_list' value: " .. to_list)
		end

	else
		debug(flag13, "  ERROR: Unexpected 'from_list' value: " .. from_list)
	end

	debug(flag13, "allow_metadata_inventory_move() end *** " .. mt_get_gametime() .. " ***")
	return move_count
end


local flag9 = false
local function campfire_allow_metadata_inventory_put(pos, listname, index, stack, player)
	debug(flag9, "\nallow_metadata_inventory_put() CAMPFIRE")

	local node_meta = mt_get_meta(pos)
	local node_inv = node_meta:get_inventory()
	local item_name = stack:get_name()
	local item_count = stack:get_count()
	local put_count = item_count

	if listname == "ingredients" then
		--debug(flag9, "  PUT " .. item_name .. " into " .. listname .. " at index " .. index)
		local to_item = node_inv:get_stack("ingredients", index)
		if item_name == "ss:item_bundle" then
			--debug(flag9, "  this is an item bundle. not allowed.")
			notify(player, "inventory", "Cannot cook items while bundled", NOTIFY_DURATION, 0, 0.5, 3)
			put_count = 0

		elseif to_item:is_empty() then
			--debug(flag9, "  target slot is empty")
			if item_count > 1 then
				notify(player, "inventory", "only 1 was added", NOTIFY_DURATION, 0.5, 0, 2)
				put_count = 1
			end
		else
			local to_item_name = to_item:get_name()
			--debug(flag9, "  target slot has item: " .. to_item_name)
			if to_item_name == item_name then
				--debug(flag9, "  item in slot and item being moved are the SAME")
				--debug(flag9, "  prevent the move action as it would increase the stack count")
				put_count = 0
				notify(player, "inventory", "Only 1 item can fit there", NOTIFY_DURATION, 0, 0.5, 3)
			else
				--debug(flag9, "  item in slot and item being moved are DIFFERENT")
				if item_count > 1 then
					notify(player, "inventory", "Item count too large to swap.", NOTIFY_DURATION, 0, 0.5, 3)
					put_count = 0
				end
				--debug(flag9, "  item_count: " .. item_count)
			end
		end

	elseif listname == "campfire_stand" then
		--debug(flag9, "  PUT " .. item_name .. " into " .. listname .. " at index " .. index)

		local campfire_status = node_meta:get_string("campfire_status")
		if campfire_status == "on" then
			--debug(flag9, "  campfire is ON")
			put_count = 0
			notify(player, "inventory", "Cannot place while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
		else
			if CAMPFIRE_STAND_NAMES[item_name] then
				--debug(flag9, "  item is a campfire stand!")
				local to_item = node_inv:get_stack("campfire_stand", index)
				if to_item:is_empty() then
					--debug(flag9, "  target slot is empty")
					put_count = 1
				else
					local to_item_name = to_item:get_name()
					--debug(flag9, "  target slot has item: " .. to_item_name)
					if to_item_name == item_name then
						--debug(flag9, "  item in slot and item being moved are the SAME")
						--debug(flag9, "  prevent the move action as it would increase the stack count")
						put_count = 0
						notify(player, "inventory", "Only 1 stand will fit there", NOTIFY_DURATION, 0, 0.5, 3)
					else
						--debug(flag9, "  item in slot and item being moved are DIFFERENT")
						if item_count > 1 then
							notify(player, "inventory", "Item count too large to swap.", NOTIFY_DURATION, 0, 0.5, 3)
							put_count = 0
						end
						--debug(flag9, "  item_count: " .. item_count)
					end
				end
			else
				--debug(flag9, "  item is not a campfire stand")
				notify(player, "inventory", "Item is not a campfire stand", NOTIFY_DURATION, 0, 0.5, 3)
				put_count = 0
			end
		end

	elseif listname == "campfire_grill" then
		--debug(flag9, "  PUT " .. item_name .. " into " .. listname .. " at index " .. index)

		local campfire_status = node_meta:get_string("campfire_status")
		if campfire_status == "on" then
			--debug(flag9, "  campfire is ON")
			put_count = 0
			notify(player, "inventory", "Cannot place while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
		else
			if CAMPFIRE_GRILL_NAMES[item_name] then
				--debug(flag9, "  item is a campfire grill!")
				local to_item = node_inv:get_stack("campfire_grill", index)
				if to_item:is_empty() then
					--debug(flag9, "  target slot is empty")
					put_count = 1
				else
					local to_item_name = to_item:get_name()
					--debug(flag9, "  target slot has item: " .. to_item_name)
					if to_item_name == item_name then
						--debug(flag9, "  item in slot and item being moved are the SAME")
						--debug(flag9, "  prevent the move action as it would increase the stack count")
						put_count = 0
						notify(player, "inventory", "Only 1 grill will fit there", NOTIFY_DURATION, 0, 0.5, 3)
					else
						--debug(flag9, "  item in slot and item being moved are DIFFERENT")
						if item_count > 1 then
							notify(player, "inventory", "Item count too large to swap.", NOTIFY_DURATION, 0, 0.5, 3)
							put_count = 0
						end
						--debug(flag9, "  item_count: " .. item_count)
					end
				end
			else
				--debug(flag9, "  item is not a campfire grill")
				notify(player, "inventory", "Item is not a campfire grill", NOTIFY_DURATION, 0, 0.5, 3)
				put_count = 0
			end
		end

	elseif listname == "fire_starter" then
		--debug(flag9, "  PUT " .. item_name .. " into " .. listname .. " at index " .. index)

		if FIRE_STARTER_NAMES[item_name] then
			--debug(flag9, "  item is a fire starter!")
			local to_item = node_inv:get_stack("fire_starter", index)
			if to_item:is_empty() then
				--debug(flag9, "  target slot is empty")
				if item_count > 1 then
					notify(player, "inventory", "only 1 was added", NOTIFY_DURATION, 0.5, 0, 2)
					put_count = 1
				end
			else
				local to_item_name = to_item:get_name()
				--debug(flag9, "  target slot has item: " .. to_item_name)
				if to_item_name == item_name then
					--debug(flag9, "  item in slot and item being moved are the SAME")
					--debug(flag9, "  prevent the move action as it would increase the stack count")
					put_count = 0
					notify(player, "inventory", "Only 1 item can fit there", NOTIFY_DURATION, 0, 0.5, 3)
				else
					--debug(flag9, "  item in slot and item being moved are DIFFERENT")
					if item_count > 1 then
						notify(player, "inventory", "Item count too large to swap.", NOTIFY_DURATION, 0, 0.5, 3)
						put_count = 0
					end
					--debug(flag9, "  item_count: " .. item_count)
				end
			end

		else
			--debug(flag9, "  item is not a fire starter")
			notify(player, "inventory", "Item not a fire starter", NOTIFY_DURATION, 0, 0.5, 3)
			put_count = 0
		end

	elseif listname == "fuel" then
		--debug(flag9, "  PUT " .. item_name .. " into " .. listname .. " at index " .. index)
		if item_name == "ss:item_bundle" then
			--debug(flag9, "  item is a bundle")
			put_count = get_fuel_item_count(player, node_meta, stack)
		elseif ITEM_BURN_TIMES[item_name] > 0 then
			--debug(flag9, "  item is campfire fuel!")
			put_count = get_fuel_item_count(player, node_meta, stack)
		else
			--debug(flag9, "  item is not a campfire fuel")
			notify(player, "inventory", "Item not burnable as fuel.", NOTIFY_DURATION, 0, 0.5, 3)
			put_count = 0
		end

	else
		debug(flag9, "  ERROR: Unexpected 'listname' value: " .. listname)
		put_count = 0
	end

	debug(flag9, "allow_metadata_inventory_put() end *** " .. mt_get_gametime() .. " ***")
	return put_count
end


local flag25 = false
local function campfire_allow_metadata_inventory_take(pos, listname, index, stack, player)
	debug(flag25, "\nallow_metadata_inventory_take() CAMPFIRE")

	local node_meta = mt_get_meta(pos)
	local item_name = stack:get_name()
	local item_count = stack:get_count()
	local take_count = item_count
	--debug(flag25, "  TAKE " .. item_name .. " from " .. listname .. " at index " .. index)

	if listname == "campfire_stand" then
		local campfire_status = node_meta:get_string("campfire_status")
		if campfire_status == "on" then
			--debug(flag25, "  campfire is ON")
			take_count = 0
			notify(player, "inventory", "Cannot remove stand while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
		end
	elseif listname == "campfire_grill" then
		local campfire_status = node_meta:get_string("campfire_status")
		if campfire_status == "on" then
			--debug(flag25, "  campfire is ON")
			take_count = 0
			notify(player, "inventory", "Cannot remove grill while campfire is on.", NOTIFY_DURATION, 0, 0.5, 3)
		end

	else
		--debug(flag25, "  Taking from any slot other than campfire_stand or campfire_grill ALLOWED.")
	end

	debug(flag25, "allow_metadata_inventory_take() end *** " .. mt_get_gametime() .. " ***")
	return take_count
end


local flag12 = false
local function campfire_on_metadata_inventory_move(pos, from_list, from_index, to_list, to_index, count, player)
	debug(flag12, "\non_metadata_inventory_move() CAMPFIRE")
	local node_meta = mt_get_meta(pos)
	local node_inv = node_meta:get_inventory()
	local item = node_inv:get_stack(to_list, to_index)
	local item_name = item:get_name()
	--debug(flag12, table_concat({ "  MOVED ", item_name, " from ", from_list, "[", from_index, "] to ", to_list, "[", to_index, "]" }) )
	play_sound("item_move", {item_name = item_name, player_name = player:get_player_name()})

	if from_list == "ingredients" then

		-- check if item was in cooking cooldown phase and reset cooking data if so
		if to_list ~= "ingredients" then
			--debug(flag12, "  moving item from ingred slot to another campfire slot")
			reset_cook_data(item)
			node_inv:set_stack(to_list, to_index, item)
		end

		if to_list == "ingredients" then
			--debug(flag12, "  moved item to another ingredient slot")
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "campfire_stand" then
			node_meta:set_int("slot_count_ingredients", node_meta:get_int("slot_count_ingredients") + 1)
			if node_meta:get_int("slot_count_fuel") == 1 then
				node_meta:set_int("slot_count_fuel", 2)
				node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[2])
			end
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "campfire_grill" then
			node_meta:set_int("slot_count_ingredients", node_meta:get_int("slot_count_ingredients") + 1)
			if node_meta:get_int("slot_count_fuel") == 1 then
				node_meta:set_int("slot_count_fuel", 2)
				node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[2])
			end
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "fire_starter" then
			--debug(flag12, "  item placed in fire starter slot")
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "fuel" then
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))

		else
			debug(flag12, "  ERROR: Unexpected 'to_list' value: " .. to_list)
		end

	elseif from_list == "campfire_stand" then
		if to_list == "ingredients" then
			reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "ingredients")
			local slot_count_fuel = node_meta:get_int("slot_count_fuel")
			if slot_count_fuel == 2 then
				--debug(flag12, "  slot_count_fuel is 2")
				if node_inv:is_empty("campfire_grill") then
					--debug(flag12, "  campfire_grill not used. removing fuel slot..")
					--node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[1])
					reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "fuel")
				else
					--debug(flag12, "  campfire_grill currently used. fuel slots unmodified.")
				end
			else
				--debug(flag12, "  slot_count_fuel is not 2.")
		 	end

		elseif to_list == "fuel" then
			reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "ingredients")
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))
			local slot_count_fuel = node_meta:get_int("slot_count_fuel")
			if slot_count_fuel == 2 then
				--debug(flag12, "  slot_count_fuel is 2")
				if node_inv:is_empty("campfire_grill") then
					--debug(flag12, "  campfire_grill not used. removing fuel slot..")
					--node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[1])
					reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "fuel")
				else
					--debug(flag12, "  campfire_grill currently used. fuel slots unmodified.")
				end
			else
				--debug(flag12, "  slot_count_fuel is not 2.")
			end

		else
			debug(flag12, "  ERROR: Unexpected 'to_list' value: " .. to_list)
		end

	elseif from_list == "campfire_grill" then
		if to_list == "ingredients" then
			reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "ingredients")
			local slot_count_fuel = node_meta:get_int("slot_count_fuel")
			if slot_count_fuel == 2 then
				--debug(flag12, "  slot_count_fuel is 2")
				if node_inv:is_empty("campfire_stand") then
					--debug(flag12, "  campfire_stand not used. removing fuel slot..")
					--node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[1])
					reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "fuel")
				else
					--debug(flag12, "  campfire_stand currently used. fuel slots unmodified.")
				end
			else
				--debug(flag12, "  slot_count_fuel is not 2.")
			end

		elseif to_list == "fuel" then
			reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "ingredients")
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))
			local slot_count_fuel = node_meta:get_int("slot_count_fuel")
			if slot_count_fuel == 2 then
				--debug(flag12, "  slot_count_fuel is 2")
				if node_inv:is_empty("campfire_stand") then
					--debug(flag12, "  campfire_stand not used. removing fuel slot..")
					--node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[1])
					reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "fuel")
				else
					--debug(flag12, "  campfire_stand currently used. fuel slots unmodified.")
				end
			else
				--debug(flag12, "  slot_count_fuel is not 2.")
			end

		else
			debug(flag12, "  ERROR: Unexpected 'to_list' value: " .. to_list)
		end

	elseif from_list == "fuel" then
		if to_list == "ingredients" then
			local campfire_status = node_meta:get_string("campfire_status")
			if campfire_status == "on" then
				--debug(flag12, "  campfire is ON")
				--debug(flag12, "  player put item in ingredient slot while campfire was on")
				check_ingredient_status(item, node_inv, to_index, player)
			else
				--debug(flag12, "  campfire is off")
			end
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "campfire_stand" then
			node_meta:set_int("slot_count_ingredients", node_meta:get_int("slot_count_ingredients") + 1)
			if node_meta:get_int("slot_count_fuel") == 1 then
				node_meta:set_int("slot_count_fuel", 2)
				node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[2])
			end
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "campfire_grill" then
			node_meta:set_int("slot_count_ingredients", node_meta:get_int("slot_count_ingredients") + 1)
			if node_meta:get_int("slot_count_fuel") == 1 then
				node_meta:set_int("slot_count_fuel", 2)
				node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[2])
			end
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "fire_starter" then
			--debug(flag12, "  item placed in fire starter slot")
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "fuel" then
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))

		else
			debug(flag12, "  ERROR: Unexpected 'to_list' value: " .. to_list)
		end

	elseif from_list == "fire_starter" then
		if to_list == "ingredients" then
			local campfire_status = node_meta:get_string("campfire_status")
			if campfire_status == "on" then
				--debug(flag12, "  campfire is ON")
				--debug(flag12, "  player put item in ingredient slot while campfire was on")
				check_ingredient_status(item, node_inv, to_index, player)
			else
				--debug(flag12, "  campfire is off")
			end
			refresh_formspec(pos, pos_to_key(pos))

		elseif to_list == "fuel" then
			update_fuel_stats(node_meta, node_inv)
			refresh_formspec(pos, pos_to_key(pos))

		else
			debug(flag12, "  ERROR: Unexpected 'to_list' value: " .. to_list)
		end

	else
		debug(flag12, "  ERROR: Unexpected 'from_list' value: " .. from_list)
	end

	debug(flag12, "on_metadata_inventory_move() end *** " .. mt_get_gametime() .. " ***")
end


local flag10 = false
local function campfire_on_metadata_inventory_put(pos, listname, index, stack, player)
	debug(flag10, "\non_metadata_inventory_put() CAMPFIRE")
	--debug(flag10, "  pos: " .. dump(pos))
	local item_name = stack:get_name()
	--debug(flag10, "  PUT " .. item_name .. " into " .. listname .. " at index " .. index)

	local node_meta = mt_get_meta(pos)
	local node_inv = node_meta:get_inventory()

	if listname == "ingredients" then

		local campfire_status = node_meta:get_string("campfire_status")
		if campfire_status == "on" then
			--debug(flag10, "  campfire is ON")
			--debug(flag10, "    player put item in ingredient slot while campfire was on")
			check_ingredient_status(stack, node_inv, index, player)
		else
			--debug(flag10, "  campfire is off")
		end

	elseif listname == "campfire_stand" then
		node_meta:set_int("slot_count_ingredients", node_meta:get_int("slot_count_ingredients") + 1)
		if node_meta:get_int("slot_count_fuel") == 1 then
			node_meta:set_int("slot_count_fuel", 2)
			node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[2])
		end
		refresh_formspec(pos, pos_to_key(pos))

	elseif listname == "campfire_grill" then
		node_meta:set_int("slot_count_ingredients", node_meta:get_int("slot_count_ingredients") + 1)
		if node_meta:get_int("slot_count_fuel") == 1 then
			node_meta:set_int("slot_count_fuel", 2)
			node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[2])
		end
		refresh_formspec(pos, pos_to_key(pos))

	elseif listname == "fire_starter" then
		--debug(flag10, "  placed fire starter into slot")

	elseif listname == "fuel" then
		update_fuel_stats(node_meta, node_inv)
		refresh_formspec(pos, pos_to_key(pos))

	else
		debug(flag10, "  ERROR: Unexpected 'listname' value: " .. listname)
	end

	debug(flag10, "on_metadata_inventory_put() end *** " .. mt_get_gametime() .. " ***")
end


local flag11 = false
local function campfire_on_metadata_inventory_take(pos, listname, index, stack, player)
	debug(flag11, "\non_metadata_inventory_take() CAMPFIRE")
	local item_name = stack:get_name()
	--debug(flag11, "  REMOVED " .. item_name)
	play_sound("item_move", {item_name = item_name, player_name = player:get_player_name()})

	local node_meta = mt_get_meta(pos)
	local node_inv = node_meta:get_inventory()
	--debug(flag11, "    campfire lists: " .. dump(node_inv:get_lists()))

	if listname == "ingredients" then
		--debug(flag11, "  removed from ingredients slot# " .. index)
		refresh_formspec(pos, pos_to_key(pos))

	elseif listname == "campfire_stand" then
		--debug(flag11, "  removed from campfire_stand slot# " .. index)
		reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "ingredients")
		local slot_count_fuel = node_meta:get_int("slot_count_fuel")
		if slot_count_fuel == 2 then
			--debug(flag11, "  slot_count_fuel is 2")
			if node_inv:is_empty("campfire_grill") then
				--debug(flag11, "  campfire_grill not used. removing fuel slot..")
				--node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[1])
				reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "fuel")
			else
				--debug(flag11, "  campfire_grill currently used. fuel slots unmodified.")
			end
		else
			--debug(flag11, "  slot_count_fuel is not 2.")
		end

	elseif listname == "campfire_grill" then
		--debug(flag11, "  removed from campfire_grill slot# " .. index)
		reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "ingredients")
		local slot_count_fuel = node_meta:get_int("slot_count_fuel")
		if slot_count_fuel == 2 then
			--debug(flag11, "  slot_count_fuel is 2")
			if node_inv:is_empty("campfire_stand") then
				--debug(flag11, "  campfire_stand not used. removing fuel slot..")
				--node_meta:set_float("weight_fuel_max", FUEL_WEIGHT_MAX[1])
				reduce_ingred_fuel_slots(player, node_meta, node_inv, pos, "fuel")
			else
				--debug(flag11, "  campfire_stand currently used. fuel slots unmodified.")
			end
		else
			--debug(flag11, "  slot_count_fuel is not 2.")
		end

	elseif listname == "fire_starter" then
		--debug(flag11, "  removed fire starter from slot")

	elseif listname == "fuel" then
		--debug(flag11, "  removed from fuel slot# " .. index)
		update_fuel_stats(node_meta, node_inv)
		refresh_formspec(pos, pos_to_key(pos))

	else
		debug(flag11, "  ERROR: Unexpected 'listname' value: " .. listname)
	end

	debug(flag11, "on_metadata_inventory_take() end *** " .. mt_get_gametime() .. " ***")
end


core.override_item("ss:campfire_small_new", {
	on_construct = campfire_on_construct,
	after_place_node = campfire_after_place_node,
	on_timer = campfire_burn_loop,
    on_rightclick = campfire_on_rightclick,
	allow_metadata_inventory_move = campfire_allow_metadata_inventory_move,
	allow_metadata_inventory_put = campfire_allow_metadata_inventory_put,
	allow_metadata_inventory_take = campfire_allow_metadata_inventory_take,
	on_metadata_inventory_move = campfire_on_metadata_inventory_move,
	on_metadata_inventory_put = campfire_on_metadata_inventory_put,
	on_metadata_inventory_take = campfire_on_metadata_inventory_take,
	on_destruct = campfire_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		campfire_on_destruct(pos)
	end,
})

core.override_item("ss:campfire_small_burning", {
	on_timer = campfire_burn_loop,
    on_rightclick = campfire_on_rightclick,
	allow_metadata_inventory_move = campfire_allow_metadata_inventory_move,
	allow_metadata_inventory_put = campfire_allow_metadata_inventory_put,
	allow_metadata_inventory_take = campfire_allow_metadata_inventory_take,
	on_metadata_inventory_move = campfire_on_metadata_inventory_move,
	on_metadata_inventory_put = campfire_on_metadata_inventory_put,
	on_metadata_inventory_take = campfire_on_metadata_inventory_take,
	on_destruct = campfire_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		campfire_on_destruct(pos)
	end,
})

core.override_item("ss:campfire_small_used", {
	on_timer = campfire_burn_loop,
    on_rightclick = campfire_on_rightclick,
	allow_metadata_inventory_move = campfire_allow_metadata_inventory_move,
	allow_metadata_inventory_put = campfire_allow_metadata_inventory_put,
	allow_metadata_inventory_take = campfire_allow_metadata_inventory_take,
	on_metadata_inventory_move = campfire_on_metadata_inventory_move,
	on_metadata_inventory_put = campfire_on_metadata_inventory_put,
	on_metadata_inventory_take = campfire_on_metadata_inventory_take,
	on_destruct = campfire_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		campfire_on_destruct(pos)
	end,
})

core.override_item("ss:campfire_small_spent", {
	on_timer = campfire_burn_loop,
    on_rightclick = campfire_on_rightclick,
	allow_metadata_inventory_move = campfire_allow_metadata_inventory_move,
	allow_metadata_inventory_put = campfire_allow_metadata_inventory_put,
	allow_metadata_inventory_take = campfire_allow_metadata_inventory_take,
	on_metadata_inventory_move = campfire_on_metadata_inventory_move,
	on_metadata_inventory_put = campfire_on_metadata_inventory_put,
	on_metadata_inventory_take = campfire_on_metadata_inventory_take,
	on_destruct = campfire_on_destruct,
	on_flood = function(pos, oldnode, newnode)
		campfire_on_destruct(pos)
	end,
})




local flag2 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag2, "\nregister_on_player_receive_fields() CAMPFIRE")
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

	--debug(flag2, "  p_data.formspec_mode: " .. p_data.formspec_mode)
    if p_data.formspec_mode ~= "campfire" then
        --debug(flag2, "  interaction not from campfire formspec. NO FURTHER ACTION.")
        --debug(flag2, "register_on_player_receive_fields() end " .. mt_get_gametime())
        return
    else
        --debug(flag2, "  interaction from campfire formspec. inspecting fields..")
    end

    local fs = player_data[player_name].fs
	--debug(flag2, "  fields: " .. dump(fields))
    local player_meta = player:get_meta()
    local player_inv = player:get_inventory()
	local pos_key = p_data.campfire_pos_key
	local pos = key_to_pos(p_data.campfire_pos_key)
	local node_meta = mt_get_meta(pos)

	if fields.quit then
		--debug(flag2, "  player quit from campfire formspec")
		p_data.formspec_mode = "main_formspec"

		--debug(flag2, "  stopping any lopping formspec refresh jobs")
		cancel_refresh_formspec_job(player_name)

		--debug(flag2, "  removing player name from campfire users table")
		remove_formspec_viewer(formspec_viewers[pos_key], player_name)
		--debug(flag2, "  formspec_viewers (after): " .. dump(formspec_viewers))

	elseif fields.campfire_start then
		--debug(flag2, "  lighting campfire...")

		local node_inv = node_meta:get_inventory()

		-- fire starter slot is empty
		if node_inv:is_empty("fire_starter") then
			--debug(flag2, "    no fire starter tool found. NO FURTHER ACTION.")
			play_sound("button", {player_name = player_name})
			notify(player, "inventory", "Fire starter tool is missing.", NOTIFY_DURATION, 0, 0.5, 3)

		-- fire starter item is equipped
		else
			local item = node_inv:get_stack("fire_starter", 1)
			local fire_starter_name = item:get_name()
			--debug(flag2, "    fire_starter_name: " .. fire_starter_name)
			play_sound("item_use", {item_name = fire_starter_name, player = player})

			-- increase tool wear for the fire starter item
			local item_meta = item:get_meta()
			local remaining_uses = item_meta:get_int("remaining_uses")
			--debug(flag2, "    current remaining_uses: " .. remaining_uses)
			remaining_uses = remaining_uses - 1
			--debug(flag2, "    updated remaining_uses: " .. remaining_uses)

			if remaining_uses > 0 then
				--debug(flag2, "    fire starter tool can still be used")
				update_meta_and_description(item_meta, fire_starter_name, {"remaining_uses"}, {remaining_uses})
				node_inv:set_stack("fire_starter", 1, item)

			else
				--debug(flag2, "    ** fire starter tool all used up **")
				node_inv:set_stack("fire_starter", 1, ItemStack(""))
				play_sound("item_break", {item_name = fire_starter_name, pos = pos})
				local broken_items = ITEM_DESTRUCT_PATH[fire_starter_name]
				if broken_items then
					--debug(flag2, "    resulted in broken items")
					for i, broken_item_name in ipairs(broken_items) do
						--debug(flag2, "      broken_item_name: " .. broken_item_name)
						local broken_item = ItemStack(broken_item_name)
						mt_add_item(player:get_pos(), broken_item)
					end
					notify(player, "inventory", "Item broke. Scraps dropped to ground.", 3, 0.5, 0, 2)
				else
					--debug(flag2, "    no broken items")
				end
			end

			local fire_start_success = true
			if fire_starter_name == "ss:fire_drill" then

				-- using fire drill reduces lots of stamina and other stats
				--debug(flag2, "    p_data.stamina_loss_fire_drill: " .. p_data.stamina_loss_fire_drill)
				do_stat_update_action(player, p_data, player_meta, "normal", "stamina", -p_data.stamina_loss_fire_drill, "curr", "add", true)

				-- 33% of fire drill failing to light
				local random_num = math_random()
				--debug(flag2, "    fire_drill_success_rate: " .. p_data.fire_drill_success_rate)
				--debug(flag2, "    random_num: " .. random_num)
				if random_num > p_data.fire_drill_success_rate then
					--debug(flag2, "    fire drill failed to light")
					notify(player, "inventory", "Failed to ignite. Try again.", NOTIFY_DURATION, 0, 0.5, 3)
					fire_start_success = false
				end

			elseif fire_starter_name == "ss:match_book" then

				-- 10% of matches failing to light
				local random_num = math_random()
				--debug(flag2, "    match_book_success_rate: " .. p_data.match_book_success_rate)
				--debug(flag2, "    random_num: " .. random_num)
				if random_num > p_data.match_book_success_rate then
					--debug(flag2, "    match failed to light")
					notify(player, "inventory", "Failed to ignite. Try another.", NOTIFY_DURATION, 0, 0.5, 3)
					fire_start_success = false
				end

			else
				debug(flag2, "    ERROR - Unexpected fire_starter_name value: " .. fire_starter_name)
			end

			-- proceed to light campfire
			if fire_start_success then

				--debug(flag2, "    campfire turned on successfully")
				local ingredient_slots = node_inv:get_list("ingredients")
				for i, ingredient_item in ipairs(ingredient_slots) do
					--debug(flag2, "    slot #" .. i)
					if not ingredient_item:is_empty() then
						local ingredient_item_name = ingredient_item:get_name()
						--debug(flag2, "    ingredient item found: " .. ingredient_item_name)
						-- campfire turned on while item in ingred slot")
						check_ingredient_status(ingredient_item, node_inv, i, player)
					end
				end

				-- refresh campfire formspec to reflect 'on' state
				node_meta:set_string("campfire_status", "on")

				play_sound("campfire_start", {pos = pos})

				-- activating node timer in 3 seconds
				local node_timer = mt_get_node_timer(pos)
				node_timer:start(FUEL_BURN_INTERVAL)

				-- replace campfire node with ss:campfire_small_burning
				mt_swap_node(pos, {name = "ss:campfire_small_burning"})

				-- adding smoke effect above campfire
				start_smoke_particles(pos)

				-- add lit campfire as a radiant source for 'feels like' temperature
				radiant_sources[p_data.campfire_pos_key] = RADIANT_SOURCES_DATA["ss:campfire_small_burning"]

			end
			refresh_formspec(pos, pos_key)

		end

	elseif fields.campfire_stop then
		--debug(flag2, "  stopping campfire...")
		play_sound("button", {player_name = player_name})
		stop_campfire(pos, pos_key, node_meta)

	elseif fields.campfire_rebuild then
		--debug(flag2, "  attempting campfire rebuild...")
		play_sound("button", {player_name = player_name})

		-- get ingredients for campfire
		local recipe_id = "tool_campfire"
		local camfire_recipe_data = RECIPES[recipe_id]
		local camfire_ingredients = camfire_recipe_data.ingredients

		-- check if player is missing ingredients for campfire recipe
		local missing_ingredients = false
		local campfire_ingredients_weight = 0
		for i, itemstring in ipairs(camfire_ingredients) do
			local itemstack = ItemStack(itemstring)
			local item_name = itemstack:get_name()
			--debug(flag2, "  looking for ingredient: " .. item_name)

			local missing_count = count_missing_items(player, itemstack)
			--debug(flag2, "  missing_count: " .. missing_count)

			if missing_count > 0 then
				missing_ingredients = true
			else
				local itemstack_weight = get_itemstack_weight(itemstack)
				campfire_ingredients_weight = campfire_ingredients_weight + itemstack_weight
			end
		end

		if missing_ingredients then
			--debug(flag2, "  missing campfire ingredients")
			notify(player, "inventory", "Missing campfire ingredients.", NOTIFY_DURATION, 0, 0.5, 3)

		else
			--debug(flag2, "  necessary ingredients avail. rebuilding campfire...")
			play_sound("item_use", {item_name = "ss:campfire_small_new", player = player})

			-- remove item from inventory
			for i, itemstring in ipairs(camfire_ingredients) do
				local itemstack = ItemStack(itemstring)
				local item_name = itemstack:get_name()
				--debug(flag2, "  removing ingredient: " .. item_name)
				player_inv:remove_item("main", itemstack)
			end

			-- update weight statbar hud and weight formspec to reflect removal of item
			--debug(flag2, "  reducing inv weight by: " .. campfire_ingredients_weight)
			do_stat_update_action(player, p_data, player_meta, "normal", "weight", -campfire_ingredients_weight, "curr", "add", true)
			fs.center.weight = get_fs_weight(player)

			--debug(flag2, "  refresh crafting pane and ingred box to reflect consumed items..")
			update_crafting_ingred_and_grid(player_name, player_inv, p_data, fs)

			-- give exp to player for rebuilding
			--debug(flag2, "  updating experience hudbar...")
            local ingredient_count = #camfire_ingredients
            local experience_gained = ingredient_count * p_data.experience_gain_crafting * p_data.experience_rec_mod_fast_learner
            --debug(flag2, "  experience_gained: " .. experience_gained)
			do_stat_update_action(player, p_data, player_meta, "normal", "experience", experience_gained, "curr", "add", true)

			--debug(flag2, "    restore campfire fuel value")
			node_meta:set_int("burn_time_campfire", CAMPFIRE_CORE_BURNTIME)

			--debug(flag2, "    set campfire status back to off")
			node_meta:set_string("campfire_status", "off")

			--debug(flag2, "    replace campfire node to ss:campfire_small_new")
			mt_swap_node(pos, {name = "ss:campfire_small_new"})

			--debug(flag2, "    dropping item-drops to ground relating to spent campfire")
			drop_campfire_drops(pos, "ss:campfire_small_spent")

			--debug(flag2, "  refreshing formspec..")
			player_meta:set_string("fs", mt_serialize(fs))
			local formspec = build_fs(fs)
			player:set_inventory_formspec(formspec)
			refresh_formspec(pos, pos_key)
		end
	end

    debug(flag2, "register_on_player_receive_fields() end *** " .. mt_get_gametime() .. " ***")
end)



local flag8 = false
core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    debug(flag8, "\nregister_allow_player_inventory_action() cooking_stations.lua")
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

	if p_data.formspec_mode ~= "campfire" then
		--debug(flag8, "  not using campfire. skip.")
		--debug(flag8, "  register_allow_player_inventory_action() end *** " .. mt_get_gametime() .. " ***")
		return
	end

	--local refresh_inventory_ui = false
    local player_meta = player:get_meta()
    --local fs = p_data.fs
    local block_action = false

	--debug(flag8, "  action: " .. action)
    if action == "move" then

		local to_list = inventory_info.to_list
        local to_index = inventory_info.to_index
        local from_list = inventory_info.from_list
        local from_index = inventory_info.from_index
        local item = inventory:get_stack(from_list, from_index)
        local item_name = item:get_name()

        --debug(flag8, "  item_name: " .. item_name)
        --debug(flag8, "  to_list: " .. to_list)

		if to_list == "main" then
			--debug(flag8, "  Moved any item to another slot within main inventory: Allowed")
			if SPILLABLE_ITEM_NAMES[item_name] then
                --debug(flag2, "  this is a filled cup!")
                if to_index > 8 then
                    --debug(flag2, "  cannot be placed in main inventory")
                    notify(player, "inventory", NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
                    block_action = true
                end
            end

		else
			notify(player, "error", "ERROR - Unexpected 'to_list' value: " .. to_list, NOTIFY_DURATION, 0, 0.5, 3)
			block_action = true
		end


	elseif action == "take" then
        --debug(flag8, "  Action TAKE not yet implemented.")

	elseif action == "put" then
		local listname = inventory_info.listname
        local item = inventory_info.stack
        local to_index = inventory_info.index
        local item_name = item:get_name()
        --debug(flag8, "  PUT " .. item_name .. " into " .. listname .. " at index " .. to_index)

		local to_item = inventory:get_stack(listname, to_index)
		if not to_item:is_empty() then
			notify(player, "inventory", "Cannot swap - find empty slot", NOTIFY_DURATION, 0, 0.5, 3)
			block_action = true

		elseif SPILLABLE_ITEM_NAMES[item_name] then
			--debug(flag8, "  this is a filled cup!")
			if to_index > 8 then
				--debug(flag8, "  cannot be placed in main inventory")
				notify(player, "inventory", NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
				block_action = true
			else
				--debug(flag8, "  placing into hotbar")
				if exceeds_inv_weight_max(item, player_meta) then
					notify(player, "inventory", NOTIFICATIONS.inv_weight_max, NOTIFY_DURATION, 0, 0.5, 3)
					block_action = true
				end
			end

		else
			--debug(flag8, "  not a filled cup")
			if exceeds_inv_weight_max(item, player_meta) then
				notify(player, "inventory", NOTIFICATIONS.inv_weight_max, NOTIFY_DURATION, 0, 0.5, 3)
				block_action = true
			end
		end

	else
		--debug(flag8, "  UNEXPECTED ACTION: " .. action)
	end

    debug(flag8, "register_allow_player_inventory_action() end *** " .. mt_get_gametime() .. " ***")
	if block_action then return 0 end
end)



local flag7 = false
core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    debug(flag7, "\nregister_on_player_inventory_action() CAMPFIRE")
	local player_name = player:get_player_name()
    local p_data = player_data[player_name]

	if p_data.formspec_mode ~= "campfire" then
		--debug(flag7, "  not using campfire. skip.")
		--debug(flag7, "register_allow_player_inventory_action() end *** " .. mt_get_gametime() .. " ***")
		return
	end

	local player_meta = player:get_meta()
    local fs = player_data[player_name].fs

	if action == "move" then
		local to_list = inventory_info.to_list
        local to_index = inventory_info.to_index
		local item = inventory:get_stack(to_list, to_index)
		local item_name = item:get_name()
		play_sound("item_move", {item_name = item_name, player_name = player_name})

	elseif action == "take" then
		local listname = inventory_info.listname
        local item = inventory_info.stack
        local from_index = inventory_info.index
        local item_name = item:get_name()
        --debug(flag7, "  listname: " .. listname)
        --debug(flag7, table_concat({ "  >> * REMOVED * ", item_name, " from player inventory. Took from ", listname, "[", from_index, "]" }) )
		play_sound("item_move", {item_name = item_name, player_name = player_name})

		local weight = get_itemstack_weight(item)
		update_weight_data(player, player_meta, p_data, fs, -weight)
		update_crafting_ingred_and_grid(player_name, inventory, p_data, fs)
		player_meta:set_string("fs", mt_serialize(fs))
		player:set_inventory_formspec(build_fs(fs))

	elseif action == "put" then

		--debug(flag7, "  Moved item from campfire to player inventory")
		local item = inventory_info.stack
		reset_cook_data(item)
		inventory:set_stack("main", inventory_info.index, item)

		local weight = get_itemstack_weight(item)
		update_weight_data(player, player_meta, p_data, fs, weight)
		update_crafting_ingred_and_grid(player_name, inventory, p_data, fs)
		player_meta:set_string("fs", mt_serialize(fs))
		player:set_inventory_formspec(build_fs(fs))

	else
        --debug(flag7, "  UNEXPECTED ACTION: " .. action)
    end

    debug(flag7, "register_on_player_inventory_action() end *** " .. mt_get_gametime() .. " ***")
end)



local flag47 = false
core.register_on_joinplayer(function(player)
	debug(flag47, "\nregister_on_joinplayer() COOKING STATIONS")
	local player_meta = player:get_meta()
    local p_data = player_data[player:get_player_name()]
	local metadata

	-- the success rate to start a flame using a the fire starter tool. for example,
    -- the value of 0.5 = 50% success rate, 1 = 100% success rate.
	metadata = player_meta:get_float("fire_drill_success_rate")
	p_data.fire_drill_success_rate = (metadata ~= 0 and metadata) or 0.5
	metadata = player_meta:get_float("match_book_success_rate")
	p_data.match_book_success_rate = (metadata ~= 0 and metadata) or 0.8

	-- how much xp gained for crafting an item. this value is multiplied by the
	-- number of outputs if the crafting recipe results in multiple items.
	metadata = player_meta:get_float("experience_gain_cooking")
	p_data.experience_gain_cooking = (metadata ~= 0 and metadata) or 0.5

	debug(flag47, "\nregister_on_joinplayer() end")
end)



local flag50 = false
core.register_on_respawnplayer(function(player)
    debug(flag50, "\nregister_on_respawnplayer() COOKING STATIONS")
	local player_meta = player:get_meta()
	local p_data = player_data[player:get_player_name()]

	-- reset fire starter tools success rates
	p_data.fire_drill_success_rate = 0.50
	player_meta:set_float("fire_drill_success_rate", p_data.fire_drill_success_rate)
	p_data.match_book_success_rate = 0.80
	player_meta:set_float("match_book_success_rate", p_data.match_book_success_rate)

	-- reset crafting and cooking xp gain rates
    p_data.experience_gain_cooking = 0.5
	player_meta:set_float("experience_gain_cooking", p_data.experience_gain_cooking)

	debug(flag50, "register_on_respawnplayer() end")
end)





local flag44 = false
core.register_on_item_pickup(function(itemstack, picker, pointed_thing, time_from_last_punch)
    debug(flag44, "\nregister_on_item_pickup() CAMPFIRE")
    reset_cook_data(itemstack)
    debug(flag44, "register_on_item_pickup() END timestamp " .. mt_get_gametime())
end)



-- find any campfires that were still lit when chunk was unloaded and rerun needed
-- actions to indicate they are lit again
local flag27 = false
core.register_lbm({
    name = "ss:reactivate_campfire",
    nodenames = {"ss:campfire_small_burning"},
    run_at_every_load = true,
    action = function(pos, node)
		debug(flag27, "\nregister_lbm() reactivate_campfire")

		-- restart smoke particles
		local node_id = mt_hash_node_position(pos)
		local particle_id = particle_ids[node_id]
		if particle_id then
			--debug(flag27, "  smoke particles already activated. no action.")
		else
			--debug(flag27, "  adding smoke effect above campfire")
			start_smoke_particles(pos)
		end

		-- re-add pos to global radiant_sources table
		radiant_sources[pos_to_key(pos)] = RADIANT_SOURCES_DATA["ss:campfire_small_burning"]

		debug(flag27, "register_lbm() END")
    end,
})


local flag34 = false
-- ensure the global formspec_viewers table has an entry for this campfire, consisting
-- of the pos_key as the index. the 'remove_formspec_all_viewers' global table relies
-- on all campfire nodes in the world to have an entry.
core.register_lbm({
    name = "ss:add_campfire_pos_formspec_viewers",
    nodenames = {
		"ss:campfire_small_new",
		"ss:campfire_small_burning",
		"ss:campfire_small_used",
		"ss:campfire_small_spent"
	},
    run_at_every_load = true,
    action = function(pos, node)
		debug(flag34, "\nregister_lbm() add_campfire_pos_formspec_viewers")
		local pos_key = pos_to_key(pos)
		local viewers = formspec_viewers[pos_key]
		if viewers then
			--debug(flag34, "  campfire pos " .. pos_key .. " already exists in formspec_viewers" )
		else
			formspec_viewers[pos_key] = {}
			--debug(flag34, "  campfire pos " .. pos_key .. " added to formspec_viewers" )
		end
		--debug(flag34, "  formspec_viewers: " .. dump(formspec_viewers))
		debug(flag34, "register_lbm() END")
    end,
})


--[[ 
NOTES

Campfire Node:

A campfire can only be placed on the top of a walkable node, and not the bottom or sides of
and node. Also, attempting to place a node on top of a solid node that has a gap on the top
like a stick, stone, stairs, slabs, etc. will cause the campfire to drop.

The campfire node first starts out as 'new'. Then when it is turned on, will transform
into the 'burning' variant. When it is then turned of, it transformed to 'used'. The
campfire continues to swap between 'used' and 'burning' versions as it is turned off
and on. Once the campfire core fuel is completely used up, it transforms into the
'spent' version.

Digging or destroying a campfire will produce item drops based on its current state. New or
unused campfires drop most of it's initial crafting recipe ingredients. Used and burning
campfires will drop a small amount of wood, sticks, and charcoal. Spent campfires drop charcoal
and ash. When a spent campfire is 'rebuit', the old charcoal and ash is dropped to the ground
as the new campfire appears.

Cooking Process:

When a new unheated ingredient item starts to be heated/cooked, it first undergoes an initial
'warm_up' period where the duration in seconds is determined by COOK_WARM_UP_TIME and the
item is not heated. During this warm up period, if the item is removed from the campfire or
the campfire is turned off, no 'cooker' is assigned to the item and its warm up timer is reset.
Once the warm up period is passed, the item then gets heated and the player who initiated the
heating/cooking process has their name assigned as the 'cooker'.

For or each second while being cooked, the item's 'heat_progress' value is increased at a rate
determined by the ITEM_HEAT_RATES table. Once the heat_progress reaches the COOK_THRESHOLD,
the item converts to the next resulting item, determined by the ITEM_COOK_PATH table. This
results in some ingredients turning into a different consumable item like an apple turning into
a dried apple, which can then be cooked further and turn to ashes. Other items can be 'cooked'
nto different resource like wood into charcoal, while other items like paper will simply turn
to ashes.

Lighting the Campfire:

A fire starter tool like a fire drill or book of matches is needed to light a campfire.
The fire drill requires a good amount of stamina and has a moderate chance of failing.
Matches don't require much stamina and has a higher chance of success. The amount of
stamina drain when using a fire drill is specific to the player's 'stamina_loss_fire_drill'
attribute which defaults to 20, but can be lowered by skilling up. The success rate of
lighting a fire using the fire drill or matches is also specific to the player, and
corresponds to the 'fire_drill_success_rate' and 'match_book_success_rate' attribute,
which also can be improved by skilling up.

Cooking Ingredients:

Any item can be placed into the ingredients slot. nonflammable items like stone, dirt,
metals, and charcoal, will remain and do nothing. Only a single item is allowed in the
ingredient slot. However, items like wood and sticks when 'cooked' results in a stack
of multiple charcoal, likewise some large food items when charred too long will result
in a stack of multiple ashes. Ashes are an exception. Any ashes that result within the
ingredient slot due to cooking will be automatically dropped to the ground.

Whether an item in the ingredient slot is nonflammable or cookable, is determined by the
ITEM_COOK_PATH table. If the item name exists as a key index in this table, then it is
cookable, and when cooked, will turn into the item defined by the corresponding element,
which represents the heated / cooking version of the item. Items not present in the
ITEM_COOK_PATH table are considered nonflammable.

Items undergoing heating / cooking are represented in the ITEM_COOK_PATH table, which
also defines the resulting item it will convert to when the cooking process is complete.
The ITEM_HEAT_RATES table will always contain the same key indexes as ITEM_COOK_PATH,
and define how quickly an item being heated will complete the cooking process.

Examples of Cooking Paths for Items:

new/unheated wooden item > charcoal > ash
new/unheated misc resource item > some other resource > ash
new/unheated misc resrouce > ash
new/unheated misc resource item > some other nonflammable item > does nothing
new/unheated food item > cooked food item > ash
new/unheated container of liquid > container with boiled/cooked liquid > empty container
new/unheated empty container > charcoal or maybe an nonflammable resource


Campfire Fuel:

The ability to place an item into the fuel slot is determined by its burn time. If the
value is greater than zero, it is 'burnable' and be placed in the fuel slot. if the
burn time value is zero, it is no flammable and cannot be placed in the fule slot.

When heated items (due to cooking) is placed in a fuel slot, its 'heat_progress' is used
to determine its actual burn time - instead of using its burn_time value directly. For example,
if an item's heat_progress is 80%, then 20% of the item's burn time is remains for fuel.
If due to this calculation the item's burn time results to 0, then it remains as 1.

Campfire Tools:

These are like campfire stands and campfire tools that can be equipped into a campfire.
For each second the campfire is lit, the campfire receives some wear which is reflected
in its 'condition' property. This value starts at 10000, and decreases as the tool is
worn. When the condition reachees zero, it is completely worn, and transforms into the
item that correspond to its cook result. Therefor wooden campfire stands and grills will
turn to charcoal. So in essence, this can be an alterative way to get charcoal other
than heating it in the ingred slot.

Burning Adjacent Nodes:

Nodes that are not nonflammable that are directly adjacent to the campfire will be burned or
cooked too. For example, trees, leaves, wooden structures, and plantlife will get burned
and drop items like partially burned stickes or wood, charcoal, ash, etc. The time it takes
for a flammable node to get burned is approx 3 times compared to if it was cooked within the
campfire's ingredient slot. punching any node with briefly display its current burn progress.

Bundling Items:

Most items are stackable, including ingredient items for cooking, fuel items, campfire tools,
and fire starter items. But, once they are heated, or partially used/consumed, they are not
stackable. Ihe 'item bundling' feature allows players to stack or 'bundle' items with varying
metadata values (like for 'heat_progress', 'condition', 'cooker', 'remaining_uses', etc) to
be bundled into a single itemstack. However, these item bundles can no longer be used directly
as cooking ingredients, campfire fuel, or campfire tools. they must fist be un-bundled.

XP from Cooking:

Ingredient items that are cooked in a campfire will have a player's name tagged to it
designating who will get the XP from cooking it. Once an item is tagged with a player's
name, it cannot be subsequently tagged by another player. There are two instances when
an ingredient item is tagged: 1) when the player places the item in the ingredient slot
while the campfire is on, or 2) the player turns on a campfire that was previously off
any items in the ingredient slots that are not yet tagged, will then get tagged.
	
Once the item is cooked, the XP is given to the player whose name was tagged. If the
player was offline when the food finished cooking, the server maintains a record of the
XP 'owed' to the player, and grants that XP the next time the player rejoins the game.

==== CAMPFIRE FEATURES LIST ====

CRAFTING CAMPFIRE
- 4 wood and 4 sticks

PLACING CAMPFIRE
- can only be placed on top side of walkable nodes
- if walkable node is gappy, campfire will fall and drop items

INGREDIENT SLOTS
- only single count item can go into ingredient slot
- anything can be placed into ingredient slot, but on certain are cookable

FUEL SLOT
- only burnables can go into fuel slot
- there is max weight limit for fuel slots

FUEL INDICATOR AND WEIGHT
- core fuel vs extra fuel
- weight max can be increased by tools

FIRESTARTER ITEM SLOT
- item gets worn out whenever fire start is attempted
- item doesn't always start fire, based on player's success rate
- fire starter uses up stamina (thus hunger, thirst, and others)

SPENT CAMPFIRE AND REBUILDING
- requires campfire recipe ingredients to rebuild
- drops charcoal and ash

CAMPFIRE TOOLS
- increases ingredient and fuel slots
- campfire tools wearing out
- worn out tools will reduce slots and drop items
- putting used campfire tools into ingredient slots
- putting used campfire tools into fuel slots
- only campfire tools can go into tool slots

COOKING
- smoke particle shows
- no cooker is assigned during 'warm up' period
- xp gained after item is cooked
- xp recovery if quit came before item is cooked

DIGGING UP CAMPFIRE
- item drops based on state of campfire (new, used/burning, or spent)
- also drops contents of all campfire slots
- drops when it's bottom support node is removed
- drops when water flows into it
- drops when snow falls onto it
- drops when falling node like sand falls onto it

COOKING ADJACENT NODES
- nodes nearby campfile will also get cooked

LEAVING CAMPFIRE ON WHILE TRAVELLING AWAY
- campfire keeps track of elapse time when campfire is unloaded
- campfire applies all elapsed time and ensures all items in slots are processed

MULTIPLAYER
- players can interact with campfire UI simultaneously


--]]