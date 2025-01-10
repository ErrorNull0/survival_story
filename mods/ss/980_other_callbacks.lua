print("- loading other_callbacks.lua")

-- cache global functions for faster access
local debug = ss.debug
local mt_serialize = minetest.serialize
local mt_get_gametime = minetest.get_gametime
local get_itemstack_weight = ss.get_itemstack_weight
local exceeds_inv_weight_max = ss.exceeds_inv_weight_max
local get_fs_weight = ss.get_fs_weight
local notify = ss.notify
local play_item_sound = ss.play_item_sound
local get_craftable_count = ss.get_craftable_count
local get_fs_craft_button = ss.get_fs_craft_button
local get_fs_ingred_box = ss.get_fs_ingred_box
local get_fs_crafting_grid = ss.get_fs_crafting_grid
local set_stat = ss.set_stat
local build_fs = ss.build_fs

-- cache global variables for faster access
local RECIPES = ss.RECIPES
local SPILLABLE_ITEM_NAMES = ss.SPILLABLE_ITEM_NAMES
local NOTIFICATIONS = ss.NOTIFICATIONS
local NOTIFY_DURATION = ss.NOTIFY_DURATION
local player_data = ss.player_data



-- this function exectues before the itemstack is added to the player inventory
local flag1 = false
minetest.register_on_item_pickup(function(itemstack, picker, pointed_thing, time_from_last_punch)
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
        notify(picker, NOTIFICATIONS.inv_space_full, NOTIFY_DURATION, "message_box_3")
        return itemstack
    end

    -- prevent item pickup if it will cause total inventory weight to exceed max
    if exceeds_inv_weight_max(itemstack, player_meta) then
        notify(picker, NOTIFICATIONS.inv_weight_max, NOTIFY_DURATION, "message_box_3")
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
            notify(picker, NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, "message_box_2")
            return itemstack
        end
    end

    -- add the itemstack to the player inventory
    player_inv:add_item("main", itemstack)
    play_item_sound("item_move", {item_name = itemstack:get_name(), player_name = player_name})

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

    -- update weight statbar hud to reflect addition of itemstack
    debug(flag1, "  Update weight statbar...")
    local weight = get_itemstack_weight(itemstack)
    set_stat(picker, player_meta, "weight", "up", weight)

    -- update inv weight formspec to reflect addition of itemstack
    debug(flag1, "  Update weight formspec...")
    fs.center.weight = get_fs_weight(picker)

    -- update recipe grid formspec based on the newly picked up itemstack
    debug(flag1, "  Update crafting grid and refresh inventory formspec")
    fs.right.craft_grid = get_fs_crafting_grid(player_name, player_inv, recipe_category)

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


local flag2 = false
minetest.register_on_player_hpchange(function(player, hp_change, reason)
    debug(flag2, "register_on_player_hpchange() other_callbacks.lua")
    debug(flag2, "  hp_change: " .. hp_change)

    -- the hp change event was caused by a built-in action like falling, drowning, etc.
    -- in this case, hook into the custom stat buffs system to alter the hp.
    if reason.from == "engine" then

        local direction, amount
        if hp_change == 0 then
            debug(flag2, "  hp unchanged")
            direction = "up"
            amount = hp_change

        elseif hp_change < 0 then
            debug(flag2, "  hp reduced")
            direction = "down"
            amount = -hp_change
        else
            debug(flag2, "  hp increased")
            direction = "up"
            amount = hp_change
        end

        set_stat(player, player:get_meta(), "health", direction, amount)

        -- return zero since 'ss.set_stat()' will modify player's hp directly
        return 0

    -- the hp change event was caused by calling the function 'player:set_hp()'
    -- directly, like via ss.set_stat() function. in this case, simply pass
    -- through the hp_change value.
    else
        return hp_change
    end

-- boolean parameter below set to 'true' which allows this function to call before the
-- player's hp is actually altered. thus, the return value specifies the actual hp_change
-- value that will impact the player's hp.
end, true)

