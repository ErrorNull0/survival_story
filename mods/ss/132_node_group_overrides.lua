<<<<<<< HEAD
print("- loading overrides_node_groups.lua")

-- Change node digging times to mach cusome tool groupcaps (refer to tools.lua)

local nodeGroups = {}
local nodeNames = {}


-- ** 'SNAPPY' GROUP **

-- MUSHROOMS
nodeNames = {"mushroom_brown", "mushroom_red"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["flowers:" .. v].groups
	nodeGroups.snappy = 9
	minetest.override_item("flowers:" .. v, { groups = nodeGroups })
end

-- FLOWERS / WATERLILY
nodeNames = {"rose", "tulip", "dandelion_yellow", "chrysanthemum_green", "geranium", "viola", "dandelion_white", "tulip_black", "waterlily", "waterlily_waving"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["flowers:" .. v].groups
	nodeGroups.snappy = 7
	minetest.override_item("flowers:" .. v, { groups = nodeGroups })
end

-- SMALLER GRASS
nodeNames = {"grass_1", "grass_2", "dry_grass_1", "dry_grass_2"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.snappy = 7
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- LARGER GRASS / MARRAN GRASS / JUNGLE GRASS
nodeNames = {"grass_3", "grass_4", "grass_5", "dry_grass_3", "dry_grass_4", "dry_grass_5", "marram_grass_1", "marram_grass_2", "marram_grass_3", "junglegrass"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.snappy = 5
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- LEAVES / FERNS / DRY SHRUB
nodeNames = {"leaves", "jungleleaves", "pine_needles", "acacia_leaves", "aspen_leaves", "fern_1", "fern_2", "fern_3", "dry_shrub"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.snappy = 3
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- SAPLINGS
nodeNames = {"sapling", "junglesapling", "emergent_jungle_sapling", "pine_sapling", "acacia_sapling", "aspen_sapling", "bush_sapling", "acacia_bush_sapling", "pine_bush_sapling", "blueberry_bush_sapling", "large_cactus_seedling"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.snappy = 2
	nodeGroups.dig_immediate = nil
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- PAPYRUS
nodeGroups = minetest.registered_items["default:papyrus"].groups
nodeGroups.snappy = 2
minetest.override_item("default:papyrus", { groups = nodeGroups })



-- ** 'CRUMBLY' GROUP **

-- SAND / SNOW BLOCK
nodeNames = {"sand", "desert_sand", "silver_sand", "snowblock"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.crumbly = 8
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- GRAVEL
nodeGroups = minetest.registered_items["default:gravel"].groups
nodeGroups.crumbly = 7
minetest.override_item("default:gravel", { groups = nodeGroups })

-- DIRT
nodeNames = {"dirt", "dirt_with_grass", "dirt_with_grass_footsteps", "dirt_with_dry_grass", "dirt_with_snow", "dirt_with_rainforest_litter", "dirt_with_coniferous_litter"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.crumbly = 5
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- DRY DIRT
nodeNames = {"dry_dirt", "dry_dirt_with_dry_grass"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.crumbly = 4
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- PERMAFROST
nodeGroups = minetest.registered_items["default:permafrost"].groups
nodeGroups.crumbly = 3
minetest.override_item("default:permafrost", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:permafrost_with_moss"].groups
nodeGroups.crumbly = 3
minetest.override_item("default:permafrost_with_moss", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:permafrost_with_stones"].groups
nodeGroups.crumbly = 2
minetest.override_item("default:permafrost_with_stones", { groups = nodeGroups })


-- ** 'CHOPPY' GROUP **

-- BUSH STEM
nodeGroups = minetest.registered_items["default:pine_bush_stem"].groups
nodeGroups.choppy = 9
minetest.override_item("default:pine_bush_stem", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:bush_stem"].groups
nodeGroups.choppy = 8
minetest.override_item("default:bush_stem", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:acacia_bush_stem"].groups
nodeGroups.choppy = 7
minetest.override_item("default:acacia_bush_stem", { groups = nodeGroups })

-- MESE POST LIGHTS
nodeGroups = minetest.registered_items["default:mese_post_light_pine_wood"].groups
nodeGroups.choppy = 9
minetest.override_item("default:mese_post_light_pine_wood", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:mese_post_light"].groups
nodeGroups.choppy = 8
minetest.override_item("default:mese_post_light", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:mese_post_light_aspen_wood"].groups
nodeGroups.choppy = 8
minetest.override_item("default:mese_post_light_aspen_wood", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:mese_post_light_acacia_wood"].groups
nodeGroups.choppy = 7
minetest.override_item("default:mese_post_light_acacia_wood", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:mese_post_light_junglewood"].groups
nodeGroups.choppy = 6
minetest.override_item("default:mese_post_light_junglewood", { groups = nodeGroups })

-- TREES
nodeGroups = minetest.registered_items["default:pine_tree"].groups
nodeGroups.choppy = 5
minetest.override_item("default:pine_tree", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:tree"].groups
nodeGroups.choppy = 4
minetest.override_item("default:tree", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:aspen_tree"].groups
nodeGroups.choppy = 4
minetest.override_item("default:aspen_tree", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:acacia_tree"].groups
nodeGroups.choppy = 3
minetest.override_item("default:acacia_tree", { groups = nodeGroups })

nodeGroups = minetest.registered_items["default:jungletree"].groups
nodeGroups.choppy = 2
minetest.override_item("default:jungletree", { groups = nodeGroups })

-- FENCES

nodeGroups = minetest.registered_items["default:fence_wood"].groups
nodeGroups.choppy = 6
minetest.override_item("default:fence_wood", { groups = nodeGroups })




-- ** 'CRACKY' GROUP **

-- SANDSTONE
nodeNames = {"sandstone", "desert_sandstone", "silver_sandstone"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.cracky = 9 -- 5 seconds w/ stone pickaxe
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- SANDSTONE BRICK
nodeNames = {"default:sandstonebrick", "default:desert_sandstone_brick", "default:silver_sandstone_brick"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items[v].groups
	nodeGroups.cracky = 8
	minetest.override_item(v, { groups = nodeGroups })
end

-- SANDSTONE BLOCK
nodeNames = {"default:sandstone_block", "default:desert_sandstone_block", "default:silver_sandstone_block"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items[v].groups
	nodeGroups.cracky = 7
	minetest.override_item(v, { groups = nodeGroups })
end

-- COBBLESTONE
nodeNames = {"cobble", "mossycobble", "desert_cobble"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.cracky = 6
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- STONE
nodeNames = {"stone", "desert_stone"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.cracky = 5
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- STONE BRICK
nodeNames = {"stonebrick", "desert_stonebrick"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.cracky = 4
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end

-- STONE BLOCK
nodeNames = {"stone_block", "desert_stone_block"}
for i,v in ipairs(nodeNames) do
	nodeGroups = minetest.registered_items["default:" .. v].groups
	nodeGroups.cracky = 3
	minetest.override_item("default:" .. v, { groups = nodeGroups })
end


-- ** 'GLASSY' GROUP **

-- GLASS
nodeGroups = minetest.registered_items["default:glass"].groups
nodeGroups.glassy = 8
nodeGroups.oddly_breakable_by_hand = nil
minetest.override_item("default:glass", { groups = nodeGroups })

-- MESE LAMP
nodeGroups = minetest.registered_items["default:meselamp"].groups
nodeGroups.glassy = 6
nodeGroups.oddly_breakable_by_hand = nil
minetest.override_item("default:meselamp", { groups = nodeGroups })

-- OBSIDIAN GLASS
nodeGroups = minetest.registered_items["default:obsidian_glass"].groups
nodeGroups.glassy = 3
minetest.override_item("default:obsidian_glass", { groups = nodeGroups })


=======
print("- loading overrides_node_groups.lua")

-- Change node digging times to match custom tool groupcaps (refer to tools.lua)

local nodeGroups = {}
local nodeNames = {}


-- ** 'SNAPPY' GROUP **

-- MUSHROOMS
nodeNames = {"mushroom_brown", "mushroom_red"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["flowers:" .. v].groups
	nodeGroups.snappy = 9
	core.override_item("flowers:" .. v, { groups = nodeGroups })
end

-- FLOWERS / WATERLILY
nodeNames = {"rose", "tulip", "dandelion_yellow", "chrysanthemum_green", "geranium", "viola", "dandelion_white", "tulip_black", "waterlily", "waterlily_waving"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["flowers:" .. v].groups
	nodeGroups.snappy = 7
	core.override_item("flowers:" .. v, { groups = nodeGroups })
end

-- SMALLER GRASS
nodeNames = {"grass_1", "grass_2", "dry_grass_1", "dry_grass_2"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.snappy = 7
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- LARGER GRASS / MARRAN GRASS / JUNGLE GRASS
nodeNames = {"grass_3", "grass_4", "grass_5", "dry_grass_3", "dry_grass_4", "dry_grass_5", "marram_grass_1", "marram_grass_2", "marram_grass_3", "junglegrass"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.snappy = 5
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- LEAVES / FERNS / DRY SHRUB
nodeNames = {"leaves", "jungleleaves", "pine_needles", "acacia_leaves", "aspen_leaves", "fern_1", "fern_2", "fern_3", "dry_shrub"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.snappy = 3
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- SAPLINGS
nodeNames = {"sapling", "junglesapling", "emergent_jungle_sapling", "pine_sapling", "acacia_sapling", "aspen_sapling", "bush_sapling", "acacia_bush_sapling", "pine_bush_sapling", "blueberry_bush_sapling", "large_cactus_seedling"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.snappy = 2
	nodeGroups.dig_immediate = nil
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- PAPYRUS
nodeGroups = core.registered_items["default:papyrus"].groups
nodeGroups.snappy = 2
core.override_item("default:papyrus", { groups = nodeGroups })



-- ** 'CRUMBLY' GROUP **

-- SAND / SNOW BLOCK
nodeNames = {"sand", "desert_sand", "silver_sand", "snowblock"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.crumbly = 8
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- GRAVEL
nodeGroups = core.registered_items["default:gravel"].groups
nodeGroups.crumbly = 7
core.override_item("default:gravel", { groups = nodeGroups })

-- DIRT
nodeNames = {"dirt", "dirt_with_grass", "dirt_with_grass_footsteps", "dirt_with_dry_grass", "dirt_with_snow", "dirt_with_rainforest_litter", "dirt_with_coniferous_litter"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.crumbly = 5
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- DRY DIRT
nodeNames = {"dry_dirt", "dry_dirt_with_dry_grass"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.crumbly = 4
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- PERMAFROST
nodeGroups = core.registered_items["default:permafrost"].groups
nodeGroups.crumbly = 3
core.override_item("default:permafrost", { groups = nodeGroups })

nodeGroups = core.registered_items["default:permafrost_with_moss"].groups
nodeGroups.crumbly = 3
core.override_item("default:permafrost_with_moss", { groups = nodeGroups })

nodeGroups = core.registered_items["default:permafrost_with_stones"].groups
nodeGroups.crumbly = 2
core.override_item("default:permafrost_with_stones", { groups = nodeGroups })


-- ** 'CHOPPY' GROUP **

-- BUSH STEM
nodeGroups = core.registered_items["default:pine_bush_stem"].groups
nodeGroups.choppy = 9
core.override_item("default:pine_bush_stem", { groups = nodeGroups })

nodeGroups = core.registered_items["default:bush_stem"].groups
nodeGroups.choppy = 8
core.override_item("default:bush_stem", { groups = nodeGroups })

nodeGroups = core.registered_items["default:acacia_bush_stem"].groups
nodeGroups.choppy = 7
core.override_item("default:acacia_bush_stem", { groups = nodeGroups })

-- MESE POST LIGHTS
nodeGroups = core.registered_items["default:mese_post_light_pine_wood"].groups
nodeGroups.choppy = 9
core.override_item("default:mese_post_light_pine_wood", { groups = nodeGroups })

nodeGroups = core.registered_items["default:mese_post_light"].groups
nodeGroups.choppy = 8
core.override_item("default:mese_post_light", { groups = nodeGroups })

nodeGroups = core.registered_items["default:mese_post_light_aspen_wood"].groups
nodeGroups.choppy = 8
core.override_item("default:mese_post_light_aspen_wood", { groups = nodeGroups })

nodeGroups = core.registered_items["default:mese_post_light_acacia_wood"].groups
nodeGroups.choppy = 7
core.override_item("default:mese_post_light_acacia_wood", { groups = nodeGroups })

nodeGroups = core.registered_items["default:mese_post_light_junglewood"].groups
nodeGroups.choppy = 6
core.override_item("default:mese_post_light_junglewood", { groups = nodeGroups })

-- TREES
nodeGroups = core.registered_items["default:pine_tree"].groups
nodeGroups.choppy = 5
core.override_item("default:pine_tree", { groups = nodeGroups })

nodeGroups = core.registered_items["default:tree"].groups
nodeGroups.choppy = 4
core.override_item("default:tree", { groups = nodeGroups })

nodeGroups = core.registered_items["default:aspen_tree"].groups
nodeGroups.choppy = 4
core.override_item("default:aspen_tree", { groups = nodeGroups })

nodeGroups = core.registered_items["default:acacia_tree"].groups
nodeGroups.choppy = 3
core.override_item("default:acacia_tree", { groups = nodeGroups })

nodeGroups = core.registered_items["default:jungletree"].groups
nodeGroups.choppy = 2
core.override_item("default:jungletree", { groups = nodeGroups })

-- FENCES

nodeGroups = core.registered_items["default:fence_wood"].groups
nodeGroups.choppy = 6
core.override_item("default:fence_wood", { groups = nodeGroups })




-- ** 'CRACKY' GROUP **

-- SANDSTONE
nodeNames = {"sandstone", "desert_sandstone", "silver_sandstone"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.cracky = 9 -- 5 seconds w/ stone pickaxe
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- SANDSTONE BRICK
nodeNames = {"default:sandstonebrick", "default:desert_sandstone_brick", "default:silver_sandstone_brick"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items[v].groups
	nodeGroups.cracky = 8
	core.override_item(v, { groups = nodeGroups })
end

-- SANDSTONE BLOCK
nodeNames = {"default:sandstone_block", "default:desert_sandstone_block", "default:silver_sandstone_block"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items[v].groups
	nodeGroups.cracky = 7
	core.override_item(v, { groups = nodeGroups })
end

-- COBBLESTONE
nodeNames = {"cobble", "mossycobble", "desert_cobble"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.cracky = 6
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- STONE
nodeNames = {"stone", "desert_stone"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.cracky = 5
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- STONE BRICK
nodeNames = {"stonebrick", "desert_stonebrick"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.cracky = 4
	core.override_item("default:" .. v, { groups = nodeGroups })
end

-- STONE BLOCK
nodeNames = {"stone_block", "desert_stone_block"}
for i,v in ipairs(nodeNames) do
	nodeGroups = core.registered_items["default:" .. v].groups
	nodeGroups.cracky = 3
	core.override_item("default:" .. v, { groups = nodeGroups })
end


-- ** 'GLASSY' GROUP **

-- GLASS
nodeGroups = core.registered_items["default:glass"].groups
nodeGroups.glassy = 8
nodeGroups.oddly_breakable_by_hand = nil
core.override_item("default:glass", { groups = nodeGroups })

-- MESE LAMP
nodeGroups = core.registered_items["default:meselamp"].groups
nodeGroups.glassy = 6
nodeGroups.oddly_breakable_by_hand = nil
core.override_item("default:meselamp", { groups = nodeGroups })

-- OBSIDIAN GLASS
nodeGroups = core.registered_items["default:obsidian_glass"].groups
nodeGroups.glassy = 3
core.override_item("default:obsidian_glass", { groups = nodeGroups })


>>>>>>> 7965987 (update to version 0.0.3)
