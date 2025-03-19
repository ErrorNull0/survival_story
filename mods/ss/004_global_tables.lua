print("- loading global_tables.lua")

--[[ This file represents the point during mod loading where all registered items
like nodes, items, and tools, have been defined and loaded. So this is the best
time to perform actions based on the "core.registered_" tables, like initialize
more global tables based on all registered items, or override registered items. --]]

-- cache global functions for faster access
local debug = ss.debug


-- ##### initialize ss.CRAFTITEM_ICON
for item_name, item_def in pairs(core.registered_items) do
	local image = item_def.inventory_image
	if image ~= "" then
		ss.CRAFTITEM_ICON[item_name] = item_def.inventory_image
	end
end

-- ##### initialize ss.CRAFTITEM_NAMES
for craftitem_name, item_def in pairs(core.registered_craftitems) do
	ss.CRAFTITEM_NAMES[craftitem_name] = true
end

-- ##### initialize ss.TOOL_NAMES
for tool_name, tool_def in pairs(core.registered_tools) do
	ss.TOOL_NAMES[tool_name] = true
end


-- ### CATEGORIZING NODE TYPES ### --

local flag4 = false
debug(flag4, "categorizing node types...")
--[[ Note: 
All nodes have selection boxes, but not all have collision boxes.
Nodes with selection box type of 'regular' do not have collison boxes specified
Nodes with selection box type of 'wallmounted' do not have collison boxes specified,
  but can have no selection box values, like ladders, or can have varying selection
  box values for each node face attachment location like signs and torches
nodes with selection box type of 'fixed' might have a collision box specified.
nodes with selection box type of 'connected' always have a collision box specified
--]]
for node_name, node_def in pairs(core.registered_nodes) do
	debug(flag4, "\n  node_name: " .. node_name)

	if node_name == "air" then
		ss.NODE_NAMES_NONSOLID_DIGGABLE[node_name] = true
		debug(flag4, "    added to NODE_NAMES_NONSOLID_DIGGABLE")

	elseif node_name == "ignore" then
		ss.NODE_NAMES_NONSOLID_NONDIGGABLE[node_name] = true
		debug(flag4, "    added to NODE_NAMES_NONSOLID_NONDIGGABLE")

	elseif core.get_item_group(node_name, "water") > 0 then
		ss.NODE_NAMES_WATER[node_name] = true
		debug(flag4, "    added to NODE_NAMES_WATER")

	elseif core.get_item_group(node_name, "lava") > 0 then
		ss.NODE_NAMES_LAVA[node_name] = true
		debug(flag4, "    added to NODE_NAMES_LAVA")

	elseif core.get_item_group(node_name, "stair") > 0 then
		debug(flag4, "    this is a stair")
		ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT[node_name] = true
		debug(flag4, "    added to NODE_NAMES_SOLID_VARIABLE_HEIGHT")

	elseif core.get_item_group(node_name, "slab") > 0 then
		debug(flag4, "    this is a slab")
		ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT[node_name] = true
		debug(flag4, "    added to NODE_NAMES_SOLID_VARIABLE_HEIGHT")

	elseif node_def.drawtype == "plantlike_rooted" then
		debug(flag4, "    this is an underwater plantlike_rooted node")
		ss.NODE_NAMES_PLANTLIKE_ROOTED[node_name] = true
		debug(flag4, "    added to NODE_NAMES_NONSOLID_NONDIGGABLE")

	elseif node_def.walkable == false then
		if node_def.buildable_to == true then
			ss.NODE_NAMES_NONSOLID_DIGGABLE[node_name] = true
			debug(flag4, "    added to NODE_NAMES_NONSOLID_DIGGABLE")
		else
			ss.NODE_NAMES_NONSOLID_NONDIGGABLE[node_name] = true
			debug(flag4, "    added to NODE_NAMES_NONSOLID_NONDIGGABLE")
		end

	else

		local name_tokens = string.split(node_name, ":")
		debug(flag4, "    name_tokens: " .. dump(name_tokens))
		local sub_name = name_tokens[2]
		debug(flag4, "    sub_name: " .. sub_name)
		if string.sub(sub_name, 1, 11) == "fence_rail_" then
			ss.NODE_NAMES_GAPPY_NONDIGGABLE[node_name] = true
			debug(flag4, "    added to NODE_NAMES_GAPPY_NONDIGGABLE")

		elseif string.sub(sub_name, 1, 6) == "fence_" then
			ss.NODE_NAMES_SOLID_CUBE[node_name] = true
			debug(flag4, "    added to NODE_NAMES_SOLID_CUBE")

		elseif string.sub(sub_name, 1, 9) == "campfire_" then
			ss.NODE_NAMES_GAPPY_NONDIGGABLE[node_name] = true
			debug(flag4, "    added to NODE_NAMES_GAPPY_NONDIGGABLE")

		else

			local selection_box = node_def.selection_box
			if selection_box then
				local s_type = selection_box.type
				debug(flag4, "    has selection_box type: " .. s_type)

				-- typical solid nodes
				if s_type == "regular" then
					ss.NODE_NAMES_SOLID_CUBE[node_name] = true
					debug(flag4, "    added to NODE_NAMES_SOLID_CUBE")

				-- signs, torches, and ladders
				elseif s_type == "wallmounted" then
					ss.NODE_NAMES_GAPPY_NONDIGGABLE[node_name] = true
					debug(flag4, "    added to NODE_NAMES_GAPPY_NONDIGGABLE")

				-- currently no nodes are using this nodebox type
				elseif s_type == "leveled" then

				-- any other nodes not already handled
				elseif s_type == "fixed" or s_type == "connected" then
					debug(flag4, "    *** selection box type of FIXED ***")
					debug(flag4, "    selection_box: " .. dump(selection_box))

					local is_gappy_height = false
					local is_variable_height = false

					local fixed_box = selection_box.fixed
					local first_element = fixed_box[1]
					if type(first_element) == "table" then
						debug(flag4, "    first_element is a table:" .. dump(first_element))

						for i, sbox in ipairs(fixed_box) do

							local fifth_element = sbox[5]
							debug(flag4, "    fifth_element:" .. fifth_element)

							if fifth_element < 0.5 then
								debug(flag4, "    *** gappy height found *** ")
								is_gappy_height = true

							else
								if is_gappy_height then
									debug(flag4, "    previous sbox hight was gappy, but this one is not.")
									debug(flag4, "    *** VARIABLE height node found ***")
									is_variable_height = true
								end
							end
						end

					else
						debug(flag4, "    first_element is a value:" .. first_element)

						local fifth_element = fixed_box[5]
						debug(flag4, "    fifth_element:" .. fifth_element)
						if fifth_element < 0.5 then
							debug(flag4, "    *** gappy height found *** ")
							is_gappy_height = true
						else
							if is_gappy_height then
								debug(flag4, "    previous sbox hight was gappy, but this one is not.")
								debug(flag4, "    *** VARIABLE height node found ***")
								is_variable_height = true
							end
						end
					end

					if is_variable_height then
						ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT[node_name] = true
						debug(flag4, "    added to NODE_NAMES_SOLID_VARIABLE_HEIGHT")
					else
						if is_gappy_height then
							if node_def.buildable_to == true then
								ss.NODE_NAMES_GAPPY_DIGGABLE[node_name] = true
								debug(flag4, "    added to NODE_NAMES_GAPPY_DIGGABLE")
							else
								ss.NODE_NAMES_GAPPY_NONDIGGABLE[node_name] = true
								debug(flag4, "    added to NODE_NAMES_GAPPY_NONDIGGABLE")
							end
						end
					end

				else
					debug(flag4, "    ERROR - Unexpected 's_type' value: " .. s_type)
				end
			end
		end
	end

end
--[[
print("NODE_NAMES_SOLID_CUBE: " .. dump(ss.NODE_NAMES_SOLID_CUBE))
print("NODE_NAMES_SOLID_VARIABLE_HEIGHT: " .. dump(ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT))
print("NODE_NAMES_GAPPY_DIGGABLE: " .. dump(ss.NODE_NAMES_GAPPY_DIGGABLE))
print("NODE_NAMES_GAPPY_NONDIGGABLE: " .. dump(ss.NODE_NAMES_GAPPY_NONDIGGABLE))
print("NODE_NAMES_PLANTLIKE_ROOTED: " .. dump(ss.NODE_NAMES_PLANTLIKE_ROOTED))
print("NODE_NAMES_WATER: " .. dump(ss.NODE_NAMES_WATER))
print("NODE_NAMES_LAVA: " .. dump(ss.NODE_NAMES_LAVA))
print("NODE_NAMES_NONSOLID_DIGGABLE: " .. dump(ss.NODE_NAMES_NONSOLID_DIGGABLE))
print("NODE_NAMES_NONSOLID_NONDIGGABLE: " .. dump(ss.NODE_NAMES_NONSOLID_NONDIGGABLE))
--]]

--[[ #### combine all 'solid' and 'gappy' tables into NODE_NAMES_SOLID_ALL --]]
for node_name in pairs(ss.NODE_NAMES_SOLID_CUBE) do
	ss.NODE_NAMES_SOLID_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT) do
	ss.NODE_NAMES_SOLID_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_GAPPY_DIGGABLE) do
	ss.NODE_NAMES_SOLID_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_GAPPY_NONDIGGABLE) do
	ss.NODE_NAMES_SOLID_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_PLANTLIKE_ROOTED) do
	ss.NODE_NAMES_SOLID_ALL[node_name] = true
end
--print("NODE_NAMES_SOLID_ALL: " .. dump(ss.NODE_NAMES_SOLID_ALL))

--[[ #### combine both 'gappy' tables into NODE_NAMES_GAPPY_ALL --]]
for node_name in pairs(ss.NODE_NAMES_GAPPY_DIGGABLE) do
	ss.NODE_NAMES_GAPPY_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_GAPPY_NONDIGGABLE) do
	ss.NODE_NAMES_GAPPY_ALL[node_name] = true
end
--print("NODE_NAMES_GAPPY_ALL: " .. dump(ss.NODE_NAMES_GAPPY_ALL))

--[[ #### combine all 'nonsolid' tables into NODE_NAMES_NONSOLID_ALL --]]
for node_name in pairs(ss.NODE_NAMES_NONSOLID_DIGGABLE) do
	ss.NODE_NAMES_NONSOLID_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_NONSOLID_NONDIGGABLE) do
	ss.NODE_NAMES_NONSOLID_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_WATER) do
	ss.NODE_NAMES_NONSOLID_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_LAVA) do
	ss.NODE_NAMES_NONSOLID_ALL[node_name] = true
end
--print("NODE_NAMES_NONSOLID_ALL: " .. dump(ss.NODE_NAMES_NONSOLID_ALL))

--[[ #### combine all 'diggable' tables into NODE_NAMES_DIGGABLE_ALL --]]
for node_name in pairs(ss.NODE_NAMES_GAPPY_DIGGABLE) do
	ss.NODE_NAMES_DIGGABLE_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_NONSOLID_DIGGABLE) do
	ss.NODE_NAMES_DIGGABLE_ALL[node_name] = true
end
--print("NODE_NAMES_DIGGABLE_ALL: " .. dump(ss.NODE_NAMES_DIGGABLE_ALL))

--[[ #### combine all 'nondiggable' tables into NODE_NAMES_DIGGABLE_ALL --]]
for node_name in pairs(ss.NODE_NAMES_SOLID_CUBE) do
	ss.NODE_NAMES_NONDIGGABLE_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_SOLID_VARIABLE_HEIGHT) do
	ss.NODE_NAMES_NONDIGGABLE_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_GAPPY_NONDIGGABLE) do
	ss.NODE_NAMES_NONDIGGABLE_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_PLANTLIKE_ROOTED) do
	ss.NODE_NAMES_NONDIGGABLE_ALL[node_name] = true
end
for node_name in pairs(ss.NODE_NAMES_NONSOLID_NONDIGGABLE) do
	ss.NODE_NAMES_NONDIGGABLE_ALL[node_name] = true
end
--print("NODE_NAMES_NONDIGGABLE_ALL: " .. dump(ss.NODE_NAMES_NONDIGGABLE_ALL))

--[[ #### combine all nodes that are never allowed no exception to be dug up by
itemdrop bag spawn and store into table NODE_NAMES_NONDIGGABLE_EVER --]]
for node_name in pairs(ss.CAMPFIRE_NODE_NAMES) do
	ss.NODE_NAMES_NONDIGGABLE_EVER[node_name] = true
end
for node_name in pairs(ss.BAG_NODE_NAMES_ALL) do
	ss.NODE_NAMES_NONDIGGABLE_EVER[node_name] = true
end
for node_name in pairs(ss.ITEMDROP_BAGS_ALL) do
	ss.NODE_NAMES_NONDIGGABLE_EVER[node_name] = true
end
--print("NODE_NAMES_NONDIGGABLE_EVER: " .. dump(ss.NODE_NAMES_NONDIGGABLE_EVER))




--[[ #### initialize ss.CAMPFIRE_NODE_NAMES, ss.CAMPFIRE_STAND_NAMES, ss.CAMPFIRE_GRILL_NAMES,
ss.FIRE_STARTER_NAMES --]]

local table_map = {
	CAMPFIRE_NODE_NAMES = ss.CAMPFIRE_NODE_NAMES,
    CAMPFIRE_STAND_NAMES = ss.CAMPFIRE_STAND_NAMES,
    CAMPFIRE_GRILL_NAMES = ss.CAMPFIRE_GRILL_NAMES,
    FIRE_STARTER_NAMES = ss.FIRE_STARTER_NAMES,
}

local flag2 = false
local file_path = core.get_modpath("ss") .. "/campfire_data.txt"
local file = io.open(file_path, "r")
if not file then
	debug(flag2, "  Could not open file: " .. file_path)
	return
end
local blank_line_found = false
local table_name
for line in file:lines() do
	-- Trim whitespace from the line
	line = line:match("^%s*(.-)%s*$")
	debug(flag2, "line: " .. line)
	if line == "" then
		debug(flag2, "  blank line")
		blank_line_found = true
	elseif line:match("^#") then
		debug(flag2, "  comment line")
	else
		-- table name line
		if blank_line_found then
			local line_tokens = string.split(line)
			table_name = line_tokens[1]
			debug(flag2, "  table_name: " .. table_name)
			blank_line_found = false
		-- item name line
		else
			debug(flag2, "  item name. will add to table name: " .. table_name)
			table_map[table_name][line] = true
		end
	end
end
file:close()
--print("  ss.CAMPFIRE_NODE_NAMES: " .. dump(ss.CAMPFIRE_NODE_NAMES))
--print("  ss.CAMPFIRE_STAND_NAMES: " .. dump(ss.CAMPFIRE_STAND_NAMES))
--print("  ss.CAMPFIRE_GRILL_NAMES: " .. dump(ss.CAMPFIRE_GRILL_NAMES))
--print("  ss.FIRE_STARTER_NAMES: " .. dump(ss.FIRE_STARTER_NAMES))