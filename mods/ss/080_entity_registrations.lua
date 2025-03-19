
-- cache global functions and variables for faster access
local mt_add_entity = core.add_entity
local vector_add = vector.add
local mt_yaw_to_dir = core.yaw_to_dir

local math_pi = math.pi


--[[
core.register_entity("ss:player_dummy", {
    -- Basic entity properties
    hp_max = 20,
    physical = true,
    collisionbox = {-0.3, -0.1, -0.10, 0.2, 0.3, 1.60},  -- Adjusted for lying position
    visual = "mesh",
    visual_size = {x = 1, y = 1},
    mesh = "character.b3d",
    textures = {"character.png"}, -- This should be the player's texture
    makes_footstep_sound = false,
    static_save = false,

    -- Make it static (no movement, no rotation)
    on_activate = function(self, staticdata, dtime_s)
        self.object:set_velocity({x = 0, y = 0, z = 0})
        self.object:set_acceleration({x = 0, y = 0, z = 0})
        self.object:set_rotation({x = -math_pi / 2, y = 0, z = 0}) -- Rotate to lie flat
    end,
    on_rightclick = function(self, clicker)
        if clicker and clicker:is_player() then
            -- Example action: print a message to the player who clicked
            print("  searching corpse...")
        end
    end,
})


local function add_dummy(player)
    if not player or not player:is_player() then return end

    local pos = player:get_pos()
    local direction = mt_yaw_to_dir(player:get_look_horizontal())

    -- Calculate new position 3 blocks away from the player
    local new_pos = vector_add(pos, vector.multiply(direction, 3))

    -- Spawn the dummy entity
    mt_add_entity(new_pos, "ss:player_dummy")
end
--]]