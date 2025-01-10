print("- loading admin_items.lua")

-- cache global functions and tables for faster access
local math_sin = math.sin
local math_cos = math.cos
local math_pi = math.pi
local string_upper = string.upper
local table_concat = table.concat
local table_insert = table.insert
local mt_show_formspec = minetest.show_formspec
local mt_set_timeofday = minetest.set_timeofday
local mt_get_mapgen_setting = minetest.get_mapgen_setting
local mt_get_node = minetest.get_node
local mt_swap_node = minetest.swap_node
local mt_chat_send_player = minetest.chat_send_player
local mt_pos_to_string = minetest.pos_to_string
local mt_get_biome_data = minetest.get_biome_data
local mt_get_biome_name = minetest.get_biome_name
local mt_after = minetest.after
local debug = ss.debug
local round = ss.round
local player_control_fix = ss.player_control_fix
local use_item = ss.use_item
local play_item_sound = ss.play_item_sound
local set_stat_value = ss.set_stat_value
local notify = ss.notify
local update_fs_weight = ss.update_fs_weight
local update_meta_and_description = ss.update_meta_and_description
local get_valid_y_pos = ss.get_valid_y_pos
local pos_to_key = ss.pos_to_key
local key_to_pos = ss.key_to_pos
local pickup_item = ss.pickup_item


local NOTIFY_DURATION = ss.NOTIFY_DURATION
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local ITEM_MAX_USES = ss.ITEM_MAX_USES
local CLOTHING_NAMES = ss.CLOTHING_NAMES
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local ARMOR_NAMES = ss.ARMOR_NAMES
local ARMOR_COLORS = ss.ARMOR_COLORS
local ARMOR_CONTRASTS = ss.ARMOR_CONTRASTS

local player_data = ss.player_data
local formspec_viewers = ss.formspec_viewers
local mt_registered_nodes = minetest.registered_nodes



local SS_ITEMS = {
    "ss:grass_clump",
    "ss:dry_grass_clump",
    "ss:marram_grass_clump",
    "ss:jungle_grass_clump",
    "ss:leaves_fern",
    "ss:leaves_clump",
    "ss:leaves_dry_clump",
    "ss:pine_needles",
    "ss:scrap_wood",
    "ss:stick",
    "ss:wood",
    "ss:wood_plank",
    "ss:dirt_pile",
    "ss:dirt_permafrost_pile",
    "ss:clay",
    "ss:stone",
    "ss:stone_pile",
    "ss:desert_stone_pile",
    "ss:sand_pile",
    "ss:desert_sand_pile",
    "ss:silver_sand_pile",
    "ss:sandstone_pile",
    "ss:desert_sandstone_pile",
    "ss:silver_sandstone_pile",
    "ss:snow_pile",
    "default:snow",
    "ss:ice",
    "ss:flower_chrysanthemum_green",
    "ss:flower_chrysanthemum_green_picked",
    "ss:flower_dandelion_white",
    "ss:flower_dandelion_white_picked",
    "ss:flower_dandelion_yellow",
    "ss:flower_dandelion_yellow_picked",
    "ss:flower_geranium",
    "ss:flower_geranium_picked",
    "ss:flower_rose",
    "ss:flower_rose_picked",
    "ss:flower_tulip",
    "ss:flower_tulip_picked",
    "ss:flower_tulip_black",
    "ss:flower_tulip_black_picked",
    "ss:flower_viola",
    "ss:flower_viola_picked",
    "ss:flower_waterlily",
    "ss:flower_waterlily_flower",
    "ss:papyrus",
    "ss:cactus",
    "ss:cactus_dried",
    "ss:kelp",
    "ss:coral_cyan",
    "ss:coral_green",
    "ss:coral_pink",
    "ss:coral_skeleton",
    "ss:moss",
    "ss:plant_fiber",
    "ss:string",
    "ss:rope",
    "ss:animal_hide",
    "ss:leather",
    "ss:cloth",
    "ss:scrap_iron",
    "ss:scrap_glass",
    "ss:scrap_rubber",
    "ss:scrap_plastic",
    "ss:scrap_paper",
    "ss:charcoal",
    "default:coal_lump",
    "ss:ash",
    "ss:bag_fiber_small",
    "ss:bag_fiber_medium",
    "ss:bag_fiber_large",
    "ss:bag_cloth_small",
    "ss:bag_cloth_medium",
    "ss:bag_cloth_large",
    "ss:apple",
    "ss:apple_dried",
    "ss:blueberries",
    "ss:blueberries_dried",
    "ss:mushroom_brown",
    "ss:mushroom_brown_dried",
    "ss:mushroom_red",
    "ss:mushroom_red_dried",
    "ss:meat_raw_beef",
    "ss:meat_raw_pork",
    "ss:meat_raw_mutton",
    "ss:meat_raw_poultry_large",
    "ss:cup_wood",
    "ss:cup_wood_water_murky",
    "ss:cup_wood_water_boiled",
    "ss:bowl_wood",
    "ss:bowl_wood_water_murky",
    "ss:bowl_wood_water_boiled",
    "ss:pot_iron",
    "ss:pot_iron_water_murky",
    "ss:pot_iron_water_boiled",
    "ss:jar_glass_lidless",
    "ss:jar_glass_lidless_water_murky",
    "ss:jar_glass_lidless_water_boiled",
    "ss:jar_glass",
    "ss:jar_glass_water_murky",
    "ss:jar_glass_water_boiled",
    "ss:clothes_sunglasses",
    "ss:clothes_glasses",
    "ss:clothes_shirt_fiber",
    "ss:clothes_tshirt",
    "ss:clothes_pants_fiber",
    "ss:clothes_pants",
    "ss:clothes_shorts",
    "ss:clothes_socks",
    "ss:clothes_scarf",
    "ss:clothes_necklace",
    "ss:clothes_gloves_fiber",
    "ss:clothes_gloves_leather",
    "ss:clothes_gloves_fingerless",
    "ss:armor_feet_fiber_1",
    "ss:armor_feet_fiber_2",
    "ss:armor_head_wood_1",
    "ss:armor_chest_wood_1",
    "ss:armor_arms_wood_1",
    "ss:armor_legs_wood_1",
    "ss:armor_head_cloth_2",
    "ss:armor_face_cloth_1",
    "ss:armor_face_cloth_2",
    "ss:armor_feet_cloth_2",
    "ss:armor_head_leather_1",
    "ss:armor_head_leather_2",
    "ss:armor_chest_leather_1",
    "ss:armor_arms_leather_1",
    "ss:armor_legs_leather_1",
    "ss:armor_feet_leather_1",
    "ss:stone_sharpened",
    "ss:hammer_wood",
    "default:axe_stone",
    "default:pick_stone",
    "default:sword_stone",
    "default:shovel_stone",
    "farming:hoe_stone",
    "default:torch",
    "ss:campfire_small_new",
    "ss:campfire_stand_wood",
    "ss:campfire_grill_wood",
    "ss:fire_drill",
    "ss:match_book",
    "default:ladder_wood",
    "default:ladder_steel",
    "default:fence_wood",
    "default:sign_wall_wood",
    "default:sign_wall_steel",
    "ss:bandages_basic",
    "ss:bandages_medical",
    "ss:pain_pills",
    "ss:health_shot",
    "ss:first_aid_kit",
    "ss:splint",
    "ss:stats_wand",
    "ss:item_spawner",
    "ss:teleporter",
    "ss:screwdriver",
    "ss:sword_admin",
    "stairs:slab_wood",
    "stairs:stair_wood",
    "stairs:stair_inner_wood",
    "stairs:stair_outer_wood",
    "default:dirt",
    "default:blueberry_bush_leaves_with_berries",
    "default:tree",
    "default:leaves",
    "default:sapling",
    "default:junglesapling",
    "default:emergent_jungle_sapling",
    "default:pine_sapling",
    "default:acacia_sapling",
    "default:aspen_sapling",
    "default:bush_sapling",
    "default:acacia_bush_sapling",
    "default:pine_bush_sapling",
    "default:blueberry_bush_sapling",
    "default:large_cactus_seedling",
    "default:papyrus"
}






local function set_stat_current(player, fields, stat, direction)
	local stat_mod_info = {
		[stat] =  {
			direction = direction,
			amount = tonumber(fields["change_value_" .. stat]),
			is_immediate = (fields["speed_type_" .. stat] == "instant")
		}
	}
	use_item(player, player:get_meta(), "ss:mushroom_brown", stat_mod_info, "action", 1.0)
end


local function set_stat_max(player, fields, stat, direction)
	local player_meta = player:get_meta()
	if direction == "up" then
		local stat_max = player_meta:get_float(stat .. "_max")
		local new_max = stat_max + tonumber(fields["change_value_" .. stat])
		set_stat_value(player, stat, player_meta:get_float(stat .. "_current"), new_max)
		notify(player, "Max " .. stat .. " is now " .. new_max, NOTIFY_DURATION, "message_box_2")
	else
		local stat_current = player_meta:get_float(stat .. "_current")
		local stat_max = player_meta:get_float(stat .. "_max")
		local new_max = stat_max - tonumber(fields["change_value_" .. stat])
		if new_max < stat_current then
			stat_current = new_max
		end
		set_stat_value(player, stat, stat_current, new_max)
		notify(player, "Max " .. stat .. " is now " .. new_max, NOTIFY_DURATION, "message_box_2")
	end
end


local flag12 = false
function ss.get_inventory_weight(player_inv)
	debug(flag12, "\nget_inventory_weight()")
	local inventory_weight = 0
	for inv_location, inv_data in pairs(player_inv:get_lists()) do
		debug(flag12, "  inv_location: " .. inv_location)

		-- loop through all items in the current inv location
		for _, item in ipairs(inv_data) do
			if not item:is_empty() then
				local item_name = item:get_name()
                debug(flag12, "  item_name: " .. item_name)
                local item_meta = item:get_meta()

                local stack_weight
                if item_meta:contains("bundle_weight") then
                    debug(flag12, "  this is a bundle")
                    stack_weight = item_meta:get_float("bundle_weight")
                else
                    stack_weight = ITEM_WEIGHTS[item_name] * item:get_count()
                end

				debug(flag12, "  stack_weight: " .. stack_weight)
				inventory_weight = inventory_weight + stack_weight
			end
		end
	end
	debug(flag12, "  inventory_weight: " .. inventory_weight)
	debug(flag12, "get_inventory_weight() end")
	return inventory_weight
end
local get_inventory_weight = ss.get_inventory_weight



-- ################################
-- ########## STATS WAND ##########
-- ################################

local flag8 = false
minetest.override_item("ss:stats_wand", {
    stack_max = 0,
    on_use = function(itemstack, user, pointed_thing)
		debug(flag8, "\n## Used STATS Wand (LMB) ##")

        local controls = user:get_player_control()
        if controls.aux1 then

            local player_name = user:get_player_name()
            local p_data = ss.player_data[player_name]
            p_data.formspec_mode = "stats_wand"
            p_data.active_tab = "stats_wand"

            local formspec = "size[8.8,10.0]position[0.5,0.45]label[3.2,0;Modify Player Stats]"
            local stats = {"health", "thirst", "hunger", "immunity", "sanity", "breath", "stamina", "experience"}
            local ypos = 1.0  -- Y position for the first stat
            for _, stat in ipairs(stats) do
                formspec = table_concat({ formspec,
                    "label[0.2,", ypos, ";", string_upper(stat), "]",
                    "dropdown[2.0,", ypos, ";1.25,1;change_type_", stat, ";curr,max;1]",
                    "dropdown[3.5,", ypos, ";1,1;change_value_", stat, ";1,3,5,10,50;4]",
                    "dropdown[4.8,", ypos, ";1.5,1;speed_type_", stat, ";instant,delayed;1]",
                    "button[6.55,", ypos - 0.1, ";1,1;increase_", stat, ";+]",
                    "button[7.55,", ypos - 0.1, ";1,1;decrease_", stat, ";-]"
                })
                ypos = ypos + 1  -- Increase ypos for the next stat
            end
            formspec = table_concat({ formspec,
                "label[0.2,", ypos, ";WEIGHT]",
                "dropdown[2.0,", ypos, ";1.25,1;change_type_weight;curr,max;1]",
                "dropdown[3.5,", ypos, ";1,1;change_value_weight;50,100,200,500;2]",
                "button[4.80,", ypos - 0.1, ";1.5,1;recalc_weight;recalc]",
                "button[6.55,", ypos - 0.1, ";1,1;increase_weight;+]",
                "button[7.55,", ypos - 0.1, ";1,1;decrease_weight;-]"
            })

            mt_show_formspec(user:get_player_name(), "ss:ui_stats_wand", formspec)
            player_control_fix(user)

        else
            debug(flag8, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)
        end
	end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        debug(flag8, "\n## Used STATS Wand (RMB) ##")
        local player_name = user:get_player_name()
        mt_set_timeofday(0.25)

        local stat_mod_info = {
            ["health"] =  { direction = "up", amount = 100, is_immediate = true },
            ["thirst"] =  { direction = "up", amount = 100, is_immediate = true },
            ["hunger"] =  { direction = "up", amount = 100, is_immediate = true },
            ["immunity"] =  { direction = "up", amount = 100, is_immediate = true },
            ["sanity"] =  { direction = "up", amount = 100, is_immediate = true },
            ["breath"] =  { direction = "up", amount = 100, is_immediate = true },
            ["stamina"] =  { direction = "up", amount = 100, is_immediate = true }
        }
        use_item(user, user:get_meta(), "ss:mushroom_brown", stat_mod_info, "action", 1.0)
    end
})












-- ##################################
-- ########## ITEM SPAWNER ##########
-- ##################################

-- Function to generate the formspec based on the current page
local function generate_item_spawner_formspec(page)
    local items_per_page = 150
    local start_index = (page - 1) * items_per_page + 1
    local end_index = math.min(start_index + items_per_page - 1, #SS_ITEMS)

    local formspec = table.concat({
        "formspec_version[7]",
        "size[16,12]",
        "label[6.85,0.75;ITEM SPAWNER]",
        "button[13.5,0.25;1,1;page_1;1]",
        "button[14.5,0.25;1,1;page_2;2]",
    })

    local row = 0.5
    local column = 0.5

    for i = start_index, end_index do
        local item_name = SS_ITEMS[i]
        formspec = formspec .. string.format(
            "item_image_button[%f,%f;1,1;%s;%s;]",
            column, row + 1, item_name, item_name
        )
        column = column + 1
        if column >= 15 then
            column = 0.5
            row = row + 1
        end
    end

    return formspec
end



local flag5 = true
minetest.override_item("ss:item_spawner", {
	stack_max = 0,
	on_use = function(itemstack, user, pointed_thing)
		debug(flag5, "\n#### ITEM SPAWNER USED: LEFT Clicked ####")

        local controls = user:get_player_control()
        if controls.aux1 then
            debug(flag5, "  pressing aux1. activating item use..")
            local player_name = user:get_player_name()
            local p_data = ss.player_data[player_name]
            p_data.formspec_mode = "item_spawner"
            p_data.active_tab = "item_spawner"
            p_data.current_page = p_data.current_page or 1 -- Default to Page 1

            local formspec = generate_item_spawner_formspec(p_data.current_page)
            minetest.show_formspec(player_name, "ss:ui_item_spawner", formspec)
            --player_control_fix(user)

        else
            debug(flag5, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)
        end

	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		debug(flag5, "\n#### ITEM SPAWNER USED: RIGHT Clicked ####")

		local player_meta = user:get_meta()
		local player_name = user:get_player_name()
        local p_data = ss.player_data[player_name]

        local seed = mt_get_mapgen_setting("seed")
        debug(flag5, "  world seed: " .. seed .. "\n")

        local child_entities = user:get_children()
        debug(flag5, "  child_entities: " .. dump(child_entities) .. "\n")

        --[[
        debug(flag5, "  checking for nearby objects...")
        for object in minetest.objects_inside_radius(user:get_pos(), 5) do
            if object:is_player() then
                debug(flag5, "    this is a player: " .. object:get_player_name())
            else
                local luaentity =  object:get_luaentity()
                local entity_name = luaentity.name
                if entity_name == "__builtin:item" then
                    local dropped_item = ItemStack(luaentity.itemstring)
                    local dropped_item_name = dropped_item:get_name()
                    debug(flag5, "    this is a item: " .. dropped_item_name)
                else
                    debug(flag5, "    this is a non-craftitem entity: " .. entity_name)
                end
            end
        end
        --]]

        -- Loop through the hotbar (assumed to be the first 8 slots)
		local player_inv = user:get_inventory()
        for i = 1, 8 do
            local item = player_inv:get_stack("main", i)
            local item_name = item:get_name()

            -- Print the item name to the console
            debug(flag5, "  Slot " .. i .. " " .. item_name)

            local item_def = minetest.registered_items[""]
            --debug(flag5, "  item_def: " .. dump(item_def))

            local item_meta = item:get_meta()
            local metadata_table = item_meta:to_table()
            for key, value in pairs(metadata_table.fields) do
                value = value:gsub("\n", "<br>")
                debug(flag5, "    " .. key .. ": " .. value)
            end
        end
        debug(flag5, "")

        debug(flag5, "formspec_viewers: " .. dump(formspec_viewers))
        

	end
})






-- #################################
-- ########## TELEPORTER ###########
-- #################################


local flag4 = false
local function get_teleport_data(player)
    debug(flag4, "  get_teleport_data() admin_items.lua")
    local teleport_data = {}
    local teleport_distance = 100

    local pos = player:get_pos()
    debug(flag4, "    pos: " .. mt_pos_to_string(pos))

    local yaw = player:get_look_horizontal()
    debug(flag4, "    yaw: " .. yaw)

    local yaw_increment = math_pi / 4

    -- start from yaw value that represents 'forward-left' or 'NW' direction in respect
    -- to the currect direction player is facing. this is because in the for loop below
    -- the value i = 2 represents 'forward-facing' direction and increments by 1/4 pi
    -- clockwise at each iteration. thus i = 1 must start at yaw 1/4 pi counter clockwise.
    yaw = yaw - yaw_increment
    debug(flag4, "   starting yaw: " .. yaw)

    -- i = 1 through 8 below, represents NW, N, NE, E, SE, S, SW, and W, or in other words
    -- forward_left, forward, forward_right, right, back_right, back, back_left, and left
    -- directions in the context of the teleport target positions.
    for i = 1, 3 do
        debug(flag4, "   target index: " .. i)
        -- calculate the forward direction vector
        local dir_x = -math_sin(yaw)
        local dir_z = math_cos(yaw)

        -- caculate teleport position 100 meters out
        local teleport_x = round(pos.x + dir_x * teleport_distance, 1)
        local teleport_z = round(pos.z + dir_z * teleport_distance, 1)
        local teleport_y = get_valid_y_pos({x = teleport_x, y = pos.y, z = teleport_z})

        local teleport_pos = {x = round(pos.x, 1), y = round(pos.y, 1), z = round(pos.z, 1)}
        local data
        if teleport_y then
            debug(flag4, "    valid pos found")
            teleport_pos = {x = teleport_x, y = round(teleport_y, 1), z = teleport_z}

            -- get biome data at that position
            local biome_data = mt_get_biome_data(teleport_pos)
            local biome_id = biome_data.biome

            -- store teleport pos and biome name into teleport_data table
            data = {pos = pos_to_key(teleport_pos), biome_name = mt_get_biome_name(biome_id)}

        else
            debug(flag4, "    ** location not fully loaded **")
            data = {pos = pos_to_key(teleport_pos), biome_name = "(not loaded)"}
        end

        table_insert(teleport_data, data)
        yaw = yaw + yaw_increment
    end

    -- insert biome name of current pos of player into the teleport_data table
    local biome_data = mt_get_biome_data(pos)
    local current_biome_id = biome_data.biome
    local current_biome_name = mt_get_biome_name(current_biome_id)
    table.insert(teleport_data, {biome_name = current_biome_name})
    debug(flag4, "    teleport_data: " .. dump(teleport_data))

    debug(flag4, "  get_teleport_data() END")
    return teleport_data
end

local function get_fs_teleporter(teleport_data)
    local formspec = table.concat({
        "formspec_version[7]",
        "size[13.0,3.5]",
        "position[0.5,1]",
        "anchor[0.5,1]",

        "label[4.5,0.5;Current Biome: ", teleport_data[4].biome_name, "]",
        "label[4.5,1.5;Nearby Biome Destinations]",
        "button[0.5,2.0;4,1;", teleport_data[1].pos, ";", teleport_data[1].biome_name, "]",
        "button[4.5,2.0;4,1;", teleport_data[2].pos, ";", teleport_data[2].biome_name, "]",
        "button[8.5,2.0;4,1;", teleport_data[3].pos, ";", teleport_data[3].biome_name, "]",
    })
    return formspec
end


local flag3 = false
minetest.override_item("ss:teleporter", {
    on_use = function(itemstack, user, pointed_thing)
        debug(flag3, "\non_use() admin_items.lua")

        local controls = user:get_player_control()
        if controls.aux1 then
            local player_name = user:get_player_name()
            local p_data = ss.player_data[player_name]
            p_data.formspec_mode = "teleporter"
            p_data.active_tab = "teleporter"

            local teleport_data = get_teleport_data(user)
            local formspec = get_fs_teleporter(teleport_data)
            minetest.show_formspec(player_name, "ss:ui_teleporter", formspec)
            player_control_fix(user)
            debug(flag3, "on_use() END")
        else
            debug(flag3, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)
        end

    end,

})










-- #################################
-- ########## SCREWDRIVER ##########
-- #################################

minetest.override_item("ss:screwdriver", {
    on_use = function(itemstack, user, pointed_thing)
        -- Check if the player is pointing at a node
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        -- Get the position and node at the pointed location
        local pos = pointed_thing.under
        local node = mt_get_node(pos)

        -- Check if the node is rotatable (e.g., a stair or similar node)
        if mt_registered_nodes[node.name] then
            -- Cycle the param2 value (node orientation)
            local new_param2 = (node.param2 + 1) % 24  -- Cycle through 0 to 23 (possible orientations)

            -- Set the new orientation of the node
            mt_swap_node(pos, {name = node.name, param2 = new_param2})

            -- Optionally: play a sound or show a message
            mt_chat_send_player(user:get_player_name(), "Node rotated to param2: " .. new_param2)
        end

    end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        -- Check if the player is pointing at a node
        if pointed_thing.type ~= "node" then
            return itemstack
        end

        -- Get the position and node at the pointed location
        local pos = pointed_thing.under
        local node = mt_get_node(pos)

        -- Check if the node is rotatable
        if mt_registered_nodes[node.name] then
            -- Modify only the axis (rotate by multiples of 4)
            local current_orientation = node.param2 % 4  -- Keep the current rotation within the axis
            local new_axis = ((node.param2 / 4) + 1) % 6  -- Cycle through the 6 axes (y+, z+, z-, x+, x-, y-)
            local new_param2 = new_axis * 4 + current_orientation  -- Combine the new axis with the same orientation

            -- Set the new axis with the same orientation
            mt_swap_node(pos, {name = node.name, param2 = new_param2})

            -- Optionally: send a message
            mt_chat_send_player(user:get_player_name(), "Axis changed, new param2: " .. new_param2)
        end
    end,
})



-- formspec for the 'stats wand' debug tool
local flag2 = false
minetest.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag2, "\nregister_on_player_receive_fields() admin_items.lua")
	--debug(flag2, "  fields: " .. dump(fields))

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    debug(flag2, "  formname: " .. formname)
    debug(flag2, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag2, "  active_tab: " .. p_data.active_tab)

    local formspec_mode = p_data.formspec_mode

    if fields.quit then
        debug(flag2, "  exited formspec. NO FURTHER ACTION.")
        if p_data.active_tab == "stats_wand"
            or p_data.active_tab == "item_spawner"
            or p_data.active_tab == "teleporter" then
            p_data.formspec_mode = "main_formspec"
            p_data.active_tab = "main"
        end
        debug(flag2, "register_on_player_receive_fields() end")
        return

    elseif formspec_mode == "stats_wand" then
        debug(flag2, "  used STATS WAND")

        if fields.increase_health then
            if fields.change_type_health == "curr" then
                debug(flag2, "  increasing current health")
                set_stat_current(player, fields, "health", "up")
            else
                debug(flag2, "  increasing max health")
                set_stat_max(player, fields, "health", "up")
            end

        elseif fields.decrease_health then
            if fields.change_type_health == "curr" then
                debug(flag2, "  decreasing health")
                set_stat_current(player, fields, "health", "down")
            else
                debug(flag2, "  decreasing max health")
                set_stat_max(player, fields, "health", "down")
            end

        elseif fields.increase_thirst then
            if fields.change_type_thirst == "curr" then
                debug(flag2, "  increase thirst")
                set_stat_current(player, fields, "thirst", "up")
            else
                debug(flag2, "  increasing max thirst")
                set_stat_max(player, fields, "thirst", "up")
            end

        elseif fields.decrease_thirst then
            if fields.change_type_thirst == "curr" then
                debug(flag2, "  decreasing thirst")
                set_stat_current(player, fields, "thirst", "down")
            else
                debug(flag2, "  decreasing max thirst")
                set_stat_max(player, fields, "thirst", "down")
            end

        elseif fields.increase_hunger then
            if fields.change_type_hunger == "curr" then
                debug(flag2, "  increase hunger")
                set_stat_current(player, fields, "hunger", "up")
            else
                debug(flag2, "  increasing max hunger")
                set_stat_max(player, fields, "hunger", "up")
            end

        elseif fields.decrease_hunger then
            if fields.change_type_hunger == "curr" then
                debug(flag2, "  decreasing hunger")
                set_stat_current(player, fields, "hunger", "down")
            else
                debug(flag2, "  decreasing max hunger")
                set_stat_max(player, fields, "hunger", "down")
            end

        elseif fields.increase_immunity then
            if fields.change_type_immunity == "curr" then
                debug(flag2, "  increase immunity")
                set_stat_current(player, fields, "immunity", "up")
            else
                debug(flag2, "  increasing max immunity")
                set_stat_max(player, fields, "immunity", "up")
            end

        elseif fields.decrease_immunity then
            if fields.change_type_immunity == "curr" then
                debug(flag2, "  decreasing immunity")
                set_stat_current(player, fields, "immunity", "down")
            else
                debug(flag2, "  decreasing max immunity")
                set_stat_max(player, fields, "immunity", "down")
            end

        elseif fields.increase_sanity then
            if fields.change_type_sanity == "curr" then
                debug(flag2, "  increase sanity")
                set_stat_current(player, fields, "sanity", "up")
            else
                debug(flag2, "  increasing max sanity")
                set_stat_max(player, fields, "sanity", "up")
            end

        elseif fields.decrease_sanity then
            if fields.change_type_sanity == "curr" then
                debug(flag2, "  decreasing sanity")
                set_stat_current(player, fields, "sanity", "down")
            else
                debug(flag2, "  decreasing max sanity")
                set_stat_max(player, fields, "sanity", "down")
            end

        elseif fields.increase_breath then
            if fields.change_type_breath == "curr" then
                debug(flag2, "  increase breath")
                set_stat_current(player, fields, "breath", "up")
            else
                debug(flag2, "  increasing max breath")
                set_stat_max(player, fields, "breath", "up")
            end

        elseif fields.decrease_breath then
            if fields.change_type_breath == "curr" then
                debug(flag2, "  decreasing breath")
                set_stat_current(player, fields, "breath", "down")
            else
                debug(flag2, "  decreasing max breath")
                set_stat_max(player, fields, "breath", "down")
            end

        elseif fields.increase_stamina then
            if fields.change_type_stamina == "curr" then
                debug(flag2, "  increase stamina")
                set_stat_current(player, fields, "stamina", "up")
            else
                debug(flag2, "  increasing max stamina")
                set_stat_max(player, fields, "stamina", "up")
            end

        elseif fields.decrease_stamina then
            if fields.change_type_stamina == "curr" then
                debug(flag2, "  decreasing stamina")
                set_stat_current(player, fields, "stamina", "down")
            else
                debug(flag2, "  decreasing max stamina")
                set_stat_max(player, fields, "stamina", "down")
            end

        elseif fields.increase_experience then
            if fields.change_type_experience == "curr" then
                debug(flag2, "  increase experience")
                set_stat_current(player, fields, "experience", "up")
            else
                debug(flag2, "  increasing max experience")
                set_stat_max(player, fields, "experience", "up")
            end

        elseif fields.decrease_experience then
            if fields.change_type_experience == "curr" then
                debug(flag2, "  decreasing experience")
                set_stat_current(player, fields, "experience", "down")
            else
                debug(flag2, "  decreasing max experience")
                set_stat_max(player, fields, "experience", "down")
            end

        elseif fields.increase_weight then
            if fields.change_type_weight == "curr" then
                debug(flag2, "  increase weight")
                fields.speed_type_weight = "instant"
                set_stat_current(player, fields, "weight", "up")
            else
                debug(flag2, "  increasing max weight")
                set_stat_max(player, fields, "weight", "up")
            end
            mt_after(1, update_fs_weight, player, player:get_meta())

        elseif fields.decrease_weight then
            if fields.change_type_weight == "curr" then
                debug(flag2, "  decreasing weight")
                fields.speed_type_weight = "instant"
                set_stat_current(player, fields, "weight", "down")
            else
                debug(flag2, "  decreasing max weight")
                set_stat_max(player, fields, "weight", "down")
            end
            mt_after(1, update_fs_weight, player, player:get_meta())

        elseif fields.recalc_weight then
            debug(flag2, "  recalculating weight")

            local inventory_weight = get_inventory_weight(player:get_inventory())
            debug(flag2, "  inventory_weight: " .. inventory_weight)

            debug(flag2, "  refreshing weight formspec")
            local player_meta = player:get_meta()
            player_meta:set_float("weight_current", inventory_weight)
            update_fs_weight(player, player:get_meta())

            debug(flag2, "  updating weight stat hud")
            set_stat_value(player, "weight", player_meta:get_float("weight_current"), player_meta:get_float("weight_max"))

        else
            debug(flag2, "  ERROR - Unexpected field value")
        end

    elseif formspec_mode == "item_spawner" then
        debug(flag2, "  used ITEM SPAWNER")

        -- Handle pagination buttons
        if fields.page_1 then
            if p_data.current_page ~= 1 then
                debug(flag2, "  loading page 1")
                play_item_sound("button", {player_name = player_name})
                p_data.current_page = 1
                local formspec = generate_item_spawner_formspec(1)
                minetest.show_formspec(player_name, "ss:ui_item_spawner", formspec)
            end
            return
        elseif fields.page_2 then
            local page_2_start = 151
            if p_data.current_page ~= 2 and #SS_ITEMS >= page_2_start then
                debug(flag2, "  loading page 2")
                play_item_sound("button", {player_name = player_name})
                p_data.current_page = 2
                local formspec = generate_item_spawner_formspec(2)
                minetest.show_formspec(player_name, "ss:ui_item_spawner", formspec)
            end
            return
        end

        for item_name, _ in pairs(fields) do
            debug(flag2, "  item_name: " .. item_name)
            play_item_sound("button", {player_name = player_name})
            local item = ItemStack(item_name)

            -- CONSUMABLE ITEMS: add 'remaining_uses' metadata
            if ITEM_MAX_USES[item_name] then
                debug(flag2, "  consumable item")
                local item_meta = item:get_meta()
                update_meta_and_description(item_meta, item_name, {"remaining_uses"}, {ITEM_MAX_USES[item_name]})

            -- CLOTHING: add custom colorization metadata
            elseif CLOTHING_NAMES[item_name] then
                debug(flag2, "  clothing item")
                local clothing_name = CLOTHING_NAMES[item_name]
                local clothing_color = CLOTHING_COLORS[clothing_name][1]
                local clothing_contrast = CLOTHING_CONTRASTS[clothing_name][1]
                local item_meta = item:get_meta()
                local inv_image = table_concat({
                    "ss_clothes_", clothing_name, ".png",
                    "^[colorizehsl:", clothing_color,
                    "^[contrast:", clothing_contrast,
                    "^[mask:ss_clothes_", clothing_name, "_mask.png"
                })
                item_meta:set_string("inventory_image", inv_image)
                item_meta:set_string("color", clothing_color)
                item_meta:set_string("contrast", clothing_contrast)

            -- ARMOR: add custom colorization metadata
            elseif ARMOR_NAMES[item_name] then
                debug(flag2, "  armor item")
                local armor_name = ARMOR_NAMES[item_name]
                local armor_color = ARMOR_COLORS[armor_name][1]
                local armor_contrast = ARMOR_CONTRASTS[armor_name][1]
                local item_meta = item:get_meta()
                local inv_image = table_concat({
                    "ss_armor_", armor_name, ".png",
                    "^[colorizehsl:", armor_color,
                    "^[contrast:", armor_contrast,
                    "^[mask:ss_armor_", armor_name, "_mask.png"
                })
                item_meta:set_string("inventory_image", inv_image)
                item_meta:set_string("color", armor_color)
                item_meta:set_string("contrast", armor_contrast)

            else
                debug(flag2, "  normal or default item")
            end

            local pos = player:get_pos()
            pos.y = pos.y + 0.5
            minetest.add_item(pos, item)
            break
        end

    elseif formspec_mode == "teleporter" then
        debug(flag2, "  used TELEPORTER")
        debug(flag2, "  fields: " .. dump(fields))
        local pos_key, biome_name
        for key, value in pairs(fields) do
            pos_key = key
            biome_name = value
        end
        debug(flag2, "  pos_key: " .. pos_key)
        debug(flag2, "  biome_name: " .. biome_name)

        local pos = key_to_pos(pos_key)
        debug(flag2, "  pos: " .. mt_pos_to_string(pos))

        player:set_pos(pos)

        local teleport_data = get_teleport_data(player)
        local formspec = get_fs_teleporter(teleport_data)
        minetest.show_formspec(player_name, "ss:ui_teleporter", formspec)
        player_control_fix(player)

    else
        debug(flag2, "  interaction not from an admin item. NO FURTHER ACTION.")
        debug(flag2, "register_on_player_receive_fields() end " .. minetest.get_gametime())
        return
    end










    debug(flag2, "register_on_player_receive_fields() end")
end)