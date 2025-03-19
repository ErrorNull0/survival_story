<<<<<<< HEAD
print("- loading food_containers.lua")

-- cache global functions for faster access
local table_copy = table.copy
local vector_add = vector.add
local vector_multiply = vector.multiply
local mt_after = minetest.after
local mt_get_node_or_nil = minetest.get_node_or_nil
local debug = ss.debug
local use_item = ss.use_item
local update_inventory_weight = ss.update_inventory_weight
local drop_items_from_inventory = ss.drop_items_from_inventory
local update_meta_and_description = ss.update_meta_and_description
local notify = ss.notify
local play_item_sound = ss.play_item_sound
local start_try_noise = ss.start_try_noise
local start_item_cooldown = ss.start_item_cooldown
local pickup_item = ss.pickup_item

-- cache global variables for faster access
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local CONTAINER_WEAR_RATES = ss.CONTAINER_WEAR_RATES
local EMPTY_CONTAINERS = ss.EMPTY_CONTAINERS
local ITEM_USAGE_PATH = ss.ITEM_USAGE_PATH
local COVERED_CONTAINERS = ss.COVERED_CONTAINERS
local ITEM_MAX_USES = ss.ITEM_MAX_USES
local CONSUMABLE_ITEMS = ss.CONSUMABLE_ITEMS
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local COOLDOWN_TEXT = ss.COOLDOWN_TEXT
local item_use_cooldowns = ss.item_use_cooldowns


local CONSUMPTION_RESULT_ITEMS = {
    ["ss:cup_wood"] = ItemStack("ss:cup_wood_water_murky"),
    ["ss:cup_wood_water_murky"] = ItemStack("ss:cup_wood"),
    ["ss:cup_wood_water_boiled"] = ItemStack("ss:cup_wood"),
    ["ss:bowl_wood"] = ItemStack("ss:bowl_wood_water_murky"),
    ["ss:bowl_wood_water_murky"] = ItemStack("ss:bowl_wood"),
    ["ss:bowl_wood_water_boiled"] = ItemStack("ss:bowl_wood"),
    ["ss:jar_glass"] = ItemStack("ss:jar_glass_water_murky"),
    ["ss:jar_glass_water_murky"] = ItemStack("ss:jar_glass"),
    ["ss:jar_glass_water_boiled"] = ItemStack("ss:jar_glass"),
    ["ss:jar_glass_lidless"] = ItemStack("ss:jar_glass_lidless_water_murky"),
    ["ss:jar_glass_lidless_water_murky"] = ItemStack("ss:jar_glass_lidless"),
    ["ss:jar_glass_lidless_water_boiled"] = ItemStack("ss:jar_glass_lidless"),
    ["ss:pot_iron"] = ItemStack("ss:pot_iron_water_murky"),
    ["ss:pot_iron_water_murky"] = ItemStack("ss:pot_iron"),
    ["ss:pot_iron_water_boiled"] = ItemStack("ss:pot_iron")
}




-- returns the node player is looking at within 2 meters distance to help determine
-- if it's a water node
local function get_look_at_node(player)
    -- Get pos at player's eye level
    local player_pos = player:get_pos()
    player_pos.y = player_pos.y + 1.75  -- Adjust for eye level
    local look_direction = player:get_look_dir()

    -- Start at 0.5 look distance and increment in steps of 0.5 up to 2.0
    for look_range = 0.5, 2.0, 0.5 do
        local look_pos = vector_add(player_pos, vector_multiply(look_direction, look_range))
        local node = mt_get_node_or_nil(look_pos)
        if node and node.name ~= "air" then
            return node
        end
    end

    -- Return nil if no valid node is found within max_range
    return nil
end


local flag2 = false
local function custom_on_use(itemstack, user, item_name, stats_mod_data, pointed_thing)
    local food_container_name = itemstack:get_name()
    debug(flag2, "\n** Using food container: " .. food_container_name .. " **")
    debug(flag2, " pointed_thing: " .. dump(pointed_thing))

    -- press aux1 key to prevent using the item and instead pickup any nearby items
    local controls = user:get_player_control()
    if controls.aux1 then
        debug(flag2, "  pressing aux1. activating item use..")

        if EMPTY_CONTAINERS[food_container_name] then
            debug(flag2, "  this is an empty container")
            local node = get_look_at_node(user)
            if node then
                local node_name = node.name
                debug(flag2, "  clicked on node: " .. node_name)
                if NODE_NAMES_WATER[node_name] then
                    debug(flag2, "  filling container with murky water")

                    local cooldown_data = stats_mod_data.cooldown
                    debug(flag2, "  cooldown_data: " .. dump(cooldown_data))
                    local cooldown_type = cooldown_data[1]
                    debug(flag2, "  cooldown_type: " .. cooldown_type)
                    local cooldown_time = cooldown_data[2]
                    debug(flag2, "  cooldown_time: " .. cooldown_time)
                    local cooldown_active = false

                    local player_name = user:get_player_name()
                    if item_use_cooldowns[player_name][cooldown_type] then
                        debug(flag2, "  cooldown found in 'player_cooldowns' ")
                        cooldown_active = true
                    end

                    if cooldown_active then
                        debug(flag2, "  ** still in cooldown **")
                        notify(user, COOLDOWN_TEXT[cooldown_type], 2, "message_box_3")

                    else
                        debug(flag2, "  not in cooldown")

                        -- return any unused containers to the player inventory
                        local empty_container_count = itemstack:get_count()
                        debug(flag2, "  empty_container_count: " .. empty_container_count)
                        if empty_container_count > 1 then
                            local player_inv = user:get_inventory()
                            debug(flag2, "  reducing empty container count by 1")
                            local empty_containers = ItemStack({
                                name = food_container_name,
                                count = empty_container_count - 1
                            })

                            -- delay via minetest.after() ensures return statement executes
                            -- first so that wielded item can turn into the filled food
                            -- container. otherwise the empty container being wielded will
                            -- just merge with the remaining empty containers, and the stack
                            -- will become the filled container item.
                            mt_after(0, function()
                                debug(flag2, "\nminetest.after()")
                                debug(flag2, "  adding remaining empty containers to player inventory..")
                                local leftover_items = player_inv:add_item("main", empty_containers)
                                if leftover_items:get_count() > 0 then
                                    debug(flag2, "  no inventory space for empty containers. dropping to the ground.")
                                    drop_items_from_inventory(user, leftover_items)
                                else
                                    debug(flag2, "  " .. empty_containers:get_count() .. " empty containers placed into inventory")
                                end
                                debug(flag2, "\nminetest.after() END")
                            end)
                        end

                        -- increase inventory weight due to food filled into container
                        local empty_container_weight = ITEM_WEIGHTS[food_container_name]
                        debug(flag2, "  empty_container_weight: " .. empty_container_weight)

                        local filled_container = CONSUMPTION_RESULT_ITEMS[food_container_name]
                        local filled_container_name = filled_container:get_name()
                        debug(flag2, "  filled_container_name: " .. filled_container_name)
                        local filled_container_weight = ITEM_WEIGHTS[filled_container_name]
                        debug(flag2, "  filled_container_weight: " .. filled_container_weight)

                        local food_weight = filled_container_weight - empty_container_weight
                        debug(flag2, "  food_weight: " .. food_weight)
                        update_inventory_weight(user, "up", food_weight)
                        debug(flag2, "  increased inventory weight by: " .. food_weight)

                        -- initialize remaining_uses for this newly filled container
                        local filled_container_meta = filled_container:get_meta()
                        local remaining_uses = ITEM_MAX_USES[filled_container_name]

                        -- transfer condition of empty container to filled container
                        local item_meta = itemstack:get_meta()
                        local condition = item_meta:get_float("condition")
                        debug(flag2, "  condition: " .. condition)

                        -- update both remaining_uses and condition metadata
                        if condition > 0 then
                            update_meta_and_description(
                                filled_container_meta,
                                filled_container_name,
                                {"remaining_uses", "condition"},
                                {remaining_uses, condition}
                            )

                        -- update only remaining_uses metadata
                        else
                            update_meta_and_description(
                                filled_container_meta,
                                filled_container_name,
                                {"remaining_uses"},
                                {remaining_uses}
                            )
                        end

                        play_item_sound("item_use", {item_name = item_name, player = user})
                        start_item_cooldown(user, player_name, item_name, cooldown_time, cooldown_type)

                        itemstack = filled_container
                    end
                else
                    debug(flag2, "  cannot place that into food container. no action.")
                    play_item_sound("swing_container", {item_name = item_name, player = user})
                    pickup_item(user, pointed_thing)
                end
            else
                debug(flag2, "  no node within 2 meters was clicked")
                pickup_item(user, pointed_thing)
            end

        else
            debug(flag2, "  this is filled container")

            local cooldown_data = stats_mod_data.cooldown
            debug(flag2, "  cooldown_data: " .. dump(cooldown_data))

            local stats_mod_data_copy = table_copy(stats_mod_data)
            stats_mod_data_copy.cooldown = nil
            debug(flag2, "  stats_mod_data_copy: " .. dump(stats_mod_data_copy))

            local cooldown_type = cooldown_data[1]
            local cooldown_time = cooldown_data[2]
            debug(flag2, "  cooldown_type: " .. cooldown_type)
            local cooldown_active = false

            if item_use_cooldowns[user:get_player_name()][cooldown_type] then
                debug(flag2, "  cooldown found in 'player_cooldowns' ")
                cooldown_active = true
            end

            if cooldown_active then
                debug(flag2, "  ** still in cooldown **")
                notify(user, COOLDOWN_TEXT[cooldown_type], 2, "message_box_3")

            else
                debug(flag2, "  not in cooldown")
                local player_meta = user:get_meta()
                local is_success = use_item(
                    user,
                    player_meta,
                    item_name,
                    stats_mod_data_copy,
                    cooldown_type,
                    cooldown_time
                )
                if is_success then
                    -- handle scenario if player tries to use a stack of more than
                    -- one filled containers
                    local unused_items
                    local quantity = itemstack:get_count()
                    if quantity > 1 then
                        debug(flag2, "  separating one container from the rest of the stack..")
                        unused_items = ItemStack(itemstack:to_string())
                        unused_items:take_item()
                        itemstack:set_count(1)
                        debug(flag2, "  unused_items count: " .. unused_items:get_count())
                    end

                    -- reduce 'remaining_uses' of the container
                    debug(flag2, "  reducing item's remaining_uses..")
                    local container_meta = itemstack:get_meta()
                    local remaining_uses = container_meta:get_int("remaining_uses")
                    debug(flag2, "  remaining_uses: " .. remaining_uses)
                    remaining_uses = remaining_uses - 1
                    debug(flag2, "  updated remaining_uses: " .. remaining_uses)

                    if remaining_uses > 0 then
                        debug(flag2, "  food container still has contents")
                        update_meta_and_description(
                            container_meta,
                            food_container_name,
                            {"remaining_uses"},
                            {remaining_uses}
                        )

                    else
                        debug(flag2, "  food container now empty")
                        local empty_container = ITEM_USAGE_PATH[food_container_name]
                        local empty_container_name = empty_container:get_name()
                        debug(flag2, "  empty_container_name: " .. empty_container_name)
                        local empty_container_meta = empty_container:get_meta()

                        -- transfer condition of filled container to empty container
                        local condition = container_meta:get_float("condition")
                        debug(flag2, "  condition: " .. condition)

                        if condition > 0 then
                            debug(flag2, "  transferring condition to empty container..")
                            update_meta_and_description(
                                empty_container_meta,
                                empty_container_name,
                                {"condition"},
                                {condition}
                            )
                        end

                        -- reduce inventory weight due to container being emptied
                        local filled_container_weight = ITEM_WEIGHTS[food_container_name]
                        debug(flag2, "  filled_container_weight: " .. filled_container_weight)
                        local empty_container_weight = ITEM_WEIGHTS[empty_container_name]
                        debug(flag2, "  empty_container_weight: " .. empty_container_weight)
                        local food_weight = filled_container_weight - empty_container_weight
                        debug(flag2, "  food_weight: " .. food_weight)
                        update_inventory_weight(user, "down", food_weight)
                        debug(flag2, "  decreased inventory weight by: " .. food_weight)

                        --itemstack = empty_container

                        -- 'on_use' function executes before the player swings their hand.
                        -- this delay allows the swinging action to think the container is
                        -- still filled and does not play the swing swoosh sound
                        mt_after(0.2, function()
                            user:set_wielded_item(empty_container)
                        end)
                    end

                    -- if multi-quantity container stack was consumed, there will be unused_items
                    -- that should be placed back into the player's inventory
                    if unused_items then
                        debug(flag2, "  unused containers from the wielded stack remain")
                        local player_inv = user:get_inventory()

                        if COVERED_CONTAINERS[unused_items:get_name()] then
                            debug(flag2, "  these are covered containers and can go anywhere in player inventory")

                            -- delay via minetest.after() ensures return statment executes first
                            -- so that wielded item gets modified before the unused items are
                            -- added back into inventory. otherwise, the wielded item will simply
                            -- merge with the unused items.
                            mt_after(0, function()
                                local leftover_items = player_inv:add_item("main", unused_items)
                                if leftover_items:is_empty() then
                                    debug(flag2, "  all unused containers placed into inventory")
                                else
                                    debug(flag2, "  inventory ran out of space")
                                    drop_items_from_inventory(user, leftover_items)
                                    debug(flag2, "  dropped to ground leftover_items: "
                                        .. leftover_items:get_name() .. " " .. leftover_items:get_count())
                                end
                            end)
                        else

                            debug(flag2, "  these are uncovered containers and can only reside in hotbar")
                            local empty_slot_index
                            local wield_index = user:get_wield_index()
                            debug(flag2, "  wield_index: " .. wield_index)

                            for slot_index = 1, 8 do
                                if slot_index == wield_index then
                                    debug(flag2, "  slot #" .. slot_index .. ": this is wield item slot. skipped.")

                                else
                                    local slot_item = player_inv:get_stack("main", slot_index)
                                    if slot_item:is_empty() then
                                        debug(flag2, "  slot #" .. slot_index .. " empty slot")
                                        if empty_slot_index == nil then
                                            empty_slot_index = slot_index
                                        end

                                    else
                                        debug(flag2, "  slot #" .. slot_index .. " has items")
                                        local sample_slot_item = ItemStack(slot_item:to_string())
                                        sample_slot_item:set_count(1)
                                        debug(flag2, "    sample_slot_item: " .. sample_slot_item:get_name() .. " " .. sample_slot_item:get_count())
                                        local sample_unused_item = ItemStack(unused_items:to_string())
                                        sample_unused_item:set_count(1)
                                        debug(flag2, "    sample_unused_item: " .. sample_unused_item:get_name() .. " " .. sample_unused_item:get_count())

                                        if sample_slot_item:equals(sample_unused_item) then
                                            debug(flag2, "    ** items are identical ** attempting to merge stack..")
                                            local slot_free_space = slot_item:get_free_space()

                                            if slot_free_space > 0 then
                                                local unused_items_count = unused_items:get_count()
                                                if unused_items_count > slot_free_space then
                                                    local leftover_count = unused_items_count - slot_free_space
                                                    slot_item:set_count(slot_item:get_stack_max())
                                                    player_inv:set_stack("main", slot_index, slot_item)
                                                    debug(flag2, "    ** ITEMS MERGED - but not entirely **")
                                                    debug(flag2, "    leftover_count: " .. leftover_count)
                                                    unused_items:set_count(leftover_count)

                                                else
                                                    slot_item:set_count(slot_item:get_count() + unused_items_count)
                                                    player_inv:set_stack("main", slot_index, slot_item)
                                                    debug(flag2, "    ** ITEMS MERGED entirely **")
                                                    unused_items:set_count(0)
                                                    break
                                                end
                                            else
                                                debug(flag2, "    itemstack already at max count. skipping slot")
                                            end
                                        else
                                            debug(flag2, "    items are different. skipping slot.")
                                        end
                                    end
                                end
                            end

                            local unused_count = unused_items:get_count()
                            debug(flag2, "  all non-empty hotbar slots acted upon")
                            if unused_count > 0 then
                                debug(flag2, "  unused containers remain")
                                debug(flag2, "  remaining unused_items: " .. unused_items:get_name() .. " " .. unused_count)
                                if empty_slot_index then
                                    debug(flag2, "  empty slot at index " .. empty_slot_index .. " is avail")
                                    player_inv:set_stack("main", empty_slot_index, unused_items)
                                    debug(flag2, "  unused containers placed into empty slot")
                                else
                                    debug(flag2, "  no empty slots available either. dropping leftovers to the ground..")
                                    drop_items_from_inventory(user, unused_items)
                                end
                            else
                                debug(flag2, "  any/all unused containers accounted for")
                            end
                        end
                    end
                end

                start_try_noise(user, player_meta, cooldown_type)

            end
        end

    else
        debug(flag2, "  swinging item as a generic craftitem..")
        pickup_item(user, pointed_thing)
        debug(flag2, "custom_on_use() END")
    end

    return itemstack
end


for item_name, v in pairs(CONTAINER_WEAR_RATES) do
    minetest.override_item(item_name, {
        on_use = function(itemstack, user, pointed_thing)
            return custom_on_use(itemstack, user, item_name, CONSUMABLE_ITEMS[item_name], pointed_thing)
        end
    })
=======
print("- loading food_containers.lua")

-- cache global functions for faster access
local table_copy = table.copy
local vector_add = vector.add
local vector_multiply = vector.multiply
local mt_after = core.after
local mt_get_node_or_nil = core.get_node_or_nil
local debug = ss.debug
local apply_stat_updates = ss.apply_stat_updates
local update_inventory_weight = ss.update_inventory_weight
local drop_items_from_inventory = ss.drop_items_from_inventory
local update_meta_and_description = ss.update_meta_and_description
local notify = ss.notify
local play_sound = ss.play_sound
local start_try_noise = ss.start_try_noise
local start_item_cooldown = ss.start_item_cooldown
local pickup_item = ss.pickup_item

-- cache global variables for faster access
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local CONTAINER_WEAR_RATES = ss.CONTAINER_WEAR_RATES
local EMPTY_CONTAINERS = ss.EMPTY_CONTAINERS
local ITEM_USAGE_PATH = ss.ITEM_USAGE_PATH
local COVERED_CONTAINERS = ss.COVERED_CONTAINERS
local ITEM_MAX_USES = ss.ITEM_MAX_USES
local CONSUMABLE_ITEMS = ss.CONSUMABLE_ITEMS
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local COOLDOWN_TEXT = ss.COOLDOWN_TEXT
local is_cooldown_active = ss.is_cooldown_active


local CONSUMPTION_RESULT_ITEMS = {
    ["ss:cup_wood"] = ItemStack("ss:cup_wood_water_murky"),
    ["ss:cup_wood_water_murky"] = ItemStack("ss:cup_wood"),
    ["ss:cup_wood_water_boiled"] = ItemStack("ss:cup_wood"),
    ["ss:bowl_wood"] = ItemStack("ss:bowl_wood_water_murky"),
    ["ss:bowl_wood_water_murky"] = ItemStack("ss:bowl_wood"),
    ["ss:bowl_wood_water_boiled"] = ItemStack("ss:bowl_wood"),
    ["ss:jar_glass"] = ItemStack("ss:jar_glass_water_murky"),
    ["ss:jar_glass_water_murky"] = ItemStack("ss:jar_glass"),
    ["ss:jar_glass_water_boiled"] = ItemStack("ss:jar_glass"),
    ["ss:jar_glass_lidless"] = ItemStack("ss:jar_glass_lidless_water_murky"),
    ["ss:jar_glass_lidless_water_murky"] = ItemStack("ss:jar_glass_lidless"),
    ["ss:jar_glass_lidless_water_boiled"] = ItemStack("ss:jar_glass_lidless"),
    ["ss:pot_iron"] = ItemStack("ss:pot_iron_water_murky"),
    ["ss:pot_iron_water_murky"] = ItemStack("ss:pot_iron"),
    ["ss:pot_iron_water_boiled"] = ItemStack("ss:pot_iron")
}




-- returns the node player is looking at within 2 meters distance to help determine
-- if it's a water node
local function get_look_at_node(player)
    -- Get pos at player's eye level
    local player_pos = player:get_pos()
    player_pos.y = player_pos.y + 1.75  -- Adjust for eye level
    local look_direction = player:get_look_dir()

    -- Start at 0.5 look distance and increment in steps of 0.5 up to 2.0
    for look_range = 0.5, 2.0, 0.5 do
        local look_pos = vector_add(player_pos, vector_multiply(look_direction, look_range))
        local node = mt_get_node_or_nil(look_pos)
        if node and node.name ~= "air" then
            return node
        end
    end

    -- Return nil if no valid node is found within max_range
    return nil
end


local flag2 = false
local function custom_on_use(itemstack, user, item_name, stat_update_data, pointed_thing)
    local food_container_name = itemstack:get_name()
    debug(flag2, "\n** Using food container: " .. food_container_name .. " **")
    debug(flag2, " pointed_thing: " .. dump(pointed_thing))

    -- press aux1 key to prevent using the item and instead pickup any nearby items
    local controls = user:get_player_control()
    if controls.aux1 then
        debug(flag2, "  pressing aux1. activating item use..")

        if EMPTY_CONTAINERS[food_container_name] then
            debug(flag2, "  this is an empty container")
            local node = get_look_at_node(user)
            if node then
                local node_name = node.name
                debug(flag2, "  clicked on node: " .. node_name)
                if NODE_NAMES_WATER[node_name] then
                    debug(flag2, "  filling container with murky water")

                    local cooldown_data = stat_update_data[#stat_update_data]
                    debug(flag2, "  cooldown_data: " .. dump(cooldown_data))
                    local cooldown_type = cooldown_data.cooldown
                    debug(flag2, "  cooldown_type: " .. cooldown_type)
                    local cooldown_time = cooldown_data.duration
                    debug(flag2, "  cooldown_time: " .. cooldown_time)
                    local cooldown_active = false

                    local player_name = user:get_player_name()
                    if is_cooldown_active[player_name][cooldown_type] then
                        debug(flag2, "  cooldown found in 'player_cooldowns' ")
                        cooldown_active = true
                    end

                    if cooldown_active then
                        debug(flag2, "  ** still in cooldown **")
                        notify(user, COOLDOWN_TEXT[cooldown_type], 2, 0.5, 0, 2)

                    else
                        debug(flag2, "  not in cooldown")

                        -- return any unused containers to the player inventory
                        local empty_container_count = itemstack:get_count()
                        debug(flag2, "  empty_container_count: " .. empty_container_count)
                        if empty_container_count > 1 then
                            local player_inv = user:get_inventory()
                            debug(flag2, "  reducing empty container count by 1")
                            local empty_containers = ItemStack({
                                name = food_container_name,
                                count = empty_container_count - 1
                            })

                            -- delay via core.after() ensures return statement executes
                            -- first so that wielded item can turn into the filled food
                            -- container. otherwise the empty container being wielded will
                            -- just merge with the remaining empty containers, and the stack
                            -- will become the filled container item.
                            mt_after(0, function()
                                debug(flag2, "\ncore.after()")
                                if not user or user:get_player_name() == "" then
                                    debug(flag2, "  player no longer exists. function skipped.")
                                    return
                                end
                                debug(flag2, "  adding remaining empty containers to player inventory..")
                                local leftover_items = player_inv:add_item("main", empty_containers)
                                if leftover_items:get_count() > 0 then
                                    debug(flag2, "  no inventory space for empty containers. dropping to the ground.")
                                    drop_items_from_inventory(user, leftover_items)
                                else
                                    debug(flag2, "  " .. empty_containers:get_count() .. " empty containers placed into inventory")
                                end
                                debug(flag2, "\ncore.after() END")
                            end)
                        end

                        -- increase inventory weight due to food filled into container
                        local empty_container_weight = ITEM_WEIGHTS[food_container_name]
                        debug(flag2, "  empty_container_weight: " .. empty_container_weight)

                        local filled_container = CONSUMPTION_RESULT_ITEMS[food_container_name]
                        local filled_container_name = filled_container:get_name()
                        debug(flag2, "  filled_container_name: " .. filled_container_name)
                        local filled_container_weight = ITEM_WEIGHTS[filled_container_name]
                        debug(flag2, "  filled_container_weight: " .. filled_container_weight)

                        local food_weight = filled_container_weight - empty_container_weight
                        debug(flag2, "  food_weight: " .. food_weight)
                        update_inventory_weight(user, food_weight)
                        debug(flag2, "  increased inventory weight by: " .. food_weight)

                        -- initialize remaining_uses for this newly filled container
                        local filled_container_meta = filled_container:get_meta()
                        local remaining_uses = ITEM_MAX_USES[filled_container_name]

                        -- transfer condition of empty container to filled container
                        local item_meta = itemstack:get_meta()
                        local condition = item_meta:get_float("condition")
                        debug(flag2, "  condition: " .. condition)

                        -- update both remaining_uses and condition metadata
                        if condition > 0 then
                            update_meta_and_description(
                                filled_container_meta,
                                filled_container_name,
                                {"remaining_uses", "condition"},
                                {remaining_uses, condition}
                            )

                        -- update only remaining_uses metadata
                        else
                            update_meta_and_description(
                                filled_container_meta,
                                filled_container_name,
                                {"remaining_uses"},
                                {remaining_uses}
                            )
                        end

                        play_sound("item_use", {item_name = item_name, player = user})
                        start_item_cooldown(user, player_name, item_name, cooldown_time, cooldown_type)

                        itemstack = filled_container
                    end
                else
                    debug(flag2, "  cannot place that into food container. no action.")
                    play_sound("swing_container", {item_name = item_name, player = user})
                    pickup_item(user, pointed_thing)
                end
            else
                debug(flag2, "  no node within 2 meters was clicked")
                pickup_item(user, pointed_thing)
            end

        else
            debug(flag2, "  this is filled container")

            local table_size = #stat_update_data
            local cooldown_data = stat_update_data[table_size]
            debug(flag2, "  cooldown_data: " .. dump(cooldown_data))

            local stat_update_data_copy = table_copy(stat_update_data)
            stat_update_data_copy[table_size] = nil
            debug(flag2, "  stat_update_data_copy: " .. dump(stat_update_data_copy))

            local cooldown_type = cooldown_data.cooldown
            local cooldown_time = cooldown_data.duration
            debug(flag2, "  cooldown_type: " .. cooldown_type)
            local cooldown_active = false

            if is_cooldown_active[user:get_player_name()][cooldown_type] then
                debug(flag2, "  cooldown found in 'player_cooldowns' ")
                cooldown_active = true
            end

            if cooldown_active then
                debug(flag2, "  ** still in cooldown **")
                notify(user, COOLDOWN_TEXT[cooldown_type], 2, 0.5, 0, 2)

            else
                debug(flag2, "  not in cooldown")
                local player_meta = user:get_meta()
                local is_success = apply_stat_updates(
                    user,
                    player_meta,
                    item_name,
                    stat_update_data_copy,
                    cooldown_type,
                    cooldown_time
                )
                if is_success then
                    -- handle scenario if player tries to use a stack of more than
                    -- one filled containers
                    local unused_items
                    local quantity = itemstack:get_count()
                    if quantity > 1 then
                        debug(flag2, "  separating one container from the rest of the stack..")
                        unused_items = ItemStack(itemstack:to_string())
                        unused_items:take_item()
                        itemstack:set_count(1)
                        debug(flag2, "  unused_items count: " .. unused_items:get_count())
                    end

                    -- reduce 'remaining_uses' of the container
                    debug(flag2, "  reducing item's remaining_uses..")
                    local container_meta = itemstack:get_meta()
                    local remaining_uses = container_meta:get_int("remaining_uses")
                    debug(flag2, "  remaining_uses: " .. remaining_uses)
                    remaining_uses = remaining_uses - 1
                    debug(flag2, "  updated remaining_uses: " .. remaining_uses)

                    if remaining_uses > 0 then
                        debug(flag2, "  food container still has contents")
                        update_meta_and_description(
                            container_meta,
                            food_container_name,
                            {"remaining_uses"},
                            {remaining_uses}
                        )

                    else
                        debug(flag2, "  food container now empty")
                        local empty_container = ITEM_USAGE_PATH[food_container_name]
                        local empty_container_name = empty_container:get_name()
                        debug(flag2, "  empty_container_name: " .. empty_container_name)
                        local empty_container_meta = empty_container:get_meta()

                        -- transfer condition of filled container to empty container
                        local condition = container_meta:get_float("condition")
                        debug(flag2, "  condition: " .. condition)

                        if condition > 0 then
                            debug(flag2, "  transferring condition to empty container..")
                            update_meta_and_description(
                                empty_container_meta,
                                empty_container_name,
                                {"condition"},
                                {condition}
                            )
                        end

                        -- reduce inventory weight due to container being emptied
                        local filled_container_weight = ITEM_WEIGHTS[food_container_name]
                        debug(flag2, "  filled_container_weight: " .. filled_container_weight)
                        local empty_container_weight = ITEM_WEIGHTS[empty_container_name]
                        debug(flag2, "  empty_container_weight: " .. empty_container_weight)
                        local food_weight = filled_container_weight - empty_container_weight
                        debug(flag2, "  food_weight: " .. food_weight)
                        update_inventory_weight(user, -food_weight)
                        debug(flag2, "  decreased inventory weight by: " .. food_weight)

                        --itemstack = empty_container

                        -- 'on_use' function executes before the player swings their hand.
                        -- this delay allows the swinging action to think the container is
                        -- still filled and does not play the swing swoosh sound
                        mt_after(0.2, function()
                            if not user or user:get_player_name() == "" then
                                debug(flag2, "  player no longer exists. function skipped.")
                                return
                            end
                            user:set_wielded_item(empty_container)
                        end)
                    end

                    -- if multi-quantity container stack was consumed, there will be unused_items
                    -- that should be placed back into the player's inventory
                    if unused_items then
                        debug(flag2, "  unused containers from the wielded stack remain")
                        local player_inv = user:get_inventory()

                        if COVERED_CONTAINERS[unused_items:get_name()] then
                            debug(flag2, "  these are covered containers and can go anywhere in player inventory")

                            -- delay via core.after() ensures return statment executes first
                            -- so that wielded item gets modified before the unused items are
                            -- added back into inventory. otherwise, the wielded item will simply
                            -- merge with the unused items.
                            mt_after(0, function()
                                if not user or user:get_player_name() == "" then
                                    debug(flag2, "  player no longer exists. function skipped.")
                                    return
                                end
                                local leftover_items = player_inv:add_item("main", unused_items)
                                if leftover_items:is_empty() then
                                    debug(flag2, "  all unused containers placed into inventory")
                                else
                                    debug(flag2, "  inventory ran out of space")
                                    drop_items_from_inventory(user, leftover_items)
                                    debug(flag2, "  dropped to ground leftover_items: "
                                        .. leftover_items:get_name() .. " " .. leftover_items:get_count())
                                end
                            end)
                        else

                            debug(flag2, "  these are uncovered containers and can only reside in hotbar")
                            local empty_slot_index
                            local wield_index = user:get_wield_index()
                            debug(flag2, "  wield_index: " .. wield_index)

                            for slot_index = 1, 8 do
                                if slot_index == wield_index then
                                    debug(flag2, "  slot #" .. slot_index .. ": this is wield item slot. skipped.")

                                else
                                    local slot_item = player_inv:get_stack("main", slot_index)
                                    if slot_item:is_empty() then
                                        debug(flag2, "  slot #" .. slot_index .. " empty slot")
                                        if empty_slot_index == nil then
                                            empty_slot_index = slot_index
                                        end

                                    else
                                        debug(flag2, "  slot #" .. slot_index .. " has items")
                                        local sample_slot_item = ItemStack(slot_item:to_string())
                                        sample_slot_item:set_count(1)
                                        debug(flag2, "    sample_slot_item: " .. sample_slot_item:get_name() .. " " .. sample_slot_item:get_count())
                                        local sample_unused_item = ItemStack(unused_items:to_string())
                                        sample_unused_item:set_count(1)
                                        debug(flag2, "    sample_unused_item: " .. sample_unused_item:get_name() .. " " .. sample_unused_item:get_count())

                                        if sample_slot_item:equals(sample_unused_item) then
                                            debug(flag2, "    ** items are identical ** attempting to merge stack..")
                                            local slot_free_space = slot_item:get_free_space()

                                            if slot_free_space > 0 then
                                                local unused_items_count = unused_items:get_count()
                                                if unused_items_count > slot_free_space then
                                                    local leftover_count = unused_items_count - slot_free_space
                                                    slot_item:set_count(slot_item:get_stack_max())
                                                    player_inv:set_stack("main", slot_index, slot_item)
                                                    debug(flag2, "    ** ITEMS MERGED - but not entirely **")
                                                    debug(flag2, "    leftover_count: " .. leftover_count)
                                                    unused_items:set_count(leftover_count)

                                                else
                                                    slot_item:set_count(slot_item:get_count() + unused_items_count)
                                                    player_inv:set_stack("main", slot_index, slot_item)
                                                    debug(flag2, "    ** ITEMS MERGED entirely **")
                                                    unused_items:set_count(0)
                                                    break
                                                end
                                            else
                                                debug(flag2, "    itemstack already at max count. skipping slot")
                                            end
                                        else
                                            debug(flag2, "    items are different. skipping slot.")
                                        end
                                    end
                                end
                            end

                            local unused_count = unused_items:get_count()
                            debug(flag2, "  all non-empty hotbar slots acted upon")
                            if unused_count > 0 then
                                debug(flag2, "  unused containers remain")
                                debug(flag2, "  remaining unused_items: " .. unused_items:get_name() .. " " .. unused_count)
                                if empty_slot_index then
                                    debug(flag2, "  empty slot at index " .. empty_slot_index .. " is avail")
                                    player_inv:set_stack("main", empty_slot_index, unused_items)
                                    debug(flag2, "  unused containers placed into empty slot")
                                else
                                    debug(flag2, "  no empty slots available either. dropping leftovers to the ground..")
                                    drop_items_from_inventory(user, unused_items)
                                end
                            else
                                debug(flag2, "  any/all unused containers accounted for")
                            end
                        end
                    end
                end

                start_try_noise(user, player_meta, cooldown_type)

            end
        end

    else
        debug(flag2, "  swinging item as a generic craftitem..")
        pickup_item(user, pointed_thing)
        debug(flag2, "custom_on_use() END")
    end

    return itemstack
end


for item_name, v in pairs(CONTAINER_WEAR_RATES) do
    core.override_item(item_name, {
        on_use = function(itemstack, user, pointed_thing)
            return custom_on_use(itemstack, user, item_name, CONSUMABLE_ITEMS[item_name], pointed_thing)
        end
    })
>>>>>>> 7965987 (update to version 0.0.3)
end