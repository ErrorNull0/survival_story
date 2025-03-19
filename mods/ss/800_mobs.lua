<<<<<<< HEAD
print("- loading mobs.lua")
-- the code in this file is from experimentation with entities and learning how
-- to create mobs. some or maybe none of the code will carry over to the actuall
-- game. this file is currently not loaded and the boar b3d files no longer exist.


-- cache global functions for faster access
local table_insert = table.insert
local io_open = io.open
local vector_equals = vector.equals
local math_random = math.random
local mt_after = minetest.after
local mt_get_node = minetest.get_node
local mt_add_item = minetest.add_item
local mt_pos_to_string = minetest.pos_to_string
local mt_deserialize = minetest.deserialize
local mt_serialize = minetest.serialize
local mt_add_entity = minetest.add_entity
local debug = ss.debug
local notify = ss.notify
local set_stat = ss.set_stat
local play_item_sound = ss.play_item_sound


local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids


---------------------------------------------------
-- Load Custom Mob Properties from External File --
---------------------------------------------------

-- table that is indexed by mob names. contains modified properties and new properties
-- to insert into the enitity definition
local mob_def_extra = {}

-- parse main line that includes the mob's name, hp, xp, and armor factors
local function parse_main_line(line)
    --print("line: " .. line)
    local values = {}
    for value in line:gmatch("[^,]+") do
        table_insert(values, value)
    end
    --print("values: " .. dump(values))
    return {
        name = values[2],
        hp = tonumber(values[3]),
        hp_corpse = tonumber(values[4]),
        xp = tonumber(values[5]),
        armor = {
            fists = tonumber(values[6]),
            blunt = tonumber(values[7]),
            blade = tonumber(values[8]),
            spear = tonumber(values[9]),
            mining = tonumber(values[10]),
        },
        drops = {}
    }
end

-- parse the item drop line that includes the item name, quant, and its probability
local function parse_drop_line(line)
    local name, quant, prob = line:match("([^,]+),([^,]+),([^,]+)")
    return {
        name = name,
        quant = tonumber(quant),
        prob = tonumber(prob)
    }
end

-- Function to read the file and parse the mob data
local function read_mob_data(filename)
    local file = io_open(filename, "r")

    if file then
        local current_mob = nil
        for line in file:lines() do
            if line:match("^#") or line:match("^%s*$") then
                -- Skip comments and blank lines
                current_mob = nil
            elseif current_mob then
                -- Parsing an item drop line
                table_insert(mob_def_extra[current_mob].drops, parse_drop_line(line))
            else
                -- Parsing the main mob data line
                local mob_name = line:match("^([^,]+),")
                if mob_name then
                    mob_def_extra[mob_name] = parse_main_line(line)
                    current_mob = mob_name
                end
            end
        end
        file:close()

    else
        print("## ERROR - Failed to open file " .. filename)
    end
end

-- Read the mob data from the file
local filename = minetest.get_modpath("ss") .. "/mob_data.txt"
read_mob_data(filename)
--print("loaded mob_def_extra: " .. dump(mob_def_extra))


local mob_hudbar_height = 15
local mob_hudbar_width = 300
local show_hudbar_duration = 6
local show_damage_duration = 1

-- hides mob name and hud from on-screen display
local function hide_mob_hud(player)
    local player_name = player:get_player_name()
    local hud_id = ss.player_hud_ids[player_name].mob_hud
    player:hud_change(hud_id, "scale", {x = 0, y = 0})
    hud_id = ss.player_hud_ids[player_name].mob_hud_bg
    player:hud_change(hud_id, "scale", {x = 0, y = 0})
    hud_id = ss.player_hud_ids[player_name].mob_hud_name
    player:hud_change(hud_id, "text", "")

end

--- @param self table the mob's entity definition table
--- @param player ObjectRef the player object
--- @param status string whether this hud is for a mob that is 'alive' or 'dead'
local function update_mod_hud(self, player, status)
    print("  update_mod_hud()")

    local hudbar_image
    if status == "alive" then
        hudbar_image = "[fill:1x1:0,0:#c00000"
    elseif status == "dead" then
        hudbar_image = "[fill:1x1:0,0:#800000"
    else
        print("    ERROR: Unknown status value: " .. status)
    end

    -- dislay mob name
    local player_name = player:get_player_name()
    local hud_id = ss.player_hud_ids[player_name].mob_hud_name
    player:hud_change(hud_id, "text", self.name_hud)

    -- dislay the black bg bar
    hud_id = ss.player_hud_ids[player_name].mob_hud_bg
    player:hud_change(hud_id, "scale", {x = mob_hudbar_width, y = mob_hudbar_height})

    -- display main hudbar
    local mob_hp = self.object:get_hp()
    local mob_hp_max = self.initial_properties.hp_max
    local hudbar_value = (mob_hp / mob_hp_max) * mob_hudbar_width
    hud_id = ss.player_hud_ids[player_name].mob_hud
    player:hud_change(hud_id, "text", hudbar_image)
    player:hud_change(hud_id, "scale", {x = hudbar_value, y = mob_hudbar_height})
    print("  update_mod_hud() end")
end


local function mob_idle(self)
    self.object:set_animation({x=self.anim.idle_start, y=self.anim.idle_end}, self.anim.speed_24)
    self.object:set_velocity({ x = 0, y = 0, z = 0 })
end

local function mob_turn(self)
    self.object:set_animation({x=self.anim.idle_start, y=self.anim.idle_end}, self.anim.speed_24)
    self.object:set_velocity({ x = 0, y = 0, z = 0 })

    -- Randomly choose 45 degree turn left or right
    local angle = math_random(2) == 1 and math.pi / 4 or -math.pi / 4
    local yaw = self.object:get_yaw()
    self.object:set_yaw(yaw + angle)
end

local function mob_walk(self)
    self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, self.anim.speed_24)
    local yaw = self.object:get_yaw()
    local horizontal_speed = 0.65
    local vec = { x = -math.sin(yaw) * horizontal_speed, y = 0, z = math.cos(yaw) * horizontal_speed }
    self.object:set_velocity(vec)
end

local function mob_run(self)
    self.object:set_animation({x=self.anim.run_start, y=self.anim.run_end}, self.anim.speed_48)
    local yaw = self.object:get_yaw()
    local horizontal_speed = 2
    local vec = { x = -math.sin(yaw) * horizontal_speed, y = 0, z = math.cos(yaw) * horizontal_speed }
    self.object:set_velocity(vec)
end

local function mob_jump(self)
    self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, self.anim.speed_24)

    -- make mob move vertically upward
    self.object:set_velocity({x = 0, y = 6.0, z = 0})

    -- make mob move horizontally forward
    mt_after(0.33, function()
        local yaw = self.object:get_yaw()
        self.object:set_velocity({x = -math.sin(yaw), y = 0, z = math.cos(yaw)})
    end)
end


local function can_mob_jump_on(mob_object)
    local jumpable = true
    print("  can_mob_jump_on()")
    -- Obtain the position and yaw directly from the self object
    local pos = mob_object:get_pos()
    local yaw = mob_object:get_yaw()

    -- Calculate the position of the target node
    local target_pos = {
        x = pos.x - math.sin(yaw),
        y = pos.y + 0.5,
        z = pos.z + math.cos(yaw)
    }
    local target_name = mt_get_node(target_pos).name
    print("    target_pos: " .. mt_pos_to_string(target_pos))
    print("    target_name: " .. target_name)

    -- snow nodes are just 1/4 height of normal block an not jumpable
    if target_name == "default:snow" then
        print("    node is snow and not solid")
        jumpable = false

    else
        if minetest.registered_nodes[target_name].walkable then
            print("    node is solid")

            -- Check for non-solid nodes above the target node
            print("    target node ok. checking nodes above...")
            for i = 1, 3 do
                local check_pos = { x = target_pos.x, y = target_pos.y + i, z = target_pos.z }
                local above_node = mt_get_node(check_pos)
                local above_name = above_node.name
                print("      above_name: " .. above_name)
                if minetest.registered_nodes[above_name].walkable then
                    if above_name == "default:snow" then
                        print("      node not solid")
                    else
                        print("      node is solid")
                        jumpable = false
                    end
                end
            end

        else
            print("    node is not solid")
            jumpable = false
        end
    end

    print("  can_mob_jump_on() end")
    return jumpable
end


-- manages animation and movement speed of the mob
local function mob_state_passive(self)
    print("\n** mob_state_passive(" .. self.name .. ") **")
    local state = self.state
    print("  state: " .. state)

    local random_num
    if state == "idle" then
        print("  entity is idle")
        mob_idle(self)
        if can_mob_jump_on(self.object) then
            print("  node jumpable")
            random_num = math_random(1,2)
            if random_num == 1 then
                self.state = "jump"
                print("  next state: jump")
            else
                self.state = "turn"
                print("  next state: turn")
            end
        else
            print("  node not jumpable")
            random_num = math_random(1,3)
            if random_num == 1 then
                self.state = "idle"
                print("  next state: idle")
            elseif random_num == 2 then
                self.state = "turn"
                print("  next state: turn")
            else
                self.state = "walk"
                print("  next state: walk")
            end
        end
        self.state = "idle"
        self.job_main = mt_after(math.random(1,5), mob_state_passive, self)


    elseif state == "turn" then
        print("  entity is turning")
        mob_turn(self)
        if can_mob_jump_on(self.object) then
            print("  node jumpable")
            random_num = math_random(1,2)
            if random_num then
                self.state = "jump"
                print("  next state: jump")
            end
        else
            print("  node not jumpable")
            random_num = math_random(1,3)
            if random_num == 1 then
                self.state = "idle"
                print("  next state: idle")
            elseif random_num == 2 then
                self.state = "turn"
                print("  next state: turn")
            else
                self.state = "walk"
                print("  next state: walk")
            end
        end
        self.job_main = mt_after(1, mob_state_passive, self)


    elseif state == "jump" then
        print("  ** jumping **")
        mob_jump(self)
        random_num = math_random(1,3)
        if random_num == 1 then
            self.state = "idle"
            print("  next state: idle")
        elseif random_num == 2 then
            self.state = "turn"
            print("  next state: turn")
        else
            self.state = "walk"
            print("  next state: walk")
        end
        self.job_main = mt_after(2, mob_state_passive, self)


    elseif state == "walk" then
        print("  entity is walking")
        mob_walk(self)

        -- ensure that if mob is walking into a node and not moving,
        -- that the next action will always be to turn
        local start_pos = self.object:get_pos()
        self.job_main = mt_after(math_random(1,5), function()
            local end_pos = self.object:get_pos()
            if vector_equals(start_pos, end_pos) then
                print("  object has not moved. turning...")
                self.state = "turn"
                print("  next state: turn")
                mob_state_passive(self)
            else
                print("  object has moved")
                random_num = math_random(1,3)
                if random_num == 1 then
                    self.state = "idle"
                    print("  next state: idle")
                elseif random_num == 2 then
                    self.state = "walk"
                    print("  next state: walk")
                else
                    self.state = "run"
                    print("  next state: run")
                end
                mob_state_passive(self)
            end
        end)


    elseif state == "run" then
        print("  entity is running")
        mob_run(self)

        -- ensure that if mob is running into a node and not moving,
        -- that the next action will always be to turn
        local start_pos = self.object:get_pos()
        self.job_main = mt_after(math_random(1,5), function()
            local end_pos = self.object:get_pos()
            if vector_equals(start_pos, end_pos) then
                print("  object has not moved. turning...")
                self.state = "turn"
                print("  next state: turn")
                mob_state_passive(self)
            else
                print("  object has moved")
                random_num = math_random(1,2)
                if random_num == 1 then
                    self.state = "run"
                    print("  next state: run")
                else
                    self.state = "walk"
                    print("  next state: walk")
                end
                mob_state_passive(self)
            end
        end)

    else
        print("  Error: Unexpected 'state' value: " .. state)
    end

    print("** mob_state_passive() end **")
end


-- Function to add initial velocity to the item drops from mobs
local function add_velocity_to_item(item_drop)
    local velocity = {
        x = math_random(-0.2, 0.2),
        y = math_random(0.5, 2.0),
        z = math_random(-0.2, 0.2)
    }
    item_drop:set_velocity(velocity)
end

local entity_name_base = "ss:boar"
for mob_variation = 1, 3 do

    -- ###############
    -- ### DEAD BOAR 
    -- ###############
    local entity_name = entity_name_base .. mob_variation
    local mob_data = mob_def_extra[entity_name_base]

    minetest.register_entity(entity_name .. "_dead", {
        initial_properties = {
            hp_max = mob_data.hp_corpse,
            physical = true,
            collide_with_objects = false,
            collisionbox = { -0.3, -0.0, -0.3, 0.3, 0.5, 0.3},
            selectionbox = { -0.3, 0.1, -0.3, 0.3, 0.9, 0.3, rotate = true },
            visual = "mesh",
            mesh = "ss_animal_boar" .. mob_variation .. ".b3d",
            textures = {"ss_mobs_animals_forest.png"},
        },

        -- custom properties
        name_hud = "Dead " .. mob_data.name,
        experience = (mob_data.xp * 0.1),
        armor = mob_data.armor,
        drops = mob_data.drops,
        job_hud = {},

        on_activate = function(self, staticdata, dtime_s)
            --print("\n### on_activate() " .. self.name .. " ###")
            local data = mt_deserialize(staticdata)

            -- reload mob's prior hp
            if data then
                print("  data: " .. dump(data))
                local mob_hp = data.mob_hp
                if data.mob_hp then
                    self.object:set_hp(mob_hp)
                else print("  New mob corpse. HP set to hp_max") end
            else print("  ERROR: No staticdata available") end

            --print("### on_activate() end ###")
        end,

        -- custom function to show mob hudbar
        update_hud = function(self, player)
            update_mod_hud(self, player, "dead")
        end,

        on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            print("\n### on_punch() " .. self.name .. " ###")
            print("  time_from_last_punch: " .. time_from_last_punch)
            local player_name = puncher:get_player_name()
            local player_meta = puncher:get_meta()
            local wielded_item_name = puncher:get_wielded_item():get_name()
            local stamina_current = player_meta:get_float("stamina_current")

            local cooldown_time, attack_group, attack_damage, weapon_weight
            if wielded_item_name == "" then
                print("  using hands")

                attack_group = "fists"
                cooldown_time = ss.player_data[player_name].fists_cooldown_time
                attack_damage = ss.player_data[player_name].fists_attack_damage
                weapon_weight = 2.00
            else
                print("  wielding an item")
                local ss_data = minetest.registered_items[wielded_item_name]._ss_data
                attack_group = ss_data.attack_group or "fists"
                cooldown_time = ss_data.attack_cooldown or 1.0
                attack_damage = ss_data.attack_damage or math_random()
                weapon_weight = ss_data.weight or 2.00
            end
            print("  weapon_weight: " .. weapon_weight)

            local weapon_stamina_loss = weapon_weight * 2
            print("  weapon_stamina_loss: " .. weapon_stamina_loss)
            set_stat(puncher, player_meta, "stamina", "down", weapon_stamina_loss)

            local cooldown_modifier = player_meta:get_float("cooldown_mod_" .. attack_group)
            local attack_cooldown_time = cooldown_time + cooldown_modifier
            print("  attack_cooldown_time: " .. attack_cooldown_time)

            local mob_name = self.name

            -- force a miss when stamina is not enough to swing the weapon
            if stamina_current < weapon_stamina_loss then
                notify(puncher, "Stamina too low", 1, "message_box_3")
                print("  ** MISSED **")
                -- 'intensity' param is set below 0.75 to have reduced gain and pitch
                --play_mob_sound(mob_name, "miss", attack_group, 0.5)
                play_item_sound("hit_mob", {
                    player = puncher,
                    hit_type = "miss",
                    attack_group = attack_group,
                    intensity = 0.5
                })
                return
            end

            local hit_intensity = time_from_last_punch / attack_cooldown_time
            if hit_intensity > 1.0 then
                print("  full attack strength")
                hit_intensity = 1.0

            elseif hit_intensity < 0.5 then
                print("  less than half attack strength")
                local random_num = math_random(1,3)
                if random_num > 1 then
                    print("  ** MISSED **")
                    --play_mob_sound(mob_name, "miss", wielded_item_name, hit_intensity)
                    play_item_sound("hit_mob", {
                        player = puncher,
                        hit_type = "miss",
                        attack_group = wielded_item_name,
                        intensity = hit_intensity
                    })
                    return
                end

            end
            print("  hit_intensity: " .. hit_intensity)

            --play_mob_sound(mob_name, "harvest", attack_group, hit_intensity)
            play_item_sound("hit_mob", {
                player = puncher,
                hit_type = "harvest",
                attack_group = attack_group,
                intensity = hit_intensity
            })

            if self.job_hud[player_name] then
                print("  hud job exists")
                self.job_hud[player_name]:cancel()
                print("  stopped job")
                self.job_hud[player_name] = nil
            else
                print("  no existing hud jobs")
            end

            local weapon_attack_strength = attack_damage
            print("  weapon_attack_strength: " .. weapon_attack_strength)

            local entity_defense_factor = self.armor[attack_group]
            print("  entity_defense_factor: " .. entity_defense_factor)

            local damage_inflicted = weapon_attack_strength * entity_defense_factor
            print("  damage_inflicted (initial): " .. damage_inflicted)

            damage_inflicted = damage_inflicted * hit_intensity
            print("  damage_inflicted (w/ intensity): " .. damage_inflicted)

            damage_inflicted = math.round(damage_inflicted)
            print("  damage_inflicted (rounded): " .. damage_inflicted)

            -- get mob's position and facing direction
            local mob = self.object
            local pos = mob:get_pos()
            local hp = mob:get_hp()
            local new_hp = hp - damage_inflicted
            mob:set_hp(new_hp)

            if new_hp <= 0 then
                print("  corpse fully harvested")
                set_stat(puncher, player_meta, "experience", "up", self.experience)
                hide_mob_hud(puncher)
                self.job_hud[player_name] = nil

                print("  Spawning items at the entity's position.")
                pos.y = pos.y + 0.5
                local item_drop
                for _, drop_data in ipairs(self.drops) do
                    local random_num = math.random(100)
                    if random_num <= drop_data.prob then
                        item_drop = mt_add_item(pos, drop_data.name .. " " .. drop_data.quant)
                        if item_drop then add_velocity_to_item(item_drop) end
                    end
                end

            else
                print("  new_hp: " .. new_hp)

                -- display mob hudbar and schedule job to handle removal
                self:update_hud(puncher)
                self.job_hud[player_name] = mt_after(show_hudbar_duration, function()
                    print("\n### hiding " .. mob_name .. " hud from player: " .. player_name .. " ###")
                    hide_mob_hud(puncher)
                    self.job_hud[player_name] = nil
                    print("### done hiding end ###")
                end)
            end

            print("### on_punch() end ###")
        end,

        on_deactivate = function(self, removal)
            --print("\non deactivate() " .. self.name)
            --print("on deactivate() end\n")
        end,

        get_staticdata = function(self)
            print("\nget_staticdata() " .. self.name)
            local static_data = {
                mob_hp = self.object:get_hp()
            }
            print("  saved static_data: " .. dump(static_data))
            print("get_staticdata() end")
            return mt_serialize(static_data)
        end,

    })


    -- ##########
    -- ### BOAR 
    -- ##########
    minetest.register_entity(entity_name, {
        initial_properties = {
            hp_max = mob_data.hp,
            physical = true,
            collisionbox = {-0.3, -0.0, -0.3, 0.3, 0.5, 0.3},
            visual = "mesh",
            mesh = "ss_animal_boar" .. mob_variation .. ".b3d",
            textures = {"ss_mobs_animals_forest.png"},
        },

        -- custom properties
        name_hud = mob_data.name,
        name_dead = entity_name .. "_dead",
        state = "idle",
        experience = mob_data.xp,
        armor = mob_data.armor,
        job_nametag = nil,
        job_hud = {},
        anim = {
            speed_24 = 24, speed_48 = 55,
            idle_start = 0, idle_end = 121,
            walk_start = 131, walk_end = 160,
            run_start = 171, run_end = 205,
        },

        -- job_main = stores minetest.after() job handle for mob_state_passive() loop
        -- job_nametag = stores minetest.after() job handle for hiding mob nametag

        on_activate = function(self, staticdata, dtime_s)
            --print("\n### on_activate() " .. self.name .. " ###")
            local data = mt_deserialize(staticdata)

            -- reload mob's prior hp
            if data then
                print("  data: " .. dump(data))
                self.object:set_hp(data.mob_hp)
            end

            -- ensure mob reacts to gravity
            self.object:set_acceleration({x=0, y=-9.8, z=0})

            -- start 'passive' AI behavior
            mob_state_passive(self)

            --print("### on_activate() end ###")
        end,

        -- custom function to show inflicted damage above mob
        update_nametag = function(self, player, damage_inflicted)
            if damage_inflicted > 0 then
                damage_inflicted = "-" .. damage_inflicted
            end
            self.object:set_nametag_attributes({
                text = damage_inflicted,
                color = {a = 255, r = 255, g = 0, b = 0},
                bgcolor = {a = 0, r = 0, g = 0, b = 0}
            })
        end,

        -- custom function to show mob hudbar
        update_hud = function(self, player)
            update_mod_hud(self, player, "alive")
        end,

        on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            print("\n### on_punch() " .. self.name .. " ###")
            print("  time_from_last_punch: " .. time_from_last_punch)
            local player_name = puncher:get_player_name()
            local player_meta = puncher:get_meta()
            local wielded_item_name = puncher:get_wielded_item():get_name()
            local stamina_current = player_meta:get_float("stamina_current")
            print("  stamina_current: " .. stamina_current)

            local cooldown_time, attack_group, attack_damage, weapon_weight
            if wielded_item_name == "" then
                print("  using hands")
                attack_group = "fists"
                cooldown_time = ss.player_data[player_name].fists_cooldown_time
                attack_damage = ss.player_data[player_name].fists_attack_damage
                weapon_weight = 2.00
            else
                print("  wielding an item")
                local ss_data = minetest.registered_items[wielded_item_name]._ss_data
                attack_group = ss_data.attack_group or "fists"
                cooldown_time = ss_data.attack_cooldown or 1.0
                attack_damage = ss_data.attack_damage or math_random()
                weapon_weight = ss_data.weight or 2.00
            end
            print("  weapon_weight: " .. weapon_weight)

            local weapon_stamina_loss = weapon_weight * 2
            print("  weapon_stamina_loss: " .. weapon_stamina_loss)
            set_stat(puncher, player_meta, "stamina", "down", weapon_stamina_loss)

            local cooldown_modifier = player_meta:get_float("cooldown_mod_" .. attack_group)
            local attack_cooldown_time = cooldown_time + cooldown_modifier
            print("  attack_cooldown_time: " .. attack_cooldown_time)

            local mob_name = self.name

            -- force a miss when stamina is not enough to swing the weapon
            if stamina_current < weapon_stamina_loss then
                notify(puncher, "Stamina too low", 1, "message_box_3")
                print("  ** MISSED **")
                -- 'intensity' param is set below 0.75 to have reduced gain and pitch
                --play_mob_sound(mob_name, "miss", attack_group, 0.5)
                play_item_sound("hit_mob", {
                    player = puncher,
                    hit_type = "miss",
                    attack_group = attack_group,
                    intensity = 0.5
                })
                return
            end

            local hit_intensity = time_from_last_punch / attack_cooldown_time
            if hit_intensity > 1.0 then
                print("  full attack strength")
                hit_intensity = 1.0

            elseif hit_intensity < 0.5 then
                print("  less than half attack strength")
                local random_num = math_random(1,3)
                if random_num > 1 then
                    print("  ** MISSED **")
                    play_item_sound("hit_mob", {
                        player = puncher,
                        hit_type = "miss",
                        attack_group = attack_group,
                        intensity = hit_intensity
                    })
                    return
                end

            end
            print("  hit_intensity: " .. hit_intensity)

            play_item_sound("hit_mob", {
                player = puncher,
                hit_type = "hit",
                attack_group = attack_group,
                intensity = hit_intensity
            })

            if self.job_nametag then
                print("  nametag job exists")
                self.job_nametag:cancel()
                print("  stopped job")
                self.job_nametag = nil
            else
                print("  no existing nametag jobs")
            end

            if self.job_hud[player_name] then
                print("  hud job exists for " .. player_name)
                self.job_hud[player_name]:cancel()
                print("  stopped job hud")
                self.job_hud[player_name] = nil
            else
                print("  no existing hud jobs")
            end

            local weapon_attack_strength = attack_damage
            local entity_defense_factor = self.armor[attack_group]
            local damage_inflicted = weapon_attack_strength * entity_defense_factor
            print("  weapon_attack_strength: " .. weapon_attack_strength)
            print("  entity_defense_factor: " .. entity_defense_factor)
            print("  damage_inflicted (initial): " .. damage_inflicted)

            damage_inflicted = math.round(damage_inflicted * hit_intensity)
            print("  damage_inflicted (rounded and w/ hit_intensity): " .. damage_inflicted)

            -- get mob's position and facing direction
            local mob = self.object
            local mob_pos = mob:get_pos()
            local mob_yaw = mob:get_yaw()

            -- reduce mod's hp
            local hp = mob:get_hp()
            local new_hp = hp - damage_inflicted
            mob:set_hp(new_hp)

            if new_hp <= 0 then
                print("  mob is dead")

                set_stat(puncher, player_meta, "experience", "up", self.experience)
                hide_mob_hud(puncher)
                self.job_hud[player_name] = nil

                -- spawn dead version of the mob. the facing direction 'yaw' of the once
                -- alive entity is passed to the dead mob via staticdata property.
                local dead_mob = mt_add_entity(mob_pos, self.name_dead, mt_serialize({yaw = mob_yaw}))

                -- ensure dead mob reacts to gravity
                dead_mob:set_acceleration({x=0, y=-9.8, z=0})

                -- make dead mob face same direction but lying on its side
                dead_mob:set_yaw(mob_yaw)
                dead_mob:set_pos({ x = mob_pos.x, y = mob_pos.y + 0.2, z = mob_pos.z })
                if math_random(1,2) == 1 then
                    dead_mob:set_rotation({x = 0, y = mob_yaw, z = math.pi / 2})
                else
                    dead_mob:set_rotation({x = 0, y = mob_yaw, z = -math.pi / 2})
                end

                -- ensure dead mob reacts to gravity
                dead_mob:set_acceleration({x=0, y=-9.8, z=0})

            else
                print("  new_hp: " .. new_hp)

                -- display nametage and schedule job to handle removal
                self:update_nametag(puncher, damage_inflicted)
                self.job_nametag = mt_after(show_damage_duration, function()
                    print("\n### hiding nametag for " .. mob_name .. " ###")
                    mob:set_nametag_attributes({text = ""})
                    self.job_nametag = nil
                    print("### done hiding end ###")
                end)

                -- display mob hudbar and schedule job to handle removal
                self:update_hud(puncher)
                self.job_hud[player_name] = mt_after(show_hudbar_duration, function()
                    print("\n### hiding " .. mob_name .. " hud from player: " .. player_name .. " ###")
                    hide_mob_hud(puncher)
                    self.job_hud[player_name] = nil
                    print("### done hiding end ###")
                end)

            end

            print("### on_punch() end ###")
        end,

        on_rightclick = function(self, clicker)
            print("> you right-cliced on " .. self.name)
            if self.job_nametag then
                print("  nametag job exists")
                self.job_nametag:cancel()
            else
                print("  no existing nametag jobs")
            end
        end,

        on_deactivate = function(self, removal)
            print("\non deactivate() " .. self.name)
            if self.job_main then
                self.job_main:cancel()
                print("  main job stopped")
            else
                print("  no main jobs to stop")
            end

            if self.job_nametag then
                self.job_nametag:cancel()
                print("  existing nametag job stopped")
            else
                print("  no existing nametag jobs to stop")
            end

            print("on deactivate() end\n")
        end,

        get_staticdata = function(self)
            print("\nget_staticdata() " .. self.name)
            local static_data = {
                mob_hp = self.object:get_hp()
            }
            print("  saved static_data: " .. dump(static_data))
            print("get_staticdata() end")
            return mt_serialize(static_data)
        end,
    })

end




-- ##############
-- ### BLOCKY MOB 
-- ##############
minetest.register_entity("ss:blocky_mob", {
    initial_properties = {
        hp_max = 100,
        physical = true,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        visual = "mesh",
        mesh = "blocky_mob2.b3d",
        textures = {"blocky_mob.png"},
    },

    -- custom properties
    hp_corpse = 100,
    name_hud = "blocky mob",
    state = "idle",
    experience = 100,
    armor = {fists = 1.0, blunt = 1.0, blade = 1.0, spear = 1.0, mining = 1.0},
    job_nametag = nil,
    job_hud = {},
    anim = {
        idle_start = 0,
        idle_end = 10,

        -- walk and run starts at 1 frame prior to actual start frame in Blender
        walk_start = 14, walk_end = 22,
        run_start = 29, run_end = 37,

        -- all death frames start 3 frames prior to actual start frame in blender, and
        -- end 1 frame prior to actual end from in blender.
        death_start_l = 42, death_end_l = 47,
        death_start_r = 52, death_end_r = 57,
        death_start_b = 62, death_end_b = 67,
        death_start_f = 72, death_end_f = 77,
    },

    -- job_main = stores minetest.after() job handle for mob_state_passive() loop
    -- job_nametag = stores minetest.after() job handle for hiding mob nametag

    on_activate = function(self, staticdata, dtime_s)
        --print("\n### on_activate() " .. self.name .. " ###")
        local data = mt_deserialize(staticdata)

        -- reload mob's prior hp
        if data then
            print("  data: " .. dump(data))
            self.object:set_hp(data.mob_hp)
        end

        -- ensure mob reacts to gravity
        self.object:set_acceleration({x=0, y=-9.8, z=0})

        -- start 'idle' animation
        if math_random(1,2) == 1 then
            self.object:set_animation({x=self.anim.run_start, y=self.anim.run_end}, 10, 0, true)
        else
            self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, 10, 0, true)
        end
        self.object:set_velocity({ x = 0, y = 0, z = 0 })

        --print("### on_activate() end ###")
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        print("\n### on_punch() " .. self.name .. " ###")

        print("### on_punch() end ###")
    end,

    on_rightclick = function(self, clicker)
        print("> you right-cliced on " .. self.name)
        if self.job_nametag then
            print("  nametag job exists")
            self.job_nametag:cancel()
        else
            print("  no existing nametag jobs")
        end
    end,

    on_deactivate = function(self, removal)
        print("\non deactivate() " .. self.name)

        print("on deactivate() end\n")
    end,

    get_staticdata = function(self)
        print("\nget_staticdata() " .. self.name)
        local static_data = {
            mob_hp = self.object:get_hp()
        }
        print("  saved static_data: " .. dump(static_data))
        print("get_staticdata() end")
        return mt_serialize(static_data)
    end,
})



-- ##############
-- ### ZOMBIE V1 
-- ##############
minetest.register_entity("ss:zombie", {
    initial_properties = {
        hp_max = 100,
        physical = true,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
        visual = "mesh",
        mesh = "zombie.b3d",
        textures = {"zombie.png"},
    },

    -- custom properties
    hp_corpse = 100,
    name_hud = "zombie",
    state = "idle",
    experience = 100,
    armor = {fists = 1.0, blunt = 1.0, blade = 1.0, spear = 1.0, mining = 1.0},
    job_nametag = nil,
    job_hud = {},
    anim = {
        -- idle ends 1 frame prior to actual end frame in blender
        idle_start = 0, idle_end = 59,

        -- walk and run starts at 1 frame prior to actual start frame in Blender
        walk_start = 69, walk_end = 81,
        run_start = 104, run_end = 116,

        -- all death frames start 3 frames prior to actual start frame in blender, and
        -- end 1 frame prior to actual end from in blender.
        death_start_l = 42, death_end_l = 47,
        death_start_r = 52, death_end_r = 57,
        death_start_b = 62, death_end_b = 67,
        death_start_f = 72, death_end_f = 77,
    },

    -- job_main = stores minetest.after() job handle for mob_state_passive() loop
    -- job_nametag = stores minetest.after() job handle for hiding mob nametag

    on_activate = function(self, staticdata, dtime_s)
        --print("\n### on_activate() " .. self.name .. " ###")
        local data = mt_deserialize(staticdata)

        -- reload mob's prior hp
        if data then
            print("  data: " .. dump(data))
            self.object:set_hp(data.mob_hp)
        end

        -- ensure mob reacts to gravity
        self.object:set_acceleration({x=0, y=-9.8, z=0})

        -- start 'idle' animation
        local random_num = math_random(1,3)
        if random_num == 1 then
            self.object:set_animation({x=self.anim.idle_start, y=self.anim.idle_end}, 10, 0, true)
        elseif random_num == 2 then
            self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, 10, 0, true)
        else
            self.object:set_animation({x=self.anim.run_start, y=self.anim.run_end}, 20, 0, true)
        end
        self.object:set_velocity({ x = 0, y = 0, z = 0 })

        --print("### on_activate() end ###")
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        print("\n### on_punch() " .. self.name .. " ###")

        print("### on_punch() end ###")
    end,

    on_rightclick = function(self, clicker)
        print("> you right-cliced on " .. self.name)
        if self.job_nametag then
            print("  nametag job exists")
            self.job_nametag:cancel()
        else
            print("  no existing nametag jobs")
        end
    end,

    on_deactivate = function(self, removal)
        print("\non deactivate() " .. self.name)

        print("on deactivate() end\n")
    end,

    get_staticdata = function(self)
        print("\nget_staticdata() " .. self.name)
        local static_data = {
            mob_hp = self.object:get_hp()
        }
        print("  saved static_data: " .. dump(static_data))
        print("get_staticdata() end")
        return mt_serialize(static_data)
    end,
})


-- ##############
-- ### PLAYER V1 
-- ##############
minetest.register_entity("ss:player", {
    initial_properties = {
        hp_max = 100,
        physical = true,
        collisionbox = {-0.35, -0.5, -0.35, 0.35, 1.25, 0.35},
        visual = "mesh",
        mesh = "player.b3d",
        textures = {"player.png"},
    },

    -- custom properties
    hp_corpse = 100,
    name_hud = "player",
    state = "idle",
    experience = 100,
    armor = {fists = 1.0, blunt = 1.0, blade = 1.0, spear = 1.0, mining = 1.0},
    job_nametag = nil,
    job_hud = {},
    anim = {
        -- animation ends 1 frame prior to actual end frame in blockbench/blender
        idle_start = 10, idle_end = 89,

        -- animation starts 1 frame prior to actual start frame in blockbench/blender
        walk_start = 99, walk_end = 115,
        run_start = 129, run_end = 145,
        mine_start = 159, mine_end = 166,

        -- animation starts and ends 1 frame prior to what is defined in blockbench/blender
        walk_mine_start = 179, walk_mine_end = 195,

        -- animation ends 1 frame prior to actual end frame in blockbench/blender
        lay_start = 210, lay_end = 211,
        sit_start = 220, sit_end = 221,
    },

    on_activate = function(self, staticdata, dtime_s)
        --print("\n### on_activate() " .. self.name .. " ###")
        local data = mt_deserialize(staticdata)

        -- reload mob's prior hp
        if data then
            print("  data: " .. dump(data))
            self.object:set_hp(data.mob_hp)
        end

        -- ensure mob reacts to gravity
        self.object:set_acceleration({x=0, y=-9.8, z=0})

        local random_num = math_random(1,4)
        if random_num == 1 then
            self.object:set_animation({x=self.anim.mine_start, y=self.anim.mine_end}, 20, 0, true)
        elseif random_num == 2 then
            self.object:set_animation({x=self.anim.walk_mine_start, y=self.anim.walk_mine_end}, 15, 0, true)
        elseif random_num == 3 then
            self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, 15, 0, true)
        else
            self.object:set_animation({x=self.anim.run_start, y=self.anim.run_end}, 25, 0, true)
        end
        self.object:set_velocity({ x = 0, y = 0, z = 0 })
        --print("### on_activate() end ###")
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        print("\n### on_punch() " .. self.name .. " ###")

        print("### on_punch() end ###")
    end,

    on_deactivate = function(self, removal)
        print("\non deactivate() " .. self.name)

        print("on deactivate() end\n")
    end,

    get_staticdata = function(self)
        print("\nget_staticdata() " .. self.name)
        local static_data = {
            mob_hp = self.object:get_hp()
        }
        print("  saved static_data: " .. dump(static_data))
        print("get_staticdata() end")
        return mt_serialize(static_data)
    end,
})


minetest.register_entity("ss:test", {
    -- Basic entity properties
    hp_max = 10,
    physical = true,
    collide_with_objects = true,
    collisionbox = {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25},
    visual = "mesh",
    visual_size = {x = 1, y = 1},
    mesh = "model.b3d",
    textures = {"model.png"},

    on_activate = function(self, staticdata, dtime_s)
        self.object:set_acceleration({x=0, y=-9.8, z=0})
    end,

})



local flag15 = false
minetest.register_on_joinplayer(function(player)
    debug(flag15, "\nregister_on_joinplayer() mobs.lua")
    local player_name = player:get_player_name()

    debug(flag15, "initializing mob huds...")
    -- initialize hud display for the mob hp hudbar. the visual scale is initially set
    -- to zero to hide it from display. when the mob is hit, the visual scale will change
    -- to real values and the hud show on screen for a short time.

    -- text for mob name
    player_hud_ids[player_name].mob_hud_name = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 0.0},
        offset = {x = 0, y = 102},
        text = "",
        size = {x = 1.0, y = 2.0},
        number = "0xFFFFFF",
        alignment = {x = 0, y = -1},
        scale = {x = 100, y = 100},
        style = 1
    })

    -- black bg for mob hp statbar
    player_hud_ids[player_name].mob_hud_bg = player:hud_add({
        type = "image",
        position = {x = 0.5, y = 0.0},
        offset = {x = -150, y = 120},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = 0, y = 0},
        alignment = {x = 1, y = -1}
    })

    -- red hp statbar for mob
    player_hud_ids[player_name].mob_hud =  player:hud_add({
        type = "image",
        position = {x = 0.5, y = 0.0},
        offset = {x = -150, y = 120},
        text = "[fill:1x1:0,0:#c00000",
        scale = {x = 0, y = 0},
        alignment = {x = 1, y = -1}
    })

    debug(flag15, "register_on_joinplayer() end " .. minetest.get_gametime())
=======
print("- loading mobs.lua")
-- the code in this file is from experimentation with entities and learning how
-- to create mobs. some or maybe none of the code will carry over to the actuall
-- game. this file is currently not loaded and the boar b3d files no longer exist.


-- cache global functions for faster access
local table_insert = table.insert
local io_open = io.open
local vector_equals = vector.equals
local math_random = math.random
local mt_after = core.after
local mt_get_node = core.get_node
local mt_add_item = core.add_item
local mt_pos_to_string = core.pos_to_string
local mt_deserialize = core.deserialize
local mt_serialize = core.serialize
local mt_add_entity = core.add_entity
local debug = ss.debug
local notify = ss.notify
local update_stat = ss.update_stat
local play_sound = ss.play_sound


local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids


---------------------------------------------------
-- Load Custom Mob Properties from External File --
---------------------------------------------------

-- table that is indexed by mob names. contains modified properties and new properties
-- to insert into the enitity definition
local mob_def_extra = {}

-- parse main line that includes the mob's name, hp, xp, and armor factors
local function parse_main_line(line)
    --print("line: " .. line)
    local values = {}
    for value in line:gmatch("[^,]+") do
        table_insert(values, value)
    end
    --print("values: " .. dump(values))
    return {
        name = values[2],
        hp = tonumber(values[3]),
        hp_corpse = tonumber(values[4]),
        xp = tonumber(values[5]),
        armor = {
            fists = tonumber(values[6]),
            blunt = tonumber(values[7]),
            blade = tonumber(values[8]),
            spear = tonumber(values[9]),
            mining = tonumber(values[10]),
        },
        drops = {}
    }
end

-- parse the item drop line that includes the item name, quant, and its probability
local function parse_drop_line(line)
    local name, quant, prob = line:match("([^,]+),([^,]+),([^,]+)")
    return {
        name = name,
        quant = tonumber(quant),
        prob = tonumber(prob)
    }
end

-- Function to read the file and parse the mob data
local function read_mob_data(filename)
    local file = io_open(filename, "r")

    if file then
        local current_mob = nil
        for line in file:lines() do
            if line:match("^#") or line:match("^%s*$") then
                -- Skip comments and blank lines
                current_mob = nil
            elseif current_mob then
                -- Parsing an item drop line
                table_insert(mob_def_extra[current_mob].drops, parse_drop_line(line))
            else
                -- Parsing the main mob data line
                local mob_name = line:match("^([^,]+),")
                if mob_name then
                    mob_def_extra[mob_name] = parse_main_line(line)
                    current_mob = mob_name
                end
            end
        end
        file:close()

    else
        print("## ERROR - Failed to open file " .. filename)
    end
end

-- Read the mob data from the file
local filename = core.get_modpath("ss") .. "/mob_data.txt"
read_mob_data(filename)
--print("loaded mob_def_extra: " .. dump(mob_def_extra))


local mob_hudbar_height = 15
local mob_hudbar_width = 300
local show_hudbar_duration = 6
local show_damage_duration = 1

-- hides mob name and hud from on-screen display
local function hide_mob_hud(player)
    local player_name = player:get_player_name()
    local hud_id = ss.player_hud_ids[player_name].mob_hud
    player:hud_change(hud_id, "scale", {x = 0, y = 0})
    hud_id = ss.player_hud_ids[player_name].mob_hud_bg
    player:hud_change(hud_id, "scale", {x = 0, y = 0})
    hud_id = ss.player_hud_ids[player_name].mob_hud_name
    player:hud_change(hud_id, "text", "")

end

--- @param self table the mob's entity definition table
--- @param player ObjectRef the player object
--- @param status string whether this hud is for a mob that is 'alive' or 'dead'
local function update_mod_hud(self, player, status)
    print("  update_mod_hud()")

    local hudbar_image
    if status == "alive" then
        hudbar_image = "[fill:1x1:0,0:#c00000"
    elseif status == "dead" then
        hudbar_image = "[fill:1x1:0,0:#800000"
    else
        print("    ERROR: Unknown status value: " .. status)
    end

    -- dislay mob name
    local player_name = player:get_player_name()
    local hud_id = ss.player_hud_ids[player_name].mob_hud_name
    player:hud_change(hud_id, "text", self.name_hud)

    -- dislay the black bg bar
    hud_id = ss.player_hud_ids[player_name].mob_hud_bg
    player:hud_change(hud_id, "scale", {x = mob_hudbar_width, y = mob_hudbar_height})

    -- display main hudbar
    local mob_hp = self.object:get_hp()
    local mob_hp_max = self.initial_properties.hp_max
    local hudbar_value = (mob_hp / mob_hp_max) * mob_hudbar_width
    hud_id = ss.player_hud_ids[player_name].mob_hud
    player:hud_change(hud_id, "text", hudbar_image)
    player:hud_change(hud_id, "scale", {x = hudbar_value, y = mob_hudbar_height})
    print("  update_mod_hud() end")
end


local function mob_idle(self)
    self.object:set_animation({x=self.anim.idle_start, y=self.anim.idle_end}, self.anim.speed_24)
    self.object:set_velocity({ x = 0, y = 0, z = 0 })
end

local function mob_turn(self)
    self.object:set_animation({x=self.anim.idle_start, y=self.anim.idle_end}, self.anim.speed_24)
    self.object:set_velocity({ x = 0, y = 0, z = 0 })

    -- Randomly choose 45 degree turn left or right
    local angle = math_random(2) == 1 and math.pi / 4 or -math.pi / 4
    local yaw = self.object:get_yaw()
    self.object:set_yaw(yaw + angle)
end

local function mob_walk(self)
    self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, self.anim.speed_24)
    local yaw = self.object:get_yaw()
    local horizontal_speed = 0.65
    local vec = { x = -math.sin(yaw) * horizontal_speed, y = 0, z = math.cos(yaw) * horizontal_speed }
    self.object:set_velocity(vec)
end

local function mob_run(self)
    self.object:set_animation({x=self.anim.run_start, y=self.anim.run_end}, self.anim.speed_48)
    local yaw = self.object:get_yaw()
    local horizontal_speed = 2
    local vec = { x = -math.sin(yaw) * horizontal_speed, y = 0, z = math.cos(yaw) * horizontal_speed }
    self.object:set_velocity(vec)
end

local function mob_jump(self)
    self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, self.anim.speed_24)

    -- make mob move vertically upward
    self.object:set_velocity({x = 0, y = 6.0, z = 0})

    -- make mob move horizontally forward
    mt_after(0.33, function()
        if not self then
            print("### core.after(): self object invalid. quitting. mobs.lua > ss.mob_jump()")
            return
        end
        local yaw = self.object:get_yaw()
        self.object:set_velocity({x = -math.sin(yaw), y = 0, z = math.cos(yaw)})
    end)
end


local function can_mob_jump_on(mob_object)
    local jumpable = true
    print("  can_mob_jump_on()")
    -- Obtain the position and yaw directly from the self object
    local pos = mob_object:get_pos()
    local yaw = mob_object:get_yaw()

    -- Calculate the position of the target node
    local target_pos = {
        x = pos.x - math.sin(yaw),
        y = pos.y + 0.5,
        z = pos.z + math.cos(yaw)
    }
    local target_name = mt_get_node(target_pos).name
    print("    target_pos: " .. mt_pos_to_string(target_pos))
    print("    target_name: " .. target_name)

    -- snow nodes are just 1/4 height of normal block an not jumpable
    if target_name == "default:snow" then
        print("    node is snow and not solid")
        jumpable = false

    else
        if core.registered_nodes[target_name].walkable then
            print("    node is solid")

            -- Check for non-solid nodes above the target node
            print("    target node ok. checking nodes above...")
            for i = 1, 3 do
                local check_pos = { x = target_pos.x, y = target_pos.y + i, z = target_pos.z }
                local above_node = mt_get_node(check_pos)
                local above_name = above_node.name
                print("      above_name: " .. above_name)
                if core.registered_nodes[above_name].walkable then
                    if above_name == "default:snow" then
                        print("      node not solid")
                    else
                        print("      node is solid")
                        jumpable = false
                    end
                end
            end

        else
            print("    node is not solid")
            jumpable = false
        end
    end

    print("  can_mob_jump_on() end")
    return jumpable
end


-- manages animation and movement speed of the mob
local function mob_state_passive(self)
    if not self then
        print("### core.after(): self object invalid. quitting. mobs.lua > mob_state_passive()")
        return
    end

    print("\n** mob_state_passive(" .. self.name .. ") **")
    local state = self.state
    print("  state: " .. state)

    local random_num
    if state == "idle" then
        print("  entity is idle")
        mob_idle(self)
        if can_mob_jump_on(self.object) then
            print("  node jumpable")
            random_num = math_random(1,2)
            if random_num == 1 then
                self.state = "jump"
                print("  next state: jump")
            else
                self.state = "turn"
                print("  next state: turn")
            end
        else
            print("  node not jumpable")
            random_num = math_random(1,3)
            if random_num == 1 then
                self.state = "idle"
                print("  next state: idle")
            elseif random_num == 2 then
                self.state = "turn"
                print("  next state: turn")
            else
                self.state = "walk"
                print("  next state: walk")
            end
        end
        self.state = "idle"
        self.job_main = mt_after(math.random(1,5), mob_state_passive, self)


    elseif state == "turn" then
        print("  entity is turning")
        mob_turn(self)
        if can_mob_jump_on(self.object) then
            print("  node jumpable")
            random_num = math_random(1,2)
            if random_num then
                self.state = "jump"
                print("  next state: jump")
            end
        else
            print("  node not jumpable")
            random_num = math_random(1,3)
            if random_num == 1 then
                self.state = "idle"
                print("  next state: idle")
            elseif random_num == 2 then
                self.state = "turn"
                print("  next state: turn")
            else
                self.state = "walk"
                print("  next state: walk")
            end
        end
        self.job_main = mt_after(1, mob_state_passive, self)


    elseif state == "jump" then
        print("  ** jumping **")
        mob_jump(self)
        random_num = math_random(1,3)
        if random_num == 1 then
            self.state = "idle"
            print("  next state: idle")
        elseif random_num == 2 then
            self.state = "turn"
            print("  next state: turn")
        else
            self.state = "walk"
            print("  next state: walk")
        end
        self.job_main = mt_after(2, mob_state_passive, self)


    elseif state == "walk" then
        print("  entity is walking")
        mob_walk(self)

        -- ensure that if mob is walking into a node and not moving,
        -- that the next action will always be to turn
        local start_pos = self.object:get_pos()
        self.job_main = mt_after(math_random(1,5), function()
            if not self then
                print("### core.after(): self object invalid. quitting. mobs.lua > mob_state_passive()")
                return
            end

            local end_pos = self.object:get_pos()
            if vector_equals(start_pos, end_pos) then
                print("  object has not moved. turning...")
                self.state = "turn"
                print("  next state: turn")
                mob_state_passive(self)
            else
                print("  object has moved")
                random_num = math_random(1,3)
                if random_num == 1 then
                    self.state = "idle"
                    print("  next state: idle")
                elseif random_num == 2 then
                    self.state = "walk"
                    print("  next state: walk")
                else
                    self.state = "run"
                    print("  next state: run")
                end
                mob_state_passive(self)
            end
        end)


    elseif state == "run" then
        print("  entity is running")
        mob_run(self)

        -- ensure that if mob is running into a node and not moving,
        -- that the next action will always be to turn
        local start_pos = self.object:get_pos()
        self.job_main = mt_after(math_random(1,5), function()
            if not self then
                print("### core.after(): self object invalid. quitting. mobs.lua > mob_state_passive()")
                return
            end
            local end_pos = self.object:get_pos()
            if vector_equals(start_pos, end_pos) then
                print("  object has not moved. turning...")
                self.state = "turn"
                print("  next state: turn")
                mob_state_passive(self)
            else
                print("  object has moved")
                random_num = math_random(1,2)
                if random_num == 1 then
                    self.state = "run"
                    print("  next state: run")
                else
                    self.state = "walk"
                    print("  next state: walk")
                end
                mob_state_passive(self)
            end
        end)

    else
        print("  Error: Unexpected 'state' value: " .. state)
    end

    print("** mob_state_passive() end **")
end


-- Function to add initial velocity to the item drops from mobs
local function add_velocity_to_item(item_drop)
    local velocity = {
        x = math_random(-0.2, 0.2),
        y = math_random(0.5, 2.0),
        z = math_random(-0.2, 0.2)
    }
    item_drop:set_velocity(velocity)
end

local entity_name_base = "ss:boar"
for mob_variation = 1, 3 do

    -- ###############
    -- ### DEAD BOAR 
    -- ###############
    local entity_name = entity_name_base .. mob_variation
    local mob_data = mob_def_extra[entity_name_base]

    core.register_entity(entity_name .. "_dead", {
        initial_properties = {
            hp_max = mob_data.hp_corpse,
            physical = true,
            collide_with_objects = false,
            collisionbox = { -0.3, -0.0, -0.3, 0.3, 0.5, 0.3},
            selectionbox = { -0.3, 0.1, -0.3, 0.3, 0.9, 0.3, rotate = true },
            visual = "mesh",
            mesh = "ss_animal_boar" .. mob_variation .. ".b3d",
            textures = {"ss_mobs_animals_forest.png"},
        },

        -- custom properties
        name_hud = "Dead " .. mob_data.name,
        experience = (mob_data.xp * 0.1),
        armor = mob_data.armor,
        drops = mob_data.drops,
        job_hud = {},

        on_activate = function(self, staticdata, dtime_s)
            --print("\n### on_activate() " .. self.name .. " ###")
            local data = mt_deserialize(staticdata)

            -- reload mob's prior hp
            if data then
                print("  data: " .. dump(data))
                local mob_hp = data.mob_hp
                if data.mob_hp then
                    self.object:set_hp(mob_hp)
                else print("  New mob corpse. HP set to hp_max") end
            else print("  ERROR: No staticdata available") end

            --print("### on_activate() end ###")
        end,

        -- custom function to show mob hudbar
        update_hud = function(self, player)
            update_mod_hud(self, player, "dead")
        end,

        on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            print("\n### on_punch() " .. self.name .. " ###")
            print("  time_from_last_punch: " .. time_from_last_punch)
            local player_name = puncher:get_player_name()
            local player_meta = puncher:get_meta()
            local p_data = player_data[player_name]
            local wielded_item_name = puncher:get_wielded_item():get_name()
            local stamina_current = player_meta:get_float("stamina_current")

            local cooldown_time, attack_group, attack_damage, weapon_weight
            if wielded_item_name == "" then
                print("  using hands")

                attack_group = "fists"
                cooldown_time = p_data.fists_cooldown_time
                attack_damage = p_data.fists_attack_damage
                weapon_weight = 2.00
            else
                print("  wielding an item")
                local ss_data = core.registered_items[wielded_item_name]._ss_data
                attack_group = ss_data.attack_group or "fists"
                cooldown_time = ss_data.attack_cooldown or 1.0
                attack_damage = ss_data.attack_damage or math_random()
                weapon_weight = ss_data.weight or 2.00
            end
            print("  weapon_weight: " .. weapon_weight)

            local weapon_stamina_loss = weapon_weight * 2
            print("  weapon_stamina_loss: " .. weapon_stamina_loss)
            local update_data = {"normal", "stamina", -weapon_stamina_loss, 1, 1, "curr", "add", true}
            update_stat(puncher, p_data, player_meta, update_data)

            local cooldown_modifier = player_meta:get_float("cooldown_mod_" .. attack_group)
            local attack_cooldown_time = cooldown_time + cooldown_modifier
            print("  attack_cooldown_time: " .. attack_cooldown_time)

            local mob_name = self.name

            -- force a miss when stamina is not enough to swing the weapon
            if stamina_current < weapon_stamina_loss then
                notify(puncher, "Stamina too low", 1, 0, 0.5, 3)
                print("  ** MISSED **")
                -- 'intensity' param is set below 0.75 to have reduced gain and pitch
                --play_mob_sound(mob_name, "miss", attack_group, 0.5)
                play_sound("hit_mob", {
                    player = puncher,
                    hit_type = "miss",
                    attack_group = attack_group,
                    intensity = 0.5
                })
                return
            end

            local hit_intensity = time_from_last_punch / attack_cooldown_time
            if hit_intensity > 1.0 then
                print("  full attack strength")
                hit_intensity = 1.0

            elseif hit_intensity < 0.5 then
                print("  less than half attack strength")
                local random_num = math_random(1,3)
                if random_num > 1 then
                    print("  ** MISSED **")
                    --play_mob_sound(mob_name, "miss", wielded_item_name, hit_intensity)
                    play_sound("hit_mob", {
                        player = puncher,
                        hit_type = "miss",
                        attack_group = wielded_item_name,
                        intensity = hit_intensity
                    })
                    return
                end

            end
            print("  hit_intensity: " .. hit_intensity)

            --play_mob_sound(mob_name, "harvest", attack_group, hit_intensity)
            play_sound("hit_mob", {
                player = puncher,
                hit_type = "harvest",
                attack_group = attack_group,
                intensity = hit_intensity
            })

            if self.job_hud[player_name] then
                print("  hud job exists")
                self.job_hud[player_name]:cancel()
                print("  stopped job")
                self.job_hud[player_name] = nil
            else
                print("  no existing hud jobs")
            end

            local weapon_attack_strength = attack_damage
            print("  weapon_attack_strength: " .. weapon_attack_strength)

            local entity_defense_factor = self.armor[attack_group]
            print("  entity_defense_factor: " .. entity_defense_factor)

            local damage_inflicted = weapon_attack_strength * entity_defense_factor
            print("  damage_inflicted (initial): " .. damage_inflicted)

            damage_inflicted = damage_inflicted * hit_intensity
            print("  damage_inflicted (w/ intensity): " .. damage_inflicted)

            damage_inflicted = math.round(damage_inflicted)
            print("  damage_inflicted (rounded): " .. damage_inflicted)

            -- get mob's position and facing direction
            local mob = self.object
            local pos = mob:get_pos()
            local hp = mob:get_hp()
            local new_hp = hp - damage_inflicted
            mob:set_hp(new_hp)

            if new_hp <= 0 then
                print("  corpse fully harvested")
                local update_data = {"normal", "experience", self.experience, 1, 1, "curr", "add", true}
                update_stat(puncher, p_data, player_meta, update_data)
                hide_mob_hud(puncher)
                self.job_hud[player_name] = nil

                print("  Spawning items at the entity's position.")
                pos.y = pos.y + 0.5
                local item_drop
                for _, drop_data in ipairs(self.drops) do
                    local random_num = math.random(100)
                    if random_num <= drop_data.prob then
                        item_drop = mt_add_item(pos, drop_data.name .. " " .. drop_data.quant)
                        if item_drop then add_velocity_to_item(item_drop) end
                    end
                end

            else
                print("  new_hp: " .. new_hp)

                -- display mob hudbar and schedule job to handle removal
                self:update_hud(puncher)
                self.job_hud[player_name] = mt_after(show_hudbar_duration, function()
                    print("\n### hiding " .. mob_name .. " hud from player: " .. player_name .. " ###")
                    if not puncher or puncher:get_player_name() == "" then
                        print("  player no longer exists. function skipped.")
                        return
                    end
                    hide_mob_hud(puncher)
                    self.job_hud[player_name] = nil
                    print("### done hiding end ###")
                end)
            end

            print("### on_punch() end ###")
        end,

        on_deactivate = function(self, removal)
            --print("\non deactivate() " .. self.name)
            --print("on deactivate() end\n")
        end,

        get_staticdata = function(self)
            print("\nget_staticdata() " .. self.name)
            local static_data = {
                mob_hp = self.object:get_hp()
            }
            print("  saved static_data: " .. dump(static_data))
            print("get_staticdata() end")
            return mt_serialize(static_data)
        end,

    })


    -- ##########
    -- ### BOAR 
    -- ##########
    core.register_entity(entity_name, {
        initial_properties = {
            hp_max = mob_data.hp,
            physical = true,
            collisionbox = {-0.3, -0.0, -0.3, 0.3, 0.5, 0.3},
            visual = "mesh",
            mesh = "ss_animal_boar" .. mob_variation .. ".b3d",
            textures = {"ss_mobs_animals_forest.png"},
        },

        -- custom properties
        name_hud = mob_data.name,
        name_dead = entity_name .. "_dead",
        state = "idle",
        experience = mob_data.xp,
        armor = mob_data.armor,
        job_nametag = nil,
        job_hud = {},
        anim = {
            speed_24 = 24, speed_48 = 55,
            idle_start = 0, idle_end = 121,
            walk_start = 131, walk_end = 160,
            run_start = 171, run_end = 205,
        },

        -- job_main = stores core.after() job handle for mob_state_passive() loop
        -- job_nametag = stores core.after() job handle for hiding mob nametag

        on_activate = function(self, staticdata, dtime_s)
            --print("\n### on_activate() " .. self.name .. " ###")
            local data = mt_deserialize(staticdata)

            -- reload mob's prior hp
            if data then
                print("  data: " .. dump(data))
                self.object:set_hp(data.mob_hp)
            end

            -- ensure mob reacts to gravity
            self.object:set_acceleration({x=0, y=-9.8, z=0})

            -- start 'passive' AI behavior
            mob_state_passive(self)

            --print("### on_activate() end ###")
        end,

        -- custom function to show inflicted damage above mob
        update_nametag = function(self, player, damage_inflicted)
            if damage_inflicted > 0 then
                damage_inflicted = "-" .. damage_inflicted
            end
            self.object:set_nametag_attributes({
                text = damage_inflicted,
                color = {a = 255, r = 255, g = 0, b = 0},
                bgcolor = {a = 0, r = 0, g = 0, b = 0}
            })
        end,

        -- custom function to show mob hudbar
        update_hud = function(self, player)
            update_mod_hud(self, player, "alive")
        end,

        on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
            print("\n### on_punch() " .. self.name .. " ###")
            print("  time_from_last_punch: " .. time_from_last_punch)
            local player_name = puncher:get_player_name()
            local player_meta = puncher:get_meta()
            local p_data = player_data[player_name]
            local wielded_item_name = puncher:get_wielded_item():get_name()
            local stamina_current = player_meta:get_float("stamina_current")
            print("  stamina_current: " .. stamina_current)

            local cooldown_time, attack_group, attack_damage, weapon_weight
            if wielded_item_name == "" then
                print("  using hands")
                attack_group = "fists"
                cooldown_time = p_data.fists_cooldown_time
                attack_damage = p_data.fists_attack_damage
                weapon_weight = 2.00
            else
                print("  wielding an item")
                local ss_data = core.registered_items[wielded_item_name]._ss_data
                attack_group = ss_data.attack_group or "fists"
                cooldown_time = ss_data.attack_cooldown or 1.0
                attack_damage = ss_data.attack_damage or math_random()
                weapon_weight = ss_data.weight or 2.00
            end
            print("  weapon_weight: " .. weapon_weight)

            local weapon_stamina_loss = weapon_weight * 2
            print("  weapon_stamina_loss: " .. weapon_stamina_loss)
            local update_data = {"normal", "stamina", -weapon_stamina_loss, 1, 1, "curr", "add", true}
            update_stat(puncher, p_data, player_meta, update_data)

            local cooldown_modifier = player_meta:get_float("cooldown_mod_" .. attack_group)
            local attack_cooldown_time = cooldown_time + cooldown_modifier
            print("  attack_cooldown_time: " .. attack_cooldown_time)

            local mob_name = self.name

            -- force a miss when stamina is not enough to swing the weapon
            if stamina_current < weapon_stamina_loss then
                notify(puncher, "Stamina too low", 1, 0, 0.5, 3)
                print("  ** MISSED **")
                -- 'intensity' param is set below 0.75 to have reduced gain and pitch
                --play_mob_sound(mob_name, "miss", attack_group, 0.5)
                play_sound("hit_mob", {
                    player = puncher,
                    hit_type = "miss",
                    attack_group = attack_group,
                    intensity = 0.5
                })
                return
            end

            local hit_intensity = time_from_last_punch / attack_cooldown_time
            if hit_intensity > 1.0 then
                print("  full attack strength")
                hit_intensity = 1.0

            elseif hit_intensity < 0.5 then
                print("  less than half attack strength")
                local random_num = math_random(1,3)
                if random_num > 1 then
                    print("  ** MISSED **")
                    play_sound("hit_mob", {
                        player = puncher,
                        hit_type = "miss",
                        attack_group = attack_group,
                        intensity = hit_intensity
                    })
                    return
                end

            end
            print("  hit_intensity: " .. hit_intensity)

            play_sound("hit_mob", {
                player = puncher,
                hit_type = "hit",
                attack_group = attack_group,
                intensity = hit_intensity
            })

            if self.job_nametag then
                print("  nametag job exists")
                self.job_nametag:cancel()
                print("  stopped job")
                self.job_nametag = nil
            else
                print("  no existing nametag jobs")
            end

            if self.job_hud[player_name] then
                print("  hud job exists for " .. player_name)
                self.job_hud[player_name]:cancel()
                print("  stopped job hud")
                self.job_hud[player_name] = nil
            else
                print("  no existing hud jobs")
            end

            local weapon_attack_strength = attack_damage
            local entity_defense_factor = self.armor[attack_group]
            local damage_inflicted = weapon_attack_strength * entity_defense_factor
            print("  weapon_attack_strength: " .. weapon_attack_strength)
            print("  entity_defense_factor: " .. entity_defense_factor)
            print("  damage_inflicted (initial): " .. damage_inflicted)

            damage_inflicted = math.round(damage_inflicted * hit_intensity)
            print("  damage_inflicted (rounded and w/ hit_intensity): " .. damage_inflicted)

            -- get mob's position and facing direction
            local mob = self.object
            local mob_pos = mob:get_pos()
            local mob_yaw = mob:get_yaw()

            -- reduce mod's hp
            local hp = mob:get_hp()
            local new_hp = hp - damage_inflicted
            mob:set_hp(new_hp)

            if new_hp <= 0 then
                print("  mob is dead")

                update_data = {"normal", "experience", self.experience, 1, 1, "curr", "add", true}
                update_stat(puncher, p_data, player_meta, update_data)
                hide_mob_hud(puncher)
                self.job_hud[player_name] = nil

                -- spawn dead version of the mob. the facing direction 'yaw' of the once
                -- alive entity is passed to the dead mob via staticdata property.
                local dead_mob = mt_add_entity(mob_pos, self.name_dead, mt_serialize({yaw = mob_yaw}))

                -- ensure dead mob reacts to gravity
                dead_mob:set_acceleration({x=0, y=-9.8, z=0})

                -- make dead mob face same direction but lying on its side
                dead_mob:set_yaw(mob_yaw)
                dead_mob:set_pos({ x = mob_pos.x, y = mob_pos.y + 0.2, z = mob_pos.z })
                if math_random(1,2) == 1 then
                    dead_mob:set_rotation({x = 0, y = mob_yaw, z = math.pi / 2})
                else
                    dead_mob:set_rotation({x = 0, y = mob_yaw, z = -math.pi / 2})
                end

                -- ensure dead mob reacts to gravity
                dead_mob:set_acceleration({x=0, y=-9.8, z=0})

            else
                print("  new_hp: " .. new_hp)

                -- display nametage and schedule job to handle removal
                self:update_nametag(puncher, damage_inflicted)
                self.job_nametag = mt_after(show_damage_duration, function()
                    if not self then
                        print("### core.after(): self object invalid. quitting. mobs.lua > on_punch()")
                        return
                    end
                    print("\n### hiding nametag for " .. mob_name .. " ###")
                    mob:set_nametag_attributes({text = ""})
                    self.job_nametag = nil
                    print("### done hiding end ###")
                end)

                -- display mob hudbar and schedule job to handle removal
                self:update_hud(puncher)
                self.job_hud[player_name] = mt_after(show_hudbar_duration, function()
                    if not self then
                        print("### core.after(): self object invalid. quitting. mobs.lua > on_punch()")
                        return
                    end
                    print("\n### hiding " .. mob_name .. " hud from player: " .. player_name .. " ###")
                    hide_mob_hud(puncher)
                    self.job_hud[player_name] = nil
                    print("### done hiding end ###")
                end)

            end

            print("### on_punch() end ###")
        end,

        on_rightclick = function(self, clicker)
            print("> you right-cliced on " .. self.name)
            if self.job_nametag then
                print("  nametag job exists")
                self.job_nametag:cancel()
            else
                print("  no existing nametag jobs")
            end
        end,

        on_deactivate = function(self, removal)
            print("\non deactivate() " .. self.name)
            if self.job_main then
                self.job_main:cancel()
                print("  main job stopped")
            else
                print("  no main jobs to stop")
            end

            if self.job_nametag then
                self.job_nametag:cancel()
                print("  existing nametag job stopped")
            else
                print("  no existing nametag jobs to stop")
            end

            print("on deactivate() end\n")
        end,

        get_staticdata = function(self)
            print("\nget_staticdata() " .. self.name)
            local static_data = {
                mob_hp = self.object:get_hp()
            }
            print("  saved static_data: " .. dump(static_data))
            print("get_staticdata() end")
            return mt_serialize(static_data)
        end,
    })

end




-- ##############
-- ### BLOCKY MOB 
-- ##############
core.register_entity("ss:blocky_mob", {
    initial_properties = {
        hp_max = 100,
        physical = true,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
        visual = "mesh",
        mesh = "blocky_mob2.b3d",
        textures = {"blocky_mob.png"},
    },

    -- custom properties
    hp_corpse = 100,
    name_hud = "blocky mob",
    state = "idle",
    experience = 100,
    armor = {fists = 1.0, blunt = 1.0, blade = 1.0, spear = 1.0, mining = 1.0},
    job_nametag = nil,
    job_hud = {},
    anim = {
        idle_start = 0,
        idle_end = 10,

        -- walk and run starts at 1 frame prior to actual start frame in Blender
        walk_start = 14, walk_end = 22,
        run_start = 29, run_end = 37,

        -- all death frames start 3 frames prior to actual start frame in blender, and
        -- end 1 frame prior to actual end from in blender.
        death_start_l = 42, death_end_l = 47,
        death_start_r = 52, death_end_r = 57,
        death_start_b = 62, death_end_b = 67,
        death_start_f = 72, death_end_f = 77,
    },

    -- job_main = stores core.after() job handle for mob_state_passive() loop
    -- job_nametag = stores core.after() job handle for hiding mob nametag

    on_activate = function(self, staticdata, dtime_s)
        --print("\n### on_activate() " .. self.name .. " ###")
        local data = mt_deserialize(staticdata)

        -- reload mob's prior hp
        if data then
            print("  data: " .. dump(data))
            self.object:set_hp(data.mob_hp)
        end

        -- ensure mob reacts to gravity
        self.object:set_acceleration({x=0, y=-9.8, z=0})

        -- start 'idle' animation
        if math_random(1,2) == 1 then
            self.object:set_animation({x=self.anim.run_start, y=self.anim.run_end}, 10, 0, true)
        else
            self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, 10, 0, true)
        end
        self.object:set_velocity({ x = 0, y = 0, z = 0 })

        --print("### on_activate() end ###")
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        print("\n### on_punch() " .. self.name .. " ###")

        print("### on_punch() end ###")
    end,

    on_rightclick = function(self, clicker)
        print("> you right-cliced on " .. self.name)
        if self.job_nametag then
            print("  nametag job exists")
            self.job_nametag:cancel()
        else
            print("  no existing nametag jobs")
        end
    end,

    on_deactivate = function(self, removal)
        print("\non deactivate() " .. self.name)

        print("on deactivate() end\n")
    end,

    get_staticdata = function(self)
        print("\nget_staticdata() " .. self.name)
        local static_data = {
            mob_hp = self.object:get_hp()
        }
        print("  saved static_data: " .. dump(static_data))
        print("get_staticdata() end")
        return mt_serialize(static_data)
    end,
})



-- ##############
-- ### ZOMBIE V1 
-- ##############
core.register_entity("ss:zombie", {
    initial_properties = {
        hp_max = 100,
        physical = true,
        collisionbox = {-0.5, -0.5, -0.5, 0.5, 1.5, 0.5},
        visual = "mesh",
        mesh = "zombie.b3d",
        textures = {"zombie.png"},
    },

    -- custom properties
    hp_corpse = 100,
    name_hud = "zombie",
    state = "idle",
    experience = 100,
    armor = {fists = 1.0, blunt = 1.0, blade = 1.0, spear = 1.0, mining = 1.0},
    job_nametag = nil,
    job_hud = {},
    anim = {
        -- idle ends 1 frame prior to actual end frame in blender
        idle_start = 0, idle_end = 59,

        -- walk and run starts at 1 frame prior to actual start frame in Blender
        walk_start = 69, walk_end = 81,
        run_start = 104, run_end = 116,

        -- all death frames start 3 frames prior to actual start frame in blender, and
        -- end 1 frame prior to actual end from in blender.
        death_start_l = 42, death_end_l = 47,
        death_start_r = 52, death_end_r = 57,
        death_start_b = 62, death_end_b = 67,
        death_start_f = 72, death_end_f = 77,
    },

    -- job_main = stores core.after() job handle for mob_state_passive() loop
    -- job_nametag = stores core.after() job handle for hiding mob nametag

    on_activate = function(self, staticdata, dtime_s)
        --print("\n### on_activate() " .. self.name .. " ###")
        local data = mt_deserialize(staticdata)

        -- reload mob's prior hp
        if data then
            print("  data: " .. dump(data))
            self.object:set_hp(data.mob_hp)
        end

        -- ensure mob reacts to gravity
        self.object:set_acceleration({x=0, y=-9.8, z=0})

        -- start 'idle' animation
        local random_num = math_random(1,3)
        if random_num == 1 then
            self.object:set_animation({x=self.anim.idle_start, y=self.anim.idle_end}, 10, 0, true)
        elseif random_num == 2 then
            self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, 10, 0, true)
        else
            self.object:set_animation({x=self.anim.run_start, y=self.anim.run_end}, 20, 0, true)
        end
        self.object:set_velocity({ x = 0, y = 0, z = 0 })

        --print("### on_activate() end ###")
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        print("\n### on_punch() " .. self.name .. " ###")

        print("### on_punch() end ###")
    end,

    on_rightclick = function(self, clicker)
        print("> you right-cliced on " .. self.name)
        if self.job_nametag then
            print("  nametag job exists")
            self.job_nametag:cancel()
        else
            print("  no existing nametag jobs")
        end
    end,

    on_deactivate = function(self, removal)
        print("\non deactivate() " .. self.name)

        print("on deactivate() end\n")
    end,

    get_staticdata = function(self)
        print("\nget_staticdata() " .. self.name)
        local static_data = {
            mob_hp = self.object:get_hp()
        }
        print("  saved static_data: " .. dump(static_data))
        print("get_staticdata() end")
        return mt_serialize(static_data)
    end,
})


-- ##############
-- ### PLAYER V1 
-- ##############
core.register_entity("ss:player", {
    initial_properties = {
        hp_max = 100,
        physical = true,
        collisionbox = {-0.35, -0.5, -0.35, 0.35, 1.25, 0.35},
        visual = "mesh",
        mesh = "player.b3d",
        textures = {"player.png"},
    },

    -- custom properties
    hp_corpse = 100,
    name_hud = "player",
    state = "idle",
    experience = 100,
    armor = {fists = 1.0, blunt = 1.0, blade = 1.0, spear = 1.0, mining = 1.0},
    job_nametag = nil,
    job_hud = {},
    anim = {
        -- animation ends 1 frame prior to actual end frame in blockbench/blender
        idle_start = 10, idle_end = 89,

        -- animation starts 1 frame prior to actual start frame in blockbench/blender
        walk_start = 99, walk_end = 115,
        run_start = 129, run_end = 145,
        mine_start = 159, mine_end = 166,

        -- animation starts and ends 1 frame prior to what is defined in blockbench/blender
        walk_mine_start = 179, walk_mine_end = 195,

        -- animation ends 1 frame prior to actual end frame in blockbench/blender
        lay_start = 210, lay_end = 211,
        sit_start = 220, sit_end = 221,
    },

    on_activate = function(self, staticdata, dtime_s)
        --print("\n### on_activate() " .. self.name .. " ###")
        local data = mt_deserialize(staticdata)

        -- reload mob's prior hp
        if data then
            print("  data: " .. dump(data))
            self.object:set_hp(data.mob_hp)
        end

        -- ensure mob reacts to gravity
        self.object:set_acceleration({x=0, y=-9.8, z=0})

        local random_num = math_random(1,4)
        if random_num == 1 then
            self.object:set_animation({x=self.anim.mine_start, y=self.anim.mine_end}, 20, 0, true)
        elseif random_num == 2 then
            self.object:set_animation({x=self.anim.walk_mine_start, y=self.anim.walk_mine_end}, 15, 0, true)
        elseif random_num == 3 then
            self.object:set_animation({x=self.anim.walk_start, y=self.anim.walk_end}, 15, 0, true)
        else
            self.object:set_animation({x=self.anim.run_start, y=self.anim.run_end}, 25, 0, true)
        end
        self.object:set_velocity({ x = 0, y = 0, z = 0 })
        --print("### on_activate() end ###")
    end,

    on_punch = function(self, puncher, time_from_last_punch, tool_capabilities, dir, damage)
        print("\n### on_punch() " .. self.name .. " ###")

        print("### on_punch() end ###")
    end,

    on_deactivate = function(self, removal)
        print("\non deactivate() " .. self.name)

        print("on deactivate() end\n")
    end,

    get_staticdata = function(self)
        print("\nget_staticdata() " .. self.name)
        local static_data = {
            mob_hp = self.object:get_hp()
        }
        print("  saved static_data: " .. dump(static_data))
        print("get_staticdata() end")
        return mt_serialize(static_data)
    end,
})


core.register_entity("ss:test", {
    -- Basic entity properties
    hp_max = 10,
    physical = true,
    collide_with_objects = true,
    collisionbox = {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25},
    visual = "mesh",
    visual_size = {x = 1, y = 1},
    mesh = "model.b3d",
    textures = {"model.png"},

    on_activate = function(self, staticdata, dtime_s)
        self.object:set_acceleration({x=0, y=-9.8, z=0})
    end,

})



local flag15 = false
core.register_on_joinplayer(function(player)
    debug(flag15, "\nregister_on_joinplayer() mobs.lua")
    local player_name = player:get_player_name()

    debug(flag15, "initializing mob huds...")
    -- initialize hud display for the mob hp hudbar. the visual scale is initially set
    -- to zero to hide it from display. when the mob is hit, the visual scale will change
    -- to real values and the hud show on screen for a short time.

    -- text for mob name
    player_hud_ids[player_name].mob_hud_name = player:hud_add({
        type = "text",
        position = {x = 0.5, y = 0.0},
        offset = {x = 0, y = 102},
        text = "",
        size = {x = 1.0, y = 2.0},
        number = "0xFFFFFF",
        alignment = {x = 0, y = -1},
        scale = {x = 100, y = 100},
        style = 1
    })

    -- black bg for mob hp statbar
    player_hud_ids[player_name].mob_hud_bg = player:hud_add({
        type = "image",
        position = {x = 0.5, y = 0.0},
        offset = {x = -150, y = 120},
        text = "[fill:1x1:0,0:#000000",
        scale = {x = 0, y = 0},
        alignment = {x = 1, y = -1}
    })

    -- red hp statbar for mob
    player_hud_ids[player_name].mob_hud =  player:hud_add({
        type = "image",
        position = {x = 0.5, y = 0.0},
        offset = {x = -150, y = 120},
        text = "[fill:1x1:0,0:#c00000",
        scale = {x = 0, y = 0},
        alignment = {x = 1, y = -1}
    })

    debug(flag15, "register_on_joinplayer() end " .. core.get_gametime())
>>>>>>> 7965987 (update to version 0.0.3)
end)