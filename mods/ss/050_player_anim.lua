print("- loading player_anim.lua")

-- cache global functions for faster access
local math_abs = math.abs
local math_random = math.random
local string_sub = string.sub
local vector_add = vector.add
local vector_distance = vector.distance
local vector_multiply = vector.multiply
local vector_round = vector.round
local mt_pos_to_string = core.pos_to_string
local mt_get_node_or_nil = core.get_node_or_nil
local mt_get_node = core.get_node
local mt_add_item = core.add_item
local mt_after = core.after
local debug = ss.debug
local notify = ss.notify
local after_player_check = ss.after_player_check
local play_sound = ss.play_sound
local get_itemstack_weight = ss.get_itemstack_weight
local get_wield_weight = ss.get_wield_weight
local do_stat_update_action = ss.do_stat_update_action
local update_fs_weight = ss.update_fs_weight
local update_player_physics = ss.update_player_physics


-- cache global variables for faster access
local NODE_NAMES_SOLID_CUBE = ss.NODE_NAMES_SOLID_CUBE
local NODE_NAMES_SOLID_ALL = ss.NODE_NAMES_SOLID_ALL
local NODE_NAMES_NONSOLID_ALL = ss.NODE_NAMES_NONSOLID_ALL
local NODE_NAMES_WATER = ss.NODE_NAMES_WATER
local NODE_LEGS_DRAIN_MOD = ss.NODE_LEGS_DRAIN_MOD
local player_data = ss.player_data
local job_handles = ss.job_handles




-- items that player cannot wield while crouch sitting
local NON_SITTABLE_ITEMS = {
	["ss:stone_sharpened"] = true,
	["default:torch"] = true,
	["default:axe_stone"] = true,
	["default:sword_stone"] = true,
	["default:pick_stone"] = true,
	["default:shovel_stone"] = true,
	["default:dirt"] = true
}


--[[ 
control inputs: LMB, dig, RMB, place, aux1, up, down, left, right, jump, sneak, zoom, (none)
core states: mine, walk, run, jump, crouch, stand, zoom

mine
run_mine run_jump run
walk_mine walk_jump walk				
jump_mine jump
crouch_walk crouch_mine crouch_walk_mine crouch_run_mine crouch_run crouch_jump crouch_jump_mine crouch				
stand
death
--]]

--$animation
--############################
--############################

-- animation names and ranges for all player models
local anims = {
	stand					= {x = 2, y = 2},
	sit_chair				= {x = 5, y = 5},
	sit_floor				= {x = 8, y = 8},
	sit_cave				= {x = 11, y = 11},
	lay_bed					= {x = 14, y = 14},
	lay_floor				= {x = 17, y = 17},
	death_front				= {x = 20, y = 20},
	death_back				= {x = 23, y = 23},
	walk					= {x = 30, y = 49},
	jump					= {x = 30, y = 49},
	walk_jump				= {x = 30, y = 49},
	mine					= {x = 60, y = 69},
	walk_mine				= {x = 80, y = 99},
	walk_jump_mine			= {x = 80, y = 99},
	jump_mine				= {x = 80, y = 99},
	run						= {x = 110, y = 129},
	run_jump				= {x = 110, y = 129},
	run_mine				= {x = 250, y = 289},
	run_jump_mine			= {x = 250, y = 289},
	crouch					= {x = 170, y = 170},
	crouch_jump				= {x = 170, y = 170},
	crouch_mine				= {x = 180, y = 185},
	crouch_jump_mine		= {x = 180, y = 189},
	crouch_walk				= {x = 200, y = 211},
	crouch_walk_jump		= {x = 200, y = 211},
	crouch_walk_jump_mine	= {x = 200, y = 211},
	crouch_run				= {x = 200, y = 211},
	crouch_run_jump			= {x = 200, y = 211},
	crouch_walk_mine		= {x = 220, y = 231},
	crouch_run_mine			= {x = 220, y = 231},
	crouch_run_jump_mine	= {x = 220, y = 231}
}

-- animation speeds for each animation
local anim_speed = {
	stand       			= 5,
	sit_chair				= 5,
	sit_floor				= 5,
	sit_cave				= 5,
	lay_bed					= 5,
	lay_floor				= 5,
	death_front				= 5,
	death_back				= 5,
	walk        			= 30,
	jump        			= 30,
	walk_jump        		= 30,
	mine        			= 30,
	walk_mine   			= 30,
	walk_jump_mine 			= 30,
	jump_mine      			= 30,
	run      				= 40,
	run_jump    			= 40,
	run_mine   				= 40,
	run_jump_mine			= 40,
	crouch      			= 5,
	crouch_jump    			= 5,
	crouch_mine				= 10,
	crouch_jump_mine		= 5,
	crouch_walk 			= 10,
	crouch_walk_jump		= 10,
	crouch_walk_jump_mine	= 10,
	crouch_run 				= 15,
	crouch_run_jump			= 15,
	crouch_walk_mine		= 10,
	crouch_run_mine			= 15,
	crouch_run_jump_mine	= 15
}


-- custom collisionbox and eye height for all standing related animations
local collisionbox_stand = {-0.3, 0.0, -0.3, 0.3, 1.75, 0.3}
local eye_height_stand = 1.65

-- custom collisionbox and eye height for all crouching related animations
local collisionbox_crouch = {-0.3, 0.0, -0.3, 0.3, 0.9, 0.3}
local eye_height_crouch = 0.85

-- custom collisionbox and eye height for the crouch sitting 'cave_sit' animations
local collisionbox_sit_cave = {-0.3, 0.0, -0.3, 0.3, 0.9, 0.3}
local eye_height_sit_cave = 0.65

-- custom collisionbox and eye height for all laying related animations
local collisionbox_lay = {-0.3, 0.0, -0.3, 0.3, 0.5, 0.3}
local eye_height_lay = 0.4



local flag2 = false
--- @param player ObjectRef the player object
--- @return boolean is_solid_node whether or not the node directly above the
-- player's head (while crouching) is a solid/walkable node. this is determined by
-- checking node positions at NE, SE, SW, and NW from player's standing eye height.
-- this function is regularly called to ensure 'automatic' crouching behavior.
local function overhead_node_solid(player)
	debug(flag2, "  overhead_node_solid()")
    local pos = player:get_pos()
	local buffer = 0.2
	local pos_y = pos.y + 1.85
	local overhead_positions = {
		{x = pos.x + buffer, y = pos_y, z = pos.z + buffer},  -- NE +Z+X
		{x = pos.x + buffer, y = pos_y, z = pos.z - buffer},  -- SE -N+X
		{x = pos.x - buffer, y = pos_y, z = pos.z - buffer},  -- SW -Z-X
		{x = pos.x - buffer, y = pos_y, z = pos.z + buffer},  -- NW +Z-X
	}
	for _, overhead_pos in ipairs(overhead_positions) do
		local node = mt_get_node_or_nil(overhead_pos)
		if node then
			--debug(flag2, "  overhead_node_solid() END")
			if NODE_NAMES_SOLID_CUBE[node.name] then
				--debug(flag2, "  ** node is solid **")
				return true
			end
		end
	end
	--debug(flag2, "  node not solid")
	debug(flag2, "  overhead_node_solid() END")
	return false
end


local flag8 = false
--- @param player ObjectRef the player object
-- Removes the item currently wielded by the player and places it into an empty slot in
-- the hotbar or inventory, or on the ground if now empty slots.
local function unequip_wield_item(player)
	debug(flag8, "  unequip_wield_item()")
    local wielded_item = player:get_wielded_item()

    if wielded_item:is_empty() then
		--debug(flag8, "    ** player not wielding any item to drop **")

	else

		if NON_SITTABLE_ITEMS[wielded_item:get_name()] then
			--debug(flag8, "    ** wield item must be un-equipped **")
			notify(player, "inventory", "Cannot wield this while sitting", 3, 0, 0.5, 3)
		else
			--debug(flag8, "    ** wield item allowed while sitting **")
			return
		end

		local pos = player:get_pos()
    	local inv = player:get_inventory()
		local wield_index = player:get_wield_index()
		local player_name = player:get_player_name()
		local p_data = player_data[player_name]
		local moved = false

        -- Put wielded item into the hotbar or inventory
        for i, stack in ipairs(inv:get_list("main")) do
            if i ~= wield_index and stack:is_empty() then
                inv:set_stack("main", i, wielded_item)
                inv:set_stack("main", wield_index, ItemStack(nil))
				p_data.wield_item_index = i
                moved = true

				--debug(flag8, "    ** moved item to inventory slot : " .. i .. " **")
                break
            end
        end

        -- If no available slot is found, drop the item at the player's position
        if not moved then
			--debug(flag8, "    ** no inv space. dropping item to ground **")

			-- deduct the item's weight from inventory total weight
			local player_meta = player:get_meta()
			local weight = get_itemstack_weight(wielded_item)
			do_stat_update_action(player, p_data, player_meta, "normal", "weight", -weight, "curr", "add", true)
			update_fs_weight(player, player_meta)

			-- drop wielded item to the ground
            pos.y = pos.y + 0.7
            mt_add_item(pos, wielded_item)
            inv:set_stack("main", wield_index, ItemStack(nil))
			notify(player, "inventory", "Item dropped to the ground", 3, 0.5, 0, 2)
        end

    end
	debug(flag8, "  unequip_wield_item() end")
end


--- @param player ObjectRef the player object
--- @param wield_item_index number the index/slot number of the item that was previously
-- 'unequipped' or removed. This function attempts to re-equip the same item that was
-- unequipped during crouch sitting.
local function equip_wield_item(player, wield_item_index)
    local inv = player:get_inventory()

    -- Check if there's an item in the specified slot
    local item_to_wield = inv:get_stack("main", wield_item_index)
    if item_to_wield:is_empty() then
        -- No item to wield, do nothing
        return
    end

    -- Get the current wielded item
    local wielded_item = player:get_wielded_item()

    -- Check if the wielded slot is empty
    if wielded_item:is_empty() then
        -- Move the item to the wielded slot
        inv:set_stack("main", player:get_wield_index(), item_to_wield)
        inv:set_stack("main", wield_item_index, ItemStack(nil))
    else
        -- Wielded slot is not empty, swap the items
        inv:set_stack("main", player:get_wield_index(), item_to_wield)
        inv:set_stack("main", wield_item_index, wielded_item)
    end
end


-- player model body types with variations in gender and hair styles
BODY_TYPES = { "ss_player_model_1.b3d", "ss_player_model_2.b3d"	}


local search_positions = {
	UP = {x = 0, y = 1, z = 0},
	N = {x = 0, y = 0, z = 1},
	NE = {x = 1, y = 0, z = 1},
	E = {x = 1, y = 0, z = 0},
	SE = {x = 1, y = 0, z = -1},
	S = {x = 0, y = 0, z = -1},
	SW = {x = -1, y = 0, z = -1},
	W = {x = -1, y = 0, z = 0},
	NW = {x = -1, y = 0, z = 1},
}

local flag6 = false
local function get_valid_player_spawn_pos(pos)
	debug(flag6, "\n  get_valid_player_spawn_pos()")
	debug(flag6, "    pos: " .. mt_pos_to_string(pos))

	local valid_pos

	-- check original pos first
	local node = mt_get_node(pos)
	local node_name = node.name
	debug(flag6, "    node_name: " .. node_name)

	if NODE_NAMES_SOLID_ALL[node_name] then
		debug(flag6, "    player's lower half is buried in a solid node")
		local pos_upper = {x = pos.x, y = pos.y + 1, z = pos.z}
		--debug(flag6, "    pos_upper: " .. mt_pos_to_string(pos_upper))
		local upper_node = mt_get_node(pos_upper)
		local upper_node_name = upper_node.name
		--debug(flag6, "    upper_node_name: " .. upper_node_name)

		if NODE_NAMES_SOLID_ALL[upper_node_name] then
			--debug(flag6, "    player is completely buried in solid nodes")

		elseif NODE_NAMES_NONSOLID_ALL[upper_node_name] then
			--debug(flag6, "    player's upper half is in air or a non-solid node")

			-- spawn player at this upper_node pos (while crouched)
			valid_pos = {x = pos_upper.x, y = pos_upper.y, z = pos_upper.z}
			--debug(flag6, "    *** pos above origin pos is valid ***")

		else
			--debug(flag6, "    ERROR - node is not recognized in any global 'NODE_NAMES' table: " .. upper_node_name)
		end

	elseif NODE_NAMES_NONSOLID_ALL[node_name] then
		--debug(flag6, "    player's lower half is in a air or non-solid node")
		--debug(flag6, "    *** original pos is valid ***")
		valid_pos = pos

	else
		debug(flag6, "    ERROR - node is not recognized in any global 'NODE_NAMES' table: " .. node_name)
	end

	if not valid_pos then

		--debug(flag6, "    origin pos not valid. checking adjacent locations..")
		-- check all other adjacent positions
		for direction, adj_vector in pairs(search_positions) do
			--debug(flag6, "    direction: " .. direction)

			local adj_pos = vector.add(pos, adj_vector)
			--debug(flag6, "      adj_pos: " .. mt_pos_to_string(adj_pos))
			local adj_pos_node = mt_get_node(adj_pos)
			local adj_pos_name = adj_pos_node.name

			if NODE_NAMES_SOLID_ALL[adj_pos_name] then
				--debug(flag6, "      player's lower half is buried in a solid node")

				local pos_upper = {x = adj_pos.x, y = adj_pos.y + 1, z = adj_pos.z}
				--debug(flag6, "      pos_upper: " .. mt_pos_to_string(pos_upper))
				local upper_node = mt_get_node(pos_upper)
				local upper_node_name = upper_node.name
				--debug(flag6, "      upper_node_name: " .. upper_node_name)

				if NODE_NAMES_SOLID_ALL[upper_node_name] then
					--debug(flag6, "      player is completely buried in solid nodes")

				elseif NODE_NAMES_NONSOLID_ALL[upper_node_name] then
					--debug(flag6, "      player's upper half is in air or a non-solid node")

					-- spawn player at this upper_node pos (while crouched)
					valid_pos = {x = pos_upper.x, y = pos_upper.y, z = pos_upper.z}
					break

				else
					--debug(flag6, "      ERROR - node is not recognized in any global 'NODE_NAMES' table: " .. upper_node_name)
				end

			elseif NODE_NAMES_NONSOLID_ALL[adj_pos_name] then
				--debug(flag6, "      player's lower half is in a air or non-solid node")
				valid_pos = adj_pos
				break

			else
				--debug(flag6, "      ERROR - node is not recognized in any global 'NODE_NAMES' table: " .. adj_pos_name)
			end

		end

		if valid_pos then
			debug(flag6, "    *** valid pos found ***")

		else
			debug(flag6, "    no valid pos found. resorting to origin pos as the 'valid' pos.")
			valid_pos = pos
		end

	end

	debug(flag6, "    valid_pos: " .. mt_pos_to_string(valid_pos))
	debug(flag6, "  get_valid_player_spawn_pos() END")
	return valid_pos

end



local flag10 = false
-- allows player to climb/crawl up onto a solid node without having to jump, which
-- uses more stamina than normal jumping and drains a bit of hygiene. this action
-- is useful when player's jump ability is restrained due to status effects
local function try_climb(player, p_data, player_meta, pos)
	debug(flag10, "  try_climb()")
	if p_data.crawling then
		--debug(flag10, "    still crawling...")
		--debug(flag10, "  try_climb() END")
		return
	end

	local player_pos = {x=pos.x, y=pos.y+0.5, z=pos.z}
	local dir = player:get_look_dir()

	-- get pos 0.5 meters in front of player
	local check_pos = vector_add(player_pos, vector_multiply(dir, 0.5))

	-- get the node name at that location
	local front_pos = vector_round(check_pos)
	local front_node = mt_get_node(front_pos)
	local front_node_name = front_node.name

	--debug(flag10, "    front_node_name: " .. front_node_name)
	if NODE_NAMES_SOLID_CUBE[front_node_name] then
		--debug(flag10, "      front_node is solid cube")
		local front_pos_top = {x = front_pos.x, y = front_pos.y + 1, z = front_pos.z}
		local front_top_node = mt_get_node(front_pos_top)
		local front_node_top_name = front_top_node.name
		--debug(flag10, "      front_node_top_name: " .. front_node_top_name)
		if NODE_NAMES_NONSOLID_ALL[front_node_top_name] then
			--debug(flag10, "      front_node_top is non solid")
			do_stat_update_action(player, p_data, player_meta, "normal", "stamina", -p_data.stamina_loss_crawl_up, "curr", "add", true)
			do_stat_update_action(player, p_data, player_meta, "normal", "hygiene", -1, "curr", "add", true)

			--debug(flag10, "      ** crawling up **")
			local physics = player:get_physics_override()
			physics.jump = 1
			player:set_physics_override(physics)
			p_data.crawling = true

			if not p_data.player_vocalizing then
				local filename = "ss_action_crawlup_" .. p_data.body_type
				play_sound("vocal_sound", {sound_file = filename, player = player, p_data = p_data})
			end

			core.after(0.1, function()
				update_player_physics(player, {jump = true})
			end)

			-- start cooldown for crawling
			core.after(2, function()
				p_data.crawling = false
			end)
		end
	end
	debug(flag10, "  try_climb() END")
end




local flag3 = false
--- @param player ObjectRef the player object
-- Sets the intial state and animation of the player when joining the game. Ensures that
-- if player is spawned in a position where a solid node is at eye level or the position
-- is completely solid, have the player spawn in crouching state or simply moved away by
-- one node in a different direction.
local function set_starting_state(player, pos)
	debug(flag3, "\n  set_starting_state()")
	local player_state
	local fcrouched = false
	if pos == nil then
		debug(flag3, "    choosing a random pos")
		pos = player:get_pos()
	else
		debug(flag3, "    using a designated pos")
	end
	--debug(flag3, "    pos: " .. mt_pos_to_string(pos))

	-- spawn_pos represents the pos at bottom half of player's body, which is a
	-- non-solid node like air or plants. the node above it is not important since
	-- the player will be spawned crouching. if the upper node is also non-solid,
	-- the player will automatically stand upright. if the upper node is solid,
	-- the player will automatically remain in crouched position
	local spawn_pos = get_valid_player_spawn_pos(pos)
	--debug(flag3, "    spawn_pos: " .. mt_pos_to_string(spawn_pos))
	player_data[player:get_player_name()].spawn_pos = spawn_pos

	-- momve player to the valid spawn pos
	player:set_pos(spawn_pos)

	-- set player anim and physics to crouching state
	local p_data = player_data[player:get_player_name()]
	player:set_animation(anims.crouch, anim_speed.crouch, 0, false)
	player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
	p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
	p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
	update_player_physics(player, {speed = true, jump = true})
	player_state = "fcrouch"
	fcrouched = true

	debug(flag3, "  set_starting_state() end")
	return player_state, fcrouched
end


-- monitors and updates player's animation, properties, movement speed, jump height,
-- and stamina use based on the current (and previous) player state
local flag4 = false
--- @param player ObjectRef the source of the sound
--- @param prev_state string the animation state before this function was called
--- @param prev_pos table the player position prior to this function call
--- @param crouched boolean whether the player was 'sneak' crouching prior to this function call
--- @param fcrouched boolean whether the player was 'forced' or auto-crouching prior to this function call
--- @param running boolean whether the player was running prior to this function call
-- This function determines the current player animation state based on the current
-- controller input and prior animation states, then updates the player animation, player
-- collision and eye height properties, player speed and jump height physics, and finally
-- modifies player stats values if needed like stamina, hunger, thirst, etc.
local function monitor_player_state(player, prev_state, prev_pos, crouched, fcrouched, running)
	debug(flag4, "\nmonitor_player_state()")
	after_player_check(player)

	local curr_pos = player:get_pos()
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]
	local player_meta = player:get_meta()

	--[[
	-- change player's head vertical (pitch) look angle based on first person view angle
	local player_look_angle = player:get_look_vertical() * 180 / math.pi
	local bone_pos_neck, bone_rot_neck = player:get_bone_position("Neck")
	debug(flag4, "  bone_pos_neck: " .. dump(bone_pos_neck))
	debug(flag4, "  bone_rot_neck: " .. dump(bone_rot_neck))
	local new_rotation = {x = -player_look_angle / 3.0, y = 0, z = 0}
	player:set_bone_position("Neck", {x = 0, y = 3.40, z = 0}, new_rotation)
	player:set_bone_position("Head", {x = 0, y = 0.65, z = 0}, new_rotation)
	player:set_bone_position("Hair", {x = 0, y = 0.20, z = 0.60}, {x = 180, y = -90, z = 0})
	--]]

	local jump_distance = curr_pos.y - prev_pos.y
	--debug(flag4, "  jump_distance: " .. jump_distance)
	local jumped = false
    if jump_distance > 0.125 then
		--debug(flag4, "  ### JUMPED ###")
		jumped = true
	end

	local moved = false
	local distance_moved = vector_distance(prev_pos, curr_pos)
	--debug(flag4, "  move dist: " .. distance_moved)
	if distance_moved > 0 then
		moved = true
	end

	-- track downward vertical distance player is traveling in each iteration.
	-- then when player is no longer falling (node below is solid), use the total
	-- fall distance to determine drain amount to 'legs' stat. ignore any legs
	-- impact if player standing or is submerged in water
	if jump_distance < 0 then

		if p_data.water_level > 0 then
			-- reset the fall distance when submerged underwater
			p_data.fall_distance = 0

		else
			-- add the downward vertial distance traveled from the prior iteration
			-- and find the node at the player's feet
			p_data.fall_distance = p_data.fall_distance - jump_distance
			local bottom_node = mt_get_node({x = curr_pos.x, y = curr_pos.y - 0.5, z = curr_pos.z})
			local bottom_node_name = bottom_node.name

			if NODE_NAMES_WATER[bottom_node_name] then
				-- reset the fall distance when feet is in water
				p_data.fall_distance = 0

			-- player lands on a solid surface
			elseif NODE_NAMES_SOLID_ALL[bottom_node_name] then

				-- reduce leg drain amount when landing on softer nodes
				local hardness_modifier = NODE_LEGS_DRAIN_MOD[bottom_node_name]

				-- player lands on a solid surface. use the fall_distance to calculate
				-- amount of legs value drain
				local legs_drain_amount = (0.25 * p_data.fall_distance ^ 2)
					* hardness_modifier
					* p_data.leg_injury_mod_foot_clothing
                    * p_data.leg_injury_mod_foot_armor
                    * p_data.leg_injury_mod_skill
					* p_data.leg_drain_mod_shin_credible

				do_stat_update_action(
					player, p_data,
					player:get_meta(),
					"normal", "legs",
					-legs_drain_amount,
					"curr",
					"add",
					true
				)
				-- reset fall distance for the next potentional jump/fall
				p_data.fall_distance = 0
			end
		end
	end

	local controls = player:get_player_control()
	local curr_state
	if player:get_hp() == 0 then
		curr_state = "death"
	elseif controls.up or controls.down or controls.left or controls.right then
		if controls.aux1 then
			if controls.LMB then
				if controls.sneak then
					if moved then
						curr_state = "crouch_run_mine"
					else
						curr_state = "crouch_mine"
					end
				elseif controls.jump or jumped then
					if moved then
						curr_state = "run_jump_mine"
					else
						curr_state = "jump_mine"
					end
				else
					if moved then
						curr_state = "run_mine"
					else
						curr_state = "mine"
					end
				end
			elseif controls.sneak then
				if moved then
					curr_state = "crouch_run"
				else
					curr_state = "crouch"
				end
			elseif controls.jump or jumped then
				if moved then
					curr_state = "run_jump"
				else
					curr_state = "jump"
				end
			else
				if moved then
					curr_state = "run"
				else
					curr_state = "stand"
				end
			end
		elseif controls.LMB then
			if controls.sneak then
				if moved then
					curr_state = "crouch_walk_mine"
				else
					curr_state = "crouch_mine"
				end
			else
				if moved then
					curr_state = "walk_mine"
				else
					curr_state = "mine"
				end
			end
		elseif controls.jump or jumped then
			if controls.sneak then
				if moved then
					curr_state = "crouch_walk_jump"
				else
					curr_state = "crouch_jump"
				end
			elseif controls.LMB then
				if moved then
					curr_state = "walk_jump_mine"
				else
					curr_state = "jump_mine"
				end
			else
				if moved then
					curr_state = "walk_jump"
				else
					curr_state = "jump"
				end
			end
		elseif controls.sneak then
			if moved then
				curr_state = "crouch_walk"
			else
				curr_state = "crouch"
			end
		else
			if moved then
				curr_state = "walk"
			else
				curr_state = "stand"
			end
		end
	elseif controls.LMB then
		if controls.jump or jumped then
			if controls.sneak then
				curr_state = "crouch_jump_mine"
			else
				curr_state = "jump_mine"
			end
		elseif controls.sneak then
				curr_state = "crouch_mine"
		else
			curr_state = "mine"
		end
	elseif controls.sneak then
		if controls.up or controls.down or controls.left or controls.right then
			if moved then
				curr_state = "crouch_walk"
			else
				curr_state = "crouch"
			end
		elseif controls.jump or jumped then
			curr_state = "crouch_jump"
		else
			curr_state = "crouch"
		end
	elseif controls.jump or jumped then
		curr_state = "jump"
	elseif controls.zoom then
		curr_state = "zoom"
	elseif controls.aux1 then
		curr_state = "stand"
	else
		curr_state = "stand"
	end
	--debug(flag4, "  detected state: " .. curr_state)

	local stamina_gain_total = 0
	local stamina_loss_total = 0
	p_data.current_anim_state = curr_state

	local LEGS_DRAIN_RUNNING = -0.03
		* p_data.leg_injury_mod_foot_clothing
		* p_data.leg_injury_mod_foot_armor
		* p_data.leg_injury_mod_skill
		* p_data.leg_injury_mod_water
	--print("### LEGS_DRAIN_RUNNING: " .. LEGS_DRAIN_RUNNING)

	-----------
	-- STAND --
	-----------

	if curr_state == "stand" then
		if prev_state == "stand" then
			--debug(flag4, "  already idling")
			crouched = false
			fcrouched = false
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_stand
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot stand when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"

		else
			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch, reduce walk speed")
					player:set_animation(anims.crouch, anim_speed.crouch, 0, false)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch
					curr_state = "fcrouch"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to stand, set prop upward, increase walk speed")
					player:set_animation(anims.stand, anim_speed.stand, 0, false)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_gain_total = stamina_gain_total + p_data.stamina_gain_stand
					crouched = false
					fcrouched = false
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch" then
						--debug(flag4, "  animation already on crouch")
					else
						--debug(flag4, "  ** updating animation to crouch **")
						player:set_animation(anims.crouch, anim_speed.crouch, 0, false)
						if running then
							p_data.speed_buff_run = 1.0
							update_player_physics(player, {speed = true})
							running = false
						end
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch
					curr_state = "fcrouch"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to stand, set prop upward, increase walk speed")
					player:set_animation(anims.stand, anim_speed.stand, 0, false)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_gain_total = stamina_gain_total + p_data.stamina_gain_stand
					crouched = false
					fcrouched = false
				end

			else
				--debug(flag4, "  previously upright, set anim to stand")
				player:set_animation(anims.stand, anim_speed.stand, 0, false)
				stamina_gain_total = stamina_gain_total + p_data.stamina_gain_stand
				if running then
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					running = false
				end
				crouched = false
				fcrouched = false
			end
		end


	----------
	-- WALK --
	----------

	elseif curr_state == "walk" then
		if prev_state == "walk" then
			--debug(flag4, "  already walking")
			crouched = false
			fcrouched = false
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_walk
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot walk when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_walk, reduce walk speed")
					player:set_animation(anims.crouch_walk, anim_speed.crouch_walk, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk
					curr_state = "fcrouch_walk"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to walk, set prop upward, increase walk speed")
					player:set_animation(anims.walk, anim_speed.walk, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_gain_total = stamina_gain_total + p_data.stamina_gain_walk
					crouched = false
					fcrouched = false
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_walk" then
						--debug(flag4, "  animation already on crouch_walk")
					else
						--debug(flag4, "  ** updating animation to crouch_walk **")
						player:set_animation(anims.crouch_walk, anim_speed.crouch_walk, 0, true)
						if running then
							p_data.speed_buff_run = 1.0
							update_player_physics(player, {speed = true})
							running = false
						end
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk
					curr_state = "fcrouch_walk"
					crouched = false
					fcrouched = true

				else
					--debug(flag4, "  set anim to walk, set prop upward, increase walk speed")
					player:set_animation(anims.walk, anim_speed.walk, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_gain_total = stamina_gain_total + p_data.stamina_gain_walk
					crouched = false
					fcrouched = false
				end

			else
				--debug(flag4, "  previously upright, set anim to walk")
				player:set_animation(anims.walk, anim_speed.walk, 0, true)
				stamina_gain_total = stamina_gain_total + p_data.stamina_gain_walk
				if running then
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					running = false
				end
				crouched = false
				fcrouched = false
			end
		end


	----------
	-- JUMP --
	----------

	elseif curr_state == "jump" then
		if prev_state == "jump" then
			--debug(flag4, "  already jumping")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_jump
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  previously sit_cave")
			if overhead_node_solid(player) then
				--debug(flag4, "  overhead node solid, set anim to crouch, reduce walk speed")
				player:set_animation(anims.crouch, anim_speed.crouch, 0, false)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = 1.0
				update_player_physics(player, {speed = true})
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch
				equip_wield_item(player, p_data.wield_item_index)
				curr_state = "fcrouch"
				crouched = false
				fcrouched = true
			else
				--debug(flag4, "  set anim to stand, set prop upward, increase walk speed")
				player:set_animation(anims.stand, anim_speed.stand, 0, false)
				player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
				p_data.speed_buff_crouch = 1.0
				p_data.speed_buff_run = 1.0
				update_player_physics(player, {speed = true})
				stamina_gain_total = stamina_gain_total + p_data.stamina_gain_stand
				crouched = false
				fcrouched = false
			end
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_jump, reduce walk speed")
					player:set_animation(anims.crouch_jump, anim_speed.crouch_jump, 0, false)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch
					curr_state = "fcrouch_jump"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to jump, set prop upward, increase walk speed")
					player:set_animation(anims.jump, anim_speed.jump, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_jump
					crouched = false
					fcrouched = false
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_jump" then
						--debug(flag4, "  animation already on crouch_jump")
					else
						--debug(flag4, "  ** updating animation to crouch_jump **")
						player:set_animation(anims.crouch_jump, anim_speed.crouch_jump, 0, false)
						if running then
							p_data.speed_buff_run = 1.0
							update_player_physics(player, {speed = true})
							running = false
						end
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch
					curr_state = "fcrouch_jump"
					crouched = false
					fcrouched = true

				else
					--debug(flag4, "  set anim to jump, set prop upward, increase walk speed")
					player:set_animation(anims.jump, anim_speed.jump, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_jump
					crouched = false
					fcrouched = false
				end

			else
				--debug(flag4, "  previously upright, set anim to jump")
				player:set_animation(anims.jump, anim_speed.jump, 0, true)
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_jump
				if running then
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					running = false
				end
				crouched = false
				fcrouched = false
			end
		end


	----------
	-- MINE --
	----------

	elseif curr_state == "mine" then

		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "mine" then
			--debug(flag4, "  already mining")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot mine when in sit_cave")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_sit_cave_mine
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_mine, reduce walk speed")
					player:set_animation(anims.crouch_mine, anim_speed.crouch_mine, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch + stamina_loss_mining
					curr_state = "fcrouch_mine"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to mine, set prop upward, increase walk speed")
					player:set_animation(anims.mine, anim_speed.mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + stamina_loss_mining
					crouched = false
					fcrouched = false
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_mine" then
						--debug(flag4, "  animation already on crouch_mine")
					else
						--debug(flag4, "  ** updating animation to crouch_mine **")
						player:set_animation(anims.crouch_mine, anim_speed.crouch_mine, 0, true)
						if running then
							p_data.speed_buff_run = 1.0
							update_player_physics(player, {speed = true})
							running = false
						end
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch + stamina_loss_mining
					curr_state = "fcrouch_mine"
					crouched = false
					fcrouched = true

				else
					--debug(flag4, "  set anim to mine, set prop upward, increase walk speed")
					player:set_animation(anims.mine, anim_speed.mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + stamina_loss_mining
					crouched = false
					fcrouched = false
				end

			else
				--debug(flag4, "  previously upright, set anim to mine")
				player:set_animation(anims.mine, anim_speed.mine, 0, true)
				stamina_loss_total = stamina_loss_total + stamina_loss_mining
				if running then
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					running = false
				end
				crouched = false
				fcrouched = false
			end
		end


	---------------
	-- WALK MINE --
	---------------

	elseif curr_state == "walk_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "walk_mine" then
			--debug(flag4, "  already walk mining")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot walk_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_walk_mine, reduce walk speed")
					player:set_animation(anims.crouch_walk_mine, anim_speed.crouch_walk_mine, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk + stamina_loss_mining
					curr_state = "fcrouch_walk_mine"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to walk_mine, set prop upward, increase walk speed")
					player:set_animation(anims.walk_mine, anim_speed.walk_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + stamina_loss_mining
					crouched = false
					fcrouched = false
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_walk_mine" then
						--debug(flag4, "  animation already on crouch_walk_mine")
					else
						--debug(flag4, "  ** updating animation to crouch_walk_mine **")
						player:set_animation(anims.crouch_walk_mine, anim_speed.crouch_walk_mine, 0, true)
						if running then
							p_data.speed_buff_run = 1.0
							update_player_physics(player, {speed = true})
							running = false
						end
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk + stamina_loss_mining
					curr_state = "fcrouch_walk_mine"
					crouched = false
					fcrouched = true

				else
					--debug(flag4, "  set anim to walk_mine, set prop upward, increase walk speed")
					player:set_animation(anims.walk_mine, anim_speed.walk_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + stamina_loss_mining
					crouched = false
					fcrouched = false
				end

			else
				--debug(flag4, "  previously upright, set anim to walk_mine")
				player:set_animation(anims.walk_mine, anim_speed.walk_mine, 0, true)
				stamina_loss_total = stamina_loss_total + stamina_loss_mining
				if running then
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					running = false
				end
				crouched = false
				fcrouched = false
			end
		end


	---------------
	-- WALK JUMP --
	---------------

	elseif curr_state == "walk_jump" then
		if prev_state == "walk_jump" then
			--debug(flag4, "  already walk jumping")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_walk_jump
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot walk_jump when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_walk_jump, reduce walk speed")
					player:set_animation(anims.crouch_walk_jump, anim_speed.crouch_walk_jump, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk
					curr_state = "fcrouch_walk_jump"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to walk_jump, set prop upward, increase walk speed")
					player:set_animation(anims.walk_jump, anim_speed.walk_jump, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_walk_jump
					crouched = false
					fcrouched = false
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_walk_jump" then
						--debug(flag4, "  animation already on crouch_walk_jump")
					else
						--debug(flag4, "  ** updating animation to crouch_walk_jump **")
						player:set_animation(anims.crouch_walk_jump, anim_speed.crouch_walk_jump, 0, true)
						if running then
							p_data.speed_buff_run = 1.0
							update_player_physics(player, {speed = true})
							running = false
						end
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk
					curr_state = "fcrouch_walk_jump"
					crouched = false
					fcrouched = true

				else
					--debug(flag4, "  set anim to walk_jump, set prop upward, increase walk speed")
					player:set_animation(anims.walk_jump, anim_speed.walk_jump, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_crouch = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_walk_jump
					crouched = false
					fcrouched = false
				end

			else
				--debug(flag4, "  previously upright, set anim to walk_jump")
				player:set_animation(anims.walk_jump, anim_speed.walk_jump, 0, true)
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_walk_jump
				if running then
					p_data.speed_buff_run = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					running = false
				end
				crouched = false
				fcrouched = false
			end
		end


	---------
	-- RUN --
	---------

	elseif curr_state == "run" then
		if prev_state == "run" then
			--debug(flag4, "  already running")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run
			do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot run when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_run, reduce walk speed")
					player:set_animation(anims.crouch_run, anim_speed.crouch_run, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = p_data.speed_buff_run_default
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run
					curr_state = "fcrouch_run"
					crouched = false
					fcrouched = true
					running = true
				else
					--debug(flag4, "  set anim to run, set prop upward, increase walk speed")
					player:set_animation(anims.run, anim_speed.run, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = p_data.speed_buff_run_default
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = p_data.jump_buff_run_default
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run
					crouched = false
					fcrouched = false
					running = true
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_run" then
						--debug(flag4, "  animation already on crouch_run")
					else
						--debug(flag4, "  ** updating animation to crouch_run **")
						player:set_animation(anims.crouch_run, anim_speed.crouch_run, 0, true)
						p_data.speed_buff_run = p_data.speed_buff_run_default
					update_player_physics(player, {speed = true})
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run
					curr_state = "fcrouch_run"
					crouched = false
					fcrouched = true
					running = true

				else
					--debug(flag4, "  set anim to run, set prop upward, increase walk speed")
					player:set_animation(anims.run, anim_speed.run, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = p_data.speed_buff_run_default
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = p_data.jump_buff_run_default
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run
					do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
					crouched = false
					fcrouched = false
					running = true
				end

			else
				--debug(flag4, "  previously upright, set anim to run")
				player:set_animation(anims.run, anim_speed.run, 0, true)
				p_data.speed_buff_run = p_data.speed_buff_run_default
				p_data.jump_buff_run = p_data.jump_buff_run_default
				update_player_physics(player, {speed = true, jump = true})
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run
				do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
				crouched = false
				fcrouched = false
				running = true
			end
		end


	--------------
	-- RUN MINE --
	--------------

	elseif curr_state == "run_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "run_mine" then
			--debug(flag4, "  already run mining")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run + stamina_loss_mining
			do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot run_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_run_mine, reduce walk speed")
					player:set_animation(anims.crouch_run_mine, anim_speed.crouch_run_mine, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = p_data.speed_buff_run_default
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run + stamina_loss_mining
					curr_state = "fcrouch_run_mine"
					crouched = false
					fcrouched = true
					running = true
				else
					--debug(flag4, "  set anim to run_mine, set prop upward, increase walk speed")
					player:set_animation(anims.run_mine, anim_speed.run_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = p_data.speed_buff_run_default
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run + stamina_loss_mining
					crouched = false
					fcrouched = false
					running = true
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_run_mine" then
						--debug(flag4, "  animation already on crouch_run_mine")
					else
						--debug(flag4, "  ** updating animation to crouch_run_mine **")
						player:set_animation(anims.crouch_run_mine, anim_speed.crouch_run_mine, 0, true)
						p_data.speed_buff_run = p_data.speed_buff_run_default
						update_player_physics(player, {speed = true})
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run + stamina_loss_mining
					curr_state = "fcrouch_run"
					crouched = false
					fcrouched = true
					running = true

				else
					--debug(flag4, "  set anim to run_mine, set prop upward, increase walk speed")
					player:set_animation(anims.run_mine, anim_speed.run_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = p_data.speed_buff_run_default
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run + stamina_loss_mining
					do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
					crouched = false
					fcrouched = false
					running = true
				end

			else
				--debug(flag4, "  previously upright, set anim to run_mine")
				player:set_animation(anims.run_mine, anim_speed.run_mine, 0, true)
				p_data.speed_buff_run = p_data.speed_buff_run_default
				p_data.jump_buff_run = 1.0
				update_player_physics(player, {speed = true, jump = true})
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run + stamina_loss_mining
				do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
				crouched = false
				fcrouched = false
				running = true
			end
		end


	-------------------
	-- RUN JUMP MINE --
	-------------------

	elseif curr_state == "run_jump_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "run_jump_mine" then
			--debug(flag4, "  already run jump mining")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run_jump + stamina_loss_mining
			do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot run_jump_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_run_jump_mine, reduce walk speed")
					player:set_animation(anims.crouch_run_jump_mine, anim_speed.crouch_run_jump_mine, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = p_data.speed_buff_run_default
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run_jump + stamina_loss_mining
					curr_state = "fcrouch_run_jump_mine"
					crouched = false
					fcrouched = true
					running = true
				else
					--debug(flag4, "  set anim to run_jump_mine, set prop upward, increase walk speed")
					player:set_animation(anims.run_jump_mine, anim_speed.run_jump_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = p_data.speed_buff_run_default
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run_jump + stamina_loss_mining
					crouched = false
					fcrouched = false
					running = true
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_run_jump_mine" then
						--debug(flag4, "  animation already on crouch_run_jump_mine")
					else
						--debug(flag4, "  ** updating animation to crouch_run_jump_mine **")
						player:set_animation(anims.crouch_run_jump_mine, anim_speed.crouch_run_jump_mine, 0, true)
						p_data.speed_buff_run = p_data.speed_buff_run_default
						update_player_physics(player, {speed = true})
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run_jump + stamina_loss_mining
					curr_state = "fcrouch_run_jump_mine"
					crouched = false
					fcrouched = true
					running = true

				else
					--debug(flag4, "  set anim to run_jump_mine, set prop upward, increase walk speed")
					player:set_animation(anims.run_jump_mine, anim_speed.run_jump_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = p_data.speed_buff_run_default
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run_jump + stamina_loss_mining
					do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
					crouched = false
					fcrouched = false
					running = true
				end

			else
				--debug(flag4, "  previously upright, set anim to run_jump_mine")
				player:set_animation(anims.run_jump_mine, anim_speed.run_jump_mine, 0, true)
				p_data.speed_buff_run = p_data.speed_buff_run_default
				p_data.jump_buff_run = 1.0
				update_player_physics(player, {speed = true, jump = true})
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run_jump + stamina_loss_mining
				do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
				crouched = false
				fcrouched = false
				running = true
			end
		end


	--------------
	-- RUN JUMP --
	--------------

	elseif curr_state == "run_jump" then
		if prev_state == "run_jump" then
			--debug(flag4, "  already run jumping")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run_jump
			do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot run_jump when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_run_jump, reduce walk speed")
					player:set_animation(anims.crouch_run_jump, anim_speed.crouch_run_jump, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					p_data.speed_buff_run = p_data.speed_buff_run_default
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run_jump
					curr_state = "fcrouch_run_jump"
					crouched = false
					fcrouched = true
					running = true
				else
					--debug(flag4, "  set anim to run_jump, set prop upward, increase walk speed")
					player:set_animation(anims.run_jump, anim_speed.run_jump, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = p_data.speed_buff_run_default
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run_jump
					crouched = false
					fcrouched = false
					running = true
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_run_jump" then
						--debug(flag4, "  animation already on crouch_run_jump")
					else
						--debug(flag4, "  ** updating animation to crouch_run_jump **")
						player:set_animation(anims.crouch_run_jump, anim_speed.crouch_run_jump, 0, true)
						p_data.speed_buff_run = p_data.speed_buff_run_default
						update_player_physics(player, {speed = true})
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run_jump
					curr_state = "fcrouch_run_jump"
					crouched = false
					fcrouched = true
					running = true

				else
					--debug(flag4, "  set anim to run_jump, set prop upward, increase walk speed")
					player:set_animation(anims.run_jump, anim_speed.run_jump, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.speed_buff_run = p_data.speed_buff_run_default
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run_jump
					do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
					crouched = false
					fcrouched = false
					running = true
				end

			else
				--debug(flag4, "  previously upright, set anim to run_jump")
				player:set_animation(anims.run_jump, anim_speed.run_jump, 0, true)
				p_data.speed_buff_run = p_data.speed_buff_run_default
				p_data.jump_buff_run = 1.0
				update_player_physics(player, {speed = true, jump = true})
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_run_jump
				do_stat_update_action(player, p_data, player_meta, "normal", "legs", LEGS_DRAIN_RUNNING, "curr", "add", true)
				crouched = false
				fcrouched = false
				running = true
			end
		end


	---------------
	-- JUMP MINE --
	---------------

	elseif curr_state == "jump_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "jump_mine" then
			--debug(flag4, "  already jump mining")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_jump + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot jump_mine when in sit_cave")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_sit_cave_mine
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_jump_mine, reduce walk speed")
					player:set_animation(anims.crouch_jump_mine, anim_speed.crouch_jump_mine, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_jump + stamina_loss_mining
					curr_state = "fcrouch_jump_mine"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to jump_mine, set prop upward, increase walk speed")
					player:set_animation(anims.jump_mine, anim_speed.jump_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_jump + stamina_loss_mining
					crouched = false
					fcrouched = false
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_jump_mine" then
						--debug(flag4, "  animation already on crouch_jump_mine")
					else
						--debug(flag4, "  ** updating animation to crouch_jump_mine **")
						player:set_animation(anims.crouch_jump_mine, anim_speed.crouch_jump_mine, 0, true)
						if running then
							p_data.speed_buff_run = 1.0
							update_player_physics(player, {speed = true})
							running = false
						end
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_jump + stamina_loss_mining
					curr_state = "fcrouch_jump_mine"
					crouched = false
					fcrouched = true

				else
					--debug(flag4, "  set anim to jump_mine, set prop upward, increase walk speed")
					player:set_animation(anims.jump_mine, anim_speed.jump_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_jump + stamina_loss_mining
					crouched = false
					fcrouched = false
				end

			else
				--debug(flag4, "  previously upright, set anim to jump_mine")
				player:set_animation(anims.jump_mine, anim_speed.jump_mine, 0, true)
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_jump + stamina_loss_mining
				if running then
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {jump = true})
					running = false
				end
				crouched = false
				fcrouched = false
			end
		end


	-------------------
	-- WALK JUMP MINE --
	-------------------

	elseif curr_state == "walk_jump_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "walk_jump_mine" then
			--debug(flag4, "  already walk jump mining")
			crouched = false
			fcrouched = false
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_walk_jump + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot jump_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else

			if crouched then
				--debug(flag4, "  previously crouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node solid, set anim to crouch_jump_mine, reduce walk speed")
					player:set_animation(anims.crouch_walk_jump_mine, anim_speed.crouch_walk_jump_mine, 0, true)
					p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
					update_player_physics(player, {speed = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk_jump + stamina_loss_mining
					curr_state = "fcrouch_jump_mine"
					crouched = false
					fcrouched = true
				else
					--debug(flag4, "  set anim to jump_mine, set prop upward, increase walk speed")
					player:set_animation(anims.jump_mine, anim_speed.jump_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_walk_jump + stamina_loss_mining
					crouched = false
					fcrouched = false
				end

			elseif fcrouched then
				--debug(flag4, "  previously fcrouched")

				if overhead_node_solid(player) then
					--debug(flag4, "  overhead node is solid")
					if prev_state == "fcrouch_jump_mine" then
						--debug(flag4, "  animation already on crouch_jump_mine")
					else
						--debug(flag4, "  ** updating animation to crouch_jump_mine **")
						player:set_animation(anims.crouch_jump_mine, anim_speed.crouch_jump_mine, 0, true)
						if running then
							p_data.speed_buff_run = 1.0
							update_player_physics(player, {speed = true})
							running = false
						end
					end
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk_jump + stamina_loss_mining
					curr_state = "fcrouch_jump_mine"
					crouched = false
					fcrouched = true

				else
					--debug(flag4, "  set anim to jump_mine, set prop upward, increase walk speed")
					player:set_animation(anims.jump_mine, anim_speed.jump_mine, 0, true)
					player:set_properties({ collisionbox = collisionbox_stand, eye_height = eye_height_stand })
					p_data.speed_buff_crouch = 1.0
					p_data.jump_buff_crouch = 1.0
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {speed = true, jump = true})
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_walk_jump + stamina_loss_mining
					crouched = false
					fcrouched = false
				end

			else
				--debug(flag4, "  previously upright, set anim to jump_mine")
				player:set_animation(anims.jump_mine, anim_speed.jump_mine, 0, true)
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_walk_jump + stamina_loss_mining
				if running then
					p_data.jump_buff_run = 1.0
					update_player_physics(player, {jump = true})
					running = false
				end
				crouched = false
				fcrouched = false
			end
		end


	-------------------------------------
	-- crouching using the 'sneak' key --
	-------------------------------------

	------------
	-- CROUCH --
	------------

	elseif curr_state == "crouch" then
		if prev_state == "crouch" then
			--debug(flag4, "  already CROUCH state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch

		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch', set anim to crouch")
				player:set_animation(anims.crouch, anim_speed.crouch, 0, false)
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch
				if running then
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					running = false
				end
			elseif fcrouched then
				if prev_state == "fcrouch" then
					--debug(flag4, "  updating animation to sit_cave")
					player:set_animation(anims.sit_cave, anim_speed.sit_cave, 0, false)
					player:set_properties({ collisionbox = collisionbox_sit_cave, eye_height = eye_height_sit_cave })
					p_data.speed_buff_crouch = 0
					update_player_physics(player, {speed = true})
					stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
					unequip_wield_item(player)
					curr_state = "sit_cave"
				else
					--debug(flag4, "  ** updating animation to crouch **")
					player:set_animation(anims.crouch, anim_speed.crouch, 0, false)
					stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch, set prop downward")
				player:set_animation(anims.crouch, anim_speed.crouch, 0, false)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = 1.0
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch
			end
		end
		crouched = true
		fcrouched = false


	-----------------
	-- CROUCH WALK --
	-----------------

	elseif curr_state == "crouch_walk" then
		if prev_state == "crouch_walk" then
			--debug(flag4, "  already CROUCH WALK state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_walk when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_walk', set anim to crouch_walk")
				player:set_animation(anims.crouch_walk, anim_speed.crouch_walk, 0, true)
				if running then
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					running = false
				end
			elseif fcrouched then
				if prev_state == "fcrouch_walk" then
					--debug(flag4, "  animation already on crouch_walk")
				else
					--debug(flag4, "  ** updating animation to CROUCH WALK**")
					player:set_animation(anims.crouch_walk, anim_speed.crouch_walk, 0, true)
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_walk, set prop downward")
				player:set_animation(anims.crouch_walk, anim_speed.crouch_walk, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = 1.0
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
			end
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk
		end
		crouched = true
		fcrouched = false


	----------------------
	-- CROUCH WALK JUMP --
	----------------------

	elseif curr_state == "crouch_walk_jump" then
		if prev_state == "crouch_walk_jump" then
			--debug(flag4, "  already CROUCH WALK JUMP state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk_jump
			-- check if player attempting to mantle up onto block/node ahead
			try_climb(player, p_data, player:get_meta(), curr_pos)
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_walk_jump when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_walk_jump', set anim to crouch_walk_jump")
				player:set_animation(anims.crouch_walk_jump, anim_speed.crouch_walk_jump, 0, true)
				if running then
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					running = false
				end
			elseif fcrouched then
				if prev_state == "fcrouch_walk_jump" then
					--debug(flag4, "  animation already on fcrouch_walk_jump")
				else
					--debug(flag4, "  ** updating animation to CROUCH **")
					player:set_animation(anims.crouch_walk_jump, anim_speed.crouch_walk_jump, 0, true)
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_walk_jump, set prop downward")
				player:set_animation(anims.crouch_walk_jump, anim_speed.crouch_walk_jump, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = 1.0
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
			end
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk_jump
		end
		crouched = true
		fcrouched = false


	-----------------
	-- CROUCH MINE --
	-----------------

	elseif curr_state == "crouch_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "crouch_mine" then
			--debug(flag4, "  already crouch_mine state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_mine', set anim to crouch_mine")
				player:set_animation(anims.crouch_mine, anim_speed.crouch_mine, 0, true)
				if running then
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					running = false
				end
			elseif fcrouched then
				if prev_state == "fcrouch_mine" then
					--debug(flag4, "  animation already on crouch_mine")
				else
					--debug(flag4, "  ** updating animation to crouch_mine **")
					player:set_animation(anims.crouch_mine, anim_speed.crouch_mine, 0, true)
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_mine, set prop downward")
				player:set_animation(anims.crouch_mine, anim_speed.crouch_mine, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = 1.0
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
			end
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch + stamina_loss_mining
		end
		crouched = true
		fcrouched = false


	----------------------
	-- CROUCH WALK MINE --
	----------------------

	elseif curr_state == "crouch_walk_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "crouch_walk_mine" then
			--debug(flag4, "  already crouch_walk_mine state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_walk_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_walk_mine', set anim to crouch_walk_mine")
				player:set_animation(anims.crouch_walk_mine, anim_speed.crouch_walk_mine, 0, true)
				if running then
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					running = false
				end
			elseif fcrouched then
				if prev_state == "fcrouch_walk_mine" then
					--debug(flag4, "  animation already on crouch_walk_mine")
				else
					--debug(flag4, "  ** updating animation to crouch_walk_mine **")
					player:set_animation(anims.crouch_walk_mine, anim_speed.crouch_walk_mine, 0, true)
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_walk_mine, set prop downward")
				player:set_animation(anims.crouch_walk_mine, anim_speed.crouch_walk_mine, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = 1.0
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
			end
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_walk + stamina_loss_mining
		end
		crouched = true
		fcrouched = false


	-----------------
	-- CROUCH JUMP --
	-----------------

	elseif curr_state == "crouch_jump" then
		if prev_state == "crouch_jump" then
			--debug(flag4, "  already crouch_jump state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_jump
			-- check if player attempting to mantle up onto block/node ahead
			try_climb(player, p_data, player:get_meta(), curr_pos)
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_jump when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_jump', set anim to crouch_jump")
				player:set_animation(anims.crouch_jump, anim_speed.crouch_jump, 0, true)
				if running then
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					running = false
				end
			elseif fcrouched then
				if prev_state == "fcrouch_jump" then
					--debug(flag4, "  animation already on crouch_jump")
				else
					--debug(flag4, "  ** updating animation to crouch_jump **")
					player:set_animation(anims.crouch_jump, anim_speed.crouch_jump, 0, true)
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_jump, set prop downward")
				player:set_animation(anims.crouch_jump, anim_speed.crouch_jump, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = 1.0
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
			end
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_jump
		end
		crouched = true
		fcrouched = false


	----------------------
	-- CROUCH JUMP MINE --
	----------------------

	elseif curr_state == "crouch_jump_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "crouch_jump_mine" then
			--debug(flag4, "  already crouch_jump_mine state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_jump + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_jump_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_jump_mine', set anim to crouch_jump_mine")
				player:set_animation(anims.crouch_jump_mine, anim_speed.crouch_jump_mine, 0, true)
				if running then
					p_data.speed_buff_run = 1.0
					update_player_physics(player, {speed = true})
					running = false
				end
			elseif fcrouched then
				if prev_state == "fcrouch_jump_mine" then
					--debug(flag4, "  animation already on crouch_jump_mine")
				else
					--debug(flag4, "  ** updating animation to crouch_jump_mine **")
					player:set_animation(anims.crouch_jump_mine, anim_speed.crouch_jump_mine, 0, true)
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_jump_mine, set prop downward")
				player:set_animation(anims.crouch_jump_mine, anim_speed.crouch_jump_mine, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = 1.0
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
			end
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_jump + stamina_loss_mining
		end
		crouched = true
		fcrouched = false


	----------------
	-- CROUCH RUN --
	----------------

	elseif curr_state == "crouch_run" then
		if prev_state == "crouch_run" then
			--debug(flag4, "  already crouch_run state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_run when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_run', set anim to crouch_run")
				player:set_animation(anims.crouch_run, anim_speed.crouch_run, 0, true)
				p_data.speed_buff_run = p_data.speed_buff_run_default
				update_player_physics(player, {speed = true})
			elseif fcrouched then
				if prev_state == "fcrouch_run" then
					--debug(flag4, "  animation already on crouch_run")
				else
					--debug(flag4, "  ** updating animation to crouch_run **")
					player:set_animation(anims.crouch_run, anim_speed.crouch_run, 0, true)
					p_data.speed_buff_run = p_data.speed_buff_run_default
					update_player_physics(player, {speed = true})
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_run, set prop downward")
				player:set_animation(anims.crouch_run, anim_speed.crouch_run, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = p_data.speed_buff_run_default
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
				stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run
			end
		end
		crouched = true
		fcrouched = false
		running = true


	----------------------
	-- CROUCH RUN MINE --
	----------------------

	elseif curr_state == "crouch_run_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "crouch_run_mine" then
			--debug(flag4, "  already crouch_run_mine state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_run_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_run_mine', set anim to crouch_run_mine")
				player:set_animation(anims.crouch_run_mine, anim_speed.crouch_run_mine, 0, true)
				p_data.speed_buff_run = p_data.speed_buff_run_default
				update_player_physics(player, {speed = true})
			elseif fcrouched then
				if prev_state == "fcrouch_run_mine" then
					--debug(flag4, "  animation already on crouch_run_mine")
				else
					--debug(flag4, "  ** updating animation to crouch_run_mine **")
					player:set_animation(anims.crouch_run_mine, anim_speed.crouch_run_mine, 0, true)
					p_data.speed_buff_run = p_data.speed_buff_run_default
					update_player_physics(player, {speed = true})
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_run_mine, set prop downward")
				player:set_animation(anims.crouch_run_mine, anim_speed.crouch_run_mine, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = p_data.speed_buff_run_default
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
			end
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run + stamina_loss_mining
		end
		crouched = true
		fcrouched = false
		running = true


	--------------------------
	-- CROUCH RUN JUMP MINE --
	--------------------------

	elseif curr_state == "crouch_run_jump_mine" then
		local stamina_loss_mining = p_data.stamina_loss_factor_mining * get_wield_weight(player, p_data)

		if prev_state == "crouch_run_jump_mine" then
			--debug(flag4, "  already crouch_run_jump_mine state")
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run_jump + stamina_loss_mining
		elseif prev_state == "sit_cave" then
			--debug(flag4, "  cannot crouch_run_jump_mine when in sit_cave")
			stamina_gain_total = stamina_gain_total + p_data.stamina_gain_sit_cave
			unequip_wield_item(player)
			curr_state = "sit_cave"
		else
			if crouched then
				--debug(flag4, "  crouching state but not 'crouch_run_jump_mine', set anim to crouch_run_jump_mine")
				player:set_animation(anims.crouch_run_jump_mine, anim_speed.crouch_run_jump_mine, 0, true)
				p_data.speed_buff_run = p_data.speed_buff_run_default
				update_player_physics(player, {speed = true})
			elseif fcrouched then
				if prev_state == "fcrouch_run_jump_mine" then
					--debug(flag4, "  animation already on crouch_run_jump_mine")
				else
					--debug(flag4, "  ** updating animation to crouch_run_jump_mine **")
					player:set_animation(anims.crouch_run_jump_mine, anim_speed.crouch_run_jump_mine, 0, true)
					p_data.speed_buff_run = p_data.speed_buff_run_default
					update_player_physics(player, {speed = true})
				end
			else
				--debug(flag4, "  previously upright, set anim to crouch_run_jump_mine, set prop downward")
				player:set_animation(anims.crouch_run_jump_mine, anim_speed.crouch_run_jump_mine, 0, true)
				player:set_properties({ collisionbox = collisionbox_crouch, eye_height = eye_height_crouch })
				p_data.speed_buff_crouch = p_data.speed_buff_crouch_default
				p_data.speed_buff_run = p_data.speed_buff_run_default
				p_data.jump_buff_crouch = p_data.jump_buff_crouch_default
				update_player_physics(player, {speed = true, jump = true})
			end
			stamina_loss_total = stamina_loss_total + p_data.stamina_loss_crouch_run_jump + stamina_loss_mining
		end
		crouched = true
		fcrouched = false
		running = true


	-----------
	-- DEATH --
	-----------

	elseif curr_state == "death" then

		--debug(flag4, "  player dead. quit monitoring of player state..")
		player:set_animation(anims.death_front, anim_speed.death_front, 0, false)
		player:set_properties({ collisionbox = collisionbox_lay, eye_height = eye_height_lay })
		p_data.speed_buff_crouch = 1.0
		p_data.speed_buff_run = 1.0
		update_player_physics(player, {speed = true})
		crouched = false
		fcrouched = false
		running = false

		-- stop monitoring player state
		return

	else
		--debug(flag4, "  ERROR Unexpected 'curr_state' value: " .. curr_state)
	end


	---------------------------
	-- DECREASE PLAYER STATS --
	---------------------------

	--debug(flag4, "  stamina_gain_total (before): " .. stamina_gain_total)
	--debug(flag4, "  stamina_loss_total (before): " .. stamina_loss_total)

	-- factor in all stamina modifiers and determine how much stamina is RAISED this cycle
	stamina_gain_total = (stamina_gain_total
		* p_data.stamina_rec_mod_hot
		* p_data.stamina_rec_mod_cold
		* p_data.stamina_rec_mod_illness
		* p_data.stamina_rec_mod_poison
		* p_data.stamina_rec_mod_fast_charger
	)

	-- factor in all stamina modifiers and determine how much stamina is LOWERED this cycle
	stamina_loss_total = (stamina_loss_total
		* p_data.stamina_drain_mod_thirst
		* p_data.stamina_drain_mod_hunger
		* p_data.stamina_drain_mod_alertness
		* p_data.stamina_drain_mod_weight
		* p_data.stamina_drain_mod_illness
		* p_data.stamina_drain_mod_poison
		* p_data.stamina_drain_mod_burnout_blocker
	)

	local stamina_change_total = stamina_gain_total - stamina_loss_total

	if stamina_change_total > 0 then
		--debug(flag4, "  stamin gain: " .. stamina_change_total)
		if p_data.stamina_ratio == 1 then
			--debug(flag4, "  stamin already full. no further gain.")
		else
			do_stat_update_action(player, p_data, player_meta, "normal", "stamina", stamina_change_total, "curr", "add", true)
		end
	elseif stamina_change_total < 0 then
		--debug(flag4, "  ** stamina loss: " .. stamina_change_total .. " **")
		do_stat_update_action(player, p_data, player_meta, "normal", "stamina", stamina_change_total, "curr", "add", true)
	else
		--debug(flag4, "  stamina unchanged")
	end

	--debug(flag4, "  prev_state: " .. prev_state .. " | final curr_state: " .. curr_state)

	--debug(flag4, "monitor_player_state() end")
	local job_handle = mt_after(0.5, monitor_player_state, player, curr_state, curr_pos, crouched, fcrouched, running)
    job_handles[player_name].monitor_player_state = job_handle
end


local flag5 = false
core.register_on_joinplayer(function(player)
	debug(flag5, "\nregister_on_joinplayer() PLAYER_ANIM")
	local p_data = player_data[player:get_player_name()]

	-- default multipliers against walking speed when doing these actions
    p_data.speed_buff_crouch_default = 0.25
    p_data.speed_buff_run_default = 1.5

	-- default multipliers against jump height when doing these actions
    p_data.jump_buff_crouch_default = 0.0
    p_data.jump_buff_run_default = 1.0

	mt_after(1, function()
		after_player_check(player)

		-- prevent slowing down movement speed when pressing 'sneak' key, by increasing the
		-- crouch speed to equal the current walk/movement speed. this is needed to have player
		-- experience the same reduced movement when switching between sneak crouching and forced
		-- crouching states.
		local physics = player:get_physics_override()
		physics.speed_crouch = physics.speed * 3
		player:set_physics_override(physics)

		local player_state, fcrouched = set_starting_state(player)
		--debug(flag5, "  player_state: " .. dump(player_state))
		monitor_player_state(player, player_state, player:get_pos(), false, fcrouched, false)
	end)

	debug(flag5, "\nregister_on_joinplayer() end")
end)


local flag7 = false
core.register_on_respawnplayer(function(player)
    debug(flag7, "\nregister_on_respawnplayer() PLAYER ANIM")
	local p_data = player_data[player:get_player_name()]

	p_data.speed_buff_crouch_default = 0.25
    p_data.speed_buff_run_default = 1.5
	p_data.jump_buff_crouch_default = 0.0
    p_data.jump_buff_run_default = 1.0

	--debug(flag7, "  start monitor player state loop in 1 second..")
	mt_after(0, function()
		after_player_check(player)
		local player_state, fcrouched = set_starting_state(player, p_data.death_pos)
		--debug(flag7, "  player_state: " .. dump(player_state))
		monitor_player_state(player, player_state, player:get_pos(), false, fcrouched, false)
	end)

    debug(flag7, "register_on_respawnplayer() END")
end)


local flag9 = false
core.register_on_leaveplayer(function(player)
    debug(flag9, "\nregister_on_leaveplayer() PLAYER_ANIM")
    local player_name = player:get_player_name()
    local job_handle = job_handles[player_name].monitor_player_state
	if job_handle then
		job_handle:cancel()
    	job_handles[player_name].monitor_player_state = nil
		--debug(flag9, "  cancelled monitor_player_state() loop..")
	end
    debug(flag9, "register_on_leaveplayer() END")
end)