print("- loading player_death.lua")

-- cache global functions for faster access
local debug = ss.debug
local math_random = math.random
local table_copy = table.copy
local mt_serialize = minetest.serialize
local mt_add_item = minetest.add_item
local mt_after = minetest.after
local mt_show_formspec = minetest.show_formspec
local set_experience = ss.set_experience
local set_stamina = ss.set_stamina
local set_stat = ss.set_stat
local set_stat_value = ss.set_stat_value
local update_fs_weight = ss.update_fs_weight
local initialize_infinite_buff = ss.initialize_infinite_buff
local get_buff_id = ss.get_buff_id
local start_buff_loop = ss.start_buff_loop
local start_monitor_breath = ss.start_monitor_breath
local set_starting_state = ss.set_starting_state
local start_monitor_player_state = ss.start_monitor_player_state
local get_fs_setup_body = ss.get_fs_setup_body
local build_fs = ss.build_fs

-- cache global variables for faster access
local SLOT_WEIGHT_MAX = ss.SLOT_WEIGHT_MAX
local INV_SIZE_START = ss.INV_SIZE_START
local DEFAULT_STAT_START = ss.DEFAULT_STAT_START
local DEFAULT_STAT_MAX = ss.DEFAULT_STAT_MAX
local ENABLE_PERMANENT_STAT_BUFFS = ss.ENABLE_PERMANENT_STAT_BUFFS
local ENABLE_BREATH_MONITOR = ss.ENABLE_BREATH_MONITOR
local current_tab = ss.current_tab
local player_data = ss.player_data
local job_handles = ss.job_handles
local stat_buffs = ss.stat_buffs

local list_names_to_drop = {
    "main",
    "bag_slots",
    "armor_slot_head",
    "armor_slot_face",
    "armor_slot_chest",
    "armor_slot_arms",
    "armor_slot_legs",
    "armor_slot_feet",
    "clothing_slot_eyes",
    "clothing_slot_neck",
    "clothing_slot_chest",
    "clothing_slot_hands",
    "clothing_slot_legs",
    "clothing_slot_feet"
}


local flag1 = false
minetest.register_on_dieplayer(function(player)
    debug(flag1, "\nregister_on_dieplayer() player_death.lua")
    local player_inv = player:get_inventory()
    local player_meta = player:get_meta()
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]

    debug(flag1, "  cancelling any pending stat buffs pending with minetest.after()")
    if job_handles[player_name] then
        for buff_id, job in pairs(job_handles[player_name]) do
            job:cancel()
            job_handles[player_name][buff_id] = nil
            debug(flag1, "  ** " .. buff_id ..  " cancelled **")
        end
    end

	debug(flag1, "  removing all saved stat buffs from 'stat_buffs' table")
	stat_buffs[player_name] = {}
	player_meta:set_string("stat_buffs", mt_serialize(stat_buffs[player_name]))

    debug(flag1, "  reset any perpetual health drain flags due to depleted player stat")
    player_meta:set_string("thirst_health_draining", "")
    player_meta:set_string("hunger_health_draining", "")
    player_meta:set_string("immunity_health_draining", "")
    player_meta:set_string("sanity_health_draining", "")
    player_meta:set_string("breath_health_draining", "")

    debug(flag1, "  resetting player model to default base textures..")
    -- ### clothing.lua and armor.lua ###
	-- minetest.after() is needed here to give engine time to respawn player object
	-- otherwise code below will refer to invalid player object
	--mt_after(1, function()
	--end)
    player:set_properties({ textures = {p_data.avatar_texture_base} })
    debug(flag1, "  p_data.avatar_texture_base: " .. p_data.avatar_texture_base)


    debug(flag1, "  resetting bundle tab")
    local bundle_status = p_data.bundle_status
    debug(flag1, "  bundle_status: " .. bundle_status)
    if bundle_status == "inactive" then
        if not player_inv:is_empty("bundle_slot") then
            debug(flag1, "  item bundle found in bundle slot. dropping to ground..")
            local bundle_item = player_inv:get_stack("bundle_slot", 1)
            mt_add_item(player:get_pos(), bundle_item)
            player_inv:set_list("bundle_slot", {})
            -- reducing inventory weight will already be handled further below
        end
    else
        -- bundle status is creating_new, update_existing, or view_bundle
        debug(flag1, "  dropping all items from bundle grid..")
        local pos = player:get_pos()
        local bundle_grid_items = player_inv:get_list("bundle_grid")
        for i = 1, #bundle_grid_items do
            local slot_item = bundle_grid_items[i]
            if not slot_item:is_empty() then
                debug(flag1, "    slot_item: " .. slot_item:get_name())
                mt_add_item({
                    x = pos.x + math_random(-2, 2)/10,
                    y = pos.y,
                    z = pos.z + math_random(-2, 2)/10},
                    slot_item
                )
            end
        end
        player_inv:set_list("bundle_grid", {})
        player_inv:set_list("bundle_slot", {})
    end

    debug(flag1, "  dropping all items from player inventory..")
    local pos = player:get_pos()
    for i = 1, #list_names_to_drop do
        local list_name = list_names_to_drop[i]
        debug(flag1, "  list_name: " .. list_name)
        local slot_items = player_inv:get_list(list_name)
        if #slot_items > 0 then
            debug(flag1, "  list contains items..")
            for j = 1, #slot_items do
                local slot_item = slot_items[j]
                if not slot_item:is_empty() then
                    debug(flag1, "    slot_item: " .. slot_item:get_name())
                    mt_add_item({
                        x = pos.x + math_random(-2, 2)/10,
                        y = pos.y,
                        z = pos.z + math_random(-2, 2)/10},
                        slot_item
                    )
                end
            end
            debug(flag1, "  all list items dropped")
            player_inv:set_list(list_name, {})
        else
            debug(flag1, "  list empty. skipped.")
        end
    end

    p_data.formspec_mode = "main_formspec"
    p_data.active_tab = "main"

    debug(flag1, "  resetting player inventory weight..")
    set_stat(player, player_meta, "weight", "up", 0)
    set_stat_value(player, "weight", 0, INV_SIZE_START * SLOT_WEIGHT_MAX)
    update_fs_weight(player, player_meta)

	debug(flag1, "register_on_dieplayer() end")
end)


local flag2 = false
minetest.register_on_respawnplayer(function(player)
    debug(flag2, "\nregister_on_respawnplayer() player_death.lua")
    local player_name = player:get_player_name()
    local player_inv = player:get_inventory()
    local player_meta = player:get_meta()
    local p_data = ss.player_data[player_name]

    -- ### inventory.lua ###
    debug(flag2, "  resetting player inventory properties..")
    player_inv:set_size("main", INV_SIZE_START)
    debug(flag2, "    INV_SIZE_START: " .. INV_SIZE_START)
    local inventory_slot_count = player_inv:get_size("main")
    debug(flag2, "    inventory_slot_count: " .. inventory_slot_count)
    local inv_weight_max = inventory_slot_count * p_data.weight_max_per_slot
    debug(flag2, "    inv_weight_max: " .. inv_weight_max)

    debug(flag2, "  resetting player inventory formspec..")
    local new_fs = {
        setup = ss.get_fs_setup(),
        left = {
            stats =             ss.get_fs_player_stats(player_name),
            left_tabs =         ss.get_fs_tabs_left(),
            player_avatar =     ss.get_fs_player_avatar(p_data.avatar_mesh, p_data.avatar_texture_base),
            equipment_slots =   ss.get_fs_equip_slots(p_data),
            equipment_stats =   ss.get_fs_equipment_buffs(player_name),
        },
        center = {
            item_info_slot =    ss.get_fs_item_info_slot(),
            item_info =         ss.get_fs_item_info(),
            inventory_grid =    ss.get_fs_inventory_grid(),
            bag_slots =         ss.get_fs_bag_slots(player_inv, player_name),
            weight =            ss.get_fs_weight(player)
        },
        right = {
            craft_categories =  ss.get_fs_craft_categories("tools"),
            craft_title =       ss.get_fs_craft_title("hands", "tools"),
            craft_item_icon =   {},
            craft_item =        {},
            craft_button =      {},
            ingredients_box =   ss.get_fs_ingred_box(player_name),
            craft_grid =        ss.get_fs_crafting_grid(player_name, player_inv, "tools")
        }
    }
    player_data[player_name].fs = new_fs
    player_meta:set_string("fs", mt_serialize(new_fs))
    player:set_inventory_formspec(build_fs(new_fs))

	-- reset statbar values for most of the main stats
    debug(flag2, "  resetting hudbar stat values..")
	set_stat_value(player, "health", DEFAULT_STAT_START.health, DEFAULT_STAT_MAX.health)
	set_stat_value(player, "hunger", DEFAULT_STAT_START.hunger, DEFAULT_STAT_MAX.hunger)
	set_stat_value(player, "thirst", DEFAULT_STAT_START.thirst, DEFAULT_STAT_MAX.thirst)
	set_stat_value(player, "immunity", DEFAULT_STAT_START.immunity, DEFAULT_STAT_MAX.immunity)
	set_stat_value(player, "sanity", DEFAULT_STAT_START.sanity, DEFAULT_STAT_MAX.sanity)
	set_stat_value(player, "breath", DEFAULT_STAT_START.breath, DEFAULT_STAT_MAX.breath)
	set_stat_value(player, "weight", DEFAULT_STAT_START.weight, inv_weight_max)

	debug(flag2, "  resetting player movement speed and jump height..")
	local physics = player:get_physics_override()
	physics.speed = p_data.speed_walk
    debug(flag2, "    physics.speed: " .. physics.speed)
	physics.jump = p_data.height_jump
    debug(flag2, "    physics.jump: " .. physics.jump)
	player:set_physics_override(physics)

	debug(flag2, "  resetting xp statbar value..")
	player_meta:set_float("experience_max", DEFAULT_STAT_MAX.experience)
	set_experience(player, DEFAULT_STAT_START.experience, DEFAULT_STAT_MAX.experience)
    debug(flag2, "    DEFAULT_STAT_START.experience: " .. DEFAULT_STAT_START.experience)

	debug(flag2, "  loading stamina statbar values..")
	player_meta:set_float("stamina_max", DEFAULT_STAT_MAX.stamina)
	player_meta:set_float("stamina_current", DEFAULT_STAT_MAX.stamina)
	set_stamina(player, DEFAULT_STAT_START.stamina, DEFAULT_STAT_MAX.stamina)
    debug(flag2, "    DEFAULT_STAT_START.stamina: " .. DEFAULT_STAT_START.stamina)

	debug(flag2, "  starting up stat drain buff loops..")
	if ENABLE_PERMANENT_STAT_BUFFS then
		initialize_infinite_buff(player_meta, player_name, "hunger", "down", 100, 1.0, 5)
		initialize_infinite_buff(player_meta, player_name, "thirst", "down", 100, 0.5, 5)
		initialize_infinite_buff(player_meta, player_name, "sanity", "down", 100, 2.0, 5)
	end

	local stat_buffs_copy = table_copy(stat_buffs[player_name])
    debug(flag2, "  executing any stat buff loops...")
    for buff_id, buff_info in pairs(stat_buffs_copy) do

        -- as each buff is re-loaded, it gets new buff_id to prevent buff_id stagnation
        -- and overlap with other buff id's as they loop from buff_id_999999 to buff_id_1
        stat_buffs[player_name][buff_id] = nil
        local new_buff_id = get_buff_id(player_meta)
        buff_info.buff_id = new_buff_id

        -- the 'health_drain_stat' property of a health drain buff must also be updated
        -- with the new buff_id from above
        if buff_info.health_drain_stat then
            debug(flag2, "    this is a health drain buff")
            local stat = buff_info.health_drain_stat
            player_meta:set_string(stat .. "_health_draining", new_buff_id)
            debug(flag2, "    updated health_drain_buff_id to: " .. new_buff_id)
        end

        stat_buffs[player_name][new_buff_id] = buff_info
        debug(flag2, "    migrated " .. buff_id .. " to new buff_id: " .. new_buff_id)

        -- adds 0 to 5 seconds to the buff's execution reload to help prevent multiple
        -- buffs with same intervals from firing simultaneously. does not apply to
        -- stamina buffs, which will execute immediately.
        local extra_time = 0
        if buff_info.stat ~= "stamina" then
            extra_time = math_random(0, 5)
        end

        debug(flag2, "    running minetest.after()...")
        local buff_handle = mt_after(buff_info.interval + extra_time, start_buff_loop, player, player_meta, buff_info)
        job_handles[player_name][new_buff_id] = buff_handle

        debug(flag2, "  ** new job saved into active_jobs table: " .. new_buff_id .. " **")
    end

    debug(flag2, "  save updated stat_buffs table to player metadata")
    player_meta:set_string("stat_buffs", mt_serialize(stat_buffs[player_name]))

    -- perpetual loop that monitors if player is underwater
    if ENABLE_BREATH_MONITOR then
        local job_handle = mt_after(1, start_monitor_breath, player)
        job_handles[player:get_player_name()].monitor_breath = job_handle
        debug(flag2, "  enabled breath monitor")
    end

    debug(flag2, "  starting up monitor player state loop..")
	mt_after(1, function()
		local player_state, fcrouched = set_starting_state(player)
		debug(flag2, "  player_state: " .. dump(player_state))
		start_monitor_player_state(player, player_state, player:get_pos(), false, fcrouched, false)
	end)


    debug(flag2, "  start up display of player setup window..")
    current_tab[player_name] = "body"
	mt_after(1, function()
		local formspec = get_fs_setup_body(p_data)
		mt_show_formspec(player_name, "ss:ui_player_setup", formspec)
	end)

	debug(flag2, "register_on_respawnplayer() end")

    -- disable standard player placement
    return true
end)