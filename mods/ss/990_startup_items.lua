print("- loading startup_items.lua")

-- cache global functions for faster access
local table_concat = table.concat
local mt_serialize = core.serialize
local debug = ss.debug
local update_stat = ss.update_stat
local update_fs_weight = ss.update_fs_weight
local get_inventory_weight = ss.get_inventory_weight
local update_meta_and_description = ss.update_meta_and_description
local get_craftable_count = ss.get_craftable_count
local get_fs_craft_button = ss.get_fs_craft_button
local get_fs_ingred_box = ss.get_fs_ingred_box
local get_fs_crafting_grid = ss.get_fs_crafting_grid
local build_fs = ss.build_fs

local ITEM_MAX_USES = ss.ITEM_MAX_USES
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local ARMOR_COLORS = ss.ARMOR_COLORS
local ARMOR_CONTRASTS = ss.ARMOR_CONTRASTS
local RECIPES = ss.RECIPES
local player_data = ss.player_data

local consumable_items = {
    -- FIRE STARTERS
    --ItemStack("ss:fire_drill 5"),
    ItemStack("ss:match_book 5"),

    -- FOOD CONTAINERS
    --ItemStack("ss:cup_wood_water_murky 5"),
    --ItemStack("ss:bowl_wood_water_murky 5"),
    --ItemStack("ss:jar_glass_lidless_water_murky 5"),
    --ItemStack("ss:jar_glass_water_murky 5"),
    --ItemStack("ss:pot_iron_water_murky 5"),

    -- FOOD
    --ItemStack("ss:apple 10"),
    --ItemStack("ss:apple_dried 10"),
    --ItemStack("ss:blueberries 10"),
    --ItemStack("ss:mushroom_brown 10"),
    --ItemStack("ss:mushroom_red 10"),

    -- MEDICAL
    --ItemStack("ss:bandages_basic 10"),
    --ItemStack("ss:bandages_medical 10"),
    --ItemStack("ss:pain_pills 5"),
    --ItemStack("ss:health_shot 5"),
    --ItemStack("ss:first_aid_kit 5"),
    ItemStack("ss:splint 5"),
    ItemStack("ss:cast 5"),
}

local normal_items = {
    -- RESOURCES
    --ItemStack("default:dirt 99"),
    --ItemStack("default:water_source 10"),
    --ItemStack("default:blueberry_bush_leaves_with_berries 10"),
    --ItemStack("ss:wood 12"),
    --ItemStack("ss:wood_plank 12"),
    --ItemStack("ss:stone 10"),
    --ItemStack("ss:stick 10"),
    --ItemStack("ss:plant_fiber 20"),
    --ItemStack("ss:string 20"),
    --ItemStack("ss:rope 10"),
    --ItemStack("ss:cloth 10"),
    --ItemStack("ss:leather 10"),
    --ItemStack("ss:animal_hide 10"),
    --ItemStack("ss:scrap_wood 10"),
    --ItemStack("ss:scrap_iron 10"),
    --ItemStack("ss:scrap_glass 10"),
    --ItemStack("ss:scrap_plastic 10"),
    --ItemStack("ss:scrap_rubber 10"),
    --ItemStack("ss:scrap_paper 10"),

    -- FOOD CONTAINERS
    --ItemStack("ss:cup_wood 10"),
    --ItemStack("ss:bowl_wood 10"),
    --ItemStack("ss:jar_glass_lidless 10"),
    --ItemStack("ss:jar_glass 10"),
    --ItemStack("ss:pot_iron 10"),

    -- TOOLS
    --ItemStack("default:torch"),
    --ItemStack("ss:stone_sharpened"),
    --ItemStack("default:axe_stone 5"),
    --ItemStack("default:shovel_stone 3"),
    --ItemStack("default:pick_stone"),
    --ItemStack("default:sword_stone"),
    --ItemStack("ss:hammer_wood"),

    -- BAGS
    --ItemStack("ss:bag_fiber_small 5"),
    --ItemStack("ss:bag_fiber_medium 5"),
    --ItemStack("ss:bag_fiber_large 5"),
    --ItemStack("ss:bag_cloth_small 5"),
    --ItemStack("ss:bag_cloth_medium 5"),
    --ItemStack("ss:bag_cloth_large 5"),

    -- CAMPFIRE
    ItemStack("ss:campfire_small_new 5"),
    --ItemStack("ss:campfire_stand_wood 5"),
    --ItemStack("ss:campfire_grill_wood 5"),

    -- ADMIN
    ItemStack("ss:stats_wand"),
    ItemStack("ss:item_spawner"),
    --ItemStack("ss:weather_wand"),
    --ItemStack("ss:debug_wand"),
    --ItemStack("ss:sound_wand"),
    --ItemStack("ss:teleporter"),
    --ItemStack("ss:mob_spawner"),
}

local clothing_names = {
    --"shirt_fiber",
    --"pants_fiber",
    --"gloves_fiber",
    "tshirt",
    "pants",
    --"gloves_leather",
    --"gloves_fingerless",
    "socks",
    "scarf",
    --"sunglasses",
    --"necklace",
    --"shorts",
    --"glasses"
}

local armor_names = {
    --"feet_fiber_1",
    --"feet_fiber_2",
    --"head_cloth_2",
    --"face_cloth_1",
    --"face_cloth_2",
    "feet_cloth_2",
    --"head_wood_1",
    --"chest_wood_1",
    --"arms_wood_1",
    --"legs_wood_1",
    "head_leather_1",
    --"head_leather_2",
    "chest_leather_1",
    "arms_leather_1",
    "legs_leather_1",
    --"feet_leather_1"
}

-- give initial items to player for debugging
local flag2 = false
local function give_startup_items(player)
    debug(flag2, "  give_startup_items()")
    local player_inv = player:get_inventory()

    for i, item in ipairs(consumable_items) do
        local item_name = item:get_name()
        debug(flag2, "    item_name: " .. item_name)
        local item_meta = item:get_meta()
        update_meta_and_description(item_meta, item_name, {"remaining_uses"}, {ITEM_MAX_USES[item_name]})
        player_inv:add_item("main", item)
    end

    for i, item in ipairs(normal_items) do
        debug(flag2, "    item_name: " .. item:get_name())
        player_inv:add_item("main", item)
    end

    for i, clothing_name in ipairs(clothing_names) do
        local item = ItemStack("ss:clothes_" .. clothing_name)
        debug(flag2, "    item_name: " .. item:get_name())
        local item_meta = item:get_meta()
        local inv_image = table_concat({
            "ss_clothes_", clothing_name, ".png",
            "^[colorizehsl:", CLOTHING_COLORS[clothing_name][1],
            "^[contrast:", CLOTHING_CONTRASTS[clothing_name][1],
            "^[mask:ss_clothes_", clothing_name, "_mask.png"
        })
        item_meta:set_string("inventory_image", inv_image)
        item_meta:set_string("color", CLOTHING_COLORS[clothing_name][1])
        item_meta:set_string("contrast", CLOTHING_CONTRASTS[clothing_name][1])
        player_inv:add_item("main", item)
    end

    for i, armor_name in ipairs(armor_names) do
        local item = ItemStack("ss:armor_" .. armor_name)
        debug(flag2, "    item_name: " .. item:get_name())
        local item_meta = item:get_meta()
        local inv_image = table_concat({
            "ss_armor_", armor_name,".png",
            "^[colorizehsl:", ARMOR_COLORS[armor_name][1],
            "^[contrast:", ARMOR_CONTRASTS[armor_name][1],
            "^[mask:ss_armor_", armor_name, "_mask.png"
        })
        item_meta:set_string("inventory_image", inv_image)
        item_meta:set_string("color", ARMOR_COLORS[armor_name][1])
        item_meta:set_string("contrast", ARMOR_CONTRASTS[armor_name][1])
        player_inv:add_item("main", item)
    end

    debug(flag2, "  give_startup_items() END")
end


local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() STARTUP ITEMS")

    if player_data[player:get_player_name()].player_status == 0 then
        debug(flag1, "  adding items to inventory")
        local player_meta = player:get_meta()
        local player_name = player:get_player_name()
        local p_data = player_data[player_name]

        give_startup_items(player)
        local inventory_weight = get_inventory_weight(player:get_inventory())
        debug(flag1, "  inventory_weight " .. inventory_weight)
        local update_data = {"normal", "weight", inventory_weight, 1, 1, "curr", "set", true}
        update_stat(player, p_data, player_meta, update_data)
        update_fs_weight(player, player_meta)

        debug(flag1, "  updating craft button, ingred box, and craft grid...")
        local fs = p_data.fs
        local player_inv = player:get_inventory()
        local recipe_id = p_data.prev_recipe_id
        if recipe_id == "" then
            debug(flag1, "  No prior recipe item clicked. Skipped refresh of ingred box and craft button.")
        else
            debug(flag1, "  Loading recipe_id and refreshing ingred_box and craft button...")
            local recipe = RECIPES[recipe_id]
            local crafting_count = get_craftable_count(player_inv, recipe_id)
            fs.right.craft_button = get_fs_craft_button(recipe_id, crafting_count)
            fs.right.ingredients_box = get_fs_ingred_box(player_name, ItemStack(recipe.icon), player_inv, recipe_id)
        end

        debug(flag1, "  Update crafting grid and refresh inventory formspec")
        fs.right.craft_grid = get_fs_crafting_grid(player_name, player_inv, p_data.recipe_category)

        -- save updated fromspec to metadata and to player active data
        player_meta:set_string("fs", mt_serialize(fs))
        player:set_inventory_formspec(build_fs(fs))
    end

	debug(flag1, "\nregister_on_joinplayer() end")
end)