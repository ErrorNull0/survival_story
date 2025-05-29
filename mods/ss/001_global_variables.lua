print("- loading global_variables.lua ")

-- the main namespace for Survival Story
ss = {}

ss.mod_storage = core.get_mod_storage()

-- this value is the rate at which time passes in-game. Higher value is faster. this is
-- also used for calcuating how much thirst and hunger is depleted while idle.
-- 72: 24 hours in-game is 20 minutes real-world (default 'minecraft' style speed)
-- 24: 24 hours in-game is 60 minutes real-world
ss.TIME_SPEED = 24

-- how many real life seconds are in one game day
ss.GAMEDAY_IRL_SECONDS = (1440 / ss.TIME_SPEED) * 60

--[[ Indexed by item name and holds the 'inventory_image' data of all craftitems
for quick access. Initialized from global_tables.lua. Note: only includes items
created via register_craftitem() function. --]]
ss.CRAFTITEM_ICON = {}

-- ##### The following tables are initialized by 'global_vars_init.lua' with data
-- ##### read from 'itme_data.txt'. Each table is indexed by the item name and the
-- ##### corresponding value it typically a string or number.

--[[ The item's name shown in bold within the item info panel. Example:
{
    ["ss:wood"] = "Wood",
    ["ss:leaves_fern"] = "Fern Leaves"
    ["ss:dirt_pile"] = "Dirt"
} --]]
ss.ITEM_DISPLAY_NAME = {}

--[[ A one-word descriptor of the item shown in parenthesis next to the
ITEM DISPLAY NAME on the item info panel. Example:
{
    ["ss:wood"] = "chunk",
    ["ss:leaves_fern"] = "large"
    ["ss:dirt_pile"] = "pile"
} --]]
ss.ITEM_DESCRIPTOR = {}

--[[ Holds the item's tooltip text that is shown when mouse is hovered over the
item icon. The text is typically the combination of ITEM_DISPLAY_NAME and
ITEM_DESCRIPTOR. Example:
{
    ["ss:wood"] = "Wood (chunk)",
    ["ss:leaves_fern"] = "Fern Leaves (large)"
    ["ss:dirt_pile"] = "Dirt (pile)"
}
--]]
ss.ITEM_TOOLTIP = {}

--[[ Holds the category name of each item that is shown below the ITEM_DISPLAY_NAME
on the item info panel. This is currently an arbituary property that does not impact
any real game mechanic. --]]
ss.ITEM_CATEGORY = {}

--[[ Holds the item group of each item. Allows recipes to use item ingredients
that are part of a group and not just a single specific item. --]]
ss.ITEM_GROUPS = {}

--[[ Table indexed by item group name holds all item names relating to that group.
Example:
 {
    ["small_leaves"] = {
        "ss:leaves_dry_clump",
        "ss:leaves_clump",
        "ss:pine_needles"
    },
    ["stick"] = {
        "default:stick",
        "ss:stick"
    } 
 } --]]
ss.GROUP_ITEMS = {}


-- store the duration of the stat effect sound effect, to ensure no other sounds
-- play while it's active. each stat relates to either "1" (male version) or "2"
-- (female version) of the sound file.
ss.SOUND_EFFECT_DURATION = {
    -- 'internal' stat effects
    health_1 = 0.5,
    health_2 = 0.5,
    thirst_1 = 1.2,
    thirst_2 = 1.3,
    hunger_1 = 1.7,
    hunger_2 = 1.6,
    immunity_1 = 1.5,
    immunity_2 = 1.5,
    alertness_1 = 0.6,
    alertness_2 = 1.1,
    sanity_1 = 2.6,
    sanity_2 = 2.5,
    hygiene_1 = 2.3,
    hygiene_2 = 2.3,
    comfort_1 = 2.1,
    comfort_2 = 1.6,
    happiness_1 = 1.8,
    happiness_2 = 2.3,
    breath_1 = 0,
    breath_2 = 0,
    stamina_1 = 3.5,
    stamina_2 = 3.5,
    weight_1 = 1.4,
    weight_2 = 2.0,
    legs_1 = 0.7,
    legs_2 = 0.5,
    hands_1 = 0.7,
    hands_2 = 0.5,

    -- 'external' stat effects
    hot_1 = 1.2,
    hot_2 = 1.3,
    cold_1 = 1.2,
    cold_2 = 1.3,
    illness_1 = 1.5,
    illness_2 = 1.5,
    poison_1 = 1.5,
    poison_2 = 1.5,
    vomit_1 = 3.5,
    vomit_2 = 3.5,
    sneeze_1 = 2.7,
    sneeze_2 = 2.5,
    cough_1 = 3.5,
    cough_2 = 3.5,

    -- other vocalized sounds
    ss_noise_cough_1 = 1.8,
    ss_noise_cough_2 = 1.8,
    ss_noise_sneeze_1 = 0.5,
    ss_noise_sneeze_2 = 0.5,
    ss_action_crawlup_1 = 0.3,
    ss_action_crawlup_2 = 0.4,

}


--[[ The following 5 'SOUND' tables represent sounds played within the contexts of
moving items between INVentory slots, swinging a wielded item and MISSing, swining
a wielded item and HITting a node or entity, item is USEd or eaten, or item BREAKs
from being worn. Each table is indexed by item name, and the value is the sound
filename. Example:
{
    ["ss:stick"] = "ss_inv_wood",
    ["ss:stone"] = "ss_inv_dense",
    ["ss:cup_wood_water_boiled"] = "ss_inv_dense_liquid"
} --]]
ss.ITEM_SOUNDS_INV = {}
ss.ITEM_SOUNDS_MISS = {}
ss.ITEM_SOUNDS_HIT = {}
ss.ITEM_SOUNDS_USE = {}
ss.ITEM_SOUNDS_BREAK = {}

--[[ The item's weight. --]]
ss.ITEM_WEIGHTS = {}

--[[ The duration in seconds the item will burn as fuel in a campfire or other
heating station. --]]
ss.ITEM_BURN_TIMES = {}

--[[ Holds the cook rate of all burnable items. Indexed by item name. The cook rate
is an int value of zero or greater that's added to the 'cook_progress'. Wwhen it hits
COOK_THRESHOLD, the item transforms to its cooked variant. This table is initialized
with data from item_data.txt --]]
ss.ITEM_HEAT_RATES = {}

--[[ Holds the monetary value of all items, can be a whole number zero or greater.
Indexed by item name. --]]
ss.ITEM_VALUES = {}

--[[ Holds the value representing the base amount of health damage that the item can
inflict. Can be a float value of zero or greater. Indexed by item name. --]]
ss.ITEM_HIT_DAMAGES = {}

--[[ Holds the duration in seconds the player must wait bewteen hits in order for
item to inflict its full hit damage. Can be a float value of zero or greater.
Indexed by item name. --]]
ss.ITEM_HIT_COOLDOWNS = {}

--[[ Holds the category name representing the type of hit damage the item can inflict.
Indexed by item name. Values can be like blunt, blade, piercing, or fist. This impacts
how effective the item is against certain armor types. --]]
ss.ITEM_HIT_TYPES = {}

--[[ Indexed by item name, holds the pointing range in meters as player wields that
item. Then the range values in this table are used to override
the 'range' property of all items via registered_everying_functions.txt --]]
ss.ITEM_POINTING_RANGES = {}

ss.POINTING_RANGE_DEFAULT = 1.4

--[[ Holds a short one line description of each time, that shows within the top
item info panel. Indexed by item name. --]]
ss.ITEM_DESC_SHORT = {}

--[[ Holds the full text description of each time, that shows within the tooltip
when hovering over the item icon within the item info panel. Indexed by item name.
The text also contains line breaks \n to ensure better formatting within the tooltip.
 --]]
ss.ITEM_DESC_LONG = {}

--[[ Hold the stack max count value for all items. These values are generated by
taking SLOT_WEIGHT_MAX divided by the item's weight. The max count values are capped
at 99. This table is indexed by the item names.]]
ss.STACK_MAX_COUNTS = {}


-- ##### The following tables are initialized from 'categorizing node types' section
-- ##### of global_tables.lua with data. All tables are indexed by the item name
-- ##### and assigned to boolean 'true'.

-- solid nodes that players can walk on and and other nodes can be placed on top of
ss.NODE_NAMES_SOLID_CUBE = {}

-- nodes with height that vary depending on its orientation, like stairs and slabs
ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT = {}

-- solid nodes that are not a full meter height, but can be dug up by node placement
ss.NODE_NAMES_GAPPY_DIGGABLE = {}

-- solid nodes that are not a full meter height, and cannot be dug up by node placement
ss.NODE_NAMES_GAPPY_NONDIGGABLE = {}

-- solid nodes underwater that have walkthru plants shown above it
ss.NODE_NAMES_PLANTLIKE_ROOTED = {}

-- all water nodes
ss.NODE_NAMES_WATER = {}

-- all lava nodes
ss.NODE_NAMES_LAVA = {}

-- walkthrough nodes like plants that can be dug up by node placement
ss.NODE_NAMES_NONSOLID_DIGGABLE = {}

-- walkthrough nodes like bags that cannot be dug up by node placement
ss.NODE_NAMES_NONSOLID_NONDIGGABLE = {}

-- table that includes all the solid 'walkable' nodes: NODE_NAMES_SOLID_CUBE,
-- NODE_NAMES_SOLID_VARIABLE_HEIGHT, NODE_NAMES_GAPPY_DIGGABLE, and NODE_NAMES_GAPPY_NONDIGGABLE
ss.NODE_NAMES_SOLID_ALL = {}

-- table that includes all the 'gappy' nodes: NODE_NAMES_GAPPY_DIGGABLE and
-- NODE_NAMES_GAPPY_NONDIGGABLE
ss.NODE_NAMES_GAPPY_ALL = {}

-- table that includes all the nonsolid nodes: NODE_NAMES_NONSOLID_NONDIGGABLE and
-- NODE_NAMES_NONSOLID_NONDIGGABLE
ss.NODE_NAMES_NONSOLID_ALL = {}

-- table that includes all the diggable nodes: NODE_NAMES_GAPPY_DIGGABLE and
-- NODE_NAMES_NONSOLID_DIGGABLE
ss.NODE_NAMES_DIGGABLE_ALL = {}

-- table that includes all the diggable nodes: NODE_NAMES_GAPPY_DIGGABLE and
-- NODE_NAMES_NONSOLID_DIGGABLE
ss.NODE_NAMES_NONDIGGABLE_ALL = {}

-- table that includes all nodes from these tables that can never ever be diggable
-- by a spawning itemdrop bag: CAMPFIRE_NODE_NAMES and BAG_NODE_NAMES_ALL
ss.NODE_NAMES_NONDIGGABLE_EVER = {}


-- ##### The following tables put item/node names in groups for quick lookup  #####
-- ##### All tables are indexed by the item name and assigned to boolean 'true'.

-- Represents all registered craftitems names.
-- Initialized from 200_global_tables.lua
ss.CRAFTITEM_NAMES = {}

-- Represents all registered tool names.
-- Initialed from 200_global_tables.lua
ss.TOOL_NAMES = {}

-- Represents all bag itmes that players can equip to increase inventory slot count
ss.BAG_NODE_NAMES_ALL = {
    ["ss:bag_fiber_small"] = true,
    ["ss:bag_fiber_medium"] = true,
    ["ss:bag_fiber_large"] = true,
    ["ss:bag_cloth_small"] = true,
    ["ss:bag_cloth_medium"] = true,
    ["ss:bag_cloth_large"] = true
}

-- Represents all itemdrop bags
ss.ITEMDROP_BAGS_ALL = {
    ["ss:itemdrop_bag"] = true,
    ["ss:itemdrop_bag_in_water"] = true,
    ["ss:itemdrop_box"] = true
}

-- Represents items that are like clumps of grass
ss.GRASS_CLUMPS = {
    ["ss:grass_clump"] = true,
    ["ss:dry_grass_clump"] = true,
    ["ss:marram_grass_clump"] = true,
    ["ss:jungle_grass_clump"] = true,
}

-- Represents items that are larger leaves
ss.LARGE_LEAVES = {
    ["ss:leaves_fern"] = true,
}

-- Represents all campfire node variations while placed in the world, like 'new',
-- 'used', 'burning', and 'spent'. Initiated from 200_global_tables.lua
-- which pulls data from campfire_data.txt.
ss.CAMPFIRE_NODE_NAMES = {}

-- Represents all campfire stand variations like unused, 'used', and 'heated'.
-- Initiated from 200_global_tables.lua which pulls data from
-- campfire_data.txt.
ss.CAMPFIRE_STAND_NAMES = {}

-- Represents all campfire grill variations like unused, 'used', and 'heated'.
-- Initiated from 200_global_tables.lua which pulls data from
-- campfire_data.txt.
ss.CAMPFIRE_GRILL_NAMES = {}

ss.CAMPFIRE_TOOL_NAMES = {
    ["ss:campfire_stand_wood"] = true,
    ["ss:campfire_stand_grill"] = true
}


-- These values are used to calculate the amount of legs value drain or health
-- damage when player jumps or falls onto the node. It is also used to calculate
-- the amount of hands value drain when player digs up the node. nodes made of
-- softer material has a lower value
ss.NODE_LEGS_DRAIN_MOD = {}
ss.NODE_HANDS_DRAIN_MOD = {}



-- Represents usable/unburt fire starter items like unused and 'used'. Initiated
-- from 200_global_tables.lua which pulls data from campfire_data.txt.
ss.FIRE_STARTER_NAMES = {}

-- preset color options for player model textures relating to skin, hair,
-- eyes and underwear, and dislay in the player setup window
ss.texture_colors = {
	{"color1",0,50,0,"#ff0000","#ffffff"},
	{"color2",18,50,0,"#ff4d00","#ffffff"},
	{"color3",36,50,0,"#ff9900","#ffffff"},
	{"color4",54,50,0,"#ffe500","#ffffff"},
	{"color5",72,50,0,"#ccff00","#ffffff"},

	{"color6",90,50,0,"#80ff00","#ffffff"},
	{"color7",108,50,0,"#33ff00","#ffffff"},
	{"color8",126,50,0,"#00ff1a","#ffffff"},
	{"color9",144,50,0,"#00ff66","#ffffff"},
	{"color10",162,50,0,"#00ffb2","#ffffff"},

	{"color11",180,50,0,"#00ffff","#ffffff"},
	{"color12",198,50,0,"#00b2ff","#ffffff"},
	{"color13",216,50,0,"#0066ff","#ffffff"},
	{"color14",234,50,0,"#001aff","#ffffff"},
	{"color15",252,50,0,"#3300ff","#ffffff"},

	{"color16",270,50,0,"#8000ff","#ffffff"},
	{"color17",288,50,0,"#cc00ff","#ffffff"},
	{"color18",306,50,0,"#ff00e5","#ffffff"},
	{"color19",324,50,0,"#ff0099","#ffffff"},
	{"color20",342,50,0,"#ff004d","#ffffff"}
}

-- preset saturation, lightness, and contrast options for player model textures
-- that display in the player setup window
ss.texture_saturations = {-50,-36,-21,-7,7,21,36,50}
ss.texture_lightnesses = {-75,-54,-32,-11,11,32,54,75}
ss.texture_contrasts = {"0:0","12:0","24:0","36:0","48:0","60:0","72:0","86:0"}

-- clothing texture color variations. values follow formatting of 'colorizehsl' texture
-- modifier, <hue -180 to +180>:<saturation 0 to 100>:<lightness -100 to +100>
ss.CLOTHING_COLORS = {
    glasses = {"0:0:-32", "50:85:-10", "80:70:-50", "190:40:-30", "230:45:-40", "300:25:-50", "0:0:32", "0:0:-67", "0:80:-50", "30:90:-15"},
    sunglasses = {"0:0:-50", "0:0:-70", "0:80:-50", "30:90:-15", "50:85:-10", "80:70:-50", "190:40:-30", "230:45:-40", "300:25:-50", "0:0:32", "0:0:-30"},
    necklace = {"0:0:16", "190:40:-30", "230:45:-40", "300:25:-50", "0:0:32", "0:80:-50", "30:90:-15", "50:85:-10", "80:70:-50"},
    scarf = {"25:5:-35", "300:25:-50", "0:0:32", "0:0:-32", "0:0:-67", "0:80:-50", "30:90:-15", "50:85:-10", "80:70:-50", "190:40:-30", "230:45:-40"},
    shirt_fiber = {"56:32:-40", "32:40:-48", "40:40:0", "20:40:-16"},
    tshirt = {"35:5:-25", "80:70:-50", "190:40:-30", "230:45:-40", "300:25:-50", "0:0:32", "0:0:-32", "0:0:-67", "0:80:-50", "30:90:-15", "50:85:-10"},
    gloves_fiber = {"56:32:-40", "32:40:-48", "40:40:0", "20:40:-16"},
    gloves_leather = {"32:40:-48", "40:40:-35", "20:40:-35", "36:40:-70", "0:0:-70"},
    gloves_fingerless = {"30:10:-40", "0:0:-70", "0:80:-60", "30:90:-32", "50:85:-26", "80:70:-66", "190:40:-46", "230:45:-56", "300:25:-66", "0:0:32", "0:0:-46"},
    pants_fiber = {"56:32:-40", "32:40:-48", "40:40:0", "20:40:-16"},
    pants = {"30:10:-30", "40:40:-15", "50:85:-20", "80:70:-60", "190:40:-40", "230:45:-50", "300:25:-60", "0:0:35", "0:0:-42", "0:0:-68", "0:80:-56", "30:90:-25"},
    shorts = {"30:15:-30", "30:90:-25", "50:85:-20", "80:70:-60", "190:40:-40", "230:45:-50", "300:25:-60", "0:0:32", "0:0:-42", "0:0:-68", "0:80:-56"},
    socks = {"25:10:-40", "0:0:-42", "0:0:-68", "0:80:-56", "30:90:-25", "50:85:-20", "80:70:-60", "190:40:-40", "230:45:-50", "300:25:-60", "0:0:32"},
}

-- clothing texture contrast variations. values follow formatting of 'contrast' texture
-- modifier, <contrast -127 to +127>:<brightness -127 to +127>
ss.CLOTHING_CONTRASTS = {
    glasses = {"0:0", "0:0", "0:0", "0:0", "0:0", "16:16", "0:0", "16:0", "0:0", "0:0"},
    sunglasses = {"16:0", "16:0", "0:0", "0:0", "0:0", "0:0", "0:0", "0:0", "0:0", "40:0", "16:0"},
    necklace = {"0:0", "0:0", "0:0", "0:0", "16:16", "0:0", "0:0", "0:0", "0:0"},
    scarf = {"35:0", "0:0", "32:0", "0:0", "16:0", "0:0", "0:0", "0:0", "0:0", "0:0", "0:0"},
    shirt_fiber = {"0:0", "0:0", "0:0", "0:0"},
    tshirt = {"24:0", "0:0", "0:0", "0:0", "0:0", "16:16", "0:0", "16:0", "0:0", "0:0", "0:0"},
    gloves_fiber = {"0:0", "0:0", "0:0", "0:0"},
    gloves_fingerless = {"32:-16", "16:16", "0:0", "16:0", "0:0", "0:0", "0:0", "0:0", "0:0", "32:0", "0:0"},
    gloves_leather = {"0:0", "0:0", "0:0", "0:0", "0:0"},
    pants_fiber = {"0:0", "0:0", "0:0", "0:0"},
    pants = {"32:0", "0:0", "0:0", "0:0", "0:0", "0:0", "0:0", "32:16", "0:0", "16:0", "0:0", "0:0"},
    shorts = {"32:0", "0:0", "0:0", "0:0", "0:0", "0:0", "0:0", "32:16", "0:0", "16:0", "0:0"},
    socks = {"32:-16", "0:0", "16:0", "0:0", "0:0", "0:0", "0:0", "0:0", "0:0", "0:0", "32:0"},
}

-- armor texture color variations. values follow formatting of 'colorizehsl' texture
-- modifier, <hue -180 to +180>:<saturation 0 to 100>:<lightness -100 to +100>
ss.ARMOR_COLORS = {
    feet_fiber_1 = {"40:40:0", "20:40:-16", "56:32:-40", "32:40:-48"},
    feet_fiber_2 = {"40:40:0", "20:40:-16", "56:32:-40", "32:40:-48"},

    head_cloth_2 = {"30:30:-30", "0:70:-50", "120:45:-50", "-130:35:-30", "0:0:32", "0:0:-32", "0:0:-64"},
    face_cloth_1 = {"30:20:-20", "0:70:-50", "120:45:-50", "-130:35:-30", "0:0:32", "0:0:-32", "0:0:-64"},
    face_cloth_2 = {"45:10:-10", "0:0:-64", "0:70:-50", "120:45:-50", "-130:35:-30", "0:0:32", "0:0:-32"},
    feet_cloth_2 = {"45:15:-15", "0:0:32", "0:0:-32", "0:0:-68", "0:70:-50", "120:45:-50", "-130:35:-30"},

    head_wood_1 = {"40:40:0", "20:40:-16", "56:32:-40", "32:40:-48"},
    chest_wood_1 = {"40:40:0", "20:40:-16", "56:32:-40", "32:40:-48"},
    arms_wood_1 = {"40:40:0", "20:40:-16", "56:32:-40", "32:40:-48"},
    legs_wood_1 = {"40:40:0", "20:40:-16", "56:32:-40", "32:40:-48"},

    head_leather_1 = {"32:40:-48", "40:40:-35", "20:40:-35", "36:40:-70"},
    head_leather_2 = {"36:40:-70", "32:40:-48", "40:40:-35", "20:40:-35"},
    chest_leather_1 = {"32:40:-48", "40:40:-35", "20:40:-35", "36:40:-70"},
    arms_leather_1 = {"32:40:-48", "40:40:-35", "20:40:-35", "36:40:-70"},
    legs_leather_1 = {"32:40:-48", "40:40:-35", "20:40:-35", "36:40:-70"},
    feet_leather_1 = {"36:40:-70", "32:40:-48", "40:40:-35", "20:40:-35"},
}

-- armor texture contrast variations. values follow formatting of 'contrast' texture
-- modifier, <contrast 127 to +127>:<brightness -127 to +127>
ss.ARMOR_CONTRASTS = {
    feet_fiber_1 = {"0:0", "0:0", "0:0", "0:0"},
    feet_fiber_2 = {"0:0", "0:0", "0:0", "0:0"},

    head_cloth_2 = {"16:-16", "0:0", "0:0", "0:0", "16:16", "0:0", "0:0"},
    face_cloth_1 = {"8:0", "0:0", "0:0", "0:0", "16:16", "0:0", "0:0"},
    face_cloth_2 = {"16:0", "0:0", "0:0", "0:0", "0:0", "60:0", "0:0"},
    feet_cloth_2 = {"32:8", "64:0", "0:0", "0:0", "32:0", "0:0", "0:0"},

    head_wood_1 = {"0:0", "0:0", "0:0", "0:0"},
    chest_wood_1 = {"0:0", "0:0", "0:0", "0:0"},
    arms_wood_1 = {"0:0", "0:0", "0:0", "0:0"},
    legs_wood_1 = {"0:0", "0:0", "0:0", "0:0"},

    head_leather_1 = {"0:0", "0:0", "0:0", "0:0"},
    head_leather_2 = {"0:0", "0:0", "0:0", "0:0"},
    chest_leather_1 = {"0:0", "0:0", "0:0", "0:0"},
    arms_leather_1 = {"0:0", "0:0", "0:0", "0:0"},
    legs_leather_1 = {"0:0", "0:0", "0:0", "0:0"},
    feet_leather_1 = {"0:0", "0:0", "0:0", "0:0"},
}


--[[ indexed by node name, the values represent the items that are dropped when the
node in question has another node placed right on its position, 'flattening' it, as
these nodes tend to be small plantlife like mushrooms and small grasses. this table
is initialized from the 'variables initialization' section of this file and reads in
data from node_drops_flattened.txt --]]
ss.NODE_DROPS_FLATTENED = {}

--[[ The 'cook_progress' value that must be reached before an item is finished
cooking and transforms into its cooked variant. --]]
ss.COOK_THRESHOLD = 10000

--[[ Items that can be worn out starts with this value as its initial 'condition'.
Its condition is reduced as its worn. Once it reaches 0, it is destroyed. --]]
ss.WEAR_VALUE_MAX = 10000


--[[ This table lists all items that can receive wear and thus be destroyed once
its 'condition' property reaches zero. The corresponding value represents the result
item it converts to when it is destroyed. --]]
ss.ITEM_DESTRUCT_PATH = {
    ["ss:campfire_stand_wood"] = { "ss:scrap_wood 6" },
    ["ss:campfire_grill_wood"] = { "ss:scrap_wood 2" },
    ["ss:fire_drill"] = { "ss:scrap_wood 2" },

	["ss:cup_wood"] = { "ss:scrap_wood" },
    ["ss:cup_wood_water_murky"] = { "ss:scrap_wood" },
    ["ss:cup_wood_water_boiled"] = { "ss:scrap_wood" },
    ["ss:bowl_wood"] = { "ss:scrap_wood 2" },
    ["ss:bowl_wood_water_murky"] = { "ss:scrap_wood 2" },
    ["ss:bowl_wood_water_boiled"] = { "ss:scrap_wood 2" },
    ["ss:jar_glass"] = { "ss:scrap_glass" },
    ["ss:jar_glass_water_murky"] = { "ss:scrap_glass" },
    ["ss:jar_glass_water_boiled"] = { "ss:scrap_glass" },
    ["ss:jar_glass_lidless"] = { "ss:scrap_glass" },
    ["ss:jar_glass_lidless_water_murky"] = { "ss:scrap_glass" },
    ["ss:jar_glass_lidless_water_boiled"] = { "ss:scrap_glass" },
    ["ss:pot_iron"] = { "ss:scrap_iron 2" },
    ["ss:pot_iron_water_murky"] = { "ss:scrap_iron 2" },
    ["ss:pot_iron_water_boiled"] = { "ss:scrap_iron 2" },

    -- first result item is placed in wield slot. any subsequent items are dropped
    -- to the ground. result items may have quantity > 1. refer to 'after_use_tool()'
    -- defined in tool_overrides.lua.
    ["ss:hammer_wood"] = { "ss:scrap_wood" },
    ["default:axe_stone"] = { "ss:scrap_wood", "ss:stone" },
    ["default:pick_stone"] = { "ss:scrap_wood", "ss:stone" },
    ["default:sword_stone"] = { "ss:scrap_wood", "ss:stone" },
    --["default:shovel_stone"] = { "ss:scrap_wood", "ss:stone" }
}


--[[ This table lists items that have limited uses or have consumable contents. Empty
containers are not included here since there is no content to be consumed. Once this
value reaches zero, the item is destroyed or converts to its empty variant. --]]
ss.ITEM_MAX_USES = {
    -- campfire
	["ss:fire_drill"] = 10,
	["ss:match_book"] = 20,
    -- food containers
    ["ss:cup_wood_water_murky"] = 2,
    ["ss:cup_wood_water_boiled"] = 2,
    ["ss:bowl_wood_water_murky"] = 3,
    ["ss:bowl_wood_water_boiled"] = 3,
    ["ss:jar_glass_lidless_water_murky"] = 3,
    ["ss:jar_glass_lidless_water_boiled"] = 3,
    ["ss:jar_glass_water_murky"] = 3,
    ["ss:jar_glass_water_boiled"] = 3,
    ["ss:pot_iron_water_murky"] = 6,
    ["ss:pot_iron_water_boiled"] = 6,
    -- food
    ["ss:apple"] = 3,
    ["ss:apple_dried"] = 3,
    ["ss:blueberries"] = 1,
    ["ss:blueberries_dried"] = 1,
    ["ss:mushroom_brown"] = 1,
    ["ss:mushroom_brown_dried"] = 1,
    ["ss:mushroom_red"] = 1,
    ["ss:mushroom_red_dried"] = 1,
    ["ss:cactus"] = 6,
    ["ss:cactus_dried"] = 5,
    -- medical
    ["ss:bandages_basic"] = 3,
    ["ss:bandages_medical"] = 3,
    ["ss:pain_pills"] = 1,
    ["ss:health_shot"] = 1,
    ["ss:first_aid_kit"] = 1,
    ["ss:splint"] = 1,
    ["ss:cast"] = 1,
}


-- the longest duration in seconds before a wielded item can be swung for
-- maximum damage effect
ss.HIT_COOLDOWN_MAX = 4

--[[ The max number of inventory slots that can ever display during gameplay.
Must be greater than INV_SIZE_MIN and must be multiples of 8. --]]
ss.INV_SIZE_MAX = 48

--[[ The minimum number of inventory slots possible during gameplay. Must
be at least 8 because that's the size of the hotbar. Cannot be higher
than INV_SIZE_MAX. --]]
ss.INV_SIZE_MIN = 8

--[[ Must be between INV_SIZE_MIN and INV_SIZE_MAX inclusively. Controls
how many inventory slots are shown at the start of a new game. If this
value is greater than INV_SIZE_MAX, players can pickup more items than
there are inventory slots, which will cause those items to be inaccessible.
--]]
ss.INV_SIZE_START = 24

--[[ this value is used to calculate the total max weight capacity for the player
inventory, based on how many inventory slots the player current has. example, if
player has 32 inventory slots and SLOT_WEIGHT_MAX is 100, then the inventory weight
max is 32 slots x 100 max per slot = 3200 max weight.
--]]
ss.SLOT_WEIGHT_MAX = 100

-- Default colorization properties within the formspec slots
ss.SLOT_COLOR_BG = "#00000080"
ss.SLOT_COLOR_HOVER = "#22222280"
ss.SLOT_COLOR_BORDER = "#33333380"

-- Default tooltip colorization properties within formspecs tooltips
ss.TOOLTIP_COLOR_BG = "#000000"
ss.TOOLTIP_COLOR_TEXT = "#FFFFFF"

--[[ The main player inventory formspec ui is grouped into left, center, and right
sections. these x pos offsets help align formspec elements to these sections. --]]
ss.X_OFFSET_LEFT = 0.0 -- left pane
ss.X_OFFSET_CENTER = 6.5 -- center pane
ss.X_OFFSET_RIGHT = 16.3 -- right pane


--[[ Holds all the hud_ids from hud_add() for each player so it can be retrieved
later calls to update_hud() and hud_remove(). table is indexed by player_name.
Example:
{
<player_name> = {
    notify_box_3 = 5,
    screen_effect = 6,
    mob_hud_name = 36,
    current_time = 8,
    mob_hud_bg = 37,
    health = { bar = 13 },
    mob_hud = 38,
    notify_box_3_bg = 4,
    current_day = 7
}
--]]
ss.player_hud_ids = {}

--[[ Holds a list of player names currently viewing a node formspec, like a campfire,
storage, etc. Table is indexed by a string pos key from pos_to_key(). This helps
ensure that if an event or action requires the formspec to be refreshed or closed,
that this result is propogated to all current viewers of that formspec.
Example:
{
    [100,15,550] = {"player1", "player2"},
    [25000,-20,000,-30000] = {"admin"},
    [-123,-200,321] = {},
}
--]]
ss.formspec_viewers = {}

--[[ Holds all the player specific properties indexed by player name. Includes
data relating to the player model textures and full inventory formspec. Most of
these properties are also saved in the player metadata in order to be persistent
between game restarts. Player stats data like health, stamina, hunger, etc. is
currently not stored here and relies on player metadata as the storege medium.
Example:
{
<player_name> = {
    speed_walk = 1,
    height_jump = 1,
    player_level = 1,
    player_skill_points = 0,
    avatar_texture_base = ""
    avatar_texture_skin = "",
    fs = ""
}
--]]
ss.player_data = {}

--[[ Holds the core.after() job handles relating to notification text huds, item
use cooldown huds, and breath monitor loop, that are still active and waiting to
execute. the handles are used to cancel the core.after() process when needed. Example:
{
    [player_name_1] = {
        notify_box_1 = <job_handle_ref>,
        notify_box_2 = <job_handle_ref>,
        cooldown_action = <job_handle_ref>,
        monitor_underwater_status = <job_handle_ref>,
    },
    [player_name_2] = {
        notify_box_2 = <job_handle_ref>,
        notify_box_3 = <job_handle_ref>,
        cooldown_ingest = <job_handle_ref>,
        monitor_underwater_status = <job_handle_ref>,
    }
}
--]]
ss.job_handles = {}

-- holds booleans indicating whether or not a certain cooldown type is currently in
-- effect for a player after consuming an item. cooldown types: 'ingest', 'action', etc.
-- indexed by player name. example: is_cooldown_active[player_name][cooldown_type] 
ss.is_cooldown_active = {}

--[[ Holds the the sound handle returned by function core.sound_play(). Indexed
by a unique pos based id. For example, this relates to the looping flame sounds
when a campfire is started. This handle is later used when calling api functions
to stop or fade the sound effect. So this table useful when multiple campfires are
playing their looping flame sounds. --]]
ss.sound_handles = {}

--[[ A table used by allow_metadata_inventory_take() from itemdrop_bag.lua and
by core.spawn_item() from api_overrides.lua to ensure the item taken from the
itemdrop bag is dropped at the bag's location and NOT at the player's location.
Table is indexed by a pos hash via core.hash_node_position() based on player's
current pos to ensure table data is unique to each player. Example:
{
    <pos_hash_1> = {x = 100, y = 10, z = 100},
    <pos_hash_2> = {x = 200, y = 20, z = 200},
    <pos_hash_3> = {x = 300, y = 30, z = 300},
}
-]]
ss.itemdrop_bag_pos = {}
