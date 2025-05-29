print("- loading player_stats.lua")

-- cache global functions for faster access
local math_round = math.round
local math_ceil = math.ceil
local math_floor = math.floor
local math_random = math.random
local string_len = string.len
local string_split = string.split
local string_sub = string.sub
local string_upper = string.upper
local table_copy = table.copy
local table_concat = table.concat
local table_insert = table.insert
local mt_get_modpath = core.get_modpath
local mt_after = core.after
local mt_get_node = core.get_node
local mt_sound_play = core.sound_play
local mt_serialize = core.serialize
local mt_deserialize = core.deserialize
local mt_add_item = core.add_item
local debug = ss.debug
local round = ss.round
local notify = ss.notify
local after_player_check = ss.after_player_check
local build_fs = ss.build_fs
local get_fs_player_stats = ss.get_fs_player_stats
local get_fs_weight = ss.get_fs_weight
local update_fs_weight = ss.update_fs_weight
local get_itemstack_weight = ss.get_itemstack_weight
local play_sound = ss.play_sound
local convert_to_celcius = ss.convert_to_celcius

-- cache global variables for faster access
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids
local job_handles = ss.job_handles
local mod_storage = ss.mod_storage

-- foward-declare functions
ss.update_stat = nil
local update_stat = ss.update_stat

-- periodically checks if player is underwater and then displays/hides breath statbar
-- depending on the player's underwater status
ss.ENABLE_UNDERWATER_CHECK = true
local ENABLE_UNDERWATER_CHECK = ss.ENABLE_UNDERWATER_CHECK

local ENABLE_BASELINE_STATS_MONITOR = true

-- the stat names are listed in a specific order where the first 9 are referred to
-- by monitor_baseline_stats(), and the entire list is referred to when all stat
-- bars and stat values are initialized via join player and respawn player callbacks
local STAT_NAMES = {"health", "thirst", "hunger", "alertness", "hygiene", "comfort",
    "immunity", "sanity", "happiness", "legs", "hands", "breath", "stamina", "weight",
    "experience"}

-- these are essentially like stats above but they don't have stat bars. they are
-- used to determine thresholds for activating external status effects. these external
-- stats use the same functions that manage stat updates and status effects.
local EXT_STAT_NAMES = {"illness", "poison", "wetness"}


-- default initial values for player stats. stored in the player metadata as
-- '<stat>_current', for example: 'health_current'
local DEFAULT_STAT_START = {
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
    experience = 0,
    weight = 0,
    legs = 100,
    hands = 100,
    illness = 0,
    poison = 0,
    wetness = 0,
}


-- default maximum values for player stats. stored in the player metadata as
-- '<stat>_max', for example: 'health_max'
local DEFAULT_STAT_MAX = {
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
    weight = ss.SLOT_WEIGHT_MAX * ss.INV_SIZE_START,
    legs = 100,
    hands = 100,
    illness = 100,
    poison = 100,
    wetness = 100,
}


-- the assigned color for all statbars
local STATBAR_COLORS = {
    health = "#C00000",     -- darker red
    thirst = "#0080C0",     -- light blue
    hunger = "#C08000",     -- darker orange
    alertness = "#9F51B6",  -- purple
    hygiene = "#51bfc0",    -- light blue
    comfort = "#906f25",    -- brown
    immunity = "#CCFFFF",   -- bluish white
    sanity = "#E15079",     -- dark pink
    happiness = "#d2c023",  -- yellow
    breath = "#FFFFFF",     -- white
    stamina = "#00C000",    -- green
    experience = "#6551b6", -- darker purple
    weight = "#C0C000",     -- yellow
    legs = "#d79682",       -- tan
    hands = "#d79682",      -- tan
}

-- the assigned color for the 'base value' markers overlaid on each statbar
local STATBAR_COLORS_BASE = {
    health = "#ff8080",     -- darker red
    thirst = "#80d4ff",     -- light blue
    hunger = "#ffd580",     -- darker orange
    alertness = "#f0bfff",  -- purple
    hygiene = "#bffeff",    -- light blue
    comfort = "#c9b996",    -- brown
    immunity = "#30bfbf",   -- bluish white
    sanity = "#ffbfd1",     -- dark pink
    happiness = "#fff9bf",  -- yellow
    legs = "#ffd6c9",       -- tan
    hands = "#ffd6c9",      -- tan
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
local Y_POS = -27

-- x offsets for the huds relating to the main vertical stat bars
local vertical_statbar_x_pos = {20, 50, 80, 110, 140, 170, 200, 230, 260, 290, 320}

-- horizontal position of all vertical statbars (does not apply to experience statbar)
local horizontal_statbar_x_pos = {
    breath = -245,
    weight = 245
}

local Y_POS_BREATH = -24


ss.STATUS_EFFECT_INFO = {}

-- Reads “status_effect_info.txt” and fills the global table STATUS_EFFECT_INFO
-- helper functions
local function trim(s)            return (s:gsub("^%s*(.-)%s*$", "%1")) end
local function isempty(s)         return s == "" or s == nil            end
local function add_hash(s)        return isempty(s) and nil or ("#"  .. s) end
local function add_0x(s)          return isempty(s) and nil or ("0x" .. s) end

local path  = mt_get_modpath("ss") .. "/status_effect_info.txt"

-- io.lines closes the file automatically
local current   = nil   -- current status‑effect name (string)
local stage     = 0     -- which sub‑field we’re filling
for raw in io.lines(path) do
    local line = trim(raw)

    -- skip comments & blanks
    if isempty(line) or line:sub(1,1) == "#" then goto continue end

    -- a new status‑effect header?
    if not current then
        current = line
        stage   = 0
        ss.STATUS_EFFECT_INFO[current] = {
            desc        = nil, fix        = nil, tooltip    = nil,
            bg_color    = nil, text_color = nil, text       = nil,
            notify_up   = nil, notify_down= nil,
        }
        goto continue
    end

    local info = ss.STATUS_EFFECT_INFO[current]

    -- branch for “_0” (only notify*)
    if current:match("_0$") then
        local _, val = line:match("([^=]+)=(.*)")
        info.notify_down = trim(val)
        current = nil  -- done with this entry
        goto continue
    end

    -- branch for _1, _2, … (full 6‑line block)
    stage = stage + 1
    if stage == 1 then
        info.desc = line

    elseif stage == 2 then
        info.fix = line

    elseif stage == 3 then
        info.tooltip = line

    elseif stage == 4 then
        -- bg_color=000000, text_color=FFA800, text=
        local bg, tc, txt = line:match("bg_color=(%x+),%s*text_color=(%x+),%s*text=(.*)")
        info.bg_color    = add_hash(bg)
        info.text_color  = add_0x(tc)
        info.text        = isempty(txt) and nil or txt

    elseif stage == 5 then
        local _, val = line:match("([^=]+)=(.*)")
        info.notify_up   = isempty(val) and nil or trim(val)

    elseif stage == 6 then
        local _, val = line:match("([^=]+)=(.*)")
        info.notify_down = isempty(val) and nil or trim(val)
        -- finished one complete record
        current, stage = nil, 0
    end

    ::continue::
end
local STATUS_EFFECT_INFO = ss.STATUS_EFFECT_INFO
--print("### ss.STATUS_EFFECT_INFO: " .. dump(ss.STATUS_EFFECT_INFO))

-- used to calculate the size of the transparent bg behind the stat effect iamges
local STAT_EFFECT_BG_HEIGHT = 32

-- the base width of the status effect hud black background box, which does not
-- account for the size of the text label
local STAT_EFFECT_BG_WIDTH = 59

-- a constant adjustment factor multiplied to the status effect text lable size
local STAT_EFFECT_BG_WIDTH_EXTRA = 8

-- recovery and drain speeds of stats that brings its value toward its base value
-- cycles once per second. one hour represents 24 hours in-game. the change rates
-- are based on how much total stat value will be drained after 1hr (or 1 in-game day).
-- '100/seconds_per_hour' = 100 stat points drained after 1 in-game day"
-- '25/seconds_per_hour' = 25 stat points drained after 1 in-game day"
local seconds_per_hour = 3600
local change_rate_thirst = round(100/seconds_per_hour, 6)
local change_rate_hunger = round(50/seconds_per_hour, 6)
local change_rate_alertness = round(75/seconds_per_hour, 6)
local change_rate_hygene = round(25/seconds_per_hour, 6)
--change_rate_thirst = 0 -- for testing purposes
--change_rate_hunger = 0 -- for testing purposes

ss.BASE_STATS_DATA = {
    health = {base_value = 100, recovery_speed = 0.01, drain_speed = 0.01},
    thirst = {base_value = 0, recovery_speed = change_rate_thirst, drain_speed = change_rate_thirst},
    hunger = {base_value = 0, recovery_speed = change_rate_hunger, drain_speed = change_rate_hunger},
    alertness = {base_value = 0, recovery_speed = change_rate_alertness, drain_speed = change_rate_alertness},
    hygiene = {base_value = 0, recovery_speed = change_rate_hygene, drain_speed = change_rate_hygene},
    comfort = {base_value = 80, recovery_speed = 0.01, drain_speed = 0.01},
    immunity = {base_value = 80, recovery_speed = 0.01, drain_speed = 0.01},
    sanity = {base_value = 80, recovery_speed = 0.01, drain_speed = 0.01},
    happiness = {base_value = 80, recovery_speed = 0.01, drain_speed = 0.01},
    legs = {base_value = 100, recovery_speed = 0.01, drain_speed = 0.01},
    hands = {base_value = 100, recovery_speed = 0.01, drain_speed = 0.01},

    -- 'recovery_speed' = speed of rising getting worse. 'drain_speed' = speed of lowering getting better
    illness = {base_value = 0, recovery_speed = 0.01, drain_speed = 0.01},
    poison = {base_value = 0, recovery_speed = 0.01, drain_speed = 0.01},

    -- recovery and drain speeds managed by monitor_underwater_status()
    --wetness = {base_value = 0, recovery_speed = 1.00, drain_speed = 1.01},

    -- 'recovery_speed' and 'drain_speed' currently unused (for now) since these
    -- stats don't use monitor_baseline_stat() and instead have custom recover/drain
    -- mechanisms, and upgrade_stat_max() expects 'base_value' property.
    breath = {base_value = 100, recovery_speed = 0, drain_speed = 0},
    experience = {base_value = 100, recovery_speed = 0, drain_speed = 0},
    stamina = {base_value = 100, recovery_speed = 0, drain_speed = 0},
}
local BASE_STATS_DATA = ss.BASE_STATS_DATA


-- converts seconds to a string format "xxh xxm xxs", of hours, minutes, and seconds
function ss.convert_seconds(time)
    local hours = math_floor(time / 3600)
    local minutes = math_floor((time % 3600) / 60)
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
        offset = {x = horizontal_statbar_x_pos.breath, y = Y_POS_BREATH},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = 0, y = 0},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name].breath.bg = player:hud_add(hud_definition)

    -- statbar icon
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.breath, y = Y_POS + 28},
        text = "ss_statbar_icon_breath.png",
        scale = {x = 0, y = 0},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name].breath.icon = player:hud_add(hud_definition)

    -- main colored stat bar
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.breath, y = Y_POS_BREATH},
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
        offset = {x = horizontal_statbar_x_pos.weight, y = Y_POS_BREATH},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = STATBAR_WIDTH_MINI, y = STATBAR_HEIGHT_MINI},
        alignment = {x = 0, y = -1}
    }
    player:hud_add(hud_definition)

    -- statbar icon
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.weight, y = Y_POS + 24},
        text = "ss_statbar_icon_weight.png",
        scale = {x = 1.3, y = 1.3},
        alignment = {x = 0, y = -1}
    }
    player:hud_add(hud_definition)

    -- main colored stat bar
    hud_definition = {
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = horizontal_statbar_x_pos.weight, y = Y_POS_BREATH},
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

    -- setting black background for statbar
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = vertical_statbar_x_pos[hud_position], y = Y_POS - 5},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = STATBAR_WIDTH, y = STATBAR_HEIGHT},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name][stat].bg = player:hud_add(hud_definition)

    -- setting stat icon image for statbar
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = vertical_statbar_x_pos[hud_position], y = Y_POS + 22},
        text = "ss_statbar_icon_" .. stat .. ".png",
        scale = {x = 1.3, y = 1.3},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name][stat].icon = player:hud_add(hud_definition)

    -- setting the main colored stat bar
    local stat_bar_value = 1
    if stat_value_current then
        debug(flag7, "      stat_value_current: " .. stat_value_current)
        local player_meta = player:get_meta()
        local stat_value_max = player_meta:get_float(stat .. "_max")
        stat_bar_value = (stat_value_current / stat_value_max) * STATBAR_HEIGHT
    end
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = vertical_statbar_x_pos[hud_position], y = Y_POS - 5},
        text = "[fill:1x1:0,0:" .. STATBAR_COLORS[stat],
        scale = {x = STATBAR_WIDTH - 6, y = stat_bar_value},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name][stat].bar = player:hud_add(hud_definition)

    -- setting the 'base value' marker overlaid on the stat bar
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = vertical_statbar_x_pos[hud_position], y = Y_POS - 5},
        text = "[fill:1x1:0,0:" .. STATBAR_COLORS_BASE[stat],
        scale = {x = STATBAR_WIDTH - 6, y = 3},
        alignment = {x = 0, y = -1}
    }
    player_hud_ids[player_name][stat].base = player:hud_add(hud_definition)

    debug(flag7, "        player_hud_ids[player_name][stat]: " .. dump(player_hud_ids[player_name][stat]))
    debug(flag7, "    initialize_hud_stats() END")
end
local initialize_hud_stats = ss.initialize_hud_stats



local flag2 = false
local function initialize_hud_stat_effects(player, player_name, on_screen_max)
    debug(flag2, "  initialize_hud_stat_effects()")

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


local flag9 = false
function ss.shift_hud_stat_effects(player, p_data, player_name, move_upward)
    debug(flag9, "    shift_hud_stat_effects()")

    local hud_id, hud_def, offset_data
    local y_offset = 140
    if move_upward then y_offset = y_offset * -1 end

    for i = 1, p_data.on_screen_max do
        --debug(flag9, "      raising BG for hud index " .. i)
        hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. i]
        hud_def = player:hud_get(hud_id)
        offset_data = hud_def.offset
        offset_data.y = offset_data.y + y_offset
        player:hud_change(hud_id, "offset", offset_data)

        --debug(flag9, "      raising IMAGE for hud index " .. i)
        hud_id = player_hud_ids[player_name]["stat_effect_image_" .. i]
        hud_def = player:hud_get(hud_id)
        offset_data = hud_def.offset
        offset_data.y = offset_data.y + y_offset
        player:hud_change(hud_id, "offset", offset_data)

        --debug(flag9, "      raising TEXT for hud index " .. i)
        hud_id = player_hud_ids[player_name]["stat_effect_text_" .. i]
        hud_def = player:hud_get(hud_id)
        offset_data = hud_def.offset
        offset_data.y = offset_data.y + y_offset
        player:hud_change(hud_id, "offset", offset_data)
    end

    debug(flag9, "    shift_hud_stat_effects() END")
end
local shift_hud_stat_effects = ss.shift_hud_stat_effects


local function initialize_hud_scren_effects(player, p_huds, effect_type, z_index)
    p_huds["screen_effect_" .. effect_type] = player:hud_add({
        type = "image",
        position = {x = 0, y = 0},
        alignment = {x = 1, y = 1},
        scale = {x = -100, y = -100},
        z_index = z_index,
        text = "", -- dummy value
    })
end


local flag11 = false
function ss.update_base_stat_value(player, player_meta, player_name, p_data, stat_list)
    debug(flag11, "\n  update_base_stat_value()")
    --debug(flag11, "    stat_list: " .. dump(stat_list))

    for i = 1, #stat_list do
        local stat = stat_list[i]
        --debug(flag11, "    stat: " .. stat)
        local new_baseline_value
        if stat == "health" then
            new_baseline_value = BASE_STATS_DATA.health.base_value
                * p_data.base_health_mod_thirst
                * p_data.base_health_mod_hunger
                * p_data.base_health_mod_alertness
                * p_data.base_health_mod_immunity
                * p_data.base_health_mod_hot
                * p_data.base_health_mod_cold
                * p_data.base_health_mod_illness
                * p_data.base_health_mod_poison
                * p_data.base_health_mod_legs
                * p_data.base_health_mod_hands
                p_data.base_value_health = new_baseline_value
                player_meta:set_float("base_value_health", new_baseline_value)

        elseif stat == "comfort" then
            new_baseline_value = BASE_STATS_DATA.comfort.base_value
                * p_data.base_comfort_mod_health
                * p_data.base_comfort_mod_thirst
                * p_data.base_comfort_mod_hunger
                * p_data.base_comfort_mod_hygiene
                * p_data.base_comfort_mod_breath
                * p_data.base_comfort_mod_stamina
                * p_data.base_comfort_mod_weight
                * p_data.base_comfort_mod_hot
                * p_data.base_comfort_mod_cold
                * p_data.base_comfort_mod_illness
                * p_data.base_comfort_mod_poison
                * p_data.base_comfort_mod_legs
                * p_data.base_comfort_mod_hands
                p_data.base_value_comfort = new_baseline_value
                player_meta:set_float("base_value_comfort", new_baseline_value)

        elseif stat == "immunity" then
            new_baseline_value = BASE_STATS_DATA.immunity.base_value
                * p_data.base_immunity_mod_thirst
                * p_data.base_immunity_mod_hunger
                * p_data.base_immunity_mod_alertness
                * p_data.base_immunity_mod_hygiene
                * p_data.base_immunity_mod_happiness
                * p_data.base_immunity_mod_cold
                p_data.base_value_immunity = new_baseline_value
                player_meta:set_float("base_value_immunity", new_baseline_value)

        elseif stat == "sanity" then
            new_baseline_value = BASE_STATS_DATA.sanity.base_value
                * p_data.base_sanity_mod_health
                * p_data.base_sanity_mod_alertness
                * p_data.base_sanity_mod_breath
                p_data.base_value_sanity = new_baseline_value
                player_meta:set_float("base_value_sanity", new_baseline_value)

        elseif stat == "happiness" then
            new_baseline_value = BASE_STATS_DATA.happiness.base_value
                * p_data.base_happiness_mod_alertness
                * p_data.base_happiness_mod_comfort
                p_data.base_value_happiness = new_baseline_value
                player_meta:set_float("base_value_happiness", new_baseline_value)

        else
            new_baseline_value = p_data["base_value_" .. stat]
        end
        --debug(flag11, "      new_baseline_value: " .. new_baseline_value)

        --debug(flag11, "    updating baseline value marker hud..")
        if stat == "breath" or stat == "experience" or stat == "stamina"
            or stat == "illness" or stat == "poison" or stat == "wetness" then
            -- pending: these stats require slightly tweaked code since their statbar data are
            -- not part of the 'statbar_settings' table since their statbars are not vertical
            -- or simply non-existent
            --debug(flag11, "      pending implemenation. no further action.")
        else
            local statbar_setting = p_data.statbar_settings[stat]
            if statbar_setting.active then
                local hud_id = player_hud_ids[player_name][stat].base
                local x_offset = vertical_statbar_x_pos[statbar_setting.hud_pos]
                local base_value_ratio = new_baseline_value / player_meta:get_float(stat .. "_max")
                --debug(flag11, "      base_value_ratio: " .. base_value_ratio)
                local base_value_statbar_height = base_value_ratio * STATBAR_HEIGHT
                --debug(flag11, "      base_value_statbar_height: " .. base_value_statbar_height)
                player:hud_change(hud_id, "offset", {x = x_offset, y = Y_POS - 5 - base_value_statbar_height})
            else
                --debug(flag11, "    this stat is hidden (not active). no further action.")
            end
        end

    end

    debug(flag11, "  update_base_stat_value() END")
end
local update_base_stat_value = ss.update_base_stat_value


local flag29 = false
function ss.stop_stat_update(p_data, player_meta, id)
    debug(flag29, "\nstop_stat_update()")
    --debug(flag29, "  id: " .. id)
    local stat_updates = p_data.stat_updates
    local update_data = stat_updates[id]
    update_data[4] = 0
    --debug(flag29, "  iterations for " .. update_data[2] .. " set to zero")
    player_meta:set_string("stat_updates", mt_serialize(p_data.stat_updates))
    --debug(flag29, "  stat_updates: " .. dump(stat_updates))
    debug(flag29, "stop_stat_update() END")
end


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
    --debug(flag3, "        effect_name: " .. effect_name)
    --debug(flag3, "        status_effects (before): " .. dump(status_effects))
    local status_effect_count = p_data.status_effect_count
    local effect_data = status_effects[effect_name]
    local hud_location = effect_data[3]
    --debug(flag3, "        status_effect_count: " .. status_effect_count)
    --debug(flag3, "        hud_location: " .. hud_location)

    local stat_effects_to_move_count = status_effect_count - hud_location
    --debug(flag3, "        stat_effects_to_move_count: " .. stat_effects_to_move_count)
    if stat_effects_to_move_count > 0 then
        --debug(flag3, "        there are stat effects located above " .. effect_name)

        -- update stat effect hud elements
        for i = 1, stat_effects_to_move_count do
            local prev_location = hud_location + i
            local new_location = prev_location - 1

            local this_effect_name = p_data.stat_effect_hud_locations[prev_location]
            local type = status_effects[this_effect_name][1]
            local duration = status_effects[this_effect_name][2]
            --debug(flag3, "          this_effect_name: " .. this_effect_name)
            local tokens = string_split(this_effect_name, "_")
            local stat = tokens[1]

            local hud_id, prev_hud_def
            hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. prev_location]
            prev_hud_def = player:hud_get(hud_id)
            hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. new_location]
            player:hud_change(hud_id, "text", prev_hud_def.text)
            player:hud_change(hud_id, "scale", prev_hud_def.scale)
            --debug(flag3, "          hud_def.text: " .. prev_hud_def.text)
            --debug(flag3, "          hud_def.scale: " .. dump(prev_hud_def.scale))

            local scale = 1.8
            if stat == "legs" or stat == "hands" then scale = 0.9 end
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. prev_location]
            prev_hud_def = player:hud_get(hud_id)
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. new_location]
            player:hud_change(hud_id, "text", prev_hud_def.text)
            player:hud_change(hud_id, "scale", {x = scale, y = scale})
            --debug(flag3, "          hud_def.text: " .. prev_hud_def.text)

            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. prev_location]
            prev_hud_def = player:hud_get(hud_id)
            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. new_location]
            player:hud_change(hud_id, "text", prev_hud_def.text)
            player:hud_change(hud_id, "number", prev_hud_def.number)
            --debug(flag3, "          hud_def.text: " .. prev_hud_def.text)
            --debug(flag3, "          hud_def.number: " .. prev_hud_def.number)

            status_effects[this_effect_name] = {type, duration, new_location}
            p_data.stat_effect_hud_locations[new_location] = this_effect_name
        end
    end

    --debug(flag3, "        all stat effects now shifted downward. hiding the stopped stat effect..")
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
    --debug(flag3, "        stat_effect_hud_locations (updated): " .. dump(p_data.stat_effect_hud_locations))

    -- update active status effect count
    local new_effect_count = status_effect_count - 1
    p_data.status_effect_count = new_effect_count

    -- remove the status effect from the stat effect table
    status_effects[effect_name] = nil
    --debug(flag3, "        status_effects (updated): " .. dump(status_effects))

    debug(flag3, "      hide_stat_effect() END")
end
local hide_stat_effect = ss.hide_stat_effect



local function get_unique_id()
    local id = tonumber(core.get_us_time() .. math_random(10, 99))
    if id then
        return id
    else
        return 0
    end
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
    after_player_check(player)
    --debug(flag5, "      effect_name: " .. effect_name)

    if status_effects[effect_name] == nil then
        --debug(flag5, "      stat effect already stopped")
        --debug(flag5, "    stat_effect_loop() END")
        return
    end

    ------------------------------------
    -- update status effect hud elements
    ------------------------------------

    local effect_data = status_effects[effect_name]
    local type = effect_data[1]
    local duration = effect_data[2]
    local hud_location = effect_data[3]
    --debug(flag5, "      duration: " .. duration)

    if false then

    elseif type == "percentage" then
        -- update stat effect text label
        local text = round(p_data[stat .. "_ratio"] * 100, 1) .. "%"
        local hud_id = player_hud_ids[player_name]["stat_effect_text_" .. hud_location]
        player:hud_change(hud_id, "text", text)
        --debug(flag5, "      text: " .. text)

        -- update stat effect background hud width size
        local total_width = STAT_EFFECT_BG_WIDTH + (string_len(text) * STAT_EFFECT_BG_WIDTH_EXTRA)
        hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. hud_location]
        player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
        --debug(flag5, "      total_width: " .. total_width)

        mt_after(1, stat_effect_loop, player, player_meta, player_name, p_data,
        status_effects, effect_name, stat, severity)

    elseif type == "weather" then
        local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. hud_location]

        -- update stat effect text label
        local text = math_round(p_data.thermal_feels_like) .. " °F"
        if p_data.thermal_units == 2 then
            text = convert_to_celcius(p_data.thermal_feels_like, 1) .. " °C"
        end
        --debug(flag5, "      text: " .. text)

        -- update stat effect background hud width size
        local text_length = string_len(text)
        local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
        player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
        --debug(flag5, "      total_width: " .. total_width)

        -- update stat effect text hud
        hud_id = player_hud_ids[player_name]["stat_effect_text_" .. hud_location]
        player:hud_change(hud_id, "text", text)
        --debug(flag5, "      text: " .. text)

        mt_after(1, stat_effect_loop, player, player_meta, player_name, p_data,
        status_effects, effect_name, stat, severity)

    elseif type == "wetness" then

        -- update the stat effect text label
        local effect_info = STATUS_EFFECT_INFO[effect_name]
        local text = round(p_data.wetness_ratio * 100, 1) .. "%"
        --debug(flag5, "      text: " .. text)

        -- update the width size of the stat effect black background hud
        local text_length = string_len(text)
        local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
        local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. hud_location]
        player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
        --debug(flag5, "      total_width: " .. total_width)

        -- update the stat effect text hud
        hud_id = player_hud_ids[player_name]["stat_effect_text_" .. hud_location]
        player:hud_change(hud_id, "text", text)
        --player:hud_change(hud_id, "number", effect_info.text_color)

        mt_after(1, stat_effect_loop, player, player_meta, player_name, p_data,
        status_effects, effect_name, stat, severity)

    elseif type == "timed" then
        --debug(flag5, "      timed stat effect")
        if duration > 0 then
            local hud_id = player_hud_ids[player_name]["stat_effect_duration_" .. hud_location]
            player:hud_change(hud_id, "text", convert_seconds(duration))

            mt_after(1, stat_effect_loop, player, player_meta, player_name, p_data,
                status_effects, effect_name, stat, severity)

            -- decrease stat effect duration
            duration = duration - 1
            effect_data[2] = duration
            --debug(flag5, "      duration reduced to " .. duration)

        else
            --debug(flag5, "      stat effect duration ended. stopping effect..")
            hide_stat_effect(player, player_meta, player_name, p_data, status_effects, effect_name)
        end

    else
        debug(flag5, "      ERROR - Unexpected 'type' value: " .. type)
    end

    debug(flag5, "    stat_effect_loop() END")
end



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
    --debug(flag6, "            stat: " .. stat)
    --debug(flag6, "            severity: " .. severity)
    --debug(flag6, "            type: " .. type)
    --debug(flag6, "            duration: " .. duration)

    local status_effects = p_data.status_effects
    --debug(flag6, "            status_effects: " .. dump(status_effects))

    local effect_name = stat .. "_" .. severity
    local effect_data = status_effects[effect_name]
    local effect_info = STATUS_EFFECT_INFO[effect_name]

    if effect_data then
        --debug(flag6, "            stat effect already active for " .. effect_name)

        -- this currently would only occur for external status effects, like injuries,
        -- infection, environmental hazards, etc.
        if type == "timed" then
            --debug(flag6, "            existing stat effect already 'timed'. increasing duration..")

            local hud_location = effect_data[3]
            --debug(flag6, "            hud_location: " .. hud_location)
            local hud_id_1 = player_hud_ids[player_name]["stat_effect_duration_" .. hud_location]

            local existing_duration = effect_data[2]
            --debug(flag6, "            existing_duration: " .. existing_duration)
            local new_duration = existing_duration + duration
            if new_duration < 0 then new_duration = 0 end
            effect_data[2] = new_duration
            --debug(flag6, "            updated duration: " .. new_duration)

            player:hud_change(hud_id_1, "text", convert_seconds(new_duration))

        else
            --debug(flag6, "            stat effect " .. effect_name .. " already active. no further action.")
            debug(flag6, "          show_stat_effect()")
            return
        end

    else
        --debug(flag6, "            stat effect is NOT already active")

        -- increase active status effect count
        local status_effect_count = p_data.status_effect_count
        --debug(flag6, "            status_effect_count (before): " .. status_effect_count)
        status_effect_count = status_effect_count + 1
        p_data.status_effect_count = status_effect_count
        --debug(flag6, "            status_effect_count (after): " .. status_effect_count)

        if type == "percentage" then
            -- stat effect hud that consists an icon and text label that shows the
            -- player's current stat value percentage. severity 1 shows the text in
            -- orange, severity 2 in red, and severity 3 in white. the black background
            -- box turns red in severity 3.
            --debug(flag6, "            showing 'percentage' stat effect hud for: " .. effect_name)

            -- set stat effect background hud color
            local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. status_effect_count]
            local bg_value = "[fill:1x1:0,0:" .. effect_info.bg_color .. p_data.stats_bg_opacity
            player:hud_change(hud_id, "text", bg_value)
            --debug(flag6, "            bg_value: " .. bg_value)

            -- initialize stat effect text label
            local text = round(100 * p_data[stat .. "_ratio"], 1) .. "%"
            --debug(flag6, "            text: " .. text)

            -- set stat effect background hud width size
            local text_length = string_len(text)
            local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
            player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
            --debug(flag6, "            total_width: " .. total_width)

            -- create stat effect image hud
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
            local image_value = "ss_statbar_icon_" .. stat .. ".png"
            player:hud_change(hud_id, "text", image_value)
            player:hud_change(hud_id, "scale", {x = 1.8, y = 1.8})
            --debug(flag6, "            image_value: " .. image_value)

            -- create stat effect text hud
            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
            player:hud_change(hud_id, "text", text)
            player:hud_change(hud_id, "number", effect_info.text_color)

            -- save stat effect hud data
            status_effects[effect_name] = {type, duration, status_effect_count}
            p_data.stat_effect_hud_locations[status_effect_count] = effect_name
            player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

            -- ensure hud text label (precentage value) and background box is constantly refreshed
            stat_effect_loop(
                player, player_meta, player_name, p_data, status_effects, effect_name, stat, severity
            )

        elseif type == "basic_3" then
            -- stat effect hud that consists an icon and text label that is a one
            -- or two word description of the condition/ailment at highest severity.
            -- thus, the text label is colored white and the background box is red.
            -- typically for internal stat effects like 'health', 'thirst', etc.
            --debug(flag6, "            showing 'basic_3' stat effect hud for: " .. effect_name)

            -- set the stat effect background hud color
            local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. status_effect_count]
            local bg_value = "[fill:1x1:0,0:#AA0000" .. p_data.stats_bg_opacity
            player:hud_change(hud_id, "text", bg_value)
            --debug(flag6, "            bg_value: " .. bg_value)

            -- initialize the stat effect text label
            local text = effect_info.text
            --debug(flag6, "            text: " .. text)

            -- set the stat effect background hud width size
            local text_length = string_len(text)
            local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
            player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
            --debug(flag6, "            total_width: " .. total_width)

            -- create stat effect image hud
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
            local image_value = "ss_statbar_icon_" .. stat .. ".png"
            player:hud_change(hud_id, "text", image_value)
            player:hud_change(hud_id, "scale", {x = 1.8, y = 1.8})
            --debug(flag6, "            image_value: " .. image_value)

            -- create stat effect text hud
            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
            player:hud_change(hud_id, "text", text)
            player:hud_change(hud_id, "number", "0xFFFFFF")

            -- save stat effect hud data
            status_effects[effect_name] = {type, duration, status_effect_count}
            p_data.stat_effect_hud_locations[status_effect_count] = effect_name
            player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

        elseif type == "weather" then
            -- stat effect hud that consists an icon and text label that shows the
            -- player's current 'feels like' temperature. severities 1 and 2 shows
            -- the text in orange, severity 3 in red, and severity 4 in white. the
            -- black background box turns red in severity 4. the feel like temperature
            -- value constantly refreshes to show the latest value.
            --debug(flag6, "            showing 'weather' stat effect hud for: " .. effect_name)

            -- set stat effect background hud color
            local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. status_effect_count]
            local bg_value = "[fill:1x1:0,0:" .. effect_info.bg_color .. p_data.stats_bg_opacity
            player:hud_change(hud_id, "text", bg_value)
            --debug(flag6, "            bg_value: " .. bg_value)

            -- initialize stat effect text label
            local text = math_round(p_data.thermal_feels_like) .. " °F"
            if p_data.thermal_units == 2 then
                text = convert_to_celcius(p_data.thermal_feels_like, 1) .. " °C"
            end
            --debug(flag6, "            text: " .. text)

            -- set stat effect background hud width size
            local text_length = string_len(text)
            local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
            player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
            --debug(flag6, "            total_width: " .. total_width)

            -- create stat effect image hud
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
            local image_value = table_concat({"ss_stat_effect_", stat, "_", severity, ".png"})
            player:hud_change(hud_id, "text", image_value)
            player:hud_change(hud_id, "scale", {x = 1.8, y = 1.8})
            --debug(flag6, "            image_value: " .. image_value)

            -- create stat effect text hud
            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
            player:hud_change(hud_id, "text", text)
            player:hud_change(hud_id, "number", effect_info.text_color)

            -- save stat effect hud data
            status_effects[effect_name] = {type, duration, status_effect_count}
            p_data.stat_effect_hud_locations[status_effect_count] = effect_name
            player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

            -- ensure hud text label (temperature value) and background box is constantly refreshed
            stat_effect_loop(
                player, player_meta, player_name, p_data, status_effects, effect_name, stat, severity
            )

        elseif type == "basic" then
            -- stat effect hud that consists an icon and text label that is a one
            -- or two word description of the condition/ailment. severity 1 shows
            -- the text in orange, severity 2 in red, and severity 3 in white. the
            -- black background box turns red in severity 3. 'illness' and 'poison'
            -- status effects use this hud display type.
            --debug(flag6, "            showing 'basic' stat effect hud for: " .. effect_name)

            -- set the stat effect background hud color
            local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. status_effect_count]
            local bg_value = "[fill:1x1:0,0:" .. effect_info.bg_color .. p_data.stats_bg_opacity
            player:hud_change(hud_id, "text", bg_value)
            --debug(flag6, "            bg_value: " .. bg_value)

            -- initialize the stat effect text label
            local text = effect_info.text
            --debug(flag6, "            text: " .. text)

            -- set the stat effect background hud width size
            local text_length = string_len(text)
            local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
            player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
            --debug(flag6, "            total_width: " .. total_width)

            -- create stat effect image hud
            local scale = 1.8
            if stat == "legs" or stat == "hands" then scale = 0.9 end
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
            local image_value = table_concat({"ss_stat_effect_", stat, "_", severity, ".png"})
            player:hud_change(hud_id, "text", image_value)
            player:hud_change(hud_id, "scale", {x = scale, y = scale})
            --debug(flag6, "            image_value: " .. image_value)

            -- create stat effect text hud
            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
            player:hud_change(hud_id, "text", text)
            player:hud_change(hud_id, "number", effect_info.text_color)

            -- save stat effect hud data
            status_effects[effect_name] = {type, duration, status_effect_count}
            p_data.stat_effect_hud_locations[status_effect_count] = effect_name
            player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

        elseif type == "wetness" then
            -- stat effect hud that shows an icon, text label, and percentage for the
            -- wetness level. all severities show the text in orange with the background
            -- box in black.
            --debug(flag6, "            showing 'basic' stat effect hud for: " .. effect_name)

            -- set the stat effect background hud color
            local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. status_effect_count]
            local bg_value = "[fill:1x1:0,0:" .. effect_info.bg_color .. p_data.stats_bg_opacity
            player:hud_change(hud_id, "text", bg_value)
            --debug(flag6, "            bg_value: " .. bg_value)

            -- initialize the stat effect text label
            local text = effect_info.text
            text = round(p_data.wetness_ratio * 100, 1) .. "%"
            --debug(flag6, "            text: " .. text)

            -- set the stat effect background hud width size
            local text_length = string_len(text)
            local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
            player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
            --debug(flag6, "            total_width: " .. total_width)

            -- create stat effect image hud
            local scale = 1.8
            if stat == "legs" or stat == "hands" then scale = 0.9 end
            hud_id = player_hud_ids[player_name]["stat_effect_image_" .. status_effect_count]
            local image_value = table_concat({"ss_stat_effect_wetness_", severity, ".png"})
            player:hud_change(hud_id, "text", image_value)
            player:hud_change(hud_id, "scale", {x = scale, y = scale})
            --debug(flag6, "            image_value: " .. image_value)

            -- create stat effect text hud
            hud_id = player_hud_ids[player_name]["stat_effect_text_" .. status_effect_count]
            player:hud_change(hud_id, "text", text)
            player:hud_change(hud_id, "number", effect_info.text_color)

            -- save stat effect hud data
            status_effects[effect_name] = {type, duration, status_effect_count}
            p_data.stat_effect_hud_locations[status_effect_count] = effect_name
            player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

            -- ensure hud text percentage value is constantly refreshed
            stat_effect_loop(
                player, player_meta, player_name, p_data, status_effects, effect_name, stat, severity
            )

        elseif type == "timed" then
            -- display hud elements for a 'timed' stat effect. this typically activates
            -- from an external trigger (injury, illness, etc) and not from a low 
            -- player stat. this timed effect will also display a timer next to it
            -- indicating duration of the status effect.
            --debug(flag6, "            activating new time effect: " .. effect_name)
            --debug(flag6, "            (not yet implemented)")

            status_effects[effect_name] = {type, duration, status_effect_count}
            p_data.stat_effect_hud_locations[status_effect_count] = effect_name
            player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))
            stat_effect_loop(player, player_meta, player_name, p_data, status_effects, effect_name, stat, severity)

        else
            debug(flag6, "            ERROR - Unexpected 'type' value: " .. type)
        end

    end

    debug(flag6, "          show_stat_effect() END")
end
local show_stat_effect = ss.show_stat_effect


local flag10 = false
--- @param new_severity number the severity of the leg stat effect to activate
--- @param old_severity number the severity of the prior leg stat effect to stop
--- @param effect_type string 'percentage', 'basic_3', 'weather', 'basic', 'timed'
--- @param hp_drain_amount number amount of health to deplete
local function start_stat_effect(
            player, player_meta, player_name, status_effects, p_data,
            stat, new_severity, old_severity, effect_type, hp_drain_amount
        )
    debug(flag10, "          start_stat_effect()")

    -- immediately play jump land sound and deplete health
    mt_sound_play("ss_jump_land", {object = player, max_hear_distance = 10})
    ss.do_stat_update_action(player, p_data, player_meta, "normal", "health", hp_drain_amount, "curr", "add", true)
    p_data.legs_damage_total = p_data.legs_damage_total - hp_drain_amount
    player_meta:set_float("legs_damage_total", p_data.legs_damage_total)

    -- after short delay play pain/health damage sound
    mt_after(0.2, function()
        mt_sound_play("ss_stat_effect_health_up_" .. p_data.body_type, {object = player, max_hear_distance = 10})
    end)

    -- then play bone break sound if severity is legs_3
    if new_severity == 3 then
        mt_after(0.5, function()
            core.sound_play("ss_break_bone", {object = player, max_hear_distance = 10})
        end)
    end

    -- finally, show hud and splay sounds related to the new leg stat effect activating
    local effect_name = stat .. "_" .. new_severity
    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, stat .. "_" .. old_severity)
    show_stat_effect(player, player_meta, player_name, p_data, stat, new_severity, effect_type, 0)
    play_sound("stat_effect", {player = player, p_data = p_data, stat = stat, severity = "up", delay = 1})
    notify(player, "stat_effect", STATUS_EFFECT_INFO[effect_name].notify_up, 2, 1.5, 0, 2)

    debug(flag10, "          start_stat_effect() END")
end


local flag8 = false
local function update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, is_breath_restored)
    debug(flag8, "          update_breath_statbar()")

    if is_breath_restored then
        --debug(flag8, "            breath is at full 100%")
        if p_data.is_breathbar_shown then
            --debug(flag8, "            breathbar already displayed on-screen. hiding it now..")
            player:hud_change(p_huds.breath.icon, "scale", {x = 0, y = 0})
            player:hud_change(p_huds.breath.bg, "scale", {x = 0, y = 0})
            player:hud_change(p_huds.breath.bar, "scale", {x = 0, y = 0})
            p_data.is_breathbar_shown = false
        else
            --debug(flag8, "            breathbar already hidden. no further action.")
        end

    else
        --debug(flag8, "            breath is not at full 100%")
        if p_data.is_breathbar_shown then
            --debug(flag8, "            breathbar already displayed on-screen")
        else
            --debug(flag8, "            breathbar currently hidden. restore icon and black bg.")
            player:hud_change(p_huds.breath.icon, "scale", {x = 1.3, y = 1.3})
            player:hud_change(p_huds.breath.bg, "scale", {x = STATBAR_WIDTH_MINI, y = STATBAR_HEIGHT_MINI})
            p_data.is_breathbar_shown = true
        end

        --debug(flag8, "            update breathbar size/value")
        local stat_bar_value = (stat_value_new / stat_value_max) * STATBAR_HEIGHT_MINI
        player:hud_change(p_huds.breath.bar, "scale", {x = STATBAR_WIDTH_MINI - 5, y = stat_bar_value})
    end

    debug(flag8, "          update_breath_statbar() END")
end


local flag22 = false
local function update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio, effect_name)
    debug(flag22, "          update_breath_visuals()")

    -- update statbar size/value
    local stat_bar_value = breath_ratio * STATBAR_HEIGHT_MINI
    player:hud_change(p_huds.breath.bar, "scale", {x = STATBAR_WIDTH_MINI - 5, y = stat_bar_value})

    -- update status effect hud percentage value text
    if effect_name == "breath_1" or  effect_name == "breath_2" then
        -- update breath stat effect hud value
        local hud_location = p_data.status_effects[effect_name][3]
        p_data.breath_ratio = breath_ratio
        local text = round(breath_ratio * 100, 1) .. "%"
        --debug(flag22, "            text: " .. text)

        local hud_id = p_huds["stat_effect_text_" .. hud_location]
        player:hud_change(hud_id, "text", text)

        -- update breath stat effect hud bg box size
        local text_length = string_len(text)
        local total_width = STAT_EFFECT_BG_WIDTH + (text_length * STAT_EFFECT_BG_WIDTH_EXTRA)
        --debug(flag22, "            total_width: " .. total_width)

        hud_id = p_huds["stat_effect_bg_" .. hud_location]
        player:hud_change(hud_id, "scale", {x = total_width, y = STAT_EFFECT_BG_HEIGHT})
    end

    debug(flag22, "          update_breath_visuals() END")
end


local flag23 = false
-- effect names ending in zero represent player no longer influenced by that 
-- status effect or condition
function ss.update_visuals(player, player_name, player_meta, effect_name)
    debug(flag23, "  update_visuals()")
    --debug(flag23, "    effect_name: " .. effect_name)
    local p_huds = player_hud_ids[player_name]

    -- HEALTH --

    if effect_name == "health_0" then
        --debug(flag23, "    health within normal range. removing any screen effects.")
        player:set_lighting({saturation = 1})
        player_meta:set_float("screen_effect_saturation", 1)
        local hud_id = player_hud_ids[player_name].screen_effect_health
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "health_1" then
        --debug(flag23, "    applying visuals for health_1")
        player:set_lighting({saturation = 0.25})
        player_meta:set_float("screen_effect_saturation", 0.25)
        local hud_id = player_hud_ids[player_name].screen_effect_health
        player:hud_change(hud_id, "text", "ss_screen_effect_health_1.png")

    elseif effect_name == "health_2" then
        --debug(flag23, "    applying visuals for health_2")
        player_meta:set_float("screen_effect_saturation", 0.10)
        player:set_lighting({saturation = 0.10})
        local hud_id = player_hud_ids[player_name].screen_effect_health
        player:hud_change(hud_id, "text", "ss_screen_effect_health_2.png")
        --debug(flag23, "    set saturation to 10% and added bloodier overlay")

    elseif effect_name == "health_3" then
        --debug(flag23, "    applying visuals for health_3")
        player_meta:set_float("screen_effect_saturation", 0)
        player:set_lighting({saturation = 0})
        local hud_id = player_hud_ids[player_name].screen_effect_health
        player:hud_change(hud_id, "text", "ss_screen_effect_health_3.png")
        --debug(flag23, "    set saturation to 0% and added bloodiest overlay")

    -- STAMINA --

    elseif effect_name == "stamina_0" then
        --debug(flag23, "    stamina is between 100% and 41%")
        player:hud_change(p_huds.stamina.bar, "text", "[fill:1x1:0,0:" .. STATBAR_COLORS.stamina)
        player:hud_change(p_huds.screen_effect_stamina, "text", "")

    elseif effect_name == "stamina_1" then
        --debug(flag23, "    applying visuals for stamina_1 40% to 21%")
        player:hud_change(p_huds.stamina.bar, "text", "[fill:1x1:0,0:#5CC000")
        player:hud_change(p_huds.screen_effect_stamina, "text", "[fill:1x1:0,0:#888844^[opacity:60")

    elseif effect_name == "stamina_2" then
        --debug(flag23, "    applying visuals for stamina_2 20% to 1%")
        player:hud_change(p_huds.stamina.bar, "text", "[fill:1x1:0,0:#A0C000")
        player:hud_change(p_huds.screen_effect_stamina, "text", "[fill:1x1:0,0:#888844^[opacity:90")

    elseif effect_name == "stamina_3" then
        --debug(flag23, "    applying visuals for stamina_3 0%")
        player:hud_change(p_huds.stamina.bar, "text", "[fill:1x1:0,0:#f1ffc0")
        player:hud_change(p_huds.screen_effect_stamina, "text", "[fill:1x1:0,0:#887244^[opacity:130")

    -- HOT --

    elseif effect_name == "hot_0" then
        --debug(flag23, "    no longer hot. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "hot_1" then
        --debug(flag23, "    applying visuals for hot_1")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_hot_1.png")

    elseif effect_name == "hot_2" then
        --debug(flag23, "    applying visuals for hot_2")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_hot_2.png")

    elseif effect_name == "hot_3" then
        --debug(flag23, "    applying visuals for hot_3")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_hot_3.png")

    elseif effect_name == "hot_4" then
        --debug(flag23, "    applying visuals for hot_4")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_hot_4.png")

    -- COLD --

    elseif effect_name == "cold_0" then
        --debug(flag23, "    no longer cold. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "cold_1" then
        --debug(flag23, "    applying visuals for cold_1")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_cold_1.png")

    elseif effect_name == "cold_2" then
        --debug(flag23, "    applying visuals for cold_2")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_cold_2.png")

    elseif effect_name == "cold_3" then
        --debug(flag23, "    applying visuals for cold_3")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_cold_3.png")

    elseif effect_name == "cold_4" then
        --debug(flag23, "    applying visuals for cold_4")
        local hud_id = player_hud_ids[player_name].screen_effect_temperature
        player:hud_change(hud_id, "text", "ss_screen_effect_cold_4.png")

    -- ILLNESS --

    elseif effect_name == "illness_0" then
        --debug(flag23, "    no longer ill. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_illness
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "illness_1" then
        --debug(flag23, "    applying visuals for illness_1")
        local hud_id = player_hud_ids[player_name].screen_effect_illness
        player:hud_change(hud_id, "text", "ss_screen_effect_illness_1.png")

    elseif effect_name == "illness_2" then
        --debug(flag23, "    applying visuals for illness_2")
        local hud_id = player_hud_ids[player_name].screen_effect_illness
        player:hud_change(hud_id, "text", "ss_screen_effect_illness_2.png")

    elseif effect_name == "illness_3" then
        --debug(flag23, "    applying visuals for illness_3")
        local hud_id = player_hud_ids[player_name].screen_effect_illness
        player:hud_change(hud_id, "text", "ss_screen_effect_illness_3.png")

    -- POISON --

    elseif effect_name == "poison_0" then
        --debug(flag23, "    no longer poisoned. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_poison
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "poison_1" then
        --debug(flag23, "    applying visuals for poison_1")
        local hud_id = player_hud_ids[player_name].screen_effect_poison
        player:hud_change(hud_id, "text", "ss_screen_effect_poison_1.png")

    elseif effect_name == "poison_2" then
        --debug(flag23, "    applying visuals for poison_2")
        local hud_id = player_hud_ids[player_name].screen_effect_poison
        player:hud_change(hud_id, "text", "ss_screen_effect_poison_2.png")

    elseif effect_name == "poison_3" then
        --debug(flag23, "    applying visuals for poison_3")
        local hud_id = player_hud_ids[player_name].screen_effect_poison
        player:hud_change(hud_id, "text", "ss_screen_effect_poison_3.png")

    -- WETNESS --

    elseif effect_name == "wetness_0" then
        --debug(flag23, "    no longer wet. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_wetness
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "wetness_1" then
        --debug(flag23, "    applying visuals for wetness_1")
        local hud_id = player_hud_ids[player_name].screen_effect_wetness
        player:hud_change(hud_id, "text", "ss_screen_effect_wetness_1.png")

    elseif effect_name == "wetness_2" then
        --debug(flag23, "    applying visuals for wetness_2")
        local hud_id = player_hud_ids[player_name].screen_effect_wetness
        player:hud_change(hud_id, "text", "ss_screen_effect_wetness_2.png")

    elseif effect_name == "wetness_3" then
        local hud_id = player_hud_ids[player_name].screen_effect_wetness
        if player_data[player_name].water_level == 100 then
            --debug(flag23, "    applying visuals for underwater")
            player:hud_change(hud_id, "text", "ss_screen_effect_wetness_4.png")
        else
            --debug(flag23, "    applying visuals for wetness_3")
            player:hud_change(hud_id, "text", "ss_screen_effect_wetness_3.png")
        end

    -- SNEEZE --

    elseif effect_name == "sneeze_0" then
        --debug(flag23, "    no longer sneezing. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_sneeze
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "sneeze_1" then
        --debug(flag23, "    applying visuals for sneeze_1")
        local hud_id = player_hud_ids[player_name].screen_effect_sneeze
        player:hud_change(hud_id, "text", "[fill:1x1:0,0:#000000")

    -- COUGH --
    -- no screen effect for cough

    -- VOMIT --

    elseif effect_name == "vomit_0" then
        --debug(flag23, "    no longer vomittin. removing any screen effects.")
        local hud_id = player_hud_ids[player_name].screen_effect_vomit
        player:hud_change(hud_id, "text", "")

    elseif effect_name == "vomit_1" then
        --debug(flag23, "    applying visuals for vomit_1")
        local hud_id = player_hud_ids[player_name].screen_effect_vomit
        player:hud_change(hud_id, "text", "ss_screen_effect_vomit_1.png")

    else
        debug(flag23, "    ERROR - Unexpected 'effect_name' value: " .. effect_name)
    end

    debug(flag23, "  update_visuals() END")
end
local update_visuals = ss.update_visuals


local flag30 = false
function ss.do_stat_update_action(player, p_data, player_meta, trigger, stat, amount, type, action, allow_effects)

    -- for testing purposes
    --[[
    if stat == "hands" and amount < 0 and trigger == "normal" then
        flag30 = true
    else
        flag30 = false
    end
    --]]
    --if stat == "wetness" and trigger == "normal" then flag30 = true else flag30 = false end
    

    debug(flag30, "        do_stat_update_action()")
    --debug(flag30, "          " .. string_upper(stat) .. ", amt " .. amount .. ", type " .. type
    --    .. ", action " .. action .. " [" .. trigger .. "]")

    local stat_value_current = player_meta:get_float(stat .. "_current")
    local stat_value_max = player_meta:get_float(stat .. "_max")
    --debug(flag30, "          stat_value_current (before) " .. stat_value_current
    --    .. " | stat_value_max (before) " .. stat_value_max)

    -- update stat max value, and ensure current value does end up higher than max value
    local stat_value_new
    if type == "max" then
        if action == "add" then
            --debug(flag30, "          updating max value")
        elseif action == "set" then
            --debug(flag30, "          overwriting max value to: " .. amount)
            stat_value_max = 0
        else
            debug(flag30, "          ERROR - Unexpected 'type' action: " .. action)
        end
        stat_value_max = stat_value_max + amount

        if stat_value_max < 1 then
            --debug(flag30, "          stat max is below 1. clamping to 1.")
            stat_value_max = 1
        end
        if stat_value_max < stat_value_current then
            --debug(flag30, "          stat current value is above max value. reducing to max value..")
            stat_value_current = stat_value_max
            --debug(flag30, "          stat_value_current (updated): " .. stat_value_current)
        end
        --debug(flag30, "          stat_value_max (updated): " .. stat_value_max)
        stat_value_new = stat_value_current

    -- clamping of current value is not done here, but instead done within the code
    -- block corresponding to that stat name
    elseif type == "curr" then

        if action == "set" then
            --debug(flag30, "          overwriting current value to: " .. amount)
            stat_value_current = 0
        elseif stat_value_current == stat_value_max and amount > 0 then
            --debug(flag30, "          attempting to raise stat value when already at max. no further action.")
            --debug(flag30, "        do_stat_update_action() END")
            return
        elseif stat_value_current == 0 and amount < 0 then
            --debug(flag30, "          attempting to lower stat value when already at zero. no further action.")
            --debug(flag30, "        do_stat_update_action() END")
            return
        elseif action == "add" then
            --debug(flag30, "          updating curr value")
        end
        stat_value_new = stat_value_current + amount

    else
        debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
    end
    --debug(flag30, "          stat_value_new: " .. stat_value_new)

    local player_name = player:get_player_name()
    local p_huds = player_hud_ids[player_name]

    -------------
    -- HEALTH --
    -------------

    if stat == "health" then
        if stat_value_new < 0 then
            --debug(flag30, "          health below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          health above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          health within valid range")
        end

        local health_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          health_ratio: " .. health_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        -----------------------------------------------------
        -- Save final health values and refresh statbar huds
        -----------------------------------------------------        

        if type == "curr" then
            --debug(flag30, "          health new " .. stat_value_new)
            player_meta:set_float("health_current", stat_value_new)

            local current_hp = player:get_hp()
            --debug(flag30, "          engine hp current " .. current_hp)
            local new_hp
            if stat_value_new > current_hp then
                new_hp = math_floor(stat_value_new)
            elseif stat_value_new < current_hp then
                new_hp = math_ceil(stat_value_new)
            else
                -- can occur when reloading values from rejoining game
                new_hp = stat_value_new
            end
            --debug(flag30, "          new engine hp: " .. new_hp)

            if new_hp == current_hp then
                --debug(flag30, "          engine hp remains at " .. current_hp)
            else
                --debug(flag30, "          updating engine hp")

                player:set_hp(new_hp)
                -- if new_hp value is zero, dieplayer() is triggered but with
                -- core.after() dealy of zero, to allow remaining code below to
                -- execute before dielayer() code is executed

                if amount < 0 then
                    --debug(flag30, "          this was an hp drain. trigger: " .. trigger)
                    if string_sub(trigger, 1, 2) == "se" then
                        local effect_name = string_sub(trigger, 4)
                        --debug(flag30, "          effect_name: " .. effect_name)

                        if effect_name == "thirst_3" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1.5})
                            notify(player, "stat_effect", "pain from dehydration", 2, 2, 0, 2)

                        elseif effect_name == "hunger_3" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1.5})
                            notify(player, "stat_effect", "pain from starvation", 2, 1.5, 0, 2)

                        elseif effect_name == "breath_3" then
                            local pitch = 1
                            if p_data.body_type == 2 then pitch = 1.25 end
                            mt_sound_play("ss_damage_breath", {
                                gain = math_random(50,100) / 100,
                                pitch = pitch,
                                object = player,
                                max_hear_distance = 10
                            })

                        elseif effect_name == "hot_3" or effect_name == "hot_4" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            if not p_data.notify_cooldown_active_temp then
                                play_sound("stat_effect", {player = player, p_data = p_data, stat = "hot", severity = "up", delay = 1.5})
                                notify(player, "stat_effect", "health damage from the heat", 2, 1.5, 0, 2)
                                p_data.notify_cooldown_active_temp = true
                                mt_after(15, function() p_data.notify_cooldown_active_temp = false end)
                            end

                        elseif effect_name == "cold_3" or effect_name == "cold_4" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            if not p_data.notify_cooldown_active_temp then
                                play_sound("stat_effect", {player = player, p_data = p_data, stat = "cold", severity = "up", delay = 1.5})
                                notify(player, "stat_effect", "health damage from the cold", 2, 1.5, 0, 2)
                                p_data.notify_cooldown_active_temp = true
                                mt_after(15, function() p_data.notify_cooldown_active_temp = false end)
                            end

                        elseif effect_name == "illness_3" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "up", delay = 1.5})
                            notify(player, "stat_effect", "health damage from pneumonia", 2, 1.5, 0, 2)

                        elseif effect_name == "poison_3" then
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 0.5})
                            play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "up", delay = 1.5})
                            notify(player, "stat_effect", "health damage from dysentery", 2, 1.5, 0, 2)

                        else
                            debug(flag30, "          ERROR - Unexpected 'effect_name' value: " .. effect_name)
                        end
                    else
                        --debug(flag30, "          this was not from a stat effect. no further action.")
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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- health is within normal range of 30% and 100%
            if health_ratio > 0.30 then
                if p_data.health_ratio > 0.30 then
                    p_data.health_ratio = health_ratio
                    --debug(flag30, "          prior health already above 30%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.health_ratio = health_ratio

                --debug(flag30, "          health within normal range 30% to 100%. stop any status effects.")
                if status_effects["health_1"] then
                    --debug(flag30, "          going from health_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["health_2"] then
                    --debug(flag30, "          going from health_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_0.notify_down, 2, 1.5, 0, 2)

                -- no "health_3" condition because player cannot come back from death

                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating health effect level 1, when health is between 30% and 10%
            elseif health_ratio > 0.10 then
                if p_data.health_ratio > 0.10 and p_data.health_ratio <= 0.30 then
                    p_data.health_ratio = health_ratio
                    --debug(flag30, "          prior health also between 30% and 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'health_1' health between 30% to 10%")
                p_data.health_ratio = health_ratio

                if status_effects["health_1"] then
                    --debug(flag30, "          and already has health_1. no further action.")
                elseif status_effects["health_2"] then
                    --debug(flag30, "          going from health_2 to health_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_1.notify_down, 2, 1.5, 0, 2)

                -- no "health_3" condition because player cannot come back from death

                else
                    --debug(flag30, "          going from status ok to health_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating health effect level 2, when health is between zero and 10%
            elseif health_ratio > 0 then
                if p_data.health_ratio > 0 and p_data.health_ratio <= 0.10 then
                    p_data.health_ratio = health_ratio
                    --debug(flag30, "          prior health also between 10% and 0%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'health_2' health between 10% to 0%")
                p_data.health_ratio = health_ratio

                if status_effects["health_1"] then
                    --debug(flag30, "          going from health_1 to health_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["health_2"] then
                    --debug(flag30, "          and already has health_2. no further action.")

                -- no "health_3" condition because player cannot come back from death

                else
                    --debug(flag30, "          going from status ok to health_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.health_ratio == 0 then
                    p_data.health_ratio = health_ratio
                    --debug(flag30, "          prior health also 0%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating health_3 health is 0%")
                p_data.health_ratio = health_ratio

                -- update_visuals() is normally handled by monitor_status_effects()
                -- loop but it gets disabled due by dieplayer() since hp = 0. so the
                -- screen effects are 'manually' triggered in the below branches.

                if status_effects["health_1"] then
                    --debug(flag30, "          going from health_1 to health_3..")
                    update_visuals(player, player_name, player_meta, "health_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_3.notify_up, 2, 1.5, 0, 2)

                elseif status_effects["health_2"] then
                    --debug(flag30, "          going from health_2 to health_3..")
                    update_visuals(player, player_name, player_meta, "health_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "health_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_3.notify_up, 2, 1.5, 0, 2)

                elseif status_effects["health_3"] then
                    --debug(flag30, "          already has health_3. no further action.")
                    -- this could happen if player rejoins game while still in dead state,
                    -- had rage quit game window before clicking to respawn

                else
                    --debug(flag30, "          going from status ok to health_3..")
                    update_visuals(player, player_name, player_meta, "health_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "health", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.health_3.notify_up, 2, 1.5, 0, 2)
                end

            end
        else
            --debug(flag30, "          status effects disallowed")
        end


    ------------
    -- THIRST --
    ------------

    elseif stat == "thirst" then

        if stat_value_new < 0 then
            --debug(flag30, "          thirst below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          thirst above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          thirst within valid range")
        end

        local thirst_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          thirst_ratio: " .. thirst_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- thirst is within normal range of 50% and 100%.
            if thirst_ratio > 0.50 then
                if p_data.thirst_ratio > 0.50 then
                    p_data.thirst_ratio = thirst_ratio
                    --debug(flag30, "          prior thirst already above 50%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.thirst_ratio = thirst_ratio

                --debug(flag30, "          thirst within normal range 50% to 100%. stop any status effects.")
                if status_effects["thirst_1"] then
                    --debug(flag30, "          going from thirst_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["thirst_2"] then
                    --debug(flag30, "          going from thirst_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["thirst_3"] then
                    --debug(flag30, "          going from thirst_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating thirst effect level 1, when thirst is between 30% and 50%
            elseif thirst_ratio > 0.30 then
                if p_data.thirst_ratio > 0.30 and p_data.thirst_ratio <= 0.50 then
                    p_data.thirst_ratio = thirst_ratio
                    --debug(flag30, "          prior thirst also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'thirst_1' thirst between 30% to 50%")
                p_data.thirst_ratio = thirst_ratio

                if status_effects["thirst_1"] then
                    --debug(flag30, "          and already has thirst_1. no further action.")
                elseif status_effects["thirst_2"] then
                    --debug(flag30, "          going from thirst_2 to thirst_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["thirst_3"] then
                    --debug(flag30, "          going from thirst_3 to thirst_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to thirst_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating thirst effect level 2, when thirst is between 10% and 30%
            elseif thirst_ratio > 0.10 then
                if p_data.thirst_ratio > 0.10 and p_data.thirst_ratio <= 0.30 then
                    p_data.thirst_ratio = thirst_ratio
                    --debug(flag30, "          prior thirst also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'thirst_2' thirst between 10% to 30%")
                p_data.thirst_ratio = thirst_ratio

                if status_effects["thirst_1"] then
                    --debug(flag30, "          going from thirst_1 to thirst_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["thirst_2"] then
                    --debug(flag30, "          and already has thirst_2. no further action.")
                elseif status_effects["thirst_3"] then
                    --debug(flag30, "          going from thirst_3 to thirst_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to thirst_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.thirst_ratio >= 0 and p_data.thirst_ratio <= 0.10 then
                    p_data.thirst_ratio = thirst_ratio
                    --debug(flag30, "          prior thirst also <= 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating thirst_3 thirst <= 10%")
                p_data.thirst_ratio = thirst_ratio

                if status_effects["thirst_1"] then
                    --debug(flag30, "          going from thirst_1 to thirst_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["thirst_2"] then
                    --debug(flag30, "          going from thirst_2 to thirst_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "thirst_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["thirst_3"] then
                    --debug(flag30, "          already has thirst_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to thirst_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "thirst", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.thirst_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end


    ------------
    -- HUNGER --
    ------------

    elseif stat == "hunger" then

        if stat_value_new < 0 then
            --debug(flag30, "          hunger below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          hunger above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          hunger within valid range")
        end

        local hunger_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          hunger_ratio: " .. hunger_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- hunger is within normal range of 50% and 100%. stop any hunger status effects.
            if hunger_ratio > 0.50 then
                if p_data.hunger_ratio > 0.50 then
                    p_data.hunger_ratio = hunger_ratio
                    --debug(flag30, "          prior hunger also already above %50. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.hunger_ratio = hunger_ratio

                --debug(flag30, "          hunger within normal range 50% to 100%. stop any status effects.")
                if status_effects["hunger_1"] then
                    --debug(flag30, "          going from hunger_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["hunger_2"] then
                    --debug(flag30, "          going from hunger_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["hunger_3"] then
                    --debug(flag30, "          going from hunger_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating hunger effect level 1, when hunger is between 30% and 50%
            elseif hunger_ratio > 0.30 then
                if p_data.hunger_ratio > 0.30 and p_data.hunger_ratio <= 0.50 then
                    p_data.hunger_ratio = hunger_ratio
                    --debug(flag30, "          prior hunger also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'hunger_1' hunger between 30% to 50%")
                p_data.hunger_ratio = hunger_ratio

                if status_effects["hunger_1"] then
                    --debug(flag30, "          and already has hunger_1. no further action.")
                elseif status_effects["hunger_2"] then
                    --debug(flag30, "          going from hunger_2 to hunger_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["hunger_3"] then
                    --debug(flag30, "          going from hunger_3 to hunger_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to hunger_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating hunger effect level 2, when hunger is between 10% and 30%
            elseif hunger_ratio > 0.10 then
                if p_data.hunger_ratio > 0.10 and p_data.hunger_ratio <= 0.30 then
                    p_data.hunger_ratio = hunger_ratio
                    --debug(flag30, "          prior hunger also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'hunger_2' hunger between 10% to 30%")
                p_data.hunger_ratio = hunger_ratio

                if status_effects["hunger_1"] then
                    --debug(flag30, "          going from hunger_1 to hunger_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hunger_2"] then
                    --debug(flag30, "          and already has hunger_2. no further action.")
                elseif status_effects["hunger_3"] then
                    --debug(flag30, "          going from hunger_3 to hunger_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to hunger_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.hunger_ratio >= 0 and p_data.hunger_ratio <= 0.10 then
                    p_data.hunger_ratio = hunger_ratio
                    --debug(flag30, "          prior hunger also <= 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating hunger_3 hunger <= 10%")
                p_data.hunger_ratio = hunger_ratio

                if status_effects["hunger_1"] then
                    --debug(flag30, "          going from hunger_1 to hunger_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hunger_2"] then
                    --debug(flag30, "          going from hunger_2 to hunger_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hunger_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hunger_3"] then
                    --debug(flag30, "          already has hunger_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to hunger_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hunger", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hunger_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    ---------------
    -- ALERTNESS --
    ---------------

    elseif stat == "alertness" then

        if stat_value_new < 0 then
            --debug(flag30, "          alertness below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          alertness above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          alertness within valid range")
        end

        local alertness_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          alertness_ratio: " .. alertness_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- alertness is within normal range of 50% and 100%. stop any alertness status effects.
            if alertness_ratio > 0.50 then
                if p_data.alertness_ratio > 0.50 then
                    p_data.alertness_ratio = alertness_ratio
                    --debug(flag30, "          prior alertness was already above 50%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.alertness_ratio = alertness_ratio

                --debug(flag30, "          alertness within normal range 50% to 100%. stop any status effects.")
                if status_effects["alertness_1"] then
                    --debug(flag30, "          going from alertness_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["alertness_2"] then
                    --debug(flag30, "          going from alertness_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["alertness_3"] then
                    --debug(flag30, "          going from alertness_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating alertness effect level 1, when alertness is between 30% and 50%
            elseif alertness_ratio > 0.30 then
                if p_data.alertness_ratio > 0.30 and p_data.alertness_ratio <= 0.50 then
                    p_data.alertness_ratio = alertness_ratio
                    --debug(flag30, "          prior alertness also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'alertness_1' alertness between 30% to 50%")
                p_data.alertness_ratio = alertness_ratio

                if status_effects["alertness_1"] then
                    --debug(flag30, "          and already has alertness_1. no further action.")
                elseif status_effects["alertness_2"] then
                    --debug(flag30, "          going from alertness_2 to alertness_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["alertness_3"] then
                    --debug(flag30, "          going from alertness_3 to alertness_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to alertness_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating alertness effect level 2, when alertness is between 10% and 30%
            elseif alertness_ratio > 0.10 then
                if p_data.alertness_ratio > 0.10 and p_data.alertness_ratio <= 0.30 then
                    p_data.alertness_ratio = alertness_ratio
                    --debug(flag30, "          prior alertness also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'alertness_2' alertness between 10% to 30%")
                p_data.alertness_ratio = alertness_ratio

                if status_effects["alertness_1"] then
                    --debug(flag30, "          going from alertness_1 to alertness_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["alertness_2"] then
                    --debug(flag30, "          and already has alertness_2. no further action.")
                elseif status_effects["alertness_3"] then
                    --debug(flag30, "          going from alertness_3 to alertness_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to alertness_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.alertness_ratio >= 0 and p_data.alertness_ratio <= 0.10 then
                    p_data.alertness_ratio = alertness_ratio
                    --debug(flag30, "          prior alertness also <= 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating alertness_3 alertness <= 10%")
                p_data.alertness_ratio = alertness_ratio

                if status_effects["alertness_1"] then
                    --debug(flag30, "          going from alertness_1 to alertness_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["alertness_2"] then
                    --debug(flag30, "          going from alertness_2 to alertness_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "alertness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["alertness_3"] then
                    --debug(flag30, "          already has alertness_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to alertness_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "alertness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.alertness_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    -------------
    -- HYGIENE --
    -------------

    elseif stat == "hygiene" then

        if stat_value_new < 0 then
            --debug(flag30, "          hygiene below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          hygiene above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          hygiene within valid range")
        end

        local hygiene_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          hygiene_ratio: " .. hygiene_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- hygiene is within normal range of 50% and 100%. stop any hygiene status effects.
            if hygiene_ratio > 0.50 then
                if p_data.hygiene_ratio > 0.50 then
                    p_data.hygiene_ratio = hygiene_ratio
                    --debug(flag30, "          prior hygiene was already above 50%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.hygiene_ratio = hygiene_ratio

                --debug(flag30, "          hygiene within normal range 50% to 100%. stop any status effects.")
                if status_effects["hygiene_1"] then
                    --debug(flag30, "          going from hygiene_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["hygiene_2"] then
                    --debug(flag30, "          going from hygiene_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["hygiene_3"] then
                    --debug(flag30, "          going from hygiene_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating hygiene effect level 1, when hygiene is between 30% and 50%
            elseif hygiene_ratio > 0.30 then
                if p_data.hygiene_ratio > 0.30 and p_data.hygiene_ratio <= 0.50 then
                    p_data.hygiene_ratio = hygiene_ratio
                    --debug(flag30, "          prior hygiene also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'hygiene_1' hygiene between 30% to 50%")
                p_data.hygiene_ratio = hygiene_ratio

                if status_effects["hygiene_1"] then
                    --debug(flag30, "          and already has hygiene_1. no further action.")
                elseif status_effects["hygiene_2"] then
                    --debug(flag30, "          going from hygiene_2 to hygiene_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["hygiene_3"] then
                    --debug(flag30, "          going from hygiene_3 to hygiene_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to hygiene_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating hygiene effect level 2, when hygiene is between 10% and 30%
            elseif hygiene_ratio > 0.10 then
                if p_data.hygiene_ratio > 0.10 and p_data.hygiene_ratio <= 0.30 then
                    p_data.hygiene_ratio = hygiene_ratio
                    --debug(flag30, "          prior hygiene also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'hygiene_2' hygiene between 10% to 30%")
                p_data.hygiene_ratio = hygiene_ratio

                if status_effects["hygiene_1"] then
                    --debug(flag30, "          going from hygiene_1 to hygiene_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hygiene_2"] then
                    --debug(flag30, "          and already has hygiene_2. no further action.")
                elseif status_effects["hygiene_3"] then
                    --debug(flag30, "          going from hygiene_3 to hygiene_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to hygiene_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.hygiene_ratio >= 0 and p_data.hygiene_ratio <= 0.10 then
                    p_data.hygiene_ratio = hygiene_ratio
                    --debug(flag30, "          prior hygiene also <= 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating hygiene_3 hygiene <= 10%")
                p_data.hygiene_ratio = hygiene_ratio

                if status_effects["hygiene_1"] then
                    --debug(flag30, "          going from hygiene_1 to hygiene_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hygiene_2"] then
                    --debug(flag30, "          going from hygiene_2 to hygiene_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hygiene_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hygiene_3"] then
                    --debug(flag30, "          already has hygiene_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to hygiene_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hygiene", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hygiene_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    -------------
    -- COMFORT --
    -------------

    elseif stat == "comfort" then

        if stat_value_new < 0 then
            --debug(flag30, "          comfort below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          comfort above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          comfort within valid range")
        end

        local comfort_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          comfort_ratio: " .. comfort_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- comfort is within normal range of 50% and 100%. stop any comfort status effects.
            if comfort_ratio > 0.50 then
                if p_data.comfort_ratio > 0.50 then
                    p_data.comfort_ratio = comfort_ratio
                    --debug(flag30, "          prior comfort already above 50%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.comfort_ratio = comfort_ratio

                --debug(flag30, "          hygiene within normal range 50% to 100%. stop any status effects.")
                if status_effects["comfort_1"] then
                    --debug(flag30, "          going from comfort_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["comfort_2"] then
                    --debug(flag30, "          going from comfort_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["comfort_3"] then
                    --debug(flag30, "          going from comfort_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating comfort effect level 1, when comfort is between 30% and 50%
            elseif comfort_ratio > 0.30 then
                if p_data.comfort_ratio > 0.30 and p_data.comfort_ratio <= 0.50 then
                    p_data.comfort_ratio = comfort_ratio
                    --debug(flag30, "          prior comfort also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'comfort_1' comfort between 30% to 50%")
                p_data.comfort_ratio = comfort_ratio

                if status_effects["comfort_1"] then
                    --debug(flag30, "          and already has comfort_1. no further action.")
                elseif status_effects["comfort_2"] then
                    --debug(flag30, "          going from comfort_2 to comfort_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["comfort_3"] then
                    --debug(flag30, "          going from comfort_3 to comfort_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to comfort_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating comfort effect level 2, when comfort is between 10% and 30%
            elseif comfort_ratio > 0.10 then
                if p_data.comfort_ratio > 0.10 and p_data.comfort_ratio <= 0.30 then
                    p_data.comfort_ratio = comfort_ratio
                    --debug(flag30, "          prior comfort also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'comfort_2' comfort between 10% to 30%")
                p_data.comfort_ratio = comfort_ratio

                if status_effects["comfort_1"] then
                    --debug(flag30, "          going from comfort_1 to comfort_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["comfort_2"] then
                    --debug(flag30, "          and already has comfort_2. no further action.")
                elseif status_effects["comfort_3"] then
                    --debug(flag30, "          going from comfort_3 to comfort_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to comfort_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.comfort_ratio >= 0 and p_data.comfort_ratio <= 0.10 then
                    p_data.comfort_ratio = comfort_ratio
                    --debug(flag30, "          prior comfort also <= 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating comfort_3 comfort <= 10%")
                p_data.comfort_ratio = comfort_ratio

                if status_effects["comfort_1"] then
                    --debug(flag30, "          going from comfort_1 to comfort_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["comfort_2"] then
                    --debug(flag30, "          going from comfort_2 to comfort_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "comfort_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["comfort_3"] then
                    --debug(flag30, "          already has comfort_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to comfort_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "comfort", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.comfort_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    --------------
    -- IMMUNITY --
    --------------

    elseif stat == "immunity" then

        if stat_value_new < 0 then
            --debug(flag30, "          immunity below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          immunity above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          immunity within valid range")
        end

        local immunity_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          immunity_ratio: " .. immunity_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        ------------------------------------------------------
        -- Save final immunity values and refresh statbar huds
        ------------------------------------------------------        

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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- immunity is within normal range of 50% and 100%. stop any immunity status effects.
            if immunity_ratio > 0.50 then
                if p_data.immunity_ratio > 0.50 then
                    p_data.immunity_ratio = immunity_ratio
                    --debug(flag30, "          prior immunity already above 50%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.immunity_ratio = immunity_ratio

                --debug(flag30, "          immunity within normal range 50% to 100%. stop any status effects.")
                if status_effects["immunity_1"] then
                    --debug(flag30, "          going from immunity_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["immunity_2"] then
                    --debug(flag30, "          going from immunity_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["immunity_3"] then
                    --debug(flag30, "          going from immunity_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating immunity effect level 1, when immunity is between 30% and 50%
            elseif immunity_ratio > 0.30 then
                if p_data.immunity_ratio > 0.30 and p_data.immunity_ratio <= 0.50 then
                    p_data.immunity_ratio = immunity_ratio
                    --debug(flag30, "          prior immunity also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'immunity_1' immunity between 30% to 50%")
                p_data.immunity_ratio = immunity_ratio

                if status_effects["immunity_1"] then
                    --debug(flag30, "          and already has immunity_1. no further action.")
                elseif status_effects["immunity_2"] then
                    --debug(flag30, "          going from immunity_2 to immunity_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["immunity_3"] then
                    --debug(flag30, "          going from immunity_3 to immunity_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to immunity_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating immunity effect level 2, when immunity is between 10% and 30%
            elseif immunity_ratio > 0.10 then
                if p_data.immunity_ratio > 0.10 and p_data.immunity_ratio <= 0.30 then
                    p_data.immunity_ratio = immunity_ratio
                    --debug(flag30, "          prior immunity also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'immunity_2' immunity between 10% to 30%")
                p_data.immunity_ratio = immunity_ratio

                if status_effects["immunity_1"] then
                    --debug(flag30, "          going from immunity_1 to immunity_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["immunity_2"] then
                    --debug(flag30, "          and already has immunity_2. no further action.")
                elseif status_effects["immunity_3"] then
                    --debug(flag30, "          going from immunity_3 to immunity_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to immunity_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.immunity_ratio >= 0 and p_data.immunity_ratio <= 0.10 then
                    p_data.immunity_ratio = immunity_ratio
                    --debug(flag30, "          prior immunity also <= 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating immunity_3 immunity <= 10%")
                p_data.immunity_ratio = immunity_ratio

                if status_effects["immunity_1"] then
                    --debug(flag30, "          going from immunity_1 to immunity_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["immunity_2"] then
                    --debug(flag30, "          going from immunity_2 to immunity_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "immunity_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["immunity_3"] then
                    --debug(flag30, "          already has immunity_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to immunity_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "immunity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.immunity_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    ------------
    -- SANITY --
    ------------

    elseif stat == "sanity" then

        if stat_value_new < 0 then
            --debug(flag30, "          sanity below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          sanity above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          sanity within valid range")
        end

        local sanity_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          sanity_ratio: " .. sanity_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- sanity is within normal range of 50% and 100%. stop any sanity status effects.
            if sanity_ratio > 0.50 then
                if p_data.sanity_ratio > 0.50 then
                    p_data.sanity_ratio = sanity_ratio
                    --debug(flag30, "          prior sanity already above 50%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.sanity_ratio = sanity_ratio

                --debug(flag30, "          sanity within normal range 50% to 100%. stop any status effects.")
                if status_effects["sanity_1"] then
                    --debug(flag30, "          going from sanity_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["sanity_2"] then
                    --debug(flag30, "          going from sanity_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["sanity_3"] then
                    --debug(flag30, "          going from sanity_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating sanity effect level 1, when sanity is between 30% and 50%
            elseif sanity_ratio > 0.30 then
                if p_data.sanity_ratio > 0.30 and p_data.sanity_ratio <= 0.50 then
                    p_data.sanity_ratio = sanity_ratio
                    --debug(flag30, "          prior sanity also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'sanity_1' sanity between 30% to 50%")
                p_data.sanity_ratio = sanity_ratio

                if status_effects["sanity_1"] then
                    --debug(flag30, "          and already has sanity_1. no further action.")
                elseif status_effects["sanity_2"] then
                    --debug(flag30, "          going from sanity_2 to sanity_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["sanity_3"] then
                    --debug(flag30, "          going from sanity_3 to sanity_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to sanity_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating sanity effect level 2, when sanity is between 10% and 30%
            elseif sanity_ratio > 0.10 then
                if p_data.sanity_ratio > 0.10 and p_data.sanity_ratio <= 0.30 then
                    p_data.sanity_ratio = sanity_ratio
                    --debug(flag30, "          prior sanity also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'sanity_2' sanity between 10% to 30%")
                p_data.sanity_ratio = sanity_ratio

                if status_effects["sanity_1"] then
                    --debug(flag30, "          going from sanity_1 to sanity_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["sanity_2"] then
                    --debug(flag30, "          and already has sanity_2. no further action.")
                elseif status_effects["sanity_3"] then
                    --debug(flag30, "          going from sanity_3 to sanity_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to sanity_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.sanity_ratio >= 0 and p_data.sanity_ratio <= 0.10 then
                    p_data.sanity_ratio = sanity_ratio
                    --debug(flag30, "          prior sanity also <= 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating sanity_3 sanity <= 10%")
                p_data.sanity_ratio = sanity_ratio

                if status_effects["sanity_1"] then
                    --debug(flag30, "          going from sanity_1 to sanity_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["sanity_2"] then
                    --debug(flag30, "          going from sanity_2 to sanity_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "sanity_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["sanity_3"] then
                    --debug(flag30, "          already has sanity_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to sanity_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "sanity", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.sanity_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    ---------------
    -- HAPPINESS --
    ---------------

    elseif stat == "happiness" then

        if stat_value_new < 0 then
            --debug(flag30, "          happiness below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          happiness above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          happiness within valid range")
        end

        local happiness_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          happiness_ratio: " .. happiness_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- happiness is within normal range of 50% and 100%. stop any happiness status effects.
            if happiness_ratio > 0.50 then
                if p_data.happiness_ratio > 0.50 then
                    p_data.happiness_ratio = happiness_ratio
                    --debug(flag30, "          prior happiness already above 50%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.happiness_ratio = happiness_ratio

                --debug(flag30, "          happiness within normal range 50% to 100%. stop any status effects.")
                if status_effects["happiness_1"] then
                    --debug(flag30, "          going from happiness_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["happiness_2"] then
                    --debug(flag30, "          going from happiness_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["happiness_3"] then
                    --debug(flag30, "          going from happiness_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating happiness effect level 1, when happiness is between 30% and 50%
            elseif happiness_ratio > 0.30 then
                if p_data.happiness_ratio > 0.30 and p_data.happiness_ratio <= 0.50 then
                    p_data.happiness_ratio = happiness_ratio
                    --debug(flag30, "          prior happiness also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'happiness_1' happiness between 30% to 50%")
                p_data.happiness_ratio = happiness_ratio

                if status_effects["happiness_1"] then
                    --debug(flag30, "          and already has happiness_1. no further action.")
                elseif status_effects["happiness_2"] then
                    --debug(flag30, "          going from happiness_2 to happiness_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["happiness_3"] then
                    --debug(flag30, "          going from happiness_3 to happiness_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to happiness_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating happiness effect level 2, when happiness is between 10% and 30%
            elseif happiness_ratio > 0.10 then
                if p_data.happiness_ratio > 0.10 and p_data.happiness_ratio <= 0.30 then
                    p_data.happiness_ratio = happiness_ratio
                    --debug(flag30, "          prior happiness also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'happiness_2' happiness between 10% to 30%")
                p_data.happiness_ratio = happiness_ratio

                if status_effects["happiness_1"] then
                    --debug(flag30, "          going from happiness_1 to happiness_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["happiness_2"] then
                    --debug(flag30, "          and already has happiness_2. no further action.")
                elseif status_effects["happiness_3"] then
                    --debug(flag30, "          going from happiness_3 to happiness_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to happiness_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.happiness_ratio >= 0 and p_data.happiness_ratio <= 0.10 then
                    p_data.happiness_ratio = happiness_ratio
                    --debug(flag30, "          prior happiness also 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating happiness_3 happiness is 10%")
                p_data.happiness_ratio = happiness_ratio

                if status_effects["happiness_1"] then
                    --debug(flag30, "          going from happiness_1 to happiness_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["happiness_2"] then
                    --debug(flag30, "          going from happiness_2 to happiness_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "happiness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["happiness_3"] then
                    --debug(flag30, "          already has happiness_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to happiness_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "happiness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.happiness_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    ------------
    -- BREATH --
    ------------

    elseif stat == "breath" then

        if stat_value_new < 0 then
            --debug(flag30, "          breath below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          breath above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          breath within valid range")
        end
        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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
        --debug(flag30, "          breath_ratio: " .. breath_ratio)

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects
            if breath_ratio == 1 then
                if p_data.breath_ratio == 1 then
                    p_data.breath_ratio = breath_ratio
                    --debug(flag30, "          prior breath also full 100%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          breath is full 100%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    --debug(flag30, "          going from breath_1 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_1")
                elseif status_effects["breath_2"] then
                    --debug(flag30, "          going from breath_2 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_2")
                elseif status_effects["breath_3"] then
                    --debug(flag30, "          going from breath_3 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_3")
                else
                    --debug(flag30, "          and no prior breath stat effects")
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, true)

            elseif breath_ratio > 0.50 then
                if p_data.breath_ratio > 0.50 and p_data.breath_ratio < 1 then
                    p_data.breath_ratio = breath_ratio
                    --debug(flag30, "          prior breath also between 50% and %100")
                    update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio)
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          remaining breath 50% to 100%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    --debug(flag30, "          going from breath_1 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_1")
                    if p_data.water_level >= 90 then
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_0.notify_down, 2, 1.5, 0, 2, true)
                    end
                elseif status_effects["breath_2"] then
                    --debug(flag30, "          going from breath_2 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_2")
                    if p_data.water_level >= 90 then
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_0.notify_down, 2, 1.5, 0, 2, true)
                    end
                elseif status_effects["breath_3"] then
                    --debug(flag30, "          going from breath_3 to ok breath")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_3")
                    if p_data.water_level >= 90 then
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_0.notify_down, 2, 1.5, 0, 2, true)
                    end
                else
                    --debug(flag30, "          and no prior breath stat effects")
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, false)

            elseif breath_ratio > 0.30 then
                if p_data.breath_ratio > 0.30 and p_data.breath_ratio <= 0.50 then
                    p_data.breath_ratio = breath_ratio
                    --debug(flag30, "          prior breath also between 30% and 50%")
                    update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio, "breath_1")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'breath_1' breath between 30% to 50%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    --debug(flag30, "          already at breath_1. no further action.")
                elseif status_effects["breath_2"] then
                    --debug(flag30, "          going from breath_2 to breath_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 1, "percentage", 0)
                    if p_data.water_level >= 90 then
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_1.notify_down, 2, 1.5, 0, 2, true)
                    end
                elseif status_effects["breath_3"] then
                    --debug(flag30, "          going from breath_3 to breath_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 1, "percentage", 0)
                    if p_data.water_level >= 90 then
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_1.notify_down, 2, 1.5, 0, 2, true)
                    end
                else
                    --debug(flag30, "          going from breath ok to breath_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_1.notify_up, 2, 1.5, 0, 2, true)
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, false)

            elseif breath_ratio > 0.10 then
                if p_data.breath_ratio > 0.10 and p_data.breath_ratio <= 0.30 then
                    p_data.breath_ratio = breath_ratio
                    --debug(flag30, "          prior breath also between 10% and 30%")
                    update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio, "breath_2")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'breath_2' breath between 10% to 30%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    --debug(flag30, "          going from breath_1 to breath_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_2.notify_up, 2, 1.5, 0, 2, true)
                elseif status_effects["breath_2"] then
                    --debug(flag30, "          already at breath_2. no further action.")
                elseif status_effects["breath_3"] then
                    --debug(flag30, "          going from breath_3 to breath_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 2, "percentage", 0)
                    if p_data.water_level >= 90 then
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_2.notify_down, 2, 1.5, 0, 2, true)
                    end
                else
                    --debug(flag30, "          going from breath ok to breath_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_2.notify_up, 2, 1.5, 0, 2, true)
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, false)

            else
                if p_data.breath_ratio >= 0 and p_data.breath_ratio <= 0.10 then
                    p_data.breath_ratio = breath_ratio
                    --debug(flag30, "          prior breath also <= 10%")
                    update_breath_visuals(player, player_name, p_huds, p_data, breath_ratio, "breath_3")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating breath_3 breath <= 10%")
                p_data.breath_ratio = breath_ratio

                if status_effects["breath_1"] then
                    --debug(flag30, "          going from breath_1 to breath_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 3, "basic_3", 0)
                    --play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_3.notify_up, 2, 1.5, 0, 2, true)
                elseif status_effects["breath_2"] then
                    --debug(flag30, "          going from breath_2 to breath_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "breath_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 3, "basic_3", 0)
                    --play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_3.notify_up, 2, 1.5, 0, 2, true)
                elseif status_effects["breath_3"] then
                    --debug(flag30, "          already at breath_3. no further action.")
                else
                    --debug(flag30, "          going from breath ok to breath_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "breath", 3, "basic_3", 0)
                    --play_sound("stat_effect", {player = player, p_data = p_data, stat = "breath", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.breath_3.notify_up, 2, 1.5, 0, 2, true)
                end
                update_breath_statbar(player, p_data, p_huds, stat_value_new, stat_value_max, false)
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    -------------
    -- STAMINA --
    -------------

    elseif stat == "stamina" then


        if stat_value_new < 0 then
            --debug(flag30, "          stamina below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          stamina above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          stamina within valid range")
        end

        local stamina_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          stamina_ratio: " .. stamina_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

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

        --debug(flag30, "          stamina_bar_value: " .. stamina_bar_value)
        --debug(flag30, "          STAMINA_BAR_HEIGHT: " .. STAMINA_BAR_HEIGHT)

        local hud_id = p_huds.stamina.bar
        player:hud_change(hud_id, "scale", {x = stamina_bar_value, y = STAMINA_BAR_HEIGHT})


        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects

            -- stamina is within normal range of 50% and 100%. stop any stamina status effects.
            if stamina_ratio > 0.50 then
                if p_data.stamina_ratio > 0.50 then
                    p_data.stamina_ratio = stamina_ratio
                    --debug(flag30, "          prior stamina already above 50%. no further action")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.stamina_ratio = stamina_ratio

                --debug(flag30, "          stamina within normal range 30% to 100%. stop any status effects.")
                if status_effects["stamina_1"] then
                    --debug(flag30, "          going from stamina_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["stamina_2"] then
                    --debug(flag30, "          going from stamina_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["stamina_3"] then
                    --debug(flag30, "          going from stamina_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

            -- activating stamina effect level 1, when stamina is between 30% and 50%
            elseif stamina_ratio > 0.30 then
                if p_data.stamina_ratio > 0.30 and p_data.stamina_ratio <= 0.50 then
                    p_data.stamina_ratio = stamina_ratio
                    --debug(flag30, "          prior stamina also between 30% and 50%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'stamina_1' stamina between 30% to 50%")
                p_data.stamina_ratio = stamina_ratio

                if status_effects["stamina_1"] then
                    --debug(flag30, "          and already has stamina_1. no further action.")
                elseif status_effects["stamina_2"] then
                    --debug(flag30, "          going from stamina_2 to stamina_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["stamina_3"] then
                    --debug(flag30, "          going from stamina_3 to stamina_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to stamina_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating stamina effect level 2, when stamina is between 10% and 30%
            elseif stamina_ratio > 0.10 then
                if p_data.stamina_ratio > 0.10 and p_data.stamina_ratio <= 0.30 then
                    p_data.stamina_ratio = stamina_ratio
                    --debug(flag30, "          prior stamina also between 10% and 30%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'stamina_2' stamina between 10% to 30%")
                p_data.stamina_ratio = stamina_ratio

                if status_effects["stamina_1"] then
                    --debug(flag30, "          going from stamina_1 to stamina_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["stamina_2"] then
                    --debug(flag30, "          and already has stamina_2. no further action.")
                elseif status_effects["stamina_3"] then
                    --debug(flag30, "          going from stamina_3 to stamina_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from status ok to stamina_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.stamina_ratio >= 0 and p_data.stamina_ratio <= 0.10 then
                    p_data.stamina_ratio = stamina_ratio
                    --debug(flag30, "          prior stamina also <= 10%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating stamina_3 stamina <= 10%")
                p_data.stamina_ratio = stamina_ratio

                if status_effects["stamina_1"] then
                    --debug(flag30, "          going from stamina_1 to stamina_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["stamina_2"] then
                    --debug(flag30, "          going from stamina_2 to stamina_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "stamina_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["stamina_3"] then
                    --debug(flag30, "          already has stamina_3. no further action.")
                else
                    --debug(flag30, "          going from status ok to stamina_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "stamina", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.stamina_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    ----------------
    -- EXPERIENCE --
    ----------------

    elseif stat == "experience" then

        if stat_value_new < stat_value_max then
            if stat_value_new > 0 then
                --debug(flag30, "          xp is between zero and max")
            elseif stat_value_new < 0 then
                --debug(flag30, "          xp is lower than zero. clamped to zero.")
                stat_value_new = 0
            else
                --debug(flag30, "          xp is zero")
            end

        else
            --debug(flag30, "          gained a level")
            notify(player, "stat_effect", "Experience level up!", 3, 1, 0, 2)

            stat_value_new = stat_value_new - stat_value_max
            --debug(flag30, "          new xp value: " .. stat_value_new)

            local new_player_level = p_data.player_level + 1
            p_data.player_level = new_player_level
            player_meta:set_int("player_level", new_player_level)
            --debug(flag30, "\n          player level increased to " .. new_player_level)

            local new_skill_points = p_data.player_skill_points + 1
            p_data.player_skill_points = new_skill_points
            player_meta:set_int("player_skill_points", new_skill_points)
            --debug(flag30, "          skill points increased to " .. new_skill_points)

            stat_value_max = stat_value_max * (1 + XP_MAX_GROWTH_RATE)
            player_meta:set_float("experience_max", stat_value_max)
            --debug(flag30, "          experience_max increased to " .. stat_value_max)

            -- uplodate main formspec ui with new level and skill values
            local fs = player_data[player_name].fs
            fs.left.stats = get_fs_player_stats(player_name)
            player_meta:set_string("fs", mt_serialize(fs))
            player:set_inventory_formspec(build_fs(fs))
        end

        --debug(flag30, "          final xp " .. stat_value_new .. " | final max xp " .. stat_value_max)
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
            --debug(flag30, "          weight is below zero")
            stat_value_new = 0
            notify(player, "stat_effect", "ERROR - Weight below zero. Set to 0.", 2, 0, 0.5, 3)
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          hit max weight")
            stat_value_new = stat_value_max
            notify(player, "stat_effect", "ERROR - Weight above max. Set to " .. stat_value_max, 2, 0, 0.5, 3)
        else
            --debug(flag30, "          stat within valid range")
        end

        local weight_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          weight_ratio: " .. weight_ratio)

        ------------------------------------------------------
        -- Save the new weight values and refresh statbar huds
        ------------------------------------------------------

        --debug(flag30, "          final weight " .. stat_value_new .. " | final max weight " .. stat_value_max)
        local hud_id = p_huds.weight.bar
        player_meta:set_float("weight_current", stat_value_new)
        player_meta:set_float("weight_max", stat_value_max)

        local stat_bar_value = weight_ratio * STATBAR_HEIGHT_MINI
        player:hud_change(hud_id, "scale", {x = STATBAR_WIDTH_MINI - 5, y = stat_bar_value})
        --debug(flag30, "          stat_bar_value: " .. stat_bar_value)

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects
            if weight_ratio < 0.30 then
                if p_data.weight_ratio < 0.30 then
                    p_data.weight_ratio = weight_ratio
                    --debug(flag30, "          prior weight also between 30% and 0%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          carrying 30% to 0% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    --debug(flag30, "          going from weight_1 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_2"] then
                    --debug(flag30, "          going from weight_2 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_3"] then
                    --debug(flag30, "          going from weight_3 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_4"] then
                    --debug(flag30, "          going from weight_4 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_4")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_5"] then
                    --debug(flag30, "          going from weight_5 to ok weight")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_5")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and no prior weight stat effects")
                end
                --debug(flag30, "            change stamina bar color to #C0C000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C0C000")

            elseif weight_ratio < 0.45 then
                if p_data.weight_ratio < 0.45 and p_data.weight_ratio >= 0.30 then
                    --debug(flag30, "          prior weight also between 45% and 30%. no further action.")
                    --debug(flag30, "          update weight stat effect hud value")
                    p_data.weight_ratio = weight_ratio
                    local remaining_ratio_percentage = (1 - weight_ratio) * 100
                    local text = round((remaining_ratio_percentage), 1) .. "%"
                    local id = player_hud_ids[player_name]["stat_effect_text_" .. status_effects.weight_1[3]]
                    player:hud_change(id, "text", text)
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'weight_1' carrying 45% to 30% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    --debug(flag30, "          and already has weight_1. no further action.")
                elseif status_effects["weight_2"] then
                    --debug(flag30, "          going from weight_2 to weight_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_3"] then
                    --debug(flag30, "          going from weight_3 to weight_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_4"] then
                    --debug(flag30, "          going from weight_4 to weight_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_4")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_5"] then
                    --debug(flag30, "          going from weight_5 to weight_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_5")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from weight ok to weight_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 1, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_1.notify_up, 2, 1.5, 0, 2)
                end
                --debug(flag30, "            change stamina bar color to #C0A000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C0A000")

            elseif weight_ratio < 0.60 then
                if p_data.weight_ratio < 0.60 and p_data.weight_ratio >= 0.45 then
                    --debug(flag30, "          prior weight also between 60% and 45%")
                    --debug(flag30, "          update weight stat effect hud value")
                    p_data.weight_ratio = weight_ratio
                    local remaining_ratio_percentage = (1 - weight_ratio) * 100
                    local text = round((remaining_ratio_percentage), 1) .. "%"
                    local id = player_hud_ids[player_name]["stat_effect_text_" .. status_effects.weight_2[3]]
                    player:hud_change(id, "text", text)
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'weight_2' carrying 60% to 45% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    --debug(flag30, "          going from weight_1 to weight_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_2"] then
                    --debug(flag30, "          and already has weight_2. no further action.")
                elseif status_effects["weight_3"] then
                    --debug(flag30, "          going from weight_3 to weight_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_4"] then
                    --debug(flag30, "          going from weight_4 to weight_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_4")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_5"] then
                    --debug(flag30, "          going from weight_5 to weight_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_5")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from weight ok to weight_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 2, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_2.notify_up, 2, 1.5, 0, 2)
                end

                --debug(flag30, "            change stamina bar color to #C08000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C08000")

            elseif weight_ratio < 0.75 then
                if p_data.weight_ratio < 0.75 and p_data.weight_ratio >= 0.60 then
                    --debug(flag30, "          prior weight also between 75% and 60%. no further action.")
                    --debug(flag30, "          update weight stat effect hud value")
                    p_data.weight_ratio = weight_ratio
                    local remaining_ratio_percentage = (1 - weight_ratio) * 100
                    local text = round((remaining_ratio_percentage), 1) .. "%"
                    local id = player_hud_ids[player_name]["stat_effect_text_" .. status_effects.weight_3[3]]
                    player:hud_change(id, "text", text)
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'weight_3' carrying 75% to 60% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    --debug(flag30, "          going from weight_1 to weight_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 3, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_2"] then
                    --debug(flag30, "          going from weight_2 to weight_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 3, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_3"] then
                    --debug(flag30, "          and already has weight_3. no further action.")
                elseif status_effects["weight_4"] then
                    --debug(flag30, "          going from weight_4 to weight_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_4")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 3, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_3.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["weight_5"] then
                    --debug(flag30, "          going from weight_5 to weight_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_5")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 3, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_3.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from weight ok to weight_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 3, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_3.notify_up, 2, 1.5, 0, 2)
                end
                --debug(flag30, "            change stamina bar color to #C06000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C06000")

            elseif weight_ratio < 0.90 then
                if p_data.weight_ratio < 0.90 and p_data.weight_ratio >= 0.75 then
                    --debug(flag30, "          prior weight also between 90% and 75%. no further action.")
                    --debug(flag30, "          update weight stat effect hud value")
                    p_data.weight_ratio = weight_ratio
                    local remaining_ratio_percentage = (1 - weight_ratio) * 100
                    local text = round((remaining_ratio_percentage), 1) .. "%"
                    local id = player_hud_ids[player_name]["stat_effect_text_" .. status_effects.weight_4[3]]
                    player:hud_change(id, "text", text)
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'weight_4' carrying 90% to 75% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    --debug(flag30, "          going from weight_1 to weight_4")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 4, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_4.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_2"] then
                    --debug(flag30, "          going from weight_2 to weight_4")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 4, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_4.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_3"] then
                    --debug(flag30, "          going from weight_3 to weight_4")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 4, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_4.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_4"] then
                    --debug(flag30, "          and already has weight_4. no further action.")
                elseif status_effects["weight_5"] then
                    --debug(flag30, "          going from weight_5 to weight_4")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_5")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 4, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_4.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from weight ok to weight_4")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 4, "percentage", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_4.notify_up, 2, 1.5, 0, 2)
                end
                --debug(flag30, "            change stamina bar color to #C04000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C04000")

            else
                if p_data.weight_ratio >= 0.90 then
                    --debug(flag30, "          prior weight also above 90%. no further action.")
                    --debug(flag30, "          update weight stat effect hud value")
                    p_data.weight_ratio = weight_ratio
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'weight_5' carrying 90% to 100% of max weight")
                p_data.weight_ratio = weight_ratio

                if status_effects["weight_1"] then
                    --debug(flag30, "          going from weight_1 to weight_5")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 5, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_5.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_2"] then
                    --debug(flag30, "          going from weight_2 to weight_5")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 5, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_5.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_3"] then
                    --debug(flag30, "          going from weight_3 to weight_5")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 5, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_5.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_4"] then
                    --debug(flag30, "          going from weight_4 to weight_5")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "weight_4")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 5, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_5.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["weight_5"] then
                    --debug(flag30, "          already at weight_5. no further action.")
                else
                    --debug(flag30, "          going from weight ok to weight_5")
                    show_stat_effect(player, player_meta, player_name, p_data, "weight", 5, "basic_3", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "weight", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.weight_5.notify_up, 2, 1.5, 0, 2)
                end
                --debug(flag30, "            change stamina bar color to #C00000")
                player:hud_change(hud_id, "text", "[fill:1x1:0,0:#C00000")

            end

        else
            --debug(flag30, "          status effects disallowed")
        end


    -------------
    -- ILLNESS --
    -------------

    elseif stat == "illness" then

        if stat_value_new < 0 then
            --debug(flag30, "          illness below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          illness above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          illness within valid range")
        end

        local illness_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          illness_ratio: " .. illness_ratio)

        ------------------------------
        -- Save the new illness values
        ------------------------------

        if type == "curr" then
            player_meta:set_float("illness_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("illness_max", stat_value_max)
            player_meta:set_float("illness_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects
            if illness_ratio < 0.40 then
                if p_data.illness_ratio >= 0 and p_data.illness_ratio < 0.40 then
                    p_data.illness_ratio = illness_ratio
                    --debug(flag30, "          prior illness also between 0% and 40%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.illness_ratio = illness_ratio

                --debug(flag30, "          illness within normal range 0% to 40%. stop any status effects.")
                if status_effects["illness_1"] then
                    --debug(flag30, "          going from illness_1 to ok illness")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["illness_2"] then
                    --debug(flag30, "          going from illness_2 to ok illness")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["illness_3"] then
                    --debug(flag30, "          going from illness_3 to ok illness")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and no prior illness stat effects")
                end

            elseif illness_ratio < 0.60 then
                if p_data.illness_ratio >= 0.40 and p_data.illness_ratio < 0.60 then
                    p_data.illness_ratio = illness_ratio
                    --debug(flag30, "          prior illness also between 40% and 60%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'illness_1' 40% to 60%")
                p_data.illness_ratio = illness_ratio

                if status_effects["illness_1"] then
                    --debug(flag30, "          already at illness_1. no further action.")
                elseif status_effects["illness_2"] then
                    --debug(flag30, "          going from illness_2 to illness_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["illness_3"] then
                    --debug(flag30, "          going from illness_3 to illness_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from illness ok to illness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_1.notify_up, 2, 1.5, 0, 2)
                end

            elseif illness_ratio < 0.80 then
                if p_data.illness_ratio >= 0.60 and p_data.illness_ratio < 0.80 then
                    p_data.illness_ratio = illness_ratio
                    --debug(flag30, "          prior illness also between 60% and 80%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'illness_2' 60% to 80%")
                p_data.illness_ratio = illness_ratio

                if status_effects["illness_1"] then
                    --debug(flag30, "          going from illness_1 to illness_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["illness_2"] then
                    --debug(flag30, "          already at illness_2. no further action.")
                elseif status_effects["illness_3"] then
                    --debug(flag30, "          going from illness_3 to illness_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from illness ok to illness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.illness_ratio >= 0.80 then
                    p_data.illness_ratio = illness_ratio
                    --debug(flag30, "          prior illness also above 80%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'illness_3' 80% or greater")
                p_data.illness_ratio = illness_ratio

                if status_effects["illness_1"] then
                    --debug(flag30, "          going from illness_1 to illness_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["illness_2"] then
                    --debug(flag30, "          going from illness_2 to illness_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "illness_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["illness_3"] then
                    --debug(flag30, "          already at illness_3. no further action.")
                else
                    --debug(flag30, "          going from illness ok to illness_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "illness", 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "illness", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.illness_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end


    ------------
    -- POISON --
    ------------

    elseif stat == "poison" then

        if stat_value_new < 0 then
            --debug(flag30, "          poison below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          poison above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          poison within valid range")
        end

        local poison_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          poison_ratio: " .. poison_ratio)

        ------------------------------
        -- Save the new poison values
        ------------------------------

        if type == "curr" then
            player_meta:set_float("poison_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("poison_max", stat_value_max)
            player_meta:set_float("poison_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            --debug(flag30, "          status effects allowed")

            local status_effects = p_data.status_effects
            if poison_ratio < 0.40 then
                if p_data.poison_ratio >= 0 and p_data.poison_ratio < 0.40 then
                    p_data.poison_ratio = poison_ratio
                    --debug(flag30, "          prior poison also between 0% and 40%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.poison_ratio = poison_ratio

                --debug(flag30, "          poison within normal range 0% to 40%. stop any status effects.")
                if status_effects["poison_1"] then
                    --debug(flag30, "          going from poison_1 to ok poison")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["poison_2"] then
                    --debug(flag30, "          going from poison_2 to ok poison")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_0.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["poison_3"] then
                    --debug(flag30, "          going from poison_3 to ok poison")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_0.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          and no prior poison stat effects")
                end

            elseif poison_ratio < 0.60 then
                if p_data.poison_ratio >= 0.40 and p_data.poison_ratio < 0.60 then
                    p_data.poison_ratio = poison_ratio
                    --debug(flag30, "          prior poison also between 40% and 60%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'poison_1' 40% to 60%")
                p_data.poison_ratio = poison_ratio

                if status_effects["poison_1"] then
                    --debug(flag30, "          already at poison_1. no further action.")
                elseif status_effects["poison_2"] then
                    --debug(flag30, "          going from poison_2 to poison_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_1.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["poison_3"] then
                    --debug(flag30, "          going from poison_3 to poison_1")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_1.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from poison ok to poison_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_1.notify_up, 2, 1.5, 0, 2)
                end

            elseif poison_ratio < 0.80 then
                if p_data.poison_ratio >= 0.60 and p_data.poison_ratio < 0.80 then
                    p_data.poison_ratio = poison_ratio
                    --debug(flag30, "          prior poison also between 60% and 80%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'poison_2' 60% to 80%")
                p_data.poison_ratio = poison_ratio

                if status_effects["poison_1"] then
                    --debug(flag30, "          going from poison_1 to poison_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["poison_2"] then
                    --debug(flag30, "          already at poison_2. no further action.")
                elseif status_effects["poison_3"] then
                    --debug(flag30, "          going from poison_3 to poison_2")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_2.notify_down, 2, 1.5, 0, 2)
                else
                    --debug(flag30, "          going from poison ok to poison_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_2.notify_up, 2, 1.5, 0, 2)
                end

            else
                if p_data.poison_ratio >= 0.80 then
                    p_data.poison_ratio = poison_ratio
                    --debug(flag30, "          prior poison also above 80%. no further action.")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'poison_3' 80% or greater")
                p_data.poison_ratio = poison_ratio

                if status_effects["poison_1"] then
                    --debug(flag30, "          going from poison_1 to poison_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_1")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["poison_2"] then
                    --debug(flag30, "          going from poison_2 to poison_3")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "poison_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["poison_3"] then
                    --debug(flag30, "          already at poison_3. no further action.")
                else
                    --debug(flag30, "          going from poison ok to poison_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "poison", 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "poison", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.poison_3.notify_up, 2, 1.5, 0, 2)
                end
            end
        else
            --debug(flag30, "          status effects disallowed")
        end


    -------------
    -- WETNESS --
    -------------

elseif stat == "wetness" then

    if stat_value_new < 0 then
        --debug(flag30, "          wetness below zero. clampted to 0.")
        stat_value_new = 0
    elseif stat_value_new > stat_value_max then
        --debug(flag30, "          wetness above max. clampted to 0.")
        stat_value_new = stat_value_max
    else
        --debug(flag30, "          wetness within valid range")
    end

    local wetness_ratio = stat_value_new / stat_value_max
    --debug(flag30, "          wetness_ratio: " .. wetness_ratio)

    ------------------------------
    -- Save the new wetness values
    ------------------------------

    if type == "curr" then
        player_meta:set_float("wetness_current", stat_value_new)
    elseif type == "max" then
        player_meta:set_float("wetness_max", stat_value_max)
        player_meta:set_float("wetness_current", stat_value_new)
    else
        debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
    end

    -----------------------------------------------
    -- Trigger any on-screen stat effect hud images
    -----------------------------------------------

    -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
    -- during certain game start initialization steps
    if allow_effects then
        --debug(flag30, "          status effects allowed")

        local status_effects = p_data.status_effects
        if wetness_ratio == 0 then
            if p_data.wetness_ratio == 0 then
                --debug(flag30, "          prior wetness also 0%. no further action.")
                --debug(flag30, "        do_stat_update_action() END")
                return
            end
            p_data.wetness_ratio = wetness_ratio

            --debug(flag30, "          wetness at 0%. stop any status effects.")
            if status_effects["wetness_1"] then
                --debug(flag30, "          going from wetness_1 to no wetness")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_1")
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "down", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_0.notify_down, 2, 1.5, 0, 2)
            elseif status_effects["wetness_2"] then
                --debug(flag30, "          going from wetness_2 to no wetness")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_2")
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "down", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_0.notify_down, 2, 1.5, 0, 2)
            elseif status_effects["wetness_3"] then
                --debug(flag30, "          going from wetness_3 to no wetness")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_3")
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "down", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_0.notify_down, 2, 1.5, 0, 2)
            else
                --debug(flag30, "          and no prior wetness stat effects")
            end

        elseif wetness_ratio < 0.20 then
            if p_data.wetness_ratio > 0 and p_data.wetness_ratio < 0.20 then
                p_data.wetness_ratio = wetness_ratio
                --debug(flag30, "          prior wetness also between 0% and 20%")
                --debug(flag30, "        do_stat_update_action() END")
                return
            end
            --debug(flag30, "          activating 'wetness_1' 0% to 20%")
            p_data.wetness_ratio = wetness_ratio

            if status_effects["wetness_1"] then
                --debug(flag30, "          already at wetness_1. no further action.")
            elseif status_effects["wetness_2"] then
                --debug(flag30, "          going from wetness_2 to wetness_1")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_2")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 1, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "down", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_1.notify_down, 2, 1.5, 0, 2)
            elseif status_effects["wetness_3"] then
                --debug(flag30, "          going from wetness_3 to wetness_1")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_3")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 1, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "down", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_1.notify_down, 2, 1.5, 0, 2)
            else
                --debug(flag30, "          going from wetness ok to wetness_1")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 1, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "up", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_1.notify_up, 2, 1.5, 0, 2)
            end

        elseif wetness_ratio < 0.80 then
            if p_data.wetness_ratio >= 0.20 and p_data.wetness_ratio < 0.80 then
                p_data.wetness_ratio = wetness_ratio
                --debug(flag30, "          prior wetness also between 20% and 80%. no further action.")
                --debug(flag30, "        do_stat_update_action() END")
                return
            end
            --debug(flag30, "          activating 'wetness_2' 20% to 80%")
            p_data.wetness_ratio = wetness_ratio

            if status_effects["wetness_1"] then
                --debug(flag30, "          going from wetness_1 to wetness_2")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_1")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 2, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "up", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_2.notify_up, 2, 1.5, 0, 2)
            elseif status_effects["wetness_2"] then
                --debug(flag30, "          already at wetness_2. no further action.")
            elseif status_effects["wetness_3"] then
                --debug(flag30, "          going from wetness_3 to wetness_2")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_3")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 2, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "down", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_2.notify_down, 2, 1.5, 0, 2)
            else
                --debug(flag30, "          going from wetness ok to wetness_2")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 2, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "up", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_2.notify_up, 2, 1.5, 0, 2)
            end

        else
            if p_data.wetness_ratio >= 0.80 then
                p_data.wetness_ratio = wetness_ratio
                --debug(flag30, "          prior wetness also above 80%. no further action.")
                --debug(flag30, "        do_stat_update_action() END")
                return
            end
            --debug(flag30, "          activating 'wetness_3' 80% or greater")
            p_data.wetness_ratio = wetness_ratio

            if status_effects["wetness_1"] then
                --debug(flag30, "          going from wetness_1 to wetness_3")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_1")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 3, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "up", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_3.notify_up, 2, 1.5, 0, 2)
            elseif status_effects["wetness_2"] then
                --debug(flag30, "          going from wetness_2 to wetness_3")
                hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "wetness_2")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 3, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "up", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_3.notify_up, 2, 1.5, 0, 2)
            elseif status_effects["wetness_3"] then
                --debug(flag30, "          already at wetness_3. no further action.")
            else
                --debug(flag30, "          going from wetness ok to wetness_3")
                show_stat_effect(player, player_meta, player_name, p_data, "wetness", 3, "wetness", 0)
                --play_sound("stat_effect", {player = player, p_data = p_data, stat = "wetness", severity = "up", delay = 1})
                notify(player, "stat_effect", STATUS_EFFECT_INFO.wetness_3.notify_up, 2, 1.5, 0, 2)
            end
        end
    else
        --debug(flag30, "          status effects disallowed")
    end


    ----------
    -- LEGS --
    ----------

    elseif stat == "legs" then

        if stat_value_new < 0 then
            --debug(flag30, "          legs below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          legs above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          legs within valid range")
        end

        local legs_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          legs_ratio: " .. legs_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        --------------------------------------------------
        -- Save final legs values and refresh statbar huds
        --------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("legs_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("legs_max", stat_value_max)
            player_meta:set_float("legs_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.legs.active then
            local stat_bar_value = legs_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.legs.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            --debug(flag30, "          status effects allowed")
            --debug(flag30, "          amount: " .. amount)

            local status_effects = p_data.status_effects

            -- legs is within normal range of 90% and 100%. stop any legs status effects.
            if legs_ratio > 0.90 then
                if p_data.legs_ratio > 0.90 then
                    if amount < 0 then p_data.got_fall_damage = false end
                    p_data.legs_ratio = legs_ratio
                    --debug(flag30, "          prior legs also above 90%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.legs_ratio = legs_ratio

                --debug(flag30, "          legs within normal range 90% to 100%. stop any status effects.")
                if status_effects["legs_1"] then
                    --debug(flag30, "          going from legs_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_0.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)
                elseif status_effects["legs_2"] then
                    --debug(flag30, "          going from legs_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_0.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)
                elseif status_effects["legs_3"] then
                    --debug(flag30, "          going from legs_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_0.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)
                elseif status_effects["legs_4"] then
                    --debug(flag30, "          going from legs_4 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_4")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_0.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_recovery_status = 0
                    player_meta:set_int("legs_recovery_status", 0)
                elseif status_effects["legs_5"] then
                    --debug(flag30, "          going from legs_5 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_5")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_0.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_recovery_status = 0
                    player_meta:set_int("legs_recovery_status", 0)
                elseif status_effects["legs_6"] then
                    --debug(flag30, "          going from legs_6 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_6")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_0.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_recovery_status = 0
                    player_meta:set_int("legs_recovery_status", 0)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

                -- activating legs effect level 1 "sore", when legs is between 90% and 80%
            elseif legs_ratio > 0.80 then
                if p_data.legs_ratio > 0.80 and p_data.legs_ratio <= 0.90 then
                    if amount < 0 then p_data.got_fall_damage = false end
                    p_data.legs_ratio = legs_ratio
                    --debug(flag30, "          prior legs also between 90% and 80%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'legs_1' legs between 90% to 80%")
                p_data.legs_ratio = legs_ratio

                if status_effects["legs_1"] then
                    --debug(flag30, "          and already has legs_1. no further action.")
                elseif status_effects["legs_2"] then
                    --debug(flag30, "          going from legs_2 to legs_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_1.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)
                elseif status_effects["legs_3"] then
                    --debug(flag30, "          going from legs_3 to legs_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_1.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)
                elseif status_effects["legs_4"] then
                    --debug(flag30, "          going from legs_4 to legs_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_4")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_1.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_recovery_status = 0
                    player_meta:set_int("legs_recovery_status", 0)
                elseif status_effects["legs_5"] then
                    --debug(flag30, "          going from legs_5 to legs_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_5")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_1.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_recovery_status = 0
                    player_meta:set_int("legs_recovery_status", 0)
                elseif status_effects["legs_6"] then
                    --debug(flag30, "          going from legs_6 to legs_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_6")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_1.notify_down, 2, 1.5, 0, 2)
                    p_data.legs_recovery_status = 0
                    player_meta:set_int("legs_recovery_status", 0)
                else
                    --debug(flag30, "          going from status ok to legs_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating legs effect level 2 "sprained", when legs is between 80% and 61%
            elseif legs_ratio > 0.60 then
                if p_data.legs_ratio > 0.60 and p_data.legs_ratio <= 0.80 then
                    if amount < 0 then p_data.got_fall_damage = false end
                    p_data.legs_ratio = legs_ratio
                    --debug(flag30, "          prior legs also between 80% and 60%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'legs_2' legs between 80% to 60%")
                p_data.legs_ratio = legs_ratio

                if status_effects["legs_1"] then
                    -- only allow severity increase to 'legs_2' if due to fall damage
                    if p_data.got_fall_damage then
                        --debug(flag30, "          ** got fall damage. going from legs_1 to legs_2..")
                        hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_1")
                        show_stat_effect(player, player_meta, player_name, p_data, "legs", 2, "basic", 0)
                        play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "up", delay = 1})
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_2.notify_up, 2, 1.5, 0, 2)
                    elseif status_effects["weight_5"] and amount < -2.5 then
                        --debug(flag30, "          activating 'legs_2' due to overburdened weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 2, 1, "basic", -1)
                    elseif status_effects["weight_4"] and amount < -4.0 then
                        --debug(flag30, "          activating 'legs_2' due to very heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 2, 1, "basic", -2)
                    elseif status_effects["weight_3"] and amount < -5.5 then
                        --debug(flag30, "          activating 'legs_2' due to heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 2, 1, "basic", -3)
                    elseif status_effects["weight_2"] and amount < -7.0 then
                        --debug(flag30, "          activating 'legs_2' due to a bit heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 2, 1, "basic", -4)
                    elseif status_effects["weight_1"] and (amount < -8.5 and amount > -11) then
                        --debug(flag30, "          activating 'legs_2' due to noticeable weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 2, 1, "basic", -5)
                    else
                        --debug(flag30, "          NO fall damage. prevent increase to legs_2..")
                        p_data.legs_ratio = 80.01 / stat_value_max
                        player_meta:set_float("legs_current", 80.01)
                    end
                elseif status_effects["legs_2"] then
                    --debug(flag30, "          and already has legs_2. no further action.")
                elseif status_effects["legs_3"] then
                    --debug(flag30, "          going from legs_3 to legs_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_2.notify_down, 2, 1.5, 0, 2)
                else

                    -- this block also executes on game startup when legs value is
                    -- being initialized. check if legs value is in this rage due
                    -- to a splint/cast applied
                    local recovery_status = player_meta:get_int("legs_recovery_status")
                    if recovery_status == 4 then
                        --debug(flag30, "          leg is splinted from a sprain")
                        show_stat_effect(player, player_meta, player_name, p_data, "legs", 4, "basic", 0)

                    elseif recovery_status == 5 then
                        --debug(flag30, "          leg is splinted from a break")
                        show_stat_effect(player, player_meta, player_name, p_data, "legs", 5, "basic", 0)

                    elseif recovery_status == 6 then
                        --debug(flag30, "          leg is casted from a break")
                        show_stat_effect(player, player_meta, player_name, p_data, "legs", 6, "basic", 0)

                    else
                        --debug(flag30, "          leg is not in recovery")
                        -- no need to check if fall damage had occurred here since going
                        -- from status ok to legs_2 requires legs value drop of at least 11,
                        -- which based on formula "legs_drain_amount = 0.1736 * fall_distance ^ 2" 
                        -- requires fall distance of close to 8 meters, which will always
                        -- trigger 'got_fall_damage' flag
                        --debug(flag30, "          going from status ok to legs_2..")
                        show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "basic", 0)
                        play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "up", delay = 1})
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_2.notify_up, 2, 1.5, 0, 2)
                    end
                end

            -- activating legs effect level 3, when legs is between 60% and zero
            else
                if p_data.legs_ratio >= 0 and p_data.legs_ratio <= 0.60 then
                    if amount < 0 then p_data.got_fall_damage = false end
                    p_data.legs_ratio = legs_ratio
                    --debug(flag30, "          prior legs also 0%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating legs_3 legs between 60% and 0%")
                p_data.legs_ratio = legs_ratio

                if status_effects["legs_1"] then
                    -- no need to check if fall damage had occurred here since going
                    -- from legs_1 to legs_3 requires legs value drop of at least 21,
                    -- which based on formula "legs_drain_amount = 0.1736 * fall_distance ^ 2" 
                    -- requires fall distance of 11 meters, which will always trigger
                    -- 'got_fall_damage' flag
                    --debug(flag30, "          going from legs_1 to legs_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                    mt_after(0.5, function()
                        core.sound_play("ss_break_bone", {object = player, max_hear_distance = 10})
                    end)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_3.notify_up, 2, 1.5, 0, 2)

                elseif status_effects["legs_2"] then
                    -- only allow severity increase to 'legs_3' if due to fall damage
                    if p_data.got_fall_damage then
                        --debug(flag30, "          ** got fall damage. going from legs_2 to legs_3..")
                        hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_2")
                        show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                        mt_after(0.5, function()
                            core.sound_play("ss_break_bone", {object = player, max_hear_distance = 10})
                        end)
                        play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "up", delay = 1})
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_3.notify_up, 2, 1.5, 0, 2)
                    elseif status_effects["weight_5"] and amount < -2.5 then
                        --debug(flag30, "          activating 'legs_3' due to overburdened weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 2, "basic", -1)
                    elseif status_effects["weight_4"] and amount < -4.0 then
                        --debug(flag30, "          activating 'legs_3' due to very heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 2, "basic", -2)
                    elseif status_effects["weight_3"] and amount < -5.5 then
                        --debug(flag30, "          activating 'legs_3' due to heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 2, "basic", -3)
                    elseif status_effects["weight_2"] and amount < -7.0 then
                        --debug(flag30, "          activating 'legs_3' due to a bit heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 2, "basic", -4)
                    elseif status_effects["weight_1"] and (amount < -8.5 and amount > -11) then
                        --debug(flag30, "          activating 'legs_3' due to noticeable weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 2, "basic", -5)
                    else
                        --debug(flag30, "          NO fall damage. prevent increase to legs_3..")
                        p_data.legs_ratio = 60.01 / stat_value_max
                        player_meta:set_float("legs_current", 60.01)
                    end

                elseif status_effects["legs_3"] then
                    --debug(flag30, "          already has legs_3. no further action.")

                elseif status_effects["legs_4"] then
                    -- only allow severity increase to 'legs_3' if due to fall damage
                    if p_data.got_fall_damage then
                        --debug(flag30, "          ** got fall damage. going from legs_4 to legs_3..")
                        hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_4")
                        show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                        mt_after(0.5, function()
                            core.sound_play("ss_break_bone", {object = player, max_hear_distance = 10})
                        end)
                        play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "up", delay = 1})
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_3.notify_up, 2, 1.5, 0, 2)
                    elseif status_effects["weight_5"] and amount < -2.5 then
                        --debug(flag30, "          activating 'legs_3' due to overburdened weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 4, "basic", -1)
                    elseif status_effects["weight_4"] and amount < -4.0 then
                        --debug(flag30, "          activating 'legs_3' due to very heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 4, "basic", -2)
                    elseif status_effects["weight_3"] and amount < -5.5 then
                        --debug(flag30, "          activating 'legs_3' due to heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 4, "basic", -3)
                    elseif status_effects["weight_2"] and amount < -7.0 then
                        --debug(flag30, "          activating 'legs_3' due to a bit heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 4, "basic", -4)
                    elseif status_effects["weight_1"] and (amount < -8.5 and amount > -11) then
                        --debug(flag30, "          activating 'legs_3' due to noticeable weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 4, "basic", -5)
                    else
                        --debug(flag30, "          NO fall damage. prevent increase to legs_3..")
                        p_data.legs_ratio = 60.01 / stat_value_max
                        player_meta:set_float("legs_current", 60.01)
                    end

                elseif status_effects["legs_5"] then
                    -- only allow severity increase to 'legs_3' if due to fall damage
                    if p_data.got_fall_damage then
                        --debug(flag30, "          ** got fall damage. going from legs_5 to legs_3..")
                        hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_5")
                        show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                        mt_after(0.5, function()
                            core.sound_play("ss_break_bone", {object = player, max_hear_distance = 10})
                        end)
                        play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "up", delay = 1})
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_3.notify_up, 2, 1.5, 0, 2)
                    elseif status_effects["weight_5"] and amount < -2.5 then
                        --debug(flag30, "          activating 'legs_3' due to overburdened weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 5, "basic", -1)
                    elseif status_effects["weight_4"] and amount < -4.0 then
                        --debug(flag30, "          activating 'legs_3' due to very heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 5, "basic", -1)
                    elseif status_effects["weight_3"] and amount < -5.5 then
                        --debug(flag30, "          activating 'legs_3' due to heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 5, "basic", -1)
                    elseif status_effects["weight_2"] and amount < -7.0 then
                        --debug(flag30, "          activating 'legs_3' due to a bit heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 5, "basic", -2)
                    elseif status_effects["weight_1"] and (amount < -8.5 and amount > -11) then
                        --debug(flag30, "          activating 'legs_3' due to noticeable weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 5, "basic", -3)
                    else
                        --debug(flag30, "          NO fall damage. prevent increase to legs_3..")
                        p_data.legs_ratio = 60.01 / stat_value_max
                        player_meta:set_float("legs_current", 60.01)
                    end

                elseif status_effects["legs_6"] then
                    -- only allow severity increase to 'legs_3' if due to fall damage
                    if p_data.got_fall_damage then
                        --debug(flag30, "          ** got fall damage. going from legs_6 to legs_3..")
                        hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_6")
                        show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                        mt_after(0.5, function()
                            core.sound_play("ss_break_bone", {object = player, max_hear_distance = 10})
                        end)
                        play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "up", delay = 1})
                        notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_3.notify_up, 2, 1.5, 0, 2)
                    elseif status_effects["weight_5"] and amount < -2.5 then
                        --debug(flag30, "          activating 'legs_3' due to overburdened weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 6, "basic", -1)
                    elseif status_effects["weight_4"] and amount < -4.0 then
                        --debug(flag30, "          activating 'legs_3' due to very heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 6, "basic", -1)
                    elseif status_effects["weight_3"] and amount < -5.5 then
                        --debug(flag30, "          activating 'legs_3' due to heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 6, "basic", -1)
                    elseif status_effects["weight_2"] and amount < -7.0 then
                        --debug(flag30, "          activating 'legs_3' due to a bit heavy weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 6, "basic", -1)
                    elseif status_effects["weight_1"] and (amount < -8.5 and amount > -11) then
                        --debug(flag30, "          activating 'legs_3' due to noticeable weight")
                        start_stat_effect(player, player_meta, player_name, status_effects, p_data, stat, 3, 6, "basic", -2)
                    else
                        --debug(flag30, "          NO fall damage. prevent increase to legs_3..")
                        p_data.legs_ratio = 60.01 / stat_value_max
                        player_meta:set_float("legs_current", 60.01)
                    end

                else
                    -- no need to check if fall damage had occurred here since going
                    -- from ok (91) to legs_3 (60) requires legs value drop of at least 21,
                    -- which based on formula "legs_drain_amount = 0.1736 * fall_distance ^ 2" 
                    -- requires fall distance of close to 13.4 meters, which would have always
                    -- triggered 'got_fall_damage' flag
                    --debug(flag30, "          going from status ok to legs_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                    mt_after(0.5, function()
                        core.sound_play("ss_break_bone", {object = player, max_hear_distance = 10})
                    end)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "legs", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_3.notify_up, 2, 1.5, 0, 2)
                end
            end
            if amount < 0 then p_data.got_fall_damage = false end
        else
            --debug(flag30, "          status effects disallowed")
        end


    -----------
    -- HANDS --
    -----------

    elseif stat == "hands" then

        if stat_value_new < 0 then
            --debug(flag30, "          hands below zero. clampted to 0.")
            stat_value_new = 0
        elseif stat_value_new > stat_value_max then
            --debug(flag30, "          hands above max. clampted to 0.")
            stat_value_new = stat_value_max
        else
            --debug(flag30, "          hands within valid range")
        end

        local hands_ratio = stat_value_new / stat_value_max
        --debug(flag30, "          hands_ratio: " .. hands_ratio)

        --debug(flag30, "          final current val " .. stat_value_new .. " | final max val " .. stat_value_max)

        ---------------------------------------------------
        -- Save final hands values and refresh statbar huds
        ---------------------------------------------------        

        if type == "curr" then
            player_meta:set_float("hands_current", stat_value_new)
        elseif type == "max" then
            player_meta:set_float("hands_max", stat_value_max)
            player_meta:set_float("hands_current", stat_value_new)
        else
            debug(flag30, "          ERROR - Unexpected 'type' value: " .. type)
        end

        if p_data.statbar_settings.hands.active then
            local stat_bar_value = hands_ratio * STATBAR_HEIGHT
            player:hud_change(p_huds.hands.bar, "scale", {x = STATBAR_WIDTH - 6, y = stat_bar_value})
        end

        -----------------------------------------------
        -- Trigger any on-screen stat effect hud images
        -----------------------------------------------

        -- 'allow_effects' is typically 'true' during normal gameplay, but can be false
        -- during certain game start initialization steps
        if allow_effects then
            --debug(flag30, "          status effects allowed")
            --debug(flag30, "          amount: " .. amount)

            local status_effects = p_data.status_effects

            -- hands is within normal range of 90% and 100%. stop any hands status effects.
            if hands_ratio > 0.90 then
                if p_data.hands_ratio > 0.90 then
                    p_data.hands_ratio = hands_ratio
                    --debug(flag30, "          prior hands also above 90%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                p_data.hands_ratio = hands_ratio

                --debug(flag30, "          hands within normal range 90% to 100%. stop any status effects.")
                if status_effects["hands_1"] then
                    --debug(flag30, "          going from hands_1 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_1")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_0.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_damage_total = 0
                    player_meta:set_float("hands_damage_total", 0)
                elseif status_effects["hands_2"] then
                    --debug(flag30, "          going from hands_2 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_2")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_0.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_damage_total = 0
                    player_meta:set_float("hands_damage_total", 0)
                elseif status_effects["hands_3"] then
                    --debug(flag30, "          going from hands_3 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_3")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_0.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_damage_total = 0
                    player_meta:set_float("hands_damage_total", 0)
                elseif status_effects["hands_4"] then
                    --debug(flag30, "          going from hands_4 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_4")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_0.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                elseif status_effects["hands_5"] then
                    --debug(flag30, "          going from hands_5 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_5")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_0.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                elseif status_effects["hands_6"] then
                    --debug(flag30, "          going from hands_6 to recovered")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_6")
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_0.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                else
                    --debug(flag30, "          and had no active stat effects. no further action.")
                end

                -- activating hands effect level 1 "sore", when hands is between 90% and 80%
            elseif hands_ratio > 0.80 then
                if p_data.hands_ratio > 0.80 and p_data.hands_ratio <= 0.90 then
                    p_data.hands_ratio = hands_ratio
                    --debug(flag30, "          prior hands also between 90% and 80%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'hands_1' hands between 90% to 80%")
                p_data.hands_ratio = hands_ratio

                if status_effects["hands_1"] then
                    --debug(flag30, "          and already has hands_1. no further action.")
                elseif status_effects["hands_2"] then
                    --debug(flag30, "          going from hands_2 to hands_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_1.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_damage_total = 0
                    player_meta:set_float("hands_damage_total", 0)
                elseif status_effects["hands_3"] then
                    --debug(flag30, "          going from hands_3 to hands_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_1.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_damage_total = 0
                    player_meta:set_float("hands_damage_total", 0)
                elseif status_effects["hands_4"] then
                    --debug(flag30, "          going from hands_4 to hands_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_4")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_1.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                elseif status_effects["hands_5"] then
                    --debug(flag30, "          going from hands_5 to hands_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_5")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_1.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                elseif status_effects["hands_6"] then
                    --debug(flag30, "          going from hands_6 to hands_1..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_6")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_1.notify_down, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                else
                    --debug(flag30, "          going from status ok to hands_1..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 1, "basic", 0)
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_1.notify_up, 2, 1.5, 0, 2)
                end

            -- activating hands effect level 2 "sprained", when hands is between 80% and 61%
            elseif hands_ratio > 0.60 then
                if p_data.hands_ratio > 0.60 and p_data.hands_ratio <= 0.80 then
                    p_data.hands_ratio = hands_ratio
                    --debug(flag30, "          prior hands also between 80% and 60%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating 'hands_2' hands between 80% to 60%")
                p_data.hands_ratio = hands_ratio

                if status_effects["hands_1"] then
                    --debug(flag30, "          going from hands_1 to hands_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_2.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hands_2"] then
                    --debug(flag30, "          and already has hands_2. no further action.")
                elseif status_effects["hands_3"] then
                    --debug(flag30, "          going from hands_3 to hands_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_3")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "down", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_2.notify_down, 2, 1.5, 0, 2)
                elseif status_effects["hands_4"] then
                    --debug(flag30, "          going from hands_4 to hands_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_4")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_2.notify_up, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                elseif status_effects["hands_5"] then
                    --debug(flag30, "          going from hands_5 to hands_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_5")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_2.notify_up, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                elseif status_effects["hands_6"] then
                    --debug(flag30, "          going from hands_6 to hands_2..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_6")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_2.notify_up, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                else
                    --debug(flag30, "          going from status ok to hands_2..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 2, "basic", 0)
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_2.notify_up, 2, 1.5, 0, 2)
                end

            -- activating hands effect level 3, when hands is between 60% and zero
            else
                if p_data.hands_ratio >= 0 and p_data.hands_ratio <= 0.60 then
                    p_data.hands_ratio = hands_ratio
                    --debug(flag30, "          prior hands also 0%")
                    --debug(flag30, "        do_stat_update_action() END")
                    return
                end
                --debug(flag30, "          activating hands_3 hands between 60% and 0%")
                p_data.hands_ratio = hands_ratio

                if status_effects["hands_1"] then
                    --debug(flag30, "          going from hands_1 to hands_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_1")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hands_2"] then
                    --debug(flag30, "          going from hands_2 to hands_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_2")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_3.notify_up, 2, 1.5, 0, 2)
                elseif status_effects["hands_3"] then
                    --debug(flag30, "          and already has hands_3. no further action.")
                elseif status_effects["hands_4"] then
                    --debug(flag30, "          going from hands_4 to hands_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_4")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_3.notify_up, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                elseif status_effects["hands_5"] then
                    --debug(flag30, "          going from hands_5 to hands_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_5")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_3.notify_up, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                elseif status_effects["hands_6"] then
                    --debug(flag30, "          going from hands_6 to hands_3..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "hands_6")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                    play_sound("stat_effect", {player = player, p_data = p_data, stat = "hands", severity = "up", delay = 1})
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_3.notify_up, 2, 1.5, 0, 2)
                    p_data.hands_recovery_status = 0
                    player_meta:set_int("hands_recovery_status", 0)
                else
                    --debug(flag30, "          going from status ok to hands_3..")
                    show_stat_effect(player, player_meta, player_name, p_data, stat, 3, "basic", 0)
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.hands_3.notify_up, 2, 1.5, 0, 2)
                end

            end
        else
            --debug(flag30, "          status effects disallowed")
        end

    else
        debug(flag30, "          ERROR - Unexpected 'stat' value: " .. stat)
    end

    debug(flag30, "        do_stat_update_action() END")
end
local do_stat_update_action = ss.do_stat_update_action


local flag28 = false
--- @param player ObjectRef the player for which the stat will be modified
--- @param p_data table reference to table with data specific to this player
--- @param player_meta MetaDataRef used to access 'stat_updates' metadata
--- @param id number unique numerical id for this status update.
local function stat_update_loop(player, p_data, player_meta, id)
    debug(flag28, "\n      stat_update_loop()")
    after_player_check(player)

    if p_data.stat_updates[id] == nil then
        --debug(flag28, "        stat update was stopped")
        --debug(flag28, "      stat_update_loop() END")
        return
    end

    local update_data = p_data.stat_updates[id]

    -- for testing purposes
    --if update_data[1] == "baseline" then flag28 = false else flag28 = true end
    --if update_data[2] == "comfort" then flag28 = false else flag28 = true end

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
    --debug(flag28, "        id[" .. id .. "] " .. trigger .. " >> " .. string_upper(stat) .. " " .. amount .. " [ " .. stat_current_value .. " ]")
    --debug(flag28, "        iterations (before): " .. iterations)

    if iterations > 0 then
        --debug(flag28, "        performing stat update action..")
        do_stat_update_action(player, p_data, player_meta, trigger, stat, amount, type, action, allow_effects)
        --debug(flag28, "        stat update action completed")
        iterations = iterations - 1
        --debug(flag28, "        iterations (after): " .. iterations)
        if iterations > 0 then
            --debug(flag28, "        continuing stat update")

            -- check if this stat update was triggered by a status effect, and if
            -- the stat that triggered the status effect is already fully recovered.
            -- if so, this stat update is no longer necessary and is cancelled.
            if p_data.se_stat_updates[trigger] then
                --debug(flag28, "        this stat update was triggered by a status effect")
                if p_data[stat .. "_ratio"] == 1 then
                    --debug(flag28, "        " .. stat .. " already fully recovered. cancelling restore..")
                    local tokens = string_split(trigger, "_")
                    local trigger_stat = tokens[2]
                    --debug(flag28, "        trigger_stat: " .. trigger_stat)
                    local key = "recovery_total_" .. stat
                    p_data[key] = 0
                    player_meta:set_float(key, 0)
                    p_data.se_stat_updates[trigger] = nil
                    p_data.stat_updates[id] = nil
                    key = "recovery_" .. stat .. "_count"
                    p_data[key] = p_data[key] - 1
                else
                    --debug(flag28, "        " .. stat .. " not yet recovered. continuing next iteration.")
                    update_data[4] = iterations
                    mt_after(1, stat_update_loop, player, p_data, player_meta, id)
                end
            else
                --debug(flag28, "        continuing next iteration")
                update_data[4] = iterations
                mt_after(1, stat_update_loop, player, p_data, player_meta, id)
            end
        else
            --debug(flag28, "        no more iterations. stat update stopped.")
            p_data.stat_updates[id] = nil
            if p_data.se_stat_updates[trigger] then
                --debug(flag28, "        " .. trigger .. " exists in 'se_stat_updates' table. removing..")
                p_data.se_stat_updates[trigger] = nil
                local key = "recovery_" .. stat .. "_count"
                p_data[key] = p_data[key] - 1
            else
                --debug(flag28, "        " .. trigger .. " does not exist in 'se_stat_updates' table")
            end
        end

    -- when 'iteration' was already set or reduced to 0 before this current loop
    -- of stat_update_loop()
    elseif iterations == 0 then
        --debug(flag28, "        iterations is zero. stat update stopped.")
        p_data.stat_updates[id] = nil
        if string_sub(trigger, 1, 3) == "rec" then
            --debug(flag28, "        this was a 'recovery' stat update. removed from 'se_stat_updates' table.")
            p_data.se_stat_updates[trigger] = nil
        end

    else
        --debug(flag28, "        perpetual stat update")
        if timer == 0 then
            --debug(flag28, "        timer reached. resetting to " .. interval)
            update_data[6] = interval
            do_stat_update_action(player, p_data, player_meta, trigger, stat, amount, type, action, allow_effects)
        else
            --debug(flag28, "        timer at " .. timer .. " of " .. interval)
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
    depletion of thirst, hunger, and alertness throughout the day. 'baseline' is the
    stat increaseing or decreasing to return to its baseline value.
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
    --debug(flag27, "      update_data: {" .. stat .. ", " .. amount .. ", " .. iterations
    --    .. ", " .. update_data[5] .. ", " .. update_data[6] .. ", " .. update_data[7]
    --    .. ", " .. dump(update_data[8]) .. "}")

    --print("update_stat() " .. trigger .. " " .. stat .. " " .. amount)

    local id = get_unique_id()
    --debug(flag27, "      id: " .. id)

    if amount == 0 then
        if update_data[7] == "set" then
            do_stat_update_action(player, p_data, player_meta, trigger, stat, amount, update_data[6], update_data[7], update_data[8])
        else
            --debug(flag27, "      cannot add 'amount' of zero. no update performed.'")
        end

    else
        if iterations > 0 then
            --debug(flag27, "      this is a normal stat update")
            amount = amount / iterations
            -- the total 'amount' applied to 'stat' is spread equally among all iterations
        else
            --debug(flag27, "      this is a perpetual stat update")
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


local flag4 = false
-- decreases or incrases breath stat value depending on if player is under water
local function monitor_underwater_status(player, player_name, p_data, status_effects)
    debug(flag4, "\nmonitor_underwater_status()")
    after_player_check(player)

    local player_meta = player:get_meta()
    local breath_current = player_meta:get_float("breath_current")
    local breath_max = player_meta:get_float("breath_max")
    --debug(flag4, "  current " .. breath_current .. " | max " .. breath_max)

    local water_level = 0
    local pos = player:get_pos()
    local node = mt_get_node(pos)
    local node_name = node.name
    if NODE_NAMES_WATER[node_name] then
        water_level = math_random(48, 52)
        -- get node at 60% away from feet
        node = mt_get_node({x=pos.x, y=pos.y + 0.8, z=pos.z})
        node_name = node.name

        if NODE_NAMES_WATER[node_name] then
            water_level = math_random(58, 62)
            -- get node at 70% away from feet
            node = mt_get_node({x=pos.x, y=pos.y + 1.0, z=pos.z})
            node_name = node.name

            if NODE_NAMES_WATER[node_name] then
                water_level = math_random(68, 72)
                -- get node at 70% away from feet
                node = mt_get_node({x=pos.x, y=pos.y + 1.2, z=pos.z})
                node_name = node.name

                if NODE_NAMES_WATER[node_name] then
                    water_level = math_random(78, 82)
                    -- get node at 70% away from feet
                    node = mt_get_node({x=pos.x, y=pos.y + 1.4, z=pos.z})
                    node_name = node.name

                    if NODE_NAMES_WATER[node_name] then
                        water_level = math_random(88, 92)
                        -- get node at 70% away from feet
                        node = mt_get_node({x=pos.x, y=pos.y + 1.65, z=pos.z})
                        node_name = node.name

                        if NODE_NAMES_WATER[node_name] then
                            water_level = 100
                        end
                    end
                end
            end
        end
    end

    local prev_water_level = p_data.water_level
    if water_level == 100 then
        --debug(flag4, "  water_level is 100%")
        if prev_water_level == 100 then
            -- prev water level already 100%. no change to screen effect
        else
            -- setting screen effect to underwater
            local hud_id = player_hud_ids[player_name].screen_effect_wetness
            player:hud_change(hud_id, "text", "ss_screen_effect_wetness_4.png")
            p_data.leg_injury_mod_water = 0.2
        end

        -- the engine breath value is perpetually restored back to 100 whenever
        -- player is underwater to ensure it does not impact engine hp during
        -- gameplay. the 'breath_current' metadata value controls any hp impacts.
        player:set_breath(100)

        local amount = -p_data.breath_deplete_rate * p_data.breath_drain_mod_deep_diver
        do_stat_update_action(player, p_data, player_meta, "normal", "breath", amount, "curr", "add", true)

    elseif water_level == 0 then
        --debug(flag4, "  water_level is 0%")
        if prev_water_level == 100 then
            -- prev water level was 100%. restoring screen effect to wetness_3
            local hud_id = player_hud_ids[player_name].screen_effect_wetness
            player:hud_change(hud_id, "text", "ss_screen_effect_wetness_3.png")
            p_data.leg_injury_mod_water = 1
        elseif prev_water_level == 0 then
            -- prev water level 0%. no further action
        else
            -- prev water level between 0 and 100
            p_data.leg_injury_mod_water = 1
        end
        if breath_current < breath_max then
            local amount = p_data.breath_restore_rate * p_data.breath_rec_mod_oxygenator
            do_stat_update_action(player, p_data, player_meta, "normal", "breath", amount, "curr", "add", true)
        end

    else
        --debug(flag4, "  water_level between 0% and 100%: " .. water_level)
        if string_sub(p_data.current_anim_state, 1, 6) == "crouch" then
            --debug(flag4, "  player crouching underwater")
            water_level = 100
            -- settings screen effect for underwater")
            local hud_id = player_hud_ids[player_name].screen_effect_wetness
            player:hud_change(hud_id, "text", "ss_screen_effect_wetness_4.png")
            p_data.leg_injury_mod_water = 0.2
            local amount = -p_data.breath_deplete_rate * p_data.breath_drain_mod_deep_diver
            do_stat_update_action(player, p_data, player_meta, "normal", "breath", amount, "curr", "add", true)
        else
            --debug(flag4, "  player standing in water")
            if prev_water_level == 100 then
                -- prev water level was 100%. restoring screen effect to wetness_3")
                local hud_id = player_hud_ids[player_name].screen_effect_wetness
                player:hud_change(hud_id, "text", "ss_screen_effect_wetness_3.png")
            end
            node = mt_get_node({x=pos.x, y=pos.y-0.1, z=pos.z})
            if NODE_NAMES_WATER[node.name] then
                p_data.leg_injury_mod_water = 0.2
            else
                p_data.leg_injury_mod_water = 0.5
            end
            if breath_current < breath_max then
                local amount = p_data.breath_restore_rate * p_data.breath_rec_mod_oxygenator
                do_stat_update_action(player, p_data, player_meta, "normal", "breath", amount, "curr", "add", true)
            end
        end
        --debug(flag4, "  water_level (final): " .. water_level)

    end

    p_data.water_level = water_level
    player_meta:set_int("submersion_level", water_level)

    debug(flag4, "monitor_underwater_status() end")
    local job_handle = mt_after(1, monitor_underwater_status, player, player_name, p_data, status_effects)
    job_handles[player_name].monitor_underwater_status = job_handle
end


local stat_effect_name_count = 0
local STAT_EFFECT_NAMES = {}
for i = 1, 11 do
    STAT_EFFECT_NAMES[i] = STAT_NAMES[i]
    stat_effect_name_count = stat_effect_name_count + 1
end
table_insert(STAT_EFFECT_NAMES, "illness")
table_insert(STAT_EFFECT_NAMES, "poison")


local flag21 = false
-- Ensures the stat values for health, thirst, hunger, alertness, hygiene, comfort,
-- immunity, sanity, and happiness gradually approaches a baseline value as time
-- passes. For example, thirst, hunger, and alertness have a baseline value of zero,
-- which means player must counteract it during gameplay else is will eventaully
-- deplete to zero. health has a baseline value of 100%, and if the player has
-- natuaral healing ability, the player's health will gratdually restore to 100%
-- given enough time. stats like immunity, sanity, and happiness, have baseline
-- values anywhere between zero and 100%, which means those stats will gradully
-- deplete or restore to reach that baseline.
--- @param player ObjectRef the player object
--- @param player_meta MetaDataRef used to access the current stat value
--- @param player_name string the player's name
--- @param p_data table reference to table with data specific to this player
local function monitor_baseline_stats(player, player_meta, player_name, p_data)
    debug(flag21, "\nmonitor_baseline_stats()")

    for i = 1, stat_effect_name_count do
        local stat_name = STAT_EFFECT_NAMES[i]
        local stat_current = player_meta:get_float(stat_name .. "_current")
        --debug(flag21, "  " .. stat_name .. " stat_current: " .. stat_current)

        local  immunity_factor = 1
        if stat_name == "illness" or stat_name == "poison" then
            if p_data.immunity_ratio < 0.5 then
                local delta_value = 0.5 - p_data.immunity_ratio
                immunity_factor = 1 - (delta_value * 2)
            else
                local delta_value = p_data.immunity_ratio - 0.5
                immunity_factor = 1 + (delta_value * 2)
            end
            --debug(flag21, "    immunity_ratio: " .. p_data.immunity_ratio)
            --debug(flag21, "    immunity_factor: " .. immunity_factor)

        end

        local baseline_value = p_data["base_value_" .. stat_name]
        --debug(flag21, "    baseline_value: " .. baseline_value)
        if stat_current == baseline_value then
            --debug(flag21, "    stat at baseline. no further action.")
        else
            local change_rate
            if stat_current > baseline_value then
                --debug(flag21, "    stat above baseline")
                change_rate = p_data["drain_speed_" .. stat_name] * immunity_factor
                stat_current = stat_current - change_rate
                if stat_current < baseline_value then
                    change_rate = change_rate - (baseline_value - stat_current)
                end
                change_rate = -change_rate

            else
                --debug(flag21, "    stat below baseline")
                change_rate = p_data["recovery_speed_" .. stat_name] * immunity_factor
                stat_current = stat_current + change_rate
                if stat_current > baseline_value then
                    change_rate = change_rate - (stat_current - baseline_value)
                end
            end
            change_rate = round(change_rate, 5)
            --debug(flag21, "    modifying stat by " .. change_rate)
            do_stat_update_action(player, p_data, player_meta, "baseline", stat_name, change_rate, "curr", "add", true)
        end
    end

    debug(flag21, "monitor_baseline_stats() END")
    local job_handle = mt_after(1, monitor_baseline_stats, player, player_meta, player_name, p_data)
    job_handles[player_name].monitor_baseline_stats = job_handle
end



local flag17 = false
-- updates the weight display on the player inventory formspec according to
-- 'amount', which can be negative signifying a reduction in weight.
function ss.update_inventory_weight(player, weight_change)
    debug(flag17, "  update_inventory_weight()")
    --debug(flag17, "    weight_change: " .. weight_change)
    local player_meta = player:get_meta()
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]

    -- update vertical statbar weight HUD
    do_stat_update_action(player, p_data, player_meta, "normal", "weight", weight_change, "curr", "add", true)
    --debug(flag17, "    updated weight hudbar")

	-- update weight values display tied to inventory formspec
    local fs = player_data[player_name].fs
	fs.center.weight = get_fs_weight(player)
	player_meta:set_string("fs", mt_serialize(fs))
	local formspec = build_fs(fs)
	player:set_inventory_formspec(formspec)
    --debug(flag17, "    updated weight formspec")
    debug(flag17, "  update_inventory_weight() END")
end
local update_inventory_weight = ss.update_inventory_weight


local flag18 = false
-- drops the 'item' from the player inventory and ensures the weight formspec
-- and weigth hud bar are also updated. does not call core.show_formspec()
function ss.drop_items_from_inventory(player, item)
    debug(flag18, "  drop_items_from_inventory()")
    --debug(flag18, "    item name: " .. item:get_name())

    -- update weight formspec and hud
    local weight = get_itemstack_weight(item)
    --debug(flag18, "    weight: " .. weight)
    update_inventory_weight(player, -weight)

    -- drop the items to the ground at player's feet
    local pos = player:get_pos()
    --debug(flag18, "    player pos: " .. mt_pos_to_string(pos))
    mt_add_item(pos, item)
    --debug(flag18, "    item spawned on ground")

    debug(flag18, "  drop_items_from_inventory() END")
end


local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() PLAYER STATS")
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local p_data = player_data[player_name]
    local p_huds = player_hud_ids[player_name]
    local stat_names, metadata

    -- player's current experience level
    metadata = player_meta:get_int("player_level")
    p_data.player_level = (metadata ~= 0 and metadata) or 1

    -- player's current amount of earned skill points
    --player_meta:set_int("player_skill_points", 100) -- for testing purposes
    p_data.player_skill_points = player_meta:get_int("player_skill_points")

    -- the percentage chance of triggering that noise condition. for exampe, a value
    -- of 25 for 'noise_chance_sneeze' is a "25% chance of sneezing" during a noise
    -- check. noise checks occur during scenarios like eating food, drinking liquids,
    -- and digging up nodes like plants and dirt.
    metadata = player_meta:get_float("noise_chance_choke")
    p_data.noise_chance_choke = (metadata ~= 0 and metadata) or 10
    metadata = player_meta:get_float("noise_chance_sneeze_plants")
    p_data.noise_chance_sneeze_plants = (metadata ~= 0 and metadata) or 10
    metadata = player_meta:get_float("noise_chance_sneeze_dust")
    p_data.noise_chance_sneeze_dust = (metadata ~= 0 and metadata) or 10
    metadata = player_meta:get_float("noise_chance_hickups")
    p_data.noise_chance_hickups = (metadata ~= 0 and metadata) or 30

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
    p_data.stamina_loss_crawl_up = 3.0

    p_data.alertness_gain_in_water = 100

    -- inventory index of where the wield item was placed when in cave_sit state
    p_data.wield_item_index = 0

    -- the percentage of the wielded weapon's weight that is used as stamina loss
    -- vlue while swinging it
    p_data.stamina_loss_factor_mining = 0.5

    -- initialize p_data.<stat>_ratio which represents the ratio of the stat's current
    -- value over its max. 0.9 = 90%, 0.5 = 50%, etc. set to -1 as a dummy value.
    -- subsequent code will update it to the actual valid value.
    stat_names = {"health", "thirst", "hunger", "alertness", "hygiene", "comfort",
        "immunity", "sanity", "happiness", "breath", "stamina", "weight", "legs",
        "hands", "illness", "poison", "wetness"}
    for _, stat in ipairs(stat_names) do p_data[stat .. "_ratio"] = -1 end

    -- modifier against the health stat's baseline value. 1 = 100% and represents
    -- no change, 0.5 is 50% reduction, and 1.25 is 25% increase.
    stat_names = {"thirst", "hunger", "alertness", "immunity", "legs", "hands",
        "hot", "cold", "illness", "poison"}
    for _, stat in ipairs(stat_names) do p_data["base_health_mod_" .. stat] = 1 end

    -- modifier against the comfort stat's baseline value. 1 = 100% and represents
    -- no change, 0.5 is 50% reduction, and 1.25 is 25% increase.
    stat_names = {"health", "thirst", "hunger", "hygiene", "breath", "stamina",
        "weight", "legs", "hands", "hot", "cold", "illness", "poison"}
    for _, stat in ipairs(stat_names) do p_data["base_comfort_mod_" .. stat] = 1 end

    -- modifier against the immunity stat's baseline value. 1 = 100% and represents
    -- no change, 0.5 is 50% reduction, and 1.25 is 25% increase.
    stat_names = {"thirst", "hunger", "alertness", "hygiene", "happiness", "cold"}
    for _, stat in ipairs(stat_names) do p_data["base_immunity_mod_" .. stat] = 1 end

    -- modifier against the sanity stat's baseline value. 1 = 100% and represents
    -- no change, 0.5 is 50% reduction, and 1.25 is 25% increase.
    stat_names = {"health", "alertness", "breath"}
    for _, stat in ipairs(stat_names) do p_data["base_sanity_mod_" .. stat] = 1 end

    -- modifier against the happiness stat's baseline value. 1 = 100% and represents
    -- no change, 0.5 is 50% reduction, and 1.25 is 25% increase.
    stat_names = {"alertness", "comfort"}
    for _, stat in ipairs(stat_names) do p_data["base_happiness_mod_" .. stat] = 1 end

    p_data.leg_injury_mod_water = 1

    -- tracks if the breath bar is currently shown on-screen. not saved in player
    -- metadata since this is for hud tracking and will always be false at start
    p_data.is_breathbar_shown = false

    p_data.fall_distance = 0
    p_data.move_distance = 0

    -- hide default health bar
    player:hud_set_flags({ healthbar = false, breathbar = false })

    -- initialize black transparent box hud behind statbars
    p_huds.statbar_bg_box = player:hud_add({
        type = "image",
        position = {x = 0, y = 1},
        alignment = {x = 1, y = -1},
        offset = {x = 0, y = 0},
        -- 'scale' and 'text' properties are initialized further below
    })

    -- holds the HUD display info for each statbar. 'hud_pos' determines which
    -- horiztal position index the statbar appears, 1 starting from the left side.
    -- 'active' determines if the statbar is active or hidden on screen. these
    -- properties are configurable from the Settings tab.
    local statbar_settings_string = player_meta:get_string("statbar_settings")
    if statbar_settings_string == "" then
        --debug(flag1, "  initializing statbar_settings table..")
        p_data.statbar_settings = {
            health = {hud_pos = 11, active = true},
            thirst = {hud_pos = 10, active = true},
            hunger = {hud_pos = 9, active = true},
            alertness = {hud_pos = 8, active = true},
            hygiene = {hud_pos = 7, active = true},
            comfort = {hud_pos = 6, active = true},
            immunity = {hud_pos = 5, active = true},
            sanity = {hud_pos = 4, active = true},
            happiness = {hud_pos = 3, active = true},
            legs = {hud_pos = 2, active = true},
            hands = {hud_pos = 1, active = true},
        }
        player_meta:set_string("statbar_settings", mt_serialize(p_data.statbar_settings))
    else
        --debug(flag1, "  statbar_settings table already contains valid data")
        p_data.statbar_settings = mt_deserialize(statbar_settings_string)
    end
    --debug(flag1, "  p_data.statbar_settings: " .. dump(p_data.statbar_settings))

    -- initialized with a copy of 'statbar_settings' above but will hold any unapplied
    -- changes from the Settings tab. if changes are applied, this data is then copied
    -- to the 'statbar_settings' table above
    p_data.statbar_settings_pending = table_copy(p_data.statbar_settings)

    -- indicates whether the statbar hud visibility or display order has been modified
    -- from the Settings menu but not yet applied
    p_data.unsaved_statbar_settings = false

    -- the opacity of the background box displayed behind the vertical statbars
    -- and status effect images. values can be 5 options, modifiable from the
    -- Settings tab: "00" = 0%, "40" = 25%, "80" = 50%, "C0" = 75%, "FF" = 100%.
    p_data.stats_bg_opacity = player_meta:get_string("stats_bg_opacity")
    if p_data.stats_bg_opacity == "" then
        p_data.stats_bg_opacity = "80"
        player_meta:set_string("stats_bg_opacity", "80")
    end
    --debug(flag1, "  p_data.stats_bg_opacity: " .. p_data.stats_bg_opacity)

    -- initialize huds for the main vertical statbars"
    local total_count = 0
    local active_count = 0
    for stat, stat_data in pairs(p_data.statbar_settings) do
        total_count = total_count + 1
        if stat_data.active then
            active_count = active_count + 1
            initialize_hud_stats(player, player_name, stat, stat_data)
        end
    end
    p_data.active_statbar_count = active_count
    p_data.total_statbar_count = total_count
    --debug(flag1, "  statbar counts: active " .. active_count .. " | total " .. total_count)


    -- the statbars that currently cannot be changed from the Settings tab: breath,
    -- stamina, and weight. 'experience' is not included since it does not trigger
    -- any stat effects
    local unmodifiable_statbars = 3

    -- currently includes 'external' status effect triggered by conditions that do not
    -- have statbars like illness, poison, and wetness. the '+1' represents status
    -- effects due to cold or hot weather.
    local external_stat_effects = #EXT_STAT_NAMES + 1

    -- the max number of status effect huds that can appear on the left side of the
    -- screen. a separate status effect can be triggered by each of the main stats
    -- that have statbars and some that do not
    p_data.on_screen_max = p_data.total_statbar_count + unmodifiable_statbars + external_stat_effects
    --debug(flag1, "  p_data.on_screen_max: " .. p_data.on_screen_max)

    -- initialize all elements of the status effect huds that appear on the left side
    -- of the screen. the actual images and text specific to each status effect and the
    -- black background boxes are updated below and during runtime.
    initialize_hud_stat_effects(player, player_name, p_data.on_screen_max)

    -- adjust vertical position of status effect huds and visiblity/size/opacity
    -- of the statbar main bg box if necessary
    if active_count == 0 then
        -- no active statbars. move stat effect huds down and hide the statbar main bg box
        shift_hud_stat_effects(player, p_data, player_name, false)
        player:hud_change(p_huds.statbar_bg_box, "scale", {x = 0, y = 145})
    else
        -- at least one active statbars exist. show statbar main bg box and apply the chosen opacity
        local x_scale = (active_count * 30) + 15
        player:hud_change(p_huds.statbar_bg_box, "scale", {x = x_scale, y = 145})
        player:hud_change(p_huds.statbar_bg_box, "text", "[fill:1x1:0,0:#000000" .. p_data.stats_bg_opacity)
    end

    -- apply the chosen opacity to the individual status effect huds
    for i = 1, p_data.on_screen_max do
        --debug(flag1, "    updating stat effect bg " .. i)
        local hud_id = player_hud_ids[player_name]["stat_effect_bg_" .. i]
        local hud_def = player:hud_get(hud_id)
        local colorstring = string_sub(hud_def.text, 1, -3) .. p_data.stats_bg_opacity
        --debug(flag1, "      colorstring: " .. colorstring)
        player:hud_change(hud_id, "text", colorstring)
    end

    -- initialize huds for the horizontal stamina and experience statbars
    initialize_hud_stamina(player, player_name)
    initialize_hud_experience(player, player_name)

    -- initialize huds for the small vertical breath and weight statbars
    initialize_hud_breath(player, player_name)
    initialize_hud_weight(player, player_name)

    -- initialize screen overlay/effect huds that are triggered from status effects
    local screen_effect_types = {"health", "stamina", "temperature", "illness",
        "poison", "wetness", "vomit", "sneeze"}
    for i, effect_type in ipairs(screen_effect_types) do
        local z_index = -10000 + (10 * i)
        initialize_hud_scren_effects(player, p_huds, effect_type, z_index)
    end

    -- reflects any active status effects currently experienced by the player.
    -- once the player is back to normal condition, the status effect is removed
    -- from this table.
    -- Example: status_effects = {
    --  <status effect name> = {<type>, <duration, <hud location>},
    --  ["thirst_1"] = {"percentage", ?, 2},
    --  ["hot_3"] = {"temperature", ?, 1},
    --  ["ill_2"] = {"basic", 15, 3}
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
    --  ["thirst_3_health_down"] = 928374657483,
    --  ["alertness_3_immunity_down"] = 768798046352,
    --  ["rec_hunger_3_health_up"] = 195069781424,
    --}
    p_data.se_stat_updates = {}


    local player_status = p_data.player_status
	if player_status == 0 then
		--debug(flag1, "  new player")

        -- set the default screen effect. not using p_data as these properties are not
        -- accessed often, and when they are accessed, they typically need to be modified
        player_meta:set_float("screen_effect_saturation", 1)
        player_meta:set_float("screen_effect_bloom", 0)
        player:set_lighting({
            saturation = 1,
            bloom = {intensity = 0, strength_factor = 0.1, radius = 0.1}
        })

        -- multiplier to fall health damage
        p_data.fall_health_modifier = 6.0
        player_meta:set_float("fall_health_modifier", p_data.fall_health_modifier)

        -- tracks total amount of health drained so far due to any legs or hands
        -- injury. used to calculate health recovery of first aid relating to legs
        -- and hands injury
        p_data.legs_damage_total = 0
        player_meta:set_float("legs_damage_total", p_data.legs_damage_total)
        p_data.hands_damage_total = 0
        player_meta:set_float("hands_damage_total", p_data.hands_damage_total)

        -- 4 = splinted from sprain, 5 = splinted from break, 6 = casted from break
        -- 0 = currently no splint/cast applied
        p_data.legs_recovery_status = 0
        player_meta:set_int("legs_recovery_status", p_data.legs_recovery_status)
        p_data.hands_recovery_status = 0
        player_meta:set_int("hands_recovery_status", p_data.hands_recovery_status)

        -- the amount of breath that is depleted/restored at each loop in monitor_underwater_status()
        p_data.breath_deplete_rate = 4
        player_meta:set_float("breath_deplete_rate", p_data.breath_deplete_rate)
        p_data.breath_restore_rate = 12
        player_meta:set_float("breath_restore_rate", p_data.breath_restore_rate)

        -- the amount of stamina drained when using a fire drill to start a campfire
        p_data.stamina_loss_fire_drill = 20
        player_meta:set_int("stamina_loss_fire_drill", p_data.stamina_loss_fire_drill)

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
        --  [2] = "thirst_1",
        --  [3] = "illness_2"
        --}
        p_data.stat_effect_hud_locations = {}
        player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

        p_data.immunity_check_timer = 0
        player_meta:set_int("immunity_check_timer", p_data.immunity_check_timer)

        -- initialize default base player physics for movement speed and jumping
		local physics = player:get_physics_override()
		physics.speed = p_data.speed_walk
		physics.jump = p_data.height_jump
		player:set_physics_override(physics)

        -- initialize default player stat values and stat bars
        for _, stat_name in ipairs(STAT_NAMES) do
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, DEFAULT_STAT_MAX[stat_name], "max", "set", false)
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, DEFAULT_STAT_START[stat_name], "curr", "set", true)
        end

        -- initialize external stats for external stat effects
        for _, stat_name in ipairs(EXT_STAT_NAMES) do
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, DEFAULT_STAT_MAX[stat_name], "max", "set", false)
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, DEFAULT_STAT_START[stat_name], "curr", "set", true)
        end

        -- initialize base values and change rates for relevant stats
        for stat, data in pairs(BASE_STATS_DATA) do
            local base_value = data.base_value
            p_data["base_value_" .. stat] = base_value
            player_meta:set_float("base_value_" .. stat, base_value)
            update_base_stat_value(player, player_meta, player_name, p_data, {stat})
            p_data["recovery_speed_" .. stat] = data.recovery_speed
            player_meta:set_float("recovery_speed_" .. stat, data.recovery_speed)
            p_data["drain_speed_" .. stat] = data.drain_speed
            player_meta:set_float("drain_speed_" .. stat, data.drain_speed)
        end

        -- add 1 second delay before triggering below 'monitor' functions to allow
        -- world and player to spawn before accessing object and/or node data.
        -- monitor_underwater_status() has an extra delay to allow monitor_player_state()
        -- from player_anim.lua to finish its 1-second delay and get up from crouching
        -- anim stat before monitor_underwater_status() checks if player is underwater.
        if ENABLE_UNDERWATER_CHECK then
            local job_handle = mt_after(0, monitor_underwater_status, player, player_name, p_data, p_data.status_effects)
            job_handles[player_name].monitor_underwater_status = job_handle
        end

        if ENABLE_BASELINE_STATS_MONITOR then
            local job_handle = mt_after(0, monitor_baseline_stats, player, player_meta, player_name, p_data)
            job_handles[player_name].monitor_baseline_stats = job_handle
        end

	elseif player_status == 1 then
		--debug(flag1, "  existing player")

        player:set_lighting({
            saturation = player_meta:get_float("screen_effect_saturation"),
            bloom = {
                intensity = player_meta:get_float("screen_effect_bloom"),
                strength_factor = 0.1,
                radius = 0.1
            }
        })

        p_data.fall_health_modifier = player_meta:get_float("fall_health_modifier")
        p_data.legs_damage_total = player_meta:get_float("legs_damage_total")
        p_data.hands_damage_total = player_meta:get_float("hands_damage_total")

        p_data.legs_recovery_status = player_meta:get_int("legs_recovery_status")
        p_data.hands_recovery_status = player_meta:get_int("hands_recovery_status")

        p_data.stat_effect_hud_locations = mt_deserialize(player_meta:get_string("stat_effect_hud_locations"))

        p_data.immunity_check_timer = player_meta:get_int("immunity_check_timer")

        p_data.breath_deplete_rate = player_meta:get_float("breath_deplete_rate")
        p_data.breath_restore_rate = player_meta:get_float("breath_restore_rate")
        p_data.stamina_loss_fire_drill = player_meta:get_int("stamina_loss_fire_drill")

        -- restore player movement speed and jump physics values
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
        --debug(flag1, "  stat_updates: " .. dump(stat_updates))

		-- restoring the main vertical player stat bars
        for _, stat_name in ipairs(STAT_NAMES) do
            local max_value = player_meta:get_float(stat_name .. "_max")
            local current_value = player_meta:get_float(stat_name .. "_current")
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, max_value, "max", "set", false)
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, current_value, "curr", "set", true)
        end

        -- restore external stats for external stat effects
        for _, stat_name in ipairs(EXT_STAT_NAMES) do
            local max_value = player_meta:get_float(stat_name .. "_max")
            local current_value = player_meta:get_float(stat_name .. "_current")
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, max_value, "max", "set", false)
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, current_value, "curr", "set", true)
        end

        --debug(flag1, "  restoring any existing stat updates")
        local delay = 0
        for id, data in pairs(stat_updates) do
            local trigger = data[1]
            local tokens = string_split(trigger, "_")
            local prefix = tokens[1]

            if prefix == "normal" then
                --debug(flag1, "    normal stat update")

            elseif prefix == "natural" then
                --debug(flag1, "    natural_drain stat update")

            elseif prefix == "se" then
                --debug(flag1, "    stat update triggered by a status effect")
                -- this is already handled by monitor_status_effects() function

            elseif prefix == "ie" then
                --debug(flag1, "    immunity effect stat update. no further action.")
                -- this is already handled by monitor_status_effects() function

            elseif prefix == "rec" then
                --debug(flag1, "    stat update to recover comfort or hp, triggered by a status effect")
                p_data.se_stat_updates[trigger] = id
                local key = "recovery_" .. tokens[4] .. "_count"
                --debug(flag1, "    key: " .. key)
                p_data[key] = p_data[key] + 1

            else
                debug(flag1, "    ERROR - Unexpected 'trigger' value: " .. trigger)
            end

            mt_after(delay, stat_update_loop, player, p_data, player_meta, id)
            delay = delay + 0.2  -- stagger them to prevent all running on same tick
        end

        for stat in pairs(BASE_STATS_DATA) do
            local base_value = player_meta:get_float("base_value_" .. stat)
            p_data["base_value_" .. stat] = base_value
            update_base_stat_value(player, player_meta, player_name, p_data, {stat})
            p_data["recovery_speed_" .. stat] = player_meta:get_float("recovery_speed_" .. stat)
            p_data["drain_speed_" .. stat] = player_meta:get_float("drain_speed_" .. stat)
        end

        if ENABLE_UNDERWATER_CHECK then
            local job_handle = mt_after(0, monitor_underwater_status, player, player_name, p_data, p_data.status_effects)
            job_handles[player_name].monitor_underwater_status = job_handle
        end

        if ENABLE_BASELINE_STATS_MONITOR then
            local job_handle = mt_after(0, monitor_baseline_stats, player, player_meta, player_name, p_data)
            job_handles[player_name].monitor_baseline_stats = job_handle
        end

        -- grant cooking XP to player due to item having finished cooking while player was offline
        local meta_key = "xp_cooking_" .. player_name
        local cooking_xp_owed = mod_storage:get_float(meta_key)

        if cooking_xp_owed > 0 then
            --debug(flag1, "  cooking_xp_owed: " .. cooking_xp_owed)
            do_stat_update_action(player, p_data, player_meta, "normal", "experience", cooking_xp_owed, "curr", "add", true)
            mod_storage:set_float(meta_key, 0)
        else
            --debug(flag1, "  no owed cooking XP")
        end


    elseif player_status == 2 then
		--debug(flag1, "  dead player")

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

        -- show the current state of the statbars and any stat effect hud images
        -- as they were upon death
        -- restore the main vertical player stat bars
        for _, stat_name in ipairs(STAT_NAMES) do
            local max_value = player_meta:get_float(stat_name .. "_max")
            local current_value = player_meta:get_float(stat_name .. "_current")
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, max_value, "max", "set", false)
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, current_value, "curr", "set", true)
        end

        -- restore external stats for external stat effects
        for _, stat_name in ipairs(EXT_STAT_NAMES) do
            local max_value = player_meta:get_float(stat_name .. "_max")
            local current_value = player_meta:get_float(stat_name .. "_current")
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, max_value, "max", "set", false)
            do_stat_update_action(player, p_data, player_meta, "normal", stat_name, current_value, "curr", "set", true)
        end

        -- stop any status effects from continuing
        for effect_name in pairs(p_data.status_effects) do
            --debug(flag1, "    stopping " .. effect_name)
            p_data.status_effects[effect_name] = nil
        end
        --debug(flag1, "  status effects (after): " .. dump(p_data.status_effects) .. "\n")

        -- stop any existing stat updates from continuing
        for id, update_data in pairs(p_data.stat_updates) do
            --debug(flag1, "    stopping " .. update_data[2])
            p_data.stat_updates[id] = nil
        end
        --debug(flag1, "  stat updates (after): " .. dump(p_data.stat_updates) .. "\n")

	end

	debug(flag1, "register_on_joinplayer() end")
end)


local flag15 = false
core.register_on_dieplayer(function(player)
    debug(flag15, "\nregister_on_dieplayer() PLAYER STATS")

    -- wrapped in core.after() to allow the function that set hp to zero do_stat_update_action()
    -- to complete the rest of its execution before dieplayer() code is executed
    mt_after(0, function()
        local player_meta = player:get_meta()
        local player_name = player:get_player_name()
        local p_data = player_data[player_name]

        player_meta:set_int("player_status", 2)
        p_data.player_status = 2

        --debug(flag15, "  cancel any existing stat updates..")
        local stat_updates = p_data.stat_updates
        --debug(flag15, "  stat_updates (before): " .. dump(stat_updates))
        for id, update_data in pairs(stat_updates) do
            --debug(flag15, "    stopping stat update id: " .. id .. " for " .. update_data[2])
            stat_updates[id] = nil
        end
        --debug(flag15, "  stat_updates (after): " .. dump(stat_updates))

        --debug(flag15, "  cancel any existing status effects..")
        local status_effects = p_data.status_effects
        --debug(flag15, "  status_effects (before): " .. dump(status_effects))
        for effect_name in pairs(status_effects) do
            --debug(flag15, "    stopping stat effect: " .. effect_name)
            status_effects[effect_name] = nil
            -- this does not remove the stat effect huds from the screen, which is fine since
            -- the player should see what all ailments and injuries existed upon their death =)
            -- the stat effect huds will be removed during register_on_respawnplayer()
        end
        --debug(flag15, "  status_effects (after): " .. dump(status_effects))

        --debug(flag15, "  cancel any existing se_stat_updates..")
        local se_stat_updates = p_data.se_stat_updates
        --debug(flag15, "  se_stat_updates (before): " .. dump(se_stat_updates))
        for update_name in pairs(se_stat_updates) do
            --debug(flag15, "    stopping se_stat_updates: " .. update_name)
            se_stat_updates[update_name] = nil

        end
        --debug(flag15, "  se_stat_updates (after): " .. dump(se_stat_updates))

        --debug(flag15, "  cancel monitor_underwater_status() loop..")
        local job_handle = job_handles[player_name].monitor_underwater_status
        job_handle:cancel()
        job_handles[player_name].monitor_underwater_status = nil

        --debug(flag15, "  cancel monitor_status_effects() loop..")
        job_handle = job_handles[player_name].monitor_status_effects
        job_handle:cancel()
        job_handles[player_name].monitor_status_effects = nil

        --debug(flag15, "  cancel monitor_baseline_stats() loop..")
        job_handle = job_handles[player_name].monitor_baseline_stats
        job_handle:cancel()
        job_handles[player_name].monitor_baseline_stats = nil

        --debug(flag15, "  resetting player inventory weight to zero..")
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
    debug(flag16, "\nregister_on_respawnplayer() PLAYER STATS")
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local p_data = ss.player_data[player_name]

    --debug(flag5, "  reset player level and skill points")
    p_data.player_level = 1
	player_meta:set_int("player_level", p_data.player_level)
    p_data.player_skill_points = 0
    player_meta:set_int("player_skill_points", p_data.player_skill_points)

    p_data.noise_chance_choke = 10
    player_meta:set_float("noise_chance_choke", p_data.noise_chance_choke)
    p_data.noise_chance_sneeze_plants = 10
    player_meta:set_float("noise_chance_sneeze_plants", p_data.noise_chance_sneeze_plants)
    p_data.noise_chance_sneeze_dust = 10
    player_meta:set_float("noise_chance_sneeze_dust", p_data.noise_chance_sneeze_dust)
    p_data.noise_chance_hickups = 30
    player_meta:set_float("noise_chance_hickups", p_data.noise_chance_hickups)

    --debug(flag16, "  reset stamina gain values for certain actions")
    p_data.stamina_gain_stand = 2.0
    p_data.stamina_gain_walk = 1.0
    p_data.stamina_gain_sit_cave = 2.0

    --debug(flag16, "  reset stamina loss values for certain actions")
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
    p_data.stamina_loss_crawl_up = 3.0

    p_data.stamina_loss_factor_mining = 0.5

    --debug(flag16, "  reset breath stat related properties")
    p_data.is_breathbar_shown = false

    p_data.breath_deplete_rate = 4
    player_meta:set_float("breath_deplete_rate",p_data.breath_deplete_rate)
    p_data.breath_restore_rate = 12
    player_meta:set_float("breath_restore_rate", p_data.breath_restore_rate)

    --debug(flag16, "  reset wield item index, weight tier, and statbar settings status")
    p_data.wield_item_index = 0
    p_data.weight_ratio = 0
    p_data.unsaved_statbar_settings = false

    --debug(flag16, "  resetting hud for stamina exhaustion screen color overlay")
    player:hud_change(
        player_hud_ids[player_name].screen_effect_stamina,
        "text",
        "[fill:1x1:0,0:#888844^[opacity:0"
    )

    -- ### not resetting black transparent box hud behind statbars
    -- ### not resetting huds for the main vertical statbars
    -- ### not resetting huds for the horizontal stamina and experience statbars
    -- ### not resetting huds for the small vertical breath and weight statbars

    -- not resetting these two tables, but keeping same data from prior play session.
    -- these are loaded from join player callback in global_vars_init.lua.
    --p_data.statbar_settings = {}
    --p_data.stats_bg_opacity = {}

    --debug(flag16, "  hide any stat effects huds that remained onscreen during death")
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

    --debug(flag16, "  reset screen effects due to any status effects")
    player_meta:set_float("screen_effect_saturation", 1)
    player_meta:set_float("screen_effect_bloom", 0)
    player:set_lighting({
        saturation = 1,
        bloom = {intensity = 0, strength_factor = 0.1, radius = 0.1}
    })
    hud_id = player_hud_ids[player_name].screen_effect_health
    player:hud_change(hud_id, "text", "")

    -- re-initialize base values and change rates for relevant stats
    for stat, data in pairs(BASE_STATS_DATA) do
        p_data["base_value_" .. stat] = data.base_value
        player_meta:set_float("base_value_" .. stat, data.base_value)
        p_data["recovery_speed_" .. stat] = data.recovery_speed
        player_meta:set_float("recovery_speed_" .. stat, data.recovery_speed)
        p_data["drain_speed_" .. stat] = data.drain_speed
        player_meta:set_float("drain_speed_" .. stat, data.drain_speed)
    end

    p_data.fall_health_modifier = 6
    player_meta:set_float("fall_health_modifier", p_data.fall_health_modifier)
    p_data.legs_damage_total = 0
    player_meta:set_float("legs_damage_total", p_data.legs_damage_total)
    p_data.hands_damage_total = 0
    player_meta:set_float("hands_damage_total", p_data.hands_damage_total)

    p_data.legs_recovery_status = 0
    player_meta:set_int("legs_recovery_status", p_data.legs_recovery_status)
    p_data.hands_recovery_status = 0
    player_meta:set_int("hands_recovery_status", p_data.hands_recovery_status)

    --debug(flag16, "  reset stat updates table to empty")
    p_data.stat_updates = {}
    player_meta:set_string("stat_updates", mt_serialize(p_data.stat_updates))

    --debug(flag16, "  reset status effect related properties and tables")
    p_data.status_effect_count = 0
    p_data.status_effects = {}
    player_meta:set_string("status_effects", mt_serialize(p_data.status_effects))
    p_data.stat_effect_udpate_ids = {}
    player_meta:set_string("stat_effect_udpate_ids", mt_serialize(p_data.stat_effect_udpate_ids))
    p_data.stat_effect_hud_locations = {}
    player_meta:set_string("stat_effect_hud_locations", mt_serialize(p_data.stat_effect_hud_locations))

    --debug(flag16, "  remove any screen effects from status effects")
    player:set_lighting({
        saturation = 1,
        bloom = {intensity = 0, strength_factor = 0.1, radius = 0.1}
    })

    --debug(flag16, "  reset immunity effects related properties")
    p_data.immunity_check_timer = 0
    player_meta:set_int("immunity_check_timer", p_data.immunity_check_timer)

    --debug(flag16, "  stamina loss value from using fire drill")
    p_data.stamina_loss_fire_drill = 20
    player_meta:set_int("stamina_loss_fire_drill", p_data.stamina_loss_fire_drill)

    --debug(flag16, "  reset to default movement speed and jumping height")
    local physics = player:get_physics_override()
    physics.speed = p_data.speed_walk
    physics.jump = p_data.height_jump
    player:set_physics_override(physics)

    --debug(flag16, "  reset player stat bars to default values")
    --local update_data
    for _, stat_name in ipairs(STAT_NAMES) do
        do_stat_update_action(player, p_data, player_meta, "normal", stat_name, DEFAULT_STAT_MAX[stat_name], "max", "set", false)
        do_stat_update_action(player, p_data, player_meta, "normal", stat_name, DEFAULT_STAT_START[stat_name], "curr", "set", true)
    end

    --debug(flag16, "  reset external stats")
    for _, stat_name in ipairs(EXT_STAT_NAMES) do
        do_stat_update_action(player, p_data, player_meta, "normal", stat_name, DEFAULT_STAT_MAX[stat_name], "max", "set", false)
        do_stat_update_action(player, p_data, player_meta, "normal", stat_name, DEFAULT_STAT_START[stat_name], "curr", "set", true)
    end

    -- initialize base values and change rates for relevant stats
    for stat, data in pairs(BASE_STATS_DATA) do
        local base_value = data.base_value
        p_data["base_value_" .. stat] = base_value
        player_meta:set_float("base_value_" .. stat, base_value)
        update_base_stat_value(player, player_meta, player_name, p_data, {stat})
        p_data["recovery_speed_" .. stat] = data.recovery_speed
        player_meta:set_float("recovery_speed_" .. stat, data.recovery_speed)
        p_data["drain_speed_" .. stat] = data.drain_speed
        player_meta:set_float("drain_speed_" .. stat, data.drain_speed)
    end

    if ENABLE_UNDERWATER_CHECK then
        local job_handle = mt_after(0, monitor_underwater_status, player, player_name, p_data, p_data.status_effects)
        job_handles[player_name].monitor_underwater_status = job_handle
        --debug(flag16, "  enabled breath monitor")
    end

    if ENABLE_BASELINE_STATS_MONITOR then
        local job_handle = mt_after(0, monitor_baseline_stats, player, player_meta, player_name, p_data)
        job_handles[player_name].monitor_baseline_stats = job_handle
        --debug(flag1, "  started baseline stats monitor")
    end

    debug(flag16, "register_on_respawnplayer() END")
end)


local flag19 = false
core.register_on_leaveplayer(function(player)
    debug(flag19, "\nregister_on_leaveplayer() PLAYER STATS")
    local player_name = player:get_player_name()

    local job_handle = job_handles[player_name].monitor_underwater_status
    if job_handle then
        job_handle:cancel()
        job_handles[player_name].monitor_underwater_status = nil
        --debug(flag19, "  cancelled monitor_underwater_status() loop..")
    end

    job_handle = job_handles[player_name].monitor_status_effects
    if job_handle then
        job_handle:cancel()
        job_handles[player_name].monitor_status_effects = nil
        --debug(flag19, "  cancelled monitor_status_effects() loop..")
    end

    job_handle = job_handles[player_name].monitor_baseline_stats
    if job_handle then
        job_handle:cancel()
        job_handles[player_name].monitor_baseline_stats = nil
        --debug(flag19, "  cancelled monitor_baseline_stats() loop..")
    end

    debug(flag19, "register_on_leaveplayer() END")
end)