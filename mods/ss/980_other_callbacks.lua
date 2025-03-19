print("- loading other_callbacks.lua")

-- cache global functions for faster access
local debug = ss.debug
local mt_serialize = core.serialize
local mt_get_gametime = core.get_gametime
local round = ss.round
local get_itemstack_weight = ss.get_itemstack_weight
local exceeds_inv_weight_max = ss.exceeds_inv_weight_max
local get_fs_weight = ss.get_fs_weight
local notify = ss.notify
local play_sound = ss.play_sound
local get_craftable_count = ss.get_craftable_count
local get_fs_craft_button = ss.get_fs_craft_button
local get_fs_ingred_box = ss.get_fs_ingred_box
local get_fs_crafting_grid = ss.get_fs_crafting_grid
local update_stat = ss.update_stat
local build_fs = ss.build_fs

-- cache global variables for faster access
local RECIPES = ss.RECIPES
local SPILLABLE_ITEM_NAMES = ss.SPILLABLE_ITEM_NAMES
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

    debug(flag1, "  item_name: " .. itemstack:get_name() .. ", item_count: " .. item_count)

    -- prevent item pickup if no empty slots available
    if not player_inv:room_for_item("main", itemstack) then
        notify(picker, "No inventory space", NOTIFY_DURATION, 0, 0.5, 3)
        return itemstack
    end

    -- prevent item pickup if inventory weight will exceed max
    if exceeds_inv_weight_max(itemstack, player_meta) then
        notify(picker, NOTIFICATIONS.inv_weight_max, NOTIFY_DURATION, 0, 0.5, 3)
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
            notify(picker, NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
            return itemstack
        end
    end

    -- add the itemstack to the player inventory
    player_inv:add_item("main", itemstack)
    play_sound("item_move", {item_name = itemstack:get_name(), player_name = player_name})

    -- update inventory formspec recipes with the new picked up items
    debug(flag1, "  updating craft button, ingred box, and craft grid...")
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

    -- update recipe grid formspec based on the newly picked up itemstack
    debug(flag1, "  Update crafting grid and refresh inventory formspec")
    fs.right.craft_grid = get_fs_crafting_grid(player_name, player_inv, recipe_category)

    -- update weight statbar hud to reflect addition of itemstack
    debug(flag1, "  Update weight statbar...")
    local weight = get_itemstack_weight(itemstack)
    local update_data = {"normal", "weight", weight, 1, 1, "curr", "add", true}
    update_stat(picker, p_data, player_meta, update_data)

    -- update inv weight formspec to reflect addition of itemstack
    debug(flag1, "  Update weight formspec...")
    fs.center.weight = get_fs_weight(picker)

    -- saved updated fromspec to metadata and to player active data
    player_meta:set_string("fs", mt_serialize(fs))
    picker:set_inventory_formspec(build_fs(fs))

    -- remove the picked up item entity from the world
    debug(flag1, "  removing item entity from world...")
    if pointed_thing and pointed_thing.type == "object" then
        local object = pointed_thing.ref
        if object and object:is_player() == false then
            debug(flag1, "    item remmoved!")
            object:remove()
        end
    end

    debug(flag1, "register_on_item_pickup() END " .. mt_get_gametime())
    return itemstack
end)





local DIG_NODE_XP = {}

-- calculate the XP reward for each node based on tool capabilities of digging
-- with an empty hand. store the XP value in DIG_NODE_XP table above indexed
-- by the node name.
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

    if not digger or not digger:is_player() then
        debug(flag11, "  node not dug by a player. no XP rewarded.")
    else
        local xp_reward = DIG_NODE_XP[oldnode.name] or 0
        local player_meta = digger:get_meta()
        local update_data = {"normal", "experience", xp_reward, 1, 1, "curr", "add", true}
        update_stat(digger, player_data[digger:get_player_name()], player_meta, update_data)
        debug(flag11, "  xp_reward: " .. xp_reward)
    end

    debug(flag11, "register_on_dignode() end")
end)





local flag2 = false
core.register_on_player_hpchange(function(player, hp_change, reason)
    debug(flag2, "          register_on_player_hpchange() OTHER CALLBACKS")
    debug(flag2, "          current MTG hp " .. player:get_hp())
    debug(flag2, "          current MTG hp_max " .. player:get_properties().hp_max)

    debug(flag2, "            hp_change: " .. hp_change)
    debug(flag2, "            reason: " .. dump(reason))

    local player_meta = player:get_meta()
    debug(flag2, "            current: " .. player_meta:get_float("health_current"))
    debug(flag2, "            max: " .. player_meta:get_float("health_max"))

    -- the hp change event was caused by a built-in action like falling, drowning, etc.
    -- in this case, hook into the custom stat buffs system to alter the hp.
    if reason.from == "engine" then

        local p_data = player_data[player:get_player_name()]
        local update_data = {"normal", "health", hp_change, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player:get_meta(), update_data)

        -- return zero since 'update_stat()' will handle the actual hp change
        debug(flag2, "          register_on_player_hpchange() END")
        return 0

    -- the hp change event was caused by calling the function 'player:set_hp()'
    -- directly, like via update_stat() function. in this case, simply pass
    -- through the hp_change value.
    else
        debug(flag2, "          register_on_player_hpchange() END")
        return hp_change
    end

-- boolean parameter below set to 'true' which allows this function to call before the
-- player's hp is actually altered. thus, the return value specifies the actual hp_change
-- value that will impact the player's hp.
end, true)

