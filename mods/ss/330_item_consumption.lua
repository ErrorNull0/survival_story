print("- loading item_consumption.lua")

-- cache global functions for faster access
local math_min = math.min
local math_random = math.random
local table_copy = table.copy
local table_insert = table.insert
local mt_after = core.after
local debug = ss.debug
local notify = ss.notify
local after_player_check = ss.after_player_check
local update_inventory_weight = ss.update_inventory_weight
local drop_items_from_inventory = ss.drop_items_from_inventory
local update_meta_and_description = ss.update_meta_and_description
local start_try_noise = ss.start_try_noise
local play_sound = ss.play_sound
local update_stat = ss.update_stat
local do_stat_update_action = ss.do_stat_update_action
local hide_stat_effect = ss.hide_stat_effect
local show_stat_effect = ss.show_stat_effect
local start_item_cooldown = ss.start_item_cooldown
local pickup_item = ss.pickup_item

-- cache global variables for faster access
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local NOTIFY_DURATION = ss.NOTIFY_DURATION
local STATUS_EFFECT_INFO = ss.STATUS_EFFECT_INFO
local player_data = ss.player_data
local is_cooldown_active = ss.is_cooldown_active


--[[ Defines the stat impacts of all consumable items, in addition to its cooldown
info. cooldown can be 'ingest' or 'action'. cooldown 'duration' can be fractional.
To ensure a one-time immediate update to 'stat', set 'iterations' to 1 and 'interval'
value doesn't matter. To make a perpetual stat update, set iterations less than 1
and 'amount' will be applied every 'interval' seconds. 'interval' must be greater
than 1. To make a stat update 'amount' applied gradually over time, set 'iterations'
greater than 1 and 'interval' to how many seconds between each iteration. 'amount'
will be divided equally among all iterations. --]]
ss.CONSUMABLE_ITEMS = {
    -- FOOD
    ["ss:apple"] = {
        {stat = "hunger", amount = 10, iterations = 10, interval = 1},
        {stat = "thirst", amount = 4, iterations = 4, interval = 1},
        {stat = "immunity", amount = 0.5, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 4},
    },
    ["ss:apple_dried"] = {
        {stat = "hunger", amount = 10, iterations = 10, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:blueberries"] = {
        {stat = "hunger", amount = 2, iterations = 2, interval = 1},
        {stat = "immunity", amount = 0.75, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 2},
    },
    ["ss:blueberries_dried"] = {
        {stat = "hunger", amount = 2, iterations = 2, interval = 1},
        {stat = "immunity", amount = 0.5, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 2},
    },
    ["ss:mushroom_brown"] = {
        {stat = "hunger", amount = 5, iterations = 5, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:mushroom_brown_dried"] = {
        {stat = "hunger", amount = 3, iterations = 3, interval = 1},
        {cooldown = "ingest", duration = 2},
    },
    ["ss:mushroom_red"] = {
        {stat = "hunger", amount = 5, iterations = 5, interval = 1},
        {stat = "immunity", amount = -2.5, iterations = 5, interval = 1},
        {stat = "poison", amount = 5, iterations = 5, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:mushroom_red_dried"] = {
        {stat = "hunger", amount = 3, iterations = 3, interval = 1},
        {stat = "immunity", amount = -0.5, iterations = 1, interval = 1},
        {stat = "poison", amount = 1, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 2},
    },
    ["ss:cactus"] = {
        {stat = "health", amount = -1, iterations = 1, interval = 1},
        {stat = "hunger", amount = 10, iterations = 10, interval = 1},
        {stat = "thirst", amount = 5, iterations = 5, interval = 1},
        {stat = "immunity", amount = -5, iterations = 10, interval = 1},
        {stat = "poison", amount = 10, iterations = 10, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:cactus_dried"] = {
        {stat = "hunger", amount = 6, iterations = 6, interval = 1},
        {stat = "immunity", amount = -1, iterations = 2, interval = 1},
        {stat = "poison", amount = 2, iterations = 2, interval = 1},
        {cooldown = "ingest", duration = 3},
    },

    ["ss:meat_raw_beef"] = {
        {stat = "hunger", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -10, iterations = 20, interval = 1},
        {stat = "poison", amount = 20, iterations = 20, interval = 1},
        {cooldown = "ingest", duration = 5},
    },
    ["ss:meat_raw_mutton"] = {
        {stat = "hunger", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -12.5, iterations = 25, interval = 1},
        {stat = "poison", amount = 25, iterations = 25, interval = 1},
        {cooldown = "ingest", duration = 5},
    },
    ["ss:meat_raw_pork"] = {
        {stat = "hunger", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -15, iterations = 30, interval = 1},
        {stat = "poison", amount = 30, iterations = 30, interval = 1},
        {cooldown = "ingest", duration = 5},
    },
    ["ss:meat_raw_poultry_large"] = {
        {stat = "hunger", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -15, iterations = 30, interval = 1},
        {stat = "poison", amount = -30, iterations = 30, interval = 1},
        {cooldown = "ingest", duration = 5},
    },

    -- FOOD CONTAINERS
    ["ss:cup_wood"] = {
        {cooldown = "action", duration = 2},
    },
    ["ss:cup_wood_water_murky"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -5, iterations = 10, interval = 1},
        {stat = "poison", amount = 10, iterations = 10, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:cup_wood_water_boiled"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -0.5, iterations = 1, interval = 1},
        {stat = "poison", amount = 1, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:bowl_wood"] = {
        {cooldown = "action", duration = 2},
    },
    ["ss:bowl_wood_water_murky"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -150, iterations = 10, interval = 1},
        {stat = "poison", amount = 10, iterations = 10, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:bowl_wood_water_boiled"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -0.5, iterations = 1, interval = 1},
        {stat = "poison", amount = 1, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:jar_glass"] = {
        {cooldown = "action", duration = 3},
    },
    ["ss:jar_glass_water_murky"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -5, iterations = 10, interval = 1},
        {stat = "poison", amount = 10, iterations = 10, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:jar_glass_water_boiled"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -0.5, iterations = 1, interval = 1},
        {stat = "poison", amount = 1, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:jar_glass_lidless"] = {
        {cooldown = "action", duration = 3},
    },
    ["ss:jar_glass_lidless_water_murky"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -5, iterations = 10, interval = 1},
        {stat = "poison", amount = 10, iterations = 10, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:jar_glass_lidless_water_boiled"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -0.5, iterations = 1, interval = 1},
        {stat = "poison", amount = 1, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:pot_iron"] = {
        {cooldown = "action", duration = 4},
    },
    ["ss:pot_iron_water_murky"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -5, iterations = 10, interval = 1},
        {stat = "poison", amount = 10, iterations = 10, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:pot_iron_water_boiled"] = {
        {stat = "thirst", amount = 20, iterations = 20, interval = 1},
        {stat = "immunity", amount = -0.5, iterations = 1, interval = 1},
        {stat = "poison", amount = 1, iterations = 1, interval = 1},
        {cooldown = "ingest", duration = 3},
    },

    -- MEDICAL
    ["ss:bandages_basic"] = {
        {stat = "health", amount = 3, iterations = 3, interval = 1},
        {cooldown = "action", duration = 4},
    },
    ["ss:bandages_medical"] = {
        {stat = "health", amount = 10, iterations = 10, interval = 1},
        {cooldown = "action", duration = 4},
    },
    ["ss:pain_pills"] = {
        {stat = "health", amount = 30, iterations = 30, interval = 1},
        {stat = "thirst", amount = -10, iterations = 3, interval = 1},
        {cooldown = "ingest", duration = 3},
    },
    ["ss:health_shot"] = {
        {stat = "health", amount = 30, iterations = 3, interval = 1},
        {cooldown = "action", duration = 3},
    },
    ["ss:first_aid_kit"] = {
        {stat = "health", amount = 50, iterations = 25, interval = 1},
        {cooldown = "action", duration = 5},
    },
    ["ss:splint"] = {
        {cooldown = "action", duration = 5},
        -- health data below are dummy values. the real data is applied by
        -- the custom_on_use() function
        --{stat = "health", amount = 0, iterations = 0, interval = 0},
    },
    ["ss:cast"] = {
        {cooldown = "action", duration = 5},
        -- health data below are dummy values. the real data is applied by
        -- the custom_on_use() function
        --{stat = "health", amount = 0, iterations = 0, interval = 0},
    },
}
local CONSUMABLE_ITEMS = ss.CONSUMABLE_ITEMS


ss.COOLDOWN_TEXT = {
    ingest = "* mouth is still full *",
    action = "* hands are still busy *"
}
local COOLDOWN_TEXT = ss.COOLDOWN_TEXT


local flag4 = false
--- @param player ObjectRef the player object
--- @param player_meta MetaDataRef used to access various player meta data
--- @param stat_update_data table data relating to how one or more stats will be updated
function ss.apply_stat_updates(player, player_meta, item_name, stat_update_data, cooldown_type, cooldown_time)
    debug(flag4, "  apply_stat_updates()")
    local player_name = player:get_player_name()
    local valid_stat_updates = 0

    --[[ 'stat_update_data' is the subtable from 'CONSUMABLE_ITEMS' that corresponded
    to the item name that was consumed. the subtable contains more subtables which
    each represent a stat to be modified. example:
    {
        {stat = "hunger", amount = 2, iterations = 2, interval = 1},
        {stat = "immunity", amount = 0.75, iterations = 1, interval = 1},
    }
    --]]

    for i, update_data in ipairs(stat_update_data) do
        local update_data_copy = table_copy(update_data)
        local stat = update_data.stat
        local amount = update_data_copy.amount
        local iterations = update_data_copy.iterations
        local interval = update_data_copy.interval
        local stat_current = player_meta:get_float(stat .. "_current")
        local stat_max = player_meta:get_float(stat .. "_max")
        --debug(flag4, "    stat: " .. stat)

        local stat_update_valid = false
        if amount > 0 then
            --debug(flag4, "    attempt to increase stat")
            if stat_current < (stat_max - 0.5) then
                --debug(flag4, "    " .. stat .. " can be increased")
                stat_update_valid = true
            else
                --debug(flag4, "    " .. stat .. " already at max")
            end
        elseif amount < 0 then
            --debug(flag4, "    attempt to decrease stat")
            if stat_current > 0 then
                --debug(flag4, "    " .. stat .. " can be decreased")
                stat_update_valid = true
            else
                --debug(flag4, "    " .. stat .. " already at zero")
            end
        else
            --debug(flag4, "    'amount' is zero. no stat update performed.'")
        end

        if stat_update_valid then
            valid_stat_updates = valid_stat_updates + 1
            if stat == "hunger" and amount > 0 then
                amount = amount * player_data[player_name].hunger_rec_mod_digestinator
            elseif stat == "thirst" and amount > 0 then
                amount = amount * player_data[player_name].thirst_rec_mod_h2_oh_yeah
            elseif stat == "poison" and amount > 0 then
                amount = amount * player_data[player_name].poison_drain_mod_toxintanium
            end
            local update_data_2 = {"normal", stat, amount, iterations, interval, "curr", "add", true}
            update_stat(player, player_data[player_name], player_meta, update_data_2)
        end

    end

    if valid_stat_updates > 0 then
        play_sound("item_use", {item_name = item_name, player = player})
        start_item_cooldown(player, player_name, item_name, cooldown_time, cooldown_type)
    else
        notify(player, "inventory", "item not useful right now", NOTIFY_DURATION, 0.5, 0, 2)
    end

    debug(flag4, "  apply_stat_updates() end")
    return valid_stat_updates
end
local apply_stat_updates = ss.apply_stat_updates



local flag3 = false
local function update_consumed_item(player, player_meta, itemstack, item_name, cooldown_type)
    debug(flag3, "\n  update_consumed_item()")

    -- handle scenario if player tries to use item with stack count > 1
    local unused_items
    local item_meta = itemstack:get_meta()
    local remaining_uses = item_meta:get_int("remaining_uses")
    local quantity = itemstack:get_count()

    if quantity > 1 then
        --debug(flag3, "    stack count > 1")

        if remaining_uses > 1 then
            --debug(flag3, "    stack remaining_uses > 1")
            --debug(flag3, "    separating one item from the rest of the stack..")
            unused_items = ItemStack(itemstack:to_string())
            unused_items:take_item()
            itemstack:set_count(1)
            --debug(flag3, "    unused_items count: " .. unused_items:get_count())

            -- reduce 'remaining_uses' of the item
            --debug(flag3, "    remaining_uses: " .. remaining_uses)
            --debug(flag3, "    reducing item's remaining_uses..")
            remaining_uses = remaining_uses - 1
            --debug(flag3, "    updated remaining_uses: " .. remaining_uses)

            if remaining_uses > 0 then
                --debug(flag3, "    item still has contents")
                update_meta_and_description(item_meta, item_name, {"remaining_uses"}, {remaining_uses})

            else
                --debug(flag3, "    item used up. reducing inventory weight..")
                local item_weight = ITEM_WEIGHTS[item_name]
                --debug(flag3, "    item_weight: " .. item_weight)
                update_inventory_weight(player, -item_weight)
                --debug(flag3, "    decreased inventory weight by: " .. item_weight)

                -- 'on_use' function executes before the player swings their hand.
                -- this delay allows the swinging action to think the item is still
                -- wielded and thus does not play the swing swoosh sound
                mt_after(0.2, function()
                    after_player_check(player)
                    player:set_wielded_item(ItemStack(""))
                end)
            end

        else
            --debug(flag3, "    stack remaining_uses is 1")
            itemstack:take_item()

            --debug(flag3, "    reducing inventory weight..")
            local item_weight = ITEM_WEIGHTS[item_name]
            --debug(flag3, "    item_weight: " .. item_weight)
            update_inventory_weight(player, -item_weight)
            --debug(flag3, "    decreased inventory weight by: " .. item_weight)

        end

        -- if multi-quantity itemstack was used, there will be unused_items
        -- that should be placed back into the player's inventory
        if unused_items then
            --debug(flag3, "    unused items from the wielded stack remain")
            local player_inv = player:get_inventory()

            -- delay via core.after() ensures return statement executes first
            -- so that wielded item gets modified before the unused items are
            -- added back into inventory. otherwise, the wielded item will simply
            -- merge with the unused items.
            mt_after(0, function()
                --debug(flag3, "\n## core.after() item_consumption.lua")
                after_player_check(player)
                local unused_items_meta = unused_items:get_meta()
                local unused_items_uses = unused_items_meta:get_int("remaining_uses")
                if unused_items_uses > 1 then
                    --debug(flag3, "  all unused items placed into inventory")
                    local leftover_items = player_inv:add_item("main", unused_items)
                    if leftover_items:is_empty() then
                        --debug(flag3, "  all unused items placed into inventory")
                    else
                        --debug(flag3, "  inventory ran out of space")
                        drop_items_from_inventory(player, leftover_items)
                        --debug(flag3, "  dropped to ground leftover_items: "
                        --    .. leftover_items:get_name() .. " " .. leftover_items:get_count())
                    end
                else
                    local index = player:get_wield_index()
                    player_inv:set_stack("main", index, unused_items)
                    --debug(flag3, "  all unused items return to player's hands")
                end
                --debug(flag3, "## core.after() END")
            end)
        end

    else
        --debug(flag3, "    stack count is 1")

        if remaining_uses > 1 then
            --debug(flag3, "    stack remaining_uses > 1")

            -- reduce 'remaining_uses' of the item
            --debug(flag3, "    remaining_uses: " .. remaining_uses)
            --debug(flag3, "    reducing item's remaining_uses..")
            remaining_uses = remaining_uses - 1
            --debug(flag3, "    updated remaining_uses: " .. remaining_uses)

            if remaining_uses > 0 then
                --debug(flag3, "    item still has contents")
                update_meta_and_description(item_meta, item_name, {"remaining_uses"}, {remaining_uses})

            else
                itemstack:take_item()
                --debug(flag3, "    item used up. reducing inventory weight..")
                local item_weight = ITEM_WEIGHTS[item_name]
                --debug(flag3, "    item_weight: " .. item_weight)
                update_inventory_weight(player, -item_weight)
                --debug(flag3, "    decreased inventory weight by: " .. item_weight)

            end

        else
            --debug(flag3, "    stack remaining_uses is 1")
            itemstack:take_item()

            --debug(flag3, "    reducing inventory weight..")
            local item_weight = ITEM_WEIGHTS[item_name]
            --debug(flag3, "    item_weight: " .. item_weight)
            update_inventory_weight(player, -item_weight)
            --debug(flag3, "    decreased inventory weight by: " .. item_weight)

        end

    end

    if cooldown_type == "ingest" then
        start_try_noise(player, player_meta, cooldown_type)
    end

    debug(flag3, "  update_consumed_item() END")
end



local flag5 = false
local function custom_on_use(itemstack, player, item_name, stat_update_data, pointed_thing)
    debug(flag5, "\ncustom_on_use()")

    -- press aux1 key to use the item instead of just swinging it
    local controls = player:get_player_control()
    if controls.aux1 then
        --debug(flag5, "  pressing aux1. activating item use..")
        --debug(flag5, "  stat_update_data: " .. dump(stat_update_data))

        -- use a copy to avoid altering main ss.CONSUMABLE_ITEMS table
        local stat_update_data_copy = table_copy(stat_update_data)
        local table_size = #stat_update_data_copy
        -- retrieve cooldown information
        local cooldown_data = stat_update_data_copy[table_size]
        --debug(flag5, "  cooldown_data: " .. dump(cooldown_data))
        local cooldown_type = cooldown_data.cooldown
        local cooldown_duration = cooldown_data.duration
        --debug(flag5, "  cooldown_type: " .. cooldown_type)
        stat_update_data_copy[table_size] = nil

        local player_name = player:get_player_name()
        if is_cooldown_active[player_name][cooldown_type] then
            --debug(flag5, "  ** still in cooldown **")
            notify(player, "cooldown", COOLDOWN_TEXT[cooldown_type], 2, 0.5, 0, 2)

        else
            --debug(flag5, "  not in cooldown")
            local player_meta = player:get_meta()
            local do_stat_updates = false
            local stat_update_count = 0

            if item_name == "ss:splint" then
                --debug(flag5, "  using splint")
                local p_data = player_data[player_name]
                local status_effects = p_data.status_effects
                local legs_max = player_meta:get_float("legs_max")
                --debug(flag5, "  legs_max: " .. legs_max)
                local legs_ratio = p_data.legs_ratio
                --debug(flag5, "  legs_ratio: " .. legs_ratio)

                --debug(flag5, "  stat_update_data_copy: " .. dump(stat_update_data_copy))

                if status_effects.legs_2 then
                    --debug(flag5, "  leg is legs_2 'sprained'. proceed to splint to legs_4..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_2")
                    show_stat_effect(player, player_meta, player_name, p_data, "legs", 4, "basic", 0)
                    p_data.legs_recovery_status = 4
                    player_meta:set_int("legs_recovery_status", 4)

                    -- resture health based on total of how much was lost prior
                    table.insert(stat_update_data_copy, {
                        iterations = 5,
                        amount = math_min(p_data.legs_damage_total, 10),
                        stat = "health",
                        interval = 1
                    })
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)

                    -- 'legs_2' has value range from 61% to 80%. get the
                    -- value difference to 'sore' status and apply half of
                    -- that as an immediate restore amount for legs value.
                    local restore_ratio = (0.80 - legs_ratio) * 0.5
                    --debug(flag5, "  restore_ratio: " .. restore_ratio)
                    local new_legs_value = (legs_ratio + restore_ratio) * legs_max
                    --debug(flag5, "  new new_legs_value: " .. new_legs_value)
                    do_stat_update_action(player, p_data, player_meta, "normal", "legs", new_legs_value, "curr", "set", false)
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_4.notify_up, 2, 1.5, 0, 2)
                    do_stat_updates = true

                elseif status_effects.legs_3 then
                    --debug(flag5, "  leg is legs_3 'broken'. proceed to splint to legs_5..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "legs", 5, "basic", 0)
                    p_data.legs_recovery_status = 5
                    player_meta:set_int("legs_recovery_status", 5)

                    -- resture health based on total of how much was lost prior
                    -- according to 'legs_damage_total'
                    table.insert(stat_update_data_copy, {
                        iterations = 5,
                        amount = math_min(p_data.legs_damage_total, 10),
                        stat = "health",
                        interval = 1
                    })
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)

                    -- 'legs_3' has a ratio spread of 60, from 0% to 60%.
                    -- using splint will put in 'sprained' status which has
                    -- spread 19, from 61% to 80%. calculate the 'severity'
                    -- of leg_3 and use that ratio to calculate how much
                    -- legs value to add to the base 'sprained' ratio of 61%.
                    -- set that as the new legs value.
                    local severity_ratio = legs_ratio / 0.60
                    --debug(flag5, "  severity_ratio: " .. severity_ratio)
                    local new_legs_value = (0.61 + severity_ratio * 0.19) * legs_max
                    --debug(flag5, "  new_legs_value: " .. new_legs_value)
                    do_stat_update_action(player, p_data, player_meta, "normal", "legs", new_legs_value, "curr", "set", false)
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_5.notify_up, 2, 1.5, 0, 2)
                    do_stat_updates = true

                elseif status_effects.legs_4 then
                    notify(player, "inventory", "leg has a splint already", 2, 0, 0, 3)

                elseif status_effects.legs_5 then
                    notify(player, "inventory", "leg has a splint already", 2, 0, 0, 3)

                elseif status_effects.legs_6 then
                    notify(player, "inventory", "leg has a cast already", 2, 0, 0, 3)

                else
                    notify(player, "inventory", "leg not that injured", 2, 0, 0, 3)
                end

            elseif item_name == "ss:cast" then
                --debug(flag5, "  using cast")
                local p_data = player_data[player_name]
                local status_effects = p_data.status_effects
                local legs_max = player_meta:get_float("legs_max")
                --debug(flag5, "  legs_max: " .. legs_max)
                local legs_ratio = p_data.legs_ratio
                --debug(flag5, "  legs_ratio: " .. legs_ratio)
                if status_effects.legs_2 then
                    notify(player, "inventory", "leg is not broken", 2, 0, 0, 3)

                elseif status_effects.legs_3 then
                    --debug(flag5, "  leg is legs_3 'broken'. proceed to cast to legs_6..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_3")
                    show_stat_effect(player, player_meta, player_name, p_data, "legs", 6, "basic", 0)
                    p_data.legs_recovery_status = 6
                    player_meta:set_int("legs_recovery_status", 6)

                    -- resture health based on total of how much was lost prior
                    table.insert(stat_update_data_copy, {
                        iterations = 5,
                        amount = math_min(p_data.legs_damage_total, 20),
                        stat = "health",
                        interval = 1
                    })
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)

                    -- 'legs_3' has a ratio spread of 60, from 0% to 60%.
                    -- using cast will put in 'sprained' status which has
                    -- spread 19, from 61% to 80%. calculate the 'severity'
                    -- of leg_3 and use that ratio to calculate how much
                    -- legs value to add to the base 'sprained' ratio of 61%.
                    -- set that as the new legs value.
                    local severity_ratio = legs_ratio / 0.60
                    --debug(flag5, "  severity_ratio: " .. severity_ratio)
                    local new_legs_value = (0.61 + severity_ratio * 0.19) * legs_max
                    --debug(flag5, "  new_legs_value: " .. new_legs_value)
                    do_stat_update_action(player, p_data, player_meta, "normal", "legs", new_legs_value, "curr", "set", false)
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_6.notify_up, 2, 1.5, 0, 2)
                    do_stat_updates = true

                elseif status_effects.legs_4 then
                    notify(player, "inventory", "leg is not broken", 2, 0, 0, 3)

                elseif status_effects.legs_5 then
                    --debug(flag5, "  replacing splint with a cast on broken leg..")
                    hide_stat_effect(player, player_meta, player_name, p_data, status_effects, "legs_5")
                    show_stat_effect(player, player_meta, player_name, p_data, "legs", 6, "basic", 0)
                    p_data.legs_recovery_status = 6
                    player_meta:set_int("legs_recovery_status", 6)

                    -- resture health based on total of how much was lost prior
                    -- according to 'legs_damage_total'. however since leg was
                    -- recently casted, 'legs_damage_total' might still be 0 and
                    -- if that's the case, would cause notification to pop up that
                    -- 'item is not useful'. so allow at least 1 point of health
                    -- recovery at minimum.
                    if p_data.legs_damage_total == 0 then
                        p_data.legs_damage_total = 1
                    end
                    table.insert(stat_update_data_copy, {
                        iterations = 5,
                        amount = math_min(p_data.legs_damage_total, 20),
                        stat = "health",
                        interval = 1
                    })
                    p_data.legs_damage_total = 0
                    player_meta:set_float("legs_damage_total", 0)

                    -- legs value is current in 'sprained' range from 61% to 80%.
                    -- get the value difference to 'sore' status and apply half of
                    -- that as an immediate restore amount for legs value.
                    local restore_ratio = (0.80 - legs_ratio) * 0.5
                    --debug(flag5, "  restore_ratio: " .. restore_ratio)
                    local new_legs_value = (legs_ratio + restore_ratio) * legs_max
                    --debug(flag5, "  new new_legs_value: " .. new_legs_value)
                    do_stat_update_action(player, p_data, player_meta, "normal", "legs", new_legs_value, "curr", "set", false)
                    notify(player, "stat_effect", STATUS_EFFECT_INFO.legs_6.notify_up, 2, 1.5, 0, 2)
                    do_stat_updates = true

                elseif status_effects.legs_6 then
                    notify(player, "inventory", "leg has a cast already", 2, 0, 0, 3)

                else
                    notify(player, "inventory", "leg not that injured", 2, 0, 0, 3)
                end

            else
                --debug(flag5, "  item not relatd to leg repair")
                do_stat_updates = true
            end

            if do_stat_updates then
                -- attempt to alter one or more stats defined by the item's actions.
                -- 'stat_update_count' counts how many stats could be altered.
                stat_update_count = apply_stat_updates(
                    player,
                    player_meta,
                    item_name,
                    stat_update_data_copy,
                    cooldown_type,
                    cooldown_duration
                )
            end

            -- update quantity and/or any relevant metadata of the itemstack to
            -- signify the item was consumed
            if stat_update_count > 0 then
                update_consumed_item(player, player_meta, itemstack, item_name, cooldown_type)
            end

        end

    else
        --debug(flag5, "  swinging item as a generic craftitem..")
        pickup_item(player, pointed_thing)
    end

    debug(flag5, "custom_on_use() END")
    return itemstack
end


local items_to_override = {
    "ss:apple",
    "ss:apple_dried",
    "ss:blueberries",
    "ss:blueberries_dried",
    "ss:mushroom_brown",
    "ss:mushroom_brown_dried",
    "ss:mushroom_red",
    "ss:mushroom_red_dried",
    "ss:cactus",
    "ss:cactus_dried",
    "ss:meat_raw_beef",
    "ss:meat_raw_mutton",
    "ss:meat_raw_pork",
    "ss:meat_raw_poultry_large",
    "ss:bandages_basic",
    "ss:bandages_medical",
    "ss:pain_pills",
    "ss:health_shot",
    "ss:first_aid_kit",
    "ss:splint",
    "ss:cast"
}

local flag7 = false
-- go through each item in 'CONSUMABLE_ITEMS' table and override its on_use function
-- so that when that item is consumed or used it alters the player's stats based on
-- the data in 'stat_update_data'
debug(flag7, "## overriding consumable items ##")
for i, item_name in ipairs(items_to_override) do
    --debug(flag7, "  item_name: " .. item_name)
    core.override_item(item_name, {
        on_use = function(itemstack, user, pointed_thing)
            return custom_on_use(itemstack, user, item_name, CONSUMABLE_ITEMS[item_name], pointed_thing)
        end
    })
end