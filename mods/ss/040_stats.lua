print("- loading stats.lua")

-- cache global functions for faster access
local math_random = math.random
local math_round = math.round
local mt_after = core.after
local mt_get_node = core.get_node
local mt_serialize = core.serialize
local mt_deserialize = core.deserialize
local mt_pos_to_string = core.pos_to_string
local mt_add_item = core.add_item
local debug = ss.debug
local round = ss.round
local notify = ss.notify
local build_fs = ss.build_fs
local get_fs_player_stats = ss.get_fs_player_stats
local get_fs_weight = ss.get_fs_weight
local update_fs_weight = ss.update_fs_weight
local get_itemstack_weight = ss.get_itemstack_weight
local play_sound = ss.play_sound
local update_player_physics = ss.update_player_physics
local convert_to_celcius = ss.convert_to_celcius

-- cache global variables for faster access
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local GAMEDAY_IRL_SECONDS = ss.GAMEDAY_IRL_SECONDS
local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids
local job_handles = ss.job_handles
local mod_storage = ss.mod_storage

-- foward-declare functions
ss.update_stat = nil
local update_stat = ss.update_stat


-- refers to buffs like hunger drain, thrist drain, and stamina restore, that is normally
-- always active and constantly depleting/restoring the stat during gameplay
ALLOW_PERPETUAL_THIRST_DRAIN = true
ALLOW_PERPETUAL_HUNGER_DRAIN = true
ALLOW_PERPETUAL_ALERTNESS_DRAIN = true

-- periodically checks if player is underwater and then displays/hides breath statbar
-- depending on the player's underwater status
ss.ENABLE_UNDERWATER_CHECK = true
local ENABLE_UNDERWATER_CHECK = ss.ENABLE_UNDERWATER_CHECK

-- periodically does a random roll which determines if an immunity effect is triggered
local ENABLE_IMMUNITY_MONITOR = true

local ENABLE_STATUS_EFFECTS_MONITOR = true


local STAT_NAMES = {"health", "thirst", "hunger", "alertness", "hygiene", "comfort",
    "immunity", "sanity", "happiness", "breath", "stamina", "experience", "weight"}

-- default initial values for player stats. stored in the player metadata as
-- '<stat>_current', for example: 'health_current'
ss.DEFAULT_STAT_START = {
    health = 100,
    thirst = 80,
    hunger = 80,
    alertness = 80,
    hygiene = 80,
    comfort = 80,
    immunity = 80,
    sanity = 80,
    happiness = 80,
    breath = 100,
    stamina = 100,
    experience = 0,
    weight = 0
}
local DEFAULT_STAT_START = ss.DEFAULT_STAT_START


-- default maximum values for player stats. stored in the player metadata as
-- '<stat>_max', for example: 'health_max'
ss.DEFAULT_STAT_MAX = {
    health = 100,
    thirst = 100,
    hunger = 100,
    alertness = 100,
    hygiene = 100,
    comfort = 100,
    immunity = 100,
    sanity = 100,
    happiness = 100,
    breath = 100,
    stamina = 100,
    experience = 100,
    weight = ss.SLOT_WEIGHT_MAX * ss.INV_SIZE_START
}
local DEFAULT_STAT_MAX = ss.DEFAULT_STAT_MAX

-- the assigned color for all statbars
local STATBAR_COLORS = {
    health = "#C00000",         -- darker red
    hunger = "#C08000",         -- darker orange
    thirst = "#0080C0",         -- light blue
    alertness = "#9F51B6",      -- purple
    hygiene = "#51bfc0",        -- light tan
    comfort = "#906f25",        -- brown
    immunity = "#CCFFFF",       -- bluish white
    sanity = "#E15079",         -- dark pink
    happiness = "#d2c023",      -- yellow
    breath = "#FFFFFF",         -- white
    stamina = "#00C000",         -- green
    experience = "#6551b6",     -- darker purple
    weight = "#C0C000"         -- yellow
}


-- the percentage increase to the max experience value to gain each level. for example,
-- 0.20 = 20% increase on the required xp for each level.
local XP_MAX_GROWTH_RATE = 0.20

-- height of the vertial player statbars as shown at the bottom left of screeen
local STATBAR_HEIGHT = 100

-- width of the vertial player statbars as shown at the bottom left of screeen
local STATBAR_WIDTH = 20

-- height of the mini vertial statbars relating to the breath and weight bars
local STATBAR_HEIGHT_MINI = 62

-- width of the mini vertial statbars relating to the breath and weight bars
local STATBAR_WIDTH_MINI = 14

-- height of the horizontal stamina bar
local STAMINA_BAR_HEIGHT = 16

-- width of the horizontal stamina bar
local STAMINA_BAR_WIDTH = 448

-- height of the horizontal experience bar
local EXPERIENCE_BAR_HEIGHT = 8

-- width of the horizontal experience bar
local EXPERIENCE_BAR_WIDTH = 448

-- hud properties of the main vertical statbars (health, hunger, thirst, etc)
local y_pos = -27

-- x offsets for the huds relating to the main vertical stat bars
local vertical_statbar_x_pos = { 20, 50, 80, 110, 140, 170, 200, 230, 260 }

-- horizontal position of all vertical statbars (does not apply to experience statbar)
local horizontal_statbar_x_pos = {
    breath = -245,
    weight = 245
}

local y_pos_breath = -24

-- the possible colors of the transparent background behind the stat effect images
local STAT_EFFECT_BG_COLOR_BLACK = "#000000"
local STAT_EFFECT_BG_COLOR_RED = "#AA0000"
local STAT_EFFECT_BG_COLOR_GREEN = "#00AA00"

-- the possible colors of the stat effect text, indexed by the severity level of
-- the stat effect.
local STAT_EFFECT_TEXT_COLORS = {
    "0xFFA800", -- low level, orange
    "0xFF0000", -- serious level, red
    "0xFFFFFF", -- critical level, white
}

-- used to calculate the size of the transparent bg behind the stat effect iamges
local STAT_EFFECT_BG_HEIGHT = 32
local STAT_EFFECT_BG_WIDTH = 59
local STAT_EFFECT_BG_WIDTH_EXTRA = 8


-- the amount of time in seconds it will take for a player with full health to be
-- reduced to zero health by the corresponding stat effect name. so a value of '20'
-- will cause player death after 20 seconds, or sooner if player has less than full
-- health. "HP_ZERO_TIME_<stat effect name>"
local HP_ZERO_TIME_BREATH_3 = 20

-- the amount of health that is reduced or recovered per second when the corresponding
-- stat effect name is activated or stopped. "HP_DRAIN_VAL_<stat effect name>"
local HP_DRAIN_VAL_THIRST_3 = 0.01
local HP_DRAIN_VAL_HUNGER_3 = 0.005
local HP_DRAIN_VAL_WEIGHT_3 = 0.1
ss.HP_DRAIN_VAL_HOT_3 = 0.5
local HP_DRAIN_VAL_HOT_3 = ss.HP_DRAIN_VAL_HOT_3
ss.HP_DRAIN_VAL_HOT_4 = 1.0
local HP_DRAIN_VAL_HOT_4 = ss.HP_DRAIN_VAL_HOT_4
ss.HP_DRAIN_VAL_COLD_3 = 0.5
local HP_DRAIN_VAL_COLD_3 = ss.HP_DRAIN_VAL_COLD_3
ss.HP_DRAIN_VAL_COLD_4 = 1.0
local HP_DRAIN_VAL_COLD_4 = ss.HP_DRAIN_VAL_COLD_4

-- the percentage of the total accumulated hp drain amount that is actually recoverable
-- when the originating status effect is stopped. for example, 0.5 = 50%
local HP_REC_FACTOR_THIRST = 0.70
local HP_REC_FACTOR_HUNGER = 0.70
local HP_REC_FACTOR_BREATH = 0.80
local HP_REC_FACTOR_WEIGHT = 0.60
local HP_REC_FACTOR_HOT = 0.70
local HP_REC_FACTOR_COLD = 0.70

-- the amount of comfort that is reduced or recovered per second when the corresponding
-- stat effect name is activated or stopped. "COMFORT_DRAIN_VAL_<stat effect name>"
local COMFORT_DRAIN_VAL_HEALTH_1 = 0.03
local COMFORT_DRAIN_VAL_HEALTH_2 = 0.06
local COMFORT_DRAIN_VAL_THIRST_3 = 0.03
local COMFORT_DRAIN_VAL_HUNGER_3 = 0.03
local COMFORT_DRAIN_VAL_HYGIENE_1 = 0.03
local COMFORT_DRAIN_VAL_HYGIENE_2 = 0.06
local COMFORT_DRAIN_VAL_HYGIENE_3 = 0.12
local COMFORT_DRAIN_VAL_BREATH_1 = 0.03
local COMFORT_DRAIN_VAL_BREATH_2 = 0.06
local COMFORT_DRAIN_VAL_BREATH_3 = 0.12
local COMFORT_DRAIN_VAL_STAMINA_1 = 0.03
local COMFORT_DRAIN_VAL_STAMINA_2 = 0.06
local COMFORT_DRAIN_VAL_STAMINA_3 = 0.12
local COMFORT_DRAIN_VAL_WEIGHT_1 = 0.03
local COMFORT_DRAIN_VAL_WEIGHT_2 = 0.06
local COMFORT_DRAIN_VAL_WEIGHT_3 = 0.12

ss.COMFORT_DRAIN_VAL_HOT_2 = 0.03
local COMFORT_DRAIN_VAL_HOT_2 = ss.COMFORT_DRAIN_VAL_HOT_2
ss.COMFORT_DRAIN_VAL_HOT_3 = 0.06
local COMFORT_DRAIN_VAL_HOT_3 = ss.COMFORT_DRAIN_VAL_HOT_3
ss.COMFORT_DRAIN_VAL_HOT_4 = 0.12
local COMFORT_DRAIN_VAL_HOT_4 = ss.COMFORT_DRAIN_VAL_HOT_4
ss.COMFORT_DRAIN_VAL_COLD_1 = 0.02
local COMFORT_DRAIN_VAL_COLD_1 = ss.COMFORT_DRAIN_VAL_COLD_1
ss.COMFORT_DRAIN_VAL_COLD_2 = 0.04
local COMFORT_DRAIN_VAL_COLD_2 = ss.COMFORT_DRAIN_VAL_COLD_2
ss.COMFORT_DRAIN_VAL_COLD_3 = 0.08
local COMFORT_DRAIN_VAL_COLD_3 = ss.COMFORT_DRAIN_VAL_COLD_3
ss.COMFORT_DRAIN_VAL_COLD_4 = 0.12
local COMFORT_DRAIN_VAL_COLD_4 = ss.COMFORT_DRAIN_VAL_COLD_4

-- the percentage of the total accumulated comfort drain amount that is actually
-- recoverable when the originating status effect is stopped. for example, 0.9 = 90%
local COMFORT_REC_FACTOR_HEALTH = 0.70
local COMFORT_REC_FACTOR_THIRST = 0.70
local COMFORT_REC_FACTOR_HUNGER = 0.70
local COMFORT_REC_FACTOR_HYGIENE = 1.0
local COMFORT_REC_FACTOR_BREATH = 0.8
local COMFORT_REC_FACTOR_STAMINA = 1.0
local COMFORT_REC_FACTOR_WEIGHT = 0.60
local COMFORT_REC_FACTOR_HOT = 0.70
local COMFORT_REC_FACTOR_COLD = 0.70


-- 'INTERNAL_STAT_EFFECTS' table holds the stat effect names that result from stats
-- getting low or depleted. currently this table is used only to differentiate between
-- 'internal' and 'external' stat effects. the number next to each stat name relates
-- to the severity of the stat depletion. 1 = 25% remain, 2 = 10% remain, 3 = all gone.
--[[ Example:
{
    health_1 = true,
    health_2 = true,
    health_3 = true,
    thirst_1 = true,
    thirst_2 = true,
    thirst_3 = true,
    hunger_1 = true,
    hunger_2 = true,
    hunger_3 = true,
    immunity_1 = true,
    immunity_2 = true,
    immunity_3 = true,
    etc..
}
--]]
ss.INTERNAL_STAT_EFFECTS = {}
local INTERNAL_STAT_EFFECTS = ss.INTERNAL_STAT_EFFECTS

-- initialize the INTERNAL_STAT_EFFECTS table above. below are the player stats
-- that can trigger an 'internal stat effect' if its value drops too low or is
-- deplemeted. this includes most of the stats except for 'experience'
local stat_effectable_stats = {
    "health", "thirst", "hunger", "immunity", "alertness", "sanity",
    "hygiene", "comfort", "happiness", "stamina", "breath", "weight"
}
for i, stat_name in ipairs(stat_effectable_stats) do
    for j = 1, 3 do
        INTERNAL_STAT_EFFECTS[stat_name .. "_" .. j] = true
    end
end


-- the text shown next to the hud image of an 'infinite' status effect. currently
-- an infinite status effect triggers only when a player stat is completely depleted
-- to zero. or in the case of the 'weight' stat, when it reaches max value.
local STAT_EFFECT_HUD_LABELS = {
    health = "dead",
    thirst = "dehydrated",
    hunger = "starving",
    alertness = "sleepy",
    hygiene = "filthy",
    comfort = "uncomfortable",
    immunity = "sickly",
    sanity = "psychotic",
    happiness = "depressed",
    breath = "suffocating",
    stamina = "exhuasted",
    weight = "too heavy",
}


local STAT_EFFECT_TEXTS = {
    health_1_up = "health is low",
    health_2_up = "health is critical",
    health_3_up = "you are dead",
    --health_2_down = "health still critical", -- this condition not possible
    health_1_down = "health still low",
    health_0_down = "heath is better",

    thirst_1_up = "feeling a bit thirsty",
    thirst_2_up = "feeling very thirsty",
    thirst_3_up = "completely dehydrated",
    thirst_2_down = "still very thirsty",
    thirst_1_down = "still a bit thirsty",
    thirst_0_down = "not so thirsty anymore",

    hunger_1_up = "feeling a bit hungry",
    hunger_2_up = "feeling very hungry",
    hunger_3_up = "completely starving",
    hunger_2_down = "still very hungry",
    hunger_1_down = "still a bit hungry",
    hunger_0_down = "not so hungry anymore",

    alertness_1_up = "getting a bit sleepy",
    alertness_2_up = "getting very sleepy",
    alertness_3_up = "fighting to stay awake",
    alertness_2_down = "still very sleepy",
    alertness_1_down = "still a bit sleepy",
    alertness_0_down = "feeling more awake now",

    hygiene_1_up = "getting a bit dirty",
    hygiene_2_up = "getting a bit smelly",
    hygiene_3_up = "completely dirty and stinky",
    hygiene_2_down = "still a bit smelly",
    hygiene_1_down = "still a bit dirty",
    hygiene_0_down = "feeling cleaner now",

    comfort_1_up = "feeling a bit tense",
    comfort_2_up = "feeling restless",
    comfort_3_up = "completely uncomfortable",
    comfort_2_down = "still a bit restless",
    comfort_1_down = "still a bit tense",
    comfort_0_down = "feeling more comfortable now",

    immunity_1_up = "feeling a bit week",
    immunity_2_up = "feeling very weak",
    immunity_3_up = "severely weak and sickly",
    immunity_2_down = "still very weak",
    immunity_1_down = "still a bit weak",
    immunity_0_down = "feeling healthier",

    sanity_1_up = "feeling a bit unsettled",
    sanity_2_up = "feeling more crazy",
    sanity_3_up = "completely psychotic",
    sanity_2_down = "still feeling crazy",
    sanity_1_down = "still a bit unsettled",
    sanity_0_down = "feeling more stable now",

    happiness_1_up = "feeling a bit down",
    happiness_2_up = "feeling sad",
    happiness_3_up = "completely depressed",
    happiness_2_down = "still a bit sad",
    happiness_1_down = "still a bit down",
    happiness_0_down = "feeling happier now",

    breath_1_up = "need a breath soon",
    breath_2_up = "can't hold much longer",
    breath_3_up = "suffocating",
    breath_2_down = "still need a breath soon",
    breath_1_down = "still need a breath soon",
    breath_0_down = "breath level is bearable",

    stamina_1_up = "getting a bit tired",
    stamina_2_up = "getting exhausted",
    stamina_3_up = "completely exhausted",
    stamina_2_down = "still exhausted",
    stamina_1_down = "still a bit tired",
    stamina_0_down = "energy level is better",

    weight_1_up = "feeling the weight a bit",
    weight_2_up = "weight is getting heavy",
    weight_3_up = "weight is extremely heavy",
    weight_2_down = "weight still a bit heavy",
    weight_1_down = "weight is bearable",
    weight_0_down = "weight is much better",
}


-- converts seconds to a string format "xxh xxm xxs", of hours, minutes, and seconds
function ss.convert_seconds(time)
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time % 3600) / 60)
    local seconds = time % 60
    local result = ""
    if hours > 0 then
        result = result .. hours .. "h"
    end
    if minutes > 0 then
        if result ~= "" then
            result = result .. " "
        end
        result = result .. minutes .. "m"
    end
    if seconds > 0 then
        if result ~= "" then
            result = result .. " "
        end
        result = result .. seconds .. "s"
    end
    return result
end
local convert_seconds = ss.convert_seconds


--- @param player ObjectRef the player object
--- @param player_name string the player's name
-- displays a hud element icon representing the stat, and the hud element
-- image representing the bar background for the stamina stat bar.
local function initialize_hud_breath(player, player_name)
    local hud_definition

    -- stat bar values are updated to their 'live' in-game values after this function
    player_hud_ids[player_name].breath = {}

    -- black statbar background
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.breath, y = y_pos_breath},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = 0, y = 0},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name].breath.bg = player:hud_add(hud_definition)

    -- statbar icon
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.breath, y = y_pos + 28},
        text = "ss_statbar_icon_breath.png",
        scale = {x = 0, y = 0},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name].breath.icon = player:hud_add(hud_definition)

    -- main colored stat bar
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.breath, y = y_pos_breath},
        text = "[fill:1x1:0,0:" .. STATBAR_COLORS.breath,
        scale = {x = 0, y = 0},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name].breath.bar = player:hud_add(hud_definition)

end


--- @param player ObjectRef the player object
--- @param player_name string the player's name
-- displays a hud element icon representing the stat, and the hud element
-- image representing the bar background for the weight stat bar.
local function initialize_hud_weight(player, player_name)
    local hud_definition

    -- stat bar values are updated to their 'live' in-game values after this function
    player_hud_ids[player_name].weight = {}

    -- black statbar background
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.weight, y = y_pos_breath},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = STATBAR_WIDTH_MINI, y = STATBAR_HEIGHT_MINI},
        alignment = {x = 0, y = -1}
    }
    player:hud_add(hud_definition)

    -- statbar icon
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.weight, y = y_pos + 24},
        text = "ss_statbar_icon_weight.png",
        scale = {x = 1.3, y = 1.3},
        alignment = {x = 0, y = -1}
    }
    player:hud_add(hud_definition)

    -- main colored stat bar
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.weight, y = y_pos_breath},
        text = "[fill:1x1:0,0:" .. STATBAR_COLORS.weight,
        scale = {x = STATBAR_WIDTH_MINI - 5, y = 0},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name].weight.bar = player:hud_add(hud_definition)

end


--- @param player ObjectRef the player object
--- @param player_name string the player's name
-- displays a hud element icon representing the stat, and the hud element
-- image representing the bar background for the stamina stat bar.
local function initialize_hud_stamina(player, player_name)
    -- black bg bar for stamina stat
    player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = -224, y = -70},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = STAMINA_BAR_WIDTH, y = STAMINA_BAR_HEIGHT},
        alignment = {x = 1, y = -1}
    })

    -- initialize table to store hud_ids related to 'stamina' stat
    player_hud_ids[player_name].stamina = {}

    -- main stamina bar
    player_hud_ids[player_name].stamina.bar = player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = -224, y = -70},
        text = "[fill:1x1:0,0:" .. STATBAR_COLORS.stamina,
        scale = {x = 0, y = STAMINA_BAR_HEIGHT},
        alignment = {x = 1, y = -1}
    })
end


--- @param player ObjectRef the player object
--- @param player_name string the player's name
-- displays a hud element icon representing the stat, and the hud element
-- image representing the bar background for the expereience stat bar.
local function initialize_hud_experience(player, player_name)
    -- black bg bar for experience stat
    player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = -224, y = -62},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = EXPERIENCE_BAR_WIDTH, y = EXPERIENCE_BAR_HEIGHT},
        alignment = {x = 1, y = -1}
    })

    -- initialize table to store hud_ids related to 'experience' stat
    player_hud_ids[player_name].experience = {}

    -- main experience bar
    player_hud_ids[player_name].experience.bar = player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = -224, y = -62},
        text = "[fill:1x1:0,0:" .. STATBAR_COLORS.experience,
        scale = {x = 0, y = EXPERIENCE_BAR_HEIGHT},
        alignment = {x = 1, y = -1}
    })
end


local flag7 = false
function ss.initialize_hud_stats(player, player_name, stat, stat_data, stat_value_current)
    debug(flag7, "    initialize_hud_stats()")

    local hud_position = stat_data.hud_pos
    local hud_definition
    debug(flag7, "      statbar: " .. stat)

    -- stat bar values are updated to real values after this function
    player_hud_ids[player_name][stat] = {}

    debug(flag7, "        setting black background for statbar")
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = vertical_statbar_x_pos[hud_position], y = y_pos - 5},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = STATBAR_WIDTH, y = STATBAR_HEIGHT},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name][stat].bg = player:hud_add(hud_definition)

    debug(flag7, "        setting stat icon image for statbar")
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = vertical_statbar_x_pos[hud_position], y = y_pos + 22},
        text = "ss_statbar_icon_" .. stat .. ".png",
        scale = {x = 1.3, y = 1.3},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name][stat].icon = player:hud_add(hud_definition)

    debug(flag7, "        setting the main colored stat bar")
    local stat_bar_value
    if stat_value_current then
        local player_meta = player:get_meta()
        local stat_value_max = player_meta:get_float(stat .. "_max")
        stat_bar_value = (stat_value_current / stat_value_max) * STATBAR_HEIGHT
    else
        stat_bar_value = 1
    end
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = vertical_statbar_x_pos[hud_position], y = y_pos - 5},
        text = "[fill:1x1:0,0:" .. STATBAR_COLORS[stat],
        scale = {x = STATBAR_WIDTH - 6, y = stat_bar_value},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name][stat].bar = player:hud_add(hud_definition)

    debug(flag7, "        player_hud_ids[player_name][stat]: " .. dump(player_hud_ids[player_name][stat]))
    debug(flag7, "    initialize_hud_stats() END")
end
local initialize_hud_stats = ss.initialize_hud_stats



local flag2 = false
local function initialize_hud_stat_effects(player, player_name, p_data)
    debug(flag2, "  initialize_hud_stat_effects()")

    -- the statbars that currently cannot be changed from the Settings tab: breath,
    -- stamina, and weight. 'experience' is not included since it does not trigger
    -- any stat effects
    local unmodifiable_statbars = 3

    -- thermal status (hot, cold, freezing, sweltering, etc)
    local external_stat_effects = 1

    -- this is the total number of status effect hud images that can be on-screeen
    -- at once. this accounts for stat effects relating to each main vertical statbar
    -- that appears on bottom left of screen
    local on_screen_max = p_data.total_statbar_count + unmodifiable_statbars + external_stat_effects
    debug(flag2, "    on_screen_max: " .. on_screen_max)

    local y_increment = 40
    local y_offset = 130
    for i = 1, on_screen_max do

        -- colored transparent background behind each stat effect image and text.
        -- depending on the stat effect this color can be black, red, or green.
        -- the x scale (width) of this background is controlled by the length of
        -- the 'text' data from 'stat_effect_text_' hud element below.
        player_hud_ids[player_name]["stat_effect_bg_" .. i] = player:hud_add({
            type = "image",
            position = {x = 0, y = 1},
            alignment = {x = 1, y = 0},
            offset = {x = 0, y = i * -y_increment - y_offset},
            text = "[fill:1x1:0,0:#00000080",
            --scale = {x = 0, y = 0}
        })

        -- the image representing the stat effect. for internal stat effects, this
        -- is typically its corresponding statbar icon (heart, water droplet, etc),
        -- and for external stat effects it can be any image relating to that effect.
        player_hud_ids[player_name]["stat_effect_image_" .. i] = player:hud_add({
            type = "image",
            position = {x = 0, y = 1},
            alignment = {x = 1, y = 0},
            offset = {x = 3, y = i * -y_increment - y_offset},
            --text = "ss_statbar_icon_thirst.png",
            scale = {x = 1.8, y = 1.8}
        })

        -- the text shown to the right of the stat effect image, like a percentage
        -- value, countdown timer, or short description. the length of this text
        -- controls the x scale (width) of the 'stat_effect_bg_' hud element above.
        player_hud_ids[player_name]["stat_effect_text_" .. i] = player:hud_add({
            type = "text",
            position = {x = 0, y = 1},
            alignment = {x = 1, y = -1},
            offset = {x = 40, y = i * -y_increment - y_offset + 10},
            scale = {x = 20, y = 20},
            --text = "18.9%",
            --number = "0xffffff",
            style = 1
        })

    end

    debug(flag2, "  initialize_hud_stat_effects() END")
end


local flag29 = false
function ss.stop_stat_update(p_data, player_meta, id)
    debug(flag29, "\nstop_stat_update()")
    debug(flag29, "  id: " .. id)
    local stat_updates = p_data.stat_updates
    local update_data = stat_updates[id]
    update_data[4] = 0
    debug(flag29, "  iterations for " .. update_data[2] .. " set to zero")
    player_meta:set_string("stat_updates", mt_serialize(p_data.stat_updates))
    debug(flag29, "  stat_updates: " .. dump(stat_updates))
    debug(flag29, "stop_stat_update() END")
end
local stop_stat_update = ss.stop_stat_update


local flag3 = false
--- @param player ObjectRef the player object
--- @param player_meta MetaDataRef used to access the string metadata 'status_effect'
--- @param player_name string player's name. for single player it's 'singleplayer'
--- @param p_data table reference to table with data specific to this player
--- @param status_effects table table containing all active status effects data on the player
--- @param effect_name string the status effect being stopped
-- This function stops an existing status effect and removes its hud image and duration
-- fromt the screen. Hud images of other status effects still active are shifted downward
-- to occupy the empty spot.
function ss.hide_stat_effect(player, player_meta, player_name, p_data, status_effects, effect_name)
    debug(flag3, "\n      hide_stat_effect()")
    debug(flag3, "        effect_name: " .. effect_name)
    debug(flag3, "        status_effects (before): " .. dump(status_effects))
    local status_effect_count = p_data.status_effect_count
    local effect_data = status_effects[effect_name]
    local hud_location = effect_data[3]
    debug(flag3, "        status_effect_count: " .. status_effect_count)
    debug(flag3, "        hud_location: " .. hud_location)

    local stat_effects_to_move_count = status_effect_count - hud_location
    debug(flag3, "        stat_effects_to_move_count: " .. stat_effects_to_move_count)
    if stat_effects_to_move_count > 0 then
        debug(flag3, "        there are stat effects located above " .. effect_name)

        -- update stat effect hud elements
        for i = 1, stat_effects_to_move_count do
            local prev_location = hud_location + i
            local new_location = prev_location - 1

            local this_effect_name = p_data.stat_effect_hud_locations[prev_location]
            local type = status_effects[this_effect_name][1]
            local duration = status_effects[this_effect_name][2]
            debug(flag3, "          this_effect_name: " .. this_effect_name)

            local hud_id, prev_hud_def
            hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. prev_location]
            prev_hud_def = player:hud_get(hud_id)
            hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. new_location]
            player:hud_change(hud_id, "text", prev_hud_def.text)
            player:hud_change(hud_id, "scale", prev_hud_def.scale)
            debug(flag3, "          hud_def.text: " .. prev_hud_def.text)
            debug(flag3, "          hud_def.scale: " .. dump(prev_hud_def.scale))

            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. prev_location]
            prev_hud_def = player:hud_get(hud_id)
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. new_location]
            player:hud_change(hud_id, "text", prev_hud_def.text)
            debug(flag3, "          hud_def.text: " .. prev_hud_def.text)

            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. prev_location]
            prev_hud_def = player:hud_get(hud_id)
            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. new_location]
            player:hud_change(hud_id, "text", prev_hud_def.text)
            player:hud_change(hud_id, "number", prev_hud_def.number)
            debug(flag3, "          hud_def.text: " .. prev_hud_def.text)
            debug(flag3, "          hud_def.number: " .. prev_hud_def.number)

            status_effects[this_effect_name] = {type, duration, new_location}
            p_data.stat_effect_hud_locations[new_location] = this_effect_name
        end
    end

    debug(flag3, "        all stat effects now shifted downward. hiding the stopped stat effect..")
    local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. status_effect_count]
    player:hud_change(hud_id, "text", "")
    player:hud_change(hud_id, "scale", {x = 0, y = 0}) -- dummy default value
    hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
    player:hud_change(hud_id, "text", "")
    hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
    player:hud_change(hud_id, "text", "")
    player:hud_change(hud_id, "number", "0x000000") -- dummy default value

    -- remove the stopped stat effect name from the reverse lookup table
    p_data.stat_effect_hud_locations[status_effect_count] = nil
    player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))
    debug(flag3, "        stat_effect_hud_locations (updated): " .. dump(p_data.stat_effect_hud_locations))

    -- update active status effect count
    local new_effect_count = status_effect_count - 1
    p_data.status_effect_count = new_effect_count

    -- remove the status effect from the stat effect table
    status_effects[effect_name] = nil
    debug(flag3, "        status_effects (updated): " .. dump(status_effects))

    debug(flag3, "      hide_stat_effect() END")
end
local hide_stat_effect = ss.hide_stat_effect



local function get_unique_id()
    local id = tonumber(core.get_us_time() .. math.random(10, 99))
    if id then
        return id
    else
        return 0
    end
end



local flag14 = false
-- this function only handles the current stat value and does not modify the max value.
-- so there are no checks to ensure stat max values are within valid ranges.
local function do_immunity_effect_update_action(p_data, player_meta, effect_name, amount)
    debug(flag14, "            do_immunity_effect_update_action()")
    debug(flag14, "              effect_name: " .. effect_name)
    debug(flag14, "              amount: " .. amount)

    local immunity_effect_counter = p_data["ie_counter_" .. effect_name]
    debug(flag14, "              immunity_effect_counter: " .. immunity_effect_counter)

    immunity_effect_counter = immunity_effect_counter + amount

    -- only clamping negative values. positive values and go infinitely higher.
    if immunity_effect_counter < 0 then
        immunity_effect_counter = 0
    end
    p_data["ie_counter_" .. effect_name] = immunity_effect_counter
    player_meta:set_float("ie_counter_" .. effect_name, immunity_effect_counter)
    debug(flag14, "              immunity_effect_counter: " .. immunity_effect_counter)


    debug(flag14, "            do_immunity_effect_update_action() END")
end



local flag13 = false
--- @param player ObjectRef the player for which the stat will be modified
--- @param p_data table reference to table with data specific to this player
--- @param player_meta MetaDataRef used to access 'stat_updates' metadata
--- @param id number unique numerical id for this immunity effect update.
local function immunity_effect_update_loop(player, p_data, player_meta, id)
    debug(flag13, "\n          immunity_effect_update_loop()")
    if not player:is_player() then
        debug(flag13, "            player no longer exists. function skipped.")
        return
    end

    if p_data.stat_updates[id] == nil then
        debug(flag13, "            stat update was stopped")
        debug(flag13, "          immunity_effect_update_loop() END")
        return
    end

    local immunity_effect_data = p_data.stat_updates[id]
    local effect_name = immunity_effect_data[2]
    local amount = immunity_effect_data[3]
    local iterations = immunity_effect_data[4]
    local interval = immunity_effect_data[5]
    local timer = immunity_effect_data[6]
    debug(flag13, "            id[" .. id .. "] " .. string.upper(effect_name) .. ", amt " .. amount
        .. ", iter " .. iterations .. ", intv " .. interval .. ", timer " .. timer)

    if iterations > 0 then
        do_immunity_effect_update_action(p_data, player_meta, effect_name, amount)
        iterations = iterations - 1
        if iterations > 0 then
            debug(flag13, "            continuing immunity effect update")
            immunity_effect_data[4] = iterations
            mt_after(1, immunity_effect_update_loop, player, p_data, player_meta, id)
        else
            debug(flag13, "            no more iterations. immunity effect update stopped.")
            p_data.stat_updates[id] = nil
        end

    elseif iterations == 0 then
        debug(flag13, "            no more iterations. immunity effect update stopped.")
        p_data.stat_updates[id] = nil

    else
        debug(flag13, "            perpetual immunity effect update")
        if timer == 0 then
            debug(flag13, "            timer reached. resetting to " .. interval)
            immunity_effect_data[6] = interval
            do_immunity_effect_update_action(p_data, player_meta, effect_name, amount)
        else
            debug(flag13, "            timer not reached. iteration skipped.")
            immunity_effect_data[6] = timer - 1
        end
        mt_after(1, immunity_effect_update_loop, player, p_data, player_meta, id)
    end

    debug(flag13, "          immunity_effect_update_loop() END")
end


local flag12 = false
--- @param player ObjectRef the player for which the stat will be modified
--- @param p_data table reference to table with data specific to this player
--- @param player_meta MetaDataRef used to access various player meta data
--- @param effect_data table data relating to how the immunity effect will be modified
local function update_immunity_effect(player, p_data, player_meta, effect_data)
    debug(flag12, "        update_immunity_effect()")
    local trigger = effect_data[1]
    local stat = effect_data[2]
    local amount = effect_data[3]
    local iterations = effect_data[4]
    local timer = 0

    debug(flag12, "          effect_data: {" .. stat .. ", " .. amount .. ", "
        .. iterations .. ", " .. effect_data[5] .. "}")

    local id = get_unique_id()
    debug(flag12, "          id: " .. id)

    if iterations > 0 then
        debug(flag12, "          this is a normal immunity effect update")
        amount = amount / iterations
        -- the total 'amount' applied to 'stat' is spread equally among all iterations
    else
        debug(flag12, "          this is a perpetual immunity effect update")
        iterations = -1

        -- 'timer' applies only for perpetual updates and is ignored for normal updates.
        -- it determines the wait time in seconds before the update performs its first
        -- iteration, after which it determines how many seconds between each interval.
        timer = effect_data[5] -- setting timer to 'interval' value
    end

    p_data.stat_updates[id] = {
        trigger,
        stat,
        amount,
        iterations,
        effect_data[5],
        timer
    }
    immunity_effect_update_loop(player, p_data, player_meta, id)

    debug(flag12, "        update_immunity_effect() END")
    return id
end


local flag5 = false
--- @param player ObjectRef the player object
--- @param player_meta MetaDataRef used to access the string metadata 'status_effect'
--- @param player_name string player's name. for single player it's 'singleplayer'
--- @param p_data table reference to table with data specific to this player
--- @param status_effects table table containing all active status effects data on the player
--- @param effect_name string the status effect being managed
-- This function determines if the status effect remains shown or hidden, based on
-- its remaining duration time. It also serves to update each status effect's duration
-- time hud as it counts down.
local function stat_effect_loop(player, player_meta, player_name, p_data, status_effects, effect_name, stat, severity)
    debug(flag5, "\n    stat_effect_loop()")
    if not player:is_player() then
        debug(flag5, "      player no longer exists. function skipped.")
        return
    end
    debug(flag5, "      effect_name: " .. effect_name)

    if status_effects[effect_name] == nil then
        debug(flag5, "      stat effect already stopped")
        debug(flag5, "    stat_effect_loop() END")
        return
    end

    ------------------------------------
    -- update status effect hud elements
    ------------------------------------

    local effect_data = status_effects[effect_name]
    local type = effect_data[1]
    local duration = effect_data[2]
    local hud_location = effect_data[3]
    debug(flag5, "      duration: " .. duration)

    if type == "infinite" then
        debug(flag5, "      infinite stat effect. continuing effect..")
        mt_after(1, stat_effect_loop, player, player_meta, player_name, p_data,
            status_effects, effect_name, stat, severity)

    elseif type == "warning" then
        debug(flag5, "      warning stat effect")

        local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. hud_location]

        local text
        if INTERNAL_STAT_EFFECTS[effect_name] then
            debug(flag5, "      this is an 'internal' effect")
            local percent_value
            if stat == "weight" then
                percent_value = 100 * (1 - p_data.weight_ratio)
            else
                percent_value = 100 * player_meta:get_float(stat .. "_current") / player_meta:get_float(stat .. "_max")
            end
            text = round(percent_value, 1) .. "%"
            debug(flag5, "      text: " .. text)

            local text_length = string.len(text)
            local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
            debug(flag5, "      total_width: " .. total_width)
            player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})

        else
            debug(flag5, "      this is an 'external' effect")

            local percent_value
            if stat == "hot" or stat == "cold" then
                if p_data.thermal_units == 1 then
                    text = math_round(p_data.thermal_feels_like) .. " °F"
                else
                    text = convert_to_celcius(p_data.thermal_feels_like) .. " °C"
                end
            else
                percent_value = 100 * player_meta:get_float(stat .. "_current") / player_meta:get_float(stat .. "_max")
                text = round(percent_value, 1) .. "%"
            end
            debug(flag5, "      text: " .. text)

            local text_length = string.len(text)
            local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
            debug(flag5, "      total_width: " .. total_width)
            player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
        end

        hud_id = player_hud_ids[player_name]["stat_effect_text_" .. hud_location]
        player:hud_change(hud_id, "text", text)
        debug(flag5, "      text: " .. text)

        mt_after(1, stat_effect_loop, player, player_meta, player_name, p_data,
        status_effects, effect_name, stat, severity)


    elseif type == "timed" then
        debug(flag5, "      timed stat effect")
        if duration > 0 then
            local hud_location = effect_data[3]
            local hud_id = player_hud_ids[player_name]["stat_effect_duration_" .. hud_location]
            player:hud_change(hud_id, "text", convert_seconds(duration))

            mt_after(1, stat_effect_loop, player, player_meta, player_name, p_data,
                status_effects, effect_name, stat, severity)

            -- decrease stat effect duration
            duration = duration - 1
            effect_data[2] = duration
            debug(flag5, "      duration reduced to " .. duration)

        else
            debug(flag5, "      stat effect duration ended. stopping effect..")
            hide_stat_effect(player, player_meta, player_name, p_data, status_effects, effect_name)
        end

    else
        debug(flag5, "      ERROR - Unexpected 'type' value: " .. type)
    end

    debug(flag5, "    stat_effect_loop() END")
end



-- stat effect names: thirsty, hungry, sickly, drowsy, exhausted, suffocating
local flag6 = false
--- @param player ObjectRef the player object
--- @param player_meta MetaDataRef used to access the string metadata 'status_effect'
--- @param player_name string player's name. for single player it's 'singleplayer'
--- @param p_data table reference to table with data specific to this player
--- @param stat string the player stat that triggered the status effect
--- @param severity number 1 = stat low, 2 = stat very low, 3 = stat depleted
--- @param type string 'infinite', 'warning', or 'timed_xxx'. xxx is duration in seconds.
--- @param duration number how many seconds the stat effect will last
-- This function activates a new status effect 'effect_name' and displays its hud
-- image and duration (if not infinite) on the screen. If this function is called
-- with an 'effect_name' that is already activated, it simply adds the 'duration'
-- to the existing effect's duration. In this scenario, a negative 'duration' can
-- be passed which then shortens the stat effect's duration. If 'infinite' of 'true'
-- is passed on an existing 'effect_name' its duration will be set to zero, on-screen
-- duration hidden, and the status effect remains active indefinitely until it is
-- updated again with a different duration value, which will start the timer again.
-- 'duration' value is ignored if 'infinite' is 'true'.
function ss.show_stat_effect(player, player_meta, player_name, p_data, stat, severity, type, duration)
    debug(flag6, "          show_stat_effect()")
    debug(flag6, "            stat: " .. stat)
    debug(flag6, "            severity: " .. severity)
    debug(flag6, "            type: " .. type)
    debug(flag6, "            duration: " .. duration)

    local status_effects = p_data.status_effects
    debug(flag6, "            status_effects: " .. dump(status_effects))

    local effect_name = stat .. "_" .. severity
    local effect_data = status_effects[effect_name]
    if effect_data then
        debug(flag6, "            stat effect already active for " .. effect_name)

        -- this currently would only occur for external status effects, like injuries,
        -- infection, environmental hazards, etc.
        if type == "timed" then
            debug(flag6, "            existing stat effect already 'timed'. increasing duration..")

            local hud_location = effect_data[3]
            debug(flag6, "            hud_location: " .. hud_location)
            local hud_id_1 = player_hud_ids[player_name]["stat_effect_duration_" .. hud_location]

            local existing_duration = effect_data[2]
            debug(flag6, "            existing_duration: " .. existing_duration)
            local new_duration = existing_duration + duration
            if new_duration < 0 then new_duration = 0 end
            effect_data[2] = new_duration
            debug(flag6, "            updated duration: " .. new_duration)

            player:hud_change(hud_id_1, "text", convert_seconds(new_duration))

        else
            debug(flag6, "            stat effect " .. effect_name .. " already active. no further action.")
            debug(flag6, "          show_stat_effect()")
            return
        end

    else
        debug(flag6, "            stat effect is NOT already active")

        -- increase active status effect count
        local status_effect_count = p_data.status_effect_count
        debug(flag6, "            status_effect_count (before): " .. status_effect_count)
        status_effect_count = status_effect_count + 1
        p_data.status_effect_count = status_effect_count
        debug(flag6, "            status_effect_count (after): " .. status_effect_count)

        if type == "infinite" then
            -- display hud elements for an 'infinite' stat effect. this typically
            -- activates when a player internal stat is completely depleted, or
            -- when a custom external trigger occurs (injury, illness, etc)
            debug(flag6, "            activating new infinite effect: " .. effect_name)

            if INTERNAL_STAT_EFFECTS[effect_name] then
                debug(flag6, "            this is an 'internal' effect")

                -- create stat effect background hud
                local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. status_effect_count]

                debug(flag6, "            colorstring: " .. STAT_EFFECT_BG_COLOR_RED .. p_data.stats_bg_opacity)
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:" .. STAT_EFFECT_BG_COLOR_RED .. p_data.stats_bg_opacity)

                local text = STAT_EFFECT_HUD_LABELS[stat]
                debug(flag6, "            text: " .. text)

                local text_length = string.len(text)
                local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
                debug(flag6, "            total_width: " .. total_width)
                player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})

                -- create stat effect image hud. the image will be quite desaturated
                hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
                local image = "ss_statbar_icon_" .. stat .. ".png^[hsl:0:-80:0"
                player:hud_change(hud_id, "text", image)

                -- create stat effect text hud. the text color will be white
                hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
                player:hud_change(hud_id, "text", text)
                player:hud_change(hud_id, "number", STAT_EFFECT_TEXT_COLORS[severity])

            else
                debug(flag6, "            this is an 'external' effect")
                debug(flag6, "            (not yet implemented)")
            end

        elseif type == "warning" then
            -- display hud elements for a 'warning' stat effect. the current
            -- value of the stat as a percentage of its max value is shown next
            -- to the stat effect image.
            debug(flag6, "            activating new warning effect: " .. effect_name)

            -- create stat effect background hud
            local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. status_effect_count]

            --debug(flag6, "            colorstring: " .. STAT_EFFECT_BG_COLOR_BLACK .. p_data.stats_bg_opacity)
            player:hud_change(hud_id, "text", "[fill:1x1:0,0:" .. STAT_EFFECT_BG_COLOR_BLACK .. p_data.stats_bg_opacity)

            local text
            if INTERNAL_STAT_EFFECTS[effect_name] then
                debug(flag6, "            this is an 'internal' effect")

                local percent_value
                if stat == "weight" then
                    percent_value = 100 * (1 - p_data.weight_ratio)
                else
                    percent_value = 100 * player_meta:get_float(stat .. "_current") / player_meta:get_float(stat .. "_max")
                end
                text = round(percent_value, 1) .. "%"
                debug(flag6, "            text: " .. text)

                local text_length = string.len(text)
                local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
                debug(flag6, "            total_width: " .. total_width)
                player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})

                -- create stat effect image hud
                hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
                local image = "ss_statbar_icon_" .. stat .. ".png"
                player:hud_change(hud_id, "text", image)
                debug(flag6, "            image: " .. image)

                -- create stat effect text hud. the text color will be orange or red
                -- depending on how low that stat's current value is, which is indicated
                -- by the numer at the end of the 'effect_name'
                hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
                debug(flag6, "            text: " .. text)
                player:hud_change(hud_id, "text", text)
                player:hud_change(hud_id, "number", STAT_EFFECT_TEXT_COLORS[severity])

            else
                debug(flag6, "            this is an 'external' effect")

                local percent_value
                if stat == "hot" or stat == "cold" then
                    if p_data.thermal_units == 1 then
                        text = math_round(p_data.thermal_feels_like) .. " °F"
                    else
                        text = convert_to_celcius(p_data.thermal_feels_like) .. " °C"
                    end
                else
                    percent_value = 100 * player_meta:get_float(stat .. "_current") / player_meta:get_float(stat .. "_max")
                    text = round(percent_value, 1) .. "%"
                end
                debug(flag6, "            text: " .. text)

                local text_length = string.len(text)
                local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
                debug(flag6, "            total_width: " .. total_width)
                player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})

                -- create stat effect image hud
                hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
                local image = "ss_stat_effect_" .. stat .. "_" .. severity ..  ".png"
                player:hud_change(hud_id, "text", image)
                debug(flag6, "            image: " .. image)

                -- create stat effect text hud. the text color will be orange or red
                -- depending on how low that stat's current value is, which is indicated
                -- by the numer at the end of the 'effect_name'
                hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
                debug(flag6, "            text: " .. text)
                player:hud_change(hud_id, "text", text)

                local text_color
                if stat == "hot" then
                    if severity == 4 then
                        text_color = "0xFF0000"
                    else
                        text_color = "0xFFA800"
                    end
                else
                    if severity == 3 then
                        text_color = "0xFF0000"
                    else
                        text_color = "0xFFA800"
                    end
                end
                player:hud_change(hud_id, "number", text_color)
            end

        elseif type == "timed" then
            -- display hud elements for a 'timed' stat effect. this typically activates
            -- from an external trigger (injury, illness, etc) and not from a low 
            -- player stat. this timed effect will also display a timer next to it
            -- indicating duration of the status effect.
            debug(flag6, "            activating new time effect: " .. effect_name)
            debug(flag6, "            (not yet implemented)")

        else
            debug(flag6, "            ERROR - Unexpected 'type' value: " .. type)
        end

        status_effects[effect_name] = {type, duration, status_effect_count}
        p_data.stat_effect_hud_locations[status_effect_count] = effect_name
        player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))
        stat_effect_loop(player, player_meta, player_name, p_data, status_effects, effect_name, stat, severity)
    end

    debug(flag6, "          show_stat_effect() END")
end
local show_stat_effect = ss.show_stat_effect


local flag9 = false
-- updates the huds elements relating to the background box behind the statbars
-- and status effects, and the overall vertical placement of the stat effect huds
function ss.update_statbar_effects_huds(player, player_name, p_data, active_count, bg_box_hud_id)
    debug(flag9, "  update_statbar_effects_huds()")
    local on_screen_max = p_data.total_statbar_count + 3
    local y_offset = 140
    local hud_id, hud_def, offset_data
    if active_count > 0 then
        debug(flag9, "    at least one statbar is visible")
        local stats_bg_opacity = p_data.stats_bg_opacity
        debug(flag9, "    updating size and opacity of the black transparent bg box")
        local x_scale = (active_count * 30) + 15
        player:hud_change(bg_box_hud_id, "scale", {x = x_scale, y = 145})
        player:hud_change(bg_box_hud_id, "text", "[fill:1x1:0,0:#000000" .. stats_bg_opacity)

        debug(flag9, "    updating opacity of status effect background")
        for i = 1, on_screen_max do
            hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. i]
            hud_def = player:hud_get(hud_id)
            local text_data = string.sub(hud_def.text, 1, -3)
            debug(flag9, "    text_data: " .. text_data)
            debug(flag9, "    stats_bg_opacity: " .. stats_bg_opacity)
            player:hud_change(hud_id, "text", text_data .. stats_bg_opacity)
        end

        if p_data.stat_effects_lowered then
            debug(flag9, "    stat effect huds were repositioned lower. moving them back up..")
            for i = 1, on_screen_max do
                debug(flag9, "    shifting downward hud element stat_effect_bg_" .. i)
                hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. i]
                hud_def = player:hud_get(hud_id)
                offset_data = hud_def.offset
                offset_data.y = offset_data.y - y_offset
                player:hud_change(hud_id, "offset", offset_data)

                debug(flag9, "    shifting downward hud element stat_effect_image_" .. i)
                hud_id = player_hud_ids[player_name]["stat_effect_image_" .. i]
                hud_def = player:hud_get(hud_id)
                offset_data = hud_def.offset
                offset_data.y = offset_data.y - y_offset
                player:hud_change(hud_id, "offset", offset_data)

                debug(flag9, "    shifting downward hud element stat_effect_text_" .. i)
                hud_id = player_hud_ids[player_name]["stat_effect_text_" .. i]
                hud_def = player:hud_get(hud_id)
                offset_data = hud_def.offset
                offset_data.y = offset_data.y - y_offset
                player:hud_change(hud_id, "offset", offset_data)
            end
            p_data.stat_effects_lowered = false
        else
            debug(flag9, "    stat effect huds were not repositioned lower. no further action")
        end

    else
        debug(flag9, "    all statbars are hidden")
        debug(flag9, "    updating size and opacity of the black transparent bg box")
        player:hud_change(bg_box_hud_id, "scale", {x = 0, y = 145})

        for i = 1, on_screen_max do
            debug(flag9, "    shifting downward hud element stat_effect_bg_" .. i)
            hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. i]
            hud_def = player:hud_get(hud_id)
            offset_data = hud_def.offset
            offset_data.y = offset_data.y + y_offset
            player:hud_change(hud_id, "offset", offset_data)

            debug(flag9, "    shifting downward hud element stat_effect_image_" .. i)
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. i]
            hud_def = player:hud_get(hud_id)
            offset_data = hud_def.offset
            offset_data.y = offset_data.y + y_offset
            player:hud_change(hud_id, "offset", offset_data)

            debug(flag9, "    shifting downward hud element stat_effect_text_" .. i)
            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. i]
            hud_def = player:hud_get(hud_id)
            offset_data = hud_def.offset
            offset_data.y = offset_data.y + y_offset
            player:hud_change(hud_id, "offset", offset_data)
        end
        p_data.stat_effects_lowered = true
    end
    debug(flag9, "  update_statbar_effects_huds() END")
end
local update_statbar_effects_huds = ss.update_statbar_effects_huds


local flag8 = false
local function update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, is_breath_restored)
    debug(flag8, "          update_breath_statbar()")

    if is_breath_restored then
        debug(flag8, "            breath is at full 100%")
        if p_data.is_breathbar_shown then
            debug(flag8, "            breathbar already displayed on-screen. hiding it now..")
            player:hud_change(p_huds.breath.icon, "scale", {x = 0, y = 0})
            player:hud_change(p_huds.breath.bg, "scale", {x = 0, y = 0})
            player:hud_change(p_huds.breath.bar, "scale", {x = 0, y = 0})
            p_data.is_breathbar_shown = false
        else
            debug(flag8, "            breathbar already hidden. no further action.")
        end

    else
        debug(flag8, "            breath is not at full 100%")
        if p_data.is_breathbar_shown then
            debug(flag8, "            breathbar already displayed on-screen")
        else
            debug(flag8, "            breathbar currently hidden. restore icon and black bg.")
            player:hud_change(p_huds.breath.icon, "scale", {x = 1.3, y = 1.3})
            player:hud_change(p_huds.breath.bg, "scale", {x = STATBAR_WIDTH_MINI, y = STATBAR_HEIGHT_MINI})
            p_data.is_breathbar_shown = true
        end

        debug(flag8, "            update breathbar size/value")
        local stat_bar_value = (stat_value_new / stat_value_max) * STATBAR_HEIGHT_MINI
        player:hud_change(p_huds.breath.bar, "scale", {x = STATBAR_WIDTH_MINI - 5, y = stat_bar_value})
    end

    debug(flag8, "          update_breath_statbar() END")
end


local flag22 = false
local function update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio, effect_name)
    debug(flag22, "          update_breath_visuals()")

    debug(flag22, "            update statbar size/value")
    local stat_bar_value = breath_ratio * STATBAR_HEIGHT_MINI
    player:hud_change(p_huds.breath.bar, "scale", {x = STATBAR_WIDTH_MINI - 5, y = stat_bar_value})

    if effect_name then
        debug(flag22, "            update breath stat effect hud value")
        local hud_location = p_data.status_effects[effect_name][3]
        p_data.breath_ratio = breath_ratio
        local text = round(breath_ratio * 100, 1) .. "%"
        debug(flag22, "            text: " .. text)

        local hud_id = p_huds["stat_effect_text_" .. hud_location]
        player:hud_change(hud_id, "text", text)

        debug(flag22, "            update breath stat effect hud bg box size")
        local text_length = string.len(text)
        local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
        debug(flag22, "            total_width: " .. total_width)

        hud_id = p_huds["stat_effect_bg_" .. hud_location]
        player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
    end

    debug(flag22, "          update_breath_visuals() END")
end


local flag10 = false
function ss.recover_drained_stat(player, p_data, player_meta, stat_drained, stat_trigger, severity, drain_increment)
    debug(flag10, "          recover_drained_stat()")
    debug(flag10, "            recover " .. string.upper(stat_drained) .. " from " .. stat_trigger .. "_" .. severity)

    local key_1 = stat_drained .. "_loss_" .. stat_trigger
    if p_data[key_1] > 0 then
        debug(flag10, "            prior " .. stat_drained .. " drain from " .. stat_trigger .. " needs be recovered")
        local key_2 = "rec_" .. stat_trigger .. "_" .. severity .. "_" .. stat_drained .. "_up"
        if p_data.se_stat_updates[key_2] then
            debug(flag10, "            existing " .. stat_drained .. " recover in progress")
            local update_id = p_data.se_stat_updates[key_2]
            local update_data = p_data.stat_updates[update_id]
            update_data[4] = update_data[4] + math_round(p_data[key_1] / drain_increment)
        else
            debug(flag10, "            no existing " .. stat_drained .. " recovery detected")
            local total_drained = p_data[key_1]
            debug(flag10, "            total_drained: " .. total_drained)
            debug(flag10, "            drain_increment: " .. drain_increment)
            local iter = math_round(total_drained / drain_increment)
            debug(flag10, "            iter: " .. iter)
            local update_data = {key_2, stat_drained, total_drained, iter, 1, "curr", "add", true}
            debug(flag10, "            performing stat update..")
            local update_id = update_stat(player, p_data, player_meta, update_data)
            debug(flag10, "            stat update completed")
            if iter == 1 then
                -- do not update 'se_stat_updates' tabe with the update_id in this
                -- case because the call to update_stat() to restore the desired stat
                -- would have been performed during that single interation, and no
                -- further action is needed, and thus tracking that stat update via
                -- 'se_stat_updates' table is unnecessary.
            else
                p_data.se_stat_updates[key_2] = update_id
            end
        end
        p_data[key_1] = 0
        player_meta:set_float(key_1, 0)

    else
        debug(flag10, "            no prior " .. stat_drained .. " drain from " .. stat_trigger .. " detected")
    end

    debug(flag10, "          recover_drained_stat() END")
end
local recover_drained_stat = ss.recover_drained_stat


local flag23 = false
local function update_visuals(player, player_name, player_meta, effect_name)
    debug(flag23, "  update_visuals()")
    debug(flag23, "    effect_name: " .. effect_name)
    local p_huds = player_hud_ids[player_name]

    -- HEALTH --

    if effect_name == "health_0" then
        debug(flag23, "    health within normal range. removing any screen effects.")
        player:set_lighting({saturation = 1})
        player_meta:set_float("screen_effect_saturation", 1)
        local hud_id = player_hud_ids[player_name].screen_effect_health
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "health_1" then
        debug(flag23, "    applying visuals for health_1")
        player:set_lighting({saturation = 0.25})
        player_meta:set_float("screen_effect_saturation", 0.25)
        local hud_id = player_hud_ids[player_name].screen_effect_health
        player:hud_change(hud_id, "text", "ss_screen_effect_health_1.png")

    elseif effect_name == "health_2" then
        debug(flag23, "    applying visuals for health_2")
        player_meta:set_float("screen_effect_saturation", 0.10)
        player:set_lighting({saturation = 0.10})
        local hud_id = player_hud_ids[player_name].screen_effect_health
        player:hud_change(hud_id, "text", "ss_screen_effect_health_2.png")
        debug(flag23, "    set saturation to 10% and added bloodier overlay")

    elseif effect_name == "health_3" then
        debug(flag23, "    applying visuals for health_3")
        player_meta:set_float("screen_effect_saturation", 0)
        player:set_lighting({saturation = 0})
        local hud_id = player_hud_ids[player_name].screen_effect_health
        player:hud_change(hud_id, "text", "ss_screen_effect_health_3.png")
        debug(flag23, "    set saturation to 0% and added bloodiest overlay")

    -- STAMINA --

    elseif effect_name == "stamina_0" then
        debug(flag23, "    stamina is between 100% and 41%")
        player:hud_change(p_huds.stamina.bar, "text", "[fill:1x1:0,0:" .. STATBAR_COLORS.stamina)
        player:hud_change(p_huds.screen_effect, "text", "")

    elseif effect_name == "stamina_1" then
        debug(flag23, "    applying visuals for stamina_1 40% to 21%")
        player:hud_change(p_huds.stamina.bar, "text", "[fill:1x1:0,0:#5CC000")
        player:hud_change(p_huds.screen_effect, "text", "[fill:1x1:0,0:#888844^[opacity:60")

    elseif effect_name == "stamina_2" then
        debug(flag23, "    applying visuals for stamina_2 20% to 1%")
        player:hud_change(p_huds.stamina.bar, "text", "[fill:1x1:0,0:#A0C000")
        player:hud_change(p_huds.screen_effect, "text", "[fill:1x1:0,0:#888844^[opacity:90")

    elseif effect_name == "stamina_3" then
        debug(flag23, "    applying visuals for stamina_3 0%")
        player:hud_change(p_huds.stamina.bar, "text", "[fill:1x1:0,0:#f1ffc0")
        player:hud_change(p_huds.screen_effect, "text", "[fill:1x1:0,0:#887244^[opacity:130")

    -- HOT --

    elseif effect_name == "hot_0" then
        debug(flag23, "    no longer hot. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "hot_1" then
        debug(flag23, "    applying visuals for hot_1")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_hot_1.png")

    elseif effect_name == "hot_2" then
        debug(flag23, "    applying visuals for hot_2")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_hot_2.png")

    elseif effect_name == "hot_3" then
        debug(flag23, "    applying visuals for hot_3")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_hot_3.png")

    elseif effect_name == "hot_4" then
        debug(flag23, "    applying visuals for hot_4")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_hot_4.png")

    -- COLD --

    elseif effect_name == "cold_0" then
        debug(flag23, "    no longer cold. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "cold_1" then
        debug(flag23, "    applying visuals for cold_1")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_cold_1.png")

    elseif effect_name == "cold_2" then
        debug(flag23, "    applying visuals for cold_2")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_cold_2.png")

    elseif effect_name == "cold_3" then
        debug(flag23, "    applying visuals for cold_3")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_cold_3.png")

    elseif effect_name == "cold_4" then
        debug(flag23, "    applying visuals for cold_4")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_cold_4.png")

    else
        debug(flag23, "    ERROR - Unexpected 'effect_name' value: " .. effect_name)
    end

    debug(flag23, "  update_visuals() END")
end



local flag30 = false
local function do_stat_update_action(player, p_data, player_meta, trigger, stat, amount, type, action, allow_effects)
    debug(flag30, "        do_stat_update_action()")
    debug(flag30, "          " .. string.upper(stat) .. ", amt " .. amount .. ", type " .. type
        .. ", action " .. action)
    debug(flag30, "          stat: " .. stat)
    debug(flag30, "          amount: " .. amount)
    debug(flag30, "          type: " .. type)
    debug(flag30, "          action: " .. action)

    local stat_value_current = player_meta:get_float(stat .. "_current")
    local stat_value_max = player_meta:get_float(stat .. "_max")
    debug(flag30, "          stat_value_current (before) " .. stat_value_current
        .. " | stat_value_max (before) " .. stat_value_max)

    -- update stat max value, and ensure current value does end up higher than max value
    local stat_value_new
    if type == "max" then
        if action == "add" then
            debug(flag30, "          updating max value")
        elseif action == "set" then
            debug(flag30, "          overwriting max value to: " .. amount)
            stat_value_max = 0
        else
            debug(flag30, "          ERROR - Unexpected 'type' action: " .. action)
        end
        stat_value_max = stat_value_max + amount

        if stat_value_max < 1 then
            debug(flag30, "          stat max is below 1. clamping to 1.")
            stat_value_max = 1
        end
        if stat_value_max < stat_value_current then
            debug(flag30, "          stat current value is above max value. reducing to max value..")
            stat_value_current = stat_value_max
            debug(flag30, "          stat_value_current (updated): " .. stat_value_current)
        end
        debug(flag30, "          stat_value_max (updated): " .. stat_value_max)
        stat_value_new = stat_value_current

    -- clamping of current value is not done here but further down in the code
    -- blocks relating to the 'stat' name
    elseif type == "curr" then

        if action == "set" then
            debug(flag30, "          overwriting current value to: " .. amount)
            stat_value_current = 0
        elseif stat_value_current == stat_value_max and amount > 0 then
            debug(flag30, "          attempting to raise stat value when already at max. no further action.")
            debug(flag30, "        do_stat_update_action() END")
            return
        elseif stat_value_current == 0 and amount < 0 then
            debug(flag30, "          attempting to lower stat value when already at zero. no further action.")
            debug(flag30, "        do_stat_update_action() END")
            return
        elseif action == "add" then
            debug(flag30, "          updating curr value")
        end
        stat_value_new = stat_value_current + amount

    else
        debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
    end
    debug(flag30, "          stat_value_new: " .. stat_value_new)

    local player_name = player:get_player_name()
    local p_huds = player_hud_ids[player_name]

    -------------
    -- HEALTH --
    -------------

    if stat == "health" then

        if stat_value_new < 0 then
            debug(flag30, "          health below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          health above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          health within valid range")
        end

        local health_ratio = stat_value_new / stat_value_max
        debug(flag30, "          health_ratio: " .. health_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final health values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            debug(flag30, "          health new " .. stat_value_new)
            player_meta:set_float("health_current", stat_value_new)

            local current_hp = player:get_hp()
            debug(flag30, "          engine hp current " .. current_hp)
            local new_hp
            if stat_value_new > current_hp then
                new_hp = math.floor(stat_value_new)
            elseif stat_value_new < current_hp then
                new_hp = math.ceil(stat_value_new)
            else
                -- can occur when reloading values from rejoining game
                new_hp = stat_value_new
            end
            debug(flag30, "          new engine hp: " .. new_hp)

            if new_hp == current_hp then
                debug(flag30, "          engine hp remains at " .. current_hp)
            else
                debug(flag30, "          updating engine hp")

                player:set_hp(new_hp)
                -- if new_hp value is zero, dieplayer() is triggered but with
                -- core.after() dealy of zero, to allow remaining code below to
                -- execute before dielayer() code is executed

                if amount < 0 then
                    debug(flag30, "          this was an hp drain. trigger: " .. trigger)

                    local tokens = string.split(trigger, "_")
                    debug(flag30, "          tokens: " .. dump(tokens))
                    if tokens[1] == "se" then
                        local trigger_stat = tokens[2]
                        debug(flag30, "          this was due to a " .. trigger_stat .. " stat effect")
                        if trigger_stat == "thirst" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1.5})
                            notify(player, "pain from dehydration", 2, 2, 0, 2)
                        elseif trigger_stat == "hunger" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1.0})
                            notify(player, "pain from starvation", 2, 1.5, 0, 2)
                        --[[
                        elseif trigger_stat == "hot" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1.0})
                            notify(player, "health damage from the heat", 2, 1.5, 0, 2)
                        elseif trigger_stat == "cold" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1.0})
                            notify(player, "health damage from the cold", 2, 1.5, 0, 2)
                        --]]
                        else
                            debug(flag30, "          ERROR - Unexpected 'trigger_stat' value: " .. trigger_stat)
                        end
                    else
                        debug(flag30, "          this was not from a stat effect. no further action.")
                    end
                end
            end

        elseif type == "max" then
            player:set_properties({hp_max = stat_value_max})
            player_meta:set_float("health_max", stat_value_max)
            if stat_value_new > 0 then
                player:set_hp(stat_value_new)
                player_meta:set_float(stat .. "_current", stat_value_new)
            end
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.health.active then
            local stat_bar_value = health_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.health.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- health is within normal range of 30% and 100%
            if health_ratio > 0.30 then
                if p_data.health_ratio > 0.30 then
                    p_data.health_ratio = health_ratio
                    debug(flag30, "          prior health already above 30%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.health_ratio = health_ratio

                debug(flag30, "          health within normal range 30% to 100%. stop any status effects.")
                if status_effects["health_1"] then
                    debug(flag30, "          going from health_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "health", 1, COMFORT_DRAIN_VAL_HEALTH_1)
                elseif status_effects["health_2"] then
                    debug(flag30, "          going from health_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "health", 2, COMFORT_DRAIN_VAL_HEALTH_2)

                -- no "health_3" condition because player cannot come back from death

                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating health effect level 1, when health is between 30% and 10%
            elseif health_ratio > 0.10 then
                if p_data.health_ratio > 0.10 and p_data.health_ratio <= 0.30 then
                    p_data.health_ratio = health_ratio
                    debug(flag30, "          prior health also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'health_1' health between 30% to 10%")
                p_data.health_ratio = health_ratio

                if status_effects["health_1"] then
                    debug(flag30, "          and already has health_1. no further action.")
                elseif status_effects["health_2"] then
                    debug(flag30, "          going from health_2 to health_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "health", 2, COMFORT_DRAIN_VAL_HEALTH_2)

                -- no "health_3" condition because player cannot come back from death

                else
                    debug(flag30, "          going from status ok to health_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_1_up"], 2, 1.5, 0, 2)
                end

            -- activating health effect level 2, when health is between zero and 10%
            elseif health_ratio > 0 then
                if p_data.health_ratio > 0 and p_data.health_ratio <= 0.10 then
                    p_data.health_ratio = health_ratio
                    debug(flag30, "          prior health also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'health_2' health between 10% to 0%")
                p_data.health_ratio = health_ratio

                if status_effects["health_1"] then
                    debug(flag30, "          going from health_1 to health_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["health_2"] then
                    debug(flag30, "          and already has health_2. no further action.")

                -- no "health_3" condition because player cannot come back from death

                else
                    debug(flag30, "          going from status ok to health_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.health_ratio == 0 then
                    p_data.health_ratio = health_ratio
                    debug(flag30, "          prior health also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating health_3 health is 0%")
                p_data.health_ratio = health_ratio

                -- update_visuals() is normally handled by monitor_status_effects()
                -- loop but it gets disabled due by dieplayer() since hp = 0. so the
                -- screen effects are 'manually' triggered in the below branches.

                if status_effects["health_1"] then
                    debug(flag30, "          going from health_1 to health_3..")
                    update_visuals(player, player_name, player_meta, "health_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_3_up"], 2, 1.5, 0, 2)

                elseif status_effects["health_2"] then
                    debug(flag30, "          going from health_2 to health_3..")
                    update_visuals(player, player_name, player_meta, "health_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_3_up"], 2, 1.5, 0, 2)

                elseif status_effects["health_3"] then
                    debug(flag30, "          already has health_3. no further action.")
                    -- this could happen if player rejoins game while still in dead state,
                    -- had rage quit game window before clicking to respawn

                else
                    debug(flag30, "          going from status ok to health_3..")
                    update_visuals(player, player_name, player_meta, "health_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["health_3_up"], 2, 1.5, 0, 2)
                end

            end
        else
            debug(flag30, "          status effects disallowed")
        end


    ------------
    -- THIRST --
    ------------

    elseif stat == "thirst" then

        if stat_value_new < 0 then
            debug(flag30, "          thirst below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          thirst above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          thirst within valid range")
        end

        local thirst_ratio = stat_value_new / stat_value_max
        debug(flag30, "          thirst_ratio: " .. thirst_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final thirst values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("thirst_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("thirst_max", stat_value_max)
            player_meta:set_float("thirst_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.thirst.active then
            local stat_bar_value = thirst_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.thirst.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- thirst is within normal range of 30% and 100%.
            if thirst_ratio > 0.30 then
                if p_data.thirst_ratio > 0.30 then
                    p_data.thirst_ratio = thirst_ratio
                    debug(flag30, "          prior thirst already above 30%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.thirst_ratio = thirst_ratio

                debug(flag30, "          thirst within normal range 30% to 100%. stop any status effects.")
                if status_effects["thirst_1"] then
                    debug(flag30, "          going from thirst_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["thirst_2"] then
                    debug(flag30, "          going from thirst_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["thirst_3"] then
                    debug(flag30, "          going from thirst_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "thirst", 3, HP_DRAIN_VAL_THIRST_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "thirst", 3, COMFORT_DRAIN_VAL_THIRST_3)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating thirst effect level 1, when thirst is between 30% and 10%
            elseif thirst_ratio > 0.10 then
                if p_data.thirst_ratio > 0.10 and p_data.thirst_ratio <= 0.30 then
                    p_data.thirst_ratio = thirst_ratio
                    debug(flag30, "          prior thirst also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'thirst_1' thirst between 30% to 10%")
                p_data.thirst_ratio = thirst_ratio

                if status_effects["thirst_1"] then
                    debug(flag30, "          and already has thirst_1. no further action.")
                elseif status_effects["thirst_2"] then
                    debug(flag30, "          going from thirst_2 to thirst_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_1_down"], 2, 1.5, 0, 2)
                elseif status_effects["thirst_3"] then
                    debug(flag30, "          going from thirst_3 to thirst_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "thirst", 3, HP_DRAIN_VAL_THIRST_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "thirst", 3, COMFORT_DRAIN_VAL_THIRST_3)
                else
                    debug(flag30, "          going from status ok to thirst_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_1_up"], 2, 1.5, 0, 2)
                end

            -- activating thirst effect level 2, when thirst is between zero and 10%
            elseif thirst_ratio > 0 then
                if p_data.thirst_ratio > 0 and p_data.thirst_ratio <= 0.10 then
                    p_data.thirst_ratio = thirst_ratio
                    debug(flag30, "          prior thirst also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'thirst_2' thirst between 10% to 0%")
                p_data.thirst_ratio = thirst_ratio

                if status_effects["thirst_1"] then
                    debug(flag30, "          going from thirst_1 to thirst_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_2_up"], 2, 1.5, 0, 2)

                elseif status_effects["thirst_2"] then
                    debug(flag30, "          and already has thirst_2. no further action.")

                elseif status_effects["thirst_3"] then
                    debug(flag30, "          going from thirst_3 to thirst_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_2_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "thirst", 3, HP_DRAIN_VAL_THIRST_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "thirst", 3, COMFORT_DRAIN_VAL_THIRST_3)
                else
                    debug(flag30, "          going from status ok to thirst_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.thirst_ratio == 0 then
                    p_data.thirst_ratio = thirst_ratio
                    debug(flag30, "          prior thirst also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating thirst_3 thirst is 0%")
                p_data.thirst_ratio = thirst_ratio

                if status_effects["thirst_1"] then
                    debug(flag30, "          going from thirst_1 to thirst_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["thirst_2"] then
                    debug(flag30, "          going from thirst_2 to thirst_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["thirst_3"] then
                    debug(flag30, "          already has thirst_3. no further action.")
                else
                    debug(flag30, "          going from status ok to thirst_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["thirst_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end


    ------------
    -- HUNGER --
    ------------

    elseif stat == "hunger" then

        if stat_value_new < 0 then
            debug(flag30, "          hunger below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          hunger above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          hunger within valid range")
        end

        local hunger_ratio = stat_value_new / stat_value_max
        debug(flag30, "          hunger_ratio: " .. hunger_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final hunger values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("hunger_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("hunger_max", stat_value_max)
            player_meta:set_float("hunger_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.hunger.active then
            local stat_bar_value = hunger_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.hunger.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- hunger is within normal range of 30% and 100%. stop any hunger status effects.
            if hunger_ratio > 0.30 then
                if p_data.hunger_ratio > 0.30 then
                    p_data.hunger_ratio = hunger_ratio
                    debug(flag30, "          prior hunger also already above %30. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.hunger_ratio = hunger_ratio

                debug(flag30, "          hunger within normal range 30% to 100%. stop any status effects.")
                if status_effects["hunger_1"] then
                    debug(flag30, "          going from hunger_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["hunger_2"] then
                    debug(flag30, "          going from hunger_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["hunger_3"] then
                    debug(flag30, "          going from hunger_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "hunger", 3, HP_DRAIN_VAL_HUNGER_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "hunger", 3, COMFORT_DRAIN_VAL_HUNGER_3)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating hunger effect level 1, when hunger is between 30% and 10%
            elseif hunger_ratio > 0.10 then
                if p_data.hunger_ratio > 0.10 and p_data.hunger_ratio <= 0.30 then
                    p_data.hunger_ratio = hunger_ratio
                    debug(flag30, "          prior hunger also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'hunger_1' hunger between 30% to 10%")
                p_data.hunger_ratio = hunger_ratio

                if status_effects["hunger_1"] then
                    debug(flag30, "          and already has hunger_1. no further action.")
                elseif status_effects["hunger_2"] then
                    debug(flag30, "          going from hunger_2 to hunger_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_1_down"], 2, 1.5, 0, 2)
                elseif status_effects["hunger_3"] then
                    debug(flag30, "          going from hunger_3 to hunger_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "hunger", 3, HP_DRAIN_VAL_HUNGER_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "hunger", 3, COMFORT_DRAIN_VAL_HUNGER_3)
                else
                    debug(flag30, "          going from status ok to hunger_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_1_up"], 2, 1.5, 0, 2)
                end

            -- activating hunger effect level 2, when hunger is between zero and 10%
            elseif hunger_ratio > 0 then
                if p_data.hunger_ratio > 0 and p_data.hunger_ratio <= 0.10 then
                    p_data.hunger_ratio = hunger_ratio
                    debug(flag30, "          prior hunger also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'hunger_2' hunger between 10% to 0%")
                p_data.hunger_ratio = hunger_ratio

                if status_effects["hunger_1"] then
                    debug(flag30, "          going from hunger_1 to hunger_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["hunger_2"] then
                    debug(flag30, "          and already has hunger_2. no further action.")
                elseif status_effects["hunger_3"] then
                    debug(flag30, "          going from hunger_3 to hunger_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_2_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "hunger", 3, HP_DRAIN_VAL_HUNGER_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "hunger", 3, COMFORT_DRAIN_VAL_HUNGER_3)
                else
                    debug(flag30, "          going from status ok to hunger_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.hunger_ratio == 0 then
                    p_data.hunger_ratio = hunger_ratio
                    debug(flag30, "          prior hunger also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating hunger_3 hunger is 0%")
                p_data.hunger_ratio = hunger_ratio

                if status_effects["hunger_1"] then
                    debug(flag30, "          going from hunger_1 to hunger_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["hunger_2"] then
                    debug(flag30, "          going from hunger_2 to hunger_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["hunger_3"] then
                    debug(flag30, "          already has hunger_3. no further action.")
                else
                    debug(flag30, "          going from status ok to hunger_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hunger_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    ---------------
    -- ALERTNESS --
    ---------------

    elseif stat == "alertness" then

        if stat_value_new < 0 then
            debug(flag30, "          alertness below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          alertness above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          alertness within valid range")
        end

        local alertness_ratio = stat_value_new / stat_value_max
        debug(flag30, "          alertness_ratio: " .. alertness_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final alertness values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("alertness_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("alertness_max", stat_value_max)
            player_meta:set_float("alertness_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.alertness.active then
            local stat_bar_value = alertness_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.alertness.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- alertness is within normal range of 30% and 100%. stop any alertness status effects.
            if alertness_ratio > 0.30 then
                if p_data.alertness_ratio > 0.30 then
                    p_data.alertness_ratio = alertness_ratio
                    debug(flag30, "          prior alertness was already above 30%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.alertness_ratio = alertness_ratio

                debug(flag30, "          alertness within normal range 30% to 100%. stop any status effects.")
                if status_effects["alertness_1"] then
                    debug(flag30, "          going from alertness_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["alertness_2"] then
                    debug(flag30, "          going from alertness_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["alertness_3"] then
                    debug(flag30, "          going from alertness_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_0_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating alertness effect level 1, when alertness is between 30% and 10%
            elseif alertness_ratio > 0.10 then
                if p_data.alertness_ratio > 0.10 and p_data.alertness_ratio <= 0.30 then
                    p_data.alertness_ratio = alertness_ratio
                    debug(flag30, "          prior alertness also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'alertness_1' alertness between 30% to 10%")
                p_data.alertness_ratio = alertness_ratio

                if status_effects["alertness_1"] then
                    debug(flag30, "          and already has alertness_1. no further action.")
                elseif status_effects["alertness_2"] then
                    debug(flag30, "          going from alertness_2 to alertness_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_1_down"], 2, 1.5, 0, 2)
                elseif status_effects["alertness_3"] then
                    debug(flag30, "          going from alertness_3 to alertness_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_1_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to alertness_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_1_up"], 2, 1.5, 0, 2)
                end

            -- activating alertness effect level 2, when alertness is between zero and 10%
            elseif alertness_ratio > 0 then
                if p_data.alertness_ratio > 0 and p_data.alertness_ratio <= 0.10 then
                    p_data.alertness_ratio = alertness_ratio
                    debug(flag30, "          prior alertness also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'alertness_2' alertness between 10% to 0%")
                p_data.alertness_ratio = alertness_ratio

                if status_effects["alertness_1"] then
                    debug(flag30, "          going from alertness_1 to alertness_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["alertness_2"] then
                    debug(flag30, "          and already has alertness_2. no further action.")
                elseif status_effects["alertness_3"] then
                    debug(flag30, "          going from alertness_3 to alertness_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_2_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to alertness_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.alertness_ratio == 0 then
                    p_data.alertness_ratio = alertness_ratio
                    debug(flag30, "          prior alertness also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating alertness_3 alertness is 0%")
                p_data.alertness_ratio = alertness_ratio

                if status_effects["alertness_1"] then
                    debug(flag30, "          going from alertness_1 to alertness_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["alertness_2"] then
                    debug(flag30, "          going from alertness_2 to alertness_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["alertness_3"] then
                    debug(flag30, "          already has alertness_3. no further action.")
                else
                    debug(flag30, "          going from status ok to alertness_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["alertness_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    -------------
    -- HYGIENE --
    -------------

    elseif stat == "hygiene" then

        if stat_value_new < 0 then
            debug(flag30, "          hygiene below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          hygiene above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          hygiene within valid range")
        end

        local hygiene_ratio = stat_value_new / stat_value_max
        debug(flag30, "          hygiene_ratio: " .. hygiene_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final hygiene values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("hygiene_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("hygiene_max", stat_value_max)
            player_meta:set_float("hygiene_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.hygiene.active then
            local stat_bar_value = hygiene_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.hygiene.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- hygiene is within normal range of 30% and 100%. stop any hygiene status effects.
            if hygiene_ratio > 0.30 then
                if p_data.hygiene_ratio > 0.30 then
                    p_data.hygiene_ratio = hygiene_ratio
                    debug(flag30, "          prior hygiene was already above 30%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.hygiene_ratio = hygiene_ratio

                debug(flag30, "          hygiene within normal range 30% to 100%. stop any status effects.")
                if status_effects["hygiene_1"] then
                    debug(flag30, "          going from hygiene_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "hygiene", 1, COMFORT_DRAIN_VAL_HYGIENE_1)
                elseif status_effects["hygiene_2"] then
                    debug(flag30, "          going from hygiene_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "hygiene", 2, COMFORT_DRAIN_VAL_HYGIENE_2)
                elseif status_effects["hygiene_3"] then
                    debug(flag30, "          going from hygiene_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "hygiene", 3, COMFORT_DRAIN_VAL_HYGIENE_3)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating hygiene effect level 1, when hygiene is between 30% and 10%
            elseif hygiene_ratio > 0.10 then
                if p_data.hygiene_ratio > 0.10 and p_data.hygiene_ratio <= 0.30 then
                    p_data.hygiene_ratio = hygiene_ratio
                    debug(flag30, "          prior hygiene also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'hygiene_1' hygiene between 30% to 10%")
                p_data.hygiene_ratio = hygiene_ratio

                if status_effects["hygiene_1"] then
                    debug(flag30, "          and already has hygiene_1. no further action.")
                elseif status_effects["hygiene_2"] then
                    debug(flag30, "          going from hygiene_2 to hygiene_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "hygiene", 2, COMFORT_DRAIN_VAL_HYGIENE_2)
                elseif status_effects["hygiene_3"] then
                    debug(flag30, "          going from hygiene_3 to hygiene_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "hygiene", 3, COMFORT_DRAIN_VAL_HYGIENE_3)
                else
                    debug(flag30, "          going from status ok to hygiene_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_1_up"], 2, 1.5, 0, 2)
                end

            -- activating hygiene effect level 2, when hygiene is between zero and 10%
            elseif hygiene_ratio > 0 then
                if p_data.hygiene_ratio > 0 and p_data.hygiene_ratio <= 0.10 then
                    p_data.hygiene_ratio = hygiene_ratio
                    debug(flag30, "          prior hygiene also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'hygiene_2' hygiene between 10% to 0%")
                p_data.hygiene_ratio = hygiene_ratio

                if status_effects["hygiene_1"] then
                    debug(flag30, "          going from hygiene_1 to hygiene_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["hygiene_2"] then
                    debug(flag30, "          and already has hygiene_2. no further action.")
                elseif status_effects["hygiene_3"] then
                    debug(flag30, "          going from hygiene_3 to hygiene_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_2_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 3, COMFORT_DRAIN_VAL_BREATH_3)
                else
                    debug(flag30, "          going from status ok to hygiene_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.hygiene_ratio == 0 then
                    p_data.hygiene_ratio = hygiene_ratio
                    debug(flag30, "          prior hygiene also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating hygiene_3 hygiene is 0%")
                p_data.hygiene_ratio = hygiene_ratio

                if status_effects["hygiene_1"] then
                    debug(flag30, "          going from hygiene_1 to hygiene_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["hygiene_2"] then
                    debug(flag30, "          going from hygiene_2 to hygiene_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["hygiene_3"] then
                    debug(flag30, "          already has hygiene_3. no further action.")
                else
                    debug(flag30, "          going from status ok to hygiene_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["hygiene_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    ------------
    -- COMFORT --
    ------------

    elseif stat == "comfort" then

        if stat_value_new < 0 then
            debug(flag30, "          comfort below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          comfort above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          comfort within valid range")
        end

        local comfort_ratio = stat_value_new / stat_value_max
        debug(flag30, "          comfort_ratio: " .. comfort_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final comfort values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("comfort_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("comfort_max", stat_value_max)
            player_meta:set_float("comfort_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.comfort.active then
            local stat_bar_value = comfort_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.comfort.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- comfort is within normal range of 30% and 100%. stop any comfort status effects.
            if comfort_ratio > 0.30 then
                if p_data.comfort_ratio > 0.30 then
                    p_data.comfort_ratio = comfort_ratio
                    debug(flag30, "          prior comfort already above 30%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.comfort_ratio = comfort_ratio

                debug(flag30, "          hygiene within normal range 30% to 100%. stop any status effects.")
                if status_effects["comfort_1"] then
                    debug(flag30, "          going from comfort_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["comfort_2"] then
                    debug(flag30, "          going from comfort_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["comfort_3"] then
                    debug(flag30, "          going from comfort_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_0_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating comfort effect level 1, when comfort is between 30% and 10%
            elseif comfort_ratio > 0.10 then
                if p_data.comfort_ratio > 0.10 and p_data.comfort_ratio <= 0.30 then
                    p_data.comfort_ratio = comfort_ratio
                    debug(flag30, "          prior comfort also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'comfort_1' comfort between 30% to 10%")
                p_data.comfort_ratio = comfort_ratio

                if status_effects["comfort_1"] then
                    debug(flag30, "          and already has comfort_1. no further action.")
                elseif status_effects["comfort_2"] then
                    debug(flag30, "          going from comfort_2 to comfort_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_1_down"], 2, 1.5, 0, 2)
                elseif status_effects["comfort_3"] then
                    debug(flag30, "          going from comfort_3 to comfort_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_1_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to comfort_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_1_up"], 2, 1.5, 0, 2)
                end

            -- activating comfort effect level 2, when comfort is between zero and 10%
            elseif comfort_ratio > 0 then
                if p_data.comfort_ratio > 0 and p_data.comfort_ratio <= 0.10 then
                    p_data.comfort_ratio = comfort_ratio
                    debug(flag30, "          prior comfort also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'comfort_2' comfort between 10% to 0%")
                p_data.comfort_ratio = comfort_ratio

                if status_effects["comfort_1"] then
                    debug(flag30, "          going from comfort_1 to comfort_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["comfort_2"] then
                    debug(flag30, "          and already has comfort_2. no further action.")
                elseif status_effects["comfort_3"] then
                    debug(flag30, "          going from comfort_3 to comfort_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_2_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to comfort_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.comfort_ratio == 0 then
                    p_data.comfort_ratio = comfort_ratio
                    debug(flag30, "          prior comfort also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating comfort_3 comfort is 0%")
                p_data.comfort_ratio = comfort_ratio

                if status_effects["comfort_1"] then
                    debug(flag30, "          going from comfort_1 to comfort_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["comfort_2"] then
                    debug(flag30, "          going from comfort_2 to comfort_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["comfort_3"] then
                    debug(flag30, "          already has comfort_3. no further action.")
                else
                    debug(flag30, "          going from status ok to comfort_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["comfort_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    --------------
    -- IMMUNITY --
    --------------

    elseif stat == "immunity" then

        if stat_value_new < 0 then
            debug(flag30, "          immunity below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          immunity above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          immunity within valid range")
        end

        local immunity_ratio = stat_value_new / stat_value_max
        debug(flag30, "          immunity_ratio: " .. immunity_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final immunity values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("immunity_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("immunity_max", stat_value_max)
            player_meta:set_float("immunity_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.immunity.active then
            local stat_bar_value = immunity_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.immunity.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- immunity is within normal range of 30% and 100%. stop any immunity status effects.
            if immunity_ratio > 0.30 then
                if p_data.immunity_ratio > 0.30 then
                    p_data.immunity_ratio = immunity_ratio
                    debug(flag30, "          prior immunity already above 30%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.immunity_ratio = immunity_ratio

                debug(flag30, "          immunity within normal range 30% to 100%. stop any status effects.")
                if status_effects["immunity_1"] then
                    debug(flag30, "          going from immunity_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["immunity_2"] then
                    debug(flag30, "          going from immunity_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["immunity_3"] then
                    debug(flag30, "          going from immunity_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_0_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating immunity effect level 1, when immunity is between 30% and 10%
            elseif immunity_ratio > 0.10 then
                if p_data.immunity_ratio > 0.10 and p_data.immunity_ratio <= 0.30 then
                    p_data.immunity_ratio = immunity_ratio
                    debug(flag30, "          prior immunity also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'immunity_1' immunity between 30% to 10%")
                p_data.immunity_ratio = immunity_ratio

                if status_effects["immunity_1"] then
                    debug(flag30, "          and already has immunity_1. no further action.")
                elseif status_effects["immunity_2"] then
                    debug(flag30, "          going from immunity_2 to immunity_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_1_down"], 2, 1.5, 0, 2)
                elseif status_effects["immunity_3"] then
                    debug(flag30, "          going from immunity_3 to immunity_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_1_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to immunity_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_1_up"], 2, 1.5, 0, 2)
                end

            -- activating immunity effect level 2, when immunity is between zero and 10%
            elseif immunity_ratio > 0 then
                if p_data.immunity_ratio > 0 and p_data.immunity_ratio <= 0.10 then
                    p_data.immunity_ratio = immunity_ratio
                    debug(flag30, "          prior immunity also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'immunity_2' immunity between 10% to 0%")
                p_data.immunity_ratio = immunity_ratio

                if status_effects["immunity_1"] then
                    debug(flag30, "          going from immunity_1 to immunity_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["immunity_2"] then
                    debug(flag30, "          and already has immunity_2. no further action.")
                elseif status_effects["immunity_3"] then
                    debug(flag30, "          going from immunity_3 to immunity_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_2_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to immunity_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.immunity_ratio == 0 then
                    p_data.immunity_ratio = immunity_ratio
                    debug(flag30, "          prior immunity also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating immunity_3 immunity is 0%")
                p_data.immunity_ratio = immunity_ratio

                if status_effects["immunity_1"] then
                    debug(flag30, "          going from immunity_1 to immunity_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["immunity_2"] then
                    debug(flag30, "          going from immunity_2 to immunity_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["immunity_3"] then
                    debug(flag30, "          already has immunity_3. no further action.")
                else
                    debug(flag30, "          going from status ok to immunity_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["immunity_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    ------------
    -- SANITY --
    ------------

    elseif stat == "sanity" then

        if stat_value_new < 0 then
            debug(flag30, "          sanity below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          sanity above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          sanity within valid range")
        end

        local sanity_ratio = stat_value_new / stat_value_max
        debug(flag30, "          sanity_ratio: " .. sanity_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final sanity values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("sanity_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("sanity_max", stat_value_max)
            player_meta:set_float("sanity_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.sanity.active then
            local stat_bar_value = sanity_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.sanity.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- sanity is within normal range of 30% and 100%. stop any sanity status effects.
            if sanity_ratio > 0.30 then
                if p_data.sanity_ratio > 0.30 then
                    p_data.sanity_ratio = sanity_ratio
                    debug(flag30, "          prior sanity already above 30%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.sanity_ratio = sanity_ratio

                debug(flag30, "          sanity within normal range 30% to 100%. stop any status effects.")
                if status_effects["sanity_1"] then
                    debug(flag30, "          going from sanity_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["sanity_2"] then
                    debug(flag30, "          going from sanity_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["sanity_3"] then
                    debug(flag30, "          going from sanity_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_0_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating sanity effect level 1, when sanity is between 30% and 10%
            elseif sanity_ratio > 0.10 then
                if p_data.sanity_ratio > 0.10 and p_data.sanity_ratio <= 0.30 then
                    p_data.sanity_ratio = sanity_ratio
                    debug(flag30, "          prior sanity also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'sanity_1' sanity between 30% to 10%")
                p_data.sanity_ratio = sanity_ratio

                if status_effects["sanity_1"] then
                    debug(flag30, "          and already has sanity_1. no further action.")
                elseif status_effects["sanity_2"] then
                    debug(flag30, "          going from sanity_2 to sanity_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_1_down"], 2, 1.5, 0, 2)
                elseif status_effects["sanity_3"] then
                    debug(flag30, "          going from sanity_3 to sanity_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_1_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to sanity_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_1_up"], 2, 1.5, 0, 2)
                end

            -- activating sanity effect level 2, when sanity is between zero and 10%
            elseif sanity_ratio > 0 then
                if p_data.sanity_ratio > 0 and p_data.sanity_ratio <= 0.10 then
                    p_data.sanity_ratio = sanity_ratio
                    debug(flag30, "          prior sanity also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'sanity_2' sanity between 10% to 0%")
                p_data.sanity_ratio = sanity_ratio

                if status_effects["sanity_1"] then
                    debug(flag30, "          going from sanity_1 to sanity_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["sanity_2"] then
                    debug(flag30, "          and already has sanity_2. no further action.")
                elseif status_effects["sanity_3"] then
                    debug(flag30, "          going from sanity_3 to sanity_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_2_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to sanity_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.sanity_ratio == 0 then
                    p_data.sanity_ratio = sanity_ratio
                    debug(flag30, "          prior sanity also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating sanity_3 sanity is 0%")
                p_data.sanity_ratio = sanity_ratio

                if status_effects["sanity_1"] then
                    debug(flag30, "          going from sanity_1 to sanity_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["sanity_2"] then
                    debug(flag30, "          going from sanity_2 to sanity_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["sanity_3"] then
                    debug(flag30, "          already has sanity_3. no further action.")
                else
                    debug(flag30, "          going from status ok to sanity_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["sanity_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    ---------------
    -- HAPPINESS --
    ---------------

    elseif stat == "happiness" then

        if stat_value_new < 0 then
            debug(flag30, "          happiness below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          happiness above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          happiness within valid range")
        end

        local happiness_ratio = stat_value_new / stat_value_max
        debug(flag30, "          happiness_ratio: " .. happiness_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final happiness values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("happiness_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("happiness_max", stat_value_max)
            player_meta:set_float("happiness_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.happiness.active then
            local stat_bar_value = happiness_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.happiness.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- happiness is within normal range of 30% and 100%. stop any happiness status effects.
            if happiness_ratio > 0.30 then
                if p_data.happiness_ratio > 0.30 then
                    p_data.happiness_ratio = happiness_ratio
                    debug(flag30, "          prior happiness already above 30%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.happiness_ratio = happiness_ratio

                debug(flag30, "          happiness within normal range 30% to 100%. stop any status effects.")
                if status_effects["happiness_1"] then
                    debug(flag30, "          going from happiness_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["happiness_2"] then
                    debug(flag30, "          going from happiness_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_0_down"], 2, 1.5, 0, 2)
                elseif status_effects["happiness_3"] then
                    debug(flag30, "          going from happiness_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_0_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating happiness effect level 1, when happiness is between 30% and 10%
            elseif happiness_ratio > 0.10 then
                if p_data.happiness_ratio > 0.10 and p_data.happiness_ratio <= 0.30 then
                    p_data.happiness_ratio = happiness_ratio
                    debug(flag30, "          prior happiness also between 30% and 10%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'happiness_1' happiness between 30% to 10%")
                p_data.happiness_ratio = happiness_ratio

                if status_effects["happiness_1"] then
                    debug(flag30, "          and already has happiness_1. no further action.")
                elseif status_effects["happiness_2"] then
                    debug(flag30, "          going from happiness_2 to happiness_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_1_down"], 2, 1.5, 0, 2)
                elseif status_effects["happiness_3"] then
                    debug(flag30, "          going from happiness_3 to happiness_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_1_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to happiness_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_1_up"], 2, 1.5, 0, 2)
                end

            -- activating happiness effect level 2, when happiness is between zero and 10%
            elseif happiness_ratio > 0 then
                if p_data.happiness_ratio > 0 and p_data.happiness_ratio <= 0.10 then
                    p_data.happiness_ratio = happiness_ratio
                    debug(flag30, "          prior happiness also between 10% and 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'happiness_2' happiness between 10% to 0%")
                p_data.happiness_ratio = happiness_ratio

                if status_effects["happiness_1"] then
                    debug(flag30, "          going from happiness_1 to happiness_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["happiness_2"] then
                    debug(flag30, "          and already has happiness_2. no further action.")
                elseif status_effects["happiness_3"] then
                    debug(flag30, "          going from happiness_3 to happiness_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_2_down"], 2, 1.5, 0, 2)
                else
                    debug(flag30, "          going from status ok to happiness_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.happiness_ratio == 0 then
                    p_data.happiness_ratio = happiness_ratio
                    debug(flag30, "          prior happiness also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating happiness_3 happiness is 0%")
                p_data.happiness_ratio = happiness_ratio

                if status_effects["happiness_1"] then
                    debug(flag30, "          going from happiness_1 to happiness_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["happiness_2"] then
                    debug(flag30, "          going from happiness_2 to happiness_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["happiness_3"] then
                    debug(flag30, "          already has happiness_3. no further action.")
                else
                    debug(flag30, "          going from status ok to happiness_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["happiness_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    ------------
    -- BREATH --
    ------------

    elseif stat == "breath" then

        if stat_value_new < 0 then
            debug(flag30, "          breath below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          breath above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          breath within valid range")
        end
        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -- Save the new breath values
        if type == "curr" then
            player_meta:set_float("breath_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("breath_max", stat_value_max)
            player_meta:set_float("breath_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        -- 100% to 40%: no player impact
        -- 40% to 20%: no player impact
        -- 20% to 0%: comfort drain
        -- 0%: increased comfort drain, sanity drain, health drain
        local breath_ratio = stat_value_new / stat_value_max
        debug(flag30, "          breath_ratio: " .. breath_ratio)

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects
            if breath_ratio == 1 then
                if p_data.breath_ratio == 1 then
                    p_data.breath_ratio = breath_ratio
                    debug(flag30, "          prior breath also full 100%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          breath is full 100%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    debug(flag30, "          going from breath_1 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_1")
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 1, COMFORT_DRAIN_VAL_BREATH_1)
                elseif status_effects["breath_2"] then
                    debug(flag30, "          going from breath_2 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_2")
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 2, COMFORT_DRAIN_VAL_BREATH_2)
                elseif status_effects["breath_3"] then
                    debug(flag30, "          going from breath_3 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_3")
                    recover_drained_stat(player, p_data, player_meta, "health", "breath", 3, stat_value_max / HP_ZERO_TIME_BREATH_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 3, COMFORT_DRAIN_VAL_BREATH_3)
                else
                    debug(flag30, "          and no prior breath stat effects")
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, true)

            elseif breath_ratio > 0.4 then
                if p_data.breath_ratio > 0.4 and p_data.breath_ratio < 1 then
                    p_data.breath_ratio = breath_ratio
                    debug(flag30, "          prior breath also between 100% and %40")
                    update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio)
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          remaining breath 100% to 40%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    debug(flag30, "          going from breath_1 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_1")
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 1, COMFORT_DRAIN_VAL_BREATH_1)
                    if p_data.underwater then
                        notify(player, STAT_EFFECT_TEXTS["breath_0_down"], 2, 1.5, 0, 2)
                    end
                elseif status_effects["breath_2"] then
                    debug(flag30, "          going from breath_2 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_2")
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 2, COMFORT_DRAIN_VAL_BREATH_2)
                    if p_data.underwater then
                        notify(player, STAT_EFFECT_TEXTS["breath_0_down"], 2, 1.5, 0, 2)
                    end
                elseif status_effects["breath_3"] then
                    debug(flag30, "          going from breath_3 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_3")
                    recover_drained_stat(player, p_data, player_meta, "health", "breath", 3, stat_value_max / HP_ZERO_TIME_BREATH_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 3, COMFORT_DRAIN_VAL_BREATH_3)
                    if p_data.underwater then
                        notify(player, STAT_EFFECT_TEXTS["breath_0_down"], 2, 1.5, 0, 2)
                    end
                else
                    debug(flag30, "          and no prior breath stat effects")
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, false)

            elseif breath_ratio > 0.2 then
                if p_data.breath_ratio > 0.2 and p_data.breath_ratio <= 0.4 then
                    p_data.breath_ratio = breath_ratio
                    debug(flag30, "          prior breath also between 40% and 20%")
                    update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio, "breath_1")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'breath_1' breath between 40% to 20%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    debug(flag30, "          already at breath_1. no further action.")
                elseif status_effects["breath_2"] then
                    debug(flag30, "          going from breath_2 to breath_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 1, "warning", 0)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 2, COMFORT_DRAIN_VAL_BREATH_2)
                    if p_data.underwater then
                        notify(player, STAT_EFFECT_TEXTS["breath_1_down"], 2, 1.5, 0, 2)
                    end
                elseif status_effects["breath_3"] then
                    debug(flag30, "          going from breath_3 to breath_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 1, "warning", 0)
                    recover_drained_stat(player, p_data, player_meta, "health", "breath", 3, stat_value_max / HP_ZERO_TIME_BREATH_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 3, COMFORT_DRAIN_VAL_BREATH_3)
                    if p_data.underwater then
                        notify(player, STAT_EFFECT_TEXTS["breath_1_down"], 2, 1.5, 0, 2)
                    end
                else
                    debug(flag30, "          going from breath ok to breath_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["breath_1_up"], 2, 1.5, 0, 2, true)
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, false)

            elseif breath_ratio > 0 then
                if p_data.breath_ratio > 0 and p_data.breath_ratio <= 0.2 then
                    p_data.breath_ratio = breath_ratio
                    debug(flag30, "          prior breath also between 20% and 0%")
                    update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio, "breath_2")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'breath_2' breath between 20% to 0%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    debug(flag30, "          going from breath_1 to breath_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["breath_2_up"], 2, 1.5, 0, 2, true)
                elseif status_effects["breath_2"] then
                    debug(flag30, "          already at breath_2. no further action.")
                elseif status_effects["breath_3"] then
                    debug(flag30, "          going from breath_3 to breath_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 2, "warning", 0)
                    recover_drained_stat(player, p_data, player_meta, "health", "breath", 3, stat_value_max / HP_ZERO_TIME_BREATH_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "breath", 3, COMFORT_DRAIN_VAL_BREATH_3)
                    if p_data.underwater then
                        notify(player, STAT_EFFECT_TEXTS["breath_2_down"], 2, 1.5, 0, 2)
                    end
                else
                    debug(flag30, "          going from breath ok to breath_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["breath_2_up"], 2, 1.5, 0, 2, true)
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, false)

            else
                if p_data.breath_ratio == 0 then
                    p_data.breath_ratio = breath_ratio
                    debug(flag30, "          prior breath also 0%")
                    update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio, "breath_3")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating breath_3 breath is 0%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    debug(flag30, "          going from breath_1 to breath_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["breath_3_up"], 2, 1.5, 0, 2, true)
                elseif status_effects["breath_2"] then
                    debug(flag30, "          going from breath_2 to breath_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["breath_3_up"], 2, 1.5, 0, 2, true)
                elseif status_effects["breath_3"] then
                    debug(flag30, "          already at breath_3. no further action.")
                else
                    debug(flag30, "          going from breath ok to breath_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["breath_3_up"], 2, 1.5, 0, 2, true)
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, false)
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    -------------
    -- STAMINA --
    -------------

    elseif stat == "stamina" then


        if stat_value_new < 0 then
            debug(flag30, "          stamina below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          stamina above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            debug(flag30, "          stamina within valid range")
        end

        local stamina_ratio = stat_value_new / stat_value_max
        debug(flag30, "          stamina_ratio: " .. stamina_ratio)

        debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final stamina values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("stamina_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("stamina_max", stat_value_max)
            player_meta:set_float("stamina_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        local stamina_bar_value = stamina_ratio * STAMINA_BAR_WIDTH

        debug(flag30, "          stamina_bar_value: " .. stamina_bar_value)
        debug(flag30, "          STAMINA_BAR_HEIGHT: " .. STAMINA_BAR_HEIGHT)

        local hud_id = p_huds.stamina.bar
        player:hud_change(hud_id, "scale", {x = stamina_bar_value, y = STAMINA_BAR_HEIGHT})


        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- stamina is within normal range of 40% and 100%. stop any stamina status effects.
            if stamina_ratio > 0.40 then
                if p_data.stamina_ratio > 0.40 then
                    p_data.stamina_ratio = stamina_ratio
                    debug(flag30, "          prior stamina already above 40%. no further action")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.stamina_ratio = stamina_ratio

                debug(flag30, "          stamina within normal range 30% to 100%. stop any status effects.")
                if status_effects["stamina_1"] then
                    debug(flag30, "          going from stamina_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "stamina", 1, COMFORT_DRAIN_VAL_STAMINA_1)
                elseif status_effects["stamina_2"] then
                    debug(flag30, "          going from stamina_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "stamina", 2, COMFORT_DRAIN_VAL_STAMINA_2)
                elseif status_effects["stamina_3"] then
                    debug(flag30, "          going from stamina_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "stamina", 3, COMFORT_DRAIN_VAL_STAMINA_3)
                else
                    debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating stamina effect level 1, when stamina is between 20% and 40%
            elseif stamina_ratio > 0.20 then
                if p_data.stamina_ratio > 0.20 and p_data.stamina_ratio <= 0.40 then
                    p_data.stamina_ratio = stamina_ratio
                    debug(flag30, "          prior stamina also between 20% and 40%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'stamina_1' stamina between 20% to 40%")
                p_data.stamina_ratio = stamina_ratio

                if status_effects["stamina_1"] then
                    debug(flag30, "          and already has stamina_1. no further action.")
                elseif status_effects["stamina_2"] then
                    debug(flag30, "          going from stamina_2 to stamina_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "stamina", 2, COMFORT_DRAIN_VAL_STAMINA_2)
                elseif status_effects["stamina_3"] then
                    debug(flag30, "          going from stamina_3 to stamina_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "stamina", 3, COMFORT_DRAIN_VAL_STAMINA_3)
                else
                    debug(flag30, "          going from status ok to stamina_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_1_up"], 2, 1.5, 0, 2)
                end

            -- activating stamina effect level 2, when stamina is between zero and 10%
            elseif stamina_ratio > 0 then
                if p_data.stamina_ratio > 0 and p_data.stamina_ratio <= 0.20 then
                    p_data.stamina_ratio = stamina_ratio
                    debug(flag30, "          prior stamina also between 0% and 20%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'stamina_2' stamina between 0% to 20%")
                p_data.stamina_ratio = stamina_ratio

                if status_effects["stamina_1"] then
                    debug(flag30, "          going from stamina_1 to stamina_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_2_up"], 2, 1.5, 0, 2)
                elseif status_effects["stamina_2"] then
                    debug(flag30, "          and already has stamina_2. no further action.")
                elseif status_effects["stamina_3"] then
                    debug(flag30, "          going from stamina_3 to stamina_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_2_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "stamina", 3, COMFORT_DRAIN_VAL_STAMINA_3)
                else
                    debug(flag30, "          going from status ok to stamina_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_2_up"], 2, 1.5, 0, 2)
                end

            else
                if p_data.stamina_ratio == 0 then
                    p_data.stamina_ratio = stamina_ratio
                    debug(flag30, "          prior stamina also 0%")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating stamina_3 stamina is 0%")
                p_data.stamina_ratio = stamina_ratio

                if status_effects["stamina_1"] then
                    debug(flag30, "          going from stamina_1 to stamina_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["stamina_2"] then
                    debug(flag30, "          going from stamina_2 to stamina_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_3_up"], 2, 1.5, 0, 2)
                elseif status_effects["stamina_3"] then
                    debug(flag30, "          already has stamina_3. no further action.")
                else
                    debug(flag30, "          going from status ok to stamina_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["stamina_3_up"], 2, 1.5, 0, 2)
                end
            end
        else
            debug(flag30, "          status effects disallowed")
        end

    ----------------
    -- EXPERIENCE --
    ----------------

    elseif stat == "experience" then

        if stat_value_new < stat_value_max then
            if stat_value_new > 0 then
                debug(flag30, "          xp is between zero and max")
            elseif stat_value_new < 0 then
                debug(flag30, "          xp is lower than zero. clamped to zero.")
                stat_value_new = 0
            else
                debug(flag30, "          xp is zero")
            end

        else
            debug(flag30, "          gained a level")
            notify(player, "Experience level up!", 3, 1, 0, 2)

            stat_value_new = stat_value_new - stat_value_max
            debug(flag30, "          new xp value: " .. stat_value_new)

            local new_player_level = p_data.player_level + 1
            p_data.player_level = new_player_level
            player_meta:set_int("player_level", new_player_level)
            debug(flag30, "\n          player level increased to " .. new_player_level)

            local new_skill_points = p_data.player_skill_points + 1
            p_data.player_skill_points = new_skill_points
            player_meta:set_int("player_skill_points", new_skill_points)
            debug(flag30, "          skill points increased to " .. new_skill_points)

            stat_value_max = stat_value_max * (1 + XP_MAX_GROWTH_RATE)
            player_meta:set_float("experience_max", stat_value_max)
            debug(flag30, "          experience_max increased to " .. stat_value_max)

            -- uplodate main formspec ui with new level and skill values
            local fs = player_data[player_name].fs
            fs.left.stats = get_fs_player_stats(player_name)
            player_meta:set_string("fs", mt_serialize(fs))
            player:set_inventory_formspec(build_fs(fs))
        end

        debug(flag30, "          final xp " .. stat_value_new .. " | final max xp " .. stat_value_max)
        player_meta:set_float("experience_current", stat_value_new)
        player_meta:set_float("experience_max", stat_value_max)

        local experience_bar_value = (stat_value_new / stat_value_max) * EXPERIENCE_BAR_WIDTH
        local hud_id = player_hud_ids[player_name].experience.bar
        player:hud_change(hud_id, "scale", {x = experience_bar_value, y = EXPERIENCE_BAR_HEIGHT})

    ------------
    -- WEIGHT --
    ------------

    elseif stat == "weight" then

        if stat_value_new < 0 then
            debug(flag30, "          weight is below zero")
            stat_value_new = 0
            notify(player, "ERROR - Weight below zero. Set to 0.", 2, 0, 0.5, 3)
        elseif stat_value_new > stat_value_max then
            debug(flag30, "          hit max weight")
            stat_value_new = stat_value_max
            notify(player, "ERROR - Weight above max. Set to " .. stat_value_max, 2, 0, 0.5, 3)
        else
            debug(flag30, "          stat within valid range")
        end

        local weight_ratio = stat_value_new / stat_value_max
        debug(flag30, "          weight_ratio: " .. weight_ratio)

        ------------------------------------------------------
        -- Save the new weight values and refresh statbar huds
        ------------------------------------------------------

        debug(flag30, "          final weight " .. stat_value_new .. " | final max weight " .. stat_value_max)
        local hud_id = p_huds.weight.bar
        player_meta:set_float("weight_current", stat_value_new)
        player_meta:set_float("weight_max", stat_value_max)

        local stat_bar_value = weight_ratio * STATBAR_HEIGHT_MINI
        player:hud_change(hud_id, "scale", {x = STATBAR_WIDTH_MINI - 5, y = stat_bar_value})
        debug(flag30, "          stat_bar_value: " .. stat_bar_value)

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects
            if weight_ratio < 0.25 then
                if p_data.weight_ratio >= 0 and p_data.weight_ratio < 0.25 then
                    p_data.weight_ratio = weight_ratio
                    debug(flag30, "          prior weight also between 0% and 25%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          carrying 0% to 25% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    debug(flag30, "          going from weight_1 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 1, COMFORT_DRAIN_VAL_WEIGHT_1)
                elseif status_effects["weight_2"] then
                    debug(flag30, "          going from weight_2 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 2, COMFORT_DRAIN_VAL_WEIGHT_2)
                elseif status_effects["weight_3"] then
                    debug(flag30, "          going from weight_3 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "weight", 3, HP_DRAIN_VAL_WEIGHT_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 3, COMFORT_DRAIN_VAL_WEIGHT_3)
                else
                    debug(flag30, "          and no prior weight stat effects")
                end

                debug(flag30, "            change stamina bar color to #C0C000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C0C000")

                debug(flag30, "            modify movement speed and jump height")
                player_meta:set_float("speed_buff_weight", 1)
                player_meta:set_float("jump_buff_weight", 1)
                p_data.speed_buff_weight = 1
                p_data.jump_buff_weight = 1
                update_player_physics(player, {"speed", "jump"})

            elseif weight_ratio < 0.50 then
                if p_data.weight_ratio >= 0.25 and p_data.weight_ratio < 0.50 then
                    p_data.weight_ratio = weight_ratio
                    debug(flag30, "          prior weight also between 25% and 50%. no further action.")
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          carrying 25% to 50% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    debug(flag30, "          going from weight_1 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 1, COMFORT_DRAIN_VAL_WEIGHT_1)
                elseif status_effects["weight_2"] then
                    debug(flag30, "          going from weight_2 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 2, COMFORT_DRAIN_VAL_WEIGHT_2)
                elseif status_effects["weight_3"] then
                    debug(flag30, "          going from weight_3 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_0_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "weight", 3, HP_DRAIN_VAL_WEIGHT_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 3, COMFORT_DRAIN_VAL_WEIGHT_3)
                else
                    debug(flag30, "          and no prior weight stat effects")
                end

                debug(flag30, "            change stamina bar color to #C0A000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C0A000")

                debug(flag30, "            modify movement speed and jump height")
                player_meta:set_float("speed_buff_weight", 0.8)
                player_meta:set_float("jump_buff_weight", 0.98)
                p_data.speed_buff_weight = 0.8
                p_data.jump_buff_weight = 0.98
                update_player_physics(player, {"speed", "jump"})

            elseif weight_ratio < 0.75 then
                if p_data.weight_ratio >= 0.50 and p_data.weight_ratio < 0.75 then
                    debug(flag30, "          prior weight also between 50% and 75%")
                    debug(flag30, "          update weight stat effect hud value")
                    p_data.weight_ratio = weight_ratio
                    local remaining_ratio_percentage = (1 - weight_ratio) * 100
                    local text = round((remaining_ratio_percentage), 1) .. "%"
                    local id = player_hud_ids[player_name]["stat_effect_text_" .. status_effects.weight_1[3]]
                    player:hud_change(id, "text", text)
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'weight_1' carrying 50% to 75% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    debug(flag30, "          already at weight_1. no further action.")
                elseif status_effects["weight_2"] then
                    debug(flag30, "          going from weight_2 to weight_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 2, COMFORT_DRAIN_VAL_WEIGHT_2)
                elseif status_effects["weight_3"] then
                    debug(flag30, "          going from weight_3 to weight_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_1_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "weight", 3, HP_DRAIN_VAL_WEIGHT_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 3, COMFORT_DRAIN_VAL_WEIGHT_3)
                else
                    debug(flag30, "          going from weight ok to weight_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 1, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_1_up"], 2, 1.5, 0, 2)
                end

                debug(flag30, "            change stamina bar color to #C08000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C08000")

                debug(flag30, "            modify movement speed and jump height")
                player_meta:set_float("speed_buff_weight", 0.6)
                player_meta:set_float("jump_buff_weight", 0.96)
                p_data.speed_buff_weight = 0.6
                p_data.jump_buff_weight = 0.96
                update_player_physics(player, {"speed", "jump"})

            elseif weight_ratio < 0.90 then
                if p_data.weight_ratio >= 0.75 and p_data.weight_ratio < 0.90 then
                    debug(flag30, "          prior weight also between 75% and 90%. no further action.")
                    debug(flag30, "          update weight stat effect hud value")
                    p_data.weight_ratio = weight_ratio
                    local remaining_ratio_percentage = (1 - weight_ratio) * 100
                    local text = round((remaining_ratio_percentage), 1) .. "%"
                    local id = player_hud_ids[player_name]["stat_effect_text_" .. status_effects.weight_2[3]]
                    player:hud_change(id, "text", text)
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'weight_2' carrying 75% to 90% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    debug(flag30, "          going from weight_1 to weight_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_2_up"], 2, 1.5, 0, 2)

                elseif status_effects["weight_2"] then
                    debug(flag30, "          already at weight_2. no further action.")

                elseif status_effects["weight_3"] then
                    debug(flag30, "          going from weight_3 to weight_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_2_down"], 2, 1.5, 0, 2)
                    recover_drained_stat(player, p_data, player_meta, "health", "weight", 3, HP_DRAIN_VAL_WEIGHT_3)
                    recover_drained_stat(player, p_data, player_meta, "comfort", "weight", 3, COMFORT_DRAIN_VAL_WEIGHT_3)

                else
                    debug(flag30, "          going from weight ok to weight_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 2, "warning", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_2_up"], 2, 1.5, 0, 2)
                end

                debug(flag30, "            change stamina bar color to #C06000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C06000")

                debug(flag30, "            modify movement speed and jump height")
                player_meta:set_float("speed_buff_weight", 0.4)
                player_meta:set_float("jump_buff_weight", 0.94)
                p_data.speed_buff_weight = 0.4
                p_data.jump_buff_weight = 0.94
                update_player_physics(player, {"speed", "jump"})

            else
                if p_data.weight_ratio >= 0.90 then
                    debug(flag30, "          prior weight also above 90%. no further action.")
                    debug(flag30, "          update weight stat effect hud value")
                    p_data.weight_ratio = weight_ratio
                    local remaining_ratio_percentage = (1 - weight_ratio) * 100
                    local text = round((remaining_ratio_percentage), 1) .. "%"
                    local id = player_hud_ids[player_name]["stat_effect_text_" .. status_effects.weight_3[3]]
                    player:hud_change(id, "text", text)
                    debug(flag30, "        do_stat_update_action() END")
                    return
                end
                debug(flag30, "          activating 'weight_3' carrying 90% to 100% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    debug(flag30, "          going from weight_1 to weight_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_3_up"], 2, 1.5, 0, 2)

                elseif status_effects["weight_2"] then
                    debug(flag30, "          going from weight_2 to weight_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_3_up"], 2, 1.5, 0, 2)

                elseif status_effects["weight_3"] then
                    debug(flag30, "          already at weight_3. no further action.")

                else
                    debug(flag30, "          going from weight ok to weight_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 3, "infinite", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, STAT_EFFECT_TEXTS["weight_3_up"], 2, 1.5, 0, 2)
                end

                debug(flag30, "            change stamina bar color to #A00000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#A00000")

                debug(flag30, "            modify movement speed and jump height")
                player_meta:set_float("speed_buff_weight", 0.2)
                player_meta:set_float("jump_buff_weight", 0.92)
                p_data.speed_buff_weight = 0.2
                p_data.jump_buff_weight = 0.92
                update_player_physics(player, {"speed", "jump"})
            end

        else
            debug(flag30, "          status effects disallowed")
        end

    else
        debug(flag30, "          ERROR - Unexpected 'stat' value: " .. stat)
    end

    debug(flag30, "        do_stat_update_action() END")
end


local flag28 = false
--- @param player ObjectRef the player for which the stat will be modified
--- @param p_data table reference to table with data specific to this player
--- @param player_meta MetaDataRef used to access 'stat_updates' metadata
--- @param id number unique numerical id for this status update.
local function stat_update_loop(player, p_data, player_meta, id)
    debug(flag28, "\n      stat_update_loop()")
    if not player:is_player() then
        debug(flag28, "        player no longer exists. function skipped.")
        return
    end

    if p_data.stat_updates[id] == nil then
        debug(flag28, "        stat update was stopped")
        debug(flag28, "      stat_update_loop() END")
        return
    end

    local update_data = p_data.stat_updates[id]
    local trigger = update_data[1]
    local stat = update_data[2]
    local amount = update_data[3]
    local iterations = update_data[4]
    local interval = update_data[5]
    local timer = update_data[6]
    local type = update_data[7]
    local action = update_data[8]
    local allow_effects = update_data[9]

    local stat_current_value = player_meta:get_float(stat .. "_current")
    debug(flag28, "        id[" .. id .. "] " .. trigger .. " >> " .. string.upper(stat) .. " " .. amount .. " [ " .. stat_current_value .. " ]")
    debug(flag28, "        iterations (before): " .. iterations)

    if iterations > 0 then
        debug(flag28, "        performing stat update action..")
        do_stat_update_action(player, p_data, player_meta, trigger, stat, amount, type, action, allow_effects)
        debug(flag28, "        stat update action completed")
        iterations = iterations - 1
        debug(flag28, "        iterations (after): " .. iterations)
        if iterations > 0 then
            debug(flag28, "        continuing stat update")

            -- check if this stat update was triggered by a status effect, and if
            -- the stat that triggered the status effect is already fully recovered.
            -- if so, this stat update is no longer necessary and is cancelled.
            if p_data.se_stat_updates[trigger] then
                debug(flag28, "        this stat update was triggered by a status effect")
                if p_data[stat .. "_ratio"] == 1 then
                    debug(flag28, "        " .. stat .. " already fully recovered. cancelling restore..")
                    local tokens = string.split(trigger, "_")
                    local trigger_stat = tokens[2]
                    debug(flag28, "        trigger_stat: " .. trigger_stat)
                    local key = stat .. "_loss_" .. trigger_stat
                    p_data[key] = 0
                    player_meta:set_float(key, 0)
                    p_data.se_stat_updates[trigger] = nil
                    p_data.stat_updates[id] = nil
                else
                    debug(flag28, "        " .. stat .. " not yet recovered. continuing next iteration.")
                    update_data[4] = iterations
                    mt_after(1, stat_update_loop, player, p_data, player_meta, id)
                end
            else
                debug(flag28, "        continuing next iteration")
                update_data[4] = iterations
                mt_after(1, stat_update_loop, player, p_data, player_meta, id)
            end
        else
            debug(flag28, "        no more iterations. stat update stopped.")
            p_data.stat_updates[id] = nil
            if p_data.se_stat_updates[trigger] then
                debug(flag28, "        " .. trigger .. " exists in 'se_stat_updates' table. removing..")
                p_data.se_stat_updates[trigger] = nil
            else
                debug(flag28, "        " .. trigger .. " does not exist in 'se_stat_updates' table")
            end
        end

    elseif iterations == 0 then
        debug(flag28, "        iterations is zero. stat update stopped.")
        p_data.stat_updates[id] = nil

    else
        debug(flag28, "        perpetual stat update")
        if timer == 0 then
            debug(flag28, "        timer reached. resetting to " .. interval)
            update_data[6] = interval
            do_stat_update_action(player, p_data, player_meta, trigger, stat, amount, type, action, allow_effects)
        else
            debug(flag28, "        timer at " .. timer .. " of " .. interval)
            update_data[6] = timer - 1
        end
        mt_after(1, stat_update_loop, player, p_data, player_meta, id)
    end

    -- save stat update data in order to reload if player exits or if game crashes
    player_meta:set_string("stat_updates", mt_serialize(p_data.stat_updates))

    --debug(flag28, "    stat_updates: " .. dump(p_data.stat_updates))
    debug(flag28, "      stat_update_loop() END\n")
end


--[[ ##### MORE ABOUT THE 'update_data' PARAMETER #####
update_data = {
  [1] = 'trigger' can be 'normal' or 'natural_drain'. 'normal' is cause by normal
    events like consuming items, using stamina, etc. 'natural_drain' is the datural
    depletion of thirst, hunger, and alertness throughout the day.
  [2] = 'stat_name' is the player stat to be modified.
  [3] = 'change_amount' is the total amount the stat should be modified by. positive
    value raises the stat and negative value lowers the stat.
  [4] = 'iterations' is how many 1-second cycles are needed for the 'change_amount'
    to be fully applied to the stat. a value of '1' applies all of change_amount
    in a single cycle. a value of '2' applies half of change_amount in the first
    cycle, and the other half on the next, and so on. a value of 0 or less triggers
    a 'perpetual' stat update, where the full change_amount is applied to the stat
    every 'inverval' seconds, without end.
  [5] = 'interval' only applies to perpetual stat updates and determines how many seconds
    between each iteration. unlike normal stat updates, perpetual udpates have a
    'warm-up' time in seconds before its first iteration, which is set by 'interval'
  [6] = 'type' can be 'curr' or 'max'. modify the current or the max value of the stat.
  [7] = 'action' can be 'add' or 'set'. whether to add change_amount to the existing stat
    value or to simply overwrite the existing stat value.
  [8] = 'allow_effects' can be true or false. if a stat effect should be triggered due
    to the result of this stat update. this is typically set to true, but can often
    be false when 'action' is 'set'.
}
EXAMPLES: "?" is ignored
To increase health by 10 for a one-time, immediate update:
  update_data = {"normal", "health", 10, 1, ?, "curr", "add", true}
To decrease thirst by 10 across three 1-second iterations:
  update_data = {"normal", "thirst", -10, 3, ?, "curr", "add", true}
To decrease hunger by 1 every 5 seconds, without end:
  update_data = {"natural_drain", "hunger", -1, -1, 5, "curr", "add", true}
To reset max health to 100 without triggering any stat effects:
  update_data = {"normal", "health", 100, 1, ?, "max", "set", false}
To reset current health to 100 while triggering any stat effects:
  update_data = {"normal", "health", 100, 1, ?, "curr", "set", true}
--]]
local flag27 = false
--- @param player ObjectRef the player for which the stat will be modified
--- @param p_data table reference to table with data specific to this player
--- @param player_meta MetaDataRef used to access various player meta data
--- @param update_data table data relating to how the stat will be modified
ss.update_stat = function(player, p_data, player_meta, update_data)
    debug(flag27, "\n    update_stat()")
    local trigger = update_data[1]
    local stat = update_data[2]
    local amount = update_data[3]
    local iterations = update_data[4]
    local timer = 0
    debug(flag27, "      update_data: {" .. stat .. ", " .. amount .. ", " .. iterations
        .. ", " .. update_data[5] .. ", " .. update_data[6] .. ", " .. update_data[7]
        .. ", " .. dump(update_data[8]) .. "}")

    --print("update_stat() " .. trigger .. " " .. stat .. " " .. amount)

    local id = get_unique_id()
    debug(flag27, "      id: " .. id)

    if amount == 0 then
        if update_data[7] == "set" then
            do_stat_update_action(player, p_data, player_meta, trigger, stat, amount, update_data[6], update_data[7], update_data[8])
        else
            debug(flag27, "      cannot add 'amount' of zero. no update performed.'")
        end

    else
        if iterations > 0 then
            debug(flag27, "      this is a normal stat update")
            amount = amount / iterations
            -- the total 'amount' applied to 'stat' is spread equally among all iterations
        else
            debug(flag27, "      this is a perpetual stat update")
            iterations = -1

            -- 'timer' applies only for perpetual updates and is ignored for normal updates.
            -- it determines the wait time in seconds before the update performs its first
            -- iteration, after which it determines how many seconds between each interval.
            timer = update_data[5] -- setting timer to 'interval' value
        end

        p_data.stat_updates[id] = {
            trigger,
            stat,
            amount,
            iterations,
            update_data[5],
            timer,
            update_data[6],
            update_data[7],
            update_data[8]
        }
        stat_update_loop(player, p_data, player_meta, id)
    end

    debug(flag27, "    update_stat() END")
    return id
end
update_stat = ss.update_stat


-- global wrapper to reactivate a stat update while keeping the main stat_update_loop()
-- function local. the interval timer between iterations of each stat update also
-- resumes where it left off
function ss.restore_stat_update(player, p_data, player_meta, id)
    stat_update_loop(player, p_data, player_meta, id)
end


--- @param player_meta MetaDataRef used to access various player meta data
--- @param stat string player stat to be effected: health, hunger, thirst, etc
--- @param amount number the total amount of the stat to be depleted after 'days'
--- @param days number how many in-game days for the stat to fully deplete 'amount'
--- @param interval number how many seconds betweem each stat modification cycle
-- starts a stat update that modifies the stat's current value in a continuous loop
-- until manually stopped. used for scenarios like the slow hunger or thirst drain
-- throughout each day.
function ss.start_natural_stat_drain(player, p_data, player_meta, stat, amount, days, interval)
    if not player:is_player() then
        print("player no longer exists. function skipped.")
        return
    end

    -- total real-world seconds to fully restore/deplete 'amount'
    local depletion_time = GAMEDAY_IRL_SECONDS * days

    -- the total number of iterations to fully restore/deplete 'amount'
    local iterations = depletion_time / interval

    -- the portion of 'amount' to increase/decrease the stat by during each iteration
    -- in order to fully restore/deplete 'amount' within the desired number of 'days'
    local amount_per_iteration = amount / iterations

    local update_data = {"natural_drain", stat, amount_per_iteration, -1, interval, "curr", "add", true}
    update_stat(player, p_data, player_meta, update_data)

end
local start_natural_stat_drain = ss.start_natural_stat_drain



-- for testing purposes
local function debug_loop(player, p_data)
    print("\ndebug_loop()")

    if p_data.stat_updates == nil then
        print("\n stat_updates table not yet intialized")
    else
        print("\n stat_updates:")
        for id, update_data in pairs(p_data.stat_updates) do
            local trigger = update_data[1]
            local stat = update_data[2]
            local amount = update_data[3]
            local iterations = update_data[4]
            print("    [" .. id .. "] = { " .. trigger .. " " .. string.upper(stat) .. ", amnt = " .. amount .. ", iter = " .. iterations .. " }")
        end
    end
--[[
    if p_data.status_effects == nil then
        print("\n status_effects table not yet intialized")
    else
        print("\n status_effects:")
        for effect_name, effect_data in pairs(p_data.status_effects) do
            print("    [" .. effect_name .. "] = { " .. effect_data[1] .. " " .. effect_data[2] .. " " .. effect_data[3] .. " }")
        end
    end

    if p_data.se_stat_updates == nil then
        print("\n se_stat_updates table not yet intialized")
    else
        print("\n se_stat_updates:")
        for update_name, update_id in pairs(p_data.se_stat_updates) do
            print("    [" .. update_name .. "] = " .. update_id)
        end
    end
    --]]
    print("debug_loop() END " .. core.get_gametime())
    mt_after(0.5, debug_loop, player, p_data)
end


local flag20 = false
-- monitors for active status effects and triggers health consequences (stat updates)
-- depending on the type and severity of the setatus effect
local function monitor_status_effects(player, player_meta, player_name, p_data, status_effects)
    debug(flag20, "\nmonitor_status_effects()")
    if not player:is_player() then
        debug(flag20, "  player no longer exists. function skipped.")
        return
    end

    ------------
    -- HEALTH --
    ------------
    -- 100% to 31%  (normal range)
    -- 30% to 11%   'health_1'  comfort-, happiness-
    -- 10% to 1%    'health_2'  comfort--, happiness--
    -- 0%           (dead)

    if status_effects.health_1 then
        debug(flag20, "  applying stat effect for health_1")
        if p_data.health_1_applied then
            debug(flag20, "    health_1 single actions already applied. no further action.")
        else
            debug(flag20, "    add screen overlay and lower color saturation to 25%")
            update_visuals(player, player_name, player_meta, "health_1")
            p_data.health_1_applied = true
            p_data.health_2_applied = false
            p_data.health_3_applied = false
        end

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_health_1", "comfort", -COMFORT_DRAIN_VAL_HEALTH_1, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_health = p_data.comfort_loss_health + (COMFORT_DRAIN_VAL_HEALTH_1 * COMFORT_REC_FACTOR_HEALTH)
        player_meta:set_float("comfort_loss_health", p_data.comfort_loss_health)

        debug(flag20, "    applying happiness drain")
        update_data = {"se_health_1", "happiness", -0.05, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    elseif status_effects.health_2 then
        debug(flag20, "  applying stat effect for health_2")
        if p_data.health_2_applied then
            debug(flag20, "    health_2 single actions already applied. no further action.")
        else
            debug(flag20, "    add screen overlay and lower color saturation to 10%")
            update_visuals(player, player_name, player_meta, "health_2")
            p_data.health_1_applied = false
            p_data.health_2_applied = true
            p_data.health_3_applied = false
        end

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_health_2", "comfort", -COMFORT_DRAIN_VAL_HEALTH_2, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_health = p_data.comfort_loss_health + (COMFORT_DRAIN_VAL_HEALTH_2 * COMFORT_REC_FACTOR_HEALTH)
        player_meta:set_float("comfort_loss_health", p_data.comfort_loss_health)

        debug(flag20, "    applying happiness drain")
        update_data = {"se_health_2", "happiness", -0.10, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    elseif status_effects.health_3 then
        debug(flag20, "  applying stat effect for health_3")
        if p_data.health_3_applied then
            debug(flag20, "    health_3 single actions already applied. no further action.")
        else
            debug(flag20, "    add screen overlay and lower color saturation to 0%")
            update_visuals(player, player_name, player_meta, "health_3")
            p_data.health_1_applied = false
            p_data.health_2_applied = false
            p_data.health_3_applied = true
        end

    else
        debug(flag20, "  no active 'health' stat effects")
        if p_data.health_1_applied or p_data.health_2_applied or p_data.health_3_applied then
            update_visuals(player, player_name, player_meta, "health_0")
            p_data.health_1_applied = false
            p_data.health_2_applied = false
            p_data.health_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end

    ------------
    -- THIRST --
    ------------
    -- 100% to 31%  (normal range)
    -- 30% to 11%   'thirst_1'  stamina drain+
    -- 10% to 1%    'thirst_2'  stamina drain++
    -- 0%           'thirst_2'  stamina drain+++, ie_cold+, health-, immunity-, comfort-, happiness-
    if status_effects.thirst_1 then
        debug(flag20, "  applying stat effect for thirst_1")

        if p_data.thirst_1_applied then
            debug(flag20, "    thirst_1 single actions already applied. no further action.")
        else
            p_data.stamina_mod_thirst = 1.2
            player_meta:set_float("stamina_mod_thirst", 1.2)
            debug(flag20, "    increased stamina_mod_thirst factor to: " .. p_data.stamina_mod_thirst)
            p_data.thirst_1_applied = true
            p_data.thirst_2_applied = false
            p_data.thirst_3_applied = false
        end

    elseif status_effects.thirst_2 then
        debug(flag20, "  applying stat effect for thirst_2")

        if p_data.thirst_2_applied then
            debug(flag20, "    thirst_2 single actions already applied. no further action.")
        else
            p_data.stamina_mod_thirst = 1.3
            player_meta:set_float("stamina_mod_thirst", 1.3)
            debug(flag20, "   increased stamina_mod_thirst factor to: " .. p_data.stamina_mod_thirst)
            p_data.thirst_1_applied = false
            p_data.thirst_2_applied = true
            p_data.thirst_3_applied = false
        end

    elseif status_effects.thirst_3 then
        debug(flag20, "  applying stat effect for thirst_3")

        if p_data.thirst_3_applied then
            debug(flag20, "    thirst_3 single actions already applied. no further action.")
        else
            p_data.stamina_mod_thirst = 1.5
            player_meta:set_float("stamina_mod_thirst", 1.5)
            debug(flag20, "    increased stamina_mod_thirst factor to: " .. p_data.stamina_mod_thirst)
            p_data.thirst_1_applied = false
            p_data.thirst_2_applied = false
            p_data.thirst_3_applied = true
        end

        debug(flag20, "    applying health drain")
        local update_data = {"se_thirst_3", "health", -HP_DRAIN_VAL_THIRST_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.health_loss_thirst = p_data.health_loss_thirst + (HP_DRAIN_VAL_THIRST_3 * HP_REC_FACTOR_THIRST)
        player_meta:set_float("health_loss_thirst", p_data.health_loss_thirst)

        debug(flag20, "    applying immunity drain")
        update_data = {"se_thirst_3", "immunity", -0.01, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying comfort drain")
        update_data = {"se_thirst_3", "comfort", -COMFORT_DRAIN_VAL_THIRST_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_thirst = p_data.comfort_loss_thirst + (COMFORT_DRAIN_VAL_THIRST_3 * COMFORT_REC_FACTOR_THIRST)
        player_meta:set_float("comfort_loss_thirst", p_data.comfort_loss_thirst)

        debug(flag20, "    applying happiness drain")
        update_data = {"se_thirst_3", "happiness", -0.10, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'cold' immunity effect counter: 1/sec")
        update_data = {"ie_thirst_3", "cold", 1, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

    else
        debug(flag20, "  no active 'thirst' stat effects")
        if p_data.thirst_1_applied or p_data.thirst_2_applied or p_data.thirst_3_applied then
            debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.stamina_mod_thirst = 1
            player_meta:set_float("stamina_mod_thirst", 1)
            p_data.thirst_1_applied = false
            p_data.thirst_2_applied = false
            p_data.thirst_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    ------------
    -- HUNGER --
    ------------
    -- 100% to 31%  (normal range)
    -- 30% to 11%   'hunger_1'  stamina drain+
    -- 10% to 1%    'hunger_2'  stamina drain++
    -- 0%           'hunger_3'  stamina drain+++, ie_cold+, health-, immunity-, comfort-, happiness-
    if status_effects.hunger_1 then
        debug(flag20, "  applying stat effect for hunger_1")

        if p_data.hunger_1_applied then
            debug(flag20, "    hunger_1 single actions already applied. no further action.")
        else
            p_data.stamina_mod_hunger = 1.2
            player_meta:set_float("stamina_mod_hunger", 1.2)
            debug(flag20, "    increased stamina_mod_hunger factor to: " .. p_data.stamina_mod_hunger)
            p_data.hunger_1_applied = true
            p_data.hunger_2_applied = false
            p_data.hunger_3_applied = false
        end

    elseif status_effects.hunger_2 then
        debug(flag20, "  applying stat effect for hunger_2")

        if p_data.hunger_2_applied then
            debug(flag20, "    hunger_2 single actions already applied. no further action.")
        else
            p_data.stamina_mod_hunger = 1.3
            player_meta:set_float("stamina_mod_hunger", 1.3)
            debug(flag20, "   increased stamina_mod_hunger factor to: " .. p_data.stamina_mod_hunger)
            p_data.hunger_1_applied = false
            p_data.hunger_2_applied = true
            p_data.hunger_3_applied = false
        end

    elseif status_effects.hunger_3 then
        debug(flag20, "  applying stat effect for hunger_3")

        if p_data.hunger_3_applied then
            debug(flag20, "    hunger_3 single actions already applied. no further action.")
        else
            p_data.stamina_mod_hunger = 1.5
            player_meta:set_float("stamina_mod_hunger", 1.5)
            debug(flag20, "    increased stamina_mod_hunger factor to: " .. p_data.stamina_mod_hunger)
            p_data.hunger_1_applied = false
            p_data.hunger_2_applied = false
            p_data.hunger_3_applied = true
        end

        debug(flag20, "    applying health drain")
        local update_data = {"se_hunger_3", "health", -HP_DRAIN_VAL_HUNGER_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.health_loss_hunger = p_data.health_loss_hunger + (HP_DRAIN_VAL_HUNGER_3 * HP_REC_FACTOR_HUNGER)
        player_meta:set_float("health_loss_hunger", p_data.health_loss_hunger)

        debug(flag20, "    applying immunity drain")
        update_data = {"se_hunger_3", "immunity", -0.005, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying comfort drain")
        update_data = {"se_hunger_3", "comfort", -COMFORT_DRAIN_VAL_HUNGER_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_hunger = p_data.comfort_loss_hunger + (COMFORT_DRAIN_VAL_HUNGER_3 * COMFORT_REC_FACTOR_HUNGER)
        player_meta:set_float("comfort_loss_hunger", p_data.comfort_loss_hunger)

        debug(flag20, "    applying happiness drain")
        update_data = {"se_hunger_3", "happiness", -0.10, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'cold' immunity effect counter: 1/sec")
        update_data = {"ie_hunger_3", "cold", 1, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

    else
        debug(flag20, "  no active 'hunger' stat effects")
        if p_data.hunger_1_applied or p_data.hunger_2_applied or p_data.hunger_3_applied then
            debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.stamina_mod_hunger = 1
            player_meta:set_float("stamina_mod_hunger", 1)
            p_data.hunger_1_applied = false
            p_data.hunger_2_applied = false
            p_data.hunger_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end

    ---------------
    -- ALERTNESS --
    ---------------
    -- 100% to 31%  (normal range)
    -- 30% to 11%   'alertness_1'  stamina drain+
    -- 10% to 1%    'alertness_2'  stamina drain++
    -- 0%           'alertness_3'  stamina drain+++, ie_cold+, immunity-, sanity-, happiness-

    if status_effects.alertness_1 then
        debug(flag20, "  applying stat effect for alertness_1")

        if p_data.alertness_1_applied then
            debug(flag20, "    alertness_1 single actions already applied. no further action.")
        else
            p_data.stamina_mod_alertness = 1.2
            player_meta:set_float("stamina_mod_alertness", 1.2)
            debug(flag20, "    increased stamina_mod_alertness factor to: " .. p_data.stamina_mod_alertness)
            p_data.alertness_1_applied = true
            p_data.alertness_2_applied = false
            p_data.alertness_3_applied = false
        end

    elseif status_effects.alertness_2 then
        debug(flag20, "  applying stat effect for alertness_2")

        if p_data.alertness_2_applied then
            debug(flag20, "    alertness_2 single actions already applied. no further action.")
        else
            p_data.stamina_mod_alertness = 1.3
            player_meta:set_float("stamina_mod_alertness", 1.3)
            debug(flag20, "   increased stamina_mod_alertness factor to: " .. p_data.stamina_mod_alertness)
            p_data.alertness_1_applied = false
            p_data.alertness_2_applied = true
            p_data.alertness_3_applied = false
        end

    elseif status_effects.alertness_3 then
        debug(flag20, "  applying stat effect for alertness_3")

        if p_data.alertness_3_applied then
            debug(flag20, "    alertness_3 single actions already applied. no further action.")
        else
            p_data.stamina_mod_alertness = 1.5
            player_meta:set_float("stamina_mod_alertness", 1.5)
            debug(flag20, "    increased stamina_mod_alertness factor to: " .. p_data.stamina_mod_alertness)
            p_data.alertness_1_applied = false
            p_data.alertness_2_applied = false
            p_data.alertness_3_applied = true
        end

        debug(flag20, "    applying immunity drain")
        local update_data = {"se_alertness_3", "immunity", -0.005, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying sanity drain")
        update_data = {"se_alertness_3", "sanity", -0.10, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying happiness drain")
        update_data = {"se_alertness_3", "happiness", -0.10, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'cold' immunity effect counter: 1/sec")
        update_data = {"ie_alertness_3", "cold", 1, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

    else
        debug(flag20, "  no active 'alertness' stat effects")
        if p_data.alertness_1_applied or p_data.alertness_2_applied or p_data.alertness_3_applied then
            debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.stamina_mod_alertness = 1
            player_meta:set_float("stamina_mod_alertness", 1)
            p_data.alertness_1_applied = false
            p_data.alertness_2_applied = false
            p_data.alertness_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end

    -------------
    -- HYGIENE --
    -------------
    -- 100% to 31%  (normal range)
    -- 30% to 11%   'hygiene_1'  comfort-
    -- 10% to 1%    'hygiene_2'  comfort--
    -- 0%           'hygiene_3'  comfort---, immunity-, ie_bacterial+, +ie_fungal+, ie_viral+, ie_parastic+

    if status_effects.hygiene_1 then
        debug(flag20, "  no stat effect actions implemented for hygiene_1")

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_hygiene_1", "comfort", -COMFORT_DRAIN_VAL_HYGIENE_1, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_hygiene = p_data.comfort_loss_hygiene + (COMFORT_DRAIN_VAL_HYGIENE_1 * COMFORT_REC_FACTOR_HYGIENE)
        player_meta:set_float("comfort_loss_hygiene", p_data.comfort_loss_hygiene)

    elseif status_effects.hygiene_2 then
        debug(flag20, "  no stat effect actions implemented for hygiene_2")

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_hygiene_2", "comfort", -COMFORT_DRAIN_VAL_HYGIENE_2, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_hygiene = p_data.comfort_loss_hygiene + (COMFORT_DRAIN_VAL_HYGIENE_2 * COMFORT_REC_FACTOR_HYGIENE)
        player_meta:set_float("comfort_loss_hygiene", p_data.comfort_loss_hygiene)

    elseif status_effects.hygiene_3 then
        debug(flag20, "  applying stat effect for hygiene_3")

        debug(flag20, "    applying immunity drain")
        local update_data = {"se_hygiene_3", "immunity", -0.005, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying comfort drain")
        update_data = {"se_hygiene_3", "comfort", -COMFORT_DRAIN_VAL_HYGIENE_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_hygiene = p_data.comfort_loss_hygiene + (COMFORT_DRAIN_VAL_HYGIENE_3 * COMFORT_REC_FACTOR_HYGIENE)
        player_meta:set_float("comfort_loss_hygiene", p_data.comfort_loss_hygiene)

        debug(flag20, "    increasing 'bacterial_infection' immunity effect counter: 1/sec")
        update_data = {"ie_hygiene_3", "bacterial_infection", 1.0, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'fungal_infection' immunity effect counter: 1/sec")
        update_data = {"ie_hygiene_3", "fungal_infection", 0.8, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'viral_infection' immunity effect counter: 1/sec")
        update_data = {"ie_hygiene_3", "viral_infection", 0.6, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'parasitic_infection' immunity effect counter: 1/sec")
        update_data = {"ie_hygiene_3", "parasitic_infection", 0.4, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

    else
        debug(flag20, "  no active 'hygiene' stat effects")
    end

    -------------
    -- COMFORT --
    -------------

    if status_effects.comfort_1 then
        debug(flag20, "  no stat effect actions implemented for comfort_1")

    elseif status_effects.comfort_2 then
        debug(flag20, "  no stat effect actions implemented for comfort_2")

    elseif status_effects.comfort_3 then
        debug(flag20, "  no stat effect actions implemented for comfort_3")

    else
        debug(flag20, "  no active 'comfort' stat effects")
    end

    --------------
    -- IMMUNITY --
    --------------

    if status_effects.immunity_1 then
        debug(flag20, "  no stat effect actions implemented for immunity_1")

    elseif status_effects.immunity_2 then
        debug(flag20, "  no stat effect actions implemented for immunity_2")

    elseif status_effects.immunity_3 then
        debug(flag20, "  no stat effect actions implemented for immunity_3")

    else
        debug(flag20, "  no active 'immunity' stat effects")
    end

    ------------
    -- SANITY --
    ------------

    if status_effects.sanity_1 then
        debug(flag20, "  no stat effect actions implemented for sanity_1")

    elseif status_effects.sanity_2 then
        debug(flag20, "  no stat effect actions implemented for sanity_2")

    elseif status_effects.sanity_3 then
        debug(flag20, "  no stat effect actions implemented for sanity_3")

    else
        debug(flag20, "  no active 'sanity' stat effects")
    end

    ---------------
    -- HAPPINESS --
    ---------------
    -- 100% to 31%  (normal range)
    -- 30% to 11%   'happiness_1'
    -- 10% to 1%    'happiness_2'
    -- 0%           'happiness_3'   immunity-, ie_cold+

    if status_effects.happiness_1 then
        debug(flag20, "  no stat effect actions implemented for happiness_1")

        debug(flag20, "    applying immunity drain")
        local update_data = {"se_happiness_3", "immunity", -0.01, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    elseif status_effects.happiness_2 then
        debug(flag20, "  no stat effect actions implemented for happiness_2")

        debug(flag20, "    applying immunity drain")
        local update_data = {"se_happiness_3", "immunity", -0.02, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    elseif status_effects.happiness_3 then
        debug(flag20, "  applying effect for happiness_3")

        debug(flag20, "    applying immunity drain")
        local update_data = {"se_happiness_3", "immunity", -0.03, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'cold' immunity effect counter: 1/sec")
        update_data = {"ie_happiness_3", "cold", 1, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

    else
        debug(flag20, "  no active 'happiness' stat effects")
    end

    ------------
    -- BREATH --
    ------------
    -- 100% to 41%  (normal range)
    -- 40% to 21%   'breath_1'  comfort-
    -- 20% to 1%    'breath_2'  comfort--
    -- 0%           'breath_3'  comfort---, health-, sanity-, happiness-

    if status_effects.breath_1 then
        debug(flag20, "  no stat effect actions implemented for breath_1")

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_breath_1", "comfort", -COMFORT_DRAIN_VAL_BREATH_1, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_breath = p_data.comfort_loss_breath + (COMFORT_DRAIN_VAL_BREATH_1 * COMFORT_REC_FACTOR_BREATH)
        player_meta:set_float("comfort_loss_breath", p_data.comfort_loss_breath)

    elseif status_effects.breath_2 then
        debug(flag20, "  no stat effect actions implemented for breath_2")

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_breath_2", "comfort", -COMFORT_DRAIN_VAL_BREATH_2, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_breath = p_data.comfort_loss_breath + (COMFORT_DRAIN_VAL_BREATH_2 * COMFORT_REC_FACTOR_BREATH)
        player_meta:set_float("comfort_loss_breath", p_data.comfort_loss_breath)

    elseif status_effects.breath_3 then
        debug(flag20, "  no stat effect actions implemented for breath_3")

        debug(flag20, "    applying health drain based on a percentage of max health")
        local amount = player_meta:get_float("health_max") / HP_ZERO_TIME_BREATH_3
        local update_data = {"se_breath_3", "health", -amount, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.health_loss_breath = p_data.health_loss_breath + (amount * HP_REC_FACTOR_BREATH)
        player_meta:set_float("health_loss_breath", p_data.health_loss_breath)

        debug(flag20, "    applying sanity drain")
        update_data = {"se_breath_3", "sanity", -0.10, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying comfort drain")
        update_data = {"se_breath_3", "comfort", -COMFORT_DRAIN_VAL_BREATH_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_breath = p_data.comfort_loss_breath + (COMFORT_DRAIN_VAL_BREATH_3 * COMFORT_REC_FACTOR_BREATH)
        player_meta:set_float("comfort_loss_breath", p_data.comfort_loss_breath)

        debug(flag20, "    applying happiness drain")
        update_data = {"se_breath_3", "happiness", -0.10, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)        

    else
        --debug(flag20, "  no active 'breath' stat effects")
    end

    -------------
    -- STAMINA --
    -------------
    -- 100% to 41%   (normal range)
    -- 40% to 21%   'stamina_1' thirst-, hunger-, alertness-, hygiene-, comfort-, speed-, jump-
    -- 20% to 1%    'stamina_2' thirst--, hunger--, alertness--, hygiene--, comfort--, speed--, jump--
    -- 0%           'stamina_3' thirst---, hunger---, alertness---, hygiene---, comfort---, speed---, jump---

    if p_data.stamina_ratio > 0.40 then
        debug(flag20, "  stamina is between 100% and 41%")
        if p_data.stamina_0_applied then
            debug(flag20, "    stamina_0 single actions already applied. no further action.")
        else
            debug(flag20, "    updating visuals")
            update_visuals(player, player_name, player_meta, "stamina_0")
            p_data.speed_buff_exhaustion = 1
            p_data.jump_buff_exhaustion = 1
            update_player_physics(player, {"speed", "jump"})
            p_data.stamina_0_applied = true
            p_data.stamina_1_applied = false
            p_data.stamina_2_applied = false
            p_data.stamina_3_applied = false
        end

    elseif status_effects.stamina_1 then
        debug(flag20, "  applying stat effect for stamina_1")
        if p_data.stamina_1_applied then
            debug(flag20, "    stamina_1 single actions already applied. no further action.")
        else
            debug(flag20, "    add screen overlay and lower color saturation to 25%")
            update_visuals(player, player_name, player_meta, "stamina_1")
            p_data.speed_buff_exhaustion = 0.9
            p_data.jump_buff_exhaustion = 0.9
            update_player_physics(player, {"speed", "jump"})
            p_data.stamina_0_applied = false
            p_data.stamina_1_applied = true
            p_data.stamina_2_applied = false
            p_data.stamina_3_applied = false
        end
        debug(flag20, "    applying comfort drain")
        local update_data = {"se_stamina_1", "comfort", -COMFORT_DRAIN_VAL_STAMINA_1, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_stamina = p_data.comfort_loss_stamina + (COMFORT_DRAIN_VAL_STAMINA_1 * COMFORT_REC_FACTOR_STAMINA)
        player_meta:set_float("comfort_loss_stamina", p_data.comfort_loss_stamina)

        debug(flag20, "    applying alertness drain")
        update_data = {"se_stamina_1", "alertness", -0.04, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying hygiene drain")
        update_data = {"se_stamina_1", "hygiene", -0.04, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying thirst drain")
        update_data = {"se_stamina_1", "thirst", -0.04, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying hunger drain")
        update_data = {"se_stamina_1", "hunger", -0.04, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    elseif status_effects.stamina_2 then
        debug(flag20, "  applying stat effect for stamina_2")
        if p_data.stamina_2_applied then
            debug(flag20, "    stamina_2 single actions already applied. no further action.")
        else
            debug(flag20, "    add screen overlay and lower color saturation to 10%")
            update_visuals(player, player_name, player_meta, "stamina_2")
            p_data.speed_buff_exhaustion = 0.5
            p_data.jump_buff_exhaustion = 0.5
            update_player_physics(player, {"speed", "jump"})
            p_data.stamina_0_applied = false
            p_data.stamina_1_applied = false
            p_data.stamina_2_applied = true
            p_data.stamina_3_applied = false
        end
        debug(flag20, "    applying comfort drain")
        local update_data = {"se_stamina_2", "comfort", -COMFORT_DRAIN_VAL_STAMINA_2, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_stamina = p_data.comfort_loss_stamina + (COMFORT_DRAIN_VAL_STAMINA_2 * COMFORT_REC_FACTOR_STAMINA)
        player_meta:set_float("comfort_loss_stamina", p_data.comfort_loss_stamina)

        debug(flag20, "    applying alertness drain")
        update_data = {"se_stamina_2", "alertness", -0.08, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying hygiene drain")
        update_data = {"se_stamina_2", "hygiene", -0.08, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying thirst drain")
        update_data = {"se_stamina_2", "thirst", -0.08, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying hunger drain")
        update_data = {"se_stamina_2", "hunger", -0.08, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    elseif status_effects.stamina_3 then
        debug(flag20, "  applying stat effect for stamina_3")
        if p_data.stamina_3_applied then
            debug(flag20, "    stamina_3 single actions already applied. no further action.")
        else
            debug(flag20, "    add screen overlay and lower color saturation to 0%")
            update_visuals(player, player_name, player_meta, "stamina_3")
            p_data.speed_buff_exhaustion = 0.4
            p_data.jump_buff_exhaustion = 0.4
            update_player_physics(player, {"speed", "jump"})
            p_data.stamina_0_applied = false
            p_data.stamina_1_applied = false
            p_data.stamina_2_applied = false
            p_data.stamina_3_applied = true
        end
        debug(flag20, "    applying comfort drain")
        local update_data = {"se_stamina_3", "comfort", -COMFORT_DRAIN_VAL_STAMINA_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_stamina = p_data.comfort_loss_stamina + (COMFORT_DRAIN_VAL_STAMINA_3 * COMFORT_REC_FACTOR_STAMINA)
        player_meta:set_float("comfort_loss_stamina", p_data.comfort_loss_stamina)

        debug(flag20, "    applying alertness drain")
        update_data = {"se_stamina_3", "alertness", -0.16, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying hygiene drain")
        update_data = {"se_stamina_3", "hygiene", -0.16, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying thirst drain")
        update_data = {"se_stamina_3", "thirst", -0.16, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying hunger drain")
        update_data = {"se_stamina_3", "hunger", -0.16, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    else
        debug(flag20, "  ERROR - Unexpected condition: stamina is 40% or below, but stat effects not active.")
    end

    ------------
    -- WEIGHT --
    ------------
    -- 0% to 24%    (normal range)
    -- 25% to 49%   (normal range)
    -- 50% to 74%   'weight_1'  stamina drain+, comfort-
    -- 75% to 89%   'weight_2'  stamina drain++, comfort--
    -- 90% to 100%   'weight_3'  stamina drain+++, comfort---, health-

    if status_effects.weight_1 then
        debug(flag20, "  applying effect for weight_1")

        if p_data.weight_1_applied then
            debug(flag20, "    weight_1 single actions already applied. no further action.")
        else
            p_data.stamina_mod_weight = 1.2
            player_meta:set_float("stamina_mod_weight", 1.2)
            debug(flag20, "    increased stamina_mod_weight factor to: " .. p_data.stamina_mod_weight)
            p_data.weight_1_applied = true
            p_data.weight_2_applied = false
            p_data.weight_3_applied = false
        end

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_weight_1", "comfort", -COMFORT_DRAIN_VAL_WEIGHT_1, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_weight = p_data.comfort_loss_weight + (COMFORT_DRAIN_VAL_WEIGHT_1 * COMFORT_REC_FACTOR_WEIGHT)
        player_meta:set_float("comfort_loss_weight", p_data.comfort_loss_weight)

    elseif status_effects.weight_2 then
        debug(flag20, "  applying effect for weight_2")

        if p_data.weight_2_applied then
            debug(flag20, "    weight_2 single actions already applied. no further action.")
        else
            p_data.stamina_mod_weight = 1.3
            player_meta:set_float("stamina_mod_weight", 1.3)
            debug(flag20, "   increased stamina_mod_weight factor to: " .. p_data.stamina_mod_weight)
            p_data.weight_1_applied = false
            p_data.weight_2_applied = true
            p_data.weight_3_applied = false
        end

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_weight_2", "comfort", -COMFORT_DRAIN_VAL_WEIGHT_2, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_weight = p_data.comfort_loss_weight + (COMFORT_DRAIN_VAL_WEIGHT_2 * COMFORT_REC_FACTOR_WEIGHT)
        player_meta:set_float("comfort_loss_weight", p_data.comfort_loss_weight)

    elseif status_effects.weight_3 then
        debug(flag20, "  applying effect for weight_3")

        if p_data.weight_3_applied then
            debug(flag20, "    weight_3 single actions already applied. no further action.")
        else
            p_data.stamina_mod_weight = 1.5
            player_meta:set_float("stamina_mod_weight", 1.5)
            debug(flag20, "    increased stamina_mod_weight factor to: " .. p_data.stamina_mod_weight)
            p_data.weight_1_applied = false
            p_data.weight_2_applied = false
            p_data.weight_3_applied = true
        end

        debug(flag20, "    applying health drain")
        local update_data = {"se_weight_3", "health", -HP_DRAIN_VAL_WEIGHT_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.health_loss_weight = p_data.health_loss_weight + (HP_DRAIN_VAL_WEIGHT_3 * HP_REC_FACTOR_WEIGHT)
        player_meta:set_float("health_loss_weight", p_data.health_loss_weight)

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_weight_3", "comfort", -COMFORT_DRAIN_VAL_WEIGHT_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_weight = p_data.comfort_loss_weight + (COMFORT_DRAIN_VAL_WEIGHT_3 * COMFORT_REC_FACTOR_WEIGHT)
        player_meta:set_float("comfort_loss_weight", p_data.comfort_loss_weight)

    else
        debug(flag20, "  no active 'weight' stat effects")

        if p_data.weight_1_applied or p_data.weight_2_applied or p_data.weight_3_applied then
            debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.stamina_mod_weight = 1
            player_meta:set_float("stamina_mod_weight", 1)
            p_data.weight_1_applied = false
            p_data.weight_2_applied = false
            p_data.weight_3_applied = false
        end
    end

    ---------
    -- HOT --
    ---------
    -- 81 °F to 95 °F    'hot_1' "warm" thirst-, hygiene-
    -- 96 °F to 105 °F   'hot_2' "hot" thirst--, hygiene--, comfort-, stamina_rec-
    -- 106 °F to 120 °F  'hot_3' "sweltering" thirst---, hygiene---, comfort--, stamina_rec--, health-
    -- 121 °F or above   'hot_4' "scorching" thirst---, hygiene---, comfort---, stamina_rec---, health--

    if status_effects.hot_1 then
        debug(flag20, "  applying effect for hot_1")

        if p_data.hot_1_applied then
            debug(flag20, "    hot_1 single actions already applied. no further action.")
        else
            p_data.stamina_mod_hot = 1
            player_meta:set_float("stamina_mod_hot", 1)
            debug(flag20, "    reset stamina_mod_hot factor to: " .. p_data.stamina_mod_hot)
            update_visuals(player, player_name, player_meta, "hot_1")
            p_data.hot_1_applied = true
            p_data.hot_2_applied = false
            p_data.hot_3_applied = false
            p_data.hot_4_applied = false
        end

        debug(flag20, "    applying hygiene drain")
        local update_data = {"se_hot_1", "hygiene", -0.03, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying thirst drain")
        update_data = {"se_hot_1", "thirst", -0.03, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    elseif status_effects.hot_2 then
        debug(flag20, "  applying effect for hot_2")

        if p_data.hot_2_applied then
            debug(flag20, "    hot_2 single actions already applied. no further action.")
        else
            -- apply one-time stats mods or screen effects here
            p_data.stamina_mod_hot = 0.9
            player_meta:set_float("stamina_mod_hot", 0.9)
            debug(flag20, "    decreased stamina_mod_hot factor to: " .. p_data.stamina_mod_hot)
            update_visuals(player, player_name, player_meta, "hot_2")
            p_data.hot_1_applied = false
            p_data.hot_2_applied = true
            p_data.hot_3_applied = false
            p_data.hot_4_applied = false
        end

        debug(flag20, "    applying hygiene drain")
        local update_data = {"se_hot_2", "hygiene", -0.06, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying thirst drain")
        update_data = {"se_hot_2", "thirst", -0.06, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying comfort drain")
        update_data = {"se_hot_2", "comfort", -COMFORT_DRAIN_VAL_HOT_2, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_hot = p_data.comfort_loss_hot + (COMFORT_DRAIN_VAL_HOT_2 * COMFORT_REC_FACTOR_HOT)
        player_meta:set_float("comfort_loss_hot", p_data.comfort_loss_hot)

    elseif status_effects.hot_3 then
        debug(flag20, "  applying effect for hot_3")

        if p_data.hot_3_applied then
            debug(flag20, "    hot_3 single actions already applied. no further action.")
        else
            -- apply one-time stats mods or screen effects here
            p_data.stamina_mod_hot = 0.7
            player_meta:set_float("stamina_mod_hot", 0.7)
            debug(flag20, "    decreased stamina_mod_hot factor to: " .. p_data.stamina_mod_hot)
            update_visuals(player, player_name, player_meta, "hot_3")
            p_data.hot_1_applied = false
            p_data.hot_2_applied = false
            p_data.hot_3_applied = true
            p_data.hot_4_applied = false
        end

        debug(flag20, "    applying hygiene drain")
        local update_data = {"se_hot_3", "hygiene", -0.12, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying thirst drain")
        update_data = {"se_hot_3", "thirst", -0.12, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying comfort drain")
        update_data = {"se_hot_3", "comfort", -COMFORT_DRAIN_VAL_HOT_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_hot = p_data.comfort_loss_hot + (COMFORT_DRAIN_VAL_HOT_3 * COMFORT_REC_FACTOR_HOT)
        player_meta:set_float("comfort_loss_hot", p_data.comfort_loss_hot)

        debug(flag20, "    applying health drain")
        update_data = {"se_hot_3", "health", -HP_DRAIN_VAL_HOT_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.health_loss_hot = p_data.health_loss_hot + (HP_DRAIN_VAL_HOT_3 * HP_REC_FACTOR_HOT)
        player_meta:set_float("health_loss_hot", p_data.health_loss_hot)

    elseif status_effects.hot_4 then
        debug(flag20, "  applying effect for hot_4")

        if p_data.hot_4_applied then
            debug(flag20, "    hot_4 single actions already applied. no further action.")
        else
            -- apply one-time stats mods or screen effects here
            p_data.stamina_mod_hot = 0.5
            player_meta:set_float("stamina_mod_hot", 0.5)
            debug(flag20, "    decreased stamina_mod_hot factor to: " .. p_data.stamina_mod_hot)
            update_visuals(player, player_name, player_meta, "hot_4")
            p_data.hot_1_applied = false
            p_data.hot_2_applied = false
            p_data.hot_3_applied = false
            p_data.hot_4_applied = true
        end

        debug(flag20, "    applying hygiene drain")
        local update_data = {"se_hot_4", "hygiene", -0.18, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying thirst drain")
        update_data = {"se_hot_4", "thirst", -0.18, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    applying comfort drain")
        update_data = {"se_hot_4", "comfort", -COMFORT_DRAIN_VAL_HOT_4, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_hot = p_data.comfort_loss_hot + (COMFORT_DRAIN_VAL_HOT_4 * COMFORT_REC_FACTOR_HOT)
        player_meta:set_float("comfort_loss_hot", p_data.comfort_loss_hot)

        debug(flag20, "    applying health drain")
        update_data = {"se_hot_4", "health", -HP_DRAIN_VAL_HOT_4, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.health_loss_hot = p_data.health_loss_hot + (HP_DRAIN_VAL_HOT_4 * HP_REC_FACTOR_HOT)
        player_meta:set_float("health_loss_hot", p_data.health_loss_hot)

    else
        debug(flag20, "  no active 'hot' stat effects")
        if p_data.hot_1_applied or p_data.hot_2_applied
            or p_data.hot_3_applied or p_data.hot_4_applied then
            p_data.stamina_mod_hot = 1
            player_meta:set_float("stamina_mod_hot", 1)
            debug(flag20, "    reset stamina_mod_hot factor to: " .. p_data.stamina_mod_hot)
            update_visuals(player, player_name, player_meta, "hot_0")
            p_data.hot_1_applied = false
            p_data.hot_2_applied = false
            p_data.hot_3_applied = false
            p_data.hot_4_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end

    ----------
    -- COLD --
    ----------
    -- 60 °F to 46 °F   'cold_1' "cool" comfort-
    -- 45 °F to 31 °F   'cold_2' "cold" comfort--, immunity-, stamina_rec-, ie_cold+
    -- 30 °F to 11 °F   'cold_3' "frigid" comfort---, immunity--, stamina_rec---, ie_cold++, health-
    -- 10 °F or below   'cold_4' "freezing" comfort----, immunity---, stamina_rec----, ie_cold++, health--

    if status_effects.cold_1 then
        debug(flag20, "  applying effect for cold_1")

        if p_data.cold_1_applied then
            debug(flag20, "    cold_1 single actions already applied. no further action.")
        else
            p_data.stamina_mod_cold = 1
            player_meta:set_float("stamina_mod_cold", 1)
            debug(flag20, "    reset stamina_mod_cold factor to: " .. p_data.stamina_mod_hot)
            update_visuals(player, player_name, player_meta, "cold_1")
            p_data.cold_1_applied = true
            p_data.cold_2_applied = false
            p_data.cold_3_applied = false
            p_data.cold_4_applied = false
        end

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_cold_1", "comfort", -COMFORT_DRAIN_VAL_COLD_1, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_cold = p_data.comfort_loss_cold + (COMFORT_DRAIN_VAL_COLD_1 * COMFORT_REC_FACTOR_COLD)
        player_meta:set_float("comfort_loss_cold", p_data.comfort_loss_cold)

    elseif status_effects.cold_2 then
        debug(flag20, "  applying effect for cold_2")

        if p_data.cold_2_applied then
            debug(flag20, "    cold_2 single actions already applied. no further action.")
        else
            p_data.stamina_mod_cold = 0.9
            player_meta:set_float("stamina_mod_cold", 0.9)
            debug(flag20, "    decreased stamina_mod_cold factor to: " .. p_data.stamina_mod_cold)
            update_visuals(player, player_name, player_meta, "cold_2")
            p_data.cold_1_applied = false
            p_data.cold_2_applied = true
            p_data.cold_3_applied = false
            p_data.cold_4_applied = false
        end

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_cold_2", "comfort", -COMFORT_DRAIN_VAL_COLD_2, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_cold = p_data.comfort_loss_cold + (COMFORT_DRAIN_VAL_COLD_2 * COMFORT_REC_FACTOR_COLD)
        player_meta:set_float("comfort_loss_cold", p_data.comfort_loss_cold)

        debug(flag20, "    applying immunity drain")
        update_data = {"se_cold_2", "immunity", -0.01, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'cold' immunity effect counter: 1/sec")
        update_data = {"se_cold_2", "cold", 1, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

    elseif status_effects.cold_3 then
        debug(flag20, "  applying effect for cold_3")

        if p_data.cold_3_applied then
            debug(flag20, "    cold_3 single actions already applied. no further action.")
        else
            p_data.stamina_mod_cold = 0.7
            player_meta:set_float("stamina_mod_cold", 0.7)
            debug(flag20, "    decreased stamina_mod_cold factor to: " .. p_data.stamina_mod_cold)
            update_visuals(player, player_name, player_meta, "cold_3")
            p_data.cold_1_applied = false
            p_data.cold_2_applied = false
            p_data.cold_3_applied = true
            p_data.cold_4_applied = false
        end

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_cold_3", "comfort", -COMFORT_DRAIN_VAL_COLD_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_cold = p_data.comfort_loss_cold + (COMFORT_DRAIN_VAL_COLD_3 * COMFORT_REC_FACTOR_COLD)
        player_meta:set_float("comfort_loss_cold", p_data.comfort_loss_cold)

        debug(flag20, "    applying immunity drain")
        update_data = {"se_cold_3", "immunity", -0.02, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'cold' immunity effect counter: 1/sec")
        update_data = {"se_cold_3", "cold", 1, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

        debug(flag20, "    applying health drain")
        update_data = {"se_cold_3", "health", -HP_DRAIN_VAL_COLD_3, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.health_loss_cold = p_data.health_loss_cold + (HP_DRAIN_VAL_COLD_3 * HP_REC_FACTOR_COLD)
        player_meta:set_float("health_loss_cold", p_data.health_loss_cold)


    elseif status_effects.cold_4 then
        debug(flag20, "  applying effect for cold_4")

        if p_data.cold_4_applied then
            debug(flag20, "    cold_4 single actions already applied. no further action.")
        else
            p_data.stamina_mod_cold = 0.5
            player_meta:set_float("stamina_mod_cold", 0.5)
            debug(flag20, "    decreased stamina_mod_cold factor to: " .. p_data.stamina_mod_cold)
            update_visuals(player, player_name, player_meta, "cold_4")
            p_data.cold_1_applied = false
            p_data.cold_2_applied = false
            p_data.cold_3_applied = true
            p_data.cold_4_applied = false
        end

        debug(flag20, "    applying comfort drain")
        local update_data = {"se_cold_4", "comfort", -COMFORT_DRAIN_VAL_COLD_4, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.comfort_loss_cold = p_data.comfort_loss_cold + (COMFORT_DRAIN_VAL_COLD_4 * COMFORT_REC_FACTOR_COLD)
        player_meta:set_float("comfort_loss_cold", p_data.comfort_loss_cold)

        debug(flag20, "    applying immunity drain")
        update_data = {"se_cold_4", "immunity", -0.03, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        debug(flag20, "    increasing 'cold' immunity effect counter: 1/sec")
        update_data = {"se_cold_4", "cold", 1, 1, 1}
        update_immunity_effect(player, p_data, player_meta, update_data)

        debug(flag20, "    applying health drain")
        update_data = {"se_cold_4", "health", -HP_DRAIN_VAL_COLD_4, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)
        p_data.health_loss_cold = p_data.health_loss_cold + (HP_DRAIN_VAL_COLD_4 * HP_REC_FACTOR_COLD)
        player_meta:set_float("health_loss_cold", p_data.health_loss_cold)

    else
        debug(flag20, "  no active 'cold' stat effects")
        if p_data.cold_1_applied or p_data.cold_2_applied
            or p_data.cold_3_applied or p_data.cold_4_applied then
            p_data.stamina_mod_cold = 1
            player_meta:set_float("stamina_mod_cold", 1)
            debug(flag20, "    reset stamina_mod_cold factor to: " .. p_data.stamina_mod_cold)
            update_visuals(player, player_name, player_meta, "cold_0")
            p_data.cold_1_applied = false
            p_data.cold_2_applied = false
            p_data.cold_3_applied = false
            p_data.cold_4_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end



    debug(flag20, "monitor_status_effects() end")
    local job_handle = mt_after(1, monitor_status_effects, player, player_meta, player_name, p_data, status_effects)
    job_handles[player_name].monitor_status_effects = job_handle
end





local flag4 = false
-- decreases or incrases breath stat value depending on if player is under water
local function monitor_underwater_status(player, player_name, p_data, status_effects)
    debug(flag4, "\nmonitor_underwater_status()")
    if not player:is_player() then
        debug(flag4, "  player no longer exists. function skipped.")
        return
    end

    -- when crouching the head height should be 1 meter lower
    local current_anim = p_data.current_anim_state
    debug(flag4, "  current_anim_state: " .. current_anim)
    local head_height
    if string.sub(current_anim, 1, 6) == "crouch" then
        head_height = 0.5
    else
        head_height = 1.5
    end

    -- get the node name that is at player's head height
    local pos = player:get_pos()
    pos.y = pos.y + head_height
    local node = mt_get_node(pos)
    local node_name = node.name
    debug(flag4, "  node_name: " .. node_name)

    local player_meta = player:get_meta()
    local breath_current = player_meta:get_float("breath_current")
    local breath_max = player_meta:get_float("breath_max")
    debug(flag4, "  current " .. breath_current .. " | max " .. breath_max)

    if NODE_NAMES_WATER[node_name] then
        debug(flag4, "  ** underwater **")
        p_data.underwater = true
        p_data.played_breath_sound = false
        p_data.underwater_duration = p_data.underwater_duration + 1
        player_meta:set_int("underwater_duration", p_data.underwater_duration)
        debug(flag4, "  duration: " .. p_data.underwater_duration)

         -- the engine breath value is perpetually restored back to 100 whenever
         -- player is underwater to ensure it does not impact engine hp during
         -- gameplay. the 'breath_current' metadata value controls any hp impacts.
        player:set_breath(100)

        local amount = p_data.breath_deplete_rate
        local update_data = {"normal", "breath", -amount, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

    else
        debug(flag4, "  not underwater")
        p_data.underwater = false

        if p_data.played_breath_sound then
        else
            if p_data.underwater_duration > 15 then
                debug(flag4, "  underwater duration reached")
                play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "down", delay = 0})
                p_data.played_breath_sound = true
            elseif status_effects.breath_1 or status_effects.breath_2 or status_effects.breath_3 then
                play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "down", delay = 0})
                p_data.played_breath_sound = true
            end
        end
        p_data.underwater_duration = 0
        player_meta:set_int("underwater_duration", 0)

        if breath_current < breath_max then
            debug(flag4, "  restoring breath...")
            local amount = p_data.breath_restore_rate
            local update_data = {"normal", "breath", amount, 1, 1, "curr", "add", true}
            update_stat(player, p_data, player_meta, update_data)
        end
    end


    debug(flag4, "monitor_underwater_status() end")
    local job_handle = mt_after(1, monitor_underwater_status, player, player_name, p_data, status_effects)
    job_handles[player_name].monitor_underwater_status = job_handle
end


local IMMUNITY_CHECK_INTERVAL = 1800 -- 1800 seconds = 30 min = 12 hrs in-game time
--IMMUNITY_CHECK_INTERVAL = 5 -- for testing purposes

local flag11 = false

local function monitor_immunity(player, player_meta, player_name, p_data)
    debug(flag11, "\nmonitor_immunity()")
    if not player:is_player() then
        debug(flag11, "  player no longer exists. function skipped.")
        return
    end


    -- check for existence of status effects that impact immunity and
    -- perform actions here


    -- performs an 'immunity check' every in-game 12 hours to see if an immunity
    -- effect will be activated
    local timer = p_data.immunity_check_timer
    timer = timer + 1
    debug(flag11, "  timer: " .. timer)
    if timer < IMMUNITY_CHECK_INTERVAL then
        debug(flag11, "  immunity timer not reached. no action.")

    else
        debug(flag11, "  immunity timer reached. performing immunity check..")
        timer = 0
        local immunity_ratio = p_data.immunity_ratio
        debug(flag11, "  immunity_ratio: " .. immunity_ratio)
        local random_num = math.random()
        debug(flag11, "  random_num: " .. random_num)
        if random_num < immunity_ratio then
            debug(flag11, "  immunity check passed")
        else
            debug(flag11, "  immunity check failed. activating next immunity effect..")
            -- cycle through each immunity efffect
            -- find the one with the highest counter value
            -- activate that status effect
            -- reset that immunity effect counter to zero

        end
    end
    p_data.immunity_check_timer = timer
    player_meta:set_int("immunity_check_timer", timer)

    debug(flag11, "monitor_immunity() END")
    local job_handle = mt_after(1, monitor_immunity, player, player_meta, player_name, p_data)
    job_handles[player_name].monitor_immunity = job_handle
end


local flag17 = false
-- updates the weight display on the player inventory formspec according to
-- 'amount', which can be negative signifying a reduction in weight.
function ss.update_inventory_weight(player, weight_change)
    debug(flag17, "  update_inventory_weight()")
    debug(flag17, "    weight_change: " .. weight_change)
    local player_meta = player:get_meta()
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]

    -- update vertical statbar weight HUD
    local update_data = {"normal", "weight", weight_change, 1, 1, "curr", "add", true}
    update_stat(player, p_data, player_meta, update_data)
    debug(flag17, "    updated weight hudbar")

	-- update weight values display tied to inventory formspec
    local fs = player_data[player_name].fs
	fs.center.weight = get_fs_weight(player)
	player_meta:set_string("fs", mt_serialize(fs))
	local formspec = build_fs(fs)
	player:set_inventory_formspec(formspec)
    debug(flag17, "    updated weight formspec")
    debug(flag17, "  update_inventory_weight() END")
end
local update_inventory_weight = ss.update_inventory_weight


local flag18 = false
-- drops the 'item' from the player inventory and ensures the weight formspec
-- and weigth hud bar are also updated. does not call core.show_formspec()
function ss.drop_items_from_inventory(player, item)
    debug(flag18, "  drop_items_from_inventory()")
    debug(flag18, "    item name: " .. item:get_name())

    -- update weight formspec and hud
    local weight = get_itemstack_weight(item)
    debug(flag18, "    weight: " .. weight)
    update_inventory_weight(player, -weight)

    -- drop the items to the ground at player's feet
    local pos = player:get_pos()
    debug(flag18, "    player pos: " .. mt_pos_to_string(pos))
    mt_add_item(pos, item)
    debug(flag18, "    item spawned on ground")

    debug(flag18, "  drop_items_from_inventory() END")
end



local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() STATS")
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local p_data = player_data[player_name]
    local p_huds = player_hud_ids[player_name]

    --debug_loop(player, p_data) -- for testing purposes

    -- initialize the units of stamina gain/loss for each action
    p_data.stamina_gain_stand = 2.0
    p_data.stamina_gain_walk = 1.0
    p_data.stamina_gain_sit_cave = 2.0
    p_data.stamina_loss_jump = 3.0
    p_data.stamina_loss_walk_jump = 4.0
    p_data.stamina_loss_walk_jump_mine = 5.0
    p_data.stamina_loss_run = 1.5
    p_data.stamina_loss_run_jump = 6.0
    p_data.stamina_loss_crouch = 0.125
    p_data.stamina_loss_crouch_walk = 0.25
    p_data.stamina_loss_crouch_run = 1.4
    p_data.stamina_loss_crouch_jump = 3.0
    p_data.stamina_loss_crouch_walk_jump = 4.0
    p_data.stamina_loss_crouch_run_jump = 6.0
    p_data.stamina_loss_sit_cave_mine = 4.0

    -- for testing purposes
    --p_data.stamina_loss_jump = 0 
    --p_data.stamina_loss_walk_jump = 0
    --p_data.stamina_loss_run = 0
    --p_data.stamina_loss_crouch = 0
    --p_data.stamina_loss_crouch_walk = 0

    p_data.stamina_mod_thirst = 1
    p_data.stamina_mod_hunger = 1
    p_data.stamina_mod_alertness = 1
    p_data.stamina_mod_weight = 1
    p_data.stamina_mod_hot = 1
    p_data.stamina_mod_cold = 1


    -- inventory index of where the wield item was placed when in cave_sit state
    p_data.wield_item_index = 0

    -- the percentage of the wielded weapon's weight that is used as stamina loss
    -- vlue while swinging it
    p_data.stamina_loss_factor_mining = 0.5

    -- represents the ratio of the stat's current value against its max value.
    -- 0.9 = 90%, 0.5 = 50%, etc. initially set to -1 to signify this as a dummy
    -- startup value, and subsequent code will update to the 'live' weight ratio.
    p_data.health_ratio = -1
    p_data.thirst_ratio = -1
    p_data.hunger_ratio = -1
    p_data.alertness_ratio = -1
    p_data.hygiene_ratio = -1
    p_data.comfort_ratio = -1
    p_data.immunity_ratio = -1
    p_data.sanity_ratio = -1
    p_data.happiness_ratio = -1
    p_data.breath_ratio = -1
    p_data.stamina_ratio = -1
    p_data.weight_ratio = -1

    -- whether or not the player is currently underwater
    p_data.underwater = false

    -- tracks if the breath bar is currently shown on-screen. not saved in player
    -- metadata since this is for hud tracking and will always be false at start
    p_data.is_breathbar_shown = false

    -- indicates whether or not statbar settings were modified from the Settings
    -- tab and not yet applied
    p_data.statbar_settings_unsaved = false

    -- hide default health bar
    debug(flag1, "  hiding default MTG health bar..")
    player:hud_set_flags({ healthbar = false, breathbar = false })

    debug(flag1, "  initializing hud for stamina exhaustion screen color overlay..")
    p_huds.screen_effect = player:hud_add({
        type = "image",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        scale = {x = -100, y = -100},
        z_index = -9990,
        text = "", -- dummy value
    })

    debug(flag1, "  initializing hud for temperature related screen effect")
    p_huds.screen_effect_temperature = player:hud_add({
        type = "image",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        scale = {x = -100, y = -100},
        z_index = -9980,
        text = "", -- dummy value
    })

    debug(flag1, "  initializing hud for low health screen effect")
    p_huds.screen_effect_health = player:hud_add({
        type = "image",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        scale = {x = -100, y = -100},
        z_index = -9900,
        text = "", -- dummy value
    })

    debug(flag1, "  initializing black transparent box hud behind statbars..")
    p_huds.statbar_bg_box = player:hud_add({
        type = "image",
        position = {x = 0, y = 1},
        alignment = {x = 1, y = -1},
        offset = {x = 0, y = 0},
        scale = {x = 0, y = 0}, -- dummy values
        text = "", -- dummy value
    })

    debug(flag1, "  initializing huds for the main vertical statbars")
    local total_count = 0
    local active_count = 0
    for stat, stat_data in pairs(p_data.statbar_settings) do
        total_count = total_count + 1
        if stat_data.active then
            debug(flag1, "    hud for " .. stat)
            active_count = active_count + 1
            initialize_hud_stats(player, player_name, stat, stat_data)
        end
    end
    p_data.active_statbar_count = active_count
    p_data.total_statbar_count = total_count
    debug(flag1, "  statbar counts: active " .. active_count .. " | total " .. total_count)

    debug(flag1, "  initializing huds for the horizontal stamina and experience statbars")
    initialize_hud_stamina(player, player_name)
    initialize_hud_experience(player, player_name)

    debug(flag1, "  initializing huds for the small vertical breath and weight statbars")
    initialize_hud_breath(player, player_name)
    initialize_hud_weight(player, player_name)

    -- reflects any active status effects currently experienced by the player.
    -- once the player is back to normal condition, the status effect is removed
    -- from this table.
    -- Example: status_effects = {
    --  <status effect name> = {<type>, <duration, <hud location>},
    --  ["thirst_1"] = {"warning", ?, 2},
    --  ["hunger_3"] = {"infinite", ?, 1},
    --  ["immunity_2"] = {"timed", 15, 3}
    --}
    p_data.status_effects = {}

    -- always defaults to zero at game start but updated to proper value from
    -- player stat initializations further below
    p_data.status_effect_count = 0


    -- reflects any active stat updates that were triggered by a status effect.
    -- 'direction' refers to the stat update either increasing (up) or decreasing
    -- (down) the stat. the 'update_id' was obtained from the call to update_stat().
    -- Example: se_stat_updates = {
    --  <stat_effect_name + stat + direction> = update_id,
    --  ["rec_thirst_3_health_down"] = 928374657483,
    --  ["rec_alertness_3_immunity_down"] = 768798046352,
    --  ["rec_hunger_3_health_up"] = 195069781424,
    --}
    p_data.se_stat_updates = {}


    -- initialize hud elements relating to the stat effect images that appears along
    -- the left side of the screen
    initialize_hud_stat_effects(player, player_name, p_data)

    -- widen or narrow the background box behind the statbars and stat effects,
    -- and shift up or down the actual status effect hud elements
    update_statbar_effects_huds(player, player_name, p_data, active_count, p_huds.statbar_bg_box)


    local player_status = p_data.player_status
	if player_status == 0 then
		debug(flag1, "  new player")

        -- set the default screen effect. not using p_data as these properties are not
        -- accessed often, and when they are accessed, they typically need to be modified
        player_meta:set_float("screen_effect_saturation", 1)
        player_meta:set_float("screen_effect_bloom", 0)
        player:set_lighting({
            saturation = 1,
            bloom = {intensity = 0, strength_factor = 0.1, radius = 0.1}
        })

        -- the amount of breath that is depleted/restored at each loop in monitor_underwater_status()
        p_data.breath_deplete_rate = 3
        player_meta:set_float("breath_deplete_rate", p_data.breath_deplete_rate)
        p_data.breath_restore_rate = 16
        player_meta:set_float("breath_restore_rate", p_data.breath_restore_rate)

        -- the amount of stamina drained when using a fire drill to start a campfire
        p_data.stamina_loss_fire_drill = 20
        player_meta:set_int("stamina_loss_fire_drill", p_data.stamina_loss_fire_drill)

        -- this statbar settings 'pending' copy is the actual data that the Settings
        -- tab temporarily manipulates. only after the Apply button is pressed, is the
        -- data made permanent into the main 'statbar_settings' table above
        p_data.statbar_settings_pending = table.copy(p_data.statbar_settings)

        -- reflects any active player stat updates. once the stat updates have run
        -- its course, they are removed from this table. the table is indexed by a
        -- unique update id. the update data format depends on the first parameter
        -- which is the 'trigger'. refer to the ss.update_stat() definition relating
        --to 'stat_data' for more details.
        -- Example: stat_updates = {
        --  [id] = {"normal", stat, amount, iterations, interval, timer, type, action, allow_effects},
        --  [id] = {"natural_drain", stat, amount, iterations, interval, timer, type, action, allow_effects},
        --  [id] = {"se_hunger_2", stat, amount, iterations, interval, timer, type, action, allow_effects},
        --  [id] = {"ie_thirst_3", stat, amount, iterations, interval, timer},
        --  50156896669025 = {"normal", "health", 10, 1, ?, ?, "curr", "add", true},
        --  21732759583319 = {"natural_drain", "thirst", -1, -1, 60, ?, "curr", "add", true},
        --  64975821649754 = {"se_hunger_2", "immunity", -0.1, -1, 60, ?, "curr", "add", true},
        --  46923358451254 = {"ie_thirst_3", "cold", 1, 1, 1, ?},
        --}
        p_data.stat_updates = {}
        player_meta:set_string("stat_updates", mt_serialize(p_data.stat_updates))

        -- Example: stat_effect_hud_locations = {
        --  <hud location> = <status effect name>
        --  [1] = "hungr_3",
        --  [2] = "thirst_1"
        --}
        p_data.stat_effect_hud_locations = {}
        player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

        p_data.underwater_duration = 0
        player_meta:set_int("underwater_duration", p_data.underwater_duration)

        p_data.immunity_check_timer = 0
        player_meta:set_int("immunity_check_timer", p_data.immunity_check_timer)

        p_data.ie_counter_cold = 0
        player_meta:set_float("ie_counter_cold", p_data.ie_counter_cold)
        p_data.ie_counter_nausea = 0
        player_meta:set_float("ie_counter_nausea", p_data.ie_counter_nausea)
        p_data.ie_counter_diarrhea = 0
        player_meta:set_float("ie_counter_diarrhea", p_data.ie_counter_diarrhea)
        p_data.ie_counter_fungal_infection = 0
        player_meta:set_float("ie_counter_fungal_infection", p_data.ie_counter_fungal_infection)
        p_data.ie_counter_parasitic_infection = 0
        player_meta:set_float("ie_counter_parasitic_infection", p_data.ie_counter_parasitic_infection)
        p_data.ie_counter_bacterial_infection = 0
        player_meta:set_float("ie_counter_bacterial_infection", p_data.ie_counter_bacterial_infection)
        p_data.ie_counter_viral_infection = 0
        player_meta:set_float("ie_counter_viral_infection", p_data.ie_counter_viral_infection)
        p_data.ie_counter_prion_infection = 0
        player_meta:set_float("ie_counter_prion_infection", p_data.ie_counter_prion_infection)

        -- tracks how much hp lost via status effects relating to thirst, hunger,
        -- and breath, so that once the stat effect is over, that same amount of
        -- hp (or a calculated portion of it) can be recovered.
        p_data.health_loss_thirst = 0
        player_meta:set_float("health_loss_thirst", p_data.health_loss_thirst)
        p_data.health_loss_hunger = 0
        player_meta:set_float("health_loss_hunger", p_data.health_loss_hunger)
        p_data.health_loss_breath = 0
        player_meta:set_float("health_loss_breath", p_data.health_loss_breath)
        p_data.health_loss_weight = 0
        player_meta:set_float("health_loss_weight", p_data.health_loss_weight)
        p_data.health_loss_hot = 0
        player_meta:set_float("health_loss_hot", p_data.health_loss_hot)
        p_data.health_loss_cold = 0
        player_meta:set_float("health_loss_cold", p_data.health_loss_cold)

        p_data.comfort_loss_health = 0
        player_meta:set_float("comfort_loss_health", p_data.comfort_loss_health)
        p_data.comfort_loss_thirst = 0
        player_meta:set_float("comfort_loss_thirst", p_data.comfort_loss_thirst)
        p_data.comfort_loss_hunger = 0
        player_meta:set_float("comfort_loss_hunger", p_data.comfort_loss_hunger)
        p_data.comfort_loss_hygiene = 0
        player_meta:set_float("comfort_loss_hygiene", p_data.comfort_loss_hygiene)
        p_data.comfort_loss_breath = 0
        player_meta:set_float("comfort_loss_breath", p_data.comfort_loss_breath)
        p_data.comfort_loss_stamina = 0
        player_meta:set_float("comfort_loss_stamina", p_data.comfort_loss_stamina)
        p_data.comfort_loss_weight = 0
        player_meta:set_float("comfort_loss_weight", p_data.comfort_loss_weight)
        p_data.comfort_loss_hot = 0
        player_meta:set_float("comfort_loss_hot", p_data.comfort_loss_hot)
        p_data.comfort_loss_cold = 0
        player_meta:set_float("comfort_loss_cold", p_data.comfort_loss_cold)

        debug(flag1, "  initializing default base player physics for movement speed and jumping")
		local physics = player:get_physics_override()
		physics.speed = p_data.speed_walk
		physics.jump = p_data.height_jump
		player:set_physics_override(physics)

        debug(flag1, "  initialize default player stat values and stat bars")
        local update_data
        for _, stat_name in ipairs(STAT_NAMES) do
            update_data = {"normal", stat_name, DEFAULT_STAT_MAX[stat_name], 1, 1, "max", "set", false}
            update_stat(player, p_data, player_meta, update_data)
            update_data = {"normal", stat_name, DEFAULT_STAT_START[stat_name], 1, 1, "curr", "set", true}
            update_stat(player, p_data, player_meta, update_data)
        end

        debug(flag1, "  starting perpetual stat drains..")
        if ALLOW_PERPETUAL_THIRST_DRAIN then
            mt_after(0, start_natural_stat_drain, player, p_data, player_meta, "thirst", -100, 0.5, 5)
            debug(flag1, "    THIRST drain started")
        end
        if ALLOW_PERPETUAL_HUNGER_DRAIN then
            mt_after(0.25, start_natural_stat_drain, player, p_data, player_meta, "hunger", -100, 1.0, 5)
            debug(flag1, "    HUNGER drain started")
        end
        if ALLOW_PERPETUAL_ALERTNESS_DRAIN then
            mt_after(0.75, start_natural_stat_drain, player, p_data, player_meta, "alertness", -100, 1.0, 5)
            debug(flag1, "    ALERTNESS drain started")
        end

        -- add 1 second delay before triggering below 'monitor' functions to allow
        -- world and player to spawn before accessing object and/or node data.
        -- monitor_underwater_status() has an extra delay to allow monitor_player_state()
        -- from player_anim.lua to finish its 1-second delay and get up from crouching
        -- anim stat before monitor_underwater_status() checks if player is underwater.
        if ENABLE_UNDERWATER_CHECK then
            local job_handle = mt_after(1.2, monitor_underwater_status, player, player_name, p_data, p_data.status_effects)
            job_handles[player_name].monitor_underwater_status = job_handle
            debug(flag1, "  started breath monitor")
        end
        if ENABLE_IMMUNITY_MONITOR then
            local job_handle = mt_after(1, monitor_immunity, player, player_meta, player_name, p_data)
            job_handles[player_name].monitor_immunity = job_handle
            debug(flag1, "  started immunity monitor")
        end
        if ENABLE_STATUS_EFFECTS_MONITOR then
            local job_handle = mt_after(1, monitor_status_effects, player, player_meta, player_name, p_data, p_data.status_effects)
            job_handles[player_name].monitor_status_effects = job_handle
            debug(flag1, "  started status effects monitor")
        end


	elseif player_status == 1 then
		debug(flag1, "  existing player")

        player:set_lighting({
            saturation = player_meta:get_float("screen_effect_saturation"),
            bloom = {
                intensity = player_meta:get_float("screen_effect_bloom"),
                strength_factor = 0.1,
                radius = 0.1
            }
        })

        p_data.statbar_settings_pending = table.copy(p_data.statbar_settings)
        p_data.stat_effect_hud_locations = mt_deserialize(player_meta:get_string("stat_effect_hud_locations"))

        p_data.underwater_duration = player_meta:get_int("underwater_duration")
        p_data.immunity_check_timer = player_meta:get_int("immunity_check_timer")
        p_data.ie_counter_cold = player_meta:get_float("ie_counter_cold")
        p_data.ie_counter_nausea = player_meta:get_float("ie_counter_nausea")
        p_data.ie_counter_diarrhea = player_meta:get_float("ie_counter_diarrhea")
        p_data.ie_counter_fungal_infection = player_meta:get_float("ie_counter_fungal_infection")
        p_data.ie_counter_parasitic_infection = player_meta:get_float("ie_counter_parasitic_infection")
        p_data.ie_counter_bacterial_infection = player_meta:get_float("ie_counter_bacterial_infection")
        p_data.ie_counter_viral_infection = player_meta:get_float("ie_counter_viral_infection")
        p_data.ie_counter_prion_infection = player_meta:get_float("ie_counter_prion_infection")

        p_data.health_loss_thirst = player_meta:get_float("health_loss_thirst")
        p_data.health_loss_hunger = player_meta:get_float("health_loss_hunger")
        p_data.health_loss_breath = player_meta:get_float("health_loss_breath")
        p_data.health_loss_weight = player_meta:get_float("health_loss_weight")
        p_data.health_loss_hot = player_meta:get_float("health_loss_hot")
        p_data.health_loss_cold = player_meta:get_float("health_loss_cold")

        p_data.comfort_loss_health = player_meta:get_float("comfort_loss_health")
        p_data.comfort_loss_thirst = player_meta:get_float("comfort_loss_thirst")
        p_data.comfort_loss_hunger = player_meta:get_float("comfort_loss_hunger")
        p_data.comfort_loss_hygiene = player_meta:get_float("comfort_loss_hygiene")
        p_data.comfort_loss_breath = player_meta:get_float("comfort_loss_breath")
        p_data.comfort_loss_stamina = player_meta:get_float("comfort_loss_stamina")
        p_data.comfort_loss_weight = player_meta:get_float("comfort_loss_weight")
        p_data.comfort_loss_hot = player_meta:get_float("comfort_loss_hot")
        p_data.comfort_loss_cold = player_meta:get_float("comfort_loss_cold")

        p_data.breath_deplete_rate = player_meta:get_float("breath_deplete_rate")
        p_data.breath_restore_rate = player_meta:get_float("breath_restore_rate")
        p_data.stamina_loss_fire_drill = player_meta:get_int("stamina_loss_fire_drill")

        debug(flag1, "  restoring player movement speed and jump physics values..")
		local physics = player:get_physics_override()
		physics.speed = p_data.speed_walk
		physics.jump = p_data.height_jump
		player:set_physics_override(physics)

        p_data.stat_updates = mt_deserialize(player_meta:get_string("stat_updates"))
        local stat_updates = p_data.stat_updates
        if stat_updates == nil then
            debug(flag1, "  ERROR - 'stat_updates' table is NIL. set to empty table.")
            stat_updates = {}
        end
        debug(flag1, "  stat_updates: " .. dump(stat_updates))

		debug(flag1, "  restoring the main vertical player stat bars..")
        local update_data
        for _, stat_name in ipairs(STAT_NAMES) do
            local max_value = player_meta:get_float(stat_name .. "_max")
            local current_value = player_meta:get_float(stat_name .. "_current")
            update_data = {"normal", stat_name, max_value, 1, 1, "max", "set", false}
            update_stat(player, p_data, player_meta, update_data)
            update_data = {"normal", stat_name, current_value, 1, 1, "curr", "set", true}
            update_stat(player, p_data, player_meta, update_data)
        end

        debug(flag1, "  restoring any existing stat updates")
        local delay = 0
        for id, data in pairs(stat_updates) do
            local trigger = data[1]
            local tokens = string.split(trigger, "_")
            local prefix = tokens[1]
            if prefix == "normal" then
                debug(flag1, "  normal stat update")

            elseif prefix == "natural" then
                debug(flag1, "  natural_drain stat update")

            elseif prefix == "se" then
                debug(flag1, "  stat update triggered by a status effect")
                -- this is already handled by monitor_status_effects() function

            elseif prefix == "ie" then
                debug(flag1, "  immunity effect stat update. no further action.")
                -- this is already handled by monitor_status_effects() function

            elseif prefix == "rec" then
                debug(flag1, "  stat update to recover hp, triggered by a status effect")
                p_data.se_stat_updates[trigger] = id

            else
                debug(flag1, "  ERROR - Unexpected 'trigger' value: " .. trigger)
            end

            mt_after(delay, stat_update_loop, player, p_data, player_meta, id)
            delay = delay + 0.2  -- stagger them to prevent all running on same tick
        end

        if ENABLE_UNDERWATER_CHECK then
            local job_handle = mt_after(1.2, monitor_underwater_status, player, player_name, p_data, p_data.status_effects)
            job_handles[player_name].monitor_underwater_status = job_handle
            debug(flag1, "  started breath monitor")
        end
        if ENABLE_IMMUNITY_MONITOR then
            local job_handle = mt_after(1, monitor_immunity, player, player_meta, player_name, p_data)
            job_handles[player_name].monitor_immunity = job_handle
            debug(flag1, "  started immunity monitor")
        end
        if ENABLE_STATUS_EFFECTS_MONITOR then
            local job_handle = mt_after(1, monitor_status_effects, player, player_meta, player_name, p_data, p_data.status_effects)
            job_handles[player_name].monitor_status_effects = job_handle
            debug(flag1, "  started status effects monitor")
        end

        -- grant cooking XP to player due to item having finished cooking while player was offline
        local meta_key = "xp_cooking_" .. player_name
        local cooking_xp_owed = mod_storage:get_float(meta_key)
        debug(flag1, "      cooking_xp_owed: " .. cooking_xp_owed)
        if cooking_xp_owed > 0 then
            debug(flag1, "  ** owed cooking XP found **")
            local update_data = {"normal", "experience", cooking_xp_owed, 1, 1, "curr", "add", true}
            update_stat(player, p_data, player_meta, update_data)
            debug(flag1, "      player XP increased")
            mod_storage:set_float(meta_key, 0)
        else
            debug(flag1, "  no owed cooking XP")
        end


    elseif player_status == 2 then
		debug(flag1, "  dead player")

        player:set_lighting({
            saturation = player_meta:get_float("screen_effect_saturation"),
            bloom = {
                intensity = player_meta:get_float("screen_effect_bloom"),
                strength_factor = 0.1,
                radius = 0.1
            }
        })
        player:hud_change(p_huds.screen_effect_health, "text", "ss_screen_effect_health_3.png")

        -- intialize 'stat_updates' to empty table
        p_data.stat_updates = {}
        p_data.stat_effect_hud_locations = {}

        p_data.health_loss_thirst = player_meta:get_float("health_loss_thirst")
        p_data.health_loss_hunger = player_meta:get_float("health_loss_hunger")
        p_data.health_loss_breath = player_meta:get_float("health_loss_breath")
        p_data.health_loss_weight = player_meta:get_float("health_loss_weight")
        p_data.health_loss_hot = player_meta:get_float("health_loss_hot")
        p_data.health_loss_cold = player_meta:get_float("health_loss_cold")

        p_data.comfort_loss_health = player_meta:get_float("comfort_loss_health")
        p_data.comfort_loss_thirst = player_meta:get_float("comfort_loss_thirst")
        p_data.comfort_loss_hunger = player_meta:get_float("comfort_loss_hunger")
        p_data.comfort_loss_hygiene = player_meta:get_float("comfort_loss_hygiene")
        p_data.comfort_loss_breath = player_meta:get_float("comfort_loss_breath")
        p_data.comfort_loss_stamina = player_meta:get_float("comfort_loss_stamina")
        p_data.comfort_loss_weight = player_meta:get_float("comfort_loss_weight")
        p_data.comfort_loss_hot = player_meta:get_float("comfort_loss_hot")
        p_data.comfort_loss_cold = player_meta:get_float("comfort_loss_cold")

        -- show the current state of the statbars and any stat effect hud images
        -- as they were upon death
        debug(flag1, "  restore the main vertical player stat bars..")
        local update_data
        for _, stat_name in ipairs(STAT_NAMES) do
            local max_value = player_meta:get_float(stat_name .. "_max")
            local current_value = player_meta:get_float(stat_name .. "_current")
            update_data = {"normal", stat_name, max_value, 1, 1, "max", "set", false}
            update_stat(player, p_data, player_meta, update_data)
            update_data = {"normal", stat_name, current_value, 1, 1, "curr", "set", true}
            update_stat(player, p_data, player_meta, update_data)
        end

        debug(flag1, "  stat updates: " .. dump(p_data.stat_updates) .. "\n")
        debug(flag1, "  status effects: " .. dump(p_data.status_effects) .. "\n")

        -- do not trigger any actual status effect actions
        debug(flag1, "  stopping all status effects")
        for effect_name in pairs(p_data.status_effects) do
            debug(flag1, "    stopping " .. effect_name)
            p_data.status_effects[effect_name] = nil
        end
        debug(flag1, "  status effects (after): " .. dump(p_data.status_effects) .. "\n")

        -- do not trigger any actual stat update actions
        debug(flag1, "  stopping all stat updates")
        for id, update_data in pairs(p_data.stat_updates) do
            debug(flag1, "    stopping " .. update_data[2])
            p_data.stat_updates[id] = nil
        end
        debug(flag1, "  stat updates (after): " .. dump(p_data.stat_updates) .. "\n")

	end

	debug(flag1, "register_on_joinplayer() end")
end)


local flag15 = false
core.register_on_dieplayer(function(player)
    debug(flag15, "\nregister_on_dieplayer() STATS")

    -- wrapped in core.after() to allow the function that set hp to zero do_stat_update_action()
    -- to complete the rest of its execution before dieplayer() code is executed
    mt_after(0, function()
        local player_meta = player:get_meta()
        local player_name = player:get_player_name()
        local p_data = player_data[player_name]

        player_meta:set_int("player_status", 2)
        p_data.player_status = 2

        debug(flag15, "  cancel any existing stat updates..")
        local stat_updates = p_data.stat_updates
        debug(flag15, "  stat_updates (before): " .. dump(stat_updates))
        for id, update_data in pairs(stat_updates) do
            debug(flag15, "    stopping stat update id: " .. id .. " for " .. update_data[2])
            stat_updates[id] = nil
        end
        debug(flag15, "  stat_updates (after): " .. dump(stat_updates))

        debug(flag15, "  cancel any existing status effects..")
        local status_effects = p_data.status_effects
        debug(flag15, "  status_effects (before): " .. dump(status_effects))
        for effect_name in pairs(status_effects) do
            debug(flag15, "    stopping stat effect: " .. effect_name)
            status_effects[effect_name] = nil
            -- this does not remove the stat effect huds from the screen, which is fine since
            -- the player should see what all ailments and injuries existed upon their death =)
            -- the stat effect huds will be removed during register_on_respawnplayer()
        end
        debug(flag15, "  status_effects (after): " .. dump(status_effects))

        debug(flag15, "  cancel any existing se_stat_updates..")
        local se_stat_updates = p_data.se_stat_updates
        debug(flag15, "  se_stat_updates (before): " .. dump(se_stat_updates))
        for update_name in pairs(se_stat_updates) do
            debug(flag15, "    stopping se_stat_updates: " .. update_name)
            se_stat_updates[update_name] = nil

        end
        debug(flag15, "  se_stat_updates (after): " .. dump(se_stat_updates))

        debug(flag15, "  cancel monitor_underwater_status() loop..")
        local job_handle = job_handles[player_name].monitor_underwater_status
        job_handle:cancel()
        job_handles[player_name].monitor_underwater_status = nil

        debug(flag15, "  cancel monintor_immunity() loop..")
        job_handle = job_handles[player_name].monitor_immunity
        job_handle:cancel()
        job_handles[player_name].monitor_immunity = nil

        debug(flag15, "  cancel monitor_status_effects() loop..")
        job_handle = job_handles[player_name].monitor_status_effects
        job_handle:cancel()
        job_handles[player_name].monitor_status_effects = nil

        debug(flag15, "  resetting player inventory weight to zero..")
        local update_data = {"normal", "weight", DEFAULT_STAT_MAX.weight, 1, 1, "max", "set", false}
        update_stat(player, p_data, player_meta, update_data)
        update_data = {"normal", "weight", 0, 1, 1, "curr", "set", true}
        update_stat(player, p_data, player_meta, update_data)
        update_fs_weight(player, player_meta)
    end)

    debug(flag15, "register_on_dieplayer() end")
end)



local flag16 = false
core.register_on_respawnplayer(function(player)
    debug(flag16, "\nregister_on_respawnplayer() STATS")
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local p_data = ss.player_data[player_name]

    debug(flag16, "  set player_status = 1")
    player_meta:set_int("player_status", 1)
    p_data.player_status = 1

    debug(flag16, "  reset stamina gain values for certain actions")
    p_data.stamina_gain_stand = 2.0
    p_data.stamina_gain_walk = 1.0
    p_data.stamina_gain_sit_cave = 2.0

    debug(flag16, "  reset stamina loss values for certain actions")
    p_data.stamina_loss_jump = 3.0
    p_data.stamina_loss_walk_jump = 4.0
    p_data.stamina_loss_walk_jump_mine = 5.0
    p_data.stamina_loss_run = 1.5
    p_data.stamina_loss_run_jump = 6.0
    p_data.stamina_loss_crouch = 0.125
    p_data.stamina_loss_crouch_walk = 0.25
    p_data.stamina_loss_crouch_run = 1.4
    p_data.stamina_loss_crouch_jump = 3.0
    p_data.stamina_loss_crouch_walk_jump = 4.0
    p_data.stamina_loss_crouch_run_jump = 6.0
    p_data.stamina_loss_sit_cave_mine = 4.0
    p_data.stamina_loss_factor_mining = 0.5

    p_data.stamina_mod_thirst = 1
    p_data.stamina_mod_hunger = 1
    p_data.stamina_mod_alertness = 1
    p_data.stamina_mod_weight = 1
    p_data.stamina_mod_hot = 1
    p_data.stamina_mod_cold = 1

    debug(flag16, "  reset breath stat related properties")
    p_data.underwater = false
    p_data.is_breathbar_shown = false

    p_data.breath_deplete_rate = 3
    player_meta:set_float("breath_deplete_rate",p_data.breath_deplete_rate)
    p_data.breath_restore_rate = 16
    player_meta:set_float("breath_restore_rate", p_data.breath_restore_rate)

    debug(flag16, "  reset wield item index, weight tier, and statbar settings status")
    p_data.wield_item_index = 0
    p_data.weight_ratio = 0
    p_data.statbar_settings_unsaved = false

    debug(flag16, "  resetting hud for stamina exhaustion screen color overlay")
    player:hud_change(
        player_hud_ids[player_name].screen_effect,
        "text",
        "[fill:1x1:0,0:#888844^[opacity:0"
    )

    -- ### not resetting black transparent box hud behind statbars
    -- ### not resetting huds for the main vertical statbars
    -- ### not resetting huds for the horizontal stamina and experience statbars
    -- ### not resetting huds for the small vertical breath and weight statbars

    -- not resetting these two tables, but keeping same data from prior play session.
    -- these are loaded from joinplayer() function of global_vars_init.lua.
    --p_data.statbar_settings = {}
    --p_data.stats_bg_opacity = {}

    debug(flag16, "  hide any stat effects huds that remained onscreen during death")
    local hud_id
    for i = 1, p_data.total_statbar_count + 3 do
        hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. i]
        player:hud_change(hud_id, "text", "[fill:1x1:0,0:#00000080")
        player:hud_change(hud_id, "scale", {x = 0, y = 0})

        hud_id = player_hud_ids[player_name]["stat_effect_image_" .. i]
        player:hud_change(hud_id, "text", "")

        hud_id = player_hud_ids[player_name]["stat_effect_text_" .. i]
        player:hud_change(hud_id, "text", "")
        player:hud_change(hud_id, "number", "0x000000")
    end

    debug(flag16, "  reset screen effects due to any status effects")
    player_meta:set_float("screen_effect_saturation", 1)
    player_meta:set_float("screen_effect_bloom", 0)
    player:set_lighting({
        saturation = 1,
        bloom = {intensity = 0, strength_factor = 0.1, radius = 0.1}
    })
    hud_id = player_hud_ids[player_name].screen_effect_health
    player:hud_change(hud_id, "text", "")

    debug(flag16, "  reset stat updates table to empty")
    p_data.stat_updates = {}
    player_meta:set_string("stat_updates", mt_serialize(p_data.stat_updates))

    debug(flag16, "  reset status effect related properties and tables")
    p_data.status_effect_count = 0
    p_data.status_effects = {}
    player_meta:set_string("status_effects", mt_serialize(p_data.status_effects))
    p_data.stat_effect_udpate_ids = {}
    player_meta:set_string("stat_effect_udpate_ids", mt_serialize(p_data.stat_effect_udpate_ids))
    p_data.stat_effect_hud_locations = {}
    player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

    debug(flag16, "  remove any screen effects from status effects")
    player:set_lighting({
        saturation = 1,
        bloom = {intensity = 0, strength_factor = 0.1, radius = 0.1}
    })

    p_data.underwater_duration = 0
    player_meta:set_int("underwater_duration", p_data.underwater_duration)

    debug(flag16, "  reset immunity effects related properties")
    p_data.immunity_check_timer = 0
    player_meta:set_int("immunity_check_timer", p_data.immunity_check_timer)
    p_data.ie_counter_cold = 0
    player_meta:set_float("ie_counter_cold", p_data.ie_counter_cold)
    p_data.ie_counter_nausea = 0
    player_meta:set_float("ie_counter_nausea", p_data.ie_counter_nausea)
    p_data.ie_counter_diarrhea = 0
    player_meta:set_float("ie_counter_diarrhea", p_data.ie_counter_diarrhea)
    p_data.ie_counter_fungal_infection = 0
    player_meta:set_float("ie_counter_fungal_infection", p_data.ie_counter_fungal_infection)
    p_data.ie_counter_parasitic_infection = 0
    player_meta:set_float("ie_counter_parasitic_infection", p_data.ie_counter_parasitic_infection)
    p_data.ie_counter_bacterial_infection = 0
    player_meta:set_float("ie_counter_bacterial_infection", p_data.ie_counter_bacterial_infection)
    p_data.ie_counter_viral_infection = 0
    player_meta:set_float("ie_counter_viral_infection", p_data.ie_counter_viral_infection)
    p_data.ie_counter_prion_infection = 0
    player_meta:set_float("ie_counter_prion_infection", p_data.ie_counter_prion_infection)

    p_data.health_loss_thirst = 0
    player_meta:set_float("health_loss_thirst", p_data.health_loss_thirst)
    p_data.health_loss_hunger = 0
    player_meta:set_float("health_loss_hunger", p_data.health_loss_hunger)
    p_data.health_loss_breath = 0
    player_meta:set_float("health_loss_breath", p_data.health_loss_breath)
    p_data.health_loss_weight = 0
    player_meta:set_float("health_loss_weight", p_data.health_loss_weight)
    p_data.health_loss_hot = 0
    player_meta:set_float("health_loss_hot", p_data.health_loss_hot)
    p_data.health_loss_cold = 0
    player_meta:set_float("health_loss_cold", p_data.health_loss_cold)

    p_data.comfort_loss_health = 0
    player_meta:set_float("comfort_loss_health", p_data.comfort_loss_health)
    p_data.comfort_loss_thirst = 0
    player_meta:set_float("comfort_loss_thirst", p_data.comfort_loss_thirst)
    p_data.comfort_loss_hunger = 0
    player_meta:set_float("comfort_loss_hunger", p_data.comfort_loss_hunger)
    p_data.comfort_loss_hygiene = 0
    player_meta:set_float("comfort_loss_hygiene", p_data.comfort_loss_hygiene)
    p_data.comfort_loss_breath = 0
    player_meta:set_float("comfort_loss_breath", p_data.comfort_loss_breath)
    p_data.comfort_loss_stamina = 0
    player_meta:set_float("comfort_loss_stamina", p_data.comfort_loss_stamina)
    p_data.comfort_loss_weight = 0
    player_meta:set_float("comfort_loss_weight", p_data.comfort_loss_weight)
    p_data.comfort_loss_hot = 0
    player_meta:set_float("comfort_loss_hot", p_data.comfort_loss_hot)
    p_data.comfort_loss_cold = 0
    player_meta:set_float("comfort_loss_cold", p_data.comfort_loss_cold)

    debug(flag16, "  stamina loss value from using fire drill")
    p_data.stamina_loss_fire_drill = 20
    player_meta:set_int("stamina_loss_fire_drill", p_data.stamina_loss_fire_drill)

    debug(flag16, "  reset statbar_settings_pending table to mirror statbar_settings")
    p_data.statbar_settings_pending = table.copy(p_data.statbar_settings)


    debug(flag16, "  reset to default movement speed and jumping height")
    local physics = player:get_physics_override()
    physics.speed = p_data.speed_walk
    physics.jump = p_data.height_jump
    player:set_physics_override(physics)

    debug(flag16, "  reset player stat max and stat current value to defaults")
    local update_data
    for _, stat_name in ipairs(STAT_NAMES) do
        update_data = {"normal", stat_name, DEFAULT_STAT_MAX[stat_name], 1, 1, "max", "set", false}
        update_stat(player, p_data, player_meta, update_data)
        update_data = {"normal", stat_name, DEFAULT_STAT_START[stat_name], 1, 1, "curr", "set", true}
        update_stat(player, p_data, player_meta, update_data)
    end

    debug(flag16, "  start perpetual stat drains..")
    if ALLOW_PERPETUAL_THIRST_DRAIN then
        mt_after(0, start_natural_stat_drain, player, p_data, player_meta, "thirst", -100, 0.5, 5)
        debug(flag16, "    THIRST drain started")
    end
    if ALLOW_PERPETUAL_HUNGER_DRAIN then
        mt_after(0.25, start_natural_stat_drain, player, p_data, player_meta, "hunger", -100, 1.0, 5)
        debug(flag16, "    HUNGER drain started")
    end
    if ALLOW_PERPETUAL_ALERTNESS_DRAIN then
        mt_after(0.75, start_natural_stat_drain, player, p_data, player_meta, "alertness", -100, 1.0, 5)
        debug(flag16, "    ALERTNESS drain started")
    end

    if ENABLE_UNDERWATER_CHECK then
        local job_handle = mt_after(1.2, monitor_underwater_status, player, player_name, p_data, p_data.status_effects)
        job_handles[player_name].monitor_underwater_status = job_handle
        debug(flag16, "  enabled breath monitor")
    end
    if ENABLE_IMMUNITY_MONITOR then
        local job_handle = mt_after(1, monitor_immunity, player, player_meta, player_name, p_data)
        job_handles[player_name].monitor_immunity = job_handle
        debug(flag16, "  started immunity monitor")
    end
    if ENABLE_STATUS_EFFECTS_MONITOR then
        local job_handle = mt_after(1, monitor_status_effects, player, player_meta, player_name, p_data, p_data.status_effects)
        job_handles[player_name].monitor_status_effects = job_handle
        debug(flag1, "  started status effects monitor")
    end

    debug(flag16, "register_on_respawnplayer() END")
end)


local flag19 = false
core.register_on_leaveplayer(function(player)
    debug(flag19, "\nregister_on_leaveplayer() STATS")
    local player_name = player:get_player_name()

    local job_handle = job_handles[player_name].monitor_underwater_status
    if job_handle then
        job_handle:cancel()
        job_handles[player_name].monitor_underwater_status = nil
        debug(flag19, "  cancelled monitor_underwater_status() loop..")
    end

    job_handle = job_handles[player_name].monitor_immunity
    if job_handle then
        job_handle:cancel()
        job_handles[player_name].monitor_immunity = nil
        debug(flag19, "  cancelled monintor_immunity() loop..")
    end

    job_handle = job_handles[player_name].monitor_status_effects
    if job_handle then
        job_handle:cancel()
        job_handles[player_name].monitor_status_effects = nil
        debug(flag19, "  cancelled monitor_status_effects() loop..")
    end

    debug(flag19, "register_on_leaveplayer() END")
end)