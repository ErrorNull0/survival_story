print("- loading admin_items.lua")

-- cache global functions and tables for faster access
local math_sin = math.sin
local math_cos = math.cos
local math_min = math.min
local string_format = string.format
local table_concat = table.concat
local table_insert = table.insert
local mt_show_formspec = core.show_formspec
local mt_set_timeofday = core.set_timeofday
local mt_get_mapgen_setting = core.get_mapgen_setting
local mt_get_node = core.get_node
local mt_swap_node = core.swap_node
local mt_chat_send_player = core.chat_send_player
local mt_pos_to_string = core.pos_to_string
local mt_get_biome_data = core.get_biome_data
local mt_get_biome_name = core.get_biome_name
local mt_after = core.after
local debug = ss.debug
local round = ss.round
local player_control_fix = ss.player_control_fix
local after_player_check = ss.after_player_check
local play_sound = ss.play_sound
local update_fs_weight = ss.update_fs_weight
local update_meta_and_description = ss.update_meta_and_description
local get_valid_y_pos = ss.get_valid_y_pos
local pos_to_key = ss.pos_to_key
local key_to_pos = ss.key_to_pos
local pickup_item = ss.pickup_item
local update_stat = ss.update_stat
local do_stat_update_action = ss.do_stat_update_action

local math_pi = math.pi
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local ITEM_MAX_USES = ss.ITEM_MAX_USES
local CLOTHING_NAMES = ss.CLOTHING_NAMES
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local ARMOR_NAMES = ss.ARMOR_NAMES
local ARMOR_COLORS = ss.ARMOR_COLORS
local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local ARMOR_CONTRASTS = ss.ARMOR_CONTRASTS
local BIOME_DATA = ss.BIOME_DATA
local BIOME_DATA_DEFAULTS = ss.BIOME_DATA_DEFAULTS

local player_data = ss.player_data
local mt_registered_nodes = core.registered_nodes
local player_hud_ids = ss.player_hud_ids
local job_handles = ss.job_handles

local current_climates = ss.current_climates
if current_climates == nil then
    print("### ERROR - ss.current_climates is NIL")
end


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
    "ss:cast",
    "ss:stats_wand",
    "ss:item_spawner",
    "ss:debug_wand",
    "ss:weather_wand",
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





local flag10 = false
local function set_stat_current(player, p_data, fields, stat, direction)
    debug(flag10, "  set_stat_current() ADMIN ITEMS")
    debug(flag10, "    stat: " .. stat)
    debug(flag10, "    fields: " .. dump(fields))
    local amount = tonumber(fields["change_value_" .. stat]) or 0
    local is_immediate = fields["speed_type_" .. stat] == "instant"
    if amount then
        local update_data
        if is_immediate then
            if direction == "down"then
                amount = -amount
            end
            do_stat_update_action(player, p_data, player:get_meta(), "normal", stat, amount, "curr", "add", true)

        else
            local iterations = amount
            if direction == "down"then
                amount = -amount
            end
            update_data = {"normal", stat, amount, iterations, 1, "curr", "add", true}
            update_stat(player, p_data, player:get_meta(), update_data)
        end
    else
        debug(flag10, "    ERROR - unexpected 'stat' value is NIL")
    end
    debug(flag10, "  set_stat_current() END")
end


local flag9 = false
local function set_stat_max(player, p_data, fields, stat, direction)
    debug(flag9, "  set_stat_max()")
    debug(flag9, "    stat: " .. stat)
    debug(flag9, "    direction: " .. direction)

    local change_value = tonumber(fields["change_value_" .. stat]) or 0
    debug(flag9, "    change_value: " .. change_value)

	if direction == "down" then
        change_value = -change_value
	end
    do_stat_update_action(player, p_data, player:get_meta(), "normal", stat, change_value, "max", "add", true)
    debug(flag9, "  set_stat_max() END")
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
core.override_item("ss:stats_wand", {
    stack_max = 0,
    on_use = function(itemstack, user, pointed_thing)
		debug(flag8, "\n## Used STATS Wand (LMB) ##")

        local controls = user:get_player_control()
        if controls.aux1 then

            local player_name = user:get_player_name()
            local p_data = ss.player_data[player_name]
            p_data.formspec_mode = "stats_wand"
            p_data.active_tab = "stats_wand"

            local formspec = "formspec_version[7]size[9.0,14.0]position[0.5,0.45]label[3.2,0.5;Modify Player Stats]"
            local stats = {"health", "thirst", "hunger", "alertness", "hygiene",
                "comfort", "immunity", "sanity", "happiness", "breath", "legs", "hands",
                "stamina", "experience", "illness", "poison", "wetness"}
            local ypos = 1.2  -- Y position for the first stat
            for _, stat in ipairs(stats) do
                local statbar_icon_element = table_concat({"image[1.9,", ypos, ";0.5,0.5;ss_statbar_icon_", stat, ".png;]"})
                if stat == "stamina" or stat == "experience" or stat == "illness"
                    or stat == "poison" or stat == "wetness" then
                    statbar_icon_element = ""
                end
                formspec = table_concat({ formspec,
                    statbar_icon_element,
                    "label[0.3,", ypos + 0.2, ";", stat, "]",
                    "dropdown[2.8,", ypos, ";1.25,0.5;change_type_", stat, ";curr,max;1]",
                    "tooltip[2.5,", ypos, ";1.25,0.5;modify the 'current' or 'maximum' value;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                    "dropdown[4.2,", ypos, ";1.1,0.5;change_value_", stat, ";0.1,1,5,10,25,50,100,150;3]",
                    "tooltip[4.2,", ypos, ";1.1,0.5;the amount to raise or lower;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                    "dropdown[5.5,", ypos, ";1.7,0.5;speed_type_", stat, ";instant,delayed;1]",
                    "tooltip[5.5,", ypos, ";1.7,0.5;apply the amount instantly or gradually;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                    "button[7.4,", ypos, ";0.5,0.5;increase_", stat, ";+]",
                    "tooltip[7.4,", ypos, ";0.5,0.5;increase the stat;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                    "button[8.1,", ypos, ";0.5,0.5;decrease_", stat, ";-]",
                    "tooltip[8.1,", ypos, ";0.5,0.5;decrease the stat;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                })
                ypos = ypos + 0.7  -- Increase ypos for the next stat
            end

            formspec = table_concat({ formspec,
                "label[0.3,", ypos + 0.2, ";weight]",
                "dropdown[2.8,", ypos, ";1.25,0.5;change_type_weight;curr,max;1]",
                "tooltip[2.8,", ypos, ";1.25,0.5;modify the 'current' or 'maximum' value;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                "dropdown[4.2,", ypos, ";1.1,0.5;change_value_weight;50,100,300,600;3]",
                "tooltip[4.2,", ypos, ";1.1,0.5;the amount to raise or lower;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                "button[5.5,", ypos, ";1.7,0.5;recalc_weight;recalc]",
                "tooltip[5.5,", ypos, ";1.7,0.5;recalculate total inventory weight;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                "button[7.4,", ypos, ";0.5,0.5;increase_weight;+]",
                "tooltip[7.4,", ypos, ";0.5,0.5;increase inv weight;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
                "button[8.1,", ypos, ";0.5,0.5;decrease_weight;-]",
                "tooltip[8.1,", ypos, ";0.5,0.5;decrease inv weight;",
                        TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
            })

            mt_show_formspec(player_name, "ss:ui_stats_wand", formspec)
            player_control_fix(user)

        else
            debug(flag8, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)
        end
	end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        debug(flag8, "\n## Used STATS Wand (RMB) ##")
        mt_set_timeofday(0.25)

        local stat_names = {"health", "thirst", "hunger", "immunity", "alertness",
            "sanity", "hygiene", "comfort", "happiness", "breath", "legs", "hands", "stamina"}
        local p_data = player_data[user:get_player_name()]
        local player_meta = user:get_meta()
        for i, stat in ipairs(stat_names) do
            update_stat(
                user, p_data, player_meta,
                {"normal", stat, 999, 1, 1, "curr", "add", true}
            )
        end

        update_stat(
            user, p_data, player_meta,
            {"normal", "poison", -999, 1, 1, "curr", "add", true}
        )

        update_stat(
            user, p_data, player_meta,
            {"normal", "illness", -999, 1, 1, "curr", "add", true}
        )

        update_stat(
            user, p_data, player_meta,
            {"normal", "wetness", -999, 1, 1, "curr", "add", true}
        )

    end
})






-- ##################################
-- ########## ITEM SPAWNER ##########
-- ##################################

-- Function to generate the formspec based on the current page
local function generate_item_spawner_formspec(page)
    local items_per_page = 150
    local start_index = (page - 1) * items_per_page + 1
    local end_index = math_min(start_index + items_per_page - 1, #SS_ITEMS)

    local formspec = table_concat({
        "formspec_version[7]",
        "size[16,12]",
        "label[0.5,0.75;Quantity:]",
        "dropdown[2.0,0.5;1.0,0.5;dropdown_quantity;1,5,10,99;1]",
        "label[6.85,0.75;ITEM SPAWNER]",
        "label[13.2,0.75;Page:]",
        "button[14.2,0.4;0.6,0.6;page_1;1]",
        "button[14.9,0.4;0.6,0.6;page_2;2]",
    })

    local row = 0.5
    local column = 0.5

    for i = start_index, end_index do
        local item_name = SS_ITEMS[i]
        formspec = formspec .. string_format(
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



local flag5 = false
core.override_item("ss:item_spawner", {
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
            mt_show_formspec(player_name, "ss:ui_item_spawner", formspec)
            --player_control_fix(user)

        else
            debug(flag5, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)


            local hud_id = player_hud_ids[user:get_player_name()].test_hud
            if hud_id then
                user:hud_remove(hud_id)
                player_hud_ids[user:get_player_name()].test_hud = nil
            end

        end

	end,
	on_secondary_use = function(itemstack, user, pointed_thing)
		debug(flag5, "\n#### ITEM SPAWNER USED: RIGHT Clicked ####")

		local player_meta = user:get_meta()
		local player_name = user:get_player_name()
        local p_data = ss.player_data[player_name]

        local physics = user:get_physics_override()

        debug(flag5, "  p_data.player_status: " .. p_data.player_status)
        debug(flag5, "  world seed: " .. mt_get_mapgen_setting("seed"))

        debug(flag5, "  stamina_drain_mod_thirst: " .. p_data.stamina_drain_mod_thirst)
        debug(flag5, "  stamina_drain_mod_hunger: " .. p_data.stamina_drain_mod_hunger)
        debug(flag5, "  stamina_drain_mod_alertness: " .. p_data.stamina_drain_mod_alertness)
        debug(flag5, "  stamina_drain_mod_weight: " .. p_data.stamina_drain_mod_weight .. "\n")

        debug(flag5, "  physics.speed: " .. physics.speed)
        debug(flag5, "  physics.jump: " .. physics.jump .. "\n")

        debug(flag5, "  status effects: " .. dump(p_data.status_effects) .. "\n")
        debug(flag5, "  stat updates: " .. dump(p_data.stat_updates) .. "\n")

        --[[
        local hud_definition = {
            type = "image",
            position = {x = 0, y = 0},
            alignment = {x=1, y=1},
            offset = {x = 0, y = 0},
            text = "ss_screen_effect_health_3.png",
            scale = {x = -100, y = -100},
            z_index = -9999,
        }
        player_hud_ids[player_name].test_hud = user:hud_add(hud_definition)

        debug(flag5, "  lighting preferences: " .. dump(user:get_lighting()))

                --local child_entities = user:get_children()
        --debug(flag5, "  child_entities: " .. dump(child_entities) .. "\n")   

        user:hud_add({
            type = "image",
            position = {x = 0, y = 1},
            offset = {x = 2, y = -200},
            text = "[combine:32x32:0,0=ss_stat_effect_warning.png:4,4=ss_statbar_icon_hygiene.png",
            scale = {x = 1.5, y = 1.5},
            alignment = {x = 1, y = 0}
        })
        --]]

        --debug(flag5, "  p_data: " .. dump(ss.player_hud_ids[player_name]) .. "\n")

        --[[
        debug(flag5, "  checking for nearby objects...")
        for object in core.objects_inside_radius(user:get_pos(), 5) do
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
        --[[
		local player_inv = user:get_inventory()
        for i = 1, 8 do
            local item = player_inv:get_stack("main", i)
            local item_name = item:get_name()

            -- Print the item name to the console
            debug(flag5, "  Slot " .. i .. " " .. item_name)

            local item_def = core.registered_items[""]
            --debug(flag5, "  item_def: " .. dump(item_def))

            local item_meta = item:get_meta()
            local metadata_table = item_meta:to_table()
            for key, value in pairs(metadata_table.fields) do
                value = value:gsub("\n", "<br>")
                debug(flag5, "    " .. key .. ": " .. value)
            end
        end
        debug(flag5, "")
        --]]

        --debug(flag5, "formspec_viewers: " .. dump(formspec_viewers))

	end
})





-- ##################################
-- ########## WEATHER WAND ##########
-- ##################################

local flag13 = false
local function update_climate_range(type, amount, biome_data)
    debug(flag13, "  update_climate_range()")
    debug(flag13, "    type: " .. type)

    if type == "air_temp_min" then
        local min_value = biome_data.temp_min
        local max_value = biome_data.temp_max
        local new_value = min_value + amount
        debug(flag13, "    new_value: " .. new_value)
        if new_value < max_value then
            if new_value < -150 then
                debug(flag13, "    new temp is too low. clamped to -150 F.")
                new_value = -150
            else
                debug(flag13, "    new temp within valid range.")
            end
        else
            new_value = max_value - 1
            debug(flag13, "    new temp cannot equal or exceed max temp. clamped to: " .. new_value)
        end
        biome_data.temp_min = new_value

    elseif type == "air_temp_max" then
        local min_value = biome_data.temp_min
        local max_value = biome_data.temp_max
        local new_value = max_value + amount
        debug(flag13, "    new_value: " .. new_value)
        if new_value > min_value then
            if new_value > 200 then
                debug(flag13, "    new temp is too high. clamped to 200 F.")
                new_value = 200
            else
                debug(flag13, "    new temp within valid range.")
            end
        else
            new_value = min_value + 1
            debug(flag13, "    new temp cannot be equal or below mmin temp. clamped to: " .. new_value)
        end
        biome_data.temp_max = new_value

    elseif type == "humidity_min" then
        local min_value = biome_data.humidity_min
        local max_value = biome_data.humidity_max
        local new_value = min_value + amount
        debug(flag13, "    new_value: " .. new_value)
        if new_value < max_value then
            if new_value < 0 then
                debug(flag13, "    new humidity is too low. clamped to 0%.")
                new_value = 0
            else
                debug(flag13, "    new humidity within valid range.")
            end
        else
            new_value = max_value - 1
            debug(flag13, "    new humidity cannot equal or exceed max humidity. clamped to: " .. new_value)
        end
        biome_data.humidity_min = new_value

    elseif type == "humidity_max" then
        local min_value = biome_data.humidity_min
        local max_value = biome_data.humidity_max
        local new_value = max_value + amount
        debug(flag13, "    new_value: " .. new_value)
        if new_value > min_value then
            if new_value > 100 then
                debug(flag13, "    new humidity is too high. clamped to 100%.")
                new_value = 100
            else
                debug(flag13, "    new humidity within valid range.")
            end
        else
            new_value = min_value + 1
            debug(flag13, "    new humidity cannot be equal or below mmin humidity. clamped to: " .. new_value)
        end
        biome_data.humidity_max = new_value

    elseif type == "wind_speed_min" then
        local min_value = biome_data.wind_speed_min
        local max_value = biome_data.wind_speed_max
        local new_value = min_value + amount
        debug(flag13, "    new_value: " .. new_value)
        if new_value < max_value then
            if new_value < 0 then
                debug(flag13, "    new wind speed is too low. clamped to 0%.")
                new_value = 0
            else
                debug(flag13, "    new wind speed within valid range.")
            end
        else
            new_value = max_value - 1
            debug(flag13, "    new wind speed cannot equal or exceed max wind speed. clamped to: " .. new_value)
        end
        biome_data.wind_speed_min = new_value

    elseif type == "wind_speed_max" then
        local min_value = biome_data.wind_speed_min
        local max_value = biome_data.wind_speed_max
        local new_value = max_value + amount
        debug(flag13, "    new_value: " .. new_value)
        if new_value > min_value then
            if new_value > 40 then
                debug(flag13, "    new wind speed is too high. clamped to 40 m/s.")
                new_value = 40
            else
                debug(flag13, "    new wind speed within valid range.")
            end
        else
            new_value = min_value + 1
            debug(flag13, "    new wind speed cannot be equal or below mmin wind speed. clamped to: " .. new_value)
        end
        biome_data.wind_speed_max = new_value

    else
        debug(flag13, "    ERROR - Unexpected 'type' value: " .. type)
    end

    debug(flag13, "  update_climate_range() END")
end


local function get_fs_weather_wand(biome_name, increment_index)
    local air_temp_min = BIOME_DATA[biome_name].temp_min
    local air_temp_max = BIOME_DATA[biome_name].temp_max
    local humidity_min = BIOME_DATA[biome_name].humidity_min
    local humidity_max = BIOME_DATA[biome_name].humidity_max
    local wind_min = BIOME_DATA[biome_name].wind_speed_min
    local wind_max = BIOME_DATA[biome_name].wind_speed_max

    local formspec = "formspec_version[7]size[6.7,6.8]position[0.5,0.45]label[1.9,0.5;Modify Biome Climate]"

    local ypos = 1.2  -- Y position for the first row of element(s)

    formspec = table_concat({ formspec,
        "label[0.3,", ypos + 0.2, ";current biome:]",
        "label[2.5,", ypos + 0.2, ";", biome_name, "]",
    })

    ypos = ypos + 0.7
    formspec = table_concat({ formspec,
        "label[0.3,", ypos + 0.2, ";min air temperature: ", air_temp_min, " °F]",

        "button[4.5,", ypos, ";0.5,0.5;increase_air_temp_min;+]",
        "tooltip[4.5,", ypos, ";0.5,0.5;increase min air temperature;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.2,", ypos, ";0.5,0.5;decrease_air_temp_min;-]",
        "tooltip[5.2,", ypos, ";0.5,0.5;decrease min air temperature;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.9,", ypos, ";0.5,0.5;reset_air_temp_min;x]",
        "tooltip[5.9,", ypos, ";0.5,0.5;reset min air temperature;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
    })

    ypos = ypos + 0.7
    formspec = table_concat({ formspec,
        "label[0.3,", ypos + 0.2, ";max air temperature: ", air_temp_max, " °F]",

        "button[4.5,", ypos, ";0.5,0.5;increase_air_temp_max;+]",
        "tooltip[4.5,", ypos, ";0.5,0.5;increase max air temperature;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.2,", ypos, ";0.5,0.5;decrease_air_temp_max;-]",
        "tooltip[5.2,", ypos, ";0.5,0.5;decrease max air temperature;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.9,", ypos, ";0.5,0.5;reset_air_temp_max;x]",
        "tooltip[5.9,", ypos, ";0.5,0.5;reset max air temperature;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
    })

    ypos = ypos + 0.7
    formspec = table_concat({ formspec,
        "label[0.3,", ypos + 0.2, ";min relative humidity: ", humidity_min, "%]",

        "button[4.5,", ypos, ";0.5,0.5;increase_humidity_min;+]",
        "tooltip[4.5,", ypos, ";0.5,0.5;increase min humidity;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.2,", ypos, ";0.5,0.5;decrease_humidity_min;-]",
        "tooltip[5.2,", ypos, ";0.5,0.5;decrease min humidity;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.9,", ypos, ";0.5,0.5;reset_humidity_min;x]",
        "tooltip[5.9,", ypos, ";0.5,0.5;reset min humidity;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
    })

    ypos = ypos + 0.7
    formspec = table_concat({ formspec,
        "label[0.3,", ypos + 0.2, ";min relative humidity: ", humidity_max, "%]",

        "button[4.5,", ypos, ";0.5,0.5;increase_humidity_max;+]",
        "tooltip[4.5,", ypos, ";0.5,0.5;increase max humidity;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.2,", ypos, ";0.5,0.5;decrease_humidity_max;-]",
        "tooltip[5.2,", ypos, ";0.5,0.5;decrease max humidity;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.9,", ypos, ";0.5,0.5;reset_humidity_max;x]",
        "tooltip[5.9,", ypos, ";0.5,0.5;reset max humidity;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
    })

    ypos = ypos + 0.7
    formspec = table_concat({ formspec,
        "label[0.3,", ypos + 0.2, ";min wind speed: ", wind_min, " m/s]",

        "button[4.5,", ypos, ";0.5,0.5;increase_wind_min;+]",
        "tooltip[4.5,", ypos, ";0.5,0.5;increase min wind speed;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.2,", ypos, ";0.5,0.5;decrease_wind_min;-]",
        "tooltip[5.2,", ypos, ";0.5,0.5;decrease min wind speed;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.9,", ypos, ";0.5,0.5;reset_wind_min;x]",
        "tooltip[5.9,", ypos, ";0.5,0.5;reset min wind speed;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
    })

    ypos = ypos + 0.7
    formspec = table_concat({ formspec,
        "label[0.3,", ypos + 0.2, ";max wind speed: ", wind_max, " m/s]",

        "button[4.5,", ypos, ";0.5,0.5;increase_wind_max;+]",
        "tooltip[4.5,", ypos, ";0.5,0.5;increase max wind speed;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.2,", ypos, ";0.5,0.5;decrease_wind_max;-]",
        "tooltip[5.2,", ypos, ";0.5,0.5;decrease max wind speed;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",

        "button[5.9,", ypos, ";0.5,0.5;reset_wind_max;x]",
        "tooltip[5.9,", ypos, ";0.5,0.5;reset max wind speed;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
    })

    ypos = ypos + 0.7
    formspec = table_concat({ formspec,
        "label[0.3,", ypos + 0.2, ";increment amount]",

        "dropdown[4.5,", ypos, ";1.5,0.5;change_increment;1,2,3,4,5;", increment_index, ";true]",
        "tooltip[4.5,", ypos, ";1.5,0.5;the amount to increase or decrease;",
            TOOLTIP_COLOR_BG, ";", TOOLTIP_COLOR_TEXT, "]",
    })

    return formspec
end


local flag11 = false
core.override_item("ss:weather_wand", {
    stack_max = 0,
    on_use = function(itemstack, user, pointed_thing)
		debug(flag11, "\n## Used WEATHER Wand (LMB) ##")

        local controls = user:get_player_control()
        if controls.aux1 then

            local player_name = user:get_player_name()
            local p_data = ss.player_data[player_name]
            p_data.formspec_mode = "weather_wand"
            p_data.active_tab = "weather_wand"

            local formspec = get_fs_weather_wand(p_data.biome_name, 3)
            mt_show_formspec(player_name, "ss:ui_weather_wand", formspec)
            player_control_fix(user)

        else
            debug(flag11, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)
        end
	end,

    on_secondary_use = function(itemstack, user, pointed_thing)
        debug(flag11, "\n## Used WEATHER Wand (RMB) ##")


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
    table_insert(teleport_data, {biome_name = current_biome_name})
    debug(flag4, "    teleport_data: " .. dump(teleport_data))

    debug(flag4, "  get_teleport_data() END")
    return teleport_data
end

local function get_fs_teleporter(teleport_data)
    local formspec = table_concat({
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
core.override_item("ss:teleporter", {
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
            mt_show_formspec(player_name, "ss:ui_teleporter", formspec)
            player_control_fix(user)
            debug(flag3, "on_use() END")
        else
            debug(flag3, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)
        end

    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        debug(flag3, "\non_secondary_use()")
        debug(flag3, "\non_secondary_use()")
    end
})




local function get_all_sounds()
    local sounds_set = {}
    for _, modname in ipairs(core.get_modnames()) do
        local modpath = core.get_modpath(modname)
        if modpath then
            local sounds_dir = modpath.."/sounds"
            local files = core.get_dir_list(sounds_dir, false)
            for _, filename in ipairs(files or {}) do
                -- Only match .ogg, and strip .<number> if present
                local base = filename:match("^(.-)%.[0-9]+%.ogg$") or
                             filename:gsub("%.ogg$", "")
                sounds_set[base] = true
            end
        end
    end
    local sounds = {}
    for base, _ in pairs(sounds_set) do
        table.insert(sounds, base)
    end
    table.sort(sounds)
    return sounds
end


local all_sounds = get_all_sounds()

local function get_fs_sound_wand()
    local formspec = table_concat({
        "formspec_version[7]size[9.0,14.0]position[0.5,0.45]",
        "label[3.2,0.5;Test Sounds]",

        "label[0.6,2.0;sound]",
        "dropdown[2.5,1.5;5;selected_sound;" .. table.concat(all_sounds, ",") .. ";1]",

        "label[0.6,3.5;gain]",
        "dropdown[2.5,3.0;5;selected_gain;0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1;10]",

        "label[0.6,5.0;pitch]",
        "dropdown[2.5,4.5;5;selected_pitch;0.25,0.5,0.75,1,1.25,1.5,1.75,2,2.25,2.5;4]",

        "label[0.6,6.5;fade]",
        "dropdown[2.5,6.0;5;selected_fade;0,0.01,0.05,0.1,0.2,0.33,0.5;1]",

        "label[0.6,8.0;loop]",
        "dropdown[2.5,7.5;5;selected_loop;false,true;1]",

        "button[0.5,9;3,1;play_sound;Play Sound]",
        "button[4.0,9;3,1;stop_sound;Stop Sound]",
    })
    return formspec
end

local sound_data = {}

local flag14 = false
local function stop_current_sound(player_name)
    debug(flag14, "  stop_current_sound()")
    local data = sound_data[player_name]
    if data then
        debug(flag14, "    existing sound playing: " .. data[1])
        core.sound_stop(data[2])
        sound_data[player_name] = nil
        debug(flag14, "    sound stopped")
    else
        debug(flag14, "    no existing sound playing")
    end
    debug(flag14, "  stop_current_sound() END")
end



local flag6 = false
core.override_item("ss:sound_wand", {
    on_use = function(itemstack, user, pointed_thing)
        debug(flag6, "\non_use() ADMIN_ITEMS")

        local controls = user:get_player_control()
        if controls.aux1 then
            local player_name = user:get_player_name()
            local p_data = ss.player_data[player_name]
            p_data.formspec_mode = "sound_wand"
            p_data.active_tab = "sound_wand"

            local formspec = get_fs_sound_wand()
            mt_show_formspec(player_name, "ss:ui_sound_wand", formspec)
            player_control_fix(user)
            debug(flag6, "on_use() END")
        else
            debug(flag6, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)
        end

    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        debug(flag6, "\non_secondary_use()")
        debug(flag6, "\non_secondary_use()")
    end
})







-- #################################
-- ########## DEBUG WAND ###########
-- #################################

local function initialize_debug_huds(player, player_name)
    player_hud_ids[player_name].debug_display_0 = player:hud_add({
        type = "image",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        scale = {x = -100, y = -100},
        text = "[fill:1x1:0,0:#00000080",
    })

    -- player stat names
    player_hud_ids[player_name].debug_display_1 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 0, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- player stat current values
    player_hud_ids[player_name].debug_display_2 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 100, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- player stat current ratios
    player_hud_ids[player_name].debug_display_3 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 160, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- player stat baseline values
    player_hud_ids[player_name].debug_display_4 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 240, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- player stat baseline change rates
    player_hud_ids[player_name].debug_display_5 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 285, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- player stat max values
    player_hud_ids[player_name].debug_display_6 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 425, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- baseline modifiers for health stat
    player_hud_ids[player_name].debug_display_7 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 480, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- baseline modifiers for comfort stat
    player_hud_ids[player_name].debug_display_8 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 700, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- baseline modifiers for immunity stat
    player_hud_ids[player_name].debug_display_9 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 900, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- baseline modifiers for sanity stat
    player_hud_ids[player_name].debug_display_10 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 900, y = 150},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- baseline modifiers for happiness stat
    player_hud_ids[player_name].debug_display_11 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 480, y = 225},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- health recovery trackers
    player_hud_ids[player_name].debug_display_12 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 1100, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- sneeze, cough, and vomit timers
    player_hud_ids[player_name].debug_display_13 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 1100, y = 150},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- legs damage total
    player_hud_ids[player_name].debug_display_14 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 0, y = 320},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- show player physics properties: speed and jump
    player_hud_ids[player_name].debug_display_15 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 900, y = 240},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- hands injury mods
    player_hud_ids[player_name].debug_display_16 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 220, y = 320},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- legs injury mods
    player_hud_ids[player_name].debug_display_17 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 460, y = 320},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- modifier values triggered by subskills
    player_hud_ids[player_name].debug_display_18 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 1280, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- speed and speed buffs
    player_hud_ids[player_name].debug_display_19 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 1100, y = 220},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- current animation state
    player_hud_ids[player_name].debug_display_20 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 1550, y = 0},
        text = "",
        number = "0xffffff",
        style = 1
    })

    -- unused
    player_hud_ids[player_name].debug_display_21 = player:hud_add({
        type = "text",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        offset = {x = 1550, y = 90},
        text = "",
        number = "0xffffff",
        style = 1
    })

end



local function refresh_debug_display(player, player_name, p_data, player_meta)
    after_player_check(player)

    local hud_id, debug_info
    local physics = player:get_physics_override()

    -- player stat names
    debug_info = table_concat({
        "health:\n",
        "thirst:\n",
        "hunger:\n",
        "alertness:\n",
        "hygiene:\n",
        "comfort:\n",
        "immunity:\n",
        "sanity:\n",
        "happiness:\n",
        "breath:\n",
        "stamina:\n",
        "weight:\n",
        "legs:\n",
        "hands:\n",
        "illness:\n",
        "poison:\n",
        "wetness:\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_1
    player:hud_change(hud_id, "text", debug_info)

    -- player stat current values
    debug_info = table_concat({
        round(player_meta:get_float("health_current"), 2), "\n",
        round(player_meta:get_float("thirst_current"), 2), "\n",
        round(player_meta:get_float("hunger_current"), 2), "\n",
        round(player_meta:get_float("alertness_current"), 2), "\n",
        round(player_meta:get_float("hygiene_current"), 2), "\n",
        round(player_meta:get_float("comfort_current"), 2), "\n",
        round(player_meta:get_float("immunity_current"), 2), "\n",
        round(player_meta:get_float("sanity_current"), 2), "\n",
        round(player_meta:get_float("happiness_current"), 2), "\n",
        round(player_meta:get_float("breath_current"), 2), "\n",
        round(player_meta:get_float("stamina_current"), 2), "\n",
        round(player_meta:get_float("weight_current"), 2), "\n",
        round(player_meta:get_float("legs_current"), 2), "\n",
        round(player_meta:get_float("hands_current"), 2), "\n",
        round(player_meta:get_float("illness_current"), 2), "\n",
        round(player_meta:get_float("poison_current"), 2), "\n",
        round(player_meta:get_float("wetness_current"), 2), "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_2
    player:hud_change(hud_id, "text", debug_info)

    -- player stat current ratios
    debug_info = table_concat({
        round(p_data.health_ratio * 100, 2), "%\n",
        round(p_data.thirst_ratio * 100, 2), "%\n",
        round(p_data.hunger_ratio * 100, 2), "%\n",
        round(p_data.alertness_ratio * 100, 2), "%\n",
        round(p_data.hygiene_ratio * 100, 2), "%\n",
        round(p_data.comfort_ratio * 100, 2), "%\n",
        round(p_data.immunity_ratio * 100, 2), "%\n",
        round(p_data.sanity_ratio * 100, 2), "%\n",
        round(p_data.happiness_ratio * 100, 2), "%\n",
        round(p_data.breath_ratio * 100, 2), "%\n",
        round(p_data.stamina_ratio * 100, 2), "%\n",
        round(p_data.weight_ratio * 100, 2), "%\n",
        round(p_data.legs_ratio * 100, 2), "%\n",
        round(p_data.hands_ratio * 100, 2), "%\n",
        round(p_data.illness_ratio * 100, 2), "%\n",
        round(p_data.poison_ratio * 100, 2), "%\n",
        round(p_data.wetness_ratio * 100, 2), "%\n",

    })
    hud_id = player_hud_ids[player_name].debug_display_3
    player:hud_change(hud_id, "text", debug_info)

    -- player stat baseline values
    debug_info = table_concat({
        round(p_data.base_value_health, 2), "\n",
        round(p_data.base_value_thirst, 2), "\n",
        round(p_data.base_value_hunger, 2), "\n",
        round(p_data.base_value_alertness, 2), "\n",
        round(p_data.base_value_hygiene, 2), "\n",
        round(p_data.base_value_comfort, 2), "\n",
        round(p_data.base_value_immunity, 2), "\n",
        round(p_data.base_value_sanity, 2), "\n",
        round(p_data.base_value_happiness, 2), "\n",
        "--\n",
        "--\n",
        "--\n",
        round(p_data.base_value_legs, 2), "\n",
        round(p_data.base_value_hands, 2), "\n",
        round(p_data.base_value_illness, 2), "\n",
        round(p_data.base_value_poison, 2), "\n",
        "--\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_4
    player:hud_change(hud_id, "text", debug_info)

    -- player stat baseline change rates
    debug_info = table_concat({
        "+", round(p_data.recovery_speed_health, 4), " -", round(p_data.drain_speed_health, 4), "\n",
        "+", round(p_data.recovery_speed_thirst, 4), " -", round(p_data.drain_speed_thirst, 4), "\n",
        "+", round(p_data.recovery_speed_hunger, 4), " -", round(p_data.drain_speed_hunger, 4), "\n",
        "+", round(p_data.recovery_speed_alertness, 4), " -", round(p_data.drain_speed_alertness, 4), "\n",
        "+", round(p_data.recovery_speed_hygiene, 4), " -", round(p_data.drain_speed_hygiene, 4), "\n",
        "+", round(p_data.recovery_speed_comfort, 4), " -", round(p_data.drain_speed_comfort, 4), "\n",
        "+", round(p_data.recovery_speed_immunity, 4), " -", round(p_data.drain_speed_immunity, 4), "\n",
        "+", round(p_data.recovery_speed_sanity, 4), " -", round(p_data.drain_speed_sanity, 4), "\n",
        "+", round(p_data.recovery_speed_happiness, 4), " -", round(p_data.drain_speed_happiness, 4), "\n",
        "--\n",
        "--\n",
        "--\n",
        "+", round(p_data.recovery_speed_legs, 4), " -", round(p_data.drain_speed_legs, 4), "\n",
        "+", round(p_data.recovery_speed_hands, 4), " -", round(p_data.drain_speed_hands, 4), "\n",
        "+", round(p_data.recovery_speed_illness, 4), " -", round(p_data.drain_speed_illness, 4), "\n",
        "+", round(p_data.recovery_speed_poison, 4), " -", round(p_data.drain_speed_poison, 4), "\n",
        "--\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_5
    player:hud_change(hud_id, "text", debug_info)

    -- player stat max values
    debug_info = table_concat({
        round(player_meta:get_float("health_max"), 2), "\n",
        round(player_meta:get_float("thirst_max"), 2), "\n",
        round(player_meta:get_float("hunger_max"), 2), "\n",
        round(player_meta:get_float("alertness_max"), 2), "\n",
        round(player_meta:get_float("hygiene_max"), 2), "\n",
        round(player_meta:get_float("comfort_max"), 2), "\n",
        round(player_meta:get_float("immunity_max"), 2), "\n",
        round(player_meta:get_float("sanity_max"), 2), "\n",
        round(player_meta:get_float("happiness_max"), 2), "\n",
        round(player_meta:get_float("breath_max"), 2), "\n",
        round(player_meta:get_float("stamina_max"), 2), "\n",
        round(player_meta:get_float("weight_max"), 2), "\n",
        round(player_meta:get_float("legs_max"), 2), "\n",
        round(player_meta:get_float("hands_max"), 2), "\n",
        round(player_meta:get_float("illness_max"), 2), "\n",
        round(player_meta:get_float("poison_max"), 2), "\n",
        round(player_meta:get_float("wetness_max"), 2), "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_6
    player:hud_change(hud_id, "text", debug_info)

    -- baseline modifiers for health stat
    debug_info = table_concat({
        "base value health: ", round(p_data.base_value_health, 2), "\n",
        "thirst: ", p_data.base_health_mod_thirst, "\n",
        "hunger: ", p_data.base_health_mod_hunger, "\n",
        "alertness: ", p_data.base_health_mod_alertness, "\n",
        "immunity: ", p_data.base_health_mod_immunity, "\n",
        "hot:  ", p_data.base_health_mod_hot, "\n",
        "cold: ", p_data.base_health_mod_cold, "\n",
        "illness: ", p_data.base_health_mod_illness, "\n",
        "poison: ", p_data.base_health_mod_poison, "\n",
        "legs: ", p_data.base_health_mod_legs, "\n",
        "hands: ", p_data.base_health_mod_hands, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_7
    player:hud_change(hud_id, "text", debug_info)

    -- baseline modifiers for comfort stat
    debug_info = table_concat({
        "base val Comfort: ", round(p_data.base_value_comfort, 2), "\n",
        "health: ", p_data.base_comfort_mod_health, "\n",
        "thirst: ", p_data.base_comfort_mod_thirst, "\n",
        "hunger: ", p_data.base_comfort_mod_hunger, "\n",
        "hygiene: ", p_data.base_comfort_mod_hygiene, "\n",
        "breath: ", p_data.base_comfort_mod_breath, "\n",
        "stamina: ", p_data.base_comfort_mod_stamina, "\n",
        "weight: ", p_data.base_comfort_mod_weight, "\n",
        "hot: ", p_data.base_comfort_mod_hot, "\n",
        "cold: ", p_data.base_comfort_mod_cold, "\n",
        "illness: ", p_data.base_comfort_mod_illness, "\n",
        "poison: ", p_data.base_comfort_mod_poison, "\n",
        "legs: ", p_data.base_comfort_mod_legs, "\n",
        "hands: ", p_data.base_comfort_mod_hands, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_8
    player:hud_change(hud_id, "text", debug_info)

    -- baseline modifiers for immunity stat
    debug_info = table_concat({
        "base val Immunity: ", round(p_data.base_value_immunity, 2), "\n",
        "thirst: ", p_data.base_immunity_mod_thirst, "\n",
        "hunger: ", p_data.base_immunity_mod_hunger, "\n",
        "alertness: ", p_data.base_immunity_mod_alertness, "\n",
        "hygiene: ", p_data.base_immunity_mod_hygiene, "\n",
        "happiness: ", p_data.base_immunity_mod_happiness, "\n",
        "cold: ", p_data.base_immunity_mod_cold, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_9
    player:hud_change(hud_id, "text", debug_info)

    -- baseline modifiers for sanity stat
    debug_info = table_concat({
        "base val Sanity: ", round(p_data.base_value_sanity, 2), "\n",
        "health: ", p_data.base_sanity_mod_health, "\n",
        "alertness: ", p_data.base_sanity_mod_alertness, "\n",
        "breath: ", p_data.base_sanity_mod_breath, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_10
    player:hud_change(hud_id, "text", debug_info)

    -- baseline modifiers for happiness stat
    debug_info = table_concat({
        "base val Happiness: ", round(p_data.base_value_happiness, 2), "\n",
        "alertness: ", p_data.base_happiness_mod_alertness, "\n",
        "comfort: ", p_data.base_happiness_mod_comfort, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_11
    player:hud_change(hud_id, "text", debug_info)

    -- health recovery trackers
    debug_info = table_concat({
        "health rec thirst: ", p_data.health_rec_from_thirst, "\n",
        "health rec hunger: ", p_data.health_rec_from_hunger, "\n",
        "health rec breath: ", p_data.health_rec_from_breath, "\n",
        "health rec hot: ", p_data.health_rec_from_hot, "\n",
        "health rec cold: ", p_data.health_rec_from_cold, "\n",
        "health rec illness: ", p_data.health_rec_from_illness, "\n",
        "health rec poison: ", p_data.health_rec_from_poison, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_12
    player:hud_change(hud_id, "text", debug_info)

    -- sneeze, cough, and vomit timers
    debug_info = table_concat({
        "sneeze timer: ", round(p_data.sneeze_timer, 2), "\n",
        "cough  timer: ", round(p_data.cough_timer, 2), "\n",
        "vomit  timer: ", round(p_data.vomit_timer, 2), "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_13
    player:hud_change(hud_id, "text", debug_info)

    -- legs damage total
    debug_info = table_concat({
        "legs_damage_total: ", p_data.legs_damage_total, "\n",
        "hands_damage_total: ", p_data.hands_damage_total, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_14
    player:hud_change(hud_id, "text", debug_info)

    -- jump and jump buffs
    debug_info = table_concat({
        "JUMP FINAL: ", round(physics.jump, 2), "\n",
        "curr speed: ", p_data.jump_height_current, "\n",
        "weight: ", p_data.jump_buff_weight, "\n",
        "crouch: ", p_data.jump_buff_crouch, "\n",
        "run: ", p_data.jump_buff_run, "\n",
        "exhaustion: ", p_data.jump_buff_exhaustion, "\n",
        "illness: ", p_data.jump_buff_illness, "\n",
        "poison: ", p_data.jump_buff_poison, "\n",
        "vomit: ", p_data.jump_buff_vomit, "\n",
        "sneeze: ", p_data.jump_buff_sneeze, "\n",
        "cough: ", p_data.jump_buff_cough, "\n",
        "legs: ", p_data.jump_buff_legs, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_15
    player:hud_change(hud_id, "text", debug_info)

    -- hands injury mods
    debug_info = table_concat({
        "hand_injury_mod_glove: ", p_data.hand_injury_mod_glove, "\n",
        "hand_injury_mod_skill: ", p_data.hand_injury_mod_skill, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_16
    player:hud_change(hud_id, "text", debug_info)

    -- legs injury mods
    debug_info = table_concat({
        "fall_health_modifier: ", p_data.fall_health_modifier, "\n",
        "leg_injury_mod_foot_clothing: ", p_data.leg_injury_mod_foot_clothing, "\n",
        "leg_injury_mod_foot_armor: ", p_data.leg_injury_mod_foot_armor, "\n",
        "leg_injury_mod_skill: ", p_data.leg_injury_mod_skill, "\n",
        "leg_injury_mod_water: ", p_data.leg_injury_mod_water, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_17
    player:hud_change(hud_id, "text", debug_info)

    -- modifier values triggered by subskills
    debug_info = table_concat({
        "stam rec fast_charger: ", p_data.stamina_rec_mod_fast_charger, "\n",
        "stam rec mod hot: ", p_data.stamina_rec_mod_hot, "\n",
        "stam rec mod cold: ", p_data.stamina_rec_mod_cold, "\n",
        "stam rec mod illness: ", p_data.stamina_rec_mod_illness, "\n",
        "stam rec mod poison: ", p_data.stamina_rec_mod_poison, "\n",
        "\n",
        "hp drain thudmuffin: ", p_data.health_drain_mod_thudmuffin, "\n",
        "hp drain sipless_survivor: ", p_data.health_drain_mod_sipless_survivor, "\n",
        "hp drain foodless_freak: ", p_data.health_drain_mod_foodless_freak, "\n",
        "hp drain smotherproof: ", p_data.health_drain_mod_smotherproof, "\n",
        "hp drain stage4_nope: ", p_data.health_drain_mod_stage4_nope, "\n",
        "hp drain dinner_death_dodger: ", p_data.health_drain_mod_dinner_death_dodger, "\n",
        "hp drain freezeproof: ", p_data.health_drain_mod_freezeproof, "\n",
        "hp drain scorchproof: ", p_data.health_drain_mod_scorchproof, "\n",
        "\n",
        "stam drain burnout_blocker: ", p_data.stamina_drain_mod_burnout_blocker, "\n",
        "brea drain deep_diver: ", p_data.breath_drain_mod_deep_diver, "\n",
        "brea rec oxygenator: ", p_data.breath_rec_mod_oxygenator, "\n",
        "ill drain sniffle_shield: ", p_data.illness_drain_mod_sniffle_shield, "\n",
        "pois drain toxintanium: ", p_data.poison_drain_mod_toxintanium, "\n",
        "leg drain shin_credible: ", p_data.leg_drain_mod_shin_credible, "\n",
        "leg drain knuckle_saurus: ", p_data.hand_drain_mod_knuckle_saurus, "\n",
        "xp gain fast_learner: ", p_data.experience_rec_mod_fast_learner, "\n",
        "weight forearm_freak: ", p_data.weight_mod_forearm_freak, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_18
    player:hud_change(hud_id, "text", debug_info)

    -- modifier values triggered by subskills (part 2)
    debug_info = table_concat({
        "speed mod speed_walker: ", p_data.speed_mod_speed_walker, "\n",
        "speed mod sprinter: ", p_data.speed_mod_sprinter, "\n",
        "speed mod creeper: ", p_data.speed_mod_creeper, "\n",
        "speed mod cargo_tank: ", p_data.speed_mod_cargo_tank, "\n",
        "jump mod launchitude: ", p_data.jump_mod_launchitude, "\n",
        "jump mod bulk_bouncer: ", p_data.jump_mod_bulk_bouncer, "\n",
        "temp mod coolossus: ", p_data.temperature_mod_coolossus, "\n",
        "temp mod crispy_crusader: ", p_data.temperature_mod_crispy_crusader, "\n",
        "noise mod unchokeable: ", p_data.noise_mod_unchokeable, "\n",
        "noise mod booger_barrier: ", p_data.noise_mod_booger_barrier, "\n",
        "noise mod unhiccable: ", p_data.noise_mod_unhiccable, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_21
    player:hud_change(hud_id, "text", debug_info)

    -- speed and speed buffs
    debug_info = table_concat({
        "SPEED FINAL: ", round(physics.speed, 2), "\n",
        "curr speed: ", p_data.speed_walk_current, "\n",
        "weight: ", p_data.speed_buff_weight, "\n",
        "crouch: ", p_data.speed_buff_crouch, "\n",
        "run: ", p_data.speed_buff_run, "\n",
        "exhaustion: ", p_data.speed_buff_exhaustion, "\n",
        "illness: ", p_data.speed_buff_illness, "\n",
        "poison: ", p_data.speed_buff_poison, "\n",
        "vomit: ", p_data.speed_buff_vomit, "\n",
        "sneeze: ", p_data.speed_buff_sneeze, "\n",
        "cough: ", p_data.speed_buff_cough, "\n",
        "legs: ", p_data.speed_buff_legs, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_19
    player:hud_change(hud_id, "text", debug_info)

    -- current aniimation state and moisture related mods
    debug_info = table_concat({
        "curr anim state: ", p_data.current_anim_state, "\n",
        "water_level: ", dump(p_data.water_level), "\n",
        "equipment_count: ", p_data.equipment_count, "\n",
        "wetness_drain_mod_equip: ", p_data.wetness_drain_mod_equip, "\n",
    })
    hud_id = player_hud_ids[player_name].debug_display_20
    player:hud_change(hud_id, "text", debug_info)

    local job_handle = mt_after(0.5, refresh_debug_display, player, player_name, p_data, player_meta)
    job_handles[player_name].refresh_debug_display = job_handle

end



local flag7 = false
core.override_item("ss:debug_wand", {
    on_use = function(itemstack, user, pointed_thing)
        debug(flag7, "\non_use() admin_items.lua")

        local controls = user:get_player_control()
        if controls.aux1 then
            local player_name = user:get_player_name()
            local p_data = ss.player_data[player_name]

            -- show debug info
            if p_data.is_debug_on == 0 then
                p_data.is_debug_on = 1
                initialize_debug_huds(user, player_name)
                refresh_debug_display(user, player_name, p_data, user:get_meta())

            -- hide debug info
            else
                p_data.is_debug_on = 0
                for i = 0, 21 do
                    local hud_id = player_hud_ids[player_name]["debug_display_" .. i]
                    user:hud_remove(hud_id)
                end

                local job_handle = job_handles[player_name].refresh_debug_display
                job_handle:cancel()
            end

            debug(flag7, "on_use() END")
        else
            debug(flag7, "  swinging item as a generic craftitem..")
            pickup_item(user, pointed_thing)
            debug(flag7, "on_use() END")
        end

    end,
    on_secondary_use = function(itemstack, user, pointed_thing)
        debug(flag7, "\non_secondary_use() admin_items.lua")



        debug(flag7, "\non_secondary_use() END")
    end
})



-- #################################
-- ########## SCREWDRIVER ##########
-- #################################

core.override_item("ss:screwdriver", {
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



local flag2 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag2, "\nregister_on_player_receive_fields() admin_items.lua")
	debug(flag2, "  fields: " .. dump(fields))

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
            or p_data.active_tab == "weather_wand"
            or p_data.active_tab == "teleporter" then
            p_data.formspec_mode = "main_formspec"
            p_data.active_tab = "main"
        end
        debug(flag2, "register_on_player_receive_fields() end")
        return

    elseif formspec_mode == "stats_wand" then
        debug(flag2, "  used STATS WAND")
        play_sound("button", {player_name = player_name})
        if fields.increase_health then
            if fields.change_type_health == "curr" then
                debug(flag2, "  increasing current health")
                set_stat_current(player, p_data, fields, "health", "up")
            else
                debug(flag2, "  increasing max health")
                set_stat_max(player, p_data, fields, "health", "up")
            end
        elseif fields.decrease_health then
            if fields.change_type_health == "curr" then
                debug(flag2, "  decreasing health")
                set_stat_current(player, p_data, fields, "health", "down")
            else
                debug(flag2, "  decreasing max health")
                set_stat_max(player, p_data, fields, "health", "down")
            end

        elseif fields.increase_thirst then
            if fields.change_type_thirst == "curr" then
                debug(flag2, "  increase thirst")
                set_stat_current(player, p_data, fields, "thirst", "up")
            else
                debug(flag2, "  increasing max thirst")
                set_stat_max(player, p_data, fields, "thirst", "up")
            end
        elseif fields.decrease_thirst then
            if fields.change_type_thirst == "curr" then
                debug(flag2, "  decreasing thirst")
                set_stat_current(player, p_data, fields, "thirst", "down")
            else
                debug(flag2, "  decreasing max thirst")
                set_stat_max(player, p_data, fields, "thirst", "down")
            end

        elseif fields.increase_hunger then
            if fields.change_type_hunger == "curr" then
                debug(flag2, "  increase hunger")
                set_stat_current(player, p_data, fields, "hunger", "up")
            else
                debug(flag2, "  increasing max hunger")
                set_stat_max(player, p_data, fields, "hunger", "up")
            end
        elseif fields.decrease_hunger then
            if fields.change_type_hunger == "curr" then
                debug(flag2, "  decreasing hunger")
                set_stat_current(player, p_data, fields, "hunger", "down")
            else
                debug(flag2, "  decreasing max hunger")
                set_stat_max(player, p_data, fields, "hunger", "down")
            end

        elseif fields.increase_immunity then
            if fields.change_type_immunity == "curr" then
                debug(flag2, "  increase immunity")
                set_stat_current(player, p_data, fields, "immunity", "up")
            else
                debug(flag2, "  increasing max immunity")
                set_stat_max(player, p_data, fields, "immunity", "up")
            end
        elseif fields.decrease_immunity then
            if fields.change_type_immunity == "curr" then
                debug(flag2, "  decreasing immunity")
                set_stat_current(player, p_data, fields, "immunity", "down")
            else
                debug(flag2, "  decreasing max immunity")
                set_stat_max(player, p_data, fields, "immunity", "down")
            end

        elseif fields.increase_alertness then
            if fields.change_type_alertness == "curr" then
                debug(flag2, "  increase alertness")
                set_stat_current(player, p_data, fields, "alertness", "up")
            else
                debug(flag2, "  increasing max alertness")
                set_stat_max(player, p_data, fields, "alertness", "up")
            end
        elseif fields.decrease_alertness then
            if fields.change_type_alertness == "curr" then
                debug(flag2, "  decreasing alertness")
                set_stat_current(player, p_data, fields, "alertness", "down")
            else
                debug(flag2, "  decreasing max alertness")
                set_stat_max(player, p_data, fields, "alertness", "down")
            end

        elseif fields.increase_sanity then
            if fields.change_type_sanity == "curr" then
                debug(flag2, "  increase sanity")
                set_stat_current(player, p_data, fields, "sanity", "up")
            else
                debug(flag2, "  increasing max sanity")
                set_stat_max(player, p_data, fields, "sanity", "up")
            end
        elseif fields.decrease_sanity then
            if fields.change_type_sanity == "curr" then
                debug(flag2, "  decreasing sanity")
                set_stat_current(player, p_data, fields, "sanity", "down")
            else
                debug(flag2, "  decreasing max sanity")
                set_stat_max(player, p_data, fields, "sanity", "down")
            end

        elseif fields.increase_hygiene then
            if fields.change_type_hygiene == "curr" then
                debug(flag2, "  increase hygiene")
                set_stat_current(player, p_data, fields, "hygiene", "up")
            else
                debug(flag2, "  increasing max hygiene")
                set_stat_max(player, p_data, fields, "hygiene", "up")
            end
        elseif fields.decrease_hygiene then
            if fields.change_type_hygiene == "curr" then
                debug(flag2, "  decreasing hygiene")
                set_stat_current(player, p_data, fields, "hygiene", "down")
            else
                debug(flag2, "  decreasing max hygiene")
                set_stat_max(player, p_data, fields, "hygiene", "down")
            end

        elseif fields.increase_comfort then
            if fields.change_type_comfort == "curr" then
                debug(flag2, "  increase comfort")
                set_stat_current(player, p_data, fields, "comfort", "up")
            else
                debug(flag2, "  increasing max comfort")
                set_stat_max(player, p_data, fields, "comfort", "up")
            end
        elseif fields.decrease_comfort then
            if fields.change_type_comfort == "curr" then
                debug(flag2, "  decreasing comfort")
                set_stat_current(player, p_data, fields, "comfort", "down")
            else
                debug(flag2, "  decreasing max comfort")
                set_stat_max(player, p_data, fields, "comfort", "down")
            end

        elseif fields.increase_happiness then
            if fields.change_type_happiness == "curr" then
                debug(flag2, "  increase happiness")
                set_stat_current(player, p_data, fields, "happiness", "up")
            else
                debug(flag2, "  increasing max happiness")
                set_stat_max(player, p_data, fields, "happiness", "up")
            end
        elseif fields.decrease_happiness then
            if fields.change_type_happiness == "curr" then
                debug(flag2, "  decreasing happiness")
                set_stat_current(player, p_data, fields, "happiness", "down")
            else
                debug(flag2, "  decreasing max happiness")
                set_stat_max(player, p_data, fields, "happiness", "down")
            end

        elseif fields.increase_breath then
            if fields.change_type_breath == "curr" then
                debug(flag2, "  increase breath")
                set_stat_current(player, p_data, fields, "breath", "up")
            else
                debug(flag2, "  increasing max breath")
                set_stat_max(player, p_data, fields, "breath", "up")
            end
        elseif fields.decrease_breath then
            if fields.change_type_breath == "curr" then
                debug(flag2, "  decreasing breath")
                set_stat_current(player, p_data, fields, "breath", "down")
            else
                debug(flag2, "  decreasing max breath")
                set_stat_max(player, p_data, fields, "breath", "down")
            end

        elseif fields.increase_stamina then
            if fields.change_type_stamina == "curr" then
                debug(flag2, "  increase stamina")
                set_stat_current(player, p_data, fields, "stamina", "up")
            else
                debug(flag2, "  increasing max stamina")
                set_stat_max(player, p_data, fields, "stamina", "up")
            end
        elseif fields.decrease_stamina then
            if fields.change_type_stamina == "curr" then
                debug(flag2, "  decreasing stamina")
                set_stat_current(player, p_data, fields, "stamina", "down")
            else
                debug(flag2, "  decreasing max stamina")
                set_stat_max(player, p_data, fields, "stamina", "down")
            end

        elseif fields.increase_experience then
            if fields.change_type_experience == "curr" then
                debug(flag2, "  increase experience")
                set_stat_current(player, p_data, fields, "experience", "up")
            else
                debug(flag2, "  increasing max experience")
                set_stat_max(player, p_data, fields, "experience", "up")
            end
        elseif fields.decrease_experience then
            if fields.change_type_experience == "curr" then
                debug(flag2, "  decreasing experience")
                set_stat_current(player, p_data, fields, "experience", "down")
            else
                debug(flag2, "  decreasing max experience")
                set_stat_max(player, p_data, fields, "experience", "down")
            end

        elseif fields.increase_legs then
            if fields.change_type_legs == "curr" then
                debug(flag2, "  increase legs")
                set_stat_current(player, p_data, fields, "legs", "up")
            else
                debug(flag2, "  increasing max legs")
                set_stat_max(player, p_data, fields, "legs", "up")
            end
        elseif fields.decrease_legs then
            if fields.change_type_legs == "curr" then
                debug(flag2, "  decreasing legs")
                set_stat_current(player, p_data, fields, "legs", "down")
            else
                debug(flag2, "  decreasing max legs")
                set_stat_max(player, p_data, fields, "legs", "down")
            end

        elseif fields.increase_hands then
            if fields.change_type_hands == "curr" then
                debug(flag2, "  increase hands")
                set_stat_current(player, p_data, fields, "hands", "up")
            else
                debug(flag2, "  increasing max hands")
                set_stat_max(player, p_data, fields, "hands", "up")
            end
        elseif fields.decrease_hands then
            if fields.change_type_hands == "curr" then
                debug(flag2, "  decreasing hands")
                set_stat_current(player, p_data, fields, "hands", "down")
            else
                debug(flag2, "  decreasing max hands")
                set_stat_max(player, p_data, fields, "hands", "down")
            end

        elseif fields.increase_illness then
            if fields.change_type_illness == "curr" then
                debug(flag2, "  increase illness")
                set_stat_current(player, p_data, fields, "illness", "up")
            else
                debug(flag2, "  increasing max illness")
                set_stat_max(player, p_data, fields, "illness", "up")
            end
        elseif fields.decrease_illness then
            if fields.change_type_illness == "curr" then
                debug(flag2, "  decreasing illness")
                set_stat_current(player, p_data, fields, "illness", "down")
            else
                debug(flag2, "  decreasing max illness")
                set_stat_max(player, p_data, fields, "illness", "down")
            end

        elseif fields.increase_poison then
            if fields.change_type_poison == "curr" then
                debug(flag2, "  increase poison")
                set_stat_current(player, p_data, fields, "poison", "up")
            else
                debug(flag2, "  increasing max poison")
                set_stat_max(player, p_data, fields, "poison", "up")
            end
        elseif fields.decrease_poison then
            if fields.change_type_poison == "curr" then
                debug(flag2, "  decreasing poison")
                set_stat_current(player, p_data, fields, "poison", "down")
            else
                debug(flag2, "  decreasing max poison")
                set_stat_max(player, p_data, fields, "poison", "down")
            end

        elseif fields.increase_wetness then
            if fields.change_type_wetness == "curr" then
                debug(flag2, "  increase wetness")
                set_stat_current(player, p_data, fields, "wetness", "up")
            else
                debug(flag2, "  increasing max wetness")
                set_stat_max(player, p_data, fields, "wetness", "up")
            end
        elseif fields.decrease_wetness then
            if fields.change_type_wetness == "curr" then
                debug(flag2, "  decreasing wetness")
                set_stat_current(player, p_data, fields, "wetness", "down")
            else
                debug(flag2, "  decreasing max wetness")
                set_stat_max(player, p_data, fields, "wetness", "down")
            end

        elseif fields.increase_weight then
            if fields.change_type_weight == "curr" then
                debug(flag2, "  increase weight")
                fields.speed_type_weight = "instant"
                set_stat_current(player, p_data, fields, "weight", "up")
            else
                debug(flag2, "  increasing max weight")
                set_stat_max(player, p_data, fields, "weight", "up")
            end
            mt_after(1, update_fs_weight, player, player:get_meta())
        elseif fields.decrease_weight then
            if fields.change_type_weight == "curr" then
                debug(flag2, "  decreasing weight")
                fields.speed_type_weight = "instant"
                set_stat_current(player, p_data, fields, "weight", "down")
            else
                debug(flag2, "  decreasing max weight")
                set_stat_max(player, p_data, fields, "weight", "down")
            end
            mt_after(1, update_fs_weight, player, player:get_meta())

        elseif fields.recalc_weight then
            debug(flag2, "  recalculating weight")
            local inventory_weight = get_inventory_weight(player:get_inventory())
            debug(flag2, "  inventory_weight: " .. inventory_weight)
            debug(flag2, "  updating weight stat hud and refresh weight formspec")
            local player_meta = player:get_meta()
            player_meta:set_float("weight_current", 0)
            local update_data = {"normal", "weight", inventory_weight, 1, 1, "curr", "set", true}
            update_stat(player, p_data, player_meta, update_data)
            update_fs_weight(player, player:get_meta())

        else
            debug(flag2, "  Unhandled field value: " .. dump(fields))
        end

    elseif formspec_mode == "weather_wand" then
        debug(flag2, "  used WEATHER WAND")
        play_sound("button", {player_name = player_name})

        if fields.increase_air_temp_min then
            debug(flag2, "  increasing min air temp")
            local increment = fields.change_increment
            update_climate_range("air_temp_min", tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.decrease_air_temp_min then
            debug(flag2, "  decreasing min air temp")
            local increment = fields.change_increment
            update_climate_range("air_temp_min", -tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.reset_air_temp_min then
            debug(flag2, "  resetting min air temp")
            local increment = fields.change_increment
            local biome_data = BIOME_DATA[p_data.biome_name]
            local temp_max = biome_data.temp_max
            local temp_min_default = BIOME_DATA_DEFAULTS[p_data.biome_name].temp_min
            if temp_min_default < temp_max then
                biome_data.temp_min = temp_min_default
                debug(flag2, "  min temp reset to: " .. temp_min_default)
            else
                debug(flag2, "  also setting max temp to " .. (temp_min_default + 1))
                biome_data.temp_max = temp_min_default + 1
                biome_data.temp_min = temp_min_default
            end
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.increase_air_temp_max then
            debug(flag2, "  increasing max air temp")
            local increment = fields.change_increment
            update_climate_range("air_temp_max", tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.decrease_air_temp_max then
            debug(flag2, "  decreasing max air temp")
            local increment = fields.change_increment
            update_climate_range("air_temp_max", -tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.reset_air_temp_max then
            debug(flag2, "  resetting max air temp")
            local increment = fields.change_increment
            local biome_data = BIOME_DATA[p_data.biome_name]
            local temp_min = biome_data.temp_min
            local temp_max_default = BIOME_DATA_DEFAULTS[p_data.biome_name].temp_max
            if temp_max_default > temp_min then
                biome_data.temp_max = temp_max_default
                debug(flag2, "  max temp reset to: " .. temp_max_default)
            else
                debug(flag2, "  also setting min temp to " .. (temp_max_default - 1))
                biome_data.temp_min = temp_max_default - 1
                biome_data.temp_max = temp_max_default
            end
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.increase_humidity_min then
            debug(flag2, "  increasing min humidity")
            local increment = fields.change_increment
            update_climate_range("humidity_min", tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.decrease_humidity_min then
            debug(flag2, "  decreasing min humidity")
            local increment = fields.change_increment
            update_climate_range("humidity_min", -tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.reset_humidity_min then
            debug(flag2, "  resetting min humidity")
            local increment = fields.change_increment
            local biome_data = BIOME_DATA[p_data.biome_name]
            local humidity_max = biome_data.humidity_max
            local humidity_min_default = BIOME_DATA_DEFAULTS[p_data.biome_name].humidity_min
            if humidity_min_default < humidity_max then
                biome_data.humidity_min = humidity_min_default
                debug(flag2, "  min humidity reset to: " .. humidity_min_default)
            else
                debug(flag2, "  also setting max humidity to " .. (humidity_min_default + 1))
                biome_data.humidity_max = humidity_min_default + 1
                biome_data.humidity_min = humidity_min_default
            end
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.increase_humidity_max then
            debug(flag2, "  increasing max humidity")
            local increment = fields.change_increment
            update_climate_range("humidity_max", tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.decrease_humidity_max then
            debug(flag2, "  decreasing max humidity")
            local increment = fields.change_increment
            update_climate_range("humidity_max", -tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.reset_humidity_max then
            debug(flag2, "  resetting max humidity")
            local increment = fields.change_increment
            local biome_data = BIOME_DATA[p_data.biome_name]
            local humidity_min = biome_data.humidity_min
            local humidity_max_default = BIOME_DATA_DEFAULTS[p_data.biome_name].humidity_max
            if humidity_max_default > humidity_min then
                biome_data.humidity_max = humidity_max_default
                debug(flag2, "  max humidity reset to: " .. humidity_max_default)
            else
                debug(flag2, "  also setting min humidity to " .. (humidity_max_default - 1))
                biome_data.humidity_min = humidity_max_default - 1
                biome_data.humidity_max = humidity_max_default
            end
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))


        elseif fields.increase_wind_min then
            debug(flag2, "  increasing min wind speed")
            local increment = fields.change_increment
            update_climate_range("wind_speed_min", tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.decrease_wind_min then
            debug(flag2, "  decreasing min wind speed")
            local increment = fields.change_increment
            update_climate_range("wind_speed_min", -tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.reset_wind_min then
            debug(flag2, "  resetting min wind speed")
            local increment = fields.change_increment
            local biome_data = BIOME_DATA[p_data.biome_name]
            local wind_speed_max = biome_data.wind_speed_max
            local wind_speed_min_default = BIOME_DATA_DEFAULTS[p_data.biome_name].wind_speed_min
            if wind_speed_min_default < wind_speed_max then
                biome_data.wind_speed_min = wind_speed_min_default
                debug(flag2, "  min wind speed reset to: " .. wind_speed_min_default)
            else
                debug(flag2, "  also setting max wind speed to " .. (wind_speed_min_default + 1))
                biome_data.wind_speed_max = wind_speed_min_default + 1
                biome_data.wind_speed_min = wind_speed_min_default
            end
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.increase_wind_max then
            debug(flag2, "  increasing max wind speed")
            local increment = fields.change_increment
            update_climate_range("wind_speed_max", tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.decrease_wind_max then
            debug(flag2, "  decreasing max wind speed")
            local increment = fields.change_increment
            update_climate_range("wind_speed_max", -tonumber(increment), BIOME_DATA[p_data.biome_name])
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))

        elseif fields.reset_wind_max then
            debug(flag2, "  resetting max wind speed")
            local increment = fields.change_increment
            local biome_data = BIOME_DATA[p_data.biome_name]
            local wind_speed_min = biome_data.wind_speed_min
            local wind_speed_max_default = BIOME_DATA_DEFAULTS[p_data.biome_name].wind_speed_max
            if wind_speed_max_default > wind_speed_min then
                biome_data.wind_speed_max = wind_speed_max_default
                debug(flag2, "  max wind speed reset to: " .. wind_speed_max_default)
            else
                debug(flag2, "  also setting min wind speed to " .. (wind_speed_max_default - 1))
                biome_data.wind_speed_min = wind_speed_max_default - 1
                biome_data.wind_speed_max = wind_speed_max_default
            end
            mt_show_formspec(player_name, "ss:ui_weather_wand", get_fs_weather_wand(p_data.biome_name, increment))


        else
            debug(flag2, "  Unhandled field value: " .. dump(fields))
        end


    elseif formspec_mode == "item_spawner" then
        debug(flag2, "  used ITEM SPAWNER")
        play_sound("button", {player_name = player_name})

        -- Handle pagination buttons
        if fields.page_1 then
            if p_data.current_page ~= 1 then
                debug(flag2, "  loading page 1")
                p_data.current_page = 1
                local formspec = generate_item_spawner_formspec(1)
                mt_show_formspec(player_name, "ss:ui_item_spawner", formspec)
            end
            return
        elseif fields.page_2 then
            local page_2_start = 151
            if p_data.current_page ~= 2 and #SS_ITEMS >= page_2_start then
                debug(flag2, "  loading page 2")
                p_data.current_page = 2
                local formspec = generate_item_spawner_formspec(2)
                mt_show_formspec(player_name, "ss:ui_item_spawner", formspec)
            end
            return
        end

        debug(flag2, "  fields: " .. dump(fields))

        --local field_name, value = next(fields)
        local item_name, spawn_quantity
        for key, value in pairs(fields) do
            if key == "dropdown_quantity" then
                spawn_quantity = tonumber(value) or 0
                debug(flag2, "  spawn_quantity: " .. spawn_quantity)
            else
                item_name = key
            end
        end

        if item_name then
            debug(flag2, "  clicked on an item button")
            debug(flag2, "  item_name: " .. item_name)
            local item = ItemStack(item_name .. " " .. spawn_quantity)

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
            core.add_item(pos, item)

        else
            debug(flag2, "  clicked on quantity button")
        end

    elseif formspec_mode == "teleporter" then
        debug(flag2, "  used TELEPORTER")
        debug(flag2, "  fields: " .. dump(fields))
        play_sound("button", {player_name = player_name})

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
        mt_show_formspec(player_name, "ss:ui_teleporter", formspec)
        player_control_fix(player)

    elseif formspec_mode == "sound_wand" then
        debug(flag2, "  used SOUND WAND")

        if fields.play_sound then
            debug(flag2, "  playing sound..")
            debug(flag2, "  sound_data (before): " .. dump(sound_data))
            stop_current_sound(player_name)

            local filename = fields.selected_sound
            local gain = tonumber(fields.selected_gain)
            local pitch = tonumber(fields.selected_pitch)
            local fade = tonumber(fields.selected_fade)
            local loop = fields.selected_loop

            debug(flag2, "  filename: " .. filename)
            debug(flag2, "  gain: " .. gain)
            debug(flag2, "  pitch: " .. pitch)
            debug(flag2, "  fade: " .. fade)
            debug(flag2, "  loop: " .. loop)

            local loop_bool
            if loop == "true" then
                loop_bool = true
            else
                loop_bool = false
            end
            local handle = core.sound_play(filename, {
                gain = gain,
                pitch = pitch,
                fade = fade,
                loop = loop_bool,
            })
            sound_data[player_name] = {filename, handle}
            debug(flag2, "  sound_data (after): " .. dump(sound_data))

        elseif fields.stop_sound then
            debug(flag2, "  stopping sound..")
            debug(flag2, "  sound_data (before): " .. dump(sound_data))
            stop_current_sound(player_name)
            debug(flag2, "  sound_data (after): " .. dump(sound_data))

        else
            debug(flag2, "  only clicked on dropdown")
        end


    else
        debug(flag2, "  interaction not from an admin item. NO FURTHER ACTION.")
        debug(flag2, "register_on_player_receive_fields() end " .. core.get_gametime())
        return
    end

    debug(flag2, "register_on_player_receive_fields() end")
end)



core.register_on_joinplayer(function(player)

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    p_data.is_debug_on = 0

    print("### world seed: " .. mt_get_mapgen_setting("seed"))

end)


--[[
core.register_on_dieplayer(function(player)

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    local player_meta = player:get_meta()
    local phys = player:get_physics_override()

    local su = p_data.stat_updates
    local se = p_data.status_effects
    local se_su = p_data.se_stat_updates

    p_data.is_debug_on = 1

    initialize_debug_huds(player, player_name)

    mt_after(1, function()
        refresh_debug_display(player, player_name, p_data, player_meta, phys, su, se, se_su)
    end)

end)
--]]
--[[
core.register_on_respawnplayer(function(player)

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    local player_meta = player:get_meta()
    local phys = player:get_physics_override()

    local su = p_data.stat_updates
    local se = p_data.status_effects
    local se_su = p_data.se_stat_updates

    p_data.is_debug_on = 1

    initialize_debug_huds(player, player_name)

    mt_after(1, function()
        refresh_debug_display(player, player_name, p_data, player_meta, phys, su, se, se_su)
    end)

end)
--]]



--[[
local default_entity_spawner_entity = "ss:zombie"

core.register_on_joinplayer(function(player)
    --print("  register_on_joinplayer() ADMIN.LUA")
	local player_meta = player:get_meta()

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
core.register_on_player_receive_fields(function(player, formname, fields)
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


	if formname == "ss:mob_spawner_formspec" then
		debug(flag1, "  used entity spawner")

		if fields.quit then
			debug(flag1, "  player quit from mob_sapwner formspec")
			p_data.formspec_mode = "main_formspec"

		elseif fields.save and fields.mob_select then
			player:get_meta():set_string("entity_spawner_entity", fields.mob_select)
			debug(flag1, "  configuration saved")

			-- Add this line to close the formspec after saving
            mt_close_formspec(player_name, "ss:mob_spawner_formspec")

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


core.override_item("ss:mob_spawner", {
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
--]]
