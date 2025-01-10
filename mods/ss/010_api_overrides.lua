print("- loading api_overrides.lua")

-- cache global functions for faster access
local math_random = math.random
local mt_pos_to_string = minetest.pos_to_string
local mt_hash_node_position = minetest.hash_node_position
local mt_get_gametime = minetest.get_gametime
local mt_add_item = minetest.add_item
local debug = ss.debug

local itemdrop_bag_pos = ss.itemdrop_bag_pos




local flag1 = false
-- original definition location: builtin/game/item_entity.lua
function core.spawn_item(pos, item)
	debug(flag1, "\ncore.spawn_item() API OVERRIDES")
	debug(flag1, "  pos: " .. mt_pos_to_string(pos))

	-- use the 'pos' parameter (which is the player's pos) as the basis for the pos hash
	local pos_hash = mt_hash_node_position(pos)

	-- retrieve pos hash that was set in bag_allow_metadata_inventory_take() of itemdrop_bag.lua
	local bag_pos = itemdrop_bag_pos[pos_hash]
	if bag_pos then
		debug(flag1, "  dropping item at bag pos..")
    	pos = itemdrop_bag_pos[pos_hash]
		itemdrop_bag_pos[pos_hash] = nil
		debug(flag1, "  itemdrop_bag_pos: " .. dump(itemdrop_bag_pos))
	else
		debug(flag1, "  dropping item at player pos..")
		-- tweak item spawn height lower in case player is crouching
		pos = {x = pos.x, y = pos.y - 0.5, z = pos.z}
	end
	debug(flag1, "  pos: " .. mt_pos_to_string(pos))

	local item_object = core.add_entity(pos, "__builtin:item")
	local stack = ItemStack(item)
	if item_object then
		item_object:get_luaentity():set_item(stack:to_string())
	end

	debug(flag1, "core.spawn_item() END *** " .. mt_get_gametime() .. "\n")
	return item_object
end

-- be default, item drops from nodes and placed directly into player's inventory. overriding
-- this allows code for dropping items to the ground instead
function minetest.handle_node_drops(pos, drops, digger)
    for _, item in ipairs(drops) do
        mt_add_item({
			x = pos.x + math_random(-2, 2)/10,
			y = pos.y + 0.5,
			z = pos.z + math_random(-2, 2)/10
		}, item)
    end
end