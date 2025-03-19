print("- loading item_consumption.lua")

-- cache global functions for faster access
local table_copy = table.copy
local mt_after = core.after
local debug = ss.debug
local notify = ss.notify
local update_inventory_weight = ss.update_inventory_weight
local drop_items_from_inventory = ss.drop_items_from_inventory
local update_meta_and_description = ss.update_meta_and_description
local start_try_noise = ss.start_try_noise
local play_sound = ss.play_sound
local update_stat = ss.update_stat
local start_item_cooldown = ss.start_item_cooldown
local pickup_item = ss.pickup_item

-- cache global variables for faster access
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local COOLDOWN_TEXT = ss.COOLDOWN_TEXT
local NOTIFY_DURATION = ss.NOTIFY_DURATION
local CONSUMABLE_ITEMS = ss.CONSUMABLE_ITEMS
local player_data = ss.player_data
local is_cooldown_active = ss.is_cooldown_active


local flag4 = false
--- @param player ObjectRef the player object
--- @param player_meta MetaDataRef used to access various player meta data
--- @param stat_update_data table data relating to how one or more stats will be updated
function ss.apply_stat_updates(player, player_meta, item_name, stat_update_data, cooldown_type, cooldown_time)
    debug(flag4, "  apply_stat_updates()")
    local player_name = player:get_player_name()
    local valid_stat_updates = 0

    for i, update_data in ipairs(stat_update_data) do
        local update_data_copy = table_copy(update_data)
        local stat = update_data.stat
        local amount = update_data_copy.amount
        local iterations = update_data_copy.iterations
        local interval = update_data_copy.interval
        local stat_current = player_meta:get_float(stat .. "_current")
        local stat_max = player_meta:get_float(stat .. "_max")
        debug(flag4, "    stat: " .. stat)

        local stat_update_valid = false
        if amount > 0 then
            debug(flag4, "    attempt to increase stat")
            if stat_current < (stat_max - 0.5) then
                debug(flag4, "    " .. stat .. " can be increased")
                stat_update_valid = true
            else
                debug(flag4, "    " .. stat .. " already at max")
            end
        elseif amount < 0 then
            debug(flag4, "    attempt to decrease stat")
            if stat_current > 0 then
                debug(flag4, "    " .. stat .. " can be decreased")
                stat_update_valid = true
            else
                debug(flag4, "    " .. stat .. " already at zero")
            end
        else
            debug(flag4, "    'amount' is zero. no stat update performed.'")
        end

        if stat_update_valid then
            valid_stat_updates = valid_stat_updates + 1
            local update_data_2 = {"normal", stat, amount, iterations, interval, "curr", "add", true}
            update_stat(player, player_data[player_name], player_meta, update_data_2)
        end

    end

    if valid_stat_updates > 0 then
        play_sound("item_use", {item_name = item_name, player = player})
        start_item_cooldown(player, player_name, item_name, cooldown_time, cooldown_type)
    else
        notify(player, "item not useful right now", NOTIFY_DURATION, 0.5, 0, 2)
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
        debug(flag3, "    stack count > 1")

        if remaining_uses > 1 then
            debug(flag3, "    stack remaining_uses > 1")
            debug(flag3, "    separating one item from the rest of the stack..")
            unused_items = ItemStack(itemstack:to_string())
            unused_items:take_item()
            itemstack:set_count(1)
            debug(flag3, "    unused_items count: " .. unused_items:get_count())

            -- reduce 'remaining_uses' of the item
            debug(flag3, "    remaining_uses: " .. remaining_uses)
            debug(flag3, "    reducing item's remaining_uses..")
            remaining_uses = remaining_uses - 1
            debug(flag3, "    updated remaining_uses: " .. remaining_uses)

            if remaining_uses > 0 then
                debug(flag3, "    item still has contents")
                update_meta_and_description(item_meta, item_name, {"remaining_uses"}, {remaining_uses})

            else
                debug(flag3, "    item used up. reducing inventory weight..")
                local item_weight = ITEM_WEIGHTS[item_name]
                debug(flag3, "    item_weight: " .. item_weight)
                update_inventory_weight(player, -item_weight)
                debug(flag3, "    decreased inventory weight by: " .. item_weight)

                -- 'on_use' function executes before the player swings their hand.
                -- this delay allows the swinging action to think the item is still
                -- wielded and thus does not play the swing swoosh sound
                mt_after(0.2, function()
                    if not player:is_player() then
                        debug(flag3, "    player no longer exists. function skipped.")
                        return
                    end
                    player:set_wielded_item(ItemStack(""))
                end)
            end

        else
            debug(flag3, "    stack remaining_uses is 1")
            itemstack:take_item()

            debug(flag3, "    reducing inventory weight..")
            local item_weight = ITEM_WEIGHTS[item_name]
            debug(flag3, "    item_weight: " .. item_weight)
            update_inventory_weight(player, -item_weight)
            debug(flag3, "    decreased inventory weight by: " .. item_weight)

        end

        -- if multi-quantity itemstack was used, there will be unused_items
        -- that should be placed back into the player's inventory
        if unused_items then
            debug(flag3, "    unused items from the wielded stack remain")
            local player_inv = player:get_inventory()

            -- delay via core.after() ensures return statement executes first
            -- so that wielded item gets modified before the unused items are
            -- added back into inventory. otherwise, the wielded item will simply
            -- merge with the unused items.
            mt_after(0, function()
                debug(flag3, "\n## core.after() item_consumption.lua")
                if not player:is_player() then
                    debug(flag3, "  player no longer exists. function skipped.")
                    return
                end
                local unused_items_meta = unused_items:get_meta()
                local unused_items_uses = unused_items_meta:get_int("remaining_uses")
                if unused_items_uses > 1 then
                    debug(flag3, "  all unused items placed into inventory")
                    local leftover_items = player_inv:add_item("main", unused_items)
                    if leftover_items:is_empty() then
                        debug(flag3, "  all unused items placed into inventory")
                    else
                        debug(flag3, "  inventory ran out of space")
                        drop_items_from_inventory(player, leftover_items)
                        debug(flag3, "  dropped to ground leftover_items: "
                            .. leftover_items:get_name() .. " " .. leftover_items:get_count())
                    end
                else
                    local index = player:get_wield_index()
                    player_inv:set_stack("main", index, unused_items)
                    debug(flag3, "  all unused items return to player's hands")
                end
                debug(flag3, "## core.after() END")
            end)
        end

    else
        debug(flag3, "    stack count is 1")

        if remaining_uses > 1 then
            debug(flag3, "    stack remaining_uses > 1")

            -- reduce 'remaining_uses' of the item
            debug(flag3, "    remaining_uses: " .. remaining_uses)
            debug(flag3, "    reducing item's remaining_uses..")
            remaining_uses = remaining_uses - 1
            debug(flag3, "    updated remaining_uses: " .. remaining_uses)

            if remaining_uses > 0 then
                debug(flag3, "    item still has contents")
                update_meta_and_description(item_meta, item_name, {"remaining_uses"}, {remaining_uses})

            else
                itemstack:take_item()
                debug(flag3, "    item used up. reducing inventory weight..")
                local item_weight = ITEM_WEIGHTS[item_name]
                debug(flag3, "    item_weight: " .. item_weight)
                update_inventory_weight(player, -item_weight)
                debug(flag3, "    decreased inventory weight by: " .. item_weight)

            end

        else
            debug(flag3, "    stack remaining_uses is 1")
            itemstack:take_item()

            debug(flag3, "    reducing inventory weight..")
            local item_weight = ITEM_WEIGHTS[item_name]
            debug(flag3, "    item_weight: " .. item_weight)
            update_inventory_weight(player, -item_weight)
            debug(flag3, "    decreased inventory weight by: " .. item_weight)

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

    -- press aux1 key to prevent using the item and instead pickup any nearby items
    local controls = player:get_player_control()
    if controls.aux1 then
        debug(flag5, "  pressing aux1. activating item use..")
        --debug(flag5, "  stat_update_data: " .. dump(stat_update_data))

        -- use a copy so as not to alter any data in main ss.CONSUMABLE_ITEMS table
        local stat_update_data_copy = table_copy(stat_update_data)
        local table_size = #stat_update_data_copy
        -- retrieve cooldown information
        local cooldown_data = stat_update_data_copy[table_size]
        debug(flag5, "  cooldown_data: " .. dump(cooldown_data))
        local cooldown_type = cooldown_data.cooldown
        local cooldown_duration = cooldown_data.duration
        debug(flag5, "  cooldown_type: " .. cooldown_type)
        stat_update_data_copy[table_size] = nil

        local cooldown_active = false
        if is_cooldown_active[player:get_player_name()][cooldown_type] then
            debug(flag5, "  cooldown is active: " .. cooldown_type)
            cooldown_active = true
        end

        if cooldown_active then
            debug(flag5, "  ** still in cooldown **")
            notify(player, COOLDOWN_TEXT[cooldown_type], 2, 0.5, 0, 2)
        else
            debug(flag5, "  not in cooldown")
            local player_meta = player:get_meta()

            -- activate the stat update(s) that's tied to that consumed item
            local stat_update_count = apply_stat_updates(
                player, player_meta, item_name, stat_update_data_copy, cooldown_type, cooldown_duration
            )

            -- update the quantity and any other info relating to the consumed item
            if stat_update_count > 0 then
                update_consumed_item(player, player_meta, itemstack, item_name, cooldown_type)
            end
        end

    else
        debug(flag5, "  swinging item as a generic craftitem..")
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
    "ss:splint"
}

local flag7 = false
-- go through each item in 'CONSUMABLE_ITEMS' table and override its on_use function
-- so that when that item is consumed or used it alters the player's stats based on
-- the data in 'stat_update_data'
debug(flag7, "## overriding consumable items ##")
for i, item_name in ipairs(items_to_override) do
    debug(flag7, "  item_name: " .. item_name)
    core.override_item(item_name, {
        on_use = function(itemstack, user, pointed_thing)
            return custom_on_use(itemstack, user, item_name, CONSUMABLE_ITEMS[item_name], pointed_thing)
        end
    })
end