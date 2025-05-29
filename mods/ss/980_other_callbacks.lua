print("- loading other_callbacks.lua")

-- cache global functions for faster access
local debug = ss.debug
local mt_after = core.after
local mt_sound_play = core.sound_play
local mt_get_node = core.get_node
local mt_serialize = core.serialize
local mt_get_gametime = core.get_gametime
local round = ss.round
local get_itemstack_weight = ss.get_itemstack_weight
local get_wield_weight = ss.get_wield_weight
local exceeds_inv_weight_max = ss.exceeds_inv_weight_max
local get_fs_weight = ss.get_fs_weight
local notify = ss.notify
local play_sound = ss.play_sound
local get_craftable_count = ss.get_craftable_count
local get_fs_craft_button = ss.get_fs_craft_button
local get_fs_ingred_box = ss.get_fs_ingred_box
local get_fs_crafting_grid = ss.get_fs_crafting_grid
local do_stat_update_action = ss.do_stat_update_action
local build_fs = ss.build_fs

-- cache global variables for faster access
local RECIPES = ss.RECIPES
local SPILLABLE_ITEM_NAMES = ss.SPILLABLE_ITEM_NAMES
local NODE_LEGS_DRAIN_MOD = ss.NODE_LEGS_DRAIN_MOD
local NODE_HANDS_DRAIN_MOD = ss.NODE_HANDS_DRAIN_MOD
local NOTIFICATIONS = ss.NOTIFICATIONS
local NOTIFY_DURATION = ss.NOTIFY_DURATION
local player_data = ss.player_data



-- this function exectues before the itemstack is added to the player inventory
local flag1 = false
core.register_on_item_pickup(function(itemstack, picker, pointed_thing, time_from_last_punch)
    debug(flag1, "\nregister_on_item_pickup() other_callbacks.lua")
    local player_meta = picker:get_meta()
    local player_name = picker:get_player_name()
    local p_data = player_data[player_name]
    local fs = p_data.fs
    local player_inv = picker:get_inventory()
    local item_count = itemstack:get_count()
    local recipe_category = p_data.recipe_category

    --debug(flag1, "  item_name: " .. itemstack:get_name() .. ", item_count: " .. item_count)

    -- prevent item pickup if no empty slots available
    if not player_inv:room_for_item("main", itemstack) then
        notify(picker, "inventory", "No inventory space", NOTIFY_DURATION, 0, 0.5, 3)
        return itemstack
    end

    -- prevent item pickup if inventory weight will exceed max
    if exceeds_inv_weight_max(itemstack, player_meta) then
        notify(picker, "inventory", NOTIFICATIONS.inv_weight_max, NOTIFY_DURATION, 0, 0.5, 3)
        return itemstack
    end

    -- prevent pickup of water filled wooden cup if no space in hotbar
    if SPILLABLE_ITEM_NAMES[itemstack:get_name()] then
        local hotbar_full = true
        for i = 1, 8 do
            if player_inv:get_stack("main", i):is_empty() then
                hotbar_full = false
            end
        end
        if hotbar_full then
            notify(picker, "inventory", NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
            return itemstack
        end
    end

    -- add the itemstack to the player inventory
    player_inv:add_item("main", itemstack)
    play_sound("item_move", {item_name = itemstack:get_name(), player_name = player_name})

    -- update inventory formspec recipes with the new picked up items
    --debug(flag1, "  updating craft button, ingred box, and craft grid...")
    local recipe_id = p_data.prev_recipe_id
    if recipe_id == "" then
        --debug(flag1, "  No prior recipe item clicked. Skipped refresh of ingred box and craft button.")
    else
        --debug(flag1, "  Loading recipe_id and refreshing ingred_box and craft button...")
        local recipe = RECIPES[recipe_id]
        local crafting_count = get_craftable_count(player_inv, recipe_id)
        fs.right.craft_button = get_fs_craft_button(recipe_id, crafting_count)
        fs.right.ingredients_box = get_fs_ingred_box(player_name, ItemStack(recipe.icon), player_inv, recipe_id)
    end

    -- update recipe grid formspec based on the newly picked up itemstack
    --debug(flag1, "  Update crafting grid and refresh inventory formspec")
    fs.right.craft_grid = get_fs_crafting_grid(player_name, player_inv, recipe_category)

    -- update weight statbar hud to reflect addition of itemstack
    --debug(flag1, "  Update weight statbar...")
    local weight = get_itemstack_weight(itemstack)
    do_stat_update_action(picker, p_data, player_meta, "normal", "weight", weight, "curr", "add", true)

    -- update inv weight formspec to reflect addition of itemstack
    --debug(flag1, "  Update weight formspec...")
    fs.center.weight = get_fs_weight(picker)

    -- saved updated fromspec to metadata and to player active data
    player_meta:set_string("fs", mt_serialize(fs))
    picker:set_inventory_formspec(build_fs(fs))

    -- remove the picked up item entity from the world
    --debug(flag1, "  removing item entity from world...")
    if pointed_thing and pointed_thing.type == "object" then
        local object = pointed_thing.ref
        if object and object:is_player() == false then
            --debug(flag1, "    item remmoved!")
            object:remove()
        end
    end

    debug(flag1, "register_on_item_pickup() END " .. mt_get_gametime())
    return itemstack
end)





local DIG_NODE_XP = {}

-- populate DIG_NODE_XP table with the XP rewards for digging a specific node.
-- indexed by node name. calculate the XP reward for each node based on tool
-- capabilities of digging with an empty hand. 
local empty_hand_item = ItemStack("") -- Represents an empty hand
local tool_capabilities = empty_hand_item:get_tool_capabilities()
if tool_capabilities then
    for node_name, node_def in pairs(core.registered_nodes) do
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
core.register_on_dignode(function(pos, oldnode, digger)
    debug(flag11, "register_on_dignode() stats.lua")

    if digger and digger:is_player() then

        local p_data = player_data[digger:get_player_name()]
        local player_meta = digger:get_meta()
        local node_name = oldnode.name
        --debug(flag11, "  node_name: " .. node_name)

        -- give player XP for digging up node
        local xp_reward = (DIG_NODE_XP[node_name] * p_data.experience_rec_mod_fast_learner) or 0
        --debug(flag11, "  xp_reward: " .. xp_reward)
        do_stat_update_action(digger, p_data, player_meta, "normal", "experience", xp_reward, "curr", "add", true)

        -- drain hands value due to effort from digging a node
        local hardness_modifier = NODE_HANDS_DRAIN_MOD[node_name]
        --debug(flag11, "  hardness_modifier: " .. hardness_modifier)
        local empty_hand_modifier = 1
        local tool_weight, is_emtpy_handed = get_wield_weight(digger, p_data)
        if is_emtpy_handed then empty_hand_modifier = 3 end
        --debug(flag11, "  empty_hand_modifier: " .. empty_hand_modifier)
        local hand_drain_amount = tool_weight
            * hardness_modifier
            * empty_hand_modifier
            * p_data.hand_injury_mod_glove
            * p_data.hand_injury_mod_skill
            * p_data.hand_drain_mod_knuckle_saurus
        --debug(flag11, "  hand_drain_amount: " .. hand_drain_amount)
        local hands_current = player_meta:get_float("hands_current")
        local hands_max = player_meta:get_float("hands_max")
        local new_value = hands_current - hand_drain_amount
        local new_ratio = new_value / hands_max
        --debug(flag11, "  new_ratio: " .. new_ratio)
        if new_ratio > 0.80 then
            do_stat_update_action(digger, p_data, player_meta, "normal", "hands", -hand_drain_amount, "curr", "add", true)    
        else
            -- new hands ratio cannot drop below 'sore' 80% level. only bare hand
            -- strikes on mobs can do that. clamp ratio above 80%.
            new_value = (0.80 * hands_max) + 0.01
            player_meta:set_float("hands_current", new_value)
        end

    else
        --debug(flag11, "  node not dug by a player")
    end

    debug(flag11, "register_on_dignode() end")
end)





local flag2 = false
core.register_on_player_hpchange(function(player, hp_change, reason)
    debug(flag2, "\nregister_on_player_hpchange() OTHER CALLBACKS")
    --debug(flag2, "  engine hp (current/max) " .. player:get_hp() .. " / " .. player:get_properties().hp_max)
    --debug(flag2, "  hp_change: " .. hp_change)
    --debug(flag2, "  reason: " .. dump(reason))

    -- caused by engine event like falling, drowning, etc. use custom stat update
    -- function to handle hp loss
    local change_reason = reason.from
    if change_reason == "engine" then
        --debug(flag2, "  hp changed by engine action")
        local p_data = player_data[player:get_player_name()]
        local player_meta = player:get_meta()

        local change_type = reason.type
        if change_type == "fall" then
            --debug(flag2, "  got fall damage")

            -- set the flag true since hp change was due to fall damage. this is used 
            -- by do_stat_update_action() to determine if 'legs' related status effect
            -- can progress to severity 2 'sprained' or 3 'break'
            p_data.got_fall_damage = true

            -- play fall damage sounds
            mt_sound_play("ss_jump_land", {object = player, max_hear_distance = 10})
            mt_after(0.2, function()
                mt_sound_play("ss_stat_effect_health_up_" .. p_data.body_type, {object = player, max_hear_distance = 10})
            end)

            -- add a short delay. without it, the 'bottom_node' that is retrieved
            -- is not always the node the player is actually standing on
            mt_after(0.1, function()
                -- calculate fall damage based on softness of the node landed on
                local pos = player:get_pos()
                local bottom_node = mt_get_node({x = pos.x, y = pos.y - 0.5, z = pos.z})
                local bottom_node_name = bottom_node.name
                local hardness_modifier = NODE_LEGS_DRAIN_MOD[bottom_node_name]
                --debug(flag2, "  hardness mod for " .. bottom_node_name .. ": " .. hardness_modifier)

                hp_change = hp_change
                    * p_data.fall_health_modifier
                    * hardness_modifier
                    * p_data.leg_injury_mod_foot_clothing
                    * p_data.leg_injury_mod_foot_armor
                    * p_data.leg_injury_mod_skill
                    * p_data.health_drain_mod_thudmuffin
                --debug(flag2, "  hp_change: " .. hp_change)

                p_data.legs_damage_total = p_data.legs_damage_total - hp_change
                player_meta:set_float("legs_damage_total", p_data.legs_damage_total)

                do_stat_update_action(player, p_data, player_meta, "normal", "health", hp_change, "curr", "add", true)
            end)

        elseif change_type == "drown" then
            --debug(flag2, "  drowning")
            do_stat_update_action(player, p_data, player_meta, "normal", "health", hp_change, "curr", "add", true)

        elseif change_type == "punch" then
            --debug(flag2, "  got hit")
            do_stat_update_action(player, p_data, player_meta, "normal", "health", hp_change, "curr", "add", true)

        elseif change_type == "node_damage" then
            --debug(flag2, "  smothered by node")
            do_stat_update_action(player, p_data, player_meta, "normal", "health", hp_change, "curr", "add", true)

        elseif change_type == "set_hp" then
            --debug(flag2, "  custom action")
            do_stat_update_action(player, p_data, player_meta, "normal", "health", hp_change, "curr", "add", true)

        elseif change_type == "respawn" then
            --debug(flag2, "  respawning")
            do_stat_update_action(player, p_data, player_meta, "normal", "health", hp_change, "curr", "add", true)

        else
            --debug(flag2, "  ERROR - Unexpected 'change_type' value: " .. change_type)
        end

        -- return zero since 'do_stat_update_action()' will handle the actual hp change
        --debug(flag2, "register_on_player_hpchange() END")
        return 0

    -- caused by mod calling 'set_hp()', like when do_stat_update_action() is called
    -- and then relies on engine to modify the engine 'hp' value after having updated
    -- the corresponding stat bars
    elseif change_reason == "mod" then
        --debug(flag2, "  hp changed by mod action")
        debug(flag2, "register_on_player_hpchange() END")
        return hp_change

    else
        --debug(flag2, "  ERROR - Unexpected 'change_reason' value: " .. change_reason)
        debug(flag2, "register_on_player_hpchange() END")
        return 0
    end

-- boolean parameter below set to 'true' which allows this function to call before the
-- player's hp is actually altered. thus, the return value specifies the actual hp_change
-- value that will impact the player's hp.
end, true)

