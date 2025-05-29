print("- loading global_vars_init.lua ")

-- cache global funcions for faster access
local math_floor = math.floor
local string_split = string.split
local string_sub = string.sub
local table_insert = table.insert
local table_concat = table.concat
local mt_wrap_text = core.wrap_text
local mt_get_modpath = core.get_modpath
local mt_register_craftitem = core.register_craftitem
local mt_register_tool = core.register_tool
local mt_register_node = core.register_node

-- cache global variables for faster access
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local ARMOR_COLORS = ss.ARMOR_COLORS
local ARMOR_CONTRASTS = ss.ARMOR_CONTRASTS
local POINTING_RANGE_DEFAULT = ss.POINTING_RANGE_DEFAULT
local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids
local job_handles = ss.job_handles
local is_cooldown_active = ss.is_cooldown_active

-- Helper function to print text to console for debugging and testing.
--- @param flag boolean whether to actually print the text to console
--- @param text string the text to be printed to the console
local function debug(flag, text)
	if flag then print(text) end
end


local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() global_variables_init.lua")
    local player_meta = player:get_meta()
    local player_status = player_meta:get_int("player_status")
    local player_name = player:get_player_name()

    -- initialize global tables indexed by player name
    player_hud_ids[player_name] = {}
    job_handles[player_name] = {}
    is_cooldown_active[player_name] = {}

    -- initialize ss.player_data and any matching metadata
    player_data[player_name] = {}
    local p_data = player_data[player_name]
    p_data.player_status = player_status

    -- which of the tabs within the main inventory window that is being viewed.
    -- the default is "main" whenever the inventory window is closed.
    p_data.active_tab = "main"

    -- the player's current animation, which is mainly controlled by player_anim.lua.
    -- possible animation states are defined by 'animms' of the lua file. player
    -- spawns in as crouching by default, then stands if nothing overhead.
    p_data.current_anim_state = "crouch"

    -- the base walk speed and jump height for the player
    p_data.speed_walk_current = 1
    p_data.jump_height_current = 1

    -- the various multipliers that can modify player's walk speed
    p_data.speed_buff_crouch = 1
    p_data.speed_buff_run = 1
    p_data.speed_buff_exhaustion = 1
    p_data.speed_buff_illness = 1
    p_data.speed_buff_poison = 1
    p_data.speed_buff_vomit = 1
    p_data.speed_buff_sneeze = 1
    p_data.speed_buff_cough = 1
    p_data.speed_buff_legs = 1

    -- the various multipliers that can modify player's jump height
    p_data.jump_buff_crouch = 1
    p_data.jump_buff_run = 1
    p_data.jump_buff_exhaustion = 1
    p_data.jump_buff_weight = 1
    p_data.jump_buff_illness = 1
    p_data.jump_buff_poison = 1
    p_data.jump_buff_vomit = 1
    p_data.jump_buff_sneeze = 1
    p_data.jump_buff_cough = 1
    p_data.jump_buff_legs = 1

    -- indicates if a player vocal sound effect (coughing, grunting, exhaling, etc)
    -- is currently playing due to a stat effect or other player action. this helps
    -- prevent other vocal sound effects from playing until the current one is done.
    p_data.player_vocalizing = false

    -- an integer that ranges from 0 to 100 that represents the how far submerged
    -- the player is in water
    p_data.water_level = player_meta:get_int("submersion_level") or 0


    if player_status == 0 then
        debug(flag1, "  new player")

        -- flags that indicate if popup text notifications related to the following
        -- categories are enabled or disabled
        p_data.notify_active_inventory = 1
        player_meta:set_int("notify_active_inventory", p_data.notify_active_inventory)
        p_data.notify_active_cooldowns = 1
        player_meta:set_int("notify_active_cooldowns", p_data.notify_active_cooldowns)
        p_data.notify_active_stat_effects = 1
        player_meta:set_int("notify_active_stat_effects", p_data.notify_active_stat_effects)
        p_data.notify_active_mobs = 1
        player_meta:set_int("notify_active_mobs", p_data.notify_active_mobs)
        p_data.notify_active_errors = 0
        player_meta:set_int("notify_active_errors", p_data.notify_active_errors)

        -- green and red highlight color options text, recipe icons, tooltips and wear,
        -- and orange highlight color options for campfire cooking progress, and 
        p_data.ui_green = "#008000"
        player_meta:set_string("ui_green", p_data.ui_green)
        p_data.ui_red = "#800000"
        player_meta:set_string("ui_red", p_data.ui_red)
        p_data.ui_orange = "#c63d00"
        player_meta:set_string("ui_orange", p_data.ui_orange)

        -- holds the formspec type last interacted with to help callback functions
        -- '*_on_receive_fields()' and '*_player_inventory_action()' take the correct
        -- action. Examples: main_formspec, storage, campfire, itemdrop_bag, etc.
        -- 'player_setup' is the intial value since the player setup formspec is
        -- the the first formspec to show when starting a new game or respawning.
        -- this data is not persistent between game restarts, since formspec_mode
        -- will then default to 'main_formspec'.
        p_data.formspec_mode = "player_setup"

        -- avatar mesh file
        p_data.avatar_mesh = "ss_player_model_1.b3d"
		player_meta:set_string("avatar_mesh", p_data.avatar_mesh)

		-- avatar BODY TYPE properties
		p_data.body_type = 1
		player_meta:set_int("body_type", p_data.body_type)

        -- these represent the buffs and their values that players get for wearing
        -- equipment like clothing and armor. these values can directly impact player
        -- stats or player status effects during gameplay.
        p_data.equip_buff_damage = 0
        player_meta:set_float("equip_buff_damage", p_data.equip_buff_damage)
        p_data.equip_buff_cold = 0
        player_meta:set_float("equip_buff_cold", p_data.equip_buff_cold)
        p_data.equip_buff_heat = 0
        player_meta:set_float("equip_buff_heat", p_data.equip_buff_heat)
        p_data.equip_buff_sun = 0
        player_meta:set_float("equip_buff_sun", p_data.equip_buff_sun)
        p_data.equip_buff_water = 0
        player_meta:set_float("equip_buff_water", p_data.equip_buff_water)
        p_data.equip_buff_wetness = 0
        player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
        p_data.equip_buff_disease = 0
        player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
        p_data.equip_buff_electrical = 0
        player_meta:set_float("equip_buff_electrical", p_data.equip_buff_electrical)
        p_data.equip_buff_radiation = 0
        player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
        p_data.equip_buff_gas = 0
        player_meta:set_float("equip_buff_gas", p_data.equip_buff_gas)
        p_data.equip_buff_noise = 0
        player_meta:set_float("equip_buff_noise", p_data.equip_buff_noise)
        p_data.equip_buff_weight = 0
        player_meta:set_float("equip_buff_weight", p_data.equip_buff_weight)

        -- used by ss.get_fs_equipment_buffs() to determine visual coloring of the
        -- equipment buff icons and the red/green coloring of the buff values. not
        -- persistent between game restarts, so no need for corresponding metadata.
        p_data.equip_buff_damage_prev = 0
        p_data.equip_buff_cold_prev = 0
        p_data.equip_buff_heat_prev = 0
        p_data.equip_buff_sun_prev = 0
        p_data.equip_buff_water_prev = 0
        p_data.equip_buff_wetness_prev = 0
        p_data.equip_buff_disease_prev = 0
        p_data.equip_buff_electrical_prev = 0
        p_data.equip_buff_radiation_prev = 0
        p_data.equip_buff_gas_prev = 0
        p_data.equip_buff_noise_prev = 0
        p_data.equip_buff_weight_prev = 0

		-- ** pending implementation (not currently used) **
        -- items usable as weapons have a cooldown time defined in attack_cooldown.txt.
        -- each item also belongs to a weapon group defined in attack_groups.txt. the
        -- below buffs add (if pos) or subtract (if neg) to the base cooldown times.
        -- these buff values can change with player skill progression, injuries, etc.
        p_data.cooldown_buff_fists = 0.1
		player_meta:set_float("cooldown_buff_fists", p_data.cooldown_buff_fists)
        p_data.cooldown_buff_blunt = 0.1
		player_meta:set_float("cooldown_buff_blunt", p_data.cooldown_buff_blunt)
        p_data.cooldown_buff_blade = 0.1
		player_meta:set_float("cooldown_buff_blade",p_data.cooldown_buff_blade)
        p_data.cooldown_buff_spear = 0.1
		player_meta:set_float("cooldown_buff_spear", p_data.cooldown_buff_spear)
        p_data.cooldown_buff_mining = 0.1
		player_meta:set_float("cooldown_buff_mining", p_data.cooldown_buff_mining)

        -- default movement speed and jump height
        p_data.speed_walk = 1.0
        player_meta:set_float("speed_walk", p_data.speed_walk)
		p_data.height_jump = 1.0
        player_meta:set_float("height_jump", p_data.height_jump)

        -- amount of decrease in speed and jump height based on various levels of
        -- inventory weight encumbrance. this value changes dynamically during gameplay
		-- based on changes to the inventory weight. 
		-- speed_buff_weight standard range: 0 to 0.8
        -- jump_buff_weight standard range: 0 to 0.1
        p_data.speed_buff_weight = 1
		player_meta:set_float("speed_buff_weight", p_data.speed_buff_weight)
        p_data.jump_buff_weight = 1
		player_meta:set_float("jump_buff_weight", p_data.jump_buff_weight)

    else
        debug(flag1, "  existing player (or joined game while dead)")

        -- enable/disable popup text notifications
        p_data.notify_active_inventory = player_meta:get_int("notify_active_inventory")
        p_data.notify_active_cooldowns = player_meta:get_int("notify_active_cooldowns")
        p_data.notify_active_stat_effects = player_meta:get_int("notify_active_stat_effects")
        p_data.notify_active_mobs = player_meta:get_int("notify_active_mobs")
        p_data.notify_active_errors = player_meta:get_int("notify_active_errors")

        -- green, orange and red highlight color for text, recipe icons, icon bg status, tooltips and wear
        p_data.ui_green = player_meta:get_string("ui_green")
        p_data.ui_orange = player_meta:get_string("ui_orange")
        p_data.ui_red = player_meta:get_string("ui_red")

        p_data.formspec_mode = "main_formspec" -- defaults to 'main_formspec' upon rejoining

        -- avatar mesh file
        p_data.avatar_mesh = player_meta:get_string("avatar_mesh")

		-- avatar BODY TYPE properties
		p_data.body_type = player_meta:get_int("body_type")

        p_data.equip_buff_damage = player_meta:get_float("equip_buff_damage")
        p_data.equip_buff_cold = player_meta:get_float("equip_buff_cold")
        p_data.equip_buff_heat = player_meta:get_float("equip_buff_heat")
        p_data.equip_buff_sun = player_meta:get_float("equip_buff_sun")
        p_data.equip_buff_water = player_meta:get_float("equip_buff_water")
        p_data.equip_buff_wetness = player_meta:get_float("equip_buff_wetness")
        p_data.equip_buff_disease = player_meta:get_float("equip_buff_disease")
        p_data.equip_buff_electrical = player_meta:get_float("equip_buff_electrical")
        p_data.equip_buff_radiation = player_meta:get_float("equip_buff_radiation")
        p_data.equip_buff_gas = player_meta:get_float("equip_buff_gas")
        p_data.equip_buff_noise = player_meta:get_float("equip_buff_noise")
        p_data.equip_buff_weight = player_meta:get_float("equip_buff_weight")
        p_data.equip_buff_damage_prev = p_data.equip_buff_damage
        p_data.equip_buff_cold_prev = p_data.equip_buff_cold
        p_data.equip_buff_heat_prev = p_data.equip_buff_heat
        p_data.equip_buff_sun_prev = p_data.equip_buff_sun
        p_data.equip_buff_water_prev = p_data.equip_buff_water
        p_data.equip_buff_wetness_prev = p_data.equip_buff_wetness
        p_data.equip_buff_disease_prev = p_data.equip_buff_disease
        p_data.equip_buff_electrical_prev = p_data.equip_buff_electrical
        p_data.equip_buff_radiation_prev = p_data.equip_buff_radiation
        p_data.equip_buff_gas_prev = p_data.equip_buff_gas
        p_data.equip_buff_noise_prev = p_data.equip_buff_noise
        p_data.equip_buff_weight_prev = p_data.equip_buff_weight

        -- player stats
        p_data.cooldown_buff_fists = player_meta:get_float("cooldown_buff_fists")
        p_data.cooldown_buff_blunt = player_meta:get_float("cooldown_buff_blunt")
        p_data.cooldown_buff_blade = player_meta:get_float("cooldown_buff_blade")
        p_data.cooldown_buff_spear = player_meta:get_float("cooldown_buff_spear")
        p_data.cooldown_buff_mining = player_meta:get_float("cooldown_buff_mining")
        p_data.speed_walk = player_meta:get_float("speed_walk")
        p_data.height_jump = player_meta:get_float("height_jump")
        p_data.speed_buff_weight = player_meta:get_float("speed_buff_weight")
        p_data.jump_buff_weight = player_meta:get_float("jump_buff_weight")

    end

    debug(flag1, "register_on_joinplayer() END")
end)


local flag3 = false
core.register_on_dieplayer(function(player)
    debug(flag3, "\nregister_on_dieplayer() GLOBAL VARS INIT")
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    local player_meta = player:get_meta()

    -- reset the values shown in the equip buffs box
	p_data.equip_buff_damage = 0
    player_meta:set_float("equip_buff_damage", p_data.equip_buff_damage)
    p_data.equip_buff_cold = 0
    player_meta:set_float("equip_buff_cold", p_data.equip_buff_cold)
    p_data.equip_buff_heat = 0
    player_meta:set_float("equip_buff_heat", p_data.equip_buff_heat)
    p_data.equip_buff_sun = 0
    player_meta:set_float("equip_buff_sun", p_data.equip_buff_sun)
    p_data.equip_buff_water = 0
    player_meta:set_float("equip_buff_water", p_data.equip_buff_water)
    p_data.equip_buff_wetness = 0
    player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
    p_data.equip_buff_disease = 0
    player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
    p_data.equip_buff_electrical = 0
    player_meta:set_float("equip_buff_electrical", p_data.equip_buff_electrical)
    p_data.equip_buff_radiation = 0
    player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
    p_data.equip_buff_gas = 0
    player_meta:set_float("equip_buff_gas", p_data.equip_buff_gas)
    p_data.equip_buff_noise = 0
    player_meta:set_float("equip_buff_noise", p_data.equip_buff_noise)
    p_data.equip_buff_weight = 0
    player_meta:set_float("equip_buff_weight", p_data.equip_buff_weight)

	-- these helper values are not persistent between game restarts,
	-- so no need for corresponding player metadata.
    debug(flag3, "  resetting all equipbuff values to zero")
	p_data.equip_buff_damage_prev = 0
	p_data.equip_buff_cold_prev = 0
	p_data.equip_buff_heat_prev = 0
    p_data.equip_buff_sun_prev = 0
    p_data.equip_buff_water_prev = 0
	p_data.equip_buff_wetness_prev = 0
	p_data.equip_buff_disease_prev = 0
	p_data.equip_buff_electrical_prev = 0
    p_data.equip_buff_radiation_prev = 0
    p_data.equip_buff_gas_prev = 0
	p_data.equip_buff_noise_prev = 0
	p_data.equip_buff_weight_prev = 0

    debug(flag3, "register_on_dieplayer() END")
end)


-- Note: the respawnplayer() code mostly mirrors the joinplayer() code
-- except for the parts relating to if plyer_status == 1. code relating to if
-- player_status == 2 is also incorporated where it does not already overlap with
-- player_status == 0
local flag5 = false
core.register_on_respawnplayer(function(player)
    debug(flag5, "\nregister_on_respawnplayer() global_variables_init.lua")
	local player_meta = player:get_meta()
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

    debug(flag5, "  reset movement and jump physics")
    p_data.speed_walk_current = 1
    p_data.jump_height_current = 1

    debug(flag5, "  reset speed buffs")
    p_data.speed_buff_crouch = 1
    p_data.speed_buff_run = 1
    p_data.speed_buff_exhaustion = 1
    p_data.speed_buff_illness = 1
    p_data.speed_buff_poison = 1
    p_data.speed_buff_vomit = 1
    p_data.speed_buff_sneeze = 1
    p_data.speed_buff_cough = 1
    p_data.speed_buff_legs = 1

    debug(flag5, "  reset jump buffs")
    p_data.jump_buff_crouch = 1
    p_data.jump_buff_run = 1
    p_data.jump_buff_exhaustion = 1
    p_data.jump_buff_weight = 1
    p_data.jump_buff_illness = 1
    p_data.jump_buff_poison = 1
    p_data.jump_buff_vomit = 1
    p_data.jump_buff_sneeze = 1
    p_data.jump_buff_cough = 1
    p_data.jump_buff_legs = 1

    debug(flag5, "  reset active tab and anim state")
    p_data.active_tab = "main"
    p_data.current_anim_state = "crouch"

    debug(flag5, "  reset player vocalizing flag")
    p_data.player_vocalizing = false

    debug(flag5, "  reset player inventory properties")
    p_data.formspec_mode = "player_setup" -- player starts new character
    p_data.prev_iteminfo_item = ""
    player_meta:set_string("prev_iteminfo_item", p_data.prev_iteminfo_item)
    p_data.recipe_category = "tools"
    player_meta:set_string("recipe_category", p_data.recipe_category)
    p_data.prev_recipe_id = ""
    player_meta:set_string("prev_recipe_id", p_data.prev_recipe_id)
    p_data.slot_bonus_credit = 0
    player_meta:set_int("slot_bonus_credit", p_data.slot_bonus_credit)

    -- ### not restting player avatar mesh and body type preferences
    -- p_data.avatar_mesh = "ss_player_model_1.b3d"
    -- p_data.body_type = 1

    debug(flag5, "  reset cooldown durations")
    p_data.fists_attack_damage = 1.5
	player_meta:set_float("fists_attack_damage", 1.5)
    p_data.cooldown_buff_fists = 0.1
	player_meta:set_float("cooldown_buff_fists", 0.1)
    p_data.cooldown_buff_blunt = 0.1
	player_meta:set_float("cooldown_buff_blunt", 0.1)
    p_data.cooldown_buff_blade = 0.1
	player_meta:set_float("cooldown_buff_blade", 0.1)
    p_data.cooldown_buff_spear = 0.1
	player_meta:set_float("cooldown_buff_spear", 0.1)
    p_data.cooldown_buff_mining = 0.1
	player_meta:set_float("cooldown_buff_mining", 0.1)

    debug(flag5, "  reset 'current' movement and jump physics")
    p_data.speed_walk = 1.0
	player_meta:set_float("speed_walk", 1.0)
    p_data.height_jump = 1.0
	player_meta:set_float("height_jump", 1.0)

    debug(flag5, "  reset weight buffs on movement and jumping")
    p_data.speed_buff_weight = 1
	player_meta:set_float("speed_buff_weight", 1)
    p_data.jump_buff_weight = 1
	player_meta:set_float("jump_buff_weight", 1)

    -- ### not resetting UI highlight color preferences

    debug(flag5, "  reset job_handles and is_cooldown_active global tables")
    job_handles[player_name] = {}
    is_cooldown_active[player_name] = {}

	debug(flag5, "register_on_respawnplayer() END")
end)



-- #### initializing tables: ITEM_DISPLAY_NAME, ITEM_DESCRIPTOR, ITEM_TOOLTIP,
-- ITEM_CATEGORY, ITEM_DESC_SHORT, ITEM_DESC_LONG

local flag2 = false
debug(flag2, "importing data from item_data.txt ..")
local file_path = mt_get_modpath("ss") .. "/item_data.txt"
local file = io.open(file_path, "r")
if not file then
	debug(flag2, "  Could not open file: " .. file_path)
	return
end

local dataline_1_read = false
local dataline_2_read = false
local dataline_3_read = false
local dataline_4_read = false
local dataline_5_read = false
local item_name, texture_inv
local display_name, descriptor, type, category, group
local inv_sound, miss_sound, hit_sound, consume_sound, break_sound
local weight, fuel_burn_time, cook_time, value, hit_damage, hit_cooldown_time, hit_type, pointing_range
local item_tooltip
local description_short

for line in file:lines() do
    debug(flag2, "  line: " .. line)
	-- Trim whitespace from the line
	line = line:match("^%s*(.-)%s*$")
	-- Skip blank lines and lines that start with '#'
    if line == "" then
        debug(flag2, "    blank line")
        dataline_1_read = false
        dataline_2_read = false
        dataline_3_read = false
        dataline_4_read = false
        dataline_5_read = false
    elseif line:sub(1, 1) == "#" then
        debug(flag2, "    comment line")
        dataline_1_read = false
        dataline_2_read = false
        dataline_3_read = false
        dataline_4_read = false
        dataline_5_read = false
    else
        debug(flag2, "    valid data line")
        if dataline_1_read then
            if dataline_2_read then
                if dataline_3_read then
                    if dataline_4_read then
                        if dataline_5_read then
                            debug(flag2, "    found data line 6")

                            display_name = display_name or "(no display name)"
                            ss.ITEM_DISPLAY_NAME[item_name] = display_name

                            if descriptor == "" then
                                item_tooltip = display_name
                            else
                                ss.ITEM_DESCRIPTOR[item_name] = descriptor
                                item_tooltip = display_name .. " (" .. descriptor .. ")"
                            end
                            ss.ITEM_TOOLTIP[item_name] = item_tooltip

                            ss.ITEM_CATEGORY[item_name] = category

                            if group ~= "" then
                                debug(flag2, "    group: " .. group)
                                if ss.GROUP_ITEMS[group] == nil then
                                    ss.GROUP_ITEMS[group] = {}
                                end
                                table_insert(ss.GROUP_ITEMS[group], item_name)
                                ss.ITEM_GROUPS[item_name] = group
                            end

                            if inv_sound ~= "" then
                                ss.ITEM_SOUNDS_INV[item_name] = inv_sound
                            end

                            if miss_sound ~= "" then
                                ss.ITEM_SOUNDS_MISS[item_name] = miss_sound
                            end

                            if hit_sound ~= "" then
                                ss.ITEM_SOUNDS_HIT[item_name] = inv_sound
                            end
                            if consume_sound ~= "" then
                                ss.ITEM_SOUNDS_USE[item_name] = consume_sound
                            end
                            if break_sound ~= "" then
                                ss.ITEM_SOUNDS_BREAK[item_name] = break_sound
                            end

                            local final_weight = tonumber(weight)
                            ss.ITEM_WEIGHTS[item_name] = final_weight

                            local max_count = math_floor(ss.SLOT_WEIGHT_MAX / final_weight)
                            if max_count > 99 then max_count = 99 end
                            ss.STACK_MAX_COUNTS[item_name] = max_count

                            ss.ITEM_BURN_TIMES[item_name] = tonumber(fuel_burn_time)

                            cook_time = tonumber(cook_time)
                            if cook_time > 0 then
                                ss.ITEM_HEAT_RATES[item_name] = math_floor(ss.COOK_THRESHOLD / cook_time)
                            else
                                ss.ITEM_HEAT_RATES[item_name] = 0
                            end
                            ss.ITEM_VALUES[item_name] = tonumber(value)
                            ss.ITEM_HIT_DAMAGES[item_name] = tonumber(hit_damage)
                            ss.ITEM_HIT_COOLDOWNS[item_name] = tonumber(hit_cooldown_time)
                            ss.ITEM_HIT_TYPES[item_name] = hit_type

                            if pointing_range == "" then
                                ss.ITEM_POINTING_RANGES[item_name] = POINTING_RANGE_DEFAULT
                                pointing_range = POINTING_RANGE_DEFAULT
                            else
                                ss.ITEM_POINTING_RANGES[item_name] = tonumber(pointing_range)
                                pointing_range = tonumber(pointing_range)
                            end

                            ss.ITEM_DESC_SHORT[item_name] = description_short
                            ss.ITEM_DESC_LONG[item_name] = mt_wrap_text(line, 70)

                            local name_tokens = string_split(item_name, ":", true)
                            local type_tokens = string_split(type, ":")

                            if name_tokens[1] == "default" then
                                debug(flag2, "    this is a 'default' mod item. no need to register it.")
                            elseif name_tokens[1] == "stairs" then
                                debug(flag2, "    this is a 'stairs' mod item. no need to register it.")
                            elseif name_tokens[1] == "flowers" then
                                debug(flag2, "    this is a 'flowers' mod item. no need to register it.")
                            elseif name_tokens[1] == "farming" then
                                debug(flag2, "    this is a 'farming' mod item. no need to register it.")

                            elseif type_tokens[1] == "clothes" then
                                debug(flag2, "    this is clothing that can be colored")
                                local clothing_name = string_sub(item_name, 12)
                                debug(flag2, "    clothing_name: " .. clothing_name)
                                texture_inv = table_concat({
                                    "ss_clothes_", clothing_name, ".png",
                                    "^[colorizehsl:", CLOTHING_COLORS[clothing_name][1],
                                    "^[contrast:", CLOTHING_CONTRASTS[clothing_name][1],
                                    "^[mask:ss_clothes_", clothing_name, "_mask.png"
                                })
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            elseif type_tokens[1] == "armor" then
                                debug(flag2, "    this is armor that can be colored")
                                local armor_name = string_sub(item_name, 10)
                                debug(flag2, "    armor_name: " .. armor_name)
                                texture_inv = table_concat({
                                    "ss_armor_", armor_name, ".png",
                                    "^[colorizehsl:", ARMOR_COLORS[armor_name][1],
                                    "^[contrast:", ARMOR_CONTRASTS[armor_name][1],
                                    "^[mask:ss_armor_", armor_name, "_mask.png"
                                })
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            elseif type_tokens[1] == "craftitem" then
                                debug(flag2, "    this is a craftitem")
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv .. ".png",
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            -- only applies to 'ss:' tools
                            elseif type_tokens[1] == "tool" then
                                debug(flag2, "    this is a tool")
                                mt_register_tool(item_name, {
                                        description = item_tooltip,
                                        inventory_image = texture_inv .. ".png",
                                        range = pointing_range,
                                        sound = {
                                            punch_use_air = miss_sound
                                        }
                                    })

                            -- only applies to 'ss:' nodes
                            elseif type_tokens[1] == "node" then
                                debug(flag2, "    this is a node")

                                local node_type = type_tokens[2]
                                debug(flag2, "    node_type: " .. node_type)

                                local walkable
                                local buildable_to

                                if node_type == "solid" then
                                    walkable = true
                                    buildable_to = false
                                elseif node_type == "solid_variable" then
                                    walkable = true
                                    buildable_to = true
                                elseif node_type == "nonsolid_dig" then
                                    walkable = false
                                    buildable_to = true
                                elseif node_type == "nonsolid_nodig" then
                                    walkable = false
                                    buildable_to = false
                                elseif node_type == "gappy_dig" then
                                    walkable = true
                                    buildable_to = true
                                elseif node_type == "gappy_nodig" then
                                    walkable = true
                                    buildable_to = false
                                else
                                    debug(flag2, "    ERROR - Unexpected 'node_type' value: " .. node_type)
                                end

                                local node_def = {
                                    description = item_tooltip,
                                    inventory_image = texture_inv .. ".png",
                                    walkable = walkable,
                                    buildable_to = buildable_to,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                }
                                mt_register_node(item_name, node_def)
                                debug(flag2, "    node_def: " .. dump(node_def))

                            else
                                debug(flag2, "    ERROR - Unexpected 'type' value: " .. type)
                            end

                            dataline_1_read = false
                            dataline_2_read = false
                            dataline_3_read = false
                            dataline_4_read = false
                            dataline_5_read = false
                        else
                            debug(flag2, "    found data line 5")
                            description_short = line
                            dataline_5_read = true
                        end
                    else
                        debug(flag2, "    found data line 4")
                        local tokens = string_split(line, ",", true)
                        debug(flag2, "    dataline_tokens: " .. dump(tokens))
                        weight = tokens[1]
                        fuel_burn_time = tokens[2]
                        cook_time = tokens[3]
                        value = tokens[4]
                        hit_damage = tokens[5]
                        hit_cooldown_time = tokens[6]
                        hit_type = tokens[7]
                        pointing_range = tokens[8]
                        dataline_4_read = true
                    end
                else
                    debug(flag2, "    found data line 3")
                    local tokens = string_split(line, ",", true)
                    debug(flag2, "    dataline_tokens: " .. dump(tokens))
                    inv_sound = tokens[1]
                    miss_sound = tokens[2]
                    hit_sound = tokens[3]
                    consume_sound = tokens[4]
                    break_sound = tokens[5]
                    dataline_3_read = true
                end
            else
                debug(flag2, "    found data line 2")
                local tokens = string_split(line, ",", true)
                debug(flag2, "    dataline_tokens: " .. dump(tokens))
                display_name = tokens[1]
                descriptor = tokens[2]
                type = tokens[3]
                category = tokens[4]
                group = tokens[5]
                dataline_2_read = true
            end
        else
            debug(flag2, "      found data line 1")
            local tokens = string_split(line, ",", true)
            debug(flag2, "    tokens: " .. dump(tokens))
            item_name = tokens[1]
            texture_inv = tokens[2]
            dataline_1_read = true
        end
    end
end
file:close()
local flag2b = true
--debug(flag2b, "  ITEM_DISPLAY_NAME[]: " .. dump(ss.ITEM_DISPLAY_NAME))
--debug(flag2b, "  ITEM_DESCRIPTOR[]: " .. dump(ss.ITEM_DESCRIPTOR))
--debug(flag2b, "  ITEM_TOOLTIP[]: " .. dump(ss.ITEM_TOOLTIP))
--debug(flag2b, "  ITEM_CATEGORY[]: " .. dump(ss.ITEM_CATEGORY))
--debug(flag2b, "  ITEM_GROUPS: " .. dump(ss.ITEM_GROUPS))
--debug(flag2b, "  GROUP_ITEMS: " .. dump(ss.GROUP_ITEMS))
--debug(flag2b, "  ITEM_SOUNDS_INV[]: " .. dump(ss.ITEM_SOUNDS_INV))
--debug(flag2b, "  ITEM_SOUNDS_MISS[]: " .. dump(ss.ITEM_SOUNDS_MISS))
--debug(flag2b, "  ITEM_SOUNDS_HIT[]: " .. dump(ss.ITEM_SOUNDS_HIT))
--debug(flag2b, "  ITEM_SOUNDS_USE[]: " .. dump(ss.ITEM_SOUNDS_USE))
--debug(flag2b, "  ITEM_SOUNDS_BREAK[]: " .. dump(ss.ITEM_SOUNDS_BREAK))
--debug(flag2b, "  ITEM_WEIGHTS[]: " .. dump(ss.ITEM_WEIGHTS))
--debug(flag2b, "  STACK_MAX_COUNTS: " .. dump(ss.STACK_MAX_COUNTS))
--debug(flag2b, "  ITEM_BURN_TIMES[]: " .. dump(ss.ITEM_BURN_TIMES))
--debug(flag2b, "  ITEM_HEAT_RATES[]: " .. dump(ss.ITEM_HEAT_RATES))
--debug(flag2b, "  ITEM_VALUES[]: " .. dump(ss.ITEM_VALUES))
--debug(flag2b, "  ITEM_HIT_DAMAGES[]: " .. dump(ss.ITEM_HIT_DAMAGES))
--debug(flag2b, "  ITEM_HIT_COOLDOWNS[]: " .. dump(ss.ITEM_HIT_COOLDOWNS))
--debug(flag2b, "  ITEM_HIT_TYPES[]: " .. dump(ss.ITEM_HIT_TYPES))
--debug(flag2b, "  ITEM_POINTING_RANGES[]: " .. dump(ss.ITEM_POINTING_RANGES))
--debug(flag2b, "  ITEM_DESC_SHORT[]: " .. dump(ss.ITEM_DESC_SHORT))
--debug(flag2b, "  ITEM_DESC_LONG[]: " .. dump(ss.ITEM_DESC_LONG))



-- #### initialize ss.NODE_DROPS_FLATTENED

local flag4 = false
debug(flag4, "populating FLATTENED_NODE_DROPS table..")
file_path = mt_get_modpath("ss") .. "/node_drops_flattened.txt"
file = io.open(file_path, "r")
if not file then
	debug(flag4, "  Could not open file: " .. file_path)
	return
end
for line in file:lines() do
	-- Trim whitespace from the line
	line = line:match("^%s*(.-)%s*$")
	-- Skip blank lines and lines that start with '#'
	if line ~= "" and line:sub(1, 1) ~= "#" then
		local line_tokens = string_split(line)
		local item_name_ = line_tokens[1]
		debug(flag4, "  item_name_: " .. item_name_)
		local item_drop
		if line_tokens[2] then
			item_drop = ItemStack(line_tokens[2])
		else
			item_drop = ItemStack("")
		end
		ss.NODE_DROPS_FLATTENED[item_name_] = ItemStack(item_drop)
	end
end
file:close()
debug(flag4, "  NODE_DROPS_FLATTENED[]: " .. dump(ss.NODE_DROPS_FLATTENED))