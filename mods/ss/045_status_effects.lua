print("- loading status_effects.lua")

-- cache global functions for faster access
local math_random = math.random
local mt_after = core.after
local debug = ss.debug
local notify = ss.notify
local after_player_check = ss.after_player_check
local play_sound = ss.play_sound
local update_visuals = ss.update_visuals
local do_stat_update_action = ss.do_stat_update_action
local update_player_physics = ss.update_player_physics
local update_base_stat_value = ss.update_base_stat_value

-- cache global variables for faster access
local player_data = ss.player_data
local job_handles = ss.job_handles


local ENABLE_STATUS_EFFECTS_MONITOR = true

-- drain rates applied to stats based on the stat effect severity, which is loosely
-- represented by the number at the end of each variable name
local DRAIN_VAL_0 = -0.01
local DRAIN_VAL_1 = -0.03
local DRAIN_VAL_2 = -0.06
local DRAIN_VAL_3 = -0.09
local DRAIN_VAL_4 = -0.12
local DRAIN_VAL_5 = -0.15

-- stat effects that can modify the health baseline value. the values below modify
-- the health baseline value by that factor
local BASE_MOD_HEALTH = {
    thirst_1 =    0.99, thirst_2 =    0.95, thirst_3 =    0.50,
    hunger_1 =    0.99, hunger_2 =    0.95, hunger_3 =    0.50,
    alertness_1 = 0.99, alertness_2 = 0.98, alertness_3 = 0.95,
    immunity_1 =  0.99, immunity_2 =  0.95, immunity_3 =  0.90,
    illness_1 =   0.99, illness_2 =   0.90, illness_3 =   0.70,
    poison_1 =    0.99, poison_2 =    0.90, poison_3 =    0.80,
                        hot_2 =       0.99, hot_3 =       0.95, hot_4 =   0.90,
                        cold_2 =      0.99, cold_3 =      0.95, cold_4 =  0.90,
    legs_1 =      0.99, legs_2 =      0.94, legs_3 =      0.85, legs_4 =  0.96, legs_5 =  0.88, legs_6 =  0.90,
    hands_1 =     0.99, hands_2 =     0.95, hands_3 =     0.90, hands_4 = 0.98, hands_5 = 0.92, hands_6 = 0.94,
}

-- stat effects that can modify the comfort baseline value. the values below modify
-- the comfort baseline value by that factor
local BASE_MOD_COMFORT = {
    health_1 =  0.80, health_2 =  0.60,
    thirst_1 =  0.99, thirst_2 =  0.90, thirst_3 =  0.60,
    hunger_1 =  0.99, hunger_2 =  0.90, hunger_3 =  0.60,
    hygiene_1 = 0.99, hygiene_2 = 0.95, hygiene_3 = 0.90,
    breath_1 =  0.90, breath_2 =  0.80, breath_3 =  0.60,
    stamina_1 = 0.90, stamina_2 = 0.80, stamina_3 = 0.60,
    weight_1 =  0.95, weight_2 =  0.90, weight_3 =  0.80, weight_4 = 0.70, weight_5 = 0.60,
    hot_1 =     0.99, hot_2 =     0.90, hot_3 =     0.70, hot_4 =    0.40,
    cold_1 =    0.99, cold_2 =    0.90, cold_3 =    0.70, cold_4 =   0.40,
    illness_1 = 0.95, illness_2 = 0.80, illness_3 = 0.60,
    poison_1 =  0.95, poison_2 =  0.80, poison_3 =  0.60,
    legs_1 =    0.99, legs_2 =    0.85, legs_3 =    0.50, legs_4 =   0.90, legs_5 =  0.70, legs_6 = 0.80,
    hands_1 =   0.99, hands_2 =   0.90, hands_3 =   0.70, hands_4 =  0.95, hands_5 = 0.85, hands_6 = 0.90,
}

-- stat effects that can modify the immunity baseline value. the values below modify
-- the immunity baseline value by that factor
local BASE_MOD_IMMUNITY = {
    thirst_1 =    0.99, thirst_2 =    0.95, thirst_3 =    0.90,
    hunger_1 =    0.99, hunger_2 =    0.95, hunger_3 =    0.90,
    alertness_1 = 0.99, alertness_2 = 0.95, alertness_3 = 0.90,
    hygiene_1 =   0.99, hygiene_2 =   0.95, hygiene_3 =   0.90,
    happiness_1 = 0.99, happiness_2 = 0.95, happiness_3 = 0.90,
    cold_1 =      0.99, cold_2 =      0.90, cold_3 =      0.80, cold_4 =   0.60,
}

-- stat effects that can modify the sanity baseline value. the values below modify
-- the sanity baseline value by that factor
local BASE_MOD_SANITY = {
    health_1 =    0.90, health_2 =    0.80,
    alertness_1 = 0.99, alertness_2 = 0.85, alertness_3 = 0.60,
    breath_1 =    0.90, breath_2 =    0.80, breath_3 =    0.60,
}

-- stat effects that can modify the happiness baseline value. the values below modify
-- the happiness baseline value by that factor. Note: happiness baseline value is not
-- directly influenced by many other stat effects. this is because those stat effects
-- already influence 'comfort', and comfort influences happiness. 'alertness' stat
-- effects do not influect comfort, and so directly influence happiness here.
local BASE_MOD_HAPPINESS = {
    alertness_1 = 0.99, alertness_2 = 0.95, alertness_3 = 0.90,
    comfort_1 =   0.90, comfort_2 =   0.80, comfort_3 =   0.60,
}

-- the health drain amount (per second) when the named status effect is triggered
local HEALTH_DRAIN_VALUE = {
    thirst_3 = -0.03,
    hunger_3 = -0.03,
    breath_3 = -5.0,
    hot_3 = -0.06,
    hot_4 = -0.09,
    cold_3 = -0.9,
    cold_4 = -0.12,
    illness_3 = -0.06,
    poison_3 = -0.06,
}

-- the percentage of the health drain amount that is recoverable when the originating
-- status effect is stopped. for example, 0.7 = 70% of the original health drain
-- value is recovered
local HEALTH_RECOVER_FACTOR = {
    thirst = 0.60,
    hunger = 0.60,
    breath = 0.90,
    hot = 0.70,
    cold = 0.50,
    illness = 0.60,
    poison = 0.60,
}


-- multiplier to hands value drain amount when player digs a node or hits a mob
ss.HAND_INJURY_MODIFIERS = {
    ["ss:clothes_gloves_fiber"] = 0.95,
    ["ss:clothes_gloves_fingerless"] = 0.90,
    ["ss:clothes_gloves_leather"] = 0.90,
}

-- multiplier to legs value drain amount when player lands from a jump or a fall
ss.LEG_INJURY_MODIFIERS = {
    ["ss:clothes_socks"] = 0.95,
    ["ss:armor_feet_fiber_1"] = 0.97,
    ["ss:armor_feet_fiber_2"] = 0.95,
    ["ss:armor_feet_cloth_2"] = 0.85,
    ["ss:armor_feet_leather_1"] = 0.90,
}


-- duration of the denoted action in seconds
local VOMIT_DURATION = 4
local SNEEZE_DURATION = 3
local COUGH_DURATION = 4

-- the time in seconds between each denoted action. this is just the base value, while
-- the actual interval time can be shorter or longer based on current immunity stat
local VOMIT_TIMER_LIMIT = 100
local SNEEZE_TIMER_LIMIT = 100
local COUGH_TIMER_LIMIT = 100

-- multiplying factor of the denoted action agaist player's movement speed
local VOMIT_FACTOR_SPEED = 0.05
local SNEEZE_FACTOR_SPEED = 0.05
local COUGH_FACTOR_SPEED = 0.05

-- multiplying factor of the denoted action agaist player's jump height
local VOMIT_FACTOR_JUMP = 0
local SNEEZE_FACTOR_JUMP = 0
local COUGH_FACTOR_JUMP = 0


local flag10 = false
-- certain status effects relating to stats like thirst, hunger, breath, hot,
-- and cold temporarily drains health. this function performs that action of
-- recovering the health that was lost, but limited by HEALTH_RECOVER_FACTOR
--- @param player ObjectRef the player object
--- @param p_data table reference to table with data specific to this player
--- @param player_meta MetaDataRef used to access various player meta data
--- @param effect_name string the status effect name that caused the initial health drain
--- @param total_recover_amount number the total amount of health remaining to recover
local function recover_health(player, p_data, player_meta, stat, effect_name, total_recover_amount)
    debug(flag10, "    recover_health() STATS")
    --debug(flag10, "      effect_name: " .. effect_name)

    local key = "health_rec_from_" .. stat
    --debug(flag10, "      key: " .. key)

    if total_recover_amount > 0 then
        --debug(flag10, "      " .. effect_name .. "-related health to recover: " .. total_recover_amount)
        local stat_current = player_meta:get_float("health_current")
        local health_max = player_meta:get_float("health_max")
        if stat_current < health_max then
            local hp_recover_amount = -HEALTH_DRAIN_VALUE[effect_name] * HEALTH_RECOVER_FACTOR[stat]
            --debug(flag10, "      hp_recover_amount: " .. hp_recover_amount)
            stat_current = stat_current + hp_recover_amount
            if stat_current > health_max then
                hp_recover_amount = hp_recover_amount - (stat_current - health_max)
                --debug(flag10, "      hp_recover_amount clamped to: " .. hp_recover_amount)
                p_data[key] = 0
            else
                p_data[key] = total_recover_amount - hp_recover_amount
                if p_data[key] < 0 then
                    p_data[key] = 0
                end
            end
            do_stat_update_action(player, p_data, player_meta, "normal", "health", hp_recover_amount, "curr", "add", true)

        else
            --debug(flag10, "      health already full. recovery unnecessary.")
            p_data[key] = 0
        end
        player_meta:set_float(key, p_data[key])
    else
        --debug(flag10, "      no " .. effect_name .. "-related health to recover")
    end
    debug(flag10, "    recover_health() END")
end


local flag25 = false
local function sneeze_checker(player, player_meta, player_name, p_data)
    debug(flag25, "  sneeze_checker()")

    if p_data.sneezing_time_remain > 0 then
        --debug(flag25, "    player currently sneezing")
        p_data.sneezing_time_remain = p_data.sneezing_time_remain - 1
        player_meta:set_int("sneezing_time_remain", p_data.sneezing_time_remain)
        --debug(flag25, "    sneezing_time_remain (updated): " .. p_data.sneezing_time_remain)
    else
        --debug(flag25, "    player not sneezing. sneeze_timer: " .. p_data.sneeze_timer)
        if p_data.sneeze_timer >= SNEEZE_TIMER_LIMIT then
            --debug(flag25, "    sneeze_timer reached")
            p_data.sneeze_timer = 0
            player_meta:set_float("sneeze_timer", 0)
            p_data.sneezing_time_remain = SNEEZE_DURATION
            player_meta:set_int("sneezing_time_remain", SNEEZE_DURATION)
            p_data.speed_buff_sneeze = SNEEZE_FACTOR_SPEED
            p_data.jump_buff_sneeze = SNEEZE_FACTOR_JUMP
            update_player_physics(player, {speed = true, jump = true})
            notify(player, "stat_effect", "sneezing...", SNEEZE_DURATION - 1, 0, 0, 2)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "sneeze", severity = "up", delay = 0.5})
            mt_after(1.2, update_visuals, player, player_name, player_meta, "sneeze_1")
            mt_after(2.2, update_visuals, player, player_name, player_meta, "sneeze_0")
            mt_after(2.8, function()
                p_data.speed_buff_sneeze = 1
                p_data.jump_buff_sneeze = 1
                update_player_physics(player, {speed = true, jump = true})
            end)

        else
            --debug(flag25, "    sneeze_timer not reached")
            local sneeze_timer_increment = 1
            if p_data.immunity_ratio < 0.5 then
                local delta_value = 0.5 - p_data.immunity_ratio
                --debug(flag25, "    delta_value: " .. delta_value)

                -- when immunity is between 0% and 50%, sneeze_timer_increment ranges
                -- between 1.5 and 1. assuming SNEEZE_TIMER_LIMIT at default value
                -- of 100, sneezing interval ranges between 67 sec to 1 min 40 sec
                sneeze_timer_increment = 1 + delta_value

            elseif p_data.immunity_ratio > 0.5 then
                local delta_value = p_data.immunity_ratio - 0.5
                --debug(flag25, "    delta_value: " .. delta_value)

                -- when immunity is between 50% and 100%, sneeze_timer_increment ranges
                -- between 1 and 0.625. assuming SNEEZE_TIMER_LIMIT at default value
                -- of 100, sneezing interval ranges between 1 min 40 sec to 2 min 40 sec
                sneeze_timer_increment = 1 - (delta_value * 0.75)

            else
                -- when immunity is at 50%, sneeze_timer_increment will be at default value
                -- of 1. assuming SNEEZE_TIMER_LIMIT at default value of 100, sneezing
                -- interval will be every 1 min 40 sec
            end

            --debug(flag25, "    sneeze_timer_increment: " .. sneeze_timer_increment)
            --sneeze_timer_increment = 9 -- for testing purposes
            p_data.sneeze_timer = p_data.sneeze_timer + sneeze_timer_increment
            player_meta:set_float("sneeze_timer", p_data.sneeze_timer)
        end
    end

    debug(flag25, "  sneeze_checker() END")
end


local flag26 = false
local function continue_sneezing(player, player_meta, player_name, p_data)
    debug(flag26, "  continue_sneezing()")
    if p_data.sneezing_time_remain > 1 then
        --debug(flag26, "    was previously sneezing. re-activate sneezing..")
        --debug(flag26, "    sneezing_time_remain: " .. p_data.sneezing_time_remain)
        --debug(flag26, "    sneeze_timer (should be zero): " .. p_data.sneeze_timer)
        mt_after(0, function()
            p_data.speed_buff_sneeze = SNEEZE_FACTOR_SPEED
            p_data.jump_buff_sneeze = SNEEZE_FACTOR_JUMP
            notify(player, "stat_effect", "sneezing...", p_data.sneezing_time_remain, 0, 0, 2)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "sneeze", severity = "up", delay = 0.5})
            mt_after(1.2, update_visuals, player, player_name, player_meta, "sneeze_1")
            mt_after(2.2, update_visuals, player, player_name, player_meta, "sneeze_0")
            mt_after(2.8, function()
                p_data.speed_buff_sneeze = 1
                p_data.jump_buff_sneeze = 1
                update_player_physics(player, {speed = true, jump = true})
            end)
        end)
    elseif p_data.sneezing_time_remain == 1 then
        --debug(flag26, "    was previously sneezing but mostly already done")
    else
        --debug(flag26, "    was not previously sneezing. no further action.")
    end
    debug(flag26, "  continue_sneezing() END")
end


local flag31 = false
local function cough_checker(player, player_meta, p_data)
    debug(flag31, "  cough_checker()")

    if p_data.coughing_time_remain > 0 then
        --debug(flag31, "    player currently coughing")
        p_data.coughing_time_remain = p_data.coughing_time_remain - 1
        player_meta:set_int("coughing_time_remain", p_data.coughing_time_remain)
        --debug(flag31, "    coughing_time_remain (updated): " .. p_data.coughing_time_remain)
    else
        --debug(flag31, "    player not coughing. cough_timer: " .. p_data.cough_timer)
        if p_data.cough_timer >= COUGH_TIMER_LIMIT then
            --debug(flag31, "    cough_timer reached")
            p_data.cough_timer = 0
            player_meta:set_float("cough_timer", 0)
            p_data.coughing_time_remain = COUGH_DURATION
            player_meta:set_int("coughing_time_remain", COUGH_DURATION)
            p_data.speed_buff_cough = COUGH_FACTOR_SPEED
            p_data.jump_buff_cough = COUGH_FACTOR_JUMP
            update_player_physics(player, {speed = true, jump = true})
            notify(player, "stat_effect", "coughing...", COUGH_DURATION - 1, 0, 0, 2)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cough", severity = "up", delay = 0.5})
            mt_after(4.0, function()
                p_data.speed_buff_cough = 1
                p_data.jump_buff_cough = 1
                update_player_physics(player, {speed = true, jump = true})
            end)

        else
            --debug(flag31, "    cough_timer not reached")
            local cough_timer_increment = 1
            if p_data.immunity_ratio < 0.5 then
                local delta_value = 0.5 - p_data.immunity_ratio
                --debug(flag31, "    delta_value: " .. delta_value)

                -- when immunity is between 0% and 50%, cough_timer_increment ranges
                -- between 1.5 and 1. assuming COUGH_TIMER_LIMIT at default value
                -- of 100, coughing interval ranges between 67 sec to 1 min 40 sec
                cough_timer_increment = 1 + delta_value

            elseif p_data.immunity_ratio > 0.5 then
                local delta_value = p_data.immunity_ratio - 0.5
                --debug(flag31, "    delta_value: " .. delta_value)

                -- when immunity is between 50% and 100%, cough_timer_increment ranges
                -- between 1 and 0.625. assuming COUGH_TIMER_LIMIT at default value
                -- of 100, coughing interval ranges between 1 min 40 sec to 2 min 40 sec
                cough_timer_increment = 1 - (delta_value * 0.75)

            else
                -- when immunity is at 50%, cough_timer_increment will be at default value
                -- of 1. assuming COUGH_TIMER_LIMIT at default value of 100, coughing
                -- interval will be every 1 min 40 sec
            end

            --debug(flag31, "    cough_timer_increment: " .. cough_timer_increment)
            --cough_timer_increment = 9 -- for testing purposes
            p_data.cough_timer = p_data.cough_timer + cough_timer_increment
            player_meta:set_float("cough_timer", p_data.cough_timer)
        end
    end

    debug(flag31, "  cough_checker() END")
end


local flag32 = false
local function continue_coughing(player, p_data)
    debug(flag32, "  continue_coughing()")
    if p_data.coughing_time_remain > 1 then
        --debug(flag32, "    was previously coughing. re-activate coughing..")
        --debug(flag32, "    coughing_time_remain: " .. p_data.coughing_time_remain)
        --debug(flag32, "    cough_timer (should be zero): " .. p_data.cough_timer)
        mt_after(0, function()
            p_data.speed_buff_cough = COUGH_FACTOR_SPEED
            p_data.jump_buff_cough = COUGH_FACTOR_JUMP
            notify(player, "stat_effect", "coughing...", p_data.coughing_time_remain, 0, 0, 2)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "cough", severity = "up", delay = 0.5})
            mt_after(4.0, function()
                p_data.speed_buff_cough = 1
                p_data.jump_buff_cough = 1
                update_player_physics(player, {speed = true, jump = true})
            end)
        end)
    elseif p_data.coughing_time_remain == 1 then
        --debug(flag32, "    was previously coughing but mostly already done")
    else
        --debug(flag32, "    was not previously coughing. no further action.")
    end
    debug(flag32, "  continue_coughing() END")
end


local flag33 = false
local function vomit_checker(player, player_meta, player_name, p_data, severity)
    debug(flag33, "  vomit_checker()")

    if p_data.vomitting_time_remain > 0 then
        --debug(flag33, "    player currently vomitting")
        p_data.vomitting_time_remain = p_data.vomitting_time_remain - 1
        player_meta:set_int("vomitting_time_remain", p_data.vomitting_time_remain)

        -- decrease water, food, and hygiene
        local drain_amount = math_random() * -1.2 * severity
        --debug(flag33, "    thirst drain_amount: " .. drain_amount)
        do_stat_update_action(player, p_data, player_meta, "se_poison_" .. severity, "thirst", drain_amount, "curr", "add", true)
        drain_amount = math_random() * -1.2 * severity
        --debug(flag33, "    hunger drain_amount: " .. drain_amount)
        do_stat_update_action(player, p_data, player_meta, "se_poison_" .. severity, "hunger", drain_amount, "curr", "add", true)
        drain_amount = math_random() * -1.0 * severity
        --debug(flag33, "    hygiene drain_amount: " .. drain_amount)
        do_stat_update_action(player, p_data, player_meta, "se_poison_" .. severity, "hygiene", drain_amount, "curr", "add", true)

        --debug(flag33, "    vomitting_time_remain (updated): " .. p_data.vomitting_time_remain)
    else
        --debug(flag33, "    player not vomitting. vomit_timer: " .. p_data.vomit_timer)
        if p_data.vomit_timer >= VOMIT_TIMER_LIMIT then
            --debug(flag33, "    vomit_timer reached")
            p_data.vomit_timer = 0
            player_meta:set_float("vomit_timer", 0)
            p_data.vomitting_time_remain = VOMIT_DURATION
            player_meta:set_int("vomitting_time_remain", VOMIT_DURATION)
            p_data.speed_buff_vomit = VOMIT_FACTOR_SPEED
            p_data.jump_buff_vomit = VOMIT_FACTOR_JUMP
            update_player_physics(player, {speed = true, jump = true})
            notify(player, "stat_effect", "vomitting...", VOMIT_DURATION - 1, 0, 0, 2)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "vomit", severity = "up", delay = 0.5})
            mt_after(0.25, update_visuals, player, player_name, player_meta, "vomit_1")
            mt_after(4.0, update_visuals, player, player_name, player_meta, "vomit_0")
            mt_after(4.5, function()
                p_data.speed_buff_vomit = 1
                p_data.jump_buff_vomit = 1
                update_player_physics(player, {speed = true, jump = true})
            end)

        else
            --debug(flag33, "    vomit_timer not reached")
            local vomit_timer_increment = 1
            if p_data.immunity_ratio < 0.5 then
                local delta_value = 0.5 - p_data.immunity_ratio
                --debug(flag33, "    delta_value: " .. delta_value)

                -- when immunity is between 0% and 50%, vomit_timer_increment ranges
                -- between 1.5 and 1. assuming VOMIT_TIMER_LIMIT at default value
                -- of 100, vomitting interval ranges between 67 sec to 1 min 40 sec
                vomit_timer_increment = 1 + delta_value

            elseif p_data.immunity_ratio > 0.5 then
                local delta_value = p_data.immunity_ratio - 0.5
                --debug(flag33, "    delta_value: " .. delta_value)

                -- when immunity is between 50% and 100%, vomit_timer_increment ranges
                -- between 1 and 0.625. assuming VOMIT_TIMER_LIMIT at default value
                -- of 100, vomitting interval ranges between 1 min 40 sec to 2 min 40 sec
                vomit_timer_increment = 1 - (delta_value * 0.75)

            else
                -- when immunity is at 50%, vomit_timer_increment will be at default value
                -- of 1. assuming VOMIT_TIMER_LIMIT at default value of 100, vomitting
                -- interval will be every 1 min 40 sec
            end

            --debug(flag33, "    vomit_timer_increment: " .. vomit_timer_increment)
            --vomit_timer_increment = 9 -- for testing purposes
            p_data.vomit_timer = p_data.vomit_timer + vomit_timer_increment
            player_meta:set_float("vomit_timer", p_data.vomit_timer)
        end
    end

    debug(flag33, "  vomit_checker() END")
end


local flag34 = false
local function continue_vomitting(player, player_meta, player_name, p_data)
    debug(flag34, "  continue_vomitting()")
    if p_data.vomitting_time_remain > 1 then
        --debug(flag34, "    was previously vomitting. re-activate vomitting..")
        --debug(flag34, "    vomitting_time_remain: " .. p_data.vomitting_time_remain)
        --debug(flag34, "    vomit_timer (should be zero): " .. p_data.vomit_timer)
        mt_after(0, function()
            p_data.speed_buff_vomit = VOMIT_FACTOR_SPEED
            p_data.jump_buff_vomit = VOMIT_FACTOR_JUMP
            notify(player, "stat_effect", "vomitting...", p_data.vomitting_time_remain, 0, 0, 2)
            play_sound("stat_effect", {player = player, p_data = p_data, stat = "vomit", severity = "up", delay = 0.5})
            mt_after(0.25, update_visuals, player, player_name, player_meta, "vomit_1")
            mt_after(4.0, update_visuals, player, player_name, player_meta, "vomit_0")
            mt_after(4.5, function()
                p_data.speed_buff_vomit = 1
                p_data.jump_buff_vomit = 1
                update_player_physics(player, {speed = true, jump = true})
            end)
        end)
    elseif p_data.vomitting_time_remain == 1 then
        --debug(flag34, "    was previously vomitting but mostly already done")
    else
        --debug(flag34, "    was not previously vomitting. no further action.")
    end
    debug(flag34, "  continue_vomitting() END")
end




local flag22 = false
local function try_noise(player, player_meta, source)
    debug(flag22, "start_noise()")
    after_player_check(player)

    --debug(flag22, "  source: " .. source)

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]

    if p_data.player_vocalizing then
        --debug(flag22, "  a stat effect sound currently active. skipping try_noise()")
        --debug(flag22, "start_noise() end")
        return
    end

    local noise_factor
    local random_num = math_random(1, 100)
    --random_num = 1 -- for testing purposes

    --debug(flag22, "  random_num: " .. random_num)
    if source == "ingest" then
        noise_factor = p_data.noise_chance_choke * p_data.noise_mod_unchokeable
        --debug(flag22, "  noise_factor: " .. noise_factor)
        if random_num <= noise_factor then
            p_data.coughing_time_remain = 0
            p_data.cough_timer = COUGH_TIMER_LIMIT
            cough_checker(player, player_meta, p_data)
            p_data.coughing_time_remain = 0
            player_meta:set_int("coughing_time_remain", p_data.coughing_time_remain)
            mt_after(5, try_noise, player, player_meta, "stress")
        end

    elseif source == "plants" then
        noise_factor = p_data.noise_chance_sneeze_plants * p_data.noise_mod_booger_barrier
        --debug(flag22, "  noise_factor: " .. noise_factor)
        if random_num <= noise_factor then
            p_data.sneezing_time_remain = 0
            p_data.sneeze_timer = SNEEZE_TIMER_LIMIT
            sneeze_checker(player, player_meta, player_name, p_data)
            p_data.sneezing_time_remain = 0
            player_meta:set_int("sneezing_time_remain", p_data.sneezing_time_remain)
            mt_after(5, try_noise, player, player_meta, "stress")
        end

    elseif source == "dust" then
        noise_factor = p_data.noise_chance_sneeze_dust * p_data.noise_mod_booger_barrier
        --debug(flag22, "  noise_factor: " .. noise_factor)
        if random_num <= noise_factor then
            p_data.sneezing_time_remain = 0
            p_data.sneeze_timer = SNEEZE_TIMER_LIMIT
            sneeze_checker(player, player_meta, player_name, p_data)
            p_data.sneezing_time_remain = 0
            player_meta:set_int("sneezing_time_remain", p_data.sneezing_time_remain)
            mt_after(5, try_noise, player, player_meta, "stress")
        end

    elseif source == "stress" then
        noise_factor = p_data.noise_chance_hickups * p_data.noise_mod_unhiccable
        --debug(flag22, "  noise_factor: " .. noise_factor)
        if random_num <= noise_factor then
            notify(player, "noise", "* hiccup *", 2, 0, 0, 2)
        end
    end

    debug(flag22, "start_noise() end")
end

-- global wrapper to keep try_noise() as a local function for speed
function ss.start_try_noise(player, player_meta, source)
    try_noise(player, player_meta, source)
end




local flag20 = false
-- monitors for active status effects and triggers health consequences (stat updates)
-- depending on the type and severity of the setatus effect
local function monitor_status_effects(player, player_meta, player_name, p_data, status_effects)
    debug(flag20, "\nmonitor_status_effects()")
    after_player_check(player)

    ------------
    -- HEALTH --
    ------------
    -- 100% to 31%  (normal range)
    -- 30% to 11%   'health_1'  comfort-, comfort_base-, sanity_base-
    -- 10% to 1%    'health_2'  comfort--, comfort_base--, sanity_base--
    -- 0%           (dead)

    if status_effects.health_1 then
        --debug(flag20, "  applying stat effect for health_1")
        if p_data.health_1_applied then
            --debug(flag20, "    health_1 single actions already applied. no further action.")
        else
            --debug(flag20, "    add screen overlay and lower color saturation to 25%")
            update_visuals(player, player_name, player_meta, "health_1")
            p_data.base_comfort_mod_health = BASE_MOD_COMFORT.health_1
            p_data.base_sanity_mod_health = BASE_MOD_SANITY.health_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "sanity"})
            p_data.health_1_applied = true
            p_data.health_2_applied = false
            p_data.health_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_health_1", "comfort", DRAIN_VAL_2, "curr", "add", true)

    elseif status_effects.health_2 then
        --debug(flag20, "  applying stat effect for health_2")
        if p_data.health_2_applied then
            --debug(flag20, "    health_2 single actions already applied. no further action.")
        else
            --debug(flag20, "    add screen overlay and lower color saturation to 10%")
            update_visuals(player, player_name, player_meta, "health_2")
            p_data.base_comfort_mod_health = BASE_MOD_COMFORT.health_2
            p_data.base_sanity_mod_health = BASE_MOD_SANITY.health_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "sanity"})
            p_data.health_1_applied = false
            p_data.health_2_applied = true
            p_data.health_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_health_1", "comfort", DRAIN_VAL_3, "curr", "add", true)

    elseif status_effects.health_3 then
        --debug(flag20, "  applying stat effect for health_3")
        if p_data.health_3_applied then
            --debug(flag20, "    health_3 single actions already applied. no further action.")
        else
            --debug(flag20, "    add screen overlay and lower color saturation to 0%")
            update_visuals(player, player_name, player_meta, "health_3")
            -- no further actions to perform here since player is dead
            p_data.health_1_applied = false
            p_data.health_2_applied = false
            p_data.health_3_applied = true
        end

    else
        --debug(flag20, "  no active 'health' stat effects")
        if p_data.health_1_applied or p_data.health_2_applied or p_data.health_3_applied then
            update_visuals(player, player_name, player_meta, "health_0")
            p_data.base_comfort_mod_health = 1
            p_data.base_sanity_mod_health = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "sanity"})
            p_data.health_1_applied = false
            p_data.health_2_applied = false
            p_data.health_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    ------------
    -- THIRST --
    ------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'thirst_1'  stamina drain+, immunity-, comfort-, health_base-, comfort_base-, immunity_base-
    -- 30% to 11%  'thirst_2'  stamina drain++, immunity--, comfort--, health_base--, comfort_base--, immunity_base--
    -- 10% to 0%   'thirst_3'  stamina drain+++, immunity---, comfort---, health---, health_base---, comfort_base---, immunity_base---

    if status_effects.thirst_1 then
        --debug(flag20, "  applying stat effect for thirst_1")

        if p_data.thirst_1_applied then
            --debug(flag20, "    thirst_1 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_thirst = 1.2
            player_meta:set_float("stamina_drain_mod_thirst", 1.2)
            p_data.base_health_mod_thirst = BASE_MOD_HEALTH.thirst_1
            p_data.base_comfort_mod_thirst = BASE_MOD_COMFORT.thirst_1
            p_data.base_immunity_mod_thirst = BASE_MOD_IMMUNITY.thirst_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.thirst_1_applied = true
            p_data.thirst_2_applied = false
            p_data.thirst_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_thirst_1", "comfort", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_thirst_1", "immunity", DRAIN_VAL_1, "curr", "add", true)
        recover_health(player, p_data, player_meta, "thirst", "thirst_3", p_data.health_rec_from_thirst)

    elseif status_effects.thirst_2 then
        --debug(flag20, "  applying stat effect for thirst_2")

        if p_data.thirst_2_applied then
            --debug(flag20, "    thirst_2 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_thirst = 1.3
            player_meta:set_float("stamina_drain_mod_thirst", 1.3)
            p_data.base_health_mod_thirst = BASE_MOD_HEALTH.thirst_2
            p_data.base_comfort_mod_thirst = BASE_MOD_COMFORT.thirst_2
            p_data.base_immunity_mod_thirst = BASE_MOD_IMMUNITY.thirst_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.thirst_1_applied = false
            p_data.thirst_2_applied = true
            p_data.thirst_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_thirst_2", "comfort", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_thirst_2", "immunity", DRAIN_VAL_2, "curr", "add", true)
        recover_health(player, p_data, player_meta, "thirst", "thirst_3", p_data.health_rec_from_thirst)

    elseif status_effects.thirst_3 then
        --debug(flag20, "  applying stat effect for thirst_3")

        if p_data.thirst_3_applied then
            --debug(flag20, "    thirst_3 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_thirst = 1.5
            player_meta:set_float("stamina_drain_mod_thirst", 1.5)
            p_data.base_health_mod_thirst = BASE_MOD_HEALTH.thirst_3
            p_data.base_comfort_mod_thirst = BASE_MOD_COMFORT.thirst_3
            p_data.base_immunity_mod_thirst = BASE_MOD_IMMUNITY.thirst_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.thirst_1_applied = false
            p_data.thirst_2_applied = false
            p_data.thirst_3_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_thirst_3", "comfort", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_thirst_3", "immunity", DRAIN_VAL_3, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.thirst_3 * p_data.health_drain_mod_sipless_survivor
        do_stat_update_action(player, p_data, player_meta, "se_thirst_3", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_thirst = p_data.health_rec_from_thirst + (-drain_amount * HEALTH_RECOVER_FACTOR.thirst)
        player_meta:set_float("health_rec_from_thirst", p_data.health_rec_from_thirst)

    else
        --debug(flag20, "  no active 'thirst' stat effects")
        if p_data.thirst_1_applied or p_data.thirst_2_applied or p_data.thirst_3_applied then
            --debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.stamina_drain_mod_thirst = 1
            player_meta:set_float("stamina_drain_mod_thirst", 1)
            p_data.base_health_mod_thirst = 1
            p_data.base_comfort_mod_thirst = 1
            p_data.base_immunity_mod_thirst = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.thirst_1_applied = false
            p_data.thirst_2_applied = false
            p_data.thirst_3_applied = false
        else
            --debug(flag20, "    and was not previously active")
            recover_health(player, p_data, player_meta, "thirst", "thirst_3", p_data.health_rec_from_thirst)
        end
    end


    ------------
    -- HUNGER --
    ------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'hunger_1'  stamina drain+, immunity-, comfort-, health_base-, comfort_base-, immunity_base-
    -- 30% to 11%  'hunger_2'  stamina drain++, immunity--, comfort--, health_base--, comfort_base--, immunity_base--
    -- 10% to 0%   'hunger_3'  stamina drain+++, immunity---, comfort---, health---, health_base---, comfort_base---, immunity_base---

    if status_effects.hunger_1 then
        --debug(flag20, "  applying stat effect for hunger_1")

        if p_data.hunger_1_applied then
            --debug(flag20, "    hunger_1 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_hunger = 1.2
            player_meta:set_float("stamina_drain_mod_hunger", 1.2)
            p_data.base_health_mod_hunger = BASE_MOD_HEALTH.hunger_1
            p_data.base_comfort_mod_hunger = BASE_MOD_COMFORT.hunger_1
            p_data.base_immunity_mod_hunger = BASE_MOD_IMMUNITY.hunger_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.hunger_1_applied = true
            p_data.hunger_2_applied = false
            p_data.hunger_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_hunger_1", "comfort", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hunger_1", "immunity", DRAIN_VAL_1, "curr", "add", true)
        recover_health(player, p_data, player_meta, "hunger", "hunger_3", p_data.health_rec_from_hunger)

    elseif status_effects.hunger_2 then
        --debug(flag20, "  applying stat effect for hunger_2")

        if p_data.hunger_2_applied then
            --debug(flag20, "    hunger_2 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_hunger = 1.3
            player_meta:set_float("stamina_drain_mod_hunger", 1.3)
            p_data.base_health_mod_hunger = BASE_MOD_HEALTH.hunger_2
            p_data.base_comfort_mod_hunger = BASE_MOD_COMFORT.hunger_2
            p_data.base_immunity_mod_hunger = BASE_MOD_IMMUNITY.hunger_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.hunger_1_applied = false
            p_data.hunger_2_applied = true
            p_data.hunger_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_hunger_2", "comfort", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hunger_2", "immunity", DRAIN_VAL_2, "curr", "add", true)
        recover_health(player, p_data, player_meta, "hunger", "hunger_3", p_data.health_rec_from_hunger)

    elseif status_effects.hunger_3 then
        --debug(flag20, "  applying stat effect for hunger_3")

        if p_data.hunger_3_applied then
            --debug(flag20, "    hunger_3 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_hunger = 1.5
            player_meta:set_float("stamina_drain_mod_hunger", 1.5)
            p_data.base_health_mod_hunger = BASE_MOD_HEALTH.hunger_3
            p_data.base_comfort_mod_hunger = BASE_MOD_COMFORT.hunger_3
            p_data.base_immunity_mod_hunger = BASE_MOD_IMMUNITY.hunger_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.hunger_1_applied = false
            p_data.hunger_2_applied = false
            p_data.hunger_3_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hunger_3", "comfort", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hunger_3", "immunity", DRAIN_VAL_3, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.hunger_3 * p_data.health_drain_mod_foodless_freak
        do_stat_update_action(player, p_data, player_meta, "se_hunger_3", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_hunger = p_data.health_rec_from_hunger + (-drain_amount * HEALTH_RECOVER_FACTOR.hunger)
        player_meta:set_float("health_rec_from_hunger", p_data.health_rec_from_hunger)

    else
        --debug(flag20, "  no active 'hunger' stat effects")
        if p_data.hunger_1_applied or p_data.hunger_2_applied or p_data.hunger_3_applied then
            --debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.stamina_drain_mod_hunger = 1
            player_meta:set_float("stamina_drain_mod_hunger", 1)
            p_data.base_health_mod_hunger = 1
            p_data.base_comfort_mod_hunger = 1
            p_data.base_immunity_mod_hunger = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.hunger_1_applied = false
            p_data.hunger_2_applied = false
            p_data.hunger_3_applied = false
        else
            --debug(flag20, "    and was not previously active")
            recover_health(player, p_data, player_meta, "hunger", "hunger_3", p_data.health_rec_from_hunger)
        end
    end


    ---------------
    -- ALERTNESS --
    ---------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'alertness_1' immunity-, sanity-, happiness-, stamina drain+, illness+, health_base-, immunity_base-, sanity_base-, happiness_base-
    -- 30% to 11%  'alertness_2' immunity--, sanity--, happiness--, stamina drain++, illness++, health_base--, immunity_base--, sanity_base--, happiness_base--
    -- 10% to 0%   'alertness_3' immunity---, sanity---, happiness---, stamina drain+++, illness+++, health_base---, immunity_base---, sanity_base---, happiness_base---

    if status_effects.alertness_1 then
        --debug(flag20, "  applying stat effect for alertness_1")
        if p_data.alertness_1_applied then
            --debug(flag20, "    alertness_1 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_alertness = 1.2
            player_meta:set_float("stamina_drain_mod_alertness", 1.2)
            p_data.base_health_mod_alertness = BASE_MOD_HEALTH.alertness_1
            p_data.base_immunity_mod_alertness = BASE_MOD_IMMUNITY.alertness_1
            p_data.base_sanity_mod_alertness = BASE_MOD_SANITY.alertness_1
            p_data.base_happiness_mod_alertness = BASE_MOD_HAPPINESS.alertness_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "immunity", "sanity", "happiness"})
            p_data.alertness_1_applied = true
            p_data.alertness_2_applied = false
            p_data.alertness_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_alertness_1", "immunity", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_alertness_1", "sanity", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_alertness_1", "happiness", DRAIN_VAL_1, "curr", "add", true)
        --debug(flag20, "    increasing illness")
        local drain_amount = 0.01 * p_data.illness_drain_mod_sniffle_shield
        do_stat_update_action(player, p_data, player_meta, "se_alertness_1", "illness", drain_amount, "curr", "add", true)

    elseif status_effects.alertness_2 then
        --debug(flag20, "  applying stat effect for alertness_2")
        if p_data.alertness_2_applied then
            --debug(flag20, "    alertness_2 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_alertness = 1.3
            player_meta:set_float("stamina_drain_mod_alertness", 1.3)
            p_data.base_health_mod_alertness = BASE_MOD_HEALTH.alertness_2
            p_data.base_immunity_mod_alertness = BASE_MOD_IMMUNITY.alertness_2
            p_data.base_sanity_mod_alertness = BASE_MOD_SANITY.alertness_2
            p_data.base_happiness_mod_alertness = BASE_MOD_HAPPINESS.alertness_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "immunity", "sanity", "happiness"})
            p_data.alertness_1_applied = false
            p_data.alertness_2_applied = true
            p_data.alertness_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_alertness_2", "immunity", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_alertness_2", "sanity", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_alertness_2", "happiness", DRAIN_VAL_2, "curr", "add", true)
        --debug(flag20, "    increasing illness")
        local drain_amount = 0.02 * p_data.illness_drain_mod_sniffle_shield
        do_stat_update_action(player, p_data, player_meta, "se_alertness_2", "illness", drain_amount, "curr", "add", true)

    elseif status_effects.alertness_3 then
        --debug(flag20, "  applying stat effect for alertness_3")
        if p_data.alertness_3_applied then
            --debug(flag20, "    alertness_3 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_alertness = 1.5
            player_meta:set_float("stamina_drain_mod_alertness", 1.5)
            p_data.base_health_mod_alertness = BASE_MOD_HEALTH.alertness_3
            p_data.base_immunity_mod_alertness = BASE_MOD_IMMUNITY.alertness_3
            p_data.base_sanity_mod_alertness = BASE_MOD_SANITY.alertness_3
            p_data.base_happiness_mod_alertness = BASE_MOD_HAPPINESS.alertness_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "immunity", "sanity", "happiness"})
            p_data.alertness_1_applied = false
            p_data.alertness_2_applied = false
            p_data.alertness_3_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_alertness_3", "immunity", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_alertness_3", "sanity", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_alertness_3", "happiness", DRAIN_VAL_3, "curr", "add", true)
        --debug(flag20, "    increasing illness")
        local drain_amount = 0.04 * p_data.illness_drain_mod_sniffle_shield
        do_stat_update_action(player, p_data, player_meta, "se_alertness_3", "illness", drain_amount, "curr", "add", true)

    else
        --debug(flag20, "  no active 'alertness' stat effects")
        if p_data.alertness_1_applied or p_data.alertness_2_applied or p_data.alertness_3_applied then
            --debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.stamina_drain_mod_alertness = 1
            player_meta:set_float("stamina_drain_mod_alertness", 1)
            p_data.base_health_mod_alertness = 1
            p_data.base_immunity_mod_alertness = 1
            p_data.base_sanity_mod_alertness = 1
            p_data.base_happiness_mod_alertness = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "immunity", "sanity", "happiness"})
            p_data.alertness_1_applied = false
            p_data.alertness_2_applied = false
            p_data.alertness_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    -------------
    -- HYGIENE --
    -------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'hygiene_1'  comfort_base-, immunity_base-
    -- 30% to 11%  'hygiene_2'  comfort-, comfort_base--, immunity_base--
    -- 10% to 0%   'hygiene_3'  comfort--, immunity-, comfort_base---, immunity_base---

    if status_effects.hygiene_1 then
        --debug(flag20, "  applying stat effect for hygiene_1")
        if p_data.hygiene_1_applied then
            --debug(flag20, "    hygiene_1 single actions already applied. no further action.")
        else
            p_data.base_comfort_mod_hygiene = BASE_MOD_COMFORT.hygiene_1
            p_data.base_immunity_mod_hygiene = BASE_MOD_IMMUNITY.hygiene_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "immunity"})
            p_data.hygiene_1_applied = true
            p_data.hygiene_2_applied = false
            p_data.hygiene_3_applied = false
        end

    elseif status_effects.hygiene_2 then
        --debug(flag20, "  applying stat effect for hygiene_2")
        if p_data.hygiene_2_applied then
            --debug(flag20, "    hygiene_2 single actions already applied. no further action.")
        else
            p_data.base_comfort_mod_hygiene = BASE_MOD_COMFORT.hygiene_2
            p_data.base_immunity_mod_hygiene = BASE_MOD_IMMUNITY.hygiene_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "immunity"})
            p_data.hygiene_1_applied = false
            p_data.hygiene_2_applied = true
            p_data.hygiene_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hygiene_2", "comfort", DRAIN_VAL_0, "curr", "add", true)

    elseif status_effects.hygiene_3 then
        --debug(flag20, "  applying stat effect for hygiene_3")
        if p_data.hygiene_3_applied then
            --debug(flag20, "    hygiene_3 single actions already applied. no further action.")
        else
            p_data.base_comfort_mod_hygiene = BASE_MOD_COMFORT.hygiene_3
            p_data.base_immunity_mod_hygiene = BASE_MOD_IMMUNITY.hygiene_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "immunity"})
            p_data.hygiene_1_applied = false
            p_data.hygiene_2_applied = false
            p_data.hygiene_3_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hygiene_3", "immunity", DRAIN_VAL_0, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hygiene_3", "comfort", DRAIN_VAL_1, "curr", "add", true)

    else
        --debug(flag20, "  no active 'hygiene' stat effects")
        if p_data.hygiene_1_applied or p_data.hygiene_2_applied or p_data.hygiene_3_applied then
            p_data.base_comfort_mod_hygiene = 1
            p_data.base_immunity_mod_hygiene = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "immunity"})
            p_data.hygiene_1_applied = false
            p_data.hygiene_2_applied = false
            p_data.hygiene_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    -------------
    -- COMFORT --
    -------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'comfort_1' "tense" happiness-, happiness_base-
    -- 30% to 11%  'comfort_2' "restless" happiness--, happiness_base--
    -- 10% to 0%   'comfort_3' "uncomfortable" happiness---, happiness_base---

    if status_effects.comfort_1 then
        --debug(flag20, "  applying stat effect for comfort_1")
        if p_data.comfort_1_applied then
            --debug(flag20, "    comfort_1 single actions already applied. no further action.")
        else
            p_data.base_happiness_mod_comfort = BASE_MOD_HAPPINESS.comfort_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"happiness"})
            p_data.comfort_1_applied = true
            p_data.comfort_2_applied = false
            p_data.comfort_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_comfort_1", "happiness", DRAIN_VAL_1, "curr", "add", true)

    elseif status_effects.comfort_2 then
        --debug(flag20, "  applying stat effect for comfort_2")
        if p_data.comfort_2_applied then
            --debug(flag20, "    comfort_2 single actions already applied. no further action.")
        else
            p_data.base_happiness_mod_comfort = BASE_MOD_HAPPINESS.comfort_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"happiness"})
            p_data.comfort_1_applied = false
            p_data.comfort_2_applied = true
            p_data.comfort_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_comfort_2", "happiness", DRAIN_VAL_2, "curr", "add", true)

    elseif status_effects.comfort_3 then
        --debug(flag20, "  applying stat effect for comfort_3")
        if p_data.comfort_3_applied then
            --debug(flag20, "    comfort_3 single actions already applied. no further action.")
        else
            p_data.base_happiness_mod_comfort = BASE_MOD_HAPPINESS.comfort_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"happiness"})
            p_data.comfort_1_applied = false
            p_data.comfort_2_applied = false
            p_data.comfort_3_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_comfort_3", "happiness", DRAIN_VAL_3, "curr", "add", true)

    else
        --debug(flag20, "  no active 'comfort' stat effects")
        if p_data.comfort_1_applied or p_data.comfort_2_applied or p_data.comfort_3_applied then
            --debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.base_happiness_mod_comfort = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"happiness"})
            p_data.comfort_1_applied = false
            p_data.comfort_2_applied = false
            p_data.comfort_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    --------------
    -- IMMUNITY --
    --------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'immunity_1' "weak" health_base-
    -- 30% to 11%  'immunity_2' "very weak" health_base--
    -- 10% to 0%   'immunity_3' "weak and sickly" health_base---
    if status_effects.immunity_1 then
        --debug(flag20, "  applying stat effect for immunity_1")
        if p_data.immunity_1_applied then
            --debug(flag20, "    immunity_1 single actions already applied. no further action.")
        else
            p_data.base_health_mod_immunity = BASE_MOD_HEALTH.immunity_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health"})
            p_data.immunity_1_applied = true
            p_data.immunity_2_applied = false
            p_data.immunity_3_applied = false
        end

    elseif status_effects.immunity_2 then
        --debug(flag20, "  applying stat effect for immunity_2")
        if p_data.immunity_2_applied then
            --debug(flag20, "    immunity_2 single actions already applied. no further action.")
        else
            p_data.base_health_mod_immunity = BASE_MOD_HEALTH.immunity_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health"})
            p_data.immunity_1_applied = false
            p_data.immunity_2_applied = true
            p_data.immunity_3_applied = false
        end

    elseif status_effects.immunity_3 then
        --debug(flag20, "  applying stat effect for immunity_2")
        if p_data.immunity_3_applied then
            --debug(flag20, "    immunity_3 single actions already applied. no further action.")
        else
            p_data.base_health_mod_immunity = BASE_MOD_HEALTH.immunity_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health"})
            p_data.immunity_1_applied = false
            p_data.immunity_2_applied = false
            p_data.immunity_3_applied = true
        end

    else
        --debug(flag20, "  no active 'immunity' stat effects")
        if p_data.immunity_1_applied or p_data.immunity_2_applied or p_data.immunity_3_applied then
            --debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.base_health_mod_immunity = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health"})
            p_data.hunger_1_applied = false
            p_data.hunger_2_applied = false
            p_data.hunger_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    ------------
    -- SANITY --
    ------------

    if status_effects.sanity_1 then
        --debug(flag20, "  no stat effect actions implemented for sanity_1")

    elseif status_effects.sanity_2 then
        --debug(flag20, "  no stat effect actions implemented for sanity_2")

    elseif status_effects.sanity_3 then
        --debug(flag20, "  no stat effect actions implemented for sanity_3")

    else
        --debug(flag20, "  no active 'sanity' stat effects")
    end


    ---------------
    -- HAPPINESS --
    ---------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'happiness_1'   immunity-, immunity_base-
    -- 30% to 11%  'happiness_2'   immunity--, immunity_base--
    -- 10% to 0%   'happiness_3'   immunity---, immunity_base---

    if status_effects.happiness_1 then
        --debug(flag20, "  applying stat effect for happiness_1")
        if p_data.happiness_1_applied then
            --debug(flag20, "    happiness_1 single actions already applied. no further action.")
        else
            p_data.base_immunity_mod_happiness = BASE_MOD_IMMUNITY.happiness_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"immunity"})
            p_data.happiness_1_applied = true
            p_data.happiness_2_applied = false
            p_data.happiness_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_happiness_3", "immunity", DRAIN_VAL_0, "curr", "add", true)

    elseif status_effects.happiness_2 then
        --debug(flag20, "  applying stat effect for happiness_2")
        if p_data.happiness_2_applied then
            --debug(flag20, "    happiness_2 single actions already applied. no further action.")
        else
            p_data.base_immunity_mod_happiness = BASE_MOD_IMMUNITY.happiness_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"immunity"})
            p_data.happiness_1_applied = false
            p_data.happiness_2_applied = true
            p_data.happiness_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_happiness_3", "immunity", DRAIN_VAL_1, "curr", "add", true)

    elseif status_effects.happiness_3 then
        --debug(flag20, "  applying stat effect for happiness_3")
        if p_data.happiness_3_applied then
            --debug(flag20, "    happiness_3 single actions already applied. no further action.")
        else
            p_data.base_immunity_mod_happiness = BASE_MOD_IMMUNITY.happiness_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"immunity"})
            p_data.happiness_1_applied = false
            p_data.happiness_2_applied = false
            p_data.happiness_3_applied = true
        end
        do_stat_update_action(player, p_data, player_meta, "se_happiness_3", "immunity", DRAIN_VAL_2, "curr", "add", true)
    else
        --debug(flag20, "  no active 'happiness' stat effects")
    end


    ----------
    -- LEGS --
    ----------
    -- 100% to 61%  (normal range)
    -- 60% to 41%   'legs_1' "sore" speed-, jump-, comfort-, health_base-, comfort_base-
    -- 40% to 21%   'legs_2' "sprained" speed--, jump--, comfort--, health_base--, comfort_base--
    -- 20% to 0%    'legs_3' "broken" speed---, jump---, comfort---, health_base---, comfort_base---
    -- 40% to 31%    'legs_4' "splinted sprain" speed--, jump--, comfort-, health_base--, comfort_base--, legs+
    -- 40% to 31%    'legs_5' "splinted break" speed--, jump--, comfort-, health_base--, comfort_base--, legs+
    -- 30% to 21%    'legs_6' "casted break" speed--, jump--, comfort-, health_base-, comfort_base--, legs+
    if status_effects.legs_1 then
        --debug(flag20, "  applying stat effect for legs_1")

        if p_data.legs_1_applied then
            --debug(flag20, "    legs_1 single actions already applied. no further action.")
        else
            p_data.legs_recovery_status = 0
            player_meta:set_int("legs_recovery_status", 0)
            p_data.speed_buff_legs = 0.98
            p_data.jump_buff_legs = 0.98
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_health_mod_legs = BASE_MOD_HEALTH.legs_1
            p_data.base_comfort_mod_legs = BASE_MOD_COMFORT.legs_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.legs_1_applied = true
            p_data.legs_2_applied = false
            p_data.legs_3_applied = false
            p_data.legs_4_applied = false
            p_data.legs_5_applied = false
            p_data.legs_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_legs_1", "comfort", DRAIN_VAL_0, "curr", "add", true)

    elseif status_effects.legs_2 then
        --debug(flag20, "  applying stat effect for legs_2")

        if p_data.legs_2_applied then
            --debug(flag20, "    legs_2 single actions already applied. no further action.")
        else
            p_data.legs_recovery_status = 0
            player_meta:set_int("legs_recovery_status", 0)
            p_data.speed_buff_legs = 0.94
            p_data.jump_buff_legs = 0.94
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_health_mod_legs = BASE_MOD_HEALTH.legs_2
            p_data.base_comfort_mod_legs = BASE_MOD_COMFORT.legs_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.legs_1_applied = false
            p_data.legs_2_applied = true
            p_data.legs_3_applied = false
            p_data.legs_4_applied = false
            p_data.legs_5_applied = false
            p_data.legs_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_legs_2", "comfort", DRAIN_VAL_2, "curr", "add", true)

    elseif status_effects.legs_3 then
        --debug(flag20, "  applying stat effect for legs_3")

        if p_data.legs_3_applied then
            --debug(flag20, "    legs_3 single actions already applied. no further action.")
        else
            p_data.legs_recovery_status = 0
            player_meta:set_int("legs_recovery_status", 0)
            p_data.speed_buff_legs = 0.50
            p_data.jump_buff_legs = 0.50
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_health_mod_legs = BASE_MOD_HEALTH.legs_3
            p_data.base_comfort_mod_legs = BASE_MOD_COMFORT.legs_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.legs_1_applied = false
            p_data.legs_2_applied = false
            p_data.legs_3_applied = true
            p_data.legs_4_applied = false
            p_data.legs_5_applied = false
            p_data.legs_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_legs_3", "comfort", DRAIN_VAL_3, "curr", "add", true)

    elseif status_effects.legs_4 then
        --debug(flag20, "  applying stat effect for legs_4")

        if p_data.legs_4_applied then
            --debug(flag20, "    legs_4 single actions already applied. no further action.")
        else
            p_data.legs_recovery_status = 4
            player_meta:set_int("legs_recovery_status", 4)
            p_data.speed_buff_legs = 0.96
            p_data.jump_buff_legs = 0.96
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_health_mod_legs = BASE_MOD_HEALTH.legs_4
            p_data.base_comfort_mod_legs = BASE_MOD_COMFORT.legs_4
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.legs_1_applied = false
            p_data.legs_2_applied = false
            p_data.legs_3_applied = false
            p_data.legs_4_applied = true
            p_data.legs_5_applied = false
            p_data.legs_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_legs_4", "comfort", DRAIN_VAL_0, "curr", "add", true)
        --debug(flag20, "    increasing stats from using splint")
        do_stat_update_action(player, p_data, player_meta, "se_legs_4", "legs", 0.01, "curr", "add", true)

    elseif status_effects.legs_5 then
        --debug(flag20, "  applying stat effect for legs_5")

        if p_data.legs_5_applied then
            --debug(flag20, "    legs_5 single actions already applied. no further action.")
        else
            p_data.legs_recovery_status = 5
            player_meta:set_int("legs_recovery_status", 5)
            p_data.speed_buff_legs = 0.70
            p_data.jump_buff_legs = 0.70
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_health_mod_legs = BASE_MOD_HEALTH.legs_5
            p_data.base_comfort_mod_legs = BASE_MOD_COMFORT.legs_5
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.legs_1_applied = false
            p_data.legs_2_applied = false
            p_data.legs_3_applied = false
            p_data.legs_4_applied = false
            p_data.legs_5_applied = true
            p_data.legs_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_legs_5", "comfort", DRAIN_VAL_1, "curr", "add", true)
        --debug(flag20, "    increasing stats from using splint")
        do_stat_update_action(player, p_data, player_meta, "se_legs_5", "legs", 0.01, "curr", "add", true)

    elseif status_effects.legs_6 then
        --debug(flag20, "  applying stat effect for legs_6")

        if p_data.legs_6_applied then
            --debug(flag20, "    legs_6 single actions already applied. no further action.")
        else
            p_data.legs_recovery_status = 6
            player_meta:set_int("legs_recovery_status", 6)
            p_data.speed_buff_legs = 0.80
            p_data.jump_buff_legs = 0.80
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_health_mod_legs = BASE_MOD_HEALTH.legs_6
            p_data.base_comfort_mod_legs = BASE_MOD_COMFORT.legs_6
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.legs_1_applied = false
            p_data.legs_2_applied = false
            p_data.legs_3_applied = false
            p_data.legs_4_applied = false
            p_data.legs_5_applied = false
            p_data.legs_6_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_legs_6", "comfort", DRAIN_VAL_0, "curr", "add", true)
        --debug(flag20, "    increasing stats from using splint")
        do_stat_update_action(player, p_data, player_meta, "se_legs_6", "legs", 0.02, "curr", "add", true)

    else
        --debug(flag20, "  no active 'legs' stat effects")
        if p_data.legs_1_applied or p_data.legs_2_applied or p_data.legs_3_applied then
            --debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.legs_recovery_status = 0
            player_meta:set_int("legs_recovery_status", 0)
            p_data.speed_buff_legs = 1
            p_data.jump_buff_legs = 1
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_health_mod_legs = 1
            p_data.base_comfort_mod_legs = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.legs_1_applied = false
            p_data.legs_2_applied = false
            p_data.legs_3_applied = false
            p_data.legs_4_applied = false
            p_data.legs_5_applied = false
            p_data.legs_6_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    -----------
    -- HANDS --
    -----------
    -- 100% to 61%  (normal range)
    -- 60% to 41%   'hands_1' "sore" comfort-, health_base-, comfort_base-
    -- 40% to 21%   'hands_2' "sprained" comfort--, health_base--, comfort_base--
    -- 20% to 0%    'hands_3' "broken" comfort---, health_base---, comfort_base---
    -- 40% to 31%    'hands_4' "splinted sprain" comfort-, health_base--, comfort_base--, hands+
    -- 40% to 31%    'hands_5' "splinted break" comfort-, health_base--, comfort_base--, hands+
    -- 30% to 21%    'hands_6' "casted break" comfort-, health_base-, comfort_base--, hands+
    if status_effects.hands_1 then
        --debug(flag20, "  applying stat effect for hands_1")

        if p_data.hands_1_applied then
            --debug(flag20, "    hands_1 single actions already applied. no further action.")
        else
            p_data.hands_recovery_status = 0
            player_meta:set_int("hands_recovery_status", 0)
            p_data.base_health_mod_hands = BASE_MOD_HEALTH.hands_1
            p_data.base_comfort_mod_hands = BASE_MOD_COMFORT.hands_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hands_1_applied = true
            p_data.hands_2_applied = false
            p_data.hands_3_applied = false
            p_data.hands_4_applied = false
            p_data.hands_5_applied = false
            p_data.hands_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hands_1", "comfort", DRAIN_VAL_0, "curr", "add", true)

    elseif status_effects.hands_2 then
        --debug(flag20, "  applying stat effect for hands_2")

        if p_data.hands_2_applied then
            --debug(flag20, "    hands_2 single actions already applied. no further action.")
        else
            p_data.hands_recovery_status = 0
            player_meta:set_int("hands_recovery_status", 0)
            p_data.base_health_mod_hands = BASE_MOD_HEALTH.hands_2
            p_data.base_comfort_mod_hands = BASE_MOD_COMFORT.hands_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hands_1_applied = false
            p_data.hands_2_applied = true
            p_data.hands_3_applied = false
            p_data.hands_4_applied = false
            p_data.hands_5_applied = false
            p_data.hands_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hands_2", "comfort", DRAIN_VAL_2, "curr", "add", true)

    elseif status_effects.hands_3 then
        --debug(flag20, "  applying stat effect for hands_3")

        if p_data.hands_3_applied then
            --debug(flag20, "    hands_3 single actions already applied. no further action.")
        else
            p_data.hands_recovery_status = 0
            player_meta:set_int("hands_recovery_status", 0)
            p_data.base_health_mod_hands = BASE_MOD_HEALTH.hands_3
            p_data.base_comfort_mod_hands = BASE_MOD_COMFORT.hands_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hands_1_applied = false
            p_data.hands_2_applied = false
            p_data.hands_3_applied = true
            p_data.hands_4_applied = false
            p_data.hands_5_applied = false
            p_data.hands_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hands_3", "comfort", DRAIN_VAL_3, "curr", "add", true)

    elseif status_effects.hands_4 then
        --debug(flag20, "  applying stat effect for hands_4")

        if p_data.hands_4_applied then
            --debug(flag20, "    hands_4 single actions already applied. no further action.")
        else
            p_data.hands_recovery_status = 4
            player_meta:set_int("hands_recovery_status", 4)
            p_data.base_health_mod_hands = BASE_MOD_HEALTH.hands_4
            p_data.base_comfort_mod_hands = BASE_MOD_COMFORT.hands_4
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hands_1_applied = false
            p_data.hands_2_applied = false
            p_data.hands_3_applied = false
            p_data.hands_4_applied = true
            p_data.hands_5_applied = false
            p_data.hands_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hands_4", "comfort", DRAIN_VAL_0, "curr", "add", true)
        --debug(flag20, "    increasing stats from using splint")
        do_stat_update_action(player, p_data, player_meta, "se_hands_4", "hands", 0.01, "curr", "add", true)

    elseif status_effects.hands_5 then
        --debug(flag20, "  applying stat effect for hands_5")

        if p_data.hands_5_applied then
            --debug(flag20, "    hands_5 single actions already applied. no further action.")
        else
            p_data.hands_recovery_status = 5
            player_meta:set_int("hands_recovery_status", 5)
            p_data.base_health_mod_hands = BASE_MOD_HEALTH.hands_5
            p_data.base_comfort_mod_hands = BASE_MOD_COMFORT.hands_5
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hands_1_applied = false
            p_data.hands_2_applied = false
            p_data.hands_3_applied = false
            p_data.hands_4_applied = false
            p_data.hands_5_applied = true
            p_data.hands_6_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hands_5", "comfort", DRAIN_VAL_1, "curr", "add", true)
        --debug(flag20, "    increasing stats from using splint")
        do_stat_update_action(player, p_data, player_meta, "se_hands_5", "hands", 0.01, "curr", "add", true)

    elseif status_effects.hands_6 then
        --debug(flag20, "  applying stat effect for hands_6")

        if p_data.hands_6_applied then
            --debug(flag20, "    hands_6 single actions already applied. no further action.")
        else
            p_data.hands_recovery_status = 6
            player_meta:set_int("hands_recovery_status", 6)
            p_data.base_health_mod_hands = BASE_MOD_HEALTH.hands_6
            p_data.base_comfort_mod_hands = BASE_MOD_COMFORT.hands_6
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hands_1_applied = false
            p_data.hands_2_applied = false
            p_data.hands_3_applied = false
            p_data.hands_4_applied = false
            p_data.hands_5_applied = false
            p_data.hands_6_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hands_6", "comfort", DRAIN_VAL_0, "curr", "add", true)
        --debug(flag20, "    increasing stats from using splint")
        do_stat_update_action(player, p_data, player_meta, "se_hands_6", "hands", 0.02, "curr", "add", true)

    else
        --debug(flag20, "  no active 'hands' stat effects")
        if p_data.hands_1_applied or p_data.hands_2_applied or p_data.hands_3_applied then
            --debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.hands_recovery_status = 0
            player_meta:set_int("hands_recovery_status", 0)
            p_data.base_health_mod_hands = 1
            p_data.base_comfort_mod_hands = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hands_1_applied = false
            p_data.hands_2_applied = false
            p_data.hands_3_applied = false
            p_data.hands_4_applied = false
            p_data.hands_5_applied = false
            p_data.hands_6_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    ------------
    -- BREATH --
    ------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'breath_1'  comfort-, sanity-, comfort_base-, sanity_base-
    -- 30% to 11%  'breath_2'  comfort--, sanity--, comfort_base--, sanity_base--
    -- 10% to 0%   'breath_3'  comfort---, sanity---, health----, comfort_base---, sanity_base---

    if status_effects.breath_1 then
        --debug(flag20, "  applying stat effect for breath_1")
        if p_data.breath_1_applied then
            --debug(flag20, "    breath_1 single actions already applied. no further action.")
        else
            p_data.base_comfort_mod_breath = BASE_MOD_COMFORT.breath_1
            p_data.base_sanity_mod_breath = BASE_MOD_SANITY.breath_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "sanity"})
            p_data.breath_1_applied = true
            p_data.breath_2_applied = false
            p_data.breath_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_breath_1", "comfort", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_breath_1", "sanity", DRAIN_VAL_1, "curr", "add", true)
        recover_health(player, p_data, player_meta, "breath", "breath_3", p_data.health_rec_from_breath)

    elseif status_effects.breath_2 then
        --debug(flag20, "  applying stat effect for breath_2")
        if p_data.breath_2_applied then
            --debug(flag20, "    breath_2 single actions already applied. no further action.")
        else
            p_data.base_comfort_mod_breath = BASE_MOD_COMFORT.breath_2
            p_data.base_sanity_mod_breath = BASE_MOD_SANITY.breath_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "sanity"})
            p_data.breath_1_applied = false
            p_data.breath_2_applied = true
            p_data.breath_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_breath_2", "comfort", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_breath_2", "sanity", DRAIN_VAL_2, "curr", "add", true)
        recover_health(player, p_data, player_meta, "breath", "breath_3", p_data.health_rec_from_breath)

    elseif status_effects.breath_3 then
        --debug(flag20, "  applying stat effect for breath_3")
        if p_data.breath_3_applied then
            --debug(flag20, "    breath_3 single actions already applied. no further action.")
        else
            p_data.base_comfort_mod_breath = BASE_MOD_COMFORT.breath_3
            p_data.base_sanity_mod_breath = BASE_MOD_SANITY.breath_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "sanity"})
            p_data.breath_1_applied = false
            p_data.breath_2_applied = false
            p_data.breath_3_applied = true
        end
        do_stat_update_action(player, p_data, player_meta, "se_breath_3", "comfort", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_breath_3", "sanity", DRAIN_VAL_3, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.breath_3 * p_data.health_drain_mod_smotherproof
        do_stat_update_action(player, p_data, player_meta, "se_breath_3", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_breath = p_data.health_rec_from_breath + (-drain_amount * HEALTH_RECOVER_FACTOR.breath)
        player_meta:set_float("health_rec_from_breath", p_data.health_rec_from_breath)

    else
        --debug(flag20, "  no active 'breath' stat effects")
        if p_data.breath_1_applied or p_data.breath_2_applied or p_data.breath_3_applied then
            p_data.base_comfort_mod_breath = 1
            p_data.base_sanity_mod_breath = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "sanity"})
            p_data.breath_1_applied = false
            p_data.breath_2_applied = false
            p_data.breath_3_applied = false
        else
            --debug(flag20, "    and was not previously active")
            recover_health(player, p_data, player_meta, "breath", "breath_3", p_data.health_rec_from_breath)
        end
    end


    -------------
    -- STAMINA --
    -------------
    -- 100% to 51% (normal range)
    -- 50% to 31%  'stamina_1' thirst-, hunger-, alertness-, hygiene-, comfort-, speed-, jump-, comfort_base-
    -- 30% to 11%  'stamina_2' thirst--, hunger--, alertness--, hygiene--, comfort--, speed--, jump--, comfort_base--
    -- 10% to 0%   'stamina_3' thirst---, hunger---, alertness---, hygiene---, comfort---, speed---, jump---, comfort_base---

    if status_effects.stamina_1 then
        --debug(flag20, "  applying stat effect for stamina_1")
        if p_data.stamina_1_applied then
            --debug(flag20, "    stamina_1 single actions already applied. no further action.")
        else
            --debug(flag20, "    add screen overlay and lower color saturation to 25%")
            update_visuals(player, player_name, player_meta, "stamina_1")
            p_data.speed_buff_exhaustion = 0.9
            p_data.jump_buff_exhaustion = 0.9
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_comfort_mod_stamina = BASE_MOD_COMFORT.stamina_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.stamina_0_applied = false
            p_data.stamina_1_applied = true
            p_data.stamina_2_applied = false
            p_data.stamina_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_stamina_1", "thirst", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_1", "hunger", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_1", "alertness", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_1", "hygiene", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_1", "comfort", DRAIN_VAL_1, "curr", "add", true)

    elseif status_effects.stamina_2 then
        --debug(flag20, "  applying stat effect for stamina_2")
        if p_data.stamina_2_applied then
            --debug(flag20, "    stamina_2 single actions already applied. no further action.")
        else
            --debug(flag20, "    add screen overlay and lower color saturation to 10%")
            update_visuals(player, player_name, player_meta, "stamina_2")
            p_data.speed_buff_exhaustion = 0.6
            p_data.jump_buff_exhaustion = 0.6
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_comfort_mod_stamina = BASE_MOD_COMFORT.stamina_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.stamina_0_applied = false
            p_data.stamina_1_applied = false
            p_data.stamina_2_applied = true
            p_data.stamina_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_stamina_2", "thirst", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_2", "hunger", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_2", "alertness", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_2", "hygiene", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_2", "comfort", DRAIN_VAL_2, "curr", "add", true)

    elseif status_effects.stamina_3 then
        --debug(flag20, "  applying stat effect for stamina_3")
        if p_data.stamina_3_applied then
            --debug(flag20, "    stamina_3 single actions already applied. no further action.")
        else
            --debug(flag20, "    add screen overlay and lower color saturation to 0%")
            update_visuals(player, player_name, player_meta, "stamina_3")
            p_data.speed_buff_exhaustion = 0.5
            p_data.jump_buff_exhaustion = 0.5
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_comfort_mod_stamina = BASE_MOD_COMFORT.stamina_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.stamina_0_applied = false
            p_data.stamina_1_applied = false
            p_data.stamina_2_applied = false
            p_data.stamina_3_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_stamina_3", "thirst", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_3", "hunger", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_3", "alertness", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_3", "hygiene", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_stamina_3", "comfort", DRAIN_VAL_3, "curr", "add", true)

    else
        --debug(flag20, "  no active stamina stat effects")
        if p_data.stamina_0_applied or p_data.stamina_1_applied or p_data.stamina_2_applied
            or p_data.stamina_3_applied then
            update_visuals(player, player_name, player_meta, "stamina_0")
            p_data.speed_buff_exhaustion = 1
            p_data.jump_buff_exhaustion = 1
            update_player_physics(player, {speed = true, jump = true})
            p_data.base_comfort_mod_stamina = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.stamina_0_applied = false
            p_data.stamina_1_applied = false
            p_data.stamina_2_applied = false
            p_data.stamina_3_applied = false
        else
            --debug(flag20, "    and was not previously active. no further action.")
        end
    end


    ------------
    -- WEIGHT --
    ------------
    -- 0% to 29%   (normal range)
    -- 30% to 44%  'weight_1' speed-, jump-, comfort-, comfort_base-
    -- 45% to 59%  'weight_2' speed-, jump-, comfort-, comfort_base-
    -- 60% to 74%  'weight_3' stamina drain+, comfort-, legs-, speed-, jump-, comfort_base-
    -- 75% to 89%  'weight_4' stamina drain++, comfort--, legs--, speed--, jump--, comfort_base--
    -- 90% to 100% 'weight_5' stamina drain+++, comfort---, legs---, speed---, jump---, , comfort_base---

    if status_effects.weight_1 then
        --debug(flag20, "  applying effect for weight_1")

        if p_data.weight_1_applied then
            --debug(flag20, "    weight_1 single actions already applied. no further action.")
        else
            p_data.speed_buff_weight = 0.90
            p_data.jump_buff_weight = 0.90
            update_player_physics(player, {speed = true, jump = true})
            p_data.stamina_drain_mod_weight = 1.1
            player_meta:set_float("stamina_drain_mod_weight", 1.1)
            p_data.base_comfort_mod_weight = BASE_MOD_COMFORT.weight_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.weight_1_applied = true
            p_data.weight_2_applied = false
            p_data.weight_3_applied = false
            p_data.weight_4_applied = false
            p_data.weight_5_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_weight_1", "comfort", DRAIN_VAL_0, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_weight_1", "legs", DRAIN_VAL_0, "curr", "add", true)

    elseif status_effects.weight_2 then
        --debug(flag20, "  applying effect for weight_2")

        if p_data.weight_2_applied then
            --debug(flag20, "    weight_2 single actions already applied. no further action.")
        else
            p_data.speed_buff_weight = 0.80
            p_data.jump_buff_weight = 0.80
            update_player_physics(player, {speed = true, jump = true})
            p_data.stamina_drain_mod_weight = 1.2
            player_meta:set_float("stamina_drain_mod_weight", 1.2)
            p_data.base_comfort_mod_weight = BASE_MOD_COMFORT.weight_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.weight_1_applied = false
            p_data.weight_2_applied = true
            p_data.weight_3_applied = false
            p_data.weight_4_applied = false
            p_data.weight_5_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_weight_2", "comfort", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_weight_2", "legs", DRAIN_VAL_1, "curr", "add", true)

    elseif status_effects.weight_3 then
        --debug(flag20, "  applying effect for weight_3")

        if p_data.weight_3_applied then
            --debug(flag20, "    weight_3 single actions already applied. no further action.")
        else
            p_data.speed_buff_weight = 0.70
            p_data.jump_buff_weight = 0.70
            update_player_physics(player, {speed = true, jump = true})
            p_data.stamina_drain_mod_weight = 1.3
            player_meta:set_float("stamina_drain_mod_weight", 1.3)
            p_data.base_comfort_mod_weight = BASE_MOD_COMFORT.weight_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.weight_1_applied = false
            p_data.weight_2_applied = false
            p_data.weight_3_applied = true
            p_data.weight_4_applied = false
            p_data.weight_5_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_weight_3", "comfort", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_weight_3", "legs", DRAIN_VAL_3, "curr", "add", true)

    elseif status_effects.weight_4 then
        --debug(flag20, "  applying effect for weight_4")

        if p_data.weight_4_applied then
            --debug(flag20, "    weight_4 single actions already applied. no further action.")
        else
            p_data.speed_buff_weight = 0.60
            p_data.jump_buff_weight = 0.60
            update_player_physics(player, {speed = true, jump = true})
            p_data.stamina_drain_mod_weight = 1.4
            player_meta:set_float("stamina_drain_mod_weight", 1.4)
            p_data.base_comfort_mod_weight = BASE_MOD_COMFORT.weight_4
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.weight_1_applied = false
            p_data.weight_2_applied = false
            p_data.weight_3_applied = false
            p_data.weight_4_applied = true
            p_data.weight_5_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_weight_4", "comfort", DRAIN_VAL_4, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_weight_4", "legs", DRAIN_VAL_4, "curr", "add", true)

    elseif status_effects.weight_5 then
        --debug(flag20, "  applying effect for weight_5")

        if p_data.weight_5_applied then
            --debug(flag20, "    weight_5 single actions already applied. no further action.")
        else
            p_data.speed_buff_weight = 0.50
            p_data.jump_buff_weight = 0.50
            update_player_physics(player, {speed = true, jump = true})
            p_data.stamina_drain_mod_weight = 1.5
            player_meta:set_float("stamina_drain_mod_weight", 1.5)
            p_data.base_comfort_mod_weight = BASE_MOD_COMFORT.weight_5
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.weight_1_applied = false
            p_data.weight_2_applied = false
            p_data.weight_3_applied = false
            p_data.weight_4_applied = false
            p_data.weight_5_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_weight_5", "comfort", DRAIN_VAL_5, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_weight_5", "legs", DRAIN_VAL_5, "curr", "add", true)

    else
        --debug(flag20, "  no active 'weight' stat effects")
        if p_data.weight_1_applied or p_data.weight_2_applied or p_data.weight_3_applied
            or p_data.weight_4_applied or p_data.weight_5_applied then
            --debug(flag20, "    but was active previously. clearing remaining stat effect consequences..")
            p_data.speed_buff_weight = 1
            p_data.jump_buff_weight = 1
            update_player_physics(player, {speed = true, jump = true})
            p_data.stamina_drain_mod_weight = 1
            player_meta:set_float("stamina_drain_mod_weight", 1)
            p_data.base_comfort_mod_weight = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.weight_1_applied = false
            p_data.weight_2_applied = false
            p_data.weight_3_applied = false
            p_data.weight_4_applied = false
            p_data.weight_5_applied = false
        end
    end


    ---------
    -- HOT --
    ---------
    -- 81 °F to 95 °F    'hot_1' "warm" thirst-, hygiene-, comfort-, comfort_base-
    -- 96 °F to 105 °F   'hot_2' "hot" thirst--, hygiene--, comfort--, stamina_rec-, health_base-, comfort_base--
    -- 106 °F to 120 °F  'hot_3' "sweltering" thirst---, hygiene---, comfort---, stamina_rec--, health---, health_base--, comfort_base---
    -- 121 °F or above   'hot_4' "scorching" thirst---, hygiene---, comfort----, stamina_rec---, health----, health_base--, comfort_base----

    if status_effects.hot_1 then
        --debug(flag20, "  applying effect for hot_1")

        if p_data.hot_1_applied then
            --debug(flag20, "    hot_1 single actions already applied. no further action.")
        else
            p_data.stamina_rec_mod_hot = 1
            player_meta:set_float("stamina_rec_mod_hot", 1)
            update_visuals(player, player_name, player_meta, "hot_1")
            p_data.base_comfort_mod_hot = BASE_MOD_COMFORT.hot_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort"})
            p_data.hot_1_applied = true
            p_data.hot_2_applied = false
            p_data.hot_3_applied = false
            p_data.hot_4_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hot_1", "thirst", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hot_1", "hygiene", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hot_1", "comfort", DRAIN_VAL_1, "curr", "add", true)
        recover_health(player, p_data, player_meta, "hot", "hot_3", p_data.health_rec_from_hot)

    elseif status_effects.hot_2 then
        --debug(flag20, "  applying effect for hot_2")

        if p_data.hot_2_applied then
            --debug(flag20, "    hot_2 single actions already applied. no further action.")
        else
            -- apply one-time stats mods or screen effects here
            p_data.stamina_rec_mod_hot = 0.9
            player_meta:set_float("stamina_rec_mod_hot", 0.9)
            update_visuals(player, player_name, player_meta, "hot_2")
            p_data.base_health_mod_hot = BASE_MOD_HEALTH.hot_2
            p_data.base_comfort_mod_hot = BASE_MOD_COMFORT.hot_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hot_1_applied = false
            p_data.hot_2_applied = true
            p_data.hot_3_applied = false
            p_data.hot_4_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hot_2", "thirst", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hot_2", "hygiene", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hot_2", "comfort", DRAIN_VAL_2, "curr", "add", true)
        recover_health(player, p_data, player_meta, "hot", "hot_3", p_data.health_rec_from_hot)

    elseif status_effects.hot_3 then
        --debug(flag20, "  applying effect for hot_3")

        if p_data.hot_3_applied then
            --debug(flag20, "    hot_3 single actions already applied. no further action.")
        else
            -- apply one-time stats mods or screen effects here
            p_data.stamina_rec_mod_hot = 0.7
            player_meta:set_float("stamina_rec_mod_hot", 0.7)
            update_visuals(player, player_name, player_meta, "hot_3")
            p_data.base_health_mod_hot = BASE_MOD_HEALTH.hot_3
            p_data.base_comfort_mod_hot = BASE_MOD_COMFORT.hot_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hot_1_applied = false
            p_data.hot_2_applied = false
            p_data.hot_3_applied = true
            p_data.hot_4_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hot_3", "thirst", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hot_3", "hygiene", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hot_3", "comfort", DRAIN_VAL_3, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.hot_3 * p_data.health_drain_mod_scorchproof
        do_stat_update_action(player, p_data, player_meta, "se_hot_3", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_hot = p_data.health_rec_from_hot + (-drain_amount * HEALTH_RECOVER_FACTOR.hot)
        player_meta:set_float("health_rec_from_hot", p_data.health_rec_from_hot)

    elseif status_effects.hot_4 then
        --debug(flag20, "  applying effect for hot_4")

        if p_data.hot_4_applied then
            --debug(flag20, "    hot_4 single actions already applied. no further action.")
        else
            -- apply one-time stats mods or screen effects here
            p_data.stamina_rec_mod_hot = 0.5
            player_meta:set_float("stamina_rec_mod_hot", 0.5)
            update_visuals(player, player_name, player_meta, "hot_4")
            p_data.base_health_mod_hot = BASE_MOD_HEALTH.hot_4
            p_data.base_comfort_mod_hot = BASE_MOD_COMFORT.hot_4
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hot_1_applied = false
            p_data.hot_2_applied = false
            p_data.hot_3_applied = false
            p_data.hot_4_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_hot_4", "thirst", DRAIN_VAL_4, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hot_4", "hygiene", DRAIN_VAL_4, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_hot_4", "comfort", DRAIN_VAL_4, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.hot_4 * p_data.health_drain_mod_scorchproof
        do_stat_update_action(player, p_data, player_meta, "se_hot_4", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_hot = p_data.health_rec_from_hot + (-drain_amount * HEALTH_RECOVER_FACTOR.hot)
        player_meta:set_float("health_rec_from_hot", p_data.health_rec_from_hot)

    else
        --debug(flag20, "  no active 'hot' stat effects")
        if p_data.hot_1_applied or p_data.hot_2_applied
            or p_data.hot_3_applied or p_data.hot_4_applied then
            p_data.stamina_rec_mod_hot = 1
            player_meta:set_float("stamina_rec_mod_hot", 1)
            update_visuals(player, player_name, player_meta, "hot_0")
            p_data.base_health_mod_hot = 1
            p_data.base_comfort_mod_hot = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.hot_1_applied = false
            p_data.hot_2_applied = false
            p_data.hot_3_applied = false
            p_data.hot_4_applied = false
        else
            --debug(flag20, "    and was not previously active")
            recover_health(player, p_data, player_meta, "hot", "hot_4", p_data.health_rec_from_hot)
        end
    end


    ----------
    -- COLD --
    ----------
    -- 60 °F to 46 °F   'cold_1' "cool" comfort-, comfort_base-, immunity_base-
    -- 45 °F to 31 °F   'cold_2' "cold" comfort--, immunity-, stamina_rec-, illness+, comfort_base--, immunity_base--, health_base-
    -- 30 °F to 11 °F   'cold_3' "frigid" comfort---, immunity--, stamina_rec---, illness++, health--, comfort_base--, immunity_base--, health_base--
    -- 10 °F or below   'cold_4' "freezing" comfort----, immunity---, stamina_rec----, illness+++, health---, comfort_base--, immunity_base--, health_base---

    if status_effects.cold_1 then
        --debug(flag20, "  applying effect for cold_1")

        if p_data.cold_1_applied then
            --debug(flag20, "    cold_1 single actions already applied. no further action.")
        else
            p_data.stamina_rec_mod_cold = 1
            player_meta:set_float("stamina_rec_mod_cold", 1)
            update_visuals(player, player_name, player_meta, "cold_1")
            p_data.base_comfort_mod_cold = BASE_MOD_COMFORT.cold_1
            p_data.base_immunity_mod_cold = BASE_MOD_IMMUNITY.cold_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"comfort", "immunity"})
            p_data.cold_1_applied = true
            p_data.cold_2_applied = false
            p_data.cold_3_applied = false
            p_data.cold_4_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_cold_1", "comfort", DRAIN_VAL_1, "curr", "add", true)
        recover_health(player, p_data, player_meta, "cold", "cold_3", p_data.health_rec_from_cold)

        -- increase alertness when feeling cool underwater
        if p_data.water_level > 0 then
            local amount = (p_data.water_level / 100) * 1
            print("### increasing alertness by: " .. amount)
            do_stat_update_action(player, p_data, player_meta, "se_cold_1", "alertness", amount, "curr", "add", true)
        end

    elseif status_effects.cold_2 then
        --debug(flag20, "  applying effect for cold_2")

        if p_data.cold_2_applied then
            --debug(flag20, "    cold_2 single actions already applied. no further action.")
        else
            p_data.stamina_rec_mod_cold = 0.9
            player_meta:set_float("stamina_rec_mod_cold", 0.9)
            update_visuals(player, player_name, player_meta, "cold_2")
            p_data.base_health_mod_cold = BASE_MOD_HEALTH.cold_2
            p_data.base_comfort_mod_cold = BASE_MOD_COMFORT.cold_2
            p_data.base_immunity_mod_cold = BASE_MOD_IMMUNITY.cold_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.cold_1_applied = false
            p_data.cold_2_applied = true
            p_data.cold_3_applied = false
            p_data.cold_4_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_cold_2", "comfort", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_cold_2", "immunity", DRAIN_VAL_2, "curr", "add", true)
        recover_health(player, p_data, player_meta, "cold", "cold_3", p_data.health_rec_from_cold)

        --debug(flag20, "    increasing illness")
        do_stat_update_action(player, p_data, player_meta, "se_cold_2", "illness", 0.01, "curr", "add", true)

        -- increase alertness when feeling cold underwater
        if p_data.water_level > 0 then
            local amount = (p_data.water_level / 100) * 2
            print("### increasing alertness by: " .. amount)
            do_stat_update_action(player, p_data, player_meta, "se_cold_2", "alertness", amount, "curr", "add", true)
        end

    elseif status_effects.cold_3 then
        --debug(flag20, "  applying effect for cold_3")

        if p_data.cold_3_applied then
            --debug(flag20, "    cold_3 single actions already applied. no further action.")
        else
            p_data.stamina_rec_mod_cold = 0.7
            player_meta:set_float("stamina_rec_mod_cold", 0.7)
            update_visuals(player, player_name, player_meta, "cold_3")
            p_data.base_health_mod_cold = BASE_MOD_HEALTH.cold_3
            p_data.base_comfort_mod_cold = BASE_MOD_COMFORT.cold_3
            p_data.base_immunity_mod_cold = BASE_MOD_IMMUNITY.cold_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.cold_1_applied = false
            p_data.cold_2_applied = false
            p_data.cold_3_applied = true
            p_data.cold_4_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_cold_3", "comfort", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_cold_3", "immunity", DRAIN_VAL_3, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.cold_3 * p_data.health_drain_mod_freezeproof
        do_stat_update_action(player, p_data, player_meta, "se_cold_3", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_cold = p_data.health_rec_from_cold + (-drain_amount * HEALTH_RECOVER_FACTOR.cold)
        player_meta:set_float("health_rec_from_cold", p_data.health_rec_from_cold)

        --debug(flag20, "    increasing illness")
        do_stat_update_action(player, p_data, player_meta, "se_cold_3", "illness", 0.02, "curr", "add", true)

    elseif status_effects.cold_4 then
        --debug(flag20, "  applying effect for cold_4")

        if p_data.cold_4_applied then
            --debug(flag20, "    cold_4 single actions already applied. no further action.")
        else
            p_data.stamina_rec_mod_cold = 0.5
            player_meta:set_float("stamina_rec_mod_cold", 0.5)
            update_visuals(player, player_name, player_meta, "cold_4")
            p_data.base_health_mod_cold = BASE_MOD_HEALTH.cold_4
            p_data.base_comfort_mod_cold = BASE_MOD_COMFORT.cold_4
            p_data.base_immunity_mod_cold = BASE_MOD_IMMUNITY.cold_4
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.cold_1_applied = false
            p_data.cold_2_applied = false
            p_data.cold_3_applied = false
            p_data.cold_4_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_cold_4", "comfort", DRAIN_VAL_4, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_cold_4", "immunity", DRAIN_VAL_4, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.cold_4 * p_data.health_drain_mod_freezeproof
        do_stat_update_action(player, p_data, player_meta, "se_cold_4", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_cold = p_data.health_rec_from_cold + (-drain_amount * HEALTH_RECOVER_FACTOR.cold)
        player_meta:set_float("health_rec_from_cold", p_data.health_rec_from_cold)

        --debug(flag20, "    increasing illness")
        do_stat_update_action(player, p_data, player_meta, "se_cold_4", "illness", 0.04, "curr", "add", true)

    else
        --debug(flag20, "  no active 'cold' stat effects")
        if p_data.cold_1_applied or p_data.cold_2_applied
            or p_data.cold_3_applied or p_data.cold_4_applied then
            p_data.stamina_rec_mod_cold = 1
            player_meta:set_float("stamina_rec_mod_cold", 1)
            update_visuals(player, player_name, player_meta, "cold_0")
            p_data.base_health_mod_cold = 1
            p_data.base_comfort_mod_cold = 1
            p_data.base_immunity_mod_cold = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort", "immunity"})
            p_data.cold_1_applied = false
            p_data.cold_2_applied = false
            p_data.cold_3_applied = false
            p_data.cold_4_applied = false
        else
            --debug(flag20, "    and was not previously active")
            recover_health(player, p_data, player_meta, "cold", "cold_4", p_data.health_rec_from_cold)
        end
    end


    -------------
    -- ILLNESS --
    -------------
    -- 0% to 39%   (normal range)
    -- 40% to 59%  'illness_1' "cold" alertness-, comfort-, stamina drain+, stamina_rec-, speed-, jump-, health_base-, comfort_base-
    -- 60% to 76%  'illness_2' "flu" alertness--, comfort--, stamina drain++, stamina_rec--, speed--, jump--, health_base--, comfort_base--
    -- 80% to 100% 'illness_3' "pneumonia" alertness---, comfort---, health---, stamina drain+++, stamina_rec---, speed---, jump---, health_base---, comfort_base---

    if status_effects.illness_1 then

        if p_data.illness_1_applied then
            --debug(flag20, "  illness_1 startup consequences already applied")
            sneeze_checker(player, player_meta, player_name, p_data)
        else
            --debug(flag20, "  applying startup consequences for illness_1")
            p_data.stamina_drain_mod_illness = 1.1
            player_meta:set_float("stamina_drain_mod_illness", 1.1)
            p_data.stamina_rec_mod_illness = 0.9
            player_meta:set_float("stamina_rec_mod_illness", 0.9)
            p_data.speed_buff_illness = 0.9
            p_data.jump_buff_illness = 0.9
            update_player_physics(player, {speed = true, jump = true})
            update_visuals(player, player_name, player_meta, "illness_1")
            p_data.base_health_mod_illness = BASE_MOD_HEALTH.illness_1
            p_data.base_comfort_mod_illness = BASE_MOD_COMFORT.illness_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.illness_1_applied = true
            p_data.illness_2_applied = false
            p_data.illness_3_applied = false
        end
        do_stat_update_action(player, p_data, player_meta, "se_illness_1", "alertness", DRAIN_VAL_1, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_illness_1", "comfort", DRAIN_VAL_1, "curr", "add", true)
        recover_health(player, p_data, player_meta, "illness", "illness_3", p_data.health_rec_from_illness)

    elseif status_effects.illness_2 then
        --debug(flag20, "  applying effect for illness_2")

        if p_data.illness_2_applied then
            --debug(flag20, "    illness_2 single actions already applied. no further action.")
            cough_checker(player, player_meta, p_data)
        else
            p_data.stamina_drain_mod_illness = 1.3
            player_meta:set_float("stamina_drain_mod_illness", 1.3)
            p_data.stamina_rec_mod_illness = 0.8
            player_meta:set_float("stamina_rec_mod_illness", 0.8)
            p_data.speed_buff_illness = 0.8
            p_data.jump_buff_illness = 0.8
            update_player_physics(player, {speed = true, jump = true})
            update_visuals(player, player_name, player_meta, "illness_2")
            p_data.base_health_mod_illness = BASE_MOD_HEALTH.illness_2
            p_data.base_comfort_mod_illness = BASE_MOD_COMFORT.illness_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.illness_1_applied = false
            p_data.illness_2_applied = true
            p_data.illness_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_illness_2", "alertness", DRAIN_VAL_2, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_illness_2", "comfort", DRAIN_VAL_2, "curr", "add", true)
        recover_health(player, p_data, player_meta, "illness", "illness_3", p_data.health_rec_from_illness)

    elseif status_effects.illness_3 then
        --debug(flag20, "  applying effect for illness_3")

        if p_data.illness_3_applied then
            --debug(flag20, "    illness_3 single actions already applied. no further action.")
            cough_checker(player, player_meta, p_data)
        else
            p_data.stamina_drain_mod_illness = 2.0
            player_meta:set_float("stamina_drain_mod_illness", 2.0)
            p_data.stamina_rec_mod_illness = 0.5
            player_meta:set_float("stamina_rec_mod_illness", 0.5)
            p_data.base_health_mod_illness = BASE_MOD_HEALTH.illness_3
            p_data.base_comfort_mod_illness = BASE_MOD_COMFORT.illness_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.speed_buff_illness = 0.6
            p_data.jump_buff_illness = 0.6
            update_player_physics(player, {speed = true, jump = true})
            update_visuals(player, player_name, player_meta, "illness_3")
            p_data.illness_1_applied = false
            p_data.illness_2_applied = false
            p_data.illness_3_applied = true
        end

        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_illness_3", "alertness", DRAIN_VAL_3, "curr", "add", true)
        do_stat_update_action(player, p_data, player_meta, "se_illness_3", "comfort", DRAIN_VAL_3, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.illness_3 * p_data.health_drain_mod_stage4_nope
        do_stat_update_action(player, p_data, player_meta, "se_illness_3", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_illness = p_data.health_rec_from_illness + (-drain_amount * HEALTH_RECOVER_FACTOR.illness)
        player_meta:set_float("health_rec_from_illness", p_data.health_rec_from_illness)

    else
        --debug(flag20, "  no active 'illness' stat effects")
        if p_data.illness_1_applied or p_data.illness_2_applied or p_data.illness_3_applied then
            p_data.sneeze_timer = 0
            player_meta:set_float("sneeze_timer", 0)
            p_data.cough_timer = 0
            player_meta:set_float("cough_timer", 0)
            p_data.stamina_drain_mod_illness = 1
            player_meta:set_float("stamina_drain_mod_illness", 1)
            p_data.stamina_rec_mod_illness = 1
            player_meta:set_float("stamina_rec_mod_illness", 1)
            p_data.speed_buff_illness = 1
            p_data.jump_buff_illness = 1
            update_player_physics(player, {speed = true, jump = true})
            update_visuals(player, player_name, player_meta, "illness_0")
            p_data.base_health_mod_illness = 1
            p_data.base_comfort_mod_illness = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.illness_1_applied = false
            p_data.illness_2_applied = false
            p_data.illness_3_applied = false
        else
            --debug(flag20, "    and was not previously active")
            recover_health(player, p_data, player_meta, "illness", "illness_3", p_data.health_rec_from_illness)
        end
    end


    -------------
    -- POISON --
    -------------
    -- 0% to 39%   (normal range)
    -- 40% to 59%  'poison_1' "stomach ache" comfort-, stamina_drain+, stamina_rec-, speed-, jump-, health_base-, comfort_base-
    -- 60% to 76%  'poison_2' "nausea"      comfort--, stamina_drain++, stamina_rec--, speed--, jump--, health_base--, comfort_base--, vomitting
    -- 80% to 100% 'poison_3' "dysentery"  comfort---, stamina_drain+++, stamina_rec---, speed---, jump---, health_base---, comfort_base---, vomitting, health-

    if status_effects.poison_1 then
        --debug(flag20, "  applying effect for poison_1")

        if p_data.poison_1_applied then
            --debug(flag20, "    poison_1 single actions already applied. no further action.")
        else
            p_data.stamina_drain_mod_poison = 1.05
            player_meta:set_float("stamina_drain_mod_poison", 1.05)
            p_data.stamina_rec_mod_poison = 0.95
            player_meta:set_float("stamina_rec_mod_poison", 0.95)
            p_data.speed_buff_poison = 0.95
            p_data.jump_buff_poison = 0.95
            update_player_physics(player, {speed = true, jump = true})
            update_visuals(player, player_name, player_meta, "poison_1")
            p_data.base_health_mod_poison = BASE_MOD_HEALTH.poison_1
            p_data.base_comfort_mod_poison = BASE_MOD_COMFORT.poison_1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.poison_1_applied = true
            p_data.poison_2_applied = false
            p_data.poison_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_poison_1", "comfort", DRAIN_VAL_1, "curr", "add", true)
        recover_health(player, p_data, player_meta, "poison", "poison_3", p_data.health_rec_from_poison)

    elseif status_effects.poison_2 then
        --debug(flag20, "  applying effect for poison_2")

        if p_data.poison_2_applied then
            --debug(flag20, "    poison_2 single actions already applied.")
            vomit_checker(player, player_meta, player_name, p_data, 2)
        else
            p_data.stamina_drain_mod_poison = 1.1
            player_meta:set_float("stamina_drain_mod_poison", 1.1)
            p_data.stamina_rec_mod_poison = 0.9
            player_meta:set_float("stamina_rec_mod_poison", 0.9)
            p_data.speed_buff_poison = 0.9
            p_data.jump_buff_poison = 0.9
            update_player_physics(player, {speed = true, jump = true})
            update_visuals(player, player_name, player_meta, "poison_2")
            p_data.base_health_mod_poison = BASE_MOD_HEALTH.poison_2
            p_data.base_comfort_mod_poison = BASE_MOD_COMFORT.poison_2
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.poison_1_applied = false
            p_data.poison_2_applied = true
            p_data.poison_3_applied = false
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_poison_2", "comfort", DRAIN_VAL_2, "curr", "add", true)
        recover_health(player, p_data, player_meta, "poison", "poison_3", p_data.health_rec_from_poison)

    elseif status_effects.poison_3 then
        --debug(flag20, "  applying effect for poison_3")

        if p_data.poison_3_applied then
            --debug(flag20, "    poison_3 single actions already applied. vomit_timer: " .. p_data.vomit_timer)
            vomit_checker(player, player_meta, player_name, p_data, 3)
        else
            p_data.stamina_drain_mod_poison = 1.5
            player_meta:set_float("stamina_drain_mod_poison", 1.5)
            p_data.stamina_rec_mod_poison = 0.7
            player_meta:set_float("stamina_rec_mod_poison", 0.7)
            p_data.speed_buff_poison = 0.7
            p_data.jump_buff_poison = 0.7
            update_player_physics(player, {speed = true, jump = true})
            update_visuals(player, player_name, player_meta, "poison_3")
            p_data.base_health_mod_poison = BASE_MOD_HEALTH.poison_3
            p_data.base_comfort_mod_poison = BASE_MOD_COMFORT.poison_3
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.poison_1_applied = false
            p_data.poison_2_applied = false
            p_data.poison_3_applied = true
        end
        --debug(flag20, "    decreasing stats")
        do_stat_update_action(player, p_data, player_meta, "se_poison_3", "comfort", DRAIN_VAL_3, "curr", "add", true)
        local drain_amount = HEALTH_DRAIN_VALUE.poison_3 * p_data.health_drain_mod_dinner_death_dodger
        do_stat_update_action(player, p_data, player_meta, "se_poison_3", "health", drain_amount, "curr", "add", true)
        p_data.health_rec_from_poison = p_data.health_rec_from_poison + (-drain_amount * HEALTH_RECOVER_FACTOR.poison)
        player_meta:set_float("health_rec_from_poison", p_data.health_rec_from_poison)

    else
        --debug(flag20, "  no active 'poison' stat effects")
        if p_data.poison_1_applied or p_data.poison_2_applied or p_data.poison_3_applied then
            p_data.vomit_timer = 0
            player_meta:set_float("vomit_timer", 0)
            p_data.stamina_drain_mod_poison = 1
            player_meta:set_float("stamina_drain_mod_poison", 1)
            p_data.stamina_rec_mod_poison = 1
            player_meta:set_float("stamina_rec_mod_poison", 1)
            p_data.speed_buff_poison = 1
            p_data.jump_buff_poison = 1
            p_data.speed_buff_vomit = 1
            p_data.jump_buff_vomit = 1
            update_player_physics(player, {speed = true, jump = true})
            update_visuals(player, player_name, player_meta, "poison_0")
            p_data.base_health_mod_poison = 1
            p_data.base_comfort_mod_poison = 1
            update_base_stat_value(player, player_meta, player_name, p_data, {"health", "comfort"})
            p_data.poison_1_applied = false
            p_data.poison_2_applied = false
            p_data.poison_3_applied = false
        else
            --debug(flag20, "    and was not previously active")
            recover_health(player, p_data, player_meta, "poison", "poison_3", p_data.health_rec_from_poison)
        end
    end


    -------------
    -- WETNESS --
    -------------
    -- 0%          (normal range)
    -- 1% to 19%   'wetness_1' "damp" screen_effect+
    -- 20% to 79%  'wetness_2' "wet" screen_effect++
    -- 80% to 100% 'wetness_3' "soaking wet" screen_effect++

    if status_effects.wetness_1 then
        if p_data.wetness_1_applied then
            --debug(flag20, "  wetness_1 startup consequences already applied")
        else
            --debug(flag20, "  applying startup consequences for wetness_1")
            update_visuals(player, player_name, player_meta, "wetness_1")
            p_data.wetness_1_applied = true
            p_data.wetness_2_applied = false
            p_data.wetness_3_applied = false
        end

    elseif status_effects.wetness_2 then
        --debug(flag20, "  applying effect for wetness_2")
        if p_data.wetness_2_applied then
            --debug(flag20, "    wetness_2 single actions already applied. no further action.")
        else
            update_visuals(player, player_name, player_meta, "wetness_2")
            p_data.wetness_1_applied = false
            p_data.wetness_2_applied = true
            p_data.wetness_3_applied = false
        end

    elseif status_effects.wetness_3 then
        --debug(flag20, "  applying effect for wetness_3")
        if p_data.wetness_3_applied then
            --debug(flag20, "    wetness_3 single actions already applied. no further action.")
        else
            update_visuals(player, player_name, player_meta, "wetness_3")
            p_data.wetness_1_applied = false
            p_data.wetness_2_applied = false
            p_data.wetness_3_applied = true
        end

    else
        --debug(flag20, "  no active 'wetness' stat effects")
        if p_data.wetness_1_applied or p_data.wetness_2_applied or p_data.wetness_3_applied then
            update_visuals(player, player_name, player_meta, "wetness_0")
            p_data.wetness_1_applied = false
            p_data.wetness_2_applied = false
            p_data.wetness_3_applied = false
        else
            --debug(flag20, "    and was not previously active")
        end
    end

    debug(flag20, "monitor_status_effects() end")
    local job_handle = mt_after(1, monitor_status_effects, player, player_meta, player_name, p_data, status_effects)
    job_handles[player_name].monitor_status_effects = job_handle
end


local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() STATUS EFFECTS")
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local p_data = player_data[player_name]
    local metadata

    p_data.stamina_drain_mod_thirst = 1
    p_data.stamina_drain_mod_hunger = 1
    p_data.stamina_drain_mod_alertness = 1
    p_data.stamina_drain_mod_weight = 1
    p_data.stamina_drain_mod_illness = 1
    p_data.stamina_drain_mod_poison = 1

    p_data.stamina_rec_mod_hot = 1
    p_data.stamina_rec_mod_cold = 1
    p_data.stamina_rec_mod_illness = 1
    p_data.stamina_rec_mod_poison = 1

    metadata = player_meta:get_float("leg_injury_mod_foot_clothing")
    p_data.leg_injury_mod_foot_clothing = (metadata ~= 0 and metadata) or 1

    metadata = player_meta:get_float("leg_injury_mod_foot_armor")
    p_data.leg_injury_mod_foot_armor = (metadata ~= 0 and metadata) or 1

    metadata = player_meta:get_float("leg_injury_mod_skill")
    p_data.leg_injury_mod_skill = (metadata ~= 0 and metadata) or 1

    metadata = player_meta:get_float("hand_injury_mod_glove")
    p_data.hand_injury_mod_glove = (metadata ~= 0 and metadata) or 1

    metadata = player_meta:get_float("hand_injury_mod_skill")
    p_data.hand_injury_mod_skill = (metadata ~= 0 and metadata) or 1

    p_data.sneeze_timer = player_meta:get_float("sneeze_timer")
    p_data.sneezing_time_remain = player_meta:get_int("sneezing_time_remain")
    p_data.cough_timer = player_meta:get_float("cough_timer")
    p_data.coughing_time_remain = player_meta:get_int("coughing_time_remain")
    p_data.vomit_timer = player_meta:get_float("vomit_timer")
    p_data.vomitting_time_remain = player_meta:get_int("vomitting_time_remain")

    p_data.health_rec_from_thirst = player_meta:get_float("health_rec_from_thirst")
    p_data.health_rec_from_hunger = player_meta:get_float("health_rec_from_hunger")
    p_data.health_rec_from_breath = player_meta:get_float("health_rec_from_breath")
    p_data.health_rec_from_hot = player_meta:get_float("health_rec_from_hot")
    p_data.health_rec_from_cold = player_meta:get_float("health_rec_from_cold")
    p_data.health_rec_from_illness = player_meta:get_float("health_rec_from_illness")
    p_data.health_rec_from_poison = player_meta:get_float("health_rec_from_poison")


    local player_status = p_data.player_status
	if player_status == 0 then
		--debug(flag1, "  new player")

        if ENABLE_STATUS_EFFECTS_MONITOR then
            local job_handle = mt_after(0, monitor_status_effects, player, player_meta, player_name, p_data, p_data.status_effects)
            job_handles[player_name].monitor_status_effects = job_handle
        end

	elseif player_status == 1 then
		--debug(flag1, "  existing player")

        continue_sneezing(player, player_meta, player_name, p_data)
        continue_coughing(player, p_data)
        continue_vomitting(player, player_meta, player_name, p_data)

        if ENABLE_STATUS_EFFECTS_MONITOR then
            local job_handle = mt_after(0, monitor_status_effects, player, player_meta, player_name, p_data, p_data.status_effects)
            job_handles[player_name].monitor_status_effects = job_handle
        end

    elseif player_status == 2 then
		--debug(flag1, "  dead player")
    end

    debug(flag1, "register_on_joinplayer() end")
end)



local flag16 = false
core.register_on_respawnplayer(function(player)
    debug(flag16, "\nregister_on_respawnplayer() STATUS EFFECTS")
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local p_data = ss.player_data[player_name]

    p_data.stamina_drain_mod_thirst = 1
    p_data.stamina_drain_mod_hunger = 1
    p_data.stamina_drain_mod_alertness = 1
    p_data.stamina_drain_mod_weight = 1
    p_data.stamina_drain_mod_illness = 1
    p_data.stamina_drain_mod_poison = 1

    p_data.stamina_rec_mod_hot = 1
    p_data.stamina_rec_mod_cold = 1
    p_data.stamina_rec_mod_illness = 1
    p_data.stamina_rec_mod_poison = 1

    p_data.leg_injury_mod_foot_clothing = 1
    player_meta:set_float("leg_injury_mod_foot_clothing", p_data.leg_injury_mod_foot_clothing)
    p_data.leg_injury_mod_foot_armor = 1
    player_meta:set_float("leg_injury_mod_foot_armor", p_data.leg_injury_mod_foot_armor)
    p_data.leg_injury_mod_skill = 1
    player_meta:set_float("leg_injury_mod_skill", p_data.leg_injury_mod_skill)

    p_data.hand_injury_mod_glove = 1
    player_meta:set_float("hand_injury_mod_glove", p_data.hand_injury_mod_glove)
    p_data.hand_injury_mod_skill = 1
    player_meta:set_float("hand_injury_mod_skill", p_data.hand_injury_mod_skill)

    p_data.sneeze_timer = 0
    player_meta:set_float("sneeze_timer", p_data.sneeze_timer)
    p_data.sneezing_time_remain = 0
    player_meta:set_int("sneezing_time_remain", p_data.sneezing_time_remain)
    p_data.cough_timer = 0
    player_meta:set_float("cough_timer", p_data.cough_timer)
    p_data.coughing_time_remain = 0
    player_meta:set_int("coughing_time_remain", p_data.coughing_time_remain)
    p_data.vomit_timer = 0
    player_meta:set_float("vomit_timer", p_data.vomit_timer)
    p_data.vomitting_time_remain = 0
    player_meta:set_int("vomitting_time_remain", p_data.vomitting_time_remain)

    p_data.health_rec_from_thirst = 0
    player_meta:set_float("health_rec_from_thirst", p_data.health_rec_from_thirst)
    p_data.health_rec_from_hunger = 0
    player_meta:set_float("health_rec_from_hunger", p_data.health_rec_from_hunger)
    p_data.health_rec_from_breath = 0
    player_meta:set_float("health_rec_from_breath", p_data.health_rec_from_breath)
    p_data.health_rec_from_hot = 0
    player_meta:set_float("health_rec_from_hot", p_data.health_rec_from_hot)
    p_data.health_rec_from_cold = 0
    player_meta:set_float("health_rec_from_cold", p_data.health_rec_from_cold)
    p_data.health_rec_from_illness = 0
    player_meta:set_float("health_rec_from_illness", p_data.health_rec_from_illness)
    p_data.health_rec_from_poison = 0
    player_meta:set_float("health_rec_from_poison", p_data.health_rec_from_poison)

    if ENABLE_STATUS_EFFECTS_MONITOR then
        local job_handle = mt_after(0, monitor_status_effects, player, player_meta, player_name, p_data, p_data.status_effects)
        job_handles[player_name].monitor_status_effects = job_handle
        --debug(flag1, "  started status effects monitor")
    end

    debug(flag16, "register_on_respawnplayer() END")
end)