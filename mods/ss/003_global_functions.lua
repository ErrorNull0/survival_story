print("- loading global_functions.lua ")

-- cache global functions for faster access
local math_random = math.random
local math_floor = math.floor
local math_round = math.round
local math_min = math.min
local string_sub = string.sub
local string_len = string.len
local string_find = string.find
local string_upper = string.upper
local table_remove = table.remove
local table_insert = table.insert
local table_concat = table.concat
local mt_sound_play = core.sound_play
local mt_sound_stop = core.sound_stop
local mt_colorize = core.colorize
local mt_after = core.after
local mt_get_meta = core.get_meta
local mt_get_node = core.get_node
local mt_punch_node = core.punch_node
local mt_close_formspec = core.close_formspec
local mt_add_item = core.add_item
local mt_add_entity = core.add_entity
local mt_item_pickup = core.item_pickup
local mt_pos_to_string = core.pos_to_string
local mt_serialize = core.serialize
local mt_hash_node_position = core.hash_node_position
local mt_get_gametime = core.get_gametime

-- cache global variables for faster access
local ITEM_SOUNDS_USE = ss.ITEM_SOUNDS_USE
local ITEM_SOUNDS_INV = ss.ITEM_SOUNDS_INV
local ITEM_SOUNDS_BREAK = ss.ITEM_SOUNDS_BREAK
local ITEM_SOUNDS_MISS = ss.ITEM_SOUNDS_MISS
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local NODE_NAMES_SOLID_ALL = ss.NODE_NAMES_SOLID_ALL
local NODE_NAMES_NONSOLID_ALL = ss.NODE_NAMES_NONSOLID_ALL
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local ITEM_BURN_TIMES = ss.ITEM_BURN_TIMES
local COOK_THRESHOLD = ss.COOK_THRESHOLD
local WEAR_VALUE_MAX = ss.WEAR_VALUE_MAX
local ITEM_TOOLTIP = ss.ITEM_TOOLTIP
local SOUND_EFFECT_DURATION = ss.SOUND_EFFECT_DURATION
local formspec_viewers = ss.formspec_viewers
local player_data = ss.player_data
local job_handles = ss.job_handles
local player_hud_ids = ss.player_hud_ids
local itemdrop_bag_pos = ss.itemdrop_bag_pos


-- The height of the gray background box on which the notification text is
-- displayed on top of
ss.NOTIFY_BOX_HEIGHT = 25
local NOTIFY_BOX_HEIGHT = ss.NOTIFY_BOX_HEIGHT

-- Prints debug text to console for debugging and testing.
--- @param flag boolean whether to actually print the text to console
--- @param text string the text to be printed to the console
function ss.debug(flag, text)
	if flag then print(text) end
end
local debug = ss.debug


-- typically called inside core.after to check if player is still valid, and if not
-- quit the execution
function ss.after_player_check(player)
    if not player:is_player() then
        print("\n#### 'player' object not valid' ### ")
        return
	end
end
local after_player_check = ss.after_player_check

--[[ Workaround for player_control continuously sending input clicked/pressed when
a custom formspec is activated via right mouse button. this function is currently
used in formspecs for the campfire in cooking_stations.lua, stats wand in stats.lua,
and the itemdrop bag in itemdrop_bag.lua --]]
function ss.player_control_fix(player)
    player:set_look_horizontal(player:get_look_horizontal() + 0.001)
end


--[[ Create a string based on a Luanti pos vector {x = x_pos, y = y_pos, z = a_pos}.
This key string is commonly used as an index to a table to access data unique to that
position, like for node inventories. --]]
function ss.pos_to_key(pos)
    return pos.x .. "," .. pos.y .. "," .. pos.z
end
local pos_to_key = ss.pos_to_key


--[[ Reverses the output from 'pos_to_key()' where it takes the key string and
constructs the standard Luanti position table. --]]
function ss.key_to_pos(key)
    local x, y, z = key:match("([^,]+),([^,]+),([^,]+)")
    return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
end


--- @param number number the float number that will be rounded
--- @param decimal_places number how many decimal places to the right to round 'value'
--- @return number - the rounded float number 'value'
function ss.round(number, decimal_places)
    if decimal_places then
        local factor = 10 ^ decimal_places
        return math_floor(number * factor + 0.5) / factor
    else
        return math_floor(number + 0.5)
    end
end
local round = ss.round



-- returns a value between a and b, based on the t ratio
--- @param a number start value
--- @param b number end value
--- @param t number the progress ratio between 0 or 1
function ss.lerp(a, b, t)
    return a + (b - a) * t
end


--- @param temperature number temperature in fahrenheit
--- @param precision number how many decimal places to round
--- @param flag? boolean whether to return the temperature difference
function ss.convert_to_celcius(temperature, precision, flag)
    if flag then
        -- temperature difference
        return round(temperature * 5 / 9, precision)
    else
        -- actual temperature
        return round((temperature - 32) * 5 / 9, precision)
    end
end


local flag25 = false
-- return a y pos that a player or object can spawn in
function ss.get_valid_y_pos(pos)
    debug(flag25, "    ss.get_valid_y_pos() global_functions.lua")
    debug(flag25, "      pos: " .. mt_pos_to_string(pos))
    local y_pos = pos.y
    debug(flag25, "      y_pos: " .. y_pos)

    local node = mt_get_node(pos)
    local node_name = node.name
    debug(flag25, "      node_name: " .. node_name)

    if node_name == "ignore" then
        debug(flag25, "      pos is unloaded. skipped.")
        y_pos = nil

    elseif NODE_NAMES_SOLID_ALL[node_name] then
		debug(flag25, "      pos is a solid node. checking next pos above..")
        return ss.get_valid_y_pos({x = pos.x, y = pos.y + 1, z = pos.z})

	elseif NODE_NAMES_NONSOLID_ALL[node_name] then
		debug(flag25, "      pos is non solid. this y pos is valid.")

	else
		debug(flag25, "      ERROR - node is not recognized in any global 'NODE_NAMES' table: " .. node_name)
	end

    debug(flag25, "    ss.get_valid_y_pos() END")
    return y_pos
end


local flag17 = false
function ss.is_underwater(player)
    debug(flag17, "    is_underwater()")
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    local is_underwater

    -- when crouching the head height should be 1 meter lower
    local current_anim = p_data.current_anim_state
    debug(flag17, "      current_anim_state: " .. current_anim)
    local head_height
    if string_sub(current_anim, 1, 6) == "crouch" then
        debug(flag17, "      player crouched")
        head_height = 0.5
    else
        debug(flag17, "      player not crouched")
        head_height = 1.5
    end

    -- get the node name that is at player's head height
    local pos = player:get_pos()
    pos.y = pos.y + head_height
    local node = mt_get_node(pos)
    local node_name = node.name
    debug(flag17, "      node_name: " .. node_name)

    if NODE_NAMES_WATER[node_name] then
        debug(flag17, "      player underwater")
        is_underwater = true
    else
        debug(flag17, "      player not underwater")
        is_underwater = false
    end

    debug(flag17, "    is_underwater() END")
    return is_underwater
end
local is_underwater = ss.is_underwater


local flag20 = false
--- @param action string the trigger of the sound event: 'move', 'use', or 'drop'
--- @param sound_data table contains data relevant to the 'action' parameter
function ss.play_sound(action, sound_data)
    debug(flag20, "  ss.play_sound()")
    debug(flag20, "    action: " .. action)

    if action == "item_move" then
        local sound_file = ITEM_SOUNDS_INV[sound_data.item_name]
        if sound_file then
            mt_sound_play(sound_file, {gain = 0.3, to_player = sound_data.player_name}, true)
        end

    elseif action == "item_use" then
        after_player_check(sound_data.player)
        local sound_file = ITEM_SOUNDS_USE[sound_data.item_name]
        if sound_file then
            mt_sound_play(sound_file, {
                object = sound_data.player,
                max_hear_distance = 10
            }, true)
        end

    elseif action == "item_break" then
        local sound_file = ITEM_SOUNDS_BREAK[sound_data.item_name]
        if sound_file then
            mt_sound_play(sound_file, {
                pos = sound_data.pos,
                max_hear_distance = 10
            }, true)
        end

    elseif action == "swing_container" then
        after_player_check(sound_data.player)
        local sound_file = ITEM_SOUNDS_MISS[sound_data.item_name]
        if sound_file then
            mt_sound_play(sound_file, {
                object = sound_data.player,
                max_hear_distance = 10
            }, true)
        end

    elseif action == "item_drop" then
        after_player_check(sound_data.player)
        mt_sound_play("ss_action_drop_item", {gain = 0.3, object = sound_data.player, max_hear_distance = 10}, true)

    elseif action == "button" then
        mt_sound_play("ss_ui_click1", {gain = 0.5, to_player = sound_data.player_name}, true)

    elseif action == "notify_info" then
        mt_sound_play("ss_notify_info", {gain = 0.5, to_player = sound_data.player_name}, true)

    elseif action == "notify_warning" then
        mt_sound_play("ss_notify_warning", {gain = 0.1, to_player = sound_data.player_name}, true)

    elseif action == "bundle_open" then
        mt_sound_play( "ss_item_bundle_open", {to_player = sound_data.player_name}, true)

    elseif action == "bundle_close" then
        mt_sound_play("ss_item_bundle_close", {to_player = sound_data.player_name}, true)

    elseif action == "bundle_cancel" then
        mt_sound_play("ss_ui_cloth", {to_player = sound_data.player_name}, true)

    elseif action == "bag_open" then
        mt_sound_play("ss_ui_cloth", {
            pos = sound_data.pos,
            max_hear_distance = 10,
        }, true)

    elseif action == "campfire_open" then
        mt_sound_play("ss_inv_wood_pile", {
            pos = sound_data.pos,
            max_hear_distance = 10,
        }, true)

    elseif action == "campfire_start" then
        mt_sound_play("ss_flame_burn", {
            pos = sound_data.pos,
            max_hear_distance = 10,
        }, true)

    elseif action == "campfire_stop" then
        mt_sound_play("ss_flame_douse", {
            pos = sound_data.pos,
            max_hear_distance = 10,
        }, true)

    elseif action == "campfire_cooked" then
        mt_sound_play("ss_item_cooked", {
            gain = 0.6,
            pos = sound_data.pos,
            max_hear_distance = 10,
        }, true)

    elseif action == "vocal_sound" then
        after_player_check(sound_data.player)
        local p_data = sound_data.p_data
        local filename = sound_data.sound_file
        mt_sound_play(filename, {
            gain = math_random(80,100) / 100,
            pitch = math_random(95,105) / 100,
            object = sound_data.player,
            max_hear_distance = 10
        }, true)
        p_data.player_vocalizing = true
        mt_after(SOUND_EFFECT_DURATION[filename], function()
            p_data.player_vocalizing = false
        end)

    elseif action == "stat_effect" then
        local player = sound_data.player
        local p_data = sound_data.p_data
        local stat = sound_data.stat
        local severity_direction = sound_data.severity
        local delay = sound_data.delay

        debug(flag20, "    stat: " .. stat)

        mt_after(delay, function()
            debug(flag20, "  ss.play_sound >> core.after()")
            after_player_check(player)

            -- don't player most stat effect sounds while underwater
            if p_data.water_level >= 90 then
                debug(flag20, "    player is 90% submerged")
                if stat == "hunger" then
                    if severity_direction == "up" then
                        debug(flag20, "    player getting hungrier while underwater")
                    else
                        debug(flag20, "    player getting less hugry while underwater. do not play relief sound.")
                        debug(flag20, "  core.after() END")
                        return
                    end
                elseif stat == "breath" then
                    debug(flag20, "    player losing breath underwater")
                else
                    debug(flag20, "    player activating non-hunger stat effect while underwater. do not play sound.")
                    debug(flag20, "  core.after() END")
                    return
                end
            end

            -- don't play stat effect sound if already playing a sound
            if p_data.player_vocalizing then
                debug(flag20, "    player is already vocalizing a sound")
                if stat == "hunger" then
                    if severity_direction == "up" then
                        debug(flag20, "    player getting hungrier while vocalizing")
                        -- allow stomach sound to play since it can overlap with vocal sounds
                    else
                        debug(flag20, "    player getting less hugry while vocalizing. do not play relief sound.")
                        debug(flag20, "  core.after() END")
                        return
                    end

                -- sneeze, cough, and vomit sounds will be allowd and override any
                -- current vocalized sounds
                elseif stat == "sneeze" then
                    debug(flag20, "    player sneezing. stopping current sound..")
                    core.sound_stop(p_data.sound_handle)
                elseif stat == "cough" then
                    debug(flag20, "    player coughing. stopping current sound..")
                    core.sound_stop(p_data.sound_handle)
                elseif stat == "vomit" then
                    debug(flag20, "    player vomitting. stopping current sound..")
                    core.sound_stop(p_data.sound_handle)

                else
                    debug(flag20, "    player activating non-hunger stat effect while vocalizing. do not play sound.")
                    debug(flag20, "  core.after() END")
                    return
                end
            end

            debug(flag20, "    player not already vocalizing a sound (or is sneezing)")
            p_data.player_vocalizing = true
            local sound_file
            local sound_duration
            local pitch = 1
            if severity_direction == "up" then
                debug(flag20, "    stat severity is up. play stat up sound")
                if stat == "breath" then
                    -- can't find good female drown sound, so using male sound with pitched increased
                    sound_file = "ss_stat_effect_breath_up_1"
                    pitch = 1.25
                    sound_duration = SOUND_EFFECT_DURATION["breath_1"]
                else
                    sound_file = "ss_stat_effect_" .. stat .. "_up_" .. p_data.body_type
                    sound_duration = SOUND_EFFECT_DURATION[stat .. "_" .. p_data.body_type]
                end

            elseif severity_direction == "down" then
                debug(flag20, "    stat severity is down")
                if stat == "breath" then
                    debug(flag20, "    stat is BREATH. play breath down sound.")
                    sound_file = "ss_stat_effect_breath_down_" .. p_data.body_type
                    sound_duration = SOUND_EFFECT_DURATION["breath_" .. p_data.body_type]
                else
                    debug(flag20, "    play stat down sound")
                    sound_file = "ss_stat_effect_down_" .. p_data.body_type
                    sound_duration = 0.8
                end

            else
                debug(flag20, "      ERROR - Unexpected 'severity_direction' value: " .. severity_direction)
            end
            p_data.sound_handle = mt_sound_play(sound_file,
                {object = sound_data.player, max_hear_distance = 10, pitch = pitch}
            )

            -- ensure no other 'vocalizing' type sounds are played until the duration
            -- of this sound is done playing, the sounds don't overlap and blend together
            mt_after(sound_duration, function()
                after_player_check(player)
                p_data.player_vocalizing = false
            end)


            debug(flag20, "  core.after() END")
        end)

    elseif action == "hit_mob" then
        if not sound_data.player or sound_data.player:get_player_name() == "" then
            debug(flag20, "    player no longer exists. function skipped.")
            return
        end
        local hit_type, attack_group, intensity
        hit_type = sound_data.hit_type
        attack_group = sound_data.attack_group
        intensity = sound_data.intensity
        local sound_file, sound_gain, sound_pitch
        -- player attack missed
        if hit_type == "miss" then
            sound_file = "ss_swoosh_fists"
            sound_pitch = (100 + math_random(-20, 20)) / 100
            sound_gain = math_random(80, 100) / 100
        else
            local target_type = "flesh"
            if intensity < 0.75 then
                sound_gain = 0.5
                sound_pitch = 0.8
            else
                sound_gain = math_random(80, 100) / 100
                sound_pitch = (100 + math_random(-10, 10)) / 100
            end
            -- hit_type: always 'hit' for now
            -- target_type: always 'flesh' for now
            -- attack_group: 'fists, 'blade', 'blunt', 'mining' via attack_group.txt
            sound_file = table_concat({ hit_type, "_", target_type, "_", attack_group })
        end
        debug(flag20, "    sound_file: " .. sound_file)
        mt_sound_play(sound_file, {
            gain = sound_gain,
            pitch = sound_pitch,
            object = sound_data.player,
            max_hear_distance = 10
        }, true)

    else
        debug(flag20, "    ERROR - Unexpected 'action' value: " .. action)
    end


    debug(flag20, "  ss.play_sound() END")
end
local play_sound = ss.play_sound


local flag6 = false
-- Used by ss.notify() to remove the text notification that was initially displayed.
--- @param player ObjectRef the player object
--- @param player_name string player's name. for single player it's 'singleplayer'
--- @param hud_id number an integer ID representing the text part of the notification
--- @param hud_id_bg number an integer ID representing the background box of the notification
--- @param notify_box string which of the 3 locations to display the text
local function clear_notify_box(player, player_name, hud_id, hud_id_bg, notify_box)
    debug(flag6, "clear_notify_box()")
    after_player_check(player)

    player:hud_change(hud_id, "text", "")
    player:hud_change(hud_id_bg, "text", "")

    local job_handle = job_handles[player_name]["notify_box_" .. notify_box]
    if job_handle then
        job_handle:cancel()
        job_handles[player_name]["notify_box_" .. notify_box] = nil
        debug(flag6, "  cleared notify_box " .. notify_box)
    else
        debug(flag6, "  already cleared due to death: " .. notify_box)
    end

    debug(flag6, "clear_notify_box() END")
end


local flag1 = false
-- Displays a notification 'text' above the player hotbar within the designated
-- 'notify_box' which there are three. Each target box is slighly higher above
-- the hotbar than the previous one, with its own type of color and font style.
-- 'trigger' values: inventory, stat_effect, cooldown, mobs, wield_item, noise,
-- remaining_uses, hammer, system, error
--- @param player ObjectRef the player object
--- @param trigger string the trigger or source of this notification
--- @param text string the text notification to display on screen
--- @param duration number how many seconds the notification with show on screen
--- @param delay_sound number how many seconds to wait before activating the sound effect and text
--- @param delay_text number how many seconds after the sound effect to display the text
--- @param notify_box number '3' is positioned above '2' which is above '1' and all above the hotbar
--- @param breath_flag? boolean 'true' when this was called due to breath stat effect activation
function ss.notify(player, trigger, text, duration, delay_sound, delay_text, notify_box, breath_flag)
    debug(flag1, "\nss.notify()")
    debug(flag1, "  duration " .. duration .. " | delay_sound " .. delay_sound
        .. " | delay_text " .. delay_text .. " | notify_box " .. notify_box)
    debug(flag1, "  text: " .. text)

    local player_name = player:get_player_name()
    debug(flag1, "  player_name: " .. player_name)

    -- play the notification sound effect
    mt_after(delay_sound, function()
        debug(flag1, "\nnotify() >> mt_after() >> play sound")
        after_player_check(player)

        if notify_box == 1 then
            debug(flag1, "  notify_box 1: no sound will be played")

        elseif notify_box == 2 then
            debug(flag1, "  notify_box 2: playing ding sound")

                -- exit early if this notification trigger is disabled (from Settings tab)
                local p_data = player_data[player_name]
                if trigger == "inventory" and p_data.notify_active_inventory == 0 then
                    debug(flag1, "  inventory notifications disabled")
                    debug(flag1, "ss.notify() END")
                    return
                elseif trigger == "stat_effect" and p_data.notify_active_stat_effects == 0 then
                    debug(flag1, "  status effect notifications disabled")
                    debug(flag1, "ss.notify() END")
                    return
                elseif trigger == "cooldown" and p_data.notify_active_cooldowns == 0 then
                    debug(flag1, "  cooldown notifications disabled")
                    debug(flag1, "ss.notify() END")
                    return
                elseif trigger == "mobs" and p_data.notify_active_mobs == 0 then
                    debug(flag1, "  mobs notifications disabled")
                    debug(flag1, "ss.notify() END")
                    return
                elseif trigger == "error" and p_data.notify_active_errors == 0 then
                    debug(flag1, "  error notifications disabled")
                    debug(flag1, "ss.notify() END")
                    return
                else
                    debug(flag1, "  unimplemented 'trigger' type:" .. trigger)
                end

            -- indicates that this call to notify() was from activation of breath
            -- status effect from do_stat_update_action(). since this text displays
            -- after a delay, check if player is still actually underwater. if not,
            -- cancel out this notify for the breath stat effect.
            if breath_flag then
                debug(flag1, "  this notify came from a breath stat effect")
                if not is_underwater(player) then
                    debug(flag1, "  player no longer underwater. cancel notification.")
                    debug(flag1, "ss.notify() END")
                    return
                end
            end

            play_sound("notify_info", {player_name = player_name})

        elseif notify_box == 3 then
            debug(flag1, "  notify_box 3: playing buzz sound")
            play_sound("notify_warning", {player_name = player_name})

            -- exit early if this notification trigger is disabled (from Settings tab)
            local p_data = player_data[player_name]
            if trigger == "inventory" and p_data.notify_active_inventory == 0 then
                debug(flag1, "  inventory notifications disabled")
                debug(flag1, "ss.notify() END")
                return
            elseif trigger == "stat_effect" and p_data.notify_active_stat_effects == 0 then
                debug(flag1, "  status effect notifications disabled")
                debug(flag1, "ss.notify() END")
                return
            elseif trigger == "cooldown" and p_data.notify_active_cooldowns == 0 then
                debug(flag1, "  cooldown notifications disabled")
                debug(flag1, "ss.notify() END")
                return
            elseif trigger == "mobs" and p_data.notify_active_mobs == 0 then
                debug(flag1, "  mobs notifications disabled")
                debug(flag1, "ss.notify() END")
                return
            elseif trigger == "error" and p_data.notify_active_errors == 0 then
                debug(flag1, "  error notifications disabled")
                debug(flag1, "ss.notify() END")
                return
            else
                debug(flag1, "  unimplemented 'trigger' type:" .. trigger)
            end

        else
            debug(flag1, "  ERROR - Unexpected 'notify_box' value: " .. notify_box)
        end

        -- display the notification text
        mt_after(delay_text, function()
            debug(flag1, "\nnotify() >> mt_after() >> show text")
            after_player_check(player)

            -- ensure any existing notification text is removed before showing this one
            local job_handle = job_handles[player_name]["notify_box_" .. notify_box]
            if job_handle then
                debug(flag1, "  message box " .. notify_box .. " currently in use")
                job_handle:cancel()
                job_handles[player_name]["notify_box_" .. notify_box] = nil
                debug(flag1, "  prior notification text removed")
            end

            -- the width of the black background box behind the notification text
            -- is based on the length of the text. some noitifications will pass
            -- hidden colorization tags imbedded into the notification text. compensate
            -- for this by excluding the colorization tags from the text length.
            local box_bg_width
            local colorize_index_1, colorize_index_2 = string_find(text, "@yellow")
            if colorize_index_1 then
                debug(flag1, "  this text has yellow colorization")
                colorize_index_1 = colorize_index_1 - 3
                colorize_index_2 = colorize_index_2 + 1
                local str = string_sub(text, 1, colorize_index_1 - 1) .. string_sub(text, colorize_index_2 + 1)
                debug(flag1, "  text without colorization: " .. str)
                box_bg_width = (string_len(str) * 8) + 30
            else
                box_bg_width = (string_len(text) * 8) + 30
            end

            -- display the actual notification message
            local hud_id = player_hud_ids[player_name]["notify_box_" .. notify_box]
            local hud_id_bg = player_hud_ids[player_name]["notify_box_" .. notify_box .. "_bg"]
            debug(flag1, "  displaying text on notify_box " .. notify_box)
            player:hud_change(hud_id, "text", text)
            player:hud_change(hud_id_bg, "text", "[fill:1x1:0,0:#00000080")
            player:hud_change(hud_id_bg, "scale", {x = box_bg_width, y = NOTIFY_BOX_HEIGHT})
            debug(flag1, "mt_after() END")

            -- schedule removal of the text after 'duration' seconds
            job_handle = mt_after(
                duration,
                clear_notify_box,
                player,
                player_name,
                hud_id,
                hud_id_bg,
                notify_box)
            job_handles[player_name]["notify_box_" .. notify_box] = job_handle
            debug(flag1, "\nnotify() >> mt_after() >> show text END")

        end)

        debug(flag1, "\nnotify() >> mt_after() >> play sound END")
    end)

    debug(flag1, "ss.notify() END")
end
local notify = ss.notify


local flag26 = false
function ss.pickup_item(player, pointed_thing)
    debug(flag26, "  pickup_item()")
    local type = pointed_thing.type
    if type == "object" then
        local object = pointed_thing.ref
        if object:is_player() then
            debug(flag26, "    this is a player: " .. object:get_player_name())
        else
            local luaentity =  object:get_luaentity()
            if luaentity then
                local entity_name = luaentity.name
                if entity_name == "__builtin:item" then
                    local dropped_item = ItemStack(luaentity.itemstring)
                    local dropped_item_name = dropped_item:get_name()
                    debug(flag26, "    this is a dropped item: " .. dropped_item_name)
                    debug(flag26, "    triggering item pickup..")
                    mt_item_pickup(dropped_item, player, pointed_thing, 0)
                else
                    debug(flag26, "    this is a non-craftitem entity: " .. entity_name)
                end
            else
                print("ERROR - attempted to pickup an invalud lua entity object")
                print("pointed_thing: " .. dump(pointed_thing))
                notify(player, "inventory", "ERROR - object invalid cannot pickup", 4, 0, 0.5, 3)
            end
        end
    elseif type == "node" then
        local pos = pointed_thing.under
        local node = mt_get_node(pos)
        local node_name = node.name
        debug(flag26, "    swung at a node: " .. node_name)
        if node_name == "ss:stone" then
            mt_sound_play("ss_break_stone", {object = player, max_hear_distance = 10}, true)
        elseif node_name == "ss:stick" then
            mt_sound_play("ss_inv_wood", {object = player, max_hear_distance = 10}, true)
        end
        mt_punch_node(pos, player)
    else
        debug(flag26, "    hit NOTHING")
    end
    debug(flag26, "  pickup_item() END")
end


local flag9 = false
function ss.remove_formspec_viewer(usernames, target)
    debug(flag9, "\n  ss.remove_formspec_viewer()")
    debug(flag9, "    usernames: " .. dump(usernames))
    debug(flag9, "    target: " .. target)
    for i = #usernames, 1, -1 do
        if usernames[i] == target then
            debug(flag9, "    ** username found **")
            table_remove(usernames, i)
            break
        end
    end
    debug(flag9, "    updated usernames: " .. dump(usernames))
    debug(flag9, "  ss.remove_formspec_viewer() END")
end


local flag11 = false
--[[ force-exit any players currently viewing the node formspec and remove their
names from the formspec viewers table. then remove the entry for the node pos
itself from the table. --]]
function ss.remove_formspec_all_viewers(pos, formspec_name)
    debug(flag11, "\n  ss.remove_formspec_all_viewers()")
    debug(flag11, "    formspec_viewers: " .. dump(formspec_viewers))
    debug(flag11, "    formspec_name: " .. formspec_name)
    local pos_key = pos_to_key(pos)
    debug(flag11, "    pos_key: " .. pos_key)

    for i, player_name in ipairs(formspec_viewers[pos_key]) do
        debug(flag11, "    - closing formspec for " .. player_name)
        mt_close_formspec(player_name, formspec_name)
        local p_data = player_data[player_name]
        p_data.formspec_mode = "main_formspec"
    end
    formspec_viewers[pos_key] = nil

	debug(flag11, "    updated formspec_viewers: " .. dump(formspec_viewers))
    debug(flag11, "  ss.remove_formspec_all_viewers() END")
end



local flag8 = false
function ss.drop_all_items(node_inv, pos)
    debug(flag8, "  ss.drop_all_items()")
	for list_name, slot_items in pairs(node_inv:get_lists()) do
		debug(flag8, "    list_name: " .. list_name)
		for slot_index, item in ipairs(slot_items) do
			if not item:is_empty() then
				local item_name = item:get_name()
				debug(flag8, "      [slot #" .. slot_index .. "] dropping >> "
                    .. item_name .. " " .. item:get_count())
				mt_add_item({
                    x = pos.x + math_random(-2, 2)/10,
                    y = pos.y,
                    z = pos.z + math_random(-2, 2)/10}, item
                )
			end
		end
	end
    debug(flag8, "  ss.drop_all_items() END")
end




local flag19 = false
-- Recalls the existing metadata relating to the item's cooker, remaining_uses, condition,
-- and heat_progress, and formats it as the tooltip description string.
--- @param item_meta ItemStackMetaRef the item's metadata object
--- @param item_name string the item's name
--- @return string tooltip the tooltip description text
function ss.refresh_meta_and_description(item_name, item_meta)
	debug(flag19, "      refresh_meta_and_description()")
	debug(flag19, "        item_name: " .. item_name)

	local cooker = item_meta:get_string("cooker")
    local tooltip_cooker = ""
	if cooker == "" then
		debug(flag19, "        no 'cooker' data")
	else
		tooltip_cooker = "\n" .. mt_colorize("#888888", "cooker: ") .. cooker
	end

    local remaining_uses = item_meta:get_int("remaining_uses")
    local tooltip_remaining_uses = ""
	if remaining_uses > 0 then
		tooltip_remaining_uses = "\n" .. mt_colorize("#888888", "remaining uses: ") .. remaining_uses
	else
		debug(flag19, "        no 'remaining_uses' data")
	end

	local condition = item_meta:get_float("condition")
    local tooltip_cooker_condition = ""
	if condition > 0 then
		condition = round(condition / 100, 1)
		tooltip_cooker_condition = "\n" .. mt_colorize("#888888", "condition: ") .. condition .. "%"
	else
		debug(flag19, "        no 'condition' data")
	end

	local heat_progress = item_meta:get_float("heat_progress")
    local tooltip_heat_progress = ""
	if heat_progress > 0 then
		heat_progress = round(heat_progress / 100, 1)
		tooltip_heat_progress = "\n" .. mt_colorize("#888888", "heated: ") .. heat_progress .. "%"
	else
		debug(flag19, "        no 'heat_progress' data")
	end

    local tooltip = table_concat({
        ITEM_TOOLTIP[item_name],
        tooltip_cooker,
        tooltip_remaining_uses,
        tooltip_cooker_condition,
        tooltip_heat_progress
    })

    debug(flag19, "        tooltip: " .. tooltip)

	debug(flag19, "      refresh_meta_and_description() END")
	return tooltip
end



local flag23 = false
-- Accepts values for the item's metadata relating to the cooker, remaining_uses,
-- condition, and heat_progress, then formats it as the item's new tooltip description.
--- @param item_meta ItemStackMetaRef the item's metadata object
--- @param item_name string the item's name
--- @param keys table a list of then metadata names/keys being updated
--- @param values table a list of values that the metadata keys will be set to
function ss.update_meta_and_description(item_meta, item_name, keys, values)
    debug(flag23, "      update_meta_and_description()")

    local cooker_value, remaining_uses_value, condition_value, heat_progress_value
    for i = 1, #keys do
        local key = keys[i]
        local value = values[i]

        if key == "cooker" then
            cooker_value = value
            item_meta:set_string("cooker", value)
        else
            cooker_value = item_meta:get_string("cooker")
        end

        if key == "remaining_uses" then
            remaining_uses_value = value
            item_meta:set_int("remaining_uses", value)
        else
            remaining_uses_value = item_meta:get_int("remaining_uses")
        end

        if key == "condition" then
            condition_value = value
            item_meta:set_float("condition", value)
        else
            condition_value = item_meta:get_float("condition")
        end

        if key == "heat_progress" then
            heat_progress_value = value
            item_meta:set_float("heat_progress", value)
        else
            heat_progress_value = item_meta:get_float("heat_progress")
        end
    end

    local tooltip_cooker = ""
    if cooker_value == "" then
        debug(flag23, "        no 'cooker' data")
    else
        tooltip_cooker = "\n" .. mt_colorize("#888888", "cooker: ") .. cooker_value
    end

    local tooltip_remaining_uses = ""
    if remaining_uses_value > 0 then
        tooltip_remaining_uses = "\n" .. mt_colorize("#888888", "remaining uses: ") .. remaining_uses_value
    else
        debug(flag23, "        no 'remaining_uses' data")
    end

    local tooltip_cooker_condition = ""
    if condition_value > 0 then
        condition_value = round(condition_value / 100, 1)
        tooltip_cooker_condition = "\n" .. mt_colorize("#888888", "condition: ") .. condition_value .. "%"
    else
        debug(flag23, "        no 'condition' data")
    end

    local tooltip_heat_progress = ""
    if heat_progress_value > 0 then
        heat_progress_value = round(heat_progress_value / 100, 1)
        tooltip_heat_progress = "\n" .. mt_colorize("#888888", "heated: ") .. heat_progress_value .. "%"
    else
        debug(flag23, "        no 'heat_progress' data")
    end

    local description = table_concat({
        ITEM_TOOLTIP[item_name],
        tooltip_cooker,
        tooltip_remaining_uses,
        tooltip_cooker_condition,
        tooltip_heat_progress
    })

    -- save the new description text into the metadata
    item_meta:set_string("description", description)
    debug(flag23, "        updated description: " .. description)

    debug(flag23, "      update_meta_and_description() END")
end


local flag4 = false
-- Get the total weight of an itemstack taking into account its total quantity
--- @param item ItemStack the itemstack from which the total weight is needed
--- @return number weight the total weight of the itemstack
function ss.get_itemstack_weight(item)
    debug(flag4, "  ss.get_itemstack_weight()")
    local total_weight = 0

    local item_meta = item:get_meta()
    if item_meta:contains("bundle_weight") then
        debug(flag4, "    this is an item bundle")
        total_weight = item_meta:get_float("bundle_weight")
        debug(flag4, "    total_weight: " .. total_weight)

    else
        debug(flag4, "    this is a normal itemstack")
        local item_name = item:get_name()
        local item_count = item:get_count()
        debug(flag4, "    " .. item_name .. " " .. item_count)

        local item_weight = ITEM_WEIGHTS[item_name]
        debug(flag4, "    item_weight: " .. item_weight)

        total_weight = item_count * item_weight
        debug(flag4, "    itemstack weight: " .. total_weight)
    end

    debug(flag4, "  ss.get_itemstack_weight() end")
    return total_weight
end
local get_itemstack_weight = ss.get_itemstack_weight



local flag18 = false
--- @param player ObjectRef the player object
-- Returns the weight of the currently wielded item. If player is not wielding an item
-- or the item does not have an assigned weight value, it returns 2.5 as default value.
-- also returns a boolean indicating if player was emppty handed or not
function ss.get_wield_weight(player, p_data)
	debug(flag18, "\n  get_wield_weight()")
    local weight_mod = p_data.weight_mod_forearm_freak
    local wield_weight
    local using_fists = true
	local item = player:get_wielded_item()
	local item_name = item:get_name()
	--debug(flag18, "  item_name: " .. item_name)
	if item_name == "" then
		--debug(flag18, "    swinging fists")
        wield_weight = 2.5 * weight_mod
	else
		--debug(flag18, "    swinging " .. item_name)
		local itemstack_weight = get_itemstack_weight(item)
        --debug(flag18, "    itemstack_weight: " .. itemstack_weight)
		if itemstack_weight > 0 then
            using_fists = false
			if itemstack_weight < 2.5 then
				-- weight less than 2.5. default to 2.5
                wield_weight = 2.5 * weight_mod
			else
                wield_weight = itemstack_weight * weight_mod
			end
		else
			-- default to 2.5
            wield_weight = 2.5 * weight_mod
		end
	end

    debug(flag18, "    wield_weight: " .. wield_weight)
    debug(flag18, "    using_fists: " .. dump(using_fists))
    return wield_weight, using_fists

end



-- Wheter or not the item when added to the inventory will cause it to exceed the
-- total inventory weight limit.
--- @param item ItemStack the itemstack being added to the player inventory
--- @return boolean output 'true' if adding 'item' to inventory exceeds max inv weight
function ss.exceeds_inv_weight_max(item, player_meta)
    local new_inv_weight = player_meta:get_float("weight_current") + get_itemstack_weight(item)
    if new_inv_weight > player_meta:get_float("weight_max") then
        return true
    else
        return false
    end
end


--- @param fs table the table containing subtables of formspec elements
--- @return string formspec formspec as a string or as a table
-- Takes 'fs' which is a table of key/value pairs and converts it to a standard indexed
-- array of string elements. Also ensures that the formspec elements size[] and
-- tabheader[] appear first in the returned table to maintain valid formspec formatting.
function ss.build_fs(fs)

    -- make a copy of 'fs'
    local fs_copy = {}
    for k, v in pairs(fs) do
        fs_copy[k] = v
    end

    -- remove 'setup' group elements from this table becuase it will be added back later
    fs_copy.setup = nil

    -- edd each formspec element from each group into a consolodated table
    local fs_tokenized = {}
    for i, fs_section in pairs(fs_copy) do
        for j, fs_subsection in pairs(fs_section) do
            for k, fs_element in ipairs(fs_subsection) do
                table_insert(fs_tokenized, fs_element)
            end
        end
    end

    -- added 'setup' group into the begining of the consolodated table
    for i = #fs.setup, 1, -1  do
        table_insert(fs_tokenized, 1, fs.setup[i])
    end

    return table_concat(fs_tokenized)
end
local build_fs = ss.build_fs




--- @return table
-- Returns a table of elements relating to player stats info on the upper left
-- side. Curently just hypertext[] elements with basic player info.
function ss.get_fs_player_stats(player_name)
    local x_pos = 0.2
    local y_pos = 0.2
    local p_data = player_data[player_name]
    local fs_output = {table_concat({
        "hypertext[", x_pos, ",", y_pos, ";3,1;player_name;",
        "<style color=#AAAAAA size=16><b>", string_upper(player_name), "</b></style>]",

        --"hypertext[", x_pos, ",", y_pos + 0.5, ";3,1;player_status;",
        --"<style color=#777777 size=15><b>Status:  <style color=", p_data.ui_green, ">Good</style></b></style>]",
    })}

    return fs_output
end



local flag24 = false
--- @return table
-- Returns a table of all elements relating to the avatar section of 'fs' table.
-- Curently includes only image[] which is the player avatar image on the left pane.
function ss.get_fs_player_avatar(mesh_file, texture_file)
    debug(flag24, "\n  get_fs_player_avatar()")
    debug(flag24, "    mesh_file: " .. mesh_file)
    debug(flag24, "    texture_file: " .. texture_file)
    return {
        table_concat({
            "box[1.3,0.7;3.0,6.25;#111111]",
            "box[1.35,0.75;2.9,6.15;#333333]",
            "model[1.5,1.1;2.6,5.47;player_avatar;", mesh_file, ";", texture_file,
            ";{0,200};false;true;2,2;0]"
        })
    }
end



local flag13 = false
--- @return table
-- Returns a table of all elements relating to the left side equipment slots section of
-- 'fs' table. Currently includes elements like list[], image[], and tooltip for each
-- of the 11 equipment slots.
function ss.get_fs_equip_slots(p_data)
    debug(flag13, "\n  get_fs_equip_slots()")

    local data = {
        clothing_slot_eyes   = { 4.4, 0.70, "ss_ui_slot_clothing_eyes", "Eyewear\n(shades, glasses, goggles, etc)" },
        clothing_slot_neck   = { 4.4, 1.75, "ss_ui_slot_clothing_neck", "Neck\n(scarf, necklace, etc)" },
        clothing_slot_chest = { 4.4, 2.80, "ss_ui_slot_clothing_chest", "Top Clothing\n(shirt, sweater, etc)" },
        clothing_slot_hands  = { 4.4, 3.85, "ss_ui_slot_clothing_hands", "Hand Protection\n(gloves, mittens, etc)" },
        clothing_slot_legs  = { 4.4, 4.90, "ss_ui_slot_clothing_legs", "Bottom Clothing\n(pants, shorts, etc)" },
        clothing_slot_feet  = { 4.4, 5.95, "ss_ui_slot_clothing_feet", "Foot Support\n(socks, insoles, etc)" },
        
        armor_slot_head   = { 0.2, 0.70, "ss_ui_slot_armor_head", "Headgear\n(hats, helmets, etc)" },
        armor_slot_face   = { 0.2, 1.75, "ss_ui_slot_armor_face", "Face\n(bandana, mask, etc)" },
        armor_slot_chest    = { 0.2, 2.80, "ss_ui_slot_armor_chest", "Chest Armor" },
        armor_slot_arms     = { 0.2, 3.85, "ss_ui_slot_armor_arms", "Arm Guards" },
        armor_slot_legs     = { 0.2, 4.90, "ss_ui_slot_armor_legs", "Leg Armor" },
        armor_slot_feet   = { 0.2, 5.95, "ss_ui_slot_armor_feet", "Footwear\n(shoes, boots, etc)" }
    }

    -- cycle through all p_data for each slot and if empty string, then put slot bg. if not, show green highlight
    local fs_data = {}
    for _,body_part in ipairs({"eyes", "neck", "chest", "hands", "legs", "feet"}) do
        debug(flag13, "    body_part: " .. body_part)

        local image_element = ""
        local slot_name = "clothing_slot_" .. body_part
        local image_element_data = data[slot_name]
        if p_data["avatar_clothing_" .. body_part] == "" then
            debug(flag13, "      slot is empty. show bg image.")
            image_element = table_concat({
                "image[", image_element_data[1], ",", image_element_data[2], ";1,1;", image_element_data[3], ".png;]"
            })
        else
            debug(flag13, "      slot is occupied. show highlight color.")
            image_element = table_concat({
                "image[", image_element_data[1], ",", image_element_data[2], ";1,1;[fill:1x1:#005000]"
            })
        end
        debug(flag13, "      image_element: " .. image_element)

        local new_data = {
            table_concat({
                image_element,
                "list[current_player;", slot_name, ";", image_element_data[1], ",", image_element_data[2], ";1,1;]",
                "tooltip[", image_element_data[1], ",", image_element_data[2], ";1,1;", image_element_data[4], "]"
            })
        }
        table_insert(fs_data, new_data)
    end

    for _,body_part in ipairs({"head", "face", "chest", "arms", "legs", "feet"}) do
        debug(flag13, "    body_part: " .. body_part)

        local image_element = ""
        local slot_name = "armor_slot_" .. body_part
        local image_element_data = data[slot_name]

        if p_data["avatar_armor_" .. body_part] == ""  then
            debug(flag13, "      slot is empty. show bg image.")
            image_element = table_concat({
                "image[", image_element_data[1], ",", image_element_data[2], ";1,1;", image_element_data[3], ".png;]"
            })
        else
            debug(flag13, "      slot is occupied. show highlight color.")
            image_element = table_concat({
                "image[", image_element_data[1], ",", image_element_data[2], ";1,1;[fill:1x1:#004000]"
            })
        end
        debug(flag13, "      image_element: " .. image_element)

        local new_data = {
            table_concat({
                image_element,
                "list[current_player;", slot_name, ";", image_element_data[1], ",", image_element_data[2], ";1,1;]",
                "tooltip[", image_element_data[1], ",", image_element_data[2], ";1,1;", image_element_data[4], "]"            })
        }
        table_insert(fs_data, new_data)
    end


    local fs_output = {}
    for i, fs_group in ipairs(fs_data) do
        for j, fs_element in ipairs(fs_group) do
            table_insert(fs_output, fs_element)
        end
    end

    debug(flag13, "  get_fs_equip_slots() end")
    return fs_output
end



local flag12 = false
--- @return table
-- Returns a table of all elements relating to the equipment buffs box located below the
-- equipment slots on the left pane of the player inventory formspec.
function ss.get_fs_equipment_buffs(player_name)
    debug(flag12, "  ss.get_fs_equipment_buffs()")

    local x_pos = 0.0
    local y_pos = 0.0
    local p_data = player_data[player_name]

    local damage_value = p_data.equip_buff_damage
    local damage_value_color = "#777777"
    if damage_value > p_data.equip_buff_damage_prev then
        damage_value_color = p_data.ui_green
    elseif damage_value < p_data.equip_buff_damage_prev then
        damage_value_color = p_data.ui_red
    end

    local cold_value = p_data.equip_buff_cold
    local value_sign_cold = ""
    local cold_value_color = "#777777"
    if cold_value > p_data.equip_buff_cold_prev then
        cold_value_color = p_data.ui_green
    elseif cold_value < p_data.equip_buff_cold_prev then
        cold_value_color = p_data.ui_red
    end
    if cold_value > 0 then value_sign_cold = "+" end

    local heat_value = p_data.equip_buff_heat
    local heat_value_color = "#777777"
    local value_sign_heat = ""
    if heat_value > p_data.equip_buff_heat_prev then
        heat_value_color = p_data.ui_red
    elseif heat_value < p_data.equip_buff_heat_prev then
        heat_value_color = p_data.ui_green
    end
    if heat_value > 0 then value_sign_heat = "+" end

    local sun_value = p_data.equip_buff_sun
    local sun_value_color = "#777777"
    if sun_value > p_data.equip_buff_sun_prev then
        sun_value_color = p_data.ui_green
    elseif sun_value < p_data.equip_buff_sun_prev then
        sun_value_color = p_data.ui_red
    end

    local water_value = p_data.equip_buff_water
    local water_value_color = "#777777"
    local value_sign_water = ""
    if water_value > p_data.equip_buff_water_prev then
        water_value_color = p_data.ui_green
    elseif water_value < p_data.equip_buff_water_prev then
        water_value_color = p_data.ui_red
    end
    if water_value > 0 then value_sign_water = "+" end

    local wetness_value = p_data.equip_buff_wetness
    local wetness_value_color = "#777777"
    if wetness_value > p_data.equip_buff_wetness_prev then
        wetness_value_color = p_data.ui_green
    elseif wetness_value < p_data.equip_buff_wetness_prev then
        wetness_value_color = p_data.ui_red
    end

    local disease_value = p_data.equip_buff_disease
    local disease_value_color = "#777777"
    if disease_value > p_data.equip_buff_disease_prev then
        disease_value_color = p_data.ui_green
    elseif disease_value < p_data.equip_buff_disease_prev then
        disease_value_color = p_data.ui_red
    end

    local electrical_value = p_data.equip_buff_electrical
    local electrical_value_color = "#777777"
    if electrical_value > p_data.equip_buff_electrical_prev then
        electrical_value_color = p_data.ui_green
    elseif electrical_value < p_data.equip_buff_electrical_prev then
        electrical_value_color = p_data.ui_red
    end

    local radiation_value = p_data.equip_buff_radiation
    local radiation_value_color = "#777777"
    if radiation_value > p_data.equip_buff_radiation_prev then
        radiation_value_color = p_data.ui_green
    elseif radiation_value < p_data.equip_buff_radiation_prev then
        radiation_value_color = p_data.ui_red
    end

    local gas_value = p_data.equip_buff_gas
    local gas_value_color = "#777777"
    if gas_value > p_data.equip_buff_gas_prev then
        gas_value_color = "#FF8000"
    elseif gas_value < p_data.equip_buff_gas_prev then
        gas_value_color = p_data.ui_green
    end

    local noise_value = p_data.equip_buff_noise
    local noise_value_color = "#777777"
    if noise_value > p_data.equip_buff_noise_prev then
        noise_value_color = "#FF8000"
    elseif noise_value < p_data.equip_buff_noise_prev then
        noise_value_color = p_data.ui_green
    end

    local weight_value = p_data.equip_buff_weight
    local weight_value_color = "#777777"
    if weight_value > p_data.equip_buff_weight_prev then
        weight_value_color = "#FF8000"
    elseif weight_value < p_data.equip_buff_weight_prev then
        weight_value_color = p_data.ui_green
    end

    local units = "°F"
    if p_data.thermal_units == 2 then units = "°C" end
    local fs_output = { table_concat({
        "box[", 0.2, ",", y_pos + 7.0, ";5.2,3.3;#111111]",

        "style[equipbuff_damage:hovered;fgimg=ss_ui_equip_buffs_damage.png]",
        "image_button[", x_pos + 0.45, ",", y_pos + 7.25, ";0.65,0.65;ss_ui_equip_buffs_damage.png^[hsl:0:-100:0;equipbuff_damage;;true;true;]",
        "tooltip[", x_pos + 0.45, ",", y_pos + 7.25, ";1.2,0.5;damage protection]",
        "hypertext[", x_pos + 1.1, ",", y_pos + 7.45, ";2,2;damage_protection;",
        "<style color=", damage_value_color, " size=14>", damage_value, "%</style>]",

        "style[equipbuff_cold:hovered;fgimg=ss_ui_equip_buffs_cold.png]",
        "image_button[", x_pos + 2.15, ",", y_pos + 7.25, ";0.65,0.65;ss_ui_equip_buffs_cold.png^[hsl:0:-100:0;equipbuff_cold;;true;true;]",
        "tooltip[", x_pos + 2.15, ",", y_pos + 7.25, ";1.2,0.5;cold weather factor]",
        "hypertext[", x_pos + 2.8, ",", y_pos + 7.45, ";2,2;cold_protection;",
        "<style color=", cold_value_color, " size=14>", value_sign_cold, cold_value, units, "</style>]",

        "style[equipbuff_heat:hovered;fgimg=ss_ui_equip_buffs_heat.png]",
        "image_button[", x_pos + 3.85, ",", y_pos + 7.25, ";0.65,0.65;ss_ui_equip_buffs_heat.png^[hsl:0:-100:0;equipbuff_heat;;true;true;]",
        "tooltip[", x_pos + 3.85, ",", y_pos + 7.25, ";1.2,0.5;hot weather factor]",
        "hypertext[", x_pos + 4.5, ",", y_pos + 7.45, ";2,2;heat_protection;",
        "<style color=", heat_value_color, " size=14>", value_sign_heat, heat_value, units, "</style>]",

        "style[equipbuff_wetness:hovered;fgimg=ss_ui_equip_buffs_wetness.png]",
        "image_button[", x_pos + 0.45, ",", y_pos + 8.0, ";0.65,0.65;ss_ui_equip_buffs_wetness.png^[hsl:0:-100:0;equipbuff_wetness;;true;true;]",
        "tooltip[", x_pos + 0.45, ",", y_pos + 8.0, ";1.2,0.5;wetness protection]",
        "hypertext[", x_pos + 1.1, ",", y_pos + 8.2, ";2,2;wetness_protection;",
        "<style color=", wetness_value_color, " size=14>", wetness_value, "%</style>]",

        "style[equipbuff_water:hovered;fgimg=ss_ui_equip_buffs_water.png]",
        "image_button[", x_pos + 2.15, ",", y_pos + 8.0, ";0.65,0.65;ss_ui_equip_buffs_water.png^[hsl:0:-100:0;equipbuff_water;;true;true;]",
        "tooltip[", x_pos + 2.15, ",", y_pos + 8.0, ";1.2,0.5;water temperature factor]",
        "hypertext[", x_pos + 2.8, ",", y_pos + 8.2, ";2,2;water_protection;",
        "<style color=", water_value_color, " size=14>", value_sign_water, water_value, units, "</style>]",

        "style[equipbuff_sun:hovered;fgimg=ss_ui_equip_buffs_sun.png]",
        "image_button[", x_pos + 3.85, ",", y_pos + 8.0, ";0.65,0.65;ss_ui_equip_buffs_sun.png^[hsl:0:-100:0;equipbuff_sun;;true;true;]",
        "tooltip[", x_pos + 3.85, ",", y_pos + 8.0, ";1.2,0.5;sun protection]",
        "hypertext[", x_pos + 4.5, ",", y_pos + 8.2, ";2,2;sun_protection;",
        "<style color=", sun_value_color, " size=14>", sun_value, "%</style>]",

        "style[equipbuff_disease:hovered;fgimg=ss_ui_equip_buffs_disease.png]",
        "image_button[", x_pos + 0.45, ",", y_pos + 8.75, ";0.65,0.65;ss_ui_equip_buffs_disease.png^[hsl:0:-100:0;equipbuff_disease;;true;true;]",
        "tooltip[", x_pos + 0.45, ",", y_pos + 8.75, ";1.2,0.5;disease protection]",
        "hypertext[", x_pos + 1.1, ",", y_pos + 8.95, ";2,2;disease_protection;",
        "<style color=", disease_value_color, " size=14>", disease_value, "%</style>]",

        "style[equipbuff_electrical:hovered;fgimg=ss_ui_equip_buffs_electrical.png]",
        "image_button[", x_pos + 2.15, ",", y_pos + 8.75, ";0.65,0.65;ss_ui_equip_buffs_electrical.png^[hsl:0:-100:0;equipbuff_electrical;;true;true;]",
        "tooltip[", x_pos + 2.15, ",", y_pos + 8.75, ";1.2,0.5;electrical protection]",
        "hypertext[", x_pos + 2.8, ",", y_pos + 8.95, ";2,2;electrical_protection;",
        "<style color=", electrical_value_color, " size=14>", electrical_value, "%</style>]",

        "style[equipbuff_radiation:hovered;fgimg=ss_ui_equip_buffs_radiation.png]",
        "image_button[", x_pos + 3.85, ",", y_pos + 8.75, ";0.65,0.65;ss_ui_equip_buffs_radiation.png^[hsl:0:-100:0;equipbuff_radiation;;true;true;]",
        "tooltip[", x_pos + 3.85, ",", y_pos + 8.75, ";1.2,0.5;radiation protection]",
        "hypertext[", x_pos + 4.5, ",", y_pos + 8.95, ";2,2;radiation_protection;",
        "<style color=", radiation_value_color, " size=14>", radiation_value, "%</style>]",

        "style[equipbuff_gas:hovered;fgimg=ss_ui_equip_buffs_gas.png]",
        "image_button[", x_pos + 0.45, ",", y_pos + 9.5, ";0.65,0.65;ss_ui_equip_buffs_gas.png^[hsl:0:-100:0;equipbuff_gas;;true;true;]",
        "tooltip[", x_pos + 0.45, ",", y_pos + 9.5, ";1.2,0.5;gas protection]",
        "hypertext[", x_pos + 1.1, ",", y_pos + 9.7, ";2,2;gas_level;",
        "<style color=", gas_value_color, " size=14>", gas_value, "%</style>]",

        "style[equipbuff_noise:hovered;fgimg=ss_ui_equip_buffs_noise.png]",
        "image_button[", x_pos + 2.15, ",", y_pos + 9.5, ";0.65,0.65;ss_ui_equip_buffs_noise.png^[hsl:0:-100:0;equipbuff_noise;;true;true;]",
        "tooltip[", x_pos + 2.15, ",", y_pos + 9.5, ";1.2,0.5;noise level]",
        "hypertext[", x_pos + 2.8, ",", y_pos + 9.7, ";2,2;noise_level;",
        "<style color=", noise_value_color, " size=14>", noise_value, "dB</style>]",

        "style[equipbuff_weight:hovered;fgimg=ss_ui_equip_buffs_weight.png]",
        "image_button[", x_pos + 3.85, ",", y_pos + 9.5, ";0.65,0.65;ss_ui_equip_buffs_weight.png^[hsl:0:-100:0;equipbuff_weight;;true;true;]",
        "tooltip[", x_pos + 3.85, ",", y_pos + 9.5, ";1.2,0.5;weight total]",
        "hypertext[", x_pos + 4.5, ",", y_pos + 9.7, ";2,2;weight_total;",
        "<style color=", weight_value_color, " size=14>", weight_value, "</style>]",
    })}

    p_data.equip_buff_damage_prev = damage_value
    p_data.equip_buff_cold_prev = cold_value
    p_data.equip_buff_heat_prev = heat_value
    p_data.equip_buff_sun_prev = sun_value
    p_data.equip_buff_water_prev = water_value
    p_data.equip_buff_wetness_prev = wetness_value
    p_data.equip_buff_disease_prev = disease_value
    p_data.equip_buff_electrical_prev = electrical_value
    p_data.equip_buff_radiation_prev = radiation_value
    p_data.equip_buff_gas_prev = gas_value
    p_data.equip_buff_noise_prev = noise_value
    p_data.equip_buff_weight_prev = weight_value

    debug(flag12, "  ss.get_fs_equipment_buffs() end")
    return fs_output
end



local flag10 = false
--- @return table fs_output Returns a table of all elements relating to the inventory
--- 'weight' counter located at the bottom left of the main inventory grid. Currently
--- includes hypertext[] element.
function ss.get_fs_weight(player)
    debug(flag10, "  get_fs_weight()")
    local player_meta = player:get_meta()
    local curr_weight = player_meta:get_float("weight_current")
    local max_weight = player_meta:get_float("weight_max")

    debug(flag10, "    curr_weight: " .. curr_weight)
    debug(flag10, "    max_weight: " .. max_weight)
    curr_weight = round(curr_weight, 2)

    local x_pos = 6
    local fs_output = {
        table_concat({
            "image[", x_pos, ",9.45;0.6,0.6;ss_ui_iteminfo_attrib_weight.png;]",
            "hypertext[", x_pos + 0.8, ",9.65;4.0,2;inventory_weight;<b>",
                "<style color=#999999 size=16>", curr_weight, "</style>",
                "<style color=#666666 size=16> / ", max_weight, "</style>",
            "</b>]",
            "tooltip[", x_pos, ",9.4;1.8,0.5;inventory weight (current / max)]"
        })
    }

    debug(flag10, "  get_fs_weight() end")
    return fs_output
end
local get_fs_weight = ss.get_fs_weight


local flag16 = false
--- @param player ObjectRef used to access the meta data 'inventory_weight'
--- @param player_meta MetaDataRef used to access the meta data 'inventory_weight'
function ss.update_fs_weight(player, player_meta)
    debug(flag16, "  update_fs_weight()")
    after_player_check(player)
    local fs = player_data[player:get_player_name()].fs
    fs.center.weight = get_fs_weight(player)
    player_meta:set_string("fs", mt_serialize(fs))
    player:set_inventory_formspec(build_fs(fs))
    debug(flag16, "  update_fs_weight() end")
end


local flag14 = false
function ss.add_item_to_itemdrop_bag(bag_pos, item)
    debug(flag14, "  add_item_to_itemdrop_bag()")
    debug(flag14, "    item name: " .. item:get_name())
	local bag_node = mt_get_node(bag_pos)
	local bag_node_name = bag_node.name
	debug(flag14, "    bag_node_name: " .. bag_node_name)

	local node_meta = mt_get_meta(bag_pos)
	local node_inv = node_meta:get_inventory()
	debug(flag14, "    adding " .. item:get_name() .. " into bag..")

	if node_inv:room_for_item("items", item) then
		local leftover_items = node_inv:add_item("items", item)
		debug(flag14, "    added into into existing slot")
		debug(flag14, "    leftover_items (should be 0): " .. leftover_items:get_count())

	else
		debug(flag14, "    does not fit in slot. adding another slot.. ")
		node_inv:set_size("items", node_inv:get_size("items") + 1)
		local leftover_items = node_inv:add_item("items", item)
		debug(flag14, "    item successfully added into the new slot of bag")
		debug(flag14, "    leftover_items (should be 0): " .. leftover_items:get_count())
	end

    debug(flag14, "  add_item_to_itemdrop_bag() END")
end


-- param2 values for slabs where it's oriented at the upper half of the node space
local placeable_params_slab = {20, 21, 22, 23}
local target_params_slab = {}
for _, value in ipairs(placeable_params_slab) do
    target_params_slab[value] = true
end

-- param2 values for stairs where the flat square base side is facing upward
local placeable_params_stair = {6, 8, 15, 17, 20, 21, 22, 23}
local target_params_stair = {}
for _, value in ipairs(placeable_params_stair) do
    target_params_stair[value] = true
end

-- param2 values for stairs where the flat square base side is facing upward
local placeable_params_stair_inner = {6, 7, 8, 9, 12, 15, 17, 18, 20, 21, 22, 23}
local target_params_stair_inner = {}
for _, value in ipairs(placeable_params_stair_inner) do
    target_params_stair_inner[value] = true
end

-- param2 values for stairs where the flat square base side is facing upward
local placeable_params_stair_outer = {20, 21, 22, 23}
local target_params_stair_outer = {}
for _, value in ipairs(placeable_params_stair_outer) do
    target_params_stair_outer[value] = true
end


local flag15 = false
function ss.is_variable_height_node_supportive(node, node_name)
    debug(flag15, "    is_variable_height_node_supportive()")

    local is_supportive = false
    if string_sub(node_name, 1, 12) == "stairs:slab_" then
        debug(flag15, "      this is a slab")
        if target_params_slab[node.param2] then
            debug(flag15, "      it's orientation can support a node above it")
            is_supportive = true
        else
            debug(flag15, "      it's orientation cannot support a node above it")
        end

    elseif string_sub(node_name, 1, 18) == "stairs:stair_inner" then
        debug(flag15, "      this is a inner stair")
        if target_params_stair_inner[node.param2] then
            debug(flag15, "      it's orientation can support a node above it")
            is_supportive = true
        else
            debug(flag15, "      it's orientation cannot support a node above it")
        end

    elseif string_sub(node_name, 1, 18) == "stairs:stair_outer" then
        debug(flag15, "      this is a outer stair")
        if target_params_stair_outer[node.param2] then
            debug(flag15, "      it's orientation can support a node above it")
            is_supportive = true
        else
            debug(flag15, "      it's orientation cannot support a node above it")
        end

    elseif string_sub(node_name, 1, 13) == "stairs:stair_" then
        debug(flag15, "      this is a stair")
        if target_params_stair[node.param2] then
            debug(flag15, "      it's orientation can support a node above it")
            is_supportive = true
        else
            debug(flag15, "      it orientation cannot support a node above it")
        end
    else
        debug(flag15, "      ERROR - Unexpected variable node type: " .. node_name)
    end

    debug(flag15, "    is_variable_height_node_supportive() END")
    return is_supportive
end



local flag7 = false
-- Get all buff values related to the targeted player physics property, combines
-- them, and applies it to the physics property.
--- @param player ObjectRef the player object
--- @param property_names table the physics property to modify, either 'speed' or 'jump'
function ss.update_player_physics(player, property_names)
	debug(flag7, "\n  ss.update_player_physics() " .. math_random(1, 9999))
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]
	local physics = player:get_physics_override()

    local curr_state = p_data.current_anim_state
    --debug(flag7, "    curr_state: " .. curr_state)

    if property_names.speed then
        local subskill_mod_walk = 1
        local subskill_mod_run = 1
        local subskill_mod_crouch = 1

        if string_find(curr_state, "crouch_walk") then
            subskill_mod_crouch = p_data.speed_mod_creeper
        elseif string_find(curr_state, "crouch_run") then
            subskill_mod_run = p_data.speed_mod_sprinter
            subskill_mod_crouch = p_data.speed_mod_creeper
        elseif string_find(curr_state, "crouch") then
            subskill_mod_crouch = p_data.speed_mod_creeper
        elseif string_find(curr_state, "stand") then
            subskill_mod_walk = p_data.speed_mod_speed_walker
        elseif string_find(curr_state, "walk") then
            subskill_mod_walk = p_data.speed_mod_speed_walker
        elseif string_find(curr_state, "run") then
            subskill_mod_run = p_data.speed_mod_sprinter
        else
            debug(flag7, "    ERROR - Unexpected 'curr_state' value: " .. curr_state)
        end

        local weight_buff_delta = 1 - p_data.speed_buff_weight
        local new_weight_buff = weight_buff_delta * (2 - p_data.speed_mod_cargo_tank)
        local speed_buff_weight = 1 - new_weight_buff

        physics.speed = p_data.speed_walk_current * subskill_mod_walk
            * speed_buff_weight
            * p_data.speed_buff_crouch * subskill_mod_crouch
            * p_data.speed_buff_run * subskill_mod_run
            * p_data.speed_buff_exhaustion
            * p_data.speed_buff_illness
            * p_data.speed_buff_poison
            * p_data.speed_buff_vomit
            * p_data.speed_buff_sneeze
            * p_data.speed_buff_cough
            * p_data.speed_buff_legs
    end

    if property_names.jump then
        local weight_buff_delta = 1 - p_data.jump_buff_weight
        local new_weight_buff = weight_buff_delta * (2 - p_data.jump_mod_bulk_bouncer)
        local jump_buff_weight = 1 - new_weight_buff

        physics.jump = p_data.jump_height_current
            --* p_data.jump_buff_weight
            * jump_buff_weight
            * p_data.jump_buff_crouch
            * p_data.jump_buff_run
            * p_data.jump_buff_exhaustion
            * p_data.jump_buff_illness
            * p_data.jump_buff_poison
            * p_data.jump_buff_vomit
            * p_data.jump_buff_sneeze
            * p_data.jump_buff_cough
            * p_data.jump_buff_legs
            * p_data.jump_mod_launchitude
    end

	player:set_physics_override(physics)
	debug(flag7, "  ss.update_player_physics() end")
end


local flag5 = false
function ss.get_item_burn_time(item)
    debug(flag5, "    get_item_burn_time()")

    local fuel_item_name = item:get_name()
	debug(flag5, "      fuel_item_name: " .. fuel_item_name)

    local item_burn_time
    local is_reduced = false
    local item_meta = item:get_meta()

    if fuel_item_name == "ss:item_bundle" then
        debug(flag5, "      this is an item bundle")
        item_burn_time = item_meta:get_int("bundle_burn_time")

    else
        debug(flag5, "      not an item bundle")
        -- get the fuel item's max burn time value
        item_burn_time = ITEM_BURN_TIMES[fuel_item_name]
        debug(flag5, "      item_burn_time: " .. item_burn_time)

        -- items like campfire tools can have both 'condition' and 'heat progress'
        -- properties. when placed into the fuel slot, calculate the reduced
        -- fuel burn time of the item based on the condition/heat progress value
        -- that implies the least 'burnability' amount
        local heat_progress = item_meta:get_float("heat_progress")
        debug(flag5, "      heat_progress: " .. heat_progress)
        local condition = item_meta:get_float("condition")
        debug(flag5, "      condition: " .. condition)

        if condition == 0 and heat_progress == 0 then
            debug(flag5, "      item is unused / unheated. using full burn time: " .. item_burn_time)
        else
            debug(flag5, "      item is used or heated. calculating reduced burn time..")

            if condition == 0 then condition = 10000 end
            debug(flag5, "      condition remain: " .. condition)
            local heat_progress_remain = COOK_THRESHOLD - heat_progress
            debug(flag5, "      heat_progress_remain: " .. heat_progress_remain)

            -- take the value that is the least and set as the remaining burnability
            local burnability_amount = math_min(heat_progress_remain, condition)
            debug(flag5, "      burnability_amount: " .. burnability_amount)

            -- calculate the actual reduced burn time
            local burnability_ratio = burnability_amount / WEAR_VALUE_MAX
            item_burn_time = math_round(item_burn_time * burnability_ratio)
            if item_burn_time < 1 and item_burn_time > 0 then item_burn_time = 1 end

            -- indicuate this burn time is a reduced value from original
            is_reduced = true
        end

    end

    debug(flag5, "      item_burn_time: " .. item_burn_time)

    debug(flag5, "    get_item_burn_time() END")
    return item_burn_time, is_reduced
end



-- ###################################
-- ########## API OVERRIDES ##########
-- ###################################


local flag32 = false
-- original definition location: builtin/game/item_entity.lua
function core.spawn_item(pos, item)
	debug(flag32, "\ncore.spawn_item() API OVERRIDES")
	debug(flag32, "  pos: " .. mt_pos_to_string(pos))

	-- use the 'pos' parameter (which is the player's pos) as the basis for the pos hash
	local pos_hash = mt_hash_node_position(pos)

	-- retrieve pos hash that was set in bag_allow_metadata_inventory_take() of itemdrop_bag.lua
	local bag_pos = itemdrop_bag_pos[pos_hash]
	if bag_pos then
		debug(flag32, "  dropping item at bag pos..")
    	pos = itemdrop_bag_pos[pos_hash]
		itemdrop_bag_pos[pos_hash] = nil
		debug(flag32, "  itemdrop_bag_pos: " .. dump(itemdrop_bag_pos))
	else
		debug(flag32, "  dropping item at player pos..")
		-- tweak item spawn height lower in case player is crouching
		pos = {x = pos.x, y = pos.y - 0.5, z = pos.z}
	end
	debug(flag32, "  pos: " .. mt_pos_to_string(pos))

	local item_object = mt_add_entity(pos, "__builtin:item")
	local stack = ItemStack(item)
	if item_object then
		item_object:get_luaentity():set_item(stack:to_string())
	end

	debug(flag32, "core.spawn_item() END *** " .. mt_get_gametime() .. "\n")
	return item_object
end

-- be default, item drops from nodes and placed directly into player's inventory. overriding
-- this allows code for dropping items to the ground instead
function core.handle_node_drops(pos, drops, digger)
    for _, item in ipairs(drops) do
        mt_add_item({
			x = pos.x + math_random(-2, 2)/10,
			y = pos.y + 0.5,
			z = pos.z + math_random(-2, 2)/10
		}, item)
    end
end