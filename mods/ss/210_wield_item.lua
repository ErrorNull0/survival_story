print("- loading wield_item.lua")

-- cache global functions for faster access
local debug = ss.debug
local notify = ss.notify
local mt_after = core.after
local mt_add_entity = core.add_entity

-- cache global variables for faster access
local ITEM_TOOLTIP = ss.ITEM_TOOLTIP
local job_handles = ss.job_handles
local player_data = ss.player_data

-- the name of the wield item from the previous check cycle
local wield_item_name_prev = {}

-- whether the player can see their own wield item entity (this custom one). this is not the
-- same as the standard wield item visual that is seen in first person.
local visible_to_owner = false

-- the name of the player's bone that the wield item is attached. refer to blender
-- model for bone names.
local wield_bone_default = "Hand_Right"

-- "y" is vertical from ground. -y upward, +y downward
-- "z" distance from player. -z farther forward, +z closer back
local wield_pos_default = {x = 0, y = 0.8, z = -2.2}

-- "y" controls pitch. -y pitch forward, +y pitch back
local wield_rot_default = {x = 90, y = 140, z = 90}

-- holds custom rotations for items that don't have diagonally oriented item icons,
-- or have custom rotations defined in their definition table. items not contained
-- here use the default rotation above.
local custom_rotations = {
    ["default:shovel_stone"] = {x = 90, y = 200, z = 90},
    ["ss:stone_sharpened"] = {x = 90, y = 170, z = 90},
    ["ss:cup_wood"] = {x = 90, y = 200, z = 90},
    ["ss:cup_wood_water_murky"] = {x = 90, y = 240, z = 90}
}


-- 'wield_item' defaults to ss:transparent_item but will change during gameplay
core.register_entity("ss:wield_item", {
    initial_properties = {
        --visual = "sprite",
		--visual_size = {x=1.0, y=1.0,},
		--textures = {"ss_snowball.png"},
		--collisionbox = {0, 0, 0, 0, 0, 0},

        -- ** tshooting **

        visual = "wielditem",
        visual_size = {x = 0.25, y = 0.25},
        wield_item = "ss:transparent_item",
        collisionbox = {0, 0, 0, 0, 0, 0},
        physical = false,
        pointable = false
    }
})



local flag5 = false
local function remove_wield_item(player)
    debug(flag5, "  remove_wield_item()")
    debug(flag5, "  child_entities: " .. dump(player:get_children()))

    local player_name = player:get_player_name()
    debug(flag5, "  checking for objects near ** " .. player_name .. " **")
    for object in core.objects_inside_radius(player:get_pos(), 10) do
        if object:is_player() then
            debug(flag5, "    this is player: " .. player_name)
        else
            local luaentity =  object:get_luaentity()
            local entity_name = luaentity.name
            if entity_name == "__builtin:item" then
                local dropped_item = ItemStack(luaentity.itemstring)
                local dropped_item_name = dropped_item:get_name()
                debug(flag5, "    this is a normal dropped item: " .. dropped_item_name)
            else
                if entity_name == "ss:wield_item" then
                    debug(flag5, "    this is a wield_item entity")
                    local parent = object:get_attach()
                    if parent then
                        local parent_name = parent:get_player_name()
                        debug(flag5, "    still attached to player: " .. parent_name)
                    else
                        debug(flag5, "    dropped to the ground. removing..")
                        object:remove()
                    end
                else
                    debug(flag5, "    this is some other entity: " .. entity_name)
                end
            end
        end
    end

    debug(flag5, "  remove_wield_item() END")
end



local flag1 = false
-- monitor wielded item slots and display item description when item is wielded
local function monitor_wield_items(player)
    debug(flag1, "\nmonitor_wield_items()")
    if not player:is_player() then
        debug(flag1, "  player no longer exists. function skipped.")
        return
    end

    local player_name = player:get_player_name()
    local wielded_item = player:get_wielded_item()
    local item_name = wielded_item:get_name()
    local item_name_prev = wield_item_name_prev[player_name] or ""

    if item_name == item_name_prev then
        debug(flag1, "  same wield item. no action.")

    else
        local child_entities = player:get_children()
        local wield_item_entity = child_entities[1]
        if item_name == "" then
            debug(flag1, "  changed wield item to EMPTY HANDS")
            if wield_item_entity then
                wield_item_entity:set_properties({ wield_item = "ss:transparent_item" })
            end

        else
            debug(flag1, "  changed wield item to " .. item_name)
            local item_description = ITEM_TOOLTIP[item_name]
            notify(player, item_description, 1, 0, 0, 1)
            if wield_item_entity then
                wield_item_entity:set_properties({wield_item = item_name})
                local rotation
                if custom_rotations[item_name] then
                    debug(flag1, "  update item wield entity with custom rotation")
                    rotation = custom_rotations[item_name]
                else
                    debug(flag1, "  update item wield entity with default rotation")
                    rotation = wield_rot_default
                end
                wield_item_entity:set_attach(player, wield_bone_default, wield_pos_default, rotation, visible_to_owner)
            end
        end
        wield_item_name_prev[player_name] = item_name
    end

    debug(flag1, "monitor_wield_items() end")
    local job_handle = mt_after(0.5, monitor_wield_items, player)
    job_handles[player_name].monitor_wield_items = job_handle
end


local flag2 = false
core.register_on_joinplayer(function(player)
    debug(flag2, "\nregister_on_joinplayer() wield_item.lua")

    if player_data[player:get_player_name()].player_status == 2 then
        debug(flag2, "  player is dead. wield item monitor skipped.")
        return
    end

    -- spawn wield item entity and attach it to the player
    mt_after(1, function()
        debug(flag2, "\n## spawning wield item ##")
        if not player:is_player() then
            debug(flag2, "  player no longer exists. function skipped.")
            return
        end

        remove_wield_item(player)

        local wield_item = mt_add_entity(wield_pos_default, "ss:wield_item")
        if wield_item then
            debug(flag2, "  new ss:wield_item spanwed")

            local current_wield_item_name = player:get_wielded_item():get_name()
            debug(flag2, "  current_wield_item_name: " .. current_wield_item_name)

            local rotation
            if custom_rotations[current_wield_item_name] then
                debug(flag2, "  getting custom rotation")
                rotation = custom_rotations[current_wield_item_name]
            else
                debug(flag2, "  getting default rotation")
                rotation = wield_rot_default
            end

            -- make wield item entity invisible if player currently not wielding anything
            if current_wield_item_name == "" then
                debug(flag2, "  was holding nothing. showing transparent wield item..")
                wield_item:set_properties({ wield_item = "ss:transparent_item" })

            -- set wield item entity to the name of currently wielded item
            else
                debug(flag2, "  showing existing wield item")
                wield_item:set_properties({ wield_item = current_wield_item_name })
            end

            debug(flag2, "  wield item spawned!")
            wield_item:set_attach(player, wield_bone_default, wield_pos_default, rotation, visible_to_owner)

            debug(flag2, "  checking for child entities..")
            local child_entities = player:get_children()
            debug(flag2, "    child_entities: " .. dump(child_entities))
            debug(flag2, "  checking for nearby objects")
            for object in core.objects_inside_radius(player:get_pos(), 1) do
                if object:is_player() then
                    debug(flag2, "    this is a player: " .. object:get_player_name())
                else
                    local luaentity =  object:get_luaentity()
                    local entity_name = luaentity.name
                    if entity_name == "__builtin:item" then
                        local dropped_item = ItemStack(luaentity.itemstring)
                        local dropped_item_name = dropped_item:get_name()
                        debug(flag2, "    this is a item: " .. dropped_item_name)
                    else
                        debug(flag2, "    this is a non-craftitem entity: " .. entity_name)
                    end
                end
            end
            mt_after(0, monitor_wield_items, player)

        else
            debug(flag2, "  wield item failed to spawn")
        end
    end)
    debug(flag2, "register_on_joinplayer() END")
end)


local flag3 = false
core.register_on_leaveplayer(function(player)
    debug(flag3, "\nregister_on_leaveplayer() wield_item.lua")
    local player_name = player:get_player_name()
    local job_handle = job_handles[player_name].monitor_wield_items
    if job_handle then
        job_handle:cancel()
        job_handles[player_name].monitor_wield_items = nil
        debug(flag3, "  cancelled monitor_wield_items() loop..")
    end
    remove_wield_item(player)
    debug(flag3, "register_on_leaveplayer() END")
end)


local flag4 = false
core.register_on_dieplayer(function(player)
    debug(flag4, "register_on_dieplayer() WIELD ITEM")
    local player_name = player:get_player_name()

    debug(flag4, "  cancel monitor_wield_items() loop..")
    local job_handle = job_handles[player_name].monitor_wield_items
    job_handle:cancel()
    job_handles[player_name].monitor_wield_items = nil

    debug(flag4, "  removing any attached entities from player")
    for _, child in ipairs(player:get_children()) do
        if not child:is_player() then
            child:set_detach()
            child:remove()
        end
    end
    debug(flag4, "register_on_dieplayer() END")
end)


local flag6 = false
core.register_on_respawnplayer(function(player)
    debug(flag6, "register_on_respawnplayer() WIELD ITEM")

    remove_wield_item(player)

    local wield_item = mt_add_entity(wield_pos_default, "ss:wield_item")
    if wield_item then
        debug(flag6, "  new ss:wield_item spanwed")

        local current_wield_item_name = player:get_wielded_item():get_name()
        debug(flag6, "  current_wield_item_name: " .. current_wield_item_name)

        local rotation
        if custom_rotations[current_wield_item_name] then
            debug(flag6, "  getting custom rotation")
            rotation = custom_rotations[current_wield_item_name]
        else
            debug(flag6, "  getting default rotation")
            rotation = wield_rot_default
        end

        -- make wield item entity invisible if player currently not wielding anything
        if current_wield_item_name == "" then
            debug(flag6, "  was holding nothing. showing transparent wield item..")
            wield_item:set_properties({ wield_item = "ss:transparent_item" })

        -- set wield item entity to the name of currently wielded item
        else
            debug(flag6, "  showing existing wield item")
            wield_item:set_properties({ wield_item = current_wield_item_name })
        end

        debug(flag6, "  wield item spawned!")
        wield_item:set_attach(player, wield_bone_default, wield_pos_default, rotation, visible_to_owner)

        debug(flag6, "  checking for child entities..")
        local child_entities = player:get_children()
        debug(flag6, "    child_entities: " .. dump(child_entities))
        debug(flag6, "  checking for nearby objects")
        for object in core.objects_inside_radius(player:get_pos(), 1) do
            if object:is_player() then
                debug(flag6, "    this is a player: " .. object:get_player_name())
            else
                local luaentity =  object:get_luaentity()
                local entity_name = luaentity.name
                if entity_name == "__builtin:item" then
                    local dropped_item = ItemStack(luaentity.itemstring)
                    local dropped_item_name = dropped_item:get_name()
                    debug(flag6, "    this is a item: " .. dropped_item_name)
                else
                    debug(flag6, "    this is a non-craftitem entity: " .. entity_name)
                end
            end
        end
        mt_after(0, monitor_wield_items, player)

    else
        debug(flag6, "  wield item failed to spawn")
    end


    debug(flag6, "register_on_respawnplayer() END")
end)