print("- loading stats.lua")

-- cache global functions for faster access
local math_random = math.random
local table_copy = table.copy
local mt_serialize = minetest.serialize
local mt_after = minetest.after
local mt_get_node = minetest.get_node
local debug = ss.debug
local round = ss.round
local set_stat = ss.set_stat
local set_stat_value = ss.set_stat_value
local set_experience = ss.set_experience
local set_stamina = ss.set_stamina
local get_buff_id = ss.get_buff_id
local start_buff_loop = ss.start_buff_loop

-- cache global variables for faster access
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local DEFAULT_STAT_MAX = ss.DEFAULT_STAT_MAX
local DEFAULT_STAT_START = ss.DEFAULT_STAT_START
local STATBAR_HEIGHT = ss.STATBAR_HEIGHT
local STATBAR_WIDTH = ss.STATBAR_WIDTH
local STATBAR_HEIGHT_MINI = ss.STATBAR_HEIGHT_MINI
local STATBAR_WIDTH_MINI = ss.STATBAR_WIDTH_MINI
local STATBAR_COLORS = ss.STATBAR_COLORS
local EXPERIENCE_BAR_HEIGHT = ss.EXPERIENCE_BAR_HEIGHT
local EXPERIENCE_BAR_WIDTH = ss.EXPERIENCE_BAR_WIDTH
local STAMINA_BAR_HEIGHT = ss.STAMINA_BAR_HEIGHT
local STAMINA_BAR_WIDTH = ss.STAMINA_BAR_WIDTH
local ENABLE_BREATH_MONITOR = ss.ENABLE_BREATH_MONITOR
local ENABLE_PERMANENT_STAT_BUFFS = ss.ENABLE_PERMANENT_STAT_BUFFS
local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids
local stat_buffs = ss.stat_buffs
local job_handles = ss.job_handles


-- the time inverval (seconds) that the breath and stmina monitors check for gameplay
-- events that impact those player stats, then modifies them when needed. these values
-- don't apply if the above monitors are disabled.
local BREATH_MONITOR_INTERVAL = 1.0



--- @param player_meta MetaDataRef used to access various player meta data
--- @param stat string player stat to be effected: health, hunger, thirst, etc
--- @param direction string 'up' or 'down'. reduce or increase the stat over time
--- @param amount number the total amount of the stat to be depleted after 'days'
--- @param days number how many in-game days for the stat to be reduced by 'amount'
--- @param interval number how many seconds betweem each stat modification cycle
function ss.initialize_infinite_buff(player_meta, player_name, stat, direction, amount, days, interval)

    direction = direction or "down"
    amount = amount or player_meta:get_float(stat .. "_max")
    days = days or 1.0
    interval = interval or 5

    -- Convert the in-game day duration from minutes to seconds
    local real_seconds_per_ingame_day = (1440 / TIME_SPEED) * 60

    -- Multiply by 'days' to get the total real-world seconds for full depletion
    local total_real_seconds_for_depletion = real_seconds_per_ingame_day * days

    -- Determine the total number of cycles required within the span of 'days'
    local total_cycles = total_real_seconds_for_depletion / interval

    -- how much stat value to apply during each cycle to ensure the stat is modified
    -- by total 'amount' over the given duration of 'days'
    local amount_per_cycle = amount / total_cycles

    -- initialize stat_buffs table with perpetual hunger, thirst, and sanity drain
    local buff_id = get_buff_id(player_meta)
    stat_buffs[player_name][buff_id] = {
        buff_id = buff_id,
        stat = stat,
        direction = direction,
        amount = amount_per_cycle,
        is_immediate = true,
        iterations = 1,
        interval = interval,
        infinite = true
    }

    --print("  initialized infinite buff for " .. stat)
    player_meta:set_string("stat_buffs", mt_serialize(stat_buffs[player_name]))

end
local initialize_infinite_buff = ss.initialize_infinite_buff


-- hud properties of the main vertical statbars (health, hunger, thirst, etc)
local y_pos = -27


-- horizontal position of all vertical statbars (does not apply to experience statbar)
local x_pos_stat = {
    sanity = 20, immunity = 55, hunger = 90, thirst = 125, health = 160,
    breath = -245, weight = 245
}




local y_pos_breath = -24


--- @param player ObjectRef the player object
--- @param player_name string the player's name
--- @param stat string the player stat to act upon
-- displays two hud image elements, one that is an icon representing the stat, and the
-- other a black bar background for the main stat bar.
local function initialize_hud_stats(player, player_name, stat)
    --print("  initialize_hud_stats()")
    --print("    stat: " .. stat)
    local hud_definition

    -- stat bar values are updated to real values after this function
    local dummy_value = 1
    player_hud_ids[player_name][stat] = {}

    -- black statbar background
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = x_pos_stat[stat], y = y_pos - 5},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = STATBAR_WIDTH, y = STATBAR_HEIGHT},
        alignment = {x = 0, y = -1}
    }
    if stat == "breath" then
        hud_definition.position.x = 0.5
        hud_definition.offset.y = y_pos_breath
        hud_definition.scale = {x = 0, y = 0}
        player_hud_ids[player_name][stat].bg = player:hud_add(hud_definition)
    elseif stat == "weight" then
        hud_definition.position.x = 0.5
        hud_definition.offset.y = y_pos_breath
        hud_definition.scale = {x = STATBAR_WIDTH_MINI, y = STATBAR_HEIGHT_MINI}
        player:hud_add(hud_definition)
    else
        player:hud_add(hud_definition)
    end

    -- statbar icon
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = x_pos_stat[stat], y = y_pos + 22},
        text = "ss_hud_icon_" .. stat .. ".png",
        scale = {x = 1.3, y = 1.3},
        alignment = {x = 0, y = -1}
    }
    if stat == "breath" then
        hud_definition.position.x = 0.5
        hud_definition.offset.y = y_pos + 28
        hud_definition.scale = {x = 0, y = 0}
        player_hud_ids[player_name][stat].icon = player:hud_add(hud_definition)
    elseif stat == "weight" then
        hud_definition.position.x = 0.5
        hud_definition.offset.y = y_pos + 24
        player:hud_add(hud_definition)
    else
        player:hud_add(hud_definition)
    end

    -- main colored stat bar
    hud_definition = {
        type = "image",
        position = {x = 0.0, y = 1.0},
        offset = {x = x_pos_stat[stat], y = y_pos - 5},
        text = "[fill:1x1:0,0:" .. STATBAR_COLORS[stat],
        scale = {x = STATBAR_WIDTH - 6, y = dummy_value},
        alignment = {x = 0, y = -1}
    }
    if stat == "breath" then
        hud_definition.position.x = 0.5
        hud_definition.offset.y = y_pos_breath
        hud_definition.scale = {x = 0, y = 0}
    elseif stat == "weight" then
        hud_definition.position.x = 0.5
        hud_definition.offset.y = y_pos_breath
        hud_definition.scale = {x = STATBAR_WIDTH_MINI - 5, y = 0}
    end
    player_hud_ids[player_name][stat].bar = player:hud_add(hud_definition)

    --print("  initialize_hud_stats() end")
end


--- @param player ObjectRef the player object
--- @param player_name string the player's name
-- displays two hud image elements, one that is an icon representing the stat, and the
-- other a black bar background for the main stat bar.
local function initialize_hud_experience(player, player_name)
    --print("  initialize_hud_experience()")

    -- black bg bar for experience stat
    player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = -224, y = -62},
        text = "[fill:1x1:0,0:#000000",
        --text = "ss_hud_black_xp.png",
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
        --text = "ss_hud_experience.png",
        scale = {x = 0, y = EXPERIENCE_BAR_HEIGHT},
        alignment = {x = 1, y = -1}
    })

    --print("  initialize_hud_experience() end")
end

local function initialize_hud_stamina(player, player_name)
    --print("  initialize_hud_stamina()")

    -- black bg bar for stamina stat
    player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1.0},
        offset = {x = -224, y = -70},
        text = "[fill:1x1:0,0:#000000",
        --text = "ss_hud_black_xp.png",
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
        --text = "ss_hud_stamina.png",
        scale = {x = 0, y = STAMINA_BAR_HEIGHT},
        alignment = {x = 1, y = -1}
    })

    --print("  initialize_hud_stamina() end")
end


local flag4 = false
local function monitor_breath(player)
    debug(flag4, "\nmonitor_breath()")
    if player == nil then
        debug(flag4, "  player is nil. quitting monitor_breath()...")
        return
    end

    -- get the node name that is at player's head height
    local pos = player:get_pos()
    local head_height = 1.5
    pos.y = pos.y + head_height
    local node = mt_get_node(pos)
    local node_name = node.name
    debug(flag4, "  node_name: " .. node_name)

    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local breath_current = player_meta:get_float("breath_current")
    local breath_max = player_meta:get_float("breath_max")
    debug(flag4, "  current " .. breath_current .. " | max " .. breath_max)

    if NODE_NAMES_WATER[node_name] then
        debug(flag4, "  ** underwater **")
        player:set_breath(20)
        set_stat(player, player_meta, "breath", "down", player_data[player_name].breath_deplete_rate)

    else
        --print("  not underwater")
        if breath_current < breath_max then
            debug(flag4, "  restoring breath...")
            set_stat(player, player_meta, "breath", "up", player_data[player_name].breath_restore_rate)
        end
    end

    debug(flag4, "monitor_breath() end")
    local job_handle = mt_after(BREATH_MONITOR_INTERVAL, monitor_breath, player)
    job_handles[player_name].monitor_breath = job_handle
end

-- global wrapper to keep monitor_breath() as a local function for speed
function ss.start_monitor_breath(player)
    monitor_breath(player)
end


local flag1 = false
minetest.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() STATS")
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local player_status = player_meta:get_int("player_status")
	local p_data = player_data[player_name]

    -- hide default health bar
    debug(flag1, "hiding default MTG health bar...")
    player:hud_set_flags({ healthbar = false, breathbar = false })

    debug(flag1, "initializing hud for exhaustion screen color overlay...")
    player_hud_ids[player_name].screen_effect = player:hud_add({
        type = "image",
        position = {x = 0.5, y = 0.5},
        offset = {x = 0, y = 0},
		text = "[fill:1x1:0,0:#888844^[opacity:0",
        scale = {x = -100, y = -100},
        alignment = {x = 0, y = 0},
    })

    debug(flag1, "initializing huds for player statbar bg...")
    -- transparent black bg box displayed behind all stat bars
    player:hud_add({
        type = "image",
        position = {x = 0, y = 1},
        offset = {x = 0, y = 0},
        text = "[fill:1x1:0,0:#00000080",
        scale = {x = 190, y = 150},
        alignment = {x = 1, y = -1}
    })

    -- initialize hud elements relating to the main vertical statbars and set to their
    -- default state with dummy values
    initialize_hud_stats(player, player_name, "health")
    initialize_hud_stats(player, player_name, "hunger")
    initialize_hud_stats(player, player_name, "thirst")
    initialize_hud_stats(player, player_name, "immunity")
    initialize_hud_stats(player, player_name, "sanity")
    initialize_hud_stats(player, player_name, "breath")
    initialize_hud_stats(player, player_name, "weight")

    -- initialize hudbar elements relating to experience and engergy and set it to
    -- their default state with dummy values
    initialize_hud_experience(player, player_name)
    initialize_hud_stamina(player, player_name)

	if player_status == 0 then
		debug(flag1, "  new player")

        --debug(flag1, "save initial stat_buffs table to player metadata")
        --player_meta:set_string("stat_buffs", mt_serialize(stat_buffs[player_name]))

        debug(flag1, "calculating inventory weight max")
        local player_inv = player:get_inventory()
        local inventory_slot_count = player_inv:get_size("main")
        debug(flag1, "inventory_slot_count: " .. inventory_slot_count)
        local inv_weight_max = inventory_slot_count * p_data.weight_max_per_slot
        debug(flag1, "inv_weight_max: " .. inv_weight_max)

		-- load statbar values for most of the main stats. within this process the
        -- function set_stat_value() is called and initializes the metadata for
        -- <stat>_current and <stat>_max. example: 'health_current' and 'health_max'
        debug(flag1, "load all common statbar values via set_stat_value() function")
		set_stat_value(player, "health", DEFAULT_STAT_START.health, DEFAULT_STAT_MAX.health)
		set_stat_value(player, "hunger", DEFAULT_STAT_START.hunger, DEFAULT_STAT_MAX.hunger)
		set_stat_value(player, "thirst", DEFAULT_STAT_START.thirst, DEFAULT_STAT_MAX.thirst)
		set_stat_value(player, "immunity", DEFAULT_STAT_START.immunity, DEFAULT_STAT_MAX.immunity)
		set_stat_value(player, "sanity", DEFAULT_STAT_START.sanity, DEFAULT_STAT_MAX.sanity)
		set_stat_value(player, "breath", DEFAULT_STAT_START.breath, DEFAULT_STAT_MAX.breath)
		set_stat_value(player, "weight", DEFAULT_STAT_START.weight, inv_weight_max)

		-- update player physics with the specified player walk speed and jump height
		local physics = player:get_physics_override()
		physics.speed = p_data.speed_walk
		physics.jump = p_data.height_jump
		player:set_physics_override(physics)

		-- load statbar values for experience
		debug(flag1, "loading xp statbar values via custom function..")
		player_meta:set_float("experience_max", DEFAULT_STAT_MAX.experience)
		set_experience(player, DEFAULT_STAT_START.experience, DEFAULT_STAT_MAX.experience)

		-- load statbar values for stamina
		debug(flag1, "loading stamina statbar values via custom function..")
		player_meta:set_float("stamina_max", DEFAULT_STAT_MAX.stamina)
		player_meta:set_float("stamina_current", DEFAULT_STAT_MAX.stamina)
		set_stamina(player, DEFAULT_STAT_START.stamina, DEFAULT_STAT_MAX.stamina)

        -- 'p_data.stamina_full' and 'p_data.exhausted' is not initialized here nor
		-- saved in player metadata since it's intialized 'set_stamina()' function ^.

		debug(flag1, "starting perpetual stat drain buffs")
        if ENABLE_PERMANENT_STAT_BUFFS then
            initialize_infinite_buff(player_meta, player_name, "hunger", "down", 100, 1.0, 5)
            initialize_infinite_buff(player_meta, player_name, "thirst", "down", 100, 0.5, 5)
            initialize_infinite_buff(player_meta, player_name, "sanity", "down", 100, 2.0, 5)
        end

	elseif player_status == 1 then
		debug(flag1, "  existing player")

		debug(flag1, "restoring saved values for the main (vertical) statbars..")
        for _, stat in ipairs({"health", "hunger", "thirst", "immunity", "sanity", "breath", "weight" }) do
            local stat_current = player_meta:get_float(stat .. "_current")
            local stat_max = player_meta:get_float(stat .. "_max")
            set_stat_value(player, stat, stat_current, stat_max)
        end

		debug(flag1, "restoring player speed and jump physics values..")
		local physics = player:get_physics_override()
		physics.speed = p_data.speed_walk
		physics.jump = p_data.height_jump
		player:set_physics_override(physics)

		debug(flag1, "restoring saved values for experience..")
        local experience_current = player_meta:get_float("experience_current")
        local experience_max = player_meta:get_float("experience_max")
        set_experience(player, experience_current, experience_max)

        debug(flag1, "restoring saved values for stamina..")
        local stamina_current = player_meta:get_float("stamina_current")
        local stamina_max = player_meta:get_float("stamina_max")
        set_stamina(player, stamina_current, stamina_max)

        -- ^ 'p_data.stamina_full' and 'p_data.exhausted' is not initialized here nor
		-- saved in player metadata since it's intialized 'set_stamina()' function ^.
	end

	-- use a copy of the stat_buffs table prevent scenario where existing buffs are
	-- being loaded and their new buff_ids are being stored into this same stat_buffs
	-- table and then accidentally access by the loop below and buff loaded again.
	local stat_buffs_copy = table_copy(stat_buffs[player_name])
	debug(flag1, "executing any saved stat buffs loops for player: " .. player_name)

	-- run the saved stat buffs but tie it to new buff_id to prevent them to
	-- overlapping when the id's loop around from 1000 to 1.
	for buff_id, buff_info in pairs(stat_buffs_copy) do

		-- as each buff is re-loaded, it gets new buff_id to prevent buff_id stagnation
		-- and overlap with other buff id's as they loop from buff_id_999999 to buff_id_1
		stat_buffs[player_name][buff_id] = nil
		local new_buff_id = get_buff_id(player_meta)
		buff_info.buff_id = new_buff_id

		-- the 'health_drain_stat' property of a health drain buff must also be updated
		-- with the new buff_id from above
		if buff_info.health_drain_stat then
			debug(flag1, "  this is a health drain buff")
			local stat = buff_info.health_drain_stat
			player_meta:set_string(stat .. "_health_draining", new_buff_id)
			debug(flag1, "  updated health_drain_buff_id to: " .. new_buff_id)
		end

		stat_buffs[player_name][new_buff_id] = buff_info
		debug(flag1, "  migrated " .. buff_id .. " to new buff_id: " .. new_buff_id)

		-- adds 0 to 5 seconds to the buff's execution reload to help prevent multiple
		-- buffs with same intervals from firing simultaneously. does not apply to
		-- stamina buffs, which will execute immediately.
		local extra_time = 0
		if buff_info.stat ~= "stamina" then
			extra_time = math_random(0, 5)
		end

		debug(flag1, "  running minetest.after()...")
		local buff_handle = mt_after(buff_info.interval + extra_time, start_buff_loop, player, player_meta, buff_info)
		job_handles[player_name][new_buff_id] = buff_handle

		debug(flag1, "  ** new job saved into active_jobs table: " .. new_buff_id .. " **")
	end

	debug(flag1, "save updated stat_buffs table to player metadata")
	player_meta:set_string("stat_buffs", mt_serialize(stat_buffs[player_name]))

	if ENABLE_BREATH_MONITOR then
		-- start perpetual loop that monitors if player is underwater
		local job_handle = mt_after(0, monitor_breath, player)
		job_handles[player_name].monitor_breath = job_handle
		debug(flag1, "enabled breath monitor")
	end

	--monitor_physics(player)

	debug(flag1, "\nregister_on_joinplayer() end")
end)



local flag99 = false
minetest.register_on_leaveplayer(function(player, timed_out)
    debug(flag99, "\nregister_on_leaveplayer() stats_lua")

    local player_name = player:get_player_name()
    stat_buffs[player_name] = {}
    debug(flag99, "  player removed from stat_buffs table: " .. player_name)
    debug(flag99, "  stat_buffs: " .. dump(stat_buffs))

    debug(flag99, "register_on_leaveplayer() END")
end)



local DIG_NODE_XP = {}

-- calculate the XP reward for each node based on tool capabilities of digging
-- with an empty hand. store the XP value in DIG_NODE_XP table above indexed
-- by the node name.
local empty_hand_item = ItemStack("") -- Represents an empty hand
local tool_capabilities = empty_hand_item:get_tool_capabilities()
if tool_capabilities then
    for node_name, node_def in pairs(minetest.registered_nodes) do
        local xp_reward = 0
        -- Ensure the node has groups defined for digging
        if node_def.groups then
            for group_name, group_level in pairs(node_def.groups) do
                -- Check if the empty hand has a matching group capability
                local groupcap = tool_capabilities.groupcaps[group_name]
                if groupcap then
                    -- Use dig time for the node's group level, or max level time if undefined
                    local dig_time = groupcap.times[group_level] or groupcap.times[#groupcap.times]
                    xp_reward = dig_time
                    break
                end
            end
        end
        DIG_NODE_XP[node_name] = round(xp_reward / 10, 1)
    end
end

local flag11 = false
minetest.register_on_dignode(function(pos, oldnode, digger)
    debug(flag11, "register_on_dignode() stats.lua")

    if not digger or not digger:is_player() then
        debug(flag11, "  node not dug by a player. no XP rewarded.")
    else
        local xp_reward = DIG_NODE_XP[oldnode.name] or 0
        set_stat(digger, digger:get_meta(), "experience", "up", xp_reward)
        debug(flag11, "  xp_reward: " .. xp_reward)
    end

    debug(flag11, "register_on_dignode() end")
end)