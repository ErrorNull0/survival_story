print("- loading notifications.lua")

-- cache global functions for faster access
local debug = ss.debug
local mt_after = minetest.after

-- cache global variables for faster access
local NOTIFY_BOX_HEIGHT = ss.NOTIFY_BOX_HEIGHT
local CRAFTITEM_ICON = ss.CRAFTITEM_ICON
local player_hud_ids = ss.player_hud_ids
local job_handles = ss.job_handles
local item_use_cooldowns = ss.item_use_cooldowns


minetest.register_on_joinplayer(function(player)
    --print("register_on_joinplayer() NOTIFICATIONS.LUA")
    local player_name = player:get_player_name()

    -- background box for message_box_1
    player_hud_ids[player_name].message_box_1_bg = player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1},
        offset = {x = 0, y = -105},
        text = "",
        scale = {x = 225, y = NOTIFY_BOX_HEIGHT},
        alignment = {x = 0, y = 0}
    })

    -- message_box_1: white text that displays name of current wield item
    player_hud_ids[player_name].message_box_1 = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 1},
        offset = {x = 0, y = -105},
        text = "",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        number = 0xFFFFFF,
        style = 0
    })

    -- background box for message_box_2
    player_hud_ids[player_name].message_box_2_bg = player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1},
        offset = {x = 0, y = -130},
        text = "",
        scale = {x = 225, y = NOTIFY_BOX_HEIGHT},
        alignment = {x = 0, y = 0}
    })

    -- message_box_2: white text for general gameplay notifications
    player_hud_ids[player_name].message_box_2 = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 1},
        offset = {x = 0, y = -130},
        text = "",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        number = 0xFFFFFF,
        style = 1
    })

    -- background box for message_box_3
    player_hud_ids[player_name].message_box_3_bg = player:hud_add({
        type = "image",
        position = {x = 0.5, y = 1},
        offset = {x = 0, y = -155},
        text = "",
        scale = {x = 225, y = NOTIFY_BOX_HEIGHT},
        alignment = {x = 0, y = 0}
    })

    -- message_box_3: orange text notification indicating invalid action
    player_hud_ids[player_name].message_box_3 = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 1},
        offset = {x = 0, y = -155},
        text = "",
        alignment = {x = 0, y = 0},
        scale = {x = 100, y = 100},
        number = 0xFFAA33,
        style = 1
    })


    -- hud image of an hourglass that displays durring item use cooldown
    player_hud_ids[player_name].item_cooldown_hourglass = player:hud_add({
        type = "image",
        position = {x = 1, y = 1},
        offset = {x = 0, y = 0},
        text = "",
        scale = {x = 2, y = 2},
        alignment = {x = -1, y = -1}
    })

    -- hud image overlayed atop the hourglass (hud image above)
    player_hud_ids[player_name].item_cooldown_image = player:hud_add({
        type = "image",
        position = {x = 1, y = 1},
        offset = {x = -5, y = -5},
        text = "",
        scale = {x = 1, y = 1},
        alignment = {x = -1, y = -1}
    })

    --print("  player_hud_ids[player_name]: " .. dump(player_hud_ids[player_name]))
    --print("register_on_joinplayer() NOTIFICATIONS.LUA end")
end)




local flag21 = false
function ss.stop_item_cooldown(player, player_name, cooldown_type)
    debug(flag21, "\nstop_item_cooldown()")

    local hud_id = player_hud_ids[player_name].message_box_3
    local hud_id_bg = player_hud_ids[player_name].message_box_3_bg
    local hud_id_cooldown_hourglass = player_hud_ids[player_name].item_cooldown_hourglass
    local hud_id_cooldown_image = player_hud_ids[player_name].item_cooldown_image
    player:hud_change(hud_id, "text", "")
    player:hud_change(hud_id_bg, "text", "")
    player:hud_change(hud_id_cooldown_hourglass, "text", "")
    player:hud_change(hud_id_cooldown_image, "text", "")
    debug(flag21, "  removed any cooldown text or images being displayed")

    local job_handle = job_handles[player_name]["cooldown_" .. cooldown_type]
    if job_handle then
        debug(flag21, "  job handle still exists")
        job_handle:cancel()
        job_handles[player_name]["cooldown_" .. cooldown_type] = nil
    else
        debug(flag21, "  job handle doesn't exist")
    end
    --debug(flag21, "  job_handles: " .. dump(job_handles))

    item_use_cooldowns[player_name][cooldown_type] = nil
    debug(flag21, "  cooldown removed for " .. cooldown_type)
    --print("  player_cooldowns: " .. dump(item_use_cooldowns))

    debug(flag21, "stop_item_cooldown() END")
end
local stop_item_cooldown = ss.stop_item_cooldown




local flag26 = false
function ss.start_item_cooldown(player, player_name, item_name, cooldown_time, cooldown_type)
    debug(flag26, "    start_item_cooldown()")
    debug(flag26, "      cooldown_type: " .. cooldown_type)
    debug(flag26, "      cooldown_time: " .. cooldown_time)

    item_use_cooldowns[player_name][cooldown_type] = true

    local hud_id_cooldown_hourglass = player_hud_ids[player_name].item_cooldown_hourglass
    player:hud_change(hud_id_cooldown_hourglass, "text", "ss_hourglass.png")

    local hud_id_cooldown_image = player_hud_ids[player_name].item_cooldown_image
    local cooldown_item_image = CRAFTITEM_ICON[item_name]
    player:hud_change(hud_id_cooldown_image, "text", cooldown_item_image)

    -- Schedule removal of the cooldown after specified duration
    local job_handle = mt_after(cooldown_time, stop_item_cooldown, player, player_name, cooldown_type)
    job_handles[player_name]["cooldown_" .. cooldown_type] = job_handle
    debug(flag26, "      job scheduled to stop cooldown in " .. cooldown_time .. " seconds")
    --debug(flag20, "    job handles: " .. dump(job_handles[player_name]))

    debug(flag26, "    start_item_cooldown() END")
end



--[[ 
NOTES

Message Boxes:

There are 3 locations that notification messages will appear, which all are centered above
the player hotbar. 

"message_box_1" - closest above the hotbar in white text. typically displays the item name
of what is newly selected / weilded in the hotbar.

"message_box_2" - Positioned right above message_box_1 in white text. typically displays
informational messages that relating to a recent player action.

"message_box_3" - Positioned above message_box_2 in orange text. typically displays warning
messages triggered by an invalid player action or an event that negatively impacts the player.

Sound Effects:

A small chime is played whenever a notification is triggered for message box 2. An error beep
is played whenever a warning is triggered for message box 3.
--]]