print("- loading recipes.lua")

-- cache global functions for faster access
local debug = ss.debug

-- cache global variables for faster access
local ITEM_TOOLTIP = ss.ITEM_TOOLTIP
local RECIPES = ss.RECIPES
local RECIPE_INGREDIENTS = ss.RECIPE_INGREDIENTS

--[[ RECIPE PROPERTIES:

'recipe_id' - unique identifier. crafting grid is sorted by recipe_id.

'category' - table of categories that a recipe belongs. determines which category pages
in the crafting pane ui the recipe will show. valid categories include "resources", 
"tools", "clothing", "weapons", "armor", "food", "building, "other".

'station' - table of one ore more stations at which this recipe item can be crafted.
valid stations include "hands", "campfire", "furnace", "workstation", "sawmill", etc

'tools' - table of one or more tools the station must have to craft the recipe item.
valid tools include "pot", "grill", "beaker", "anvil", "bellows", etc

'name' - the tooltip text when mouse is hovered over a recipe icon. typically should
be the name of the recipe.

'icon' - itemstring of an existing item. the item with the desired icon image to display
for this recipe.

'output' - table of one or more itemstrings denoting the items that will be added to the
player inventory after succesfully crafting.

'ingredients' - table of one or more itemstrings denoting the needed items to in order
to craft the 'output'. Recipes with more than 5 ingredients will not display optimally
within the ingredients box. 

Note: if a tool is used as an ingredient, the count value is ignored by the inventory
contains_item() function. The below lines will both return 'true' even if only one
sharpened_stone is in the player's inventory:
    ingredients = {"ss:sharpened_stone"}
    ingredients = {"ss:sharpened_stone 3"}

--]]


--- @param recipe table the recipe definition table as used in recipes.lua
-- Adds a 'recipe' into the gobal recipes table 'ss.RECIPES'.
local function add_recipe(recipe)
    local recipe_id = recipe.recipe_id

    -- Remove recipe_id from recipe object. the recipe_id will become the key within
    -- the key/value pair in the global recipes table anyway
    recipe.recipe_id = nil

    -- Check for duplicate recipe_id and append "_" until a unique id is found
    while RECIPES[recipe_id] do
        --print("  WARNING: recipe_id " .. recipe_id .. " already exists. Appending _ to the new recipe.")
        recipe_id = recipe_id .. "_"
    end

    RECIPES[recipe_id] = recipe
    --print("Added recipe: " .. recipe_id)
end


-- RESOURCES

add_recipe({
    recipe_id = "resource_plant_fiber_leaves2",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Plant Fiber",
    subname = "from large leaves",
	icon = "ss:plant_fiber",
    icon2 = "ss:plant_fiber_leaves2",
    output = {"ss:plant_fiber"},
    ingredients = {"group:large_leaves 2"}
})

add_recipe({
    recipe_id = "resource_plant_fiber_leaves1",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Plant Fiber",
    subname = "from small leaves",
	icon = "ss:plant_fiber",
    icon2 = "ss:plant_fiber_leaves1",
    output = {"ss:plant_fiber"},
    ingredients = {"group:small_leaves 3"}
})

add_recipe({
    recipe_id = "resource_plant_fiber_grass",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Plant Fiber",
    subname = "from grass",
	icon = "ss:plant_fiber",
    icon2 = "ss:plant_fiber_grass",
    output = {"ss:plant_fiber"},
    ingredients = {"group:grass_clump 4"}
})

add_recipe({
    recipe_id = "resource_plant_fiber_papyrus",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Plant Fiber x4",
    subname = "from papyrus",
	icon = "ss:plant_fiber",
    icon2 = "ss:plant_fiber_papyrus",
    output = {"ss:plant_fiber 4"},
    ingredients = {"ss:papyrus"}
})

add_recipe({
    recipe_id = "resource_string",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "String",
	icon = "ss:string",
    output = {"ss:string"},
    ingredients = {"ss:plant_fiber 2"},
})

add_recipe({
    recipe_id = "resource_rope",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Rope",
	icon = "ss:rope",
    output = {"ss:rope"},
    ingredients = {"ss:plant_fiber 5", "ss:string 5"},
})

add_recipe({
    recipe_id = "resource_sticks_6",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Sticks x6",
	icon = "ss:stick",
    output = {"ss:stick 6"},
    ingredients = {"ss:wood"},
})

add_recipe({
    recipe_id = "resource_wood_planks_4",
    categories = {"resources", "building"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wood Planks x4",
	icon = "ss:wood_plank",
    output = {"ss:wood_plank 4"},
    ingredients = {"ss:wood"},
})

add_recipe({
    recipe_id = "resource_stones_5",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Stones x5",
	icon = "ss:stone",
    output = {"ss:stone 5"},
    ingredients = {"ss:stone_pile"},
})

add_recipe({
    recipe_id = "resource_stone_pile",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Stone Pile",
	icon = "ss:stone_pile",
    output = {"ss:stone_pile"},
    ingredients = {"ss:stone 6"},
})

--[[
add_recipe({
    recipe_id = "resource_lump_clay_4",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Clay Lump x4",
	icon = "default:clay_lump",
    output = {"default:clay_lump 4"},
    ingredients = {"default:clay"},
})

add_recipe({
    recipe_id = "resource_ingot_bronze_9",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Bronze Ingot x9",
	icon = "default:bronze_ingot",
    output = {"default:bronze_ingot 9"},
    ingredients = {"default:bronzeblock"},
})

add_recipe({
    recipe_id = "resource_ingot_bronze_8",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Bronze Ingot x8",
	icon = "default:bronze_ingot",
    output = {"default:bronze_ingot 8"},
    ingredients = {"default:copper_ingot 8", "default:tin_ingot"},
})

add_recipe({
    recipe_id = "resource_ingot_tin_9",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Tin Ingot x9",
	icon = "default:tin_ingot",
    output = {"default:tin_ingot 9"},
    ingredients = {"default:tinblock"},
})


add_recipe({
    recipe_id = "resource_ingot_copper_9",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Copper Ingot x9",
	icon = "default:copper_ingot",
    output = {"default:copper_ingot 9"},
    ingredients = {"default:copperblock"},
})

add_recipe({
    recipe_id = "resource_ingot_steel_9",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Steel Ingot x9",
	icon = "default:steel_ingot",
    output = {"default:steel_ingot 9"},
    ingredients = {"default:steelblock"},
})

add_recipe({
    recipe_id = "resource_ingot_gold_9",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Gold Ingot x9",
	icon = "default:gold_ingot",
    output = {"default:gold_ingot 9"},
    ingredients = {"default:goldblock"},
})


add_recipe({
    recipe_id = "resource_diamond_9",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Diamond x9",
	icon = "default:diamond",
    output = {"default:diamond 9"},
    ingredients = {"default:diamondblock"},
})

add_recipe({
    recipe_id = "resource_mese_crystal",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Mese Crystal",
	icon = "default:mese_crystal",
    output = {"default:mese_crystal"},
    ingredients = {"default:mese_crystal_fragment 9"},
})

add_recipe({
    recipe_id = "resource_obsidian_shard_9",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Obsidian Shard x9",
	icon = "default:obsidian_shard",
    output = {"default:obsidian_shard 9"},
    ingredients = {"default:obsidian"},
})

add_recipe({
    recipe_id = "resource_paper",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Paper",
	icon = "default:paper",
    output = {"default:paper"},
    ingredients = {"default:papyrus 3"},
})
--]]

add_recipe({
    recipe_id = "resource_snow_pile",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Snow Pile",
	icon = "ss:snow_pile",
    output = {"ss:snow_pile"},
    ingredients = {"default:snow 4"},
})

add_recipe({
    recipe_id = "resource_animal_hide",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Animal Hide",
	icon = "ss:animal_hide",
    output = {"ss:animal_hide"},
    ingredients = {"ss:mushroom_brown 10"},
})

add_recipe({
    recipe_id = "resource_leather",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Leather x2",
	icon = "ss:leather",
    output = {"ss:leather 2"},
    ingredients = {"ss:armor_chest_leather_1"},
})

add_recipe({
    recipe_id = "resource_cloth",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Cloth",
	icon = "ss:cloth",
    output = {"ss:cloth"},
    ingredients = {"ss:clothes_scarf"},
})

add_recipe({
    recipe_id = "resource_scrap_wood",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Scrap Wood x3",
	icon = "ss:scrap_wood",
    output = {"ss:scrap_wood 3"},
    ingredients = {"ss:bowl_wood"},
})

add_recipe({
    recipe_id = "resource_scrap_iron",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Scrap Iron x10",
	icon = "ss:scrap_iron",
    output = {"ss:scrap_iron 10"},
    ingredients = {"ss:pot_iron"},
})

add_recipe({
    recipe_id = "resource_scrap_glass",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Scrap Glass x3",
	icon = "ss:scrap_glass",
    output = {"ss:scrap_glass 3"},
    ingredients = {"ss:jar_glass_lidless"},
})

add_recipe({
    recipe_id = "resource_scrap_plastic",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Scrap Plastic",
	icon = "ss:scrap_plastic",
    output = {"ss:scrap_plastic"},
    ingredients = {"ss:clothes_sunglasses"},
})

add_recipe({
    recipe_id = "resource_scrap_rubber",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Scrap Rubber x2",
	icon = "ss:scrap_rubber",
    output = {"ss:scrap_rubber 2"},
    ingredients = {"ss:armor_feet_cloth_2"},
})

add_recipe({
    recipe_id = "resource_scrap_paper",
    categories = {"resources"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Scrap Paper",
	icon = "ss:scrap_paper",
    output = {"ss:scrap_paper"},
    ingredients = {"ss:match_book"},
})




 -- TOOLS

 add_recipe({
    recipe_id = "tool_torch_charcoal",
    categories = {"tools", "weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Torch",
    subname = "from charcoal",
	icon = "default:torch",
    output = {"default:torch"},
    ingredients = {"ss:stick", "ss:stone", "ss:string", "ss:charcoal"},
})

add_recipe({
    recipe_id = "tool_torch_coal",
    categories = {"tools", "weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Torch",
    subname = "from coal",
	icon = "default:torch",
    output = {"default:torch"},
    ingredients = {"ss:stick", "ss:stone", "ss:string", "default:coal_lump"},
})

add_recipe({
    recipe_id = "tool_sharpened_stone",
    categories = {"tools", "weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Sharpened Stone",
	icon = "ss:stone_sharpened",
    output = {"ss:stone_sharpened"},
    ingredients = {"ss:stone 2"},
})

add_recipe({
    recipe_id = "tool_bag_fiber_small",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Small Fiber Bag",
	icon = "ss:bag_fiber_small",
    output = {"ss:bag_fiber_small"},
    ingredients = {"ss:plant_fiber 4", "ss:string"},
})

add_recipe({
    recipe_id = "tool_bag_fiber_medium",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Fiber Bag",
	icon = "ss:bag_fiber_medium",
    output = {"ss:bag_fiber_medium"},
    ingredients = {"ss:plant_fiber 8", "ss:string 2"},
})

add_recipe({
    recipe_id = "tool_bag_fiber_large",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Large Fiber Bag",
	icon = "ss:bag_fiber_large",
    output = {"ss:bag_fiber_large"},
    ingredients = {"ss:plant_fiber 12", "ss:string 3"},
})


add_recipe({
    recipe_id = "tool_bag_cloth_small",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Small cloth Bag",
	icon = "ss:bag_cloth_small",
    output = {"ss:bag_cloth_small"},
    ingredients = {"ss:cloth", "ss:string"},
})

add_recipe({
    recipe_id = "tool_bag_cloth_medium",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "cloth Bag",
	icon = "ss:bag_cloth_medium",
    output = {"ss:bag_cloth_medium"},
    ingredients = {"ss:cloth 2", "ss:rope 1", "ss:string"},
})

add_recipe({
    recipe_id = "tool_bag_cloth_large",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Large cloth Bag",
	icon = "ss:bag_cloth_large",
    output = {"ss:bag_cloth_large"},
    ingredients = {"ss:cloth 3", "ss:rope 1", "ss:string 2"},
})



add_recipe({
    recipe_id = "tool_axe_stone",
    categories = {"tools", "weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Stone Axe",
	icon = "default:axe_stone",
    output = {"default:axe_stone"},
    ingredients = {"ss:stick 2", "ss:stone 3", "ss:rope 1"},
})

add_recipe({
    recipe_id = "tool_pickaxe_stone",
    categories = {"tools", "weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Stone Pickaxe",
	icon = "default:pick_stone",
    output = {"default:pick_stone"},
    ingredients = {"ss:stick 2", "ss:stone 6", "ss:rope 1"},
})

add_recipe({
    recipe_id = "tool_shovel_stone",
    categories = {"tools", "weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Stone Shovel",
	icon = "default:shovel_stone",
    output = {"default:shovel_stone"},
    ingredients = {"ss:stick 3", "ss:stone 4", "ss:rope 1"},
})

add_recipe({
    recipe_id = "tool_hoe_stone",
    categories = {"tools", "weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Stone Hoe",
	icon = "farming:hoe_stone",
    output = {"farming:hoe_stone"},
    ingredients = {"ss:stick 3", "ss:stone 4", "ss:rope 1"},
})

add_recipe({
    recipe_id = "tool_campfire",
    categories = {"tools"},
    station = {"hands"},
    tools = {"none"},
	name = "Campfire",
	icon = "ss:campfire_small_new",
    output = {"ss:campfire_small_new"},
    ingredients = {"ss:wood 4", "ss:stick 4"},
})

add_recipe({
    recipe_id = "tool_campfire_stand_wood",
    categories = {"tools"},
    station = {"hands"},
    tools = {"none"},
	name = "Wooden Campfire Stand",
	icon = "ss:campfire_stand_wood",
    output = {"ss:campfire_stand_wood"},
    ingredients = {"ss:stick 6", "ss:rope 1"},
})

add_recipe({
    recipe_id = "tool_campfire_grill_wood",
    categories = {"tools"},
    station = {"hands"},
    tools = {"none"},
	name = "Wooden Campfire Grill",
	icon = "ss:campfire_grill_wood",
    output = {"ss:campfire_grill_wood"},
    ingredients = {"ss:stick 4", "ss:rope 1"},
})

add_recipe({
    recipe_id = "tool_fire_drill",
    categories = {"tools"},
    station = {"hands"},
    tools = {"none"},
	name = "Fire Drill",
	icon = "ss:fire_drill",
    output = {"ss:fire_drill"},
    ingredients = {"ss:stick 2", "ss:wood", "ss:string 3"},
})

add_recipe({
    recipe_id = "tool_match_book",
    categories = {"tools"},
    station = {"hands"},
    tools = {"none"},
	name = "Book of Matches",
	icon = "ss:match_book",
    output = {"ss:match_book"},
    ingredients = {"ss:charcoal", "ss:plant_fiber", "ss:string"},
})

add_recipe({
    recipe_id = "tool_hammer_wood",
    categories = {"tools", "weapons"},
    station = {"hands"},
    tools = {"none"},
	name = "Wooden Hammer",
	icon = "ss:hammer_wood",
    output = {"ss:hammer_wood"},
    ingredients = {"ss:stick", "ss:wood 2"},
})





--[[
add_recipe({
    recipe_id = "tool_sign_steel",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Steel Sign",
	icon = "default:sign_wall_steel",
    output = {"default:sign_wall_steel"},
    ingredients = {"default:steel_ingot 2", "ss:stick"},
})
--]]

add_recipe({
    recipe_id = "tool_ladder_wood",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Ladder",
	icon = "default:ladder_wood",
    output = {"default:ladder_wood"},
    ingredients = {"ss:stick 6"},
})

--[[
add_recipe({
    recipe_id = "tool_ladder_steel",
    categories = {"tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Steel Ladder x2",
	icon = "default:ladder_steel",
    output = {"default:ladder_steel 2"},
    ingredients = {"default:steel_ingot 2"},
})
--]]

add_recipe({
    recipe_id = "food_cup_wood",
    categories = {"food", "tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Cup x2",
	icon = "ss:cup_wood",
    output = {"ss:cup_wood", "ss:cup_wood"},
    ingredients = {"ss:wood"},
})

add_recipe({
    recipe_id = "food_bowl_wood",
    categories = {"food", "tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Bowl",
	icon = "ss:bowl_wood",
    output = {"ss:bowl_wood"},
    ingredients = {"ss:wood"},
})


add_recipe({
    recipe_id = "food_jar_glass_lidless",
    categories = {"food", "tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Glass Jar",
	icon = "ss:jar_glass_lidless",
    output = {"ss:jar_glass_lidless"},
    ingredients = {"ss:scrap_glass 10"},
})

add_recipe({
    recipe_id = "food_jar_glass",
    categories = {"food", "tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Covered Glass Jar",
	icon = "ss:jar_glass",
    output = {"ss:jar_glass"},
    ingredients = {"ss:scrap_glass 10", "ss:scrap_iron 2"},
})


add_recipe({
    recipe_id = "food_pot_iron",
    categories = {"food", "tools"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Iron Pot",
	icon = "ss:pot_iron",
    output = {"ss:pot_iron"},
    ingredients = {"ss:scrap_iron 25"},
})






--[[
for i=1, 30 do
    add_recipe({
        recipe_id = "test_item_" .. i,
        categories = {"tools"},
        station = {"hands", "workstation"},
        tools = {"none"},
        name = "Test Item " .. i,
        icon = "ss:stick",
        output = {"ss:stick"},
        ingredients = {"default:dirt"},
    })
end
--]]



-- CLOTHING


add_recipe({
    recipe_id = "clothing_sunglasses",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Sunglasses",
	icon = "ss:clothes_sunglasses",
    output = {"ss:clothes_sunglasses"},
    ingredients = {"ss:scrap_plastic 2", "ss:scrap_glass"},
})

add_recipe({
    recipe_id = "clothing_glasses",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Glasses",
	icon = "ss:clothes_glasses",
    output = {"ss:clothes_glasses"},
    ingredients = {"ss:scrap_plastic 2", "ss:scrap_glass"},
})


add_recipe({
    recipe_id = "clothing_shirt_fiber",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Fiber Shirt",
	icon = "ss:clothes_shirt_fiber",
    output = {"ss:clothes_shirt_fiber"},
    ingredients = {"ss:plant_fiber 12", "ss:string 6"},
})

add_recipe({
    recipe_id = "clothing_pants_fiber",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Fiber Pants",
	icon = "ss:clothes_pants_fiber",
    output = {"ss:clothes_pants_fiber"},
    ingredients = {"ss:plant_fiber 12", "ss:string 6"},
})

add_recipe({
    recipe_id = "clothing_tshirt",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "T-Shirt",
	icon = "ss:clothes_tshirt",
    output = {"ss:clothes_tshirt"},
    ingredients = {"ss:cloth 6", "ss:string 8"},
})

add_recipe({
    recipe_id = "clothing_pants",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Pants",
	icon = "ss:clothes_pants",
    output = {"ss:clothes_pants"},
    ingredients = {"ss:cloth 6", "ss:string 8"},
})

add_recipe({
    recipe_id = "clothing_shorts",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Shorts",
	icon = "ss:clothes_shorts",
    output = {"ss:clothes_shorts"},
    ingredients = {"ss:cloth 4", "ss:string 4"},
})

add_recipe({
    recipe_id = "clothing_socks",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Socks",
	icon = "ss:clothes_socks",
    output = {"ss:clothes_socks"},
    ingredients = {"ss:cloth 2", "ss:string 2"},
})

add_recipe({
    recipe_id = "clothing_scarf",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Scarf",
	icon = "ss:clothes_scarf",
    output = {"ss:clothes_scarf"},
    ingredients = {"ss:cloth 3", "ss:string 1"},
})

add_recipe({
    recipe_id = "clothing_necklace",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Necklace",
	icon = "ss:clothes_necklace",
    output = {"ss:clothes_necklace"},
    ingredients = {"ss:string 1", "ss:scrap_glass"},
})

add_recipe({
    recipe_id = "clothing_gloves_fiber",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Fiber Gloves",
	icon = "ss:clothes_gloves_fiber",
    output = {"ss:clothes_gloves_fiber"},
    ingredients = {"ss:plant_fiber 2", "ss:string 4"},
})

add_recipe({
    recipe_id = "clothing_gloves_leather",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Leather Gloves",
	icon = "ss:clothes_gloves_leather",
    output = {"ss:clothes_gloves_leather"},
    ingredients = {"ss:leather 3", "ss:string 4"},
})

add_recipe({
    recipe_id = "clothing_gloves_fingerless",
    categories = {"clothing"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Figerless Gloves",
	icon = "ss:clothes_gloves_fingerless",
    output = {"ss:clothes_gloves_fingerless"},
    ingredients = {"ss:cloth 2", "ss:leather", "ss:string 4"},
})



-- ARMOR

add_recipe({
    recipe_id = "armor_fiber_sandals",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Fiber Sandals",
	icon = "ss:armor_feet_fiber_1",
    output = {"ss:armor_feet_fiber_1"},
    ingredients = {"ss:plant_fiber 3", "ss:string 4"},
})

add_recipe({
    recipe_id = "armor_fiber_shoes",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Fiber Shoes",
	icon = "ss:armor_feet_fiber_2",
    output = {"ss:armor_feet_fiber_2"},
    ingredients = {"ss:plant_fiber 5", "ss:string 4"},
})

add_recipe({
    recipe_id = "armor_head_wood",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Helmet",
	icon = "ss:armor_head_wood_1",
    output = {"ss:armor_head_wood_1"},
    ingredients = {"ss:wood 1"},
})

add_recipe({
    recipe_id = "armor_chest_wood",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Chest Armor",
	icon = "ss:armor_chest_wood_1",
    output = {"ss:armor_chest_wood_1"},
    ingredients = {"ss:wood_plank 5", "ss:rope 2"},
})

add_recipe({
    recipe_id = "armor_arms_wood",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Arm Guards",
	icon = "ss:armor_arms_wood_1",
    output = {"ss:armor_arms_wood_1"},
    ingredients = {"ss:wood_plank 4", "ss:rope 2"},
})

add_recipe({
    recipe_id = "armor_legs_wood",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Leg Guards",
	icon = "ss:armor_legs_wood_1",
    output = {"ss:armor_legs_wood_1"},
    ingredients = {"ss:wood_plank 4", "ss:rope 2"},
})

add_recipe({
    recipe_id = "armor_baseball_cap",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Baseball Cap",
	icon = "ss:armor_head_cloth_2",
    output = {"ss:armor_head_cloth_2"},
    ingredients = {"ss:cloth 2", "ss:string 4"},
})

add_recipe({
    recipe_id = "armor_bandana",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Bandana",
	icon = "ss:armor_face_cloth_1",
    output = {"ss:armor_face_cloth_1"},
    ingredients = {"ss:cloth 3", "ss:string 1"},
})

add_recipe({
    recipe_id = "armor_face_mask",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Face Mask",
	icon = "ss:armor_face_cloth_2",
    output = {"ss:armor_face_cloth_2"},
    ingredients = {"ss:cloth 2", "ss:string 2"},
})

add_recipe({
    recipe_id = "armor_sneakers",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Sneakers",
	icon = "ss:armor_feet_cloth_2",
    output = {"ss:armor_feet_cloth_2"},
    ingredients = {"ss:cloth 4", "ss:scrap_rubber 2", "ss:string 4"},
})

add_recipe({
    recipe_id = "armor_leather_helmet",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Leather Helmet",
	icon = "ss:armor_head_leather_1",
    output = {"ss:armor_head_leather_1"},
    ingredients = {"ss:leather 2", "ss:string 3"},
})

add_recipe({
    recipe_id = "armor_cowboy_hat",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Cowboy Hat",
	icon = "ss:armor_head_leather_2",
    output = {"ss:armor_head_leather_2"},
    ingredients = {"ss:leather 4", "ss:string 4"},
})

add_recipe({
    recipe_id = "armor_chest_leather",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Leather Chest Armor",
	icon = "ss:armor_chest_leather_1",
    output = {"ss:armor_chest_leather_1"},
    ingredients = {"ss:leather 6", "ss:string 6"},
})

add_recipe({
    recipe_id = "armor_arms_leather",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Leather Arm Guards",
	icon = "ss:armor_arms_leather_1",
    output = {"ss:armor_arms_leather_1"},
    ingredients = {"ss:leather 4", "ss:string 6"},
})

add_recipe({
    recipe_id = "armor_legs_leather",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Leather Leg Guards",
	icon = "ss:armor_legs_leather_1",
    output = {"ss:armor_legs_leather_1"},
    ingredients = {"ss:leather 4", "ss:string 6"},
})

add_recipe({
    recipe_id = "armor_leather_shoes",
    categories = {"armor"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Leather Shoes",
	icon = "ss:armor_feet_leather_1",
    output = {"ss:armor_feet_leather_1"},
    ingredients = {"ss:leather 4", "ss:string 6"},
})














-- WEAPONS 

add_recipe({
    recipe_id = "weapon_sword_stone",
    categories = {"weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Stone Sword",
	icon = "default:sword_stone",
    output = {"default:sword_stone"},
    ingredients = {"ss:stick 2", "ss:stone 6", "ss:string 3"},
})

add_recipe({
    recipe_id = "weapon_snowball",
    categories = {"weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Snow Ball",
	icon = "default:snow",
    output = {"default:snow"},
    ingredients = {"ss:snow_pile"},
})

--[[
add_recipe({
    recipe_id = "weapon_snowballs_9",
    categories = {"weapons"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Snow Balls x9",
	icon = "default:snow",
    output = {"default:snow 9"},
    ingredients = {"default:snowblock"},
})
--]]


-- BUILDING

add_recipe({
    recipe_id = "tool_sign_wood",
    categories = {"building"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Sign",
	icon = "default:sign_wall_wood",
    output = {"default:sign_wall_wood"},
    ingredients = {"ss:wood_plank 2", "ss:stick"},
})


add_recipe({
    recipe_id = "building_fence_wood",
    categories = {"building"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Fence",
	icon = "default:fence_wood",
    output = {"default:fence_wood"},
    ingredients = {"ss:wood_plank 6", "ss:rope 2"},
})



--[[
add_recipe({
    recipe_id = "building_bookshelf_wood",
    categories = {"building"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Wooden Bookshelf",
	icon = "default:bookshelf",
    output = {"default:bookshelf"},
    ingredients = {"ss:wood_plank 6", "default:book 3"},
})
--]]

-- MEDICAL

add_recipe({
    recipe_id = "medical_bandages_basic",
    categories = {"medical"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Bandages",
	icon = "ss:bandages_basic",
    output = {"ss:bandages_basic"},
    ingredients = {"ss:plant_fiber 4"},
})

add_recipe({
    recipe_id = "medical_bandages_medical",
    categories = {"medical"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Medical Bandages",
	icon = "ss:bandages_medical",
    output = {"ss:bandages_medical"},
    ingredients = {"ss:charcoal", "ss:plant_fiber 4", "ss:string"},
})

add_recipe({
    recipe_id = "medical_pain_pills",
    categories = {"medical"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Pain Pills",
	icon = "ss:pain_pills",
    output = {"ss:pain_pills"},
    ingredients = {"ss:charcoal", "ss:apple", "ss:flower_dandelion_white_picked"},
})

add_recipe({
    recipe_id = "medical_first_aid_kit",
    categories = {"medical"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "First Aid Kit",
	icon = "ss:first_aid_kit",
    output = {"ss:first_aid_kit"},
    ingredients = {"ss:bandages_medical", "ss:pain_pills"},
})

add_recipe({
    recipe_id = "medical_splint",
    categories = {"medical"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Splint",
	icon = "ss:splint",
    output = {"ss:splint"},
    ingredients = {"ss:stick 2", "ss:rope"},
})

add_recipe({
    recipe_id = "medical_health_shot",
    categories = {"medical"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Health Shot",
	icon = "ss:health_shot",
    output = {"ss:health_shot"},
    ingredients = {"ss:pain_pills", "ss:blueberries 3", "ss:scrap_glass"},
})


-- OTHER

local node_names = {"rose", "tulip", "dandelion_yellow", "chrysanthemum_green",
    "geranium", "viola", "dandelion_white", "tulip_black"}
for i,v in ipairs(node_names) do
    local item_name = "ss:flower_" .. v .. "_picked"
    local tooltip_description = ITEM_TOOLTIP[item_name]
    add_recipe({
        recipe_id = "other_" .. v,
        categories = {"other"},
        station = {"hands", "workstation"},
        tools = {"none"},
        name = tooltip_description,
        icon = item_name,
        output = {item_name},
        ingredients = {"ss:flower_" .. v},
    })
end

--[[
add_recipe({
    recipe_id = "other_book",
    categories = {"other"},
    station = {"hands", "workstation"},
    tools = {"none"},
	name = "Book",
	icon = "default:book",
    output = {"default:book"},
    ingredients = {"default:paper 3"},
})
--]]

-- initialize the ss.RECIPE_INGREDIENTS table with all recipe_id's as keys
local flag1 = false
debug(flag1, "\nInitializing ss.RECIPE_INGREDIENTS table... recipe_id added: ")
for key, value in pairs(RECIPES) do
    debug(flag1, key)
    RECIPE_INGREDIENTS[key] = {}
end

--print("ss.RECIPES: " .. dump(ss.RECIPES))