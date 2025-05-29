print("- loading skills.lua")

-- cache global functions for faster access
local math_abs = math.abs
local string_split = string.split
local string_sub = string.sub
local table_concat = table.concat
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local mt_colorize = core.colorize
local debug = ss.debug
local round = ss.round
local notify = ss.notify
local convert_to_celcius = ss.convert_to_celcius
local play_sound = ss.play_sound
local do_stat_update_action = ss.do_stat_update_action
local update_fs_weight = ss.update_fs_weight
local update_player_physics = ss.update_player_physics

-- cache global variables for faster access
local SLOT_COLOR_BG = ss.SLOT_COLOR_BG
local SLOT_COLOR_HOVER = ss.SLOT_COLOR_HOVER
local SLOT_COLOR_BORDER = ss.SLOT_COLOR_BORDER
local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local BASE_STATS_DATA = ss.BASE_STATS_DATA
local player_data = ss.player_data

local SKILL_COLORS = {
    strength = "#ff0000", -- red
    toughness = "#ff4000", -- orange red
    agility = "#00ff00", -- green
    endurance = "#a0ff00", -- yellow green
    immunity = "#a0ffff", -- bluish white
    intellect = "#ff80bf", -- pink
    digestion = "#ff8000", -- orange
    survival = "#55800c", -- light brown
}

-- modify the underlying value or rate by the below percentage. example 0.10 = 10%.
local UPGRADE_INC_03 = 0.03
local UPGRADE_INC_05 = 0.05
local UPGRADE_INC_10 = 0.10

local skill_names = {
        "strength", "toughness", "agility", "endurance", "immunity", "intellect",
        "digestion", "survival"
    }

ss.PLAYER_SKILLS = {
    strength = {
        {"power_lifter", "Power Lifter", "Increased maximum carrying weight", "Total Max Weight Increase +", "increase by ", 2400},
        {"cargo_tank", "Cargo Tank", "Less impact to movement speed due to weight", "Total Hinderance Improvement +", "increase by ", UPGRADE_INC_05, "%"},
        {"bulk_bouncer", "Bulk Bouncer", "Less impact to jump height due to weight", "Total Hinderance Improvement +", "increase by ", UPGRADE_INC_05, "%"},
        {"forearm_freak", "Forearm Freak", "Less weight impact from wielded item", "Total Weight Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
    },
    toughness = {
        {"meat_shield", "Meat Shield", "Increased maximum health", "Total Max Health Increase +", "increase by ", 100},
        {"rapid_recovery", "Rapid Recovery", "Faster health regeneration", "Total Health Recovery Speed +", "increase by ", 0.1, "per min"},
        {"thudmuffin", "Thudmuffin", "Less health impact from blunt force injuries", "Total Injury Health Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"knuckle_saurus", "Knuckle-saurus", "Less prone to hand pains and injuries", "Total Hand Injury -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"digit_doctor", "Digit Doctor", "Faster hand recovery", "Total Hand Recovery Speed +", "increase by ", 0.1, "per min"},
        {"shin_credible", "Shin-credible", "Less prone to leg pains and injuries", "Total Leg Injury -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"knee_juvinator", "Knee-juvinator", "Faster leg recovery", "Total Leg Recovery Speed +", "increase by ", 0.1, "per min"},
        {"comfy_cat", "Comfy Cat", "Increased maximum comfort", "Total Max Comfort Increase +", "increase by ", 100},
        {"comeback_koala", "Comeback Koala", "Faster comfort recovery", "Total Comfort Recovery +", "increase by ", 0.1, "per min"},
        {"numb_skull", "Numb Skull", "Slower rate of comfort degradation", "Total Comfort Drain Speed -", "decrease by ", UPGRADE_INC_05, "%"},
    },
    agility = {
        {"speed_walker", "Speed Walker", "Increased walking speed", "Total Walk Speed Increase +", "increase by ", UPGRADE_INC_03, "%"},
        {"sprinter", "Sprinter", "Increased running speed", "Total Run Speed Increase +", "increase by ", UPGRADE_INC_05, "%"},
        {"creeper", "Creeper", "Increased movement speed while crouching", "Total Crouching Speed Increase +", "increase by ", UPGRADE_INC_03, "%"},
        {"launchitude", "Launchitude", "Increased jump height", "Total Jump Height Increase +", "increase by ", UPGRADE_INC_05, "%"},
    },
    endurance = {
        {"nonstop_nomad", "Nonstop Nomad", "Increased maximum stamina", "Total Max Stamina Increase +", "increase by ", 100},
        {"fast_charger", "Fast Charger", "Faster stamina recovery", "Total Stamina Recovery Speed +", "increase by ", UPGRADE_INC_10, "%"},
        {"burnout_blocker", "Burnout Blocker", "Slower stamina drain", "Total Stamina Drain Speed -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"air_tank", "Air Tank", "Increased maximum breathing capacity", "Total Max Breath Increase +", "increase by ", 100},
        {"oxygenator", "Oxygenator", "Faster breath recovery", "Total Breath Recovery Speed +", "increase by ", UPGRADE_INC_10, "%"},
        {"deep_diver", "Deep Diver", "Slower breath drain", "Total Breath Drain Speed -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"smotherproof", "Smother-proof", "Less health drain while suffocating", "Total Breath Health Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"night_owl", "Night Owl", "Increased maximum alertness", "Total Max Alertness Increase +", "increase by ", 100},
        {"insomniac", "Insomniac", "Slower onset of sleepiness", "Total Alertness Drain Speed -", "decrease by ", UPGRADE_INC_05, "%"},
    },
    immunity = {
        {"bio_blocker", "Bio-blocker", "Increased maximum immunity", "Total Max Immunity Increase +", "increase by ", 100},
        {"tcell_tyrant", "T-Cell Tyrant", "Faster immunity recovery", "Total Immunity Recovery +", "increase by ", 0.1, "per min"},
        {"bcell_boss", "B-Cell Boss", "Slower rate of immunity degradation", "Total Immunity Drain Speed -", "decrease by ", UPGRADE_INC_05, "%"},
        {"fever_flusher", "Fever Flusher", "Faster illness recovery", "Total Illness Recovery +", "increase by ", 0.1, "per min"},
        {"sniffle_shield", "Sniffle Shield", "Slower progression of illness", "Total Illness Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"stage4_nope", "Stage 4 Nope", "Less health drain while ill", "Total Illness Health Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"barf_and_go", "Barf-and-Go", "Faster recovery from food poisoning", "Total Poison Recovery +", "increase by ", 0.1, "per min"},
        {"toxintanium", "Toxin-tanium", "Slower progression of food poisoning", "Total Poison Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"dinner_death_dodger", "Dinner Death-dodger", "Less health drain while poisoned", "Total Poison Health Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
    },
    intellect = {
        {"fast_learner", "Fast Learner", "Faster experience gain", "Total Experience Gain Bonus +", "increase by ", UPGRADE_INC_10, "%"},
        {"zen_master", "Zen Master", "Increased maximum sanity", "Total Max Sanity Increase +", "increase by ", 100},
        {"brain_bouncer", "Brain Bouncer", "Faster sanity recovery", "Total Sanity Recovery +", "increase by ", 0.1, "per min"},
        {"psycho_shield", "Psycho Shield", "Slower rate of sanity degradation", "Total Sanity Drain Speed -", "decrease by ", UPGRADE_INC_05, "%"},
        {"happy_camper", "Happy Camper", "Increased maximum happiness", "Total Max Happiness Increase +", "increase by ", 100},
        {"sad_squasher", "Sad Squasher", "Faster happiness recovery", "Total Happiness Recovery +", "increase by ", 0.1, "per min"},
        {"cryproof", "Cry-proof", "Slower rate of happiness degradation", "Total Happiness Drain Speed -", "decrease by ", UPGRADE_INC_05, "%"},
    },
    digestion = {
        {"belly_bank", "Belly Bank", "Increased maximum fullness from hunger", "Total Max Hunger Increase +", "increase by ", 100},
        {"slowbelly", "Slowbelly", "Slower onset of hunger", "Total Hunger Speed -", "decrease by ", UPGRADE_INC_05, "%"},
        {"digestinator", "Digestinator", "Greater satiation when eating", "Total Satiation Recovery +", "increase by ", UPGRADE_INC_05, "%"},
        {"foodless_freak", "Foodless Freak", "Less health drain while hungry", "Total Hunger Health Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"water_camel", "Water Camel", "Increased maximum hydration from thirst", "Total Max Thirst Increase +", "increase by ", 100},
        {"h2_holder", "H2-Holder", "Slower onset of thirst", "Total Thirst Speed -", "decrease by ", UPGRADE_INC_05, "%"},
        {"h2_oh_yeah", "H2-Oh-Yeah", "Greater hydration when drinking", "Total Hydration Recovery +", "increase by ", UPGRADE_INC_05, "%"},
        {"sipless_survivor", "Sipless Survivor", "Less health drain while thirsty", "Total Thirst Health Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"unchokeable", "Unchokeable", "Less chance of choking when eating or drinking", "Total Choking Chance -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"unhiccable", "Unhiccable", "Less chance of having hiccups", "Total Hiccup Chance -", "decrease by ", -UPGRADE_INC_05, "%"},
    },
    survival = {
        {"coolossus", "Coolossus", "Increased resistance to cold temperatures", "Total Cold Resistance +", "increase by ", 1.5, "temp"},
        {"freezeproof", "Freeze-proof", "Less health drain while cold", "Total Cold Health Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"crispy_crusader", "Crispy Crusader", "Increased resistance to hot temperatures", "Total Heat Resistance ", "improve by ", 1.5, "temp"},
        {"scorchproof", "Scorch-proof", "Less health drain while hot", "Total Hot Health Impact -", "decrease by ", -UPGRADE_INC_05, "%"},
        {"stankproof", "Stank-proof", "Increased maximum hygiene", "Total Max Hygiene Increase +", "increase by ", 100},
        {"bo_buffer", "BO Buffer", "Slower rate of hygiene degradation", "Total Hygiene Drain Speed -", "decrease by ", UPGRADE_INC_05, "%"},
        {"booger_barrier", "Booger Barrier", "Less chance of sneezing from dirt and pollens", "Total Sneeze Chance -", "decrease by ", -UPGRADE_INC_05, "%"},
    },
}
local PLAYER_SKILLS = ss.PLAYER_SKILLS


local flag8 = false
function ss.update_tooltips(p_data, subskill_id, subskill_data, extra_data)
    debug(flag8, "    update_tooltips()")
    debug(flag8, "      subskill_id: " .. subskill_id)

    -- tooltip 1 = displays when over the subskill value progress bars
    -- tooltip 2 = displays when over the subskill upgrade '+' button

    local subskill_value = p_data["subskill_value_" .. subskill_id]
    local subskill_units = subskill_data[7] or ""

    -- tooltip text displays upgrade info as actual stat values with no units
    if subskill_units == "" then
        debug(flag8, "      subskill has no units")
        local increment = subskill_data[6]/10
        local subskill_total = subskill_value * increment
        p_data["subskill_tooltip_1_" .. subskill_id] = subskill_data[4] .. mt_colorize("#FFFF00", subskill_total)
        p_data["subskill_tooltip_2_" .. subskill_id] = subskill_data[5] .. mt_colorize("#FFFF00", increment)

    -- tooltip text displays upgrade info as a rate value with units of 'per min'
    elseif subskill_units == "per min" then
        debug(flag8, "      subskill has time rate units")

        local upgrade_increment = subskill_data[6]/10
        local additional_speed_per_min = upgrade_increment * 60
        local total_from_upgrades = subskill_value * additional_speed_per_min
        local total_from_default = BASE_STATS_DATA[extra_data.stat].recovery_speed * 60

        -- generate the tooltip that shows over the upgrade progress bars of the subskill
        local tooltip_1 = table_concat({
            subskill_data[4],
            mt_colorize("#FFFF00", total_from_upgrades + total_from_default),
            " ", subskill_units
        })
        p_data["subskill_tooltip_1_" .. subskill_id] = tooltip_1

        -- generate the tooltip that shows over the upgrade '+' button of the subskill
        local tooltip_2 = table_concat({
            "increase by ", mt_colorize("#FFFF00",
            additional_speed_per_min),
            " ", subskill_units
        })
        p_data["subskill_tooltip_2_" .. subskill_id] = tooltip_2

    -- tooltip text displays upgrade info as percentage values with units of '%'
    elseif subskill_units == "%" then
        debug(flag8, "      subskill has percentage units")
        local increment = math_abs(subskill_data[6])
        local total_value = subskill_value * increment * 100
        p_data["subskill_tooltip_1_" .. subskill_id] = subskill_data[4] .. mt_colorize("#FFFF00", total_value) .. subskill_units
        p_data["subskill_tooltip_2_" .. subskill_id] = subskill_data[5] .. mt_colorize("#FFFF00", increment * 100) .. subskill_units

    elseif subskill_units == "temp" then
        debug(flag8, "      subskill has temperature units")
        local increment = subskill_data[6]
        local subskill_total = subskill_value * increment

        local units = " °F"
        if p_data.thermal_units == 2 then
            units = " °C"
            subskill_total = convert_to_celcius(subskill_total, 1, true)
            increment = convert_to_celcius(increment, 2, true)
        end
        p_data["subskill_tooltip_1_" .. subskill_id] = subskill_data[4] .. mt_colorize("#FFFF00", subskill_total) .. units
        p_data["subskill_tooltip_2_" .. subskill_id] = subskill_data[5] .. mt_colorize("#FFFF00", increment) .. units

    else
        debug(flag8, "      ERROR - Unexpected 'subskill_units' value: " .. subskill_units)
    end

    debug(flag8, "    update_tooltips() END")
end
local update_tooltips = ss.update_tooltips

local function initialize_subskill_tooltips(p_data)
    -- strength
    update_tooltips(p_data, "power_lifter", PLAYER_SKILLS.strength[1])
    update_tooltips(p_data, "cargo_tank", PLAYER_SKILLS.strength[2])
    update_tooltips(p_data, "bulk_bouncer", PLAYER_SKILLS.strength[3])
    update_tooltips(p_data, "forearm_freak", PLAYER_SKILLS.strength[4])

    -- toughness
    update_tooltips(p_data, "meat_shield", PLAYER_SKILLS.toughness[1])
    update_tooltips(p_data, "rapid_recovery", PLAYER_SKILLS.toughness[2], {stat = "health"})
    update_tooltips(p_data, "thudmuffin", PLAYER_SKILLS.toughness[3])
    update_tooltips(p_data, "knuckle_saurus", PLAYER_SKILLS.toughness[4])
    update_tooltips(p_data, "digit_doctor", PLAYER_SKILLS.toughness[5], {stat = "hands"})
    update_tooltips(p_data, "shin_credible", PLAYER_SKILLS.toughness[6])
    update_tooltips(p_data, "knee_juvinator", PLAYER_SKILLS.toughness[7], {stat = "legs"})
    update_tooltips(p_data, "comfy_cat", PLAYER_SKILLS.toughness[8])
    update_tooltips(p_data, "comeback_koala", PLAYER_SKILLS.toughness[9], {stat = "comfort"})
    update_tooltips(p_data, "numb_skull", PLAYER_SKILLS.toughness[10])

    -- agility
    update_tooltips(p_data, "speed_walker", PLAYER_SKILLS.agility[1])
    update_tooltips(p_data, "sprinter", PLAYER_SKILLS.agility[2])
    update_tooltips(p_data, "creeper", PLAYER_SKILLS.agility[3])
    update_tooltips(p_data, "launchitude", PLAYER_SKILLS.agility[4])

    -- endurance
    update_tooltips(p_data, "nonstop_nomad", PLAYER_SKILLS.endurance[1])
    update_tooltips(p_data, "fast_charger", PLAYER_SKILLS.endurance[2])
    update_tooltips(p_data, "burnout_blocker", PLAYER_SKILLS.endurance[3])
    update_tooltips(p_data, "air_tank", PLAYER_SKILLS.endurance[4])
    update_tooltips(p_data, "oxygenator", PLAYER_SKILLS.endurance[5])
    update_tooltips(p_data, "deep_diver", PLAYER_SKILLS.endurance[6])
    update_tooltips(p_data, "smotherproof", PLAYER_SKILLS.endurance[7])
    update_tooltips(p_data, "night_owl", PLAYER_SKILLS.endurance[8])
    update_tooltips(p_data, "insomniac", PLAYER_SKILLS.endurance[9])

    -- immunity
    update_tooltips(p_data, "bio_blocker", PLAYER_SKILLS.immunity[1])
    update_tooltips(p_data, "tcell_tyrant", PLAYER_SKILLS.immunity[2], {stat = "immunity"})
    update_tooltips(p_data, "bcell_boss", PLAYER_SKILLS.immunity[3])
    update_tooltips(p_data, "fever_flusher", PLAYER_SKILLS.immunity[4], {stat = "illness"})
    update_tooltips(p_data, "sniffle_shield", PLAYER_SKILLS.immunity[5])
    update_tooltips(p_data, "stage4_nope", PLAYER_SKILLS.immunity[6])
    update_tooltips(p_data, "barf_and_go", PLAYER_SKILLS.immunity[7], {stat = "poison"})
    update_tooltips(p_data, "toxintanium", PLAYER_SKILLS.immunity[8])
    update_tooltips(p_data, "dinner_death_dodger", PLAYER_SKILLS.immunity[9])

    -- intellect
    update_tooltips(p_data, "fast_learner", PLAYER_SKILLS.intellect[1])
    update_tooltips(p_data, "zen_master", PLAYER_SKILLS.intellect[2])
    update_tooltips(p_data, "brain_bouncer", PLAYER_SKILLS.intellect[3], {stat = "sanity"})
    update_tooltips(p_data, "psycho_shield", PLAYER_SKILLS.intellect[4])
    update_tooltips(p_data, "happy_camper", PLAYER_SKILLS.intellect[5])
    update_tooltips(p_data, "sad_squasher", PLAYER_SKILLS.intellect[6], {stat = "happiness"})
    update_tooltips(p_data, "cryproof", PLAYER_SKILLS.intellect[7])

    -- digestion
    update_tooltips(p_data, "belly_bank", PLAYER_SKILLS.digestion[1])
    update_tooltips(p_data, "slowbelly", PLAYER_SKILLS.digestion[2])
    update_tooltips(p_data, "digestinator", PLAYER_SKILLS.digestion[3])
    update_tooltips(p_data, "foodless_freak", PLAYER_SKILLS.digestion[4])
    update_tooltips(p_data, "water_camel", PLAYER_SKILLS.digestion[5])
    update_tooltips(p_data, "h2_holder", PLAYER_SKILLS.digestion[6])
    update_tooltips(p_data, "h2_oh_yeah", PLAYER_SKILLS.digestion[7])
    update_tooltips(p_data, "sipless_survivor", PLAYER_SKILLS.digestion[8])
    update_tooltips(p_data, "unchokeable", PLAYER_SKILLS.digestion[9])
    update_tooltips(p_data, "unhiccable", PLAYER_SKILLS.digestion[10])

    -- survival
    update_tooltips(p_data, "coolossus", PLAYER_SKILLS.survival[1])
    update_tooltips(p_data, "freezeproof", PLAYER_SKILLS.survival[2])
    update_tooltips(p_data, "crispy_crusader", PLAYER_SKILLS.survival[3])
    update_tooltips(p_data, "scorchproof", PLAYER_SKILLS.survival[4])
    update_tooltips(p_data, "stankproof", PLAYER_SKILLS.survival[5])
    update_tooltips(p_data, "bo_buffer", PLAYER_SKILLS.survival[6])
    update_tooltips(p_data, "booger_barrier", PLAYER_SKILLS.survival[7])

end


-- create a table that matches the subskill_id with the subskill name
--[[ example: SUBSKILL_NAMES = {
    meat_shield = "Meat Shield",
    sprinter = "Sprinter",
    tcell_tyrant = "T-Cell Tyrant",
}
--]]
local SUBSKILL_NAMES = {}
for _, skill_data in pairs(PLAYER_SKILLS) do
    for _, subskill_data in ipairs(skill_data) do
        local subskill_id = subskill_data[1]
        SUBSKILL_NAMES[subskill_id] = subskill_data[2]
    end
end


-- index by player name and holds references to any subskill that was upgraded but
-- not yet saved. allows the 'cancel', and 'save' buttons to dynamically hide or
-- show when necessary
local unsaved_subskill_upgrades = {}
--[[ example: {
    [player_name] = {
        <subskill_id> = true,
        <modified_subskill_id> = 3,
        forearm_freak = true,
        sprinter = true,
        modified_sprinter = 3,
    }
}
--]]


-- modifies the <stat>_max value of the stat and displays upgrade info as the actual
-- value amount that is increased
local function upgrade_stat_max(player, player_meta, p_data, stat, subskill_id, subskill_data, upgrade_quantity)
    local old_stat_max = player_meta:get_float(stat .. "_max")
    local upgrade_increment = subskill_data[6]/10
    local change_value = upgrade_quantity * upgrade_increment
    do_stat_update_action(player, p_data, player_meta, "normal", stat, change_value, "max", "add", true)
    if stat == "weight" then
        update_fs_weight(player, player_meta)
    else
        local key = "base_value_" .. stat
        local base_value_ratio = p_data[key] / old_stat_max
        local new_base_value = p_data[key] + (change_value * base_value_ratio)
        p_data[key] = new_base_value
        player_meta:set_float(key, new_base_value)
    end
    update_tooltips(p_data, subskill_id, subskill_data)
end

-- modifies the p_data.recovery_speed_<stat> property, used by monitor_base_stat()
-- to automatically modify stats, and displays upgrade info in 'per min' time units
local function upgrade_rec_speed_time(player_meta, p_data, stat, subskill_id, subskill_data, upgrade_quantity)
    local key = "recovery_speed_" .. stat
    local change_value = upgrade_quantity * subskill_data[6]/10
    local new_speed = p_data[key] + change_value
    p_data[key] = new_speed
    player_meta:set_float(key, new_speed)
    update_tooltips(p_data, subskill_id, subskill_data, {stat = stat})
end

-- updates the p_data.<stat>_rec_mod_<subskill_id> modifier and displays upgrade info in
-- percentage units
local function update_modifier_percent(p_data, key, subskill_id, subskill_data, upgrade_quantity)
    local change_value = upgrade_quantity * subskill_data[6]
    local new_speed = p_data[key] + change_value
    p_data[key] = new_speed
    update_tooltips(p_data, subskill_id, subskill_data)
end

-- modifies the p_data.<stat>_drain_speed property that relates to base stats and
-- displays upgrade info in percentage units
local function upgrade_drain_speed(player_meta, p_data, stat, subskill_id, subskill_data, upgrade_quantity)
    local drain_speed = BASE_STATS_DATA[stat].drain_speed
    local drain_increment = drain_speed * subskill_data[6]
    local key = "drain_speed_" .. stat
    local new_speed = p_data[key] - upgrade_quantity * drain_increment
    p_data[key] = new_speed
    player_meta:set_float(key, new_speed)
    update_tooltips(p_data, subskill_id, subskill_data)
end

-- updates the p_data.<stat>_rec_mod_<subskill_id> modifier and displays upgrade info in
-- percentage units
local function update_modifier_physics(player, p_data, key, subskill_id, subskill_data, upgrade_quantity)
    local physics_type = string_split(key, "_")[1]
    local change_value = upgrade_quantity * subskill_data[6]
    local new_physics_value = p_data[key] + change_value
    p_data[key] = new_physics_value
    update_player_physics(player, {[physics_type] = true})
    update_tooltips(p_data, subskill_id, subskill_data)
end

-- updates the p_data.<stat>_rec_mod_<subskill_id> modifier and displays upgrade info in
-- percentage units
local function update_modifier_temperature(p_data, subskill_id, subskill_data, upgrade_quantity)
    local change_value = upgrade_quantity * subskill_data[6]
    local key = "temperature_mod_" .. subskill_id
    p_data[key] = p_data[key] + change_value
    update_tooltips(p_data, subskill_id, subskill_data)
end



local flag4 = false
local function upgrade_subskill(player, player_meta, p_data, subskill_id, upgrade_quantity)
    debug(flag4, "  upgrade_subskill()")
    debug(flag4, "    subskill_id: " .. subskill_id)

    if false then

    -- STRENGTH --

    elseif subskill_id == "power_lifter" then
        debug(flag4, "    increasing max carrying weight")
        upgrade_stat_max(player, player_meta, p_data, "weight", subskill_id, PLAYER_SKILLS.strength[1], upgrade_quantity)
    elseif subskill_id == "cargo_tank" then
        debug(flag4, "    decrease weighted speed hinderance")
        local key = "speed_mod_cargo_tank"
        update_modifier_physics(player, p_data, key, subskill_id, PLAYER_SKILLS.strength[2], upgrade_quantity)
    elseif subskill_id == "bulk_bouncer" then
        debug(flag4, "    decrease weighted jump hinderance")
        local key = "jump_mod_bulk_bouncer"
        update_modifier_physics(player, p_data, key, subskill_id, PLAYER_SKILLS.strength[3], upgrade_quantity)
    elseif subskill_id == "forearm_freak" then
        debug(flag4, "    decreasing injuiry health impact")
        local key = "weight_mod_forearm_freak"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.strength[4], upgrade_quantity)

    -- TOUGHNESS --

    elseif subskill_id == "meat_shield" then
        debug(flag4, "    increasing max health")
        upgrade_stat_max(player, player_meta, p_data, "health", subskill_id, PLAYER_SKILLS.toughness[1], upgrade_quantity)
    elseif subskill_id == "rapid_recovery" then
        debug(flag4, "    increasing health recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "health", subskill_id, PLAYER_SKILLS.toughness[2], upgrade_quantity)
    elseif subskill_id == "thudmuffin" then
        debug(flag4, "    decreasing injuiry health impact")
        local key = "health_drain_mod_thudmuffin"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.toughness[3], upgrade_quantity)
    elseif subskill_id == "knuckle_saurus" then
        debug(flag4, "    decreasing hand drain")
        local key = "hand_drain_mod_knuckle_saurus"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.toughness[4], upgrade_quantity)
    elseif subskill_id == "digit_doctor" then
        debug(flag4, "    increasing hand recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "hands", subskill_id, PLAYER_SKILLS.toughness[5], upgrade_quantity)
    elseif subskill_id == "shin_credible" then
        debug(flag4, "    decreasing leg drain")
        local key = "leg_drain_mod_shin_credible"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.toughness[6], upgrade_quantity)
    elseif subskill_id == "knee_juvinator" then
        debug(flag4, "    increasing leg recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "legs", subskill_id, PLAYER_SKILLS.toughness[7], upgrade_quantity)
    elseif subskill_id == "comfy_cat" then
        debug(flag4, "    increasing max comfort")
        upgrade_stat_max(player, player_meta, p_data, "comfort", subskill_id, PLAYER_SKILLS.toughness[8], upgrade_quantity)
    elseif subskill_id == "comeback_koala" then
        debug(flag4, "    increasing comfort recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "comfort", subskill_id, PLAYER_SKILLS.toughness[9], upgrade_quantity)
    elseif subskill_id == "numb_skull" then
        debug(flag4, "    decrease comfort drain")
        upgrade_drain_speed( player_meta, p_data, "comfort", subskill_id, PLAYER_SKILLS.toughness[10], upgrade_quantity)

    -- AGILITY --

    elseif subskill_id == "speed_walker" then
        debug(flag4, "    increase walking speed")
        local key = "speed_mod_speed_walker"
        update_modifier_physics(player, p_data, key, subskill_id, PLAYER_SKILLS.agility[1], upgrade_quantity)

    elseif subskill_id == "sprinter" then
        debug(flag4, "    increase running speed")
        local key = "speed_mod_sprinter"
        update_modifier_physics(player, p_data, key, subskill_id, PLAYER_SKILLS.agility[2], upgrade_quantity)

    elseif subskill_id == "creeper" then
        debug(flag4, "    increase crouching speed")
        local key = "speed_mod_creeper"
        update_modifier_physics(player, p_data, key, subskill_id, PLAYER_SKILLS.agility[3], upgrade_quantity)

    elseif subskill_id == "launchitude" then
        debug(flag4, "    increase jump height")
        local key = "jump_mod_launchitude"
        update_modifier_physics(player, p_data, key, subskill_id, PLAYER_SKILLS.agility[4], upgrade_quantity)

    -- ENDURANCE --

    elseif subskill_id == "nonstop_nomad" then
        debug(flag4, "    increasing max stamina")
        upgrade_stat_max(player, player_meta, p_data, "stamina", subskill_id, PLAYER_SKILLS.endurance[1], upgrade_quantity)
    elseif subskill_id == "fast_charger" then
        debug(flag4, "    increasing stamina recovery speed")
        local key = "stamina_rec_mod_fast_charger"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.endurance[2], upgrade_quantity)
    elseif subskill_id == "burnout_blocker" then
        debug(flag4, "    decreasing stamina drain speed")
        local key = "stamina_drain_mod_burnout_blocker"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.endurance[3], upgrade_quantity)
    elseif subskill_id == "air_tank" then
        debug(flag4, "    increasing max breath")
        upgrade_stat_max(player, player_meta, p_data, "breath", subskill_id, PLAYER_SKILLS.endurance[4], upgrade_quantity)
    elseif subskill_id == "oxygenator" then
        debug(flag4, "    increasing breath recovery speed")
        local key = "breath_rec_mod_oxygenator"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.endurance[5], upgrade_quantity)
    elseif subskill_id == "deep_diver" then
        debug(flag4, "    decreasing breath drain speed")
        local key = "breath_drain_mod_deep_diver"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.endurance[6], upgrade_quantity)
    elseif subskill_id == "smotherproof" then
        debug(flag4, "    decreasing breath health drain")
        local key = "health_drain_mod_smotherproof"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.endurance[7], upgrade_quantity)
    elseif subskill_id == "night_owl" then
        debug(flag4, "    increasing max alertness")
        upgrade_stat_max(player, player_meta, p_data, "alertness", subskill_id, PLAYER_SKILLS.endurance[8], upgrade_quantity)
    elseif subskill_id == "insomniac" then
        debug(flag4, "    decreases alertness drain")
        upgrade_drain_speed(player_meta, p_data, "alertness", subskill_id, PLAYER_SKILLS.endurance[9], upgrade_quantity)

    -- IMMUNITY --

    elseif subskill_id == "bio_blocker" then
        debug(flag4, "    increasing max immunity")
        upgrade_stat_max(player, player_meta, p_data, "immunity", subskill_id, PLAYER_SKILLS.immunity[1], upgrade_quantity)
    elseif subskill_id == "tcell_tyrant" then
        debug(flag4, "    increasing immunity recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "immunity", subskill_id, PLAYER_SKILLS.immunity[2], upgrade_quantity)
    elseif subskill_id == "bcell_boss" then
        debug(flag4, "    decreases immunity drain")
        upgrade_drain_speed(player_meta, p_data, "immunity", subskill_id, PLAYER_SKILLS.immunity[3], upgrade_quantity)
    elseif subskill_id == "fever_flusher" then
        debug(flag4, "    increasing illness recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "illness", subskill_id, PLAYER_SKILLS.immunity[4], upgrade_quantity)
    elseif subskill_id == "sniffle_shield" then
        debug(flag4, "    decreasing illness drain")
        local key = "illness_drain_mod_sniffle_shield"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.immunity[5], upgrade_quantity)
    elseif subskill_id == "stage4_nope" then
        debug(flag4, "    decreasing illness health drain")
        local key = "health_drain_mod_stage4_nope"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.immunity[6], upgrade_quantity)
    elseif subskill_id == "barf_and_go" then
        debug(flag4, "    increasing poison recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "poison", subskill_id, PLAYER_SKILLS.immunity[7], upgrade_quantity)
    elseif subskill_id == "toxintanium" then
        debug(flag4, "    decreasing poison drain")
        local key = "poison_drain_mod_toxintanium"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.immunity[8], upgrade_quantity)
    elseif subskill_id == "dinner_death_dodger" then
        debug(flag4, "    decreasing poison health drain")
        local key = "health_drain_mod_dinner_death_dodger"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.immunity[9], upgrade_quantity)


    -- INTELLECT --

    elseif subskill_id == "fast_learner" then
        debug(flag4, "    increasing experience gain speed")
        local key = "experience_rec_mod_fast_learner"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.intellect[1], upgrade_quantity)
    elseif subskill_id == "zen_master" then
        debug(flag4, "    increasing max sanity")
        upgrade_stat_max(player, player_meta, p_data, "sanity", subskill_id, PLAYER_SKILLS.intellect[2], upgrade_quantity)
    elseif subskill_id == "brain_bouncer" then
        debug(flag4, "    increasing sanity recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "sanity", subskill_id, PLAYER_SKILLS.intellect[3], upgrade_quantity)
    elseif subskill_id == "psycho_shield" then
        debug(flag4, "    decreases sanity drain")
        upgrade_drain_speed(player_meta, p_data, "sanity", subskill_id, PLAYER_SKILLS.intellect[4], upgrade_quantity)
    elseif subskill_id == "happy_camper" then
        debug(flag4, "    increasing max happiness")
        upgrade_stat_max(player, player_meta, p_data, "happiness", subskill_id, PLAYER_SKILLS.intellect[5], upgrade_quantity)
    elseif subskill_id == "sad_squasher" then
        debug(flag4, "    increasing happiness recovery speed")
        upgrade_rec_speed_time(player_meta, p_data, "happiness", subskill_id, PLAYER_SKILLS.intellect[6], upgrade_quantity)
    elseif subskill_id == "cryproof" then
        debug(flag4, "    decreases happiness drain")
        upgrade_drain_speed(player_meta, p_data, "happiness", subskill_id, PLAYER_SKILLS.intellect[7], upgrade_quantity)

    -- DIGESTION --

    elseif subskill_id == "belly_bank" then
        debug(flag4, "    increasing max hunger")
        upgrade_stat_max(player, player_meta, p_data, "hunger", subskill_id, PLAYER_SKILLS.digestion[1], upgrade_quantity)
    elseif subskill_id == "slowbelly" then
        debug(flag4, "    decreases hunger drain")
        upgrade_drain_speed(player_meta, p_data, "hunger", subskill_id, PLAYER_SKILLS.digestion[2], upgrade_quantity)
    elseif subskill_id == "digestinator" then
        debug(flag4, "    increasing hunger gain amount")
        local key = "hunger_rec_mod_digestinator"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.digestion[3], upgrade_quantity)
    elseif subskill_id == "foodless_freak" then
        debug(flag4, "    decreases hunger health drain")
        local key = "health_drain_mod_foodless_freak"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.digestion[4], upgrade_quantity)
    elseif subskill_id == "water_camel" then
        debug(flag4, "    increasing max thirst")
        upgrade_stat_max(player, player_meta, p_data, "thirst", subskill_id, PLAYER_SKILLS.digestion[5], upgrade_quantity)
    elseif subskill_id == "h2_holder" then
        debug(flag4, "    decreases thirst drain")
        upgrade_drain_speed(player_meta, p_data, "thirst", subskill_id, PLAYER_SKILLS.digestion[6], upgrade_quantity)
    elseif subskill_id == "h2_oh_yeah" then
        debug(flag4, "    increasing thirst gain amount")
        local key = "thirst_rec_mod_h2_oh_yeah"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.digestion[7], upgrade_quantity)
    elseif subskill_id == "sipless_survivor" then
        debug(flag4, "    decreases thirst health drain")
        local key = "health_drain_mod_sipless_survivor"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.digestion[8], upgrade_quantity)
    elseif subskill_id == "unchokeable" then
        debug(flag4, "    decreases choking chance")
        local key = "noise_mod_unchokeable"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.digestion[9], upgrade_quantity)
    elseif subskill_id == "unhiccable" then
        debug(flag4, "    decreases hiccup chance")
        local key = "noise_mod_unhiccable"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.digestion[10], upgrade_quantity)

    -- SURVIVAL --

    elseif subskill_id == "coolossus" then
        debug(flag4, "    decreases cold health drain")
        update_modifier_temperature(p_data, subskill_id, PLAYER_SKILLS.survival[1], upgrade_quantity)
    elseif subskill_id == "freezeproof" then
        debug(flag4, "    decreases cold health drain")
        local key = "health_drain_mod_freezeproof"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.survival[2], upgrade_quantity)
    elseif subskill_id == "crispy_crusader" then
        debug(flag4, "    decreases hot weather impact")
        update_modifier_temperature(p_data, subskill_id, PLAYER_SKILLS.survival[3], upgrade_quantity)
    elseif subskill_id == "scorchproof" then
        debug(flag4, "    decreases hot health drain")
        local key = "health_drain_mod_scorchproof"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.survival[4], upgrade_quantity)
    elseif subskill_id == "stankproof" then
        debug(flag4, "    increasing max hygiene")
        upgrade_stat_max(player, player_meta, p_data, "hygiene", subskill_id, PLAYER_SKILLS.survival[5], upgrade_quantity)
    elseif subskill_id == "bo_buffer" then
        debug(flag4, "    decreases hygiene drain")
        upgrade_drain_speed(player_meta, p_data, "hygiene", subskill_id, PLAYER_SKILLS.survival[6], upgrade_quantity)
    elseif subskill_id == "booger_barrier" then
        debug(flag4, "    decreases chance of allergy sneezing")
        local key = "noise_mod_booger_barrier"
        update_modifier_percent(p_data, key, subskill_id, PLAYER_SKILLS.survival[7], upgrade_quantity)


    else
        debug(flag4, "    ERROR - Unexpected 'subskill_id' value: " .. subskill_id)
    end

    debug(flag4, "  upgrade_subskill() END")
end



local flag2 = false
local function get_fs_skills(p_data, player_name)
    debug(flag2, "  get_fs_skills()")

    local skill_selected = p_data.skill_selected
    local skill_category_elements = ""
    local y_offset = 0
    local x_offset = 0
    for i = 1, 8 do
        local skill = skill_names[i]
        local skill_value = 0
        local skill_value_max = 0
        for j, subskill_data in ipairs(PLAYER_SKILLS[skill]) do
            local subskill_id = subskill_data[1]
            local subskill_value = p_data["subskill_value_" .. subskill_id]
            skill_value = skill_value + subskill_value
            skill_value_max = skill_value_max + 10
        end
        local skill_value_ratio = round(skill_value / skill_value_max, 2)

        if skill_value_ratio < 0.10 then
            x_offset = 0.2
        elseif skill_value_ratio < 1 then
            x_offset = 0.1
        end

        -- give visual highlight on the button for this skill if it was pressed
        local selected_skill_styling = ""
        local icon_saturation = "-100"
        if skill == skill_selected then
            icon_saturation = "0"
            selected_skill_styling = table_concat({
                "style[skill_", skill, ";textcolor=", SKILL_COLORS[skill_selected], ";bgcolor=#000000]"
            })
        end

        local status_bar_width = 2.5 * skill_value_ratio
        -- show image, button, and elite progress bar for this skill
        skill_category_elements = table_concat({ skill_category_elements,
            "image[0.4,", 1.60 + y_offset, ";0.75,0.75;ss_skill_", skill, ".png^[hsl:0:", icon_saturation, ":0;]",
            selected_skill_styling,
            "button[1.35,", 1.58 + y_offset, ";2.4,0.8;skill_", skill, ";", skill, "]",
            "image[4.0,", 1.6 + y_offset, ";2.5,0.75;[fill:1x1:0,0:#111111;]",
            "image[4.0,", 1.6 + y_offset, ";", status_bar_width, ",0.75;[fill:1x1:0,0:#808000;]",
            "hypertext[", 4.85 + x_offset, ",", 1.8 + y_offset, ";1,1;skill_progress_", skill,
                ";<style color=#FFFFFF size=18><b>", skill_value_ratio * 100, "%</b></style>]",
            "tooltip[4.0,", 1.6 + y_offset, ";2.5,0.6;Elite ", skill, " progress]"
        })
        y_offset = y_offset + 1.1
    end

    local fs_part_1 = table_concat({
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.4]",
        "listcolors[",
            SLOT_COLOR_BG, ";",
            SLOT_COLOR_HOVER, ";",
            SLOT_COLOR_BORDER, ";",
            TOOLTIP_COLOR_BG, ";",
            TOOLTIP_COLOR_TEXT,
        "]",
        "tabheader[0,0;inv_tabs;Main,Equipment,Status,Skills,Bundle,Settings,?,*;4;true;true]",
        "box[7.0,0.0;15.2,10.5;#111111]",

        "hypertext[0.2,0.2;4,1.5;skills_title;",
        "<style color=#AAAAAA size=16><b>PLAYER SKILLS</b></style>]",

        "hypertext[0.4,0.9;3,1;player_level;",
        "<style color=#AAAAAA size=15><b>Level:  </b></style>",
        "<style color=#FFFFFF size=15><b>", p_data.player_level, "</b></style>]",

        "hypertext[2.0,0.9;3,1;player_skill_points;",
        "<style color=#AAAAAA size=15><b>Skill Points: </b></style>",
        "<style color=#FFFFFF size=15><b>", p_data.modified_skill_points, "</b></style>]",

        skill_category_elements
    })

    local fs_part_2
    if skill_selected == "" then
        debug(flag2, "    no existing skill selected")
        fs_part_2 = table_concat({
            "hypertext[12.5,4.5;10,2.0;no_topic;",
            "<style color=#666666 size=20><b><big>\u{21FD}</big> Select a skill to improve</b></style>]"
        })

    else
        debug(flag2, "    existing skill selected: " .. skill_selected)

        local x_offset_2 = 7.6
        local y_offset_2 = 0
        local subskill_elements = ""
        for i, subskill_data in pairs(PLAYER_SKILLS[skill_selected]) do
            local subskill_id = subskill_data[1]
            local subskill_name = subskill_data[2]
            local subskill_desc = subskill_data[3]
            local subskill_value = p_data["subskill_value_" .. subskill_id]
            local subskill_value_modified = unsaved_subskill_upgrades[player_name][subskill_id]
            if subskill_value_modified == nil then subskill_value_modified = subskill_value end
            debug(flag2, "    subskill_id: " .. subskill_id)
            debug(flag2, "    subskill_value: " .. subskill_value)
            debug(flag2, "    subskill_value_modified: " .. subskill_value_modified)

            local x_offset_3 = 0
            local progress_box_elements = ""
            for j = 1, 10 do
                local box_color
                if j > subskill_value_modified then
                    box_color = "#000000"
                elseif j > subskill_value then
                    box_color = "#AAAAAA"
                else
                    box_color = SKILL_COLORS[skill_selected]
                end
                progress_box_elements = table_concat({progress_box_elements,
                    "box[", x_offset_2 + x_offset_3, ",", 1.6 + y_offset_2, ";0.20,0.4;", box_color, "]",
                })
                x_offset_3 = x_offset_3 + 0.32
            end

            local dynamic_buttons_elements = ""
            if unsaved_subskill_upgrades[player_name][subskill_id] then
                dynamic_buttons_elements = table_concat({
                    "button[", x_offset_2 + 3.7, ",", 1.25 + y_offset_2, ";0.5,0.8;subskill_cancel_", subskill_id, ";x]",
                    "tooltip[", x_offset_2 + 3.7, ",", 1.25 + y_offset_2, ";0.5,0.8;undo]",
                    "button[", x_offset_2 + 4.1, ",", 1.25 + y_offset_2, ";0.5,0.8;subskill_save_", subskill_id, ";\u{2713}]",
                    "tooltip[", x_offset_2 + 4.1, ",", 1.25 + y_offset_2, ";0.5,0.8;apply upgrade]",
                })
            end

            local subskill_info_final = p_data["subskill_tooltip_1_" .. subskill_id] or "???"
            local upgrade_button_tooltip = p_data["subskill_tooltip_2_" .. subskill_id] or "???"

            subskill_elements = table_concat({subskill_elements,
                "tooltip[", x_offset_2 - 0.1, ",", 0.9 + y_offset_2, ";3.3,0.4;", subskill_desc, "]",
                "tooltip[", x_offset_2 - 0.2, ",", 1.5 + y_offset_2, ";3.3,0.4;", subskill_info_final, "]",
                "hypertext[", x_offset_2 - 0.1, ",", 1.1 + y_offset_2, ";8,1.5;subskill_title;",
                    "<style size=16 color=#FFFFFF><b>", subskill_name, "</b></style>]",
                "button[", x_offset_2 + 3.2, ",", 1.25 + y_offset_2, ";0.5,0.8;subskill_up_", subskill_id, ";+]",
                "tooltip[", x_offset_2 + 3.2, ",", 1.25 + y_offset_2, ";0.5,0.8;", upgrade_button_tooltip, "]",
                dynamic_buttons_elements,
                progress_box_elements
            })
            if i == 7 then
                x_offset_2 = 12.5
                y_offset_2 = -1.34
            elseif i == 14 then
                x_offset_2 = 17.4
                y_offset_2 = -1.34
            end
            y_offset_2 = y_offset_2 + 1.34

        end

        fs_part_2 = table_concat({
            "hypertext[7.2,0.2;4,1.5;skill_category;",
            "<style color=#AAAAAA size=16><b>Skill: <style color=#FFFFFF>", string.upper(skill_selected), "</style></b></style>]",
            subskill_elements
        })

    end

    local formspec = fs_part_1 .. fs_part_2

    debug(flag2, "  get_fs_skills() END")
    return formspec
end


local flag1 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() SKILLS.lua")
	debug(flag1, "  fields: " .. dump(fields))
    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
    debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag1, "  active_tab: " .. p_data.active_tab)

    if fields.inv_tabs == "4" then
        debug(flag1, "  clicked on 'SKILLS' tab!")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "skills"
        local formspec = get_fs_skills(p_data, player_name)
        mt_show_formspec(player_name, "ss:ui_skills", formspec)

    else
        debug(flag1, "  did not click on SKILLS tab")
        if p_data.formspec_mode ~= "main_formspec" then
            debug(flag1, "  interaction not from main formspec. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif p_data.active_tab ~= "skills" then
            debug(flag1, "  interaction from main formspec, but not SKILLS tab. NO FURTHER ACTION.")
            unsaved_subskill_upgrades[player_name] = {}
            p_data.modified_skill_points = p_data.player_skill_points
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "2"
            or fields.inv_tabs == "3"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6"
            or fields.inv_tabs == "7"
            or fields.inv_tabs == "8" then
            debug(flag1, "  clicked on a tab that was not SKILLS. NO FURTHER ACTION.")
            unsaved_subskill_upgrades[player_name] = {}
            p_data.modified_skill_points = p_data.player_skill_points
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return
        elseif fields.quit then
            debug(flag1, "  exited formspec. NO FURTHER ACTION.")
            p_data.active_tab = "main"
            unsaved_subskill_upgrades[player_name] = {}
            p_data.modified_skill_points = p_data.player_skill_points
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        else
            local field_data, field_data_tokens, category
            for key in pairs(fields) do field_data = key end

            debug(flag1, "  field_data: " .. field_data)
            field_data_tokens = string_split(field_data, "_")
            category = field_data_tokens[1]

            if category == "skill" then
                debug(flag1, "  prior skill selected: " .. p_data.skill_selected)
                local no_refresh = false

                if fields.skill_strength then
                    debug(flag1, "  clicked on main button for strength skill")
                    if p_data.skill_selected == "strength" then
                        debug(flag1, "  already displaying strength info. no further actions.")
                        no_refresh = true
                    else
                        unsaved_subskill_upgrades[player_name] = {}
                        p_data.modified_skill_points = p_data.player_skill_points
                        play_sound("button", {player_name = player_name})
                        p_data.skill_selected = "strength"
                        local player_meta = player:get_meta()
                        player_meta:set_string("skill_selected", "strength")
                    end

                elseif fields.skill_toughness then
                    if p_data.skill_selected == "toughness" then
                        debug(flag1, "  already displaying toughness info. no further actions.")
                        no_refresh = true
                    else
                        unsaved_subskill_upgrades[player_name] = {}
                        p_data.modified_skill_points = p_data.player_skill_points
                        play_sound("button", {player_name = player_name})
                        p_data.skill_selected = "toughness"
                        local player_meta = player:get_meta()
                        player_meta:set_string("skill_selected", "toughness")
                    end

                elseif fields.skill_agility then
                    if p_data.skill_selected == "agility" then
                        debug(flag1, "  already displaying agility info. no further actions.")
                        no_refresh = true
                    else
                        unsaved_subskill_upgrades[player_name] = {}
                        p_data.modified_skill_points = p_data.player_skill_points
                        play_sound("button", {player_name = player_name})
                        p_data.skill_selected = "agility"
                        local player_meta = player:get_meta()
                        player_meta:set_string("skill_selected", "agility")
                    end

                elseif fields.skill_endurance then
                    if p_data.skill_selected == "endurance" then
                        debug(flag1, "  already displaying endurance info. no further actions.")
                        no_refresh = true
                    else
                        unsaved_subskill_upgrades[player_name] = {}
                        p_data.modified_skill_points = p_data.player_skill_points
                        play_sound("button", {player_name = player_name})
                        p_data.skill_selected = "endurance"
                        local player_meta = player:get_meta()
                        player_meta:set_string("skill_selected", "endurance")
                    end

                elseif fields.skill_immunity then
                    if p_data.skill_selected == "immunity" then
                        debug(flag1, "  already displaying immunity info. no further actions.")
                        no_refresh = true
                    else
                        unsaved_subskill_upgrades[player_name] = {}
                        p_data.modified_skill_points = p_data.player_skill_points
                        play_sound("button", {player_name = player_name})
                        p_data.skill_selected = "immunity"
                        local player_meta = player:get_meta()
                        player_meta:set_string("skill_selected", "immunity")
                    end

                elseif fields.skill_intellect then
                    if p_data.skill_selected == "intellect" then
                        debug(flag1, "  already displaying intellect info. no further actions.")
                        no_refresh = true
                    else
                        unsaved_subskill_upgrades[player_name] = {}
                        p_data.modified_skill_points = p_data.player_skill_points
                        play_sound("button", {player_name = player_name})
                        p_data.skill_selected = "intellect"
                        local player_meta = player:get_meta()
                        player_meta:set_string("skill_selected", "intellect")
                    end

                elseif fields.skill_digestion then
                    if p_data.skill_selected == "digestion" then
                        debug(flag1, "  already displaying digestion info. no further actions.")
                        no_refresh = true
                    else
                        unsaved_subskill_upgrades[player_name] = {}
                        p_data.modified_skill_points = p_data.player_skill_points
                        play_sound("button", {player_name = player_name})
                        p_data.skill_selected = "digestion"
                        local player_meta = player:get_meta()
                        player_meta:set_string("skill_selected", "digestion")
                    end

                elseif fields.skill_survival then
                    if p_data.skill_selected == "survival" then
                        debug(flag1, "  already displaying survival info. no further actions.")
                        no_refresh = true
                    else
                        unsaved_subskill_upgrades[player_name] = {}
                        p_data.modified_skill_points = p_data.player_skill_points
                        play_sound("button", {player_name = player_name})
                        p_data.skill_selected = "survival"
                        local player_meta = player:get_meta()
                        player_meta:set_string("skill_selected", "survival")
                    end

                else
                    debug(flag1, "  ERROR - Unexpected 'fields' value: " .. dump(fields))
                end

                if no_refresh then
                    debug(flag1, "register_on_player_receive_fields() end "  .. mt_get_gametime())
                    return
                end

            else

                local action = field_data_tokens[2]
                if action == "up" then
                    debug(flag1, "  clicked to upgrade subskill")
                    debug(flag1, "    player_skill_points: " .. p_data.player_skill_points)
                    debug(flag1, "    modified_skill_points (before): " .. p_data.modified_skill_points)

                    if p_data.modified_skill_points > 0 then
                        local subskill_id = string_sub(field_data, 13)
                        local subskill_value = p_data["subskill_value_" .. subskill_id]
                        local subskill_value_new
                        local subskill_value_modified = unsaved_subskill_upgrades[player_name][subskill_id]
                        if subskill_value_modified then
                            subskill_value_new = subskill_value_modified + 1
                        else
                            subskill_value_new = subskill_value + 1
                        end

                        if subskill_value_new > 10 then
                            notify(player, "inventory", "cannot upgrade any further", 2, 0, 0, 3)
                        else
                            play_sound("button", {player_name = player_name})
                            debug(flag1, "    subskill_value_new: " .. subskill_value_new)
                            unsaved_subskill_upgrades[player_name][subskill_id] = subskill_value_new
                            p_data.modified_skill_points = p_data.modified_skill_points - 1
                        end
                    else
                        notify(player, "inventory", "no skill points remain", 2, 0, 0, 3)
                    end
                    debug(flag1, "    modified_skill_points (after): " .. p_data.modified_skill_points)

                elseif action == "cancel" then
                    debug(flag1, "  clicked to cancel subskill changes")
                    play_sound("button", {player_name = player_name})
                    local subskill_id = string_sub(field_data, 17)
                    local subskill_value = p_data["subskill_value_" .. subskill_id]
                    local subskill_value_modified = unsaved_subskill_upgrades[player_name][subskill_id]
                    local upgrade_quantity = subskill_value_modified - subskill_value
                    unsaved_subskill_upgrades[player_name][subskill_id] = nil
                    p_data.modified_skill_points = p_data.modified_skill_points + upgrade_quantity

                elseif action == "save" then
                    local player_meta = player:get_meta()
                    play_sound("button", {player_name = player_name})
                    local subskill_id = string_sub(field_data, 15)
                    debug(flag1, "  clicked to save subskill changes for " .. subskill_id)
                    local subskill_value = p_data["subskill_value_" .. subskill_id]
                    local subskill_value_modified = unsaved_subskill_upgrades[player_name][subskill_id]
                    local upgrade_quantity = subskill_value_modified - subskill_value
                    local new_skill_points = p_data.player_skill_points - upgrade_quantity
                    p_data.player_skill_points = new_skill_points
                    player_meta:set_int("player_skill_points", new_skill_points)
                    p_data["subskill_value_" .. subskill_id] = subskill_value_modified
                    player_meta:set_int("subskill_value_" .. subskill_id, subskill_value_modified)

                    upgrade_subskill(player, player_meta, p_data, subskill_id, upgrade_quantity)
                    unsaved_subskill_upgrades[player_name][subskill_id] = nil
                    notify(player, "inventory", SUBSKILL_NAMES[subskill_id] .. " upgraded!", 3, 0.5, 0, 2)
                else
                    debug(flag1, "  ERROR - Unexpected 'action' value: " .. action)
                end

            end

        end

        local formspec = get_fs_skills(p_data, player_name)
        mt_show_formspec(player_name, "ss:ui_help", formspec)

    end

    debug(flag1, "register_on_player_receive_fields() end "  .. mt_get_gametime())
end)



local flag3 = false
core.register_on_joinplayer(function(player)
	debug(flag3, "\nregister_on_joinplayer() SKILLS")
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local p_data = player_data[player_name]

    -- initialize the 'subskill value' whicht represents how many times the subskill
    -- has been upgraded (or how many skill points have been applied) ranging from
    -- 1 to 10. this value is shown visually by the number of colored vertical boxes
    -- below the subskill name.
    for _, skill_data in pairs(PLAYER_SKILLS) do
        for _, subskill_data in ipairs(skill_data) do
            local subskill_id = subskill_data[1]
            local key = "subskill_value_" .. subskill_id
            p_data[key] = player_meta:get_int(key) or 0
        end
    end

    -- initialize stat drain modifiers (specific to health stat) based on state of the subskill
    p_data.health_drain_mod_thudmuffin = 1 + (p_data.subskill_value_thudmuffin * PLAYER_SKILLS.toughness[3][6])
    p_data.health_drain_mod_foodless_freak = 1 + (p_data.subskill_value_foodless_freak * PLAYER_SKILLS.digestion[3][6])
    p_data.health_drain_mod_sipless_survivor = 1 + (p_data.subskill_value_sipless_survivor * PLAYER_SKILLS.digestion[6][6])
    p_data.health_drain_mod_stage4_nope = 1 + (p_data.subskill_value_stage4_nope * PLAYER_SKILLS.immunity[6][6])
    p_data.health_drain_mod_dinner_death_dodger = 1 + (p_data.subskill_value_dinner_death_dodger * PLAYER_SKILLS.immunity[9][6])
    p_data.health_drain_mod_smotherproof = 1 + (p_data.subskill_value_smotherproof * PLAYER_SKILLS.endurance[7][6])
    p_data.health_drain_mod_freezeproof = 1 + (p_data.subskill_value_freezeproof * PLAYER_SKILLS.survival[2][6])
    p_data.health_drain_mod_scorchproof = 1 + (p_data.subskill_value_scorchproof * PLAYER_SKILLS.survival[4][6])

    -- initialize stat drain modifiers based on state of the subskill
    p_data.hand_drain_mod_knuckle_saurus = 1 + (p_data.subskill_value_knuckle_saurus * PLAYER_SKILLS.toughness[4][6])
    p_data.leg_drain_mod_shin_credible = 1 + (p_data.subskill_value_shin_credible * PLAYER_SKILLS.toughness[6][6])
    p_data.stamina_drain_mod_burnout_blocker = 1 + (p_data.subskill_value_burnout_blocker * PLAYER_SKILLS.endurance[3][6])
    p_data.breath_drain_mod_deep_diver = 1 + (p_data.subskill_value_deep_diver * PLAYER_SKILLS.endurance[6][6])
    p_data.illness_drain_mod_sniffle_shield = 1 + (p_data.subskill_value_sniffle_shield * PLAYER_SKILLS.immunity[5][6])
    p_data.poison_drain_mod_toxintanium = 1 + (p_data.subskill_value_toxintanium * PLAYER_SKILLS.immunity[8][6])

    -- initialize stat recovery modifiers based on state of the subskill
    p_data.stamina_rec_mod_fast_charger = 1 + (p_data.subskill_value_fast_charger * PLAYER_SKILLS.endurance[2][6])
    p_data.breath_rec_mod_oxygenator = 1 + (p_data.subskill_value_oxygenator * PLAYER_SKILLS.endurance[5][6])
    p_data.experience_rec_mod_fast_learner = 1 + (p_data.subskill_value_fast_learner * PLAYER_SKILLS.intellect[1][6])
    p_data.hunger_rec_mod_digestinator = 1 + (p_data.subskill_value_digestinator * PLAYER_SKILLS.digestion[3][6])
    p_data.thirst_rec_mod_h2_oh_yeah = 1 + (p_data.subskill_value_h2_oh_yeah * PLAYER_SKILLS.digestion[7][6])

    p_data.weight_mod_forearm_freak = 1 + (p_data.subskill_value_forearm_freak * PLAYER_SKILLS.strength[4][6])

    p_data.speed_mod_speed_walker = 1 + (p_data.subskill_value_speed_walker * PLAYER_SKILLS.agility[1][6])
    p_data.speed_mod_sprinter = 1 + (p_data.subskill_value_sprinter * PLAYER_SKILLS.agility[2][6])
    p_data.speed_mod_creeper = 1 + (p_data.subskill_value_creeper * PLAYER_SKILLS.agility[3][6])
    p_data.jump_mod_launchitude = 1 + (p_data.subskill_value_launchitude * PLAYER_SKILLS.agility[4][6])

    p_data.speed_mod_cargo_tank = 1 + (p_data.subskill_value_cargo_tank * PLAYER_SKILLS.strength[2][6])
    p_data.jump_mod_bulk_bouncer = 1 + (p_data.subskill_value_bulk_bouncer * PLAYER_SKILLS.strength[3][6])

    p_data.temperature_mod_coolossus = p_data.subskill_value_coolossus * PLAYER_SKILLS.survival[1][6]
    p_data.temperature_mod_crispy_crusader = p_data.subskill_value_crispy_crusader * PLAYER_SKILLS.survival[3][6]

    p_data.noise_mod_unchokeable = 1 + p_data.subskill_value_unchokeable * PLAYER_SKILLS.digestion[9][6]
    p_data.noise_mod_booger_barrier = 1 + p_data.subskill_value_booger_barrier * PLAYER_SKILLS.survival[7][6]
    p_data.noise_mod_unhiccable = 1 + p_data.subskill_value_unhiccable * PLAYER_SKILLS.digestion[1][6]

    -- generatees the tooltips that pop up when hovering over the subskill value status
    -- boxes and the subskill upgrade '+' button
    initialize_subskill_tooltips(p_data)

    -- add player's name as a new index
    unsaved_subskill_upgrades[player_name] = {}

    -- initially holds the player's current skill points, but is updated when skill
    -- points are used on a subskill for upgrade, but not yet applied/saved. this
    -- allows the skill point total to revert back if the subskill upgrade is cancelled.
    p_data.modified_skill_points = p_data.player_skill_points

    -- the currently selected skill: strength, toughness, agility, endurance, etc.
    p_data.skill_selected = player_meta:get_string("skill_selected")


	debug(flag3, "register_on_joinplayer() end")
end)



local flag5 = false
core.register_on_respawnplayer(function(player)
    debug(flag5, "\nregister_on_respawnplayer() global_variables_init.lua")
	local player_meta = player:get_meta()
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

    -- ### not resetting the selected skill
    --p_data.skill_selected = ""

    -- reset p_data entry and matching player metadata for all player subskills
    for _, skill_data in pairs(PLAYER_SKILLS) do
        for _, subskill_data in ipairs(skill_data) do
            local subskill_id = subskill_data[1]
            local key = "subskill_value_" .. subskill_id
            p_data[key] = 0
            player_meta:set_int(key, 0)
        end
    end

    initialize_subskill_tooltips(p_data)

    debug(flag5, "register_on_respawnplayer() END")
end)