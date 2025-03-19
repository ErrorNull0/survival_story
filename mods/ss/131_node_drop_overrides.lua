<<<<<<< HEAD
print("- loading overrides_node_drops.lua")

-- cache global functions for faster access
local debug = ss.debug
local math_random = math.random
local mt_add_item = minetest.add_item
local update_meta_and_description = ss.update_meta_and_description

-- cache global variables for faster access+
local ITEM_MAX_USES = ss.ITEM_MAX_USES
local ITEM_SOUNDS_MISS = ss.ITEM_SOUNDS_MISS
local ITEM_POINTING_RANGES = ss.ITEM_POINTING_RANGES

local nodeNames = {}


-- BLUEBERRIES: ensure they drop a random amount, and 'remaining_uses' metadata is initialized
local item_blueberries = ItemStack("ss:blueberries")
update_meta_and_description(item_blueberries:get_meta(), "ss:blueberries", {"remaining_uses"}, {ITEM_MAX_USES["ss:blueberries"]})
local dig_node_backup_blueberries = minetest.registered_nodes["default:blueberry_bush_leaves_with_berries"].after_dig_node
minetest.override_item("default:blueberry_bush_leaves_with_berries", {
	drop = "", -- prevent default item drop behavior
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if dig_node_backup_blueberries then
			dig_node_backup_blueberries(pos, oldnode, oldmetadata, digger)
		end
		item_blueberries:set_count(math_random(3,6))
		mt_add_item(pos, item_blueberries)
	end
})


-- APPLES: ensure 'remaining_uses' metadata is initialized
local item_apple = ItemStack("ss:apple")
update_meta_and_description(item_apple:get_meta(), "ss:apple", {"remaining_uses"}, {ITEM_MAX_USES["ss:apple"]})
local dig_node_backup_apple = minetest.registered_nodes["default:apple"].after_dig_node
minetest.override_item("default:apple", {
	drop = "", -- prevent default item drop behavior
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if dig_node_backup_apple then
			dig_node_backup_apple(pos, oldnode, oldmetadata, digger)
		end
		mt_add_item(pos, item_apple)
	end
})


-- CACTUS: ensure 'remaining_uses' metadata is initialized
local item_cactus = ItemStack("ss:cactus")
update_meta_and_description(item_cactus:get_meta(), "ss:cactus", {"remaining_uses"}, {ITEM_MAX_USES["ss:cactus"]})
local dig_node_backup_cactus = minetest.registered_nodes["default:cactus"].after_dig_node
minetest.override_item("default:cactus", {
	drop = "", -- prevent default item drop behavior
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if dig_node_backup_cactus then
			dig_node_backup_cactus(pos, oldnode, oldmetadata, digger)
		end
		local drop_quantity
		local wield_item = digger:get_wielded_item()
		if wield_item == "default:axe_stone" then
			drop_quantity = 3
		elseif wield_item == "default:axe_bronze" then
			drop_quantity = 4
		elseif wield_item == "default:axe_steel" then
			drop_quantity = 4
		elseif wield_item == "default:axe_mese" then
			drop_quantity = 5
		elseif wield_item == "default:axe_diamond" then
			drop_quantity = 5
		elseif wield_item == "default:sword_admin" then
			drop_quantity = 5
		else
			-- using hands or any other tool like sharpened stone
			drop_quantity = 2
		end
		item_cactus:set_count(drop_quantity)
		mt_add_item(pos, item_cactus)

		local item_stick = ItemStack("ss:stick")
		if wield_item == "default:axe_stone" then
			drop_quantity = 2
		elseif wield_item == "default:axe_bronze" then
			drop_quantity = 3
		elseif wield_item == "default:axe_steel" then
			drop_quantity = 3
		elseif wield_item == "default:axe_mese" then
			drop_quantity = 4
		elseif wield_item == "default:axe_diamond" then
			drop_quantity = 4
		elseif wield_item == "default:sword_admin" then
			drop_quantity = 4
		else
			-- using hands or any other tool like sharpened stone
			drop_quantity = 2
		end
		item_stick:set_count(drop_quantity)
		mt_add_item(pos, item_stick)

	end
})



-- CACTUS SEEDLING: ensure 'remaining_uses' metadata is initialized
item_cactus = ItemStack("ss:cactus")
update_meta_and_description(item_cactus:get_meta(), "ss:cactus", {"remaining_uses"}, {1})
local dig_node_backup_cactus_seedling = minetest.registered_nodes["default:large_cactus_seedling"].after_dig_node
minetest.override_item("default:large_cactus_seedling", {
	drop = "", -- prevent default item drop behavior
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if dig_node_backup_cactus_seedling then
			dig_node_backup_cactus_seedling(pos, oldnode, oldmetadata, digger)
		end
		local drop_quantity
		local wield_item = digger:get_wielded_item()
		if wield_item == "default:axe_stone" then
			drop_quantity = 1
		elseif wield_item == "default:axe_bronze" then
			drop_quantity = 1
		elseif wield_item == "default:axe_steel" then
			drop_quantity = 1
		elseif wield_item == "default:axe_mese" then
			drop_quantity = 2
		elseif wield_item == "default:axe_diamond" then
			drop_quantity = 2
		elseif wield_item == "default:sword_admin" then
			drop_quantity = 2
		else
			-- using hands or any other tool like sharpened stone
			drop_quantity = 1
		end
		item_cactus:set_count(drop_quantity)
		mt_add_item(pos, item_cactus)
		mt_add_item(pos, ItemStack("ss:stick"))

	end
})


-- TORCHES: ensure all torch nodes drops itself if itemdrop bag spawns at its position,
-- also ensure torches makes the swing swoosh noise
nodeNames = {"default:torch", "default:torch_wall", "default:torch_ceiling"}
for i,v in ipairs(nodeNames) do
	minetest.override_item(v, {
		drop_bag = "default:torch",
		range = ITEM_POINTING_RANGES["default:torch"],
		sound = {
			punch_use_air = ITEM_SOUNDS_MISS["default:torch"]
		}
	})
end


-- GRASS: Drops grass clumps. Bigger grasses drop more. Bonus for using bladed tools.
nodeNames = {"grass", "dry_grass"}
for i,v in ipairs(nodeNames) do
	minetest.override_item("default:" .. v .. "_1", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 1"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
	minetest.override_item("default:" .. v .. "_2", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 1"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
	minetest.override_item("default:" .. v .. "_3", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 2"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
	minetest.override_item("default:" .. v .. "_4", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 2"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
	minetest.override_item("default:" .. v .. "_5", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 3"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
end

-- MARRAM GRASS: Drops marram grass clumps. Bigger grasses drop more. Bonus for using bladed tools.
minetest.override_item("default:marram_grass_1", {
	drop = {
		items = {
			{ items = {"ss:marram_grass_clump 3"} }, -- applies to any tool including hands
			{ items = {"ss:marram_grass_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})
minetest.override_item("default:marram_grass_2", {
	drop = {
		items = {
			{ items = {"ss:marram_grass_clump 3"} }, -- applies to any tool including hands
			{ items = {"ss:marram_grass_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})
minetest.override_item("default:marram_grass_3", {
	drop = {
		items = {
			{ items = {"ss:marram_grass_clump 4"} }, -- applies to any tool including hands
			{ items = {"ss:marram_grass_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})

-- JUNGLE GRASS: Drops jungle grass clumps. Bonus for using bladed tools.
minetest.override_item("default:junglegrass", {
	drop = {
		items = {
			{ items = {"ss:jungle_grass_clump 5"} }, -- applies to any tool including hands
			{ items = {"ss:jungle_grass_clump 2"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})

-- FERN: Drops fern leaves. Bigger ferns drop more. Bonus for using bladed tools.
minetest.override_item("default:fern_1", {
	drop = {
		items = {
			{ items = {"ss:leaves_fern 3"} }, -- applies to any tool including hands
			{ items = {"ss:leaves_fern 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})
minetest.override_item("default:fern_2", {
	drop = {
		items = {
			{ items = {"ss:leaves_fern 3"} }, -- applies to any tool including hands
			{ items = {"ss:leaves_fern 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})
minetest.override_item("default:fern_3", {
	drop = {
		items = {
			{ items = {"ss:leaves_fern 4"} }, -- applies to any tool including hands
			{ items = {"ss:leaves_fern 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})

-- DRY SHRUB: Drops sticks
minetest.override_item("default:dry_shrub", {
	drop = {
		items = {
			{ items = {"ss:stick"} }, -- applies to any tool including hands
			{ items = {"ss:stick"}, rarity = 2, },
			{ items = {"ss:stick"}, tool_groups = {"axe", "sword"} }
		}
	}
})

-- BUSH STEMS: Drops wood and sticks, and drops more when using axes, and further bonus with higher tier axes.
nodeNames = {"default:bush_stem", "default:acacia_bush_stem", "default:pine_bush_stem"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:wood", "ss:stick"} },
				{ items = {"ss:stick"}, rarity = 2, },
				{ items = {"ss:stick 1"}, tools = {"default:axe_stone"} },
				{ items = {"ss:stick 2"}, tools = {"default:axe_bronze"} },
				{ items = {"ss:stick 3"}, tools = {"default:axe_steel"} },
				{ items = {"ss:stick 3"}, tools = {"default:axe_mese"} },
				{ items = {"ss:stick 4"}, tools = {"default:axe_diamond"} },
				{ items = {"ss:stick 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end


-- WOODEN FENCE: Drops wood and drops more when using axes, and further bonus with higher tier axes.

minetest.override_item("default:fence_wood", {
	drop = {
		items = {
			{ items = {"ss:wood_plank 3"} }, -- applies to any tool except for hands, which cannot break.
			{ items = {"ss:wood_plank"}, rarity = 2, },
			{ items = {"ss:wood_plank"}, tools = {"default:axe_stone"} },
			{ items = {"ss:wood_plank"}, tools = {"default:axe_bronze"} },
			{ items = {"ss:wood_plank"}, tools = {"default:axe_steel"} },
			{ items = {"ss:wood_plank"}, tools = {"default:axe_mese"} },
		}
	}
})

minetest.override_item("stairs:slab_wood", {
	drop = {
		items = {
			{ items = {"ss:wood_plank 2"} }, -- applies to any tool except for hands, which cannot break.
			{ items = {"ss:wood_plank"}, rarity = 2, }
		}
	}
})


-- TREE: Drops wood and drops more when using axes, and further bonus with higher tier axes.
nodeNames = {"default:tree", "default:jungletree", "default:pine_tree", "default:acacia_tree", "default:aspen_tree"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:wood 3"} }, -- applies to any tool except for hands, which cannot break.
				{ items = {"ss:wood 1"}, tools = {"default:axe_stone"} },
				{ items = {"ss:wood 2"}, tools = {"default:axe_bronze"} },
				{ items = {"ss:wood 3"}, tools = {"default:axe_steel"} },
				{ items = {"ss:wood 3"}, tools = {"default:axe_mese"} },
				{ items = {"ss:wood 3"}, tools = {"ss:axe_diamond"} },
				{ items = {"ss:wood 3"}, tools = {"ss:sword_admin"} },
			}
		}
	})
end


-- DIRT: Drops dirt pile. Drops more when using shovels and more dirt with higher tier shovels. Also drops any resource from dirt nodes with any meaningful resource on the top surface.
nodeNames = {"default:dirt", "default:dirt_with_coniferous_litter", "default:dry_dirt"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:dirt_pile 4"} }, -- applies to any tool
				{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end
nodeNames = {"default:dirt_with_grass", "default:dirt_with_grass_footsteps"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:dirt_pile 3", "ss:grass_clump"} },
				{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
			}
		},
	})
end
nodeNames = {"default:dirt_with_dry_grass", "default:dry_dirt_with_dry_grass"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:dirt_pile 3", "ss:dry_grass_clump"} },
				{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end
minetest.override_item("default:dirt_with_rainforest_litter", {
	drop = {
		items = {
			{ items = {"ss:dirt_pile 3", "ss:leaves_dry_clump"} },
			{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})
minetest.override_item("default:dirt_with_snow", {
	drop = {
		items = {
			{ items = {"ss:dirt_pile 3", "ss:snow_pile"} },
			{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

minetest.override_item("default:snowblock", {
	drop = {
		items = {
			{ items = {"ss:snow_pile 4"} },
			{ items = {"ss:snow_pile 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:snow_pile 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:snow_pile 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:snow_pile 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:snow_pile 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:snow_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

minetest.override_item("default:ice", {
	drop = {
		items = {
			{ items = {"ss:ice 4"} },
			{ items = {"ss:ice 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:ice 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:ice 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:ice 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:ice 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:ice 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

minetest.override_item("default:cave_ice", {
	drop = {
		items = {
			{ items = {"ss:ice 5"} },
			{ items = {"ss:ice 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:ice 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:ice 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:ice 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:ice 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:ice 3"}, tools = {"ss:sword_admin"} }
		}
	}
})


-- PERMAFROST: Drops permafrost dirt pile. Drops more when using pickaxe and more dirt with higher tier pickaxes.
minetest.override_item("default:permafrost", {
	drop = {
		items = {
			{ items = {"ss:dirt_permafrost_pile 4"} }, -- applies to any tool
			{ items = {"ss:dirt_permafrost_pile 1"}, tools = {"default:pick_stone"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_bronze"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_steel"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_mese"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_diamond"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

-- PERMAFROST W/ MOSS: Drops permafrost dirt pile and stone pile. Drops more when using pickaxe and more dirt with higher tier pickaxes.
minetest.override_item("default:permafrost_with_moss", {
	drop = {
		items = {
			{ items = {"ss:dirt_permafrost_pile 3", "ss:moss"} }, -- applies to any tool
			{ items = {"ss:dirt_permafrost_pile 1"}, tools = {"default:pick_stone"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_bronze"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_steel"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_mese"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_diamond"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

-- PERMAFROST W/ STONES: Drops permafrost dirt pile and stone pile. Drops more when using pickaxe and more dirt with higher tier pickaxes.
minetest.override_item("default:permafrost_with_stones", {
	drop = {
		items = {
			{ items = {"ss:dirt_permafrost_pile 3", "ss:stone_pile"} }, -- applies to any tool
			{ items = {"ss:dirt_permafrost_pile 1"}, tools = {"default:pick_stone"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_bronze"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_steel"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_mese"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_diamond"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

-- STONE / DESERT STONE: Drops stone or desert stone piles and drops more when using pickaxe, and further bonus with higher tier pickaxe.
nodeNames = {"stone", "desert_stone"}
for i,v in ipairs(nodeNames) do
	minetest.override_item("default:" .. v, {
		drop = {
			items = {
				{ items = {"ss:stone 2"} }, -- applies to any tool except for hands, which cannot break.
				{ items = {"ss:stone 2"}, tools = {"default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 1"}, tools = {"default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 1"}, tools = {"default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- STONE BRICK AND DESERT STONE BRICK: Same as Stone / Desert Stone (Above) but +2 mre stone / desert stone piles.
nodeNames = {"stone", "desert_stone"}
for i,v in ipairs(nodeNames) do
	minetest.override_item("default:" .. v .. "brick", {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 6"} }, -- applies to any tool except for hands, which cannot break.
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- STONE BLOCK AND DESERT STONE BLOCK: Same as Stone / Desert Stone (Above) but +2 mre stone / desert stone piles.
nodeNames = {"stone", "desert_stone"}
for i,v in ipairs(nodeNames) do
	minetest.override_item("default:" .. v .. "_block", {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 6"} }, -- applies to any tool except for hands, which cannot break.
                { items = {"ss:" .. v .. "_pile 2"}, tools = {"default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- COBBLE: Drops stone pile and drops more when using pickaxe, and further bonus with higher tier pickaxe.
nodeNames = {"default:cobble", "default:mossycobble"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:stone_pile 2"} }, -- applies to any tool except for hands, which cannot break.
				{ items = {"ss:stone_pile 1"}, tools = {"default:pick_stone"} },
				{ items = {"ss:stone_pile 2"}, tools = {"default:pick_bronze"} },
				{ items = {"ss:stone_pile 2"}, tools = {"default:pick_steel"} },
				{ items = {"ss:stone_pile 3"}, tools = {"default:pick_mese"} },
				{ items = {"ss:stone_pile 3"}, tools = {"default:pick_diamond"} },
				{ items = {"ss:stone_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- DESERT COBBLE: Drops desert stone pile and drops more when using pickaxe, and further bonus with higher tier pickaxe.
minetest.override_item("default:desert_cobble", {
	drop = {
		items = {
			{ items = {"ss:desert_stone_pile 2"} }, -- applies to any tool except for hands, which cannot break.
			{ items = {"ss:desert_stone_pile 1"}, tools = {"default:pick_stone"} },
			{ items = {"ss:desert_stone_pile 2"}, tools = {"default:pick_bronze"} },
			{ items = {"ss:desert_stone_pile 2"}, tools = {"default:pick_steel"} },
			{ items = {"ss:desert_stone_pile 3"}, tools = {"default:pick_mese"} },
			{ items = {"ss:desert_stone_pile 3"}, tools = {"default:pick_diamond"} },
			{ items = {"ss:desert_stone_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

-- SAND: Drops sand piles and drops more when using shovels, and further bonus with higher tier shovels.
nodeNames = {"sand", "desert_sand", "silver_sand"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("default:" .. v, {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 4"} }, -- applies to any tool
				{ items = {"ss:" .. v .. "_pile 1"}, tools = {"default:shovel_stone"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_bronze"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_steel"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_mese"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_diamond"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- SANDSTONE: Drops sandstone piles and drops more when using shovels, and further bonus with higher tier shovels.
nodeNames = {"sandstone", "desert_sandstone", "silver_sandstone"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("default:" .. v, {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 4"} }, -- applies to any tool
				{ items = {"ss:" .. v .. "_pile 1"}, tools = {"default:shovel_stone", "default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_steel", "default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_mese", "default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- SANDSTONE BRICKS: Same pattern as sandstone, but drops +2 more sandstone piles.
minetest.override_item("default:sandstonebrick", {
	drop = {
		items = {
			{ items = {"ss:sandstone_pile 6"} }, -- applies to any tool
			{ items = {"ss:sandstone_pile 2"}, tools = {"default:shovel_stone", "default:pick_stone"} },
			{ items = {"ss:sandstone_pile 3"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
			{ items = {"ss:sandstone_pile 3"}, tools = {"default:shovel_steel", "default:pick_steel"} },
			{ items = {"ss:sandstone_pile 4"}, tools = {"default:shovel_mese", "default:pick_mese"} },
			{ items = {"ss:sandstone_pile 4"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
			{ items = {"ss:sandstone_pile 4"}, tools = {"ss:sword_admin"} }
		}
	}
})
nodeNames = {"desert_sandstone", "silver_sandstone"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("default:" .. v .. "_brick", {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 6"} }, -- applies to any tool
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_stone", "default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_steel", "default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:shovel_mese", "default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- SANDSTONE BLOCKS: Same pattern as sandstone, but drops +2 more sandstone piles.
nodeNames = {"sandstone", "desert_sandstone", "silver_sandstone"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("default:" .. v .. "_block", {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 6"} }, -- applies to any tool
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_stone", "default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_steel", "default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:shovel_mese", "default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end


-- CLARY
minetest.override_item("default:clay", {
	drop = {
		items = {
			{ items = {"ss:clay"} },
			{ items = {"ss:clay 1"}, tools = {"default:shovel_stone", "default:pick_stone"} },
			{ items = {"ss:clay 2"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
			{ items = {"ss:clay 2"}, tools = {"default:shovel_steel", "default:pick_steel"} },
			{ items = {"ss:clay 3"}, tools = {"default:shovel_mese", "default:pick_mese"} },
			{ items = {"ss:clay 3"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
			{ items = {"ss:clay 3"}, tools = {"ss:sword_admin"} }
		}
	}
})


-- LEAVES / BUSH LEAVES: Drops clumps of leaves and drops more when using axe or swords, and further bonus with higher tier axes and swords.
nodeNames = {"leaves", "jungleleaves", "acacia_leaves", "aspen_leaves", "bush_leaves", "acacia_bush_leaves", "blueberry_bush_leaves"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("default:" .. v, {
		drop = {
			items = {
				{ items = {"ss:leaves_clump 4"} },
				{ items = {"ss:stick"}, rarity = 5 },
				{ items = {"ss:leaves_clump 1"}, tools = {"default:axe_stone", "default:sword_stone"} },
				{ items = {"ss:leaves_clump 2"}, tools = {"default:axe_bronze", "default:sword_bronze"} },
				{ items = {"ss:leaves_clump 2"}, tools = {"default:axe_steel", "default:sword_steel"} },
				{ items = {"ss:leaves_clump 3"}, tools = {"default:axe_mese", "default:sword_mese"} },
				{ items = {"ss:leaves_clump 4"}, tools = {"default:axe_diamond", "default:sword_diamond"} },
				{ items = {"ss:leaves_clump 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end


-- PINE NEEDLES: Drops pine needles.
nodeNames = {"pine_needles", "pine_bush_needles"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("default:" .. v, { 
		drop = {
			items = {
				{ items = {"ss:pine_needles 4"} },
				{ items = {"ss:stick"}, rarity = 5 },
				{ items = {"ss:pine_needles 1"}, tools = {"default:axe_stone", "default:sword_stone"} },
				{ items = {"ss:pine_needles 2"}, tools = {"default:axe_bronze", "default:sword_bronze"} },
				{ items = {"ss:pine_needles 2"}, tools = {"default:axe_steel", "default:sword_steel"} },
				{ items = {"ss:pine_needles 3"}, tools = {"default:axe_mese", "default:sword_mese"} },
				{ items = {"ss:pine_needles 4"}, tools = {"default:axe_diamond", "default:sword_diamond"} },
				{ items = {"ss:pine_needles 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- 	SAPLINGS: Drops leaves and a stick.
nodeNames = {"sapling", "junglesapling", "emergent_jungle_sapling", "acacia_sapling", "aspen_sapling"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("default:" .. v, { 
		drop = {
			items = {
				{ items = {"ss:leaves_clump"} },
				{ items = {"ss:stick"} }
			}
		}
	})
end

-- PINE SAPLING
minetest.override_item("default:pine_sapling", {
	drop = {
		items = {
			{ items = {"ss:pine_needles"} },
			{ items = {"ss:stick"} }
		}
	}
})

-- BUSH SAPLINGS: Drops only leaves.
nodeNames = {"bush_sapling", "acacia_bush_sapling", "blueberry_bush_sapling"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("default:" .. v, {
		drop = "ss:leaves_clump"
	})
end

-- PINE BUSH SAPLING
minetest.override_item("default:pine_bush_sapling", {
	drop = "ss:pine_needles"
})

-- PAPYRUS SALKS
minetest.override_item("default:papyrus", {
	drop = {
		items = {
			{ items = {"ss:papyrus 2"} }, -- default base quantity
			{ items = {"ss:papyrus 1"}, tools = {"default:axe_stone"} },
			{ items = {"ss:papyrus 1"}, tools = {"default:axe_bronze"} },
			{ items = {"ss:papyrus 1"}, tools = {"default:axe_steel"} },
			{ items = {"ss:papyrus 2"}, tools = {"default:axe_mese"} },
			{ items = {"ss:papyrus 2"}, tools = {"ss:axe_diamond"} },
			{ items = {"ss:papyrus 2"}, tools = {"ss:sword_admin"} },
		}
	}
})


-- FLOWERS: Drops picked version of themselves. Drops the full flower node that's plantable if using a shovel.
nodeNames = {"rose", "tulip", "dandelion_yellow", "chrysanthemum_green", "geranium", "viola", "dandelion_white", "tulip_black"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("flowers:" .. v, {
		drop = {
			max_items = 1,
			items = {
				{ items = {"ss:flower_" .. v}, tool_groups = {"shovel"} },
				{ items = {"ss:flower_" .. v}, tools = {"ss:sword_admin"} },
				{ items = {"ss:flower_" .. v .. "_picked"} }
			}
		}
	})
end

-- MUSHROOMS: Drops picked version of themselves. Unlike flowers, does not have plantable version - needs spores/seeds to plant.
nodeNames = {"mushroom_brown", "mushroom_red"}
for i,v in ipairs(nodeNames) do 
	minetest.override_item("flowers:" .. v, {
		drop = "ss:" .. v
	})
end

-- WATERLILY: Modify to drop craftitem version of lily and not the node, as well as a chance for lily flower.
minetest.override_item("flowers:waterlily", {
	drop = {
		items = {
			{ items = {"ss:flower_waterlily"} },
			{ items = {"ss:flower_waterlily_flower"}, rarity = 2, }
		}
	},
})
minetest.override_item("flowers:waterlily_waving", {
	drop = {
		items = {
			{ items = {"ss:flower_waterlily"} },
			{ items = {"ss:flower_waterlily_flower"}, rarity = 2, }
		}
	},
})


-- CORAL: digging cyan, green, and pink coral drops its corresponding craftitem,
-- while digging brown, orange, and skeleton coral will drop skeleton coral.

minetest.override_item("default:coral_cyan", {
	drop = "ss:coral_cyan"
})
minetest.override_item("default:coral_green", {
	drop = "ss:coral_green"
})
minetest.override_item("default:coral_pink", {
	drop = "ss:coral_pink"
})
minetest.override_item("default:coral_brown", {
	drop = "ss:coral_skeleton"
})
minetest.override_item("default:coral_orange", {
	drop = "ss:coral_skeleton"
})
minetest.override_item("default:coral_skeleton", {
	drop = "ss:coral_skeleton"
})


-- KELP

minetest.override_item("default:sand_with_kelp", {
	drop = "ss:kelp"
})
=======
print("- loading overrides_node_drops.lua")

-- cache global functions for faster access
local debug = ss.debug
local math_random = math.random
local mt_add_item = core.add_item
local update_meta_and_description = ss.update_meta_and_description

-- cache global variables for faster access+
local ITEM_MAX_USES = ss.ITEM_MAX_USES
local ITEM_SOUNDS_MISS = ss.ITEM_SOUNDS_MISS
local ITEM_POINTING_RANGES = ss.ITEM_POINTING_RANGES

local nodeNames = {}


-- BLUEBERRIES: ensure they drop a random amount, and 'remaining_uses' metadata is initialized
local item_blueberries = ItemStack("ss:blueberries")
update_meta_and_description(item_blueberries:get_meta(), "ss:blueberries", {"remaining_uses"}, {ITEM_MAX_USES["ss:blueberries"]})
local dig_node_backup_blueberries = core.registered_nodes["default:blueberry_bush_leaves_with_berries"].after_dig_node
core.override_item("default:blueberry_bush_leaves_with_berries", {
	drop = "", -- prevent default item drop behavior
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if dig_node_backup_blueberries then
			dig_node_backup_blueberries(pos, oldnode, oldmetadata, digger)
		end
		item_blueberries:set_count(math_random(3,6))
		mt_add_item(pos, item_blueberries)
	end
})


-- APPLES: ensure 'remaining_uses' metadata is initialized
local item_apple = ItemStack("ss:apple")
update_meta_and_description(item_apple:get_meta(), "ss:apple", {"remaining_uses"}, {ITEM_MAX_USES["ss:apple"]})
local dig_node_backup_apple = core.registered_nodes["default:apple"].after_dig_node
core.override_item("default:apple", {
	drop = "", -- prevent default item drop behavior
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if dig_node_backup_apple then
			dig_node_backup_apple(pos, oldnode, oldmetadata, digger)
		end
		mt_add_item(pos, item_apple)
	end
})


-- CACTUS: ensure 'remaining_uses' metadata is initialized
local item_cactus = ItemStack("ss:cactus")
update_meta_and_description(item_cactus:get_meta(), "ss:cactus", {"remaining_uses"}, {ITEM_MAX_USES["ss:cactus"]})
local dig_node_backup_cactus = core.registered_nodes["default:cactus"].after_dig_node
core.override_item("default:cactus", {
	drop = "", -- prevent default item drop behavior
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if dig_node_backup_cactus then
			dig_node_backup_cactus(pos, oldnode, oldmetadata, digger)
		end
		local drop_quantity
		local wield_item = digger:get_wielded_item()
		if wield_item == "default:axe_stone" then
			drop_quantity = 3
		elseif wield_item == "default:axe_bronze" then
			drop_quantity = 4
		elseif wield_item == "default:axe_steel" then
			drop_quantity = 4
		elseif wield_item == "default:axe_mese" then
			drop_quantity = 5
		elseif wield_item == "default:axe_diamond" then
			drop_quantity = 5
		elseif wield_item == "default:sword_admin" then
			drop_quantity = 5
		else
			-- using hands or any other tool like sharpened stone
			drop_quantity = 2
		end
		item_cactus:set_count(drop_quantity)
		mt_add_item(pos, item_cactus)

		local item_stick = ItemStack("ss:stick")
		if wield_item == "default:axe_stone" then
			drop_quantity = 2
		elseif wield_item == "default:axe_bronze" then
			drop_quantity = 3
		elseif wield_item == "default:axe_steel" then
			drop_quantity = 3
		elseif wield_item == "default:axe_mese" then
			drop_quantity = 4
		elseif wield_item == "default:axe_diamond" then
			drop_quantity = 4
		elseif wield_item == "default:sword_admin" then
			drop_quantity = 4
		else
			-- using hands or any other tool like sharpened stone
			drop_quantity = 2
		end
		item_stick:set_count(drop_quantity)
		mt_add_item(pos, item_stick)

	end
})



-- CACTUS SEEDLING: ensure 'remaining_uses' metadata is initialized
item_cactus = ItemStack("ss:cactus")
update_meta_and_description(item_cactus:get_meta(), "ss:cactus", {"remaining_uses"}, {1})
local dig_node_backup_cactus_seedling = core.registered_nodes["default:large_cactus_seedling"].after_dig_node
core.override_item("default:large_cactus_seedling", {
	drop = "", -- prevent default item drop behavior
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if dig_node_backup_cactus_seedling then
			dig_node_backup_cactus_seedling(pos, oldnode, oldmetadata, digger)
		end
		local drop_quantity
		local wield_item = digger:get_wielded_item()
		if wield_item == "default:axe_stone" then
			drop_quantity = 1
		elseif wield_item == "default:axe_bronze" then
			drop_quantity = 1
		elseif wield_item == "default:axe_steel" then
			drop_quantity = 1
		elseif wield_item == "default:axe_mese" then
			drop_quantity = 2
		elseif wield_item == "default:axe_diamond" then
			drop_quantity = 2
		elseif wield_item == "default:sword_admin" then
			drop_quantity = 2
		else
			-- using hands or any other tool like sharpened stone
			drop_quantity = 1
		end
		item_cactus:set_count(drop_quantity)
		mt_add_item(pos, item_cactus)
		mt_add_item(pos, ItemStack("ss:stick"))

	end
})


-- TORCHES: ensure all torch nodes drops itself if itemdrop bag spawns at its position,
-- also ensure torches makes the swing swoosh noise
nodeNames = {"default:torch", "default:torch_wall", "default:torch_ceiling"}
for i,v in ipairs(nodeNames) do
	core.override_item(v, {
		drop_bag = "default:torch",
		range = ITEM_POINTING_RANGES["default:torch"],
		sound = {
			punch_use_air = ITEM_SOUNDS_MISS["default:torch"]
		}
	})
end


-- GRASS: Drops grass clumps. Bigger grasses drop more. Bonus for using bladed tools.
nodeNames = {"grass", "dry_grass"}
for i,v in ipairs(nodeNames) do
	core.override_item("default:" .. v .. "_1", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 1"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
	core.override_item("default:" .. v .. "_2", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 1"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
	core.override_item("default:" .. v .. "_3", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 2"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
	core.override_item("default:" .. v .. "_4", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 2"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
	core.override_item("default:" .. v .. "_5", {
		drop = {
			items = {
				{ items = {"ss:" ..  v .. "_clump 3"} }, -- applies to any tool including hands
				{ items = {"ss:" ..  v .. "_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
			}
		}
	})
end

-- MARRAM GRASS: Drops marram grass clumps. Bigger grasses drop more. Bonus for using bladed tools.
core.override_item("default:marram_grass_1", {
	drop = {
		items = {
			{ items = {"ss:marram_grass_clump 3"} }, -- applies to any tool including hands
			{ items = {"ss:marram_grass_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})
core.override_item("default:marram_grass_2", {
	drop = {
		items = {
			{ items = {"ss:marram_grass_clump 3"} }, -- applies to any tool including hands
			{ items = {"ss:marram_grass_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})
core.override_item("default:marram_grass_3", {
	drop = {
		items = {
			{ items = {"ss:marram_grass_clump 4"} }, -- applies to any tool including hands
			{ items = {"ss:marram_grass_clump 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})

-- JUNGLE GRASS: Drops jungle grass clumps. Bonus for using bladed tools.
core.override_item("default:junglegrass", {
	drop = {
		items = {
			{ items = {"ss:jungle_grass_clump 5"} }, -- applies to any tool including hands
			{ items = {"ss:jungle_grass_clump 2"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})

-- FERN: Drops fern leaves. Bigger ferns drop more. Bonus for using bladed tools.
core.override_item("default:fern_1", {
	drop = {
		items = {
			{ items = {"ss:leaves_fern 3"} }, -- applies to any tool including hands
			{ items = {"ss:leaves_fern 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})
core.override_item("default:fern_2", {
	drop = {
		items = {
			{ items = {"ss:leaves_fern 3"} }, -- applies to any tool including hands
			{ items = {"ss:leaves_fern 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})
core.override_item("default:fern_3", {
	drop = {
		items = {
			{ items = {"ss:leaves_fern 4"} }, -- applies to any tool including hands
			{ items = {"ss:leaves_fern 1"}, tool_groups = {"axe", "sword", "shovel"} }
		}
	}
})

-- DRY SHRUB: Drops sticks
core.override_item("default:dry_shrub", {
	drop = {
		items = {
			{ items = {"ss:stick"} }, -- applies to any tool including hands
			{ items = {"ss:stick"}, rarity = 2, },
			{ items = {"ss:stick"}, tool_groups = {"axe", "sword"} }
		}
	}
})

-- BUSH STEMS: Drops wood and sticks, and drops more when using axes, and further bonus with higher tier axes.
nodeNames = {"default:bush_stem", "default:acacia_bush_stem", "default:pine_bush_stem"}
for i,v in ipairs(nodeNames) do 
	core.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:wood", "ss:stick"} },
				{ items = {"ss:stick"}, rarity = 2, },
				{ items = {"ss:stick 1"}, tools = {"default:axe_stone"} },
				{ items = {"ss:stick 2"}, tools = {"default:axe_bronze"} },
				{ items = {"ss:stick 3"}, tools = {"default:axe_steel"} },
				{ items = {"ss:stick 3"}, tools = {"default:axe_mese"} },
				{ items = {"ss:stick 4"}, tools = {"default:axe_diamond"} },
				{ items = {"ss:stick 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end


-- WOODEN FENCE: Drops wood and drops more when using axes, and further bonus with higher tier axes.

core.override_item("default:fence_wood", {
	drop = {
		items = {
			{ items = {"ss:wood_plank 3"} }, -- applies to any tool except for hands, which cannot break.
			{ items = {"ss:wood_plank"}, rarity = 2, },
			{ items = {"ss:wood_plank"}, tools = {"default:axe_stone"} },
			{ items = {"ss:wood_plank"}, tools = {"default:axe_bronze"} },
			{ items = {"ss:wood_plank"}, tools = {"default:axe_steel"} },
			{ items = {"ss:wood_plank"}, tools = {"default:axe_mese"} },
		}
	}
})

core.override_item("stairs:slab_wood", {
	drop = {
		items = {
			{ items = {"ss:wood_plank 2"} }, -- applies to any tool except for hands, which cannot break.
			{ items = {"ss:wood_plank"}, rarity = 2, }
		}
	}
})


-- TREE: Drops wood and drops more when using axes, and further bonus with higher tier axes.
nodeNames = {"default:tree", "default:jungletree", "default:pine_tree", "default:acacia_tree", "default:aspen_tree"}
for i,v in ipairs(nodeNames) do 
	core.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:wood 3"} }, -- applies to any tool except for hands, which cannot break.
				{ items = {"ss:wood 1"}, tools = {"default:axe_stone"} },
				{ items = {"ss:wood 2"}, tools = {"default:axe_bronze"} },
				{ items = {"ss:wood 3"}, tools = {"default:axe_steel"} },
				{ items = {"ss:wood 3"}, tools = {"default:axe_mese"} },
				{ items = {"ss:wood 3"}, tools = {"ss:axe_diamond"} },
				{ items = {"ss:wood 3"}, tools = {"ss:sword_admin"} },
			}
		}
	})
end


-- DIRT: Drops dirt pile. Drops more when using shovels and more dirt with higher tier shovels. Also drops any resource from dirt nodes with any meaningful resource on the top surface.
nodeNames = {"default:dirt", "default:dirt_with_coniferous_litter", "default:dry_dirt"}
for i,v in ipairs(nodeNames) do 
	core.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:dirt_pile 4"} }, -- applies to any tool
				{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end
nodeNames = {"default:dirt_with_grass", "default:dirt_with_grass_footsteps"}
for i,v in ipairs(nodeNames) do 
	core.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:dirt_pile 3", "ss:grass_clump"} },
				{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
			}
		},
	})
end
nodeNames = {"default:dirt_with_dry_grass", "default:dry_dirt_with_dry_grass"}
for i,v in ipairs(nodeNames) do 
	core.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:dirt_pile 3", "ss:dry_grass_clump"} },
				{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
				{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
				{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end
core.override_item("default:dirt_with_rainforest_litter", {
	drop = {
		items = {
			{ items = {"ss:dirt_pile 3", "ss:leaves_dry_clump"} },
			{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})
core.override_item("default:dirt_with_snow", {
	drop = {
		items = {
			{ items = {"ss:dirt_pile 3", "ss:snow_pile"} },
			{ items = {"ss:dirt_pile 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:dirt_pile 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:dirt_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

core.override_item("default:snowblock", {
	drop = {
		items = {
			{ items = {"ss:snow_pile 4"} },
			{ items = {"ss:snow_pile 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:snow_pile 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:snow_pile 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:snow_pile 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:snow_pile 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:snow_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

core.override_item("default:ice", {
	drop = {
		items = {
			{ items = {"ss:ice 4"} },
			{ items = {"ss:ice 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:ice 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:ice 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:ice 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:ice 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:ice 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

core.override_item("default:cave_ice", {
	drop = {
		items = {
			{ items = {"ss:ice 5"} },
			{ items = {"ss:ice 1"}, tools = {"default:shovel_stone"} },
			{ items = {"ss:ice 2"}, tools = {"default:shovel_bronze"} },
			{ items = {"ss:ice 2"}, tools = {"default:shovel_steel"} },
			{ items = {"ss:ice 3"}, tools = {"default:shovel_mese"} },
			{ items = {"ss:ice 3"}, tools = {"default:shovel_diamond"} },
			{ items = {"ss:ice 3"}, tools = {"ss:sword_admin"} }
		}
	}
})


-- PERMAFROST: Drops permafrost dirt pile. Drops more when using pickaxe and more dirt with higher tier pickaxes.
core.override_item("default:permafrost", {
	drop = {
		items = {
			{ items = {"ss:dirt_permafrost_pile 4"} }, -- applies to any tool
			{ items = {"ss:dirt_permafrost_pile 1"}, tools = {"default:pick_stone"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_bronze"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_steel"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_mese"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_diamond"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

-- PERMAFROST W/ MOSS: Drops permafrost dirt pile and stone pile. Drops more when using pickaxe and more dirt with higher tier pickaxes.
core.override_item("default:permafrost_with_moss", {
	drop = {
		items = {
			{ items = {"ss:dirt_permafrost_pile 3", "ss:moss"} }, -- applies to any tool
			{ items = {"ss:dirt_permafrost_pile 1"}, tools = {"default:pick_stone"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_bronze"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_steel"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_mese"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_diamond"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

-- PERMAFROST W/ STONES: Drops permafrost dirt pile and stone pile. Drops more when using pickaxe and more dirt with higher tier pickaxes.
core.override_item("default:permafrost_with_stones", {
	drop = {
		items = {
			{ items = {"ss:dirt_permafrost_pile 3", "ss:stone_pile"} }, -- applies to any tool
			{ items = {"ss:dirt_permafrost_pile 1"}, tools = {"default:pick_stone"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_bronze"} },
			{ items = {"ss:dirt_permafrost_pile 2"}, tools = {"default:pick_steel"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_mese"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"default:pick_diamond"} },
			{ items = {"ss:dirt_permafrost_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

-- STONE / DESERT STONE: Drops stone or desert stone piles and drops more when using pickaxe, and further bonus with higher tier pickaxe.
nodeNames = {"stone", "desert_stone"}
for i,v in ipairs(nodeNames) do
	core.override_item("default:" .. v, {
		drop = {
			items = {
				{ items = {"ss:stone 2"} }, -- applies to any tool except for hands, which cannot break.
				{ items = {"ss:stone 2"}, tools = {"default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 1"}, tools = {"default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 1"}, tools = {"default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- STONE BRICK AND DESERT STONE BRICK: Same as Stone / Desert Stone (Above) but +2 mre stone / desert stone piles.
nodeNames = {"stone", "desert_stone"}
for i,v in ipairs(nodeNames) do
	core.override_item("default:" .. v .. "brick", {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 6"} }, -- applies to any tool except for hands, which cannot break.
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- STONE BLOCK AND DESERT STONE BLOCK: Same as Stone / Desert Stone (Above) but +2 mre stone / desert stone piles.
nodeNames = {"stone", "desert_stone"}
for i,v in ipairs(nodeNames) do
	core.override_item("default:" .. v .. "_block", {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 6"} }, -- applies to any tool except for hands, which cannot break.
                { items = {"ss:" .. v .. "_pile 2"}, tools = {"default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- COBBLE: Drops stone pile and drops more when using pickaxe, and further bonus with higher tier pickaxe.
nodeNames = {"default:cobble", "default:mossycobble"}
for i,v in ipairs(nodeNames) do 
	core.override_item(v, {
		drop = {
			items = {
				{ items = {"ss:stone_pile 2"} }, -- applies to any tool except for hands, which cannot break.
				{ items = {"ss:stone_pile 1"}, tools = {"default:pick_stone"} },
				{ items = {"ss:stone_pile 2"}, tools = {"default:pick_bronze"} },
				{ items = {"ss:stone_pile 2"}, tools = {"default:pick_steel"} },
				{ items = {"ss:stone_pile 3"}, tools = {"default:pick_mese"} },
				{ items = {"ss:stone_pile 3"}, tools = {"default:pick_diamond"} },
				{ items = {"ss:stone_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- DESERT COBBLE: Drops desert stone pile and drops more when using pickaxe, and further bonus with higher tier pickaxe.
core.override_item("default:desert_cobble", {
	drop = {
		items = {
			{ items = {"ss:desert_stone_pile 2"} }, -- applies to any tool except for hands, which cannot break.
			{ items = {"ss:desert_stone_pile 1"}, tools = {"default:pick_stone"} },
			{ items = {"ss:desert_stone_pile 2"}, tools = {"default:pick_bronze"} },
			{ items = {"ss:desert_stone_pile 2"}, tools = {"default:pick_steel"} },
			{ items = {"ss:desert_stone_pile 3"}, tools = {"default:pick_mese"} },
			{ items = {"ss:desert_stone_pile 3"}, tools = {"default:pick_diamond"} },
			{ items = {"ss:desert_stone_pile 3"}, tools = {"ss:sword_admin"} }
		}
	}
})

-- SAND: Drops sand piles and drops more when using shovels, and further bonus with higher tier shovels.
nodeNames = {"sand", "desert_sand", "silver_sand"}
for i,v in ipairs(nodeNames) do 
	core.override_item("default:" .. v, {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 4"} }, -- applies to any tool
				{ items = {"ss:" .. v .. "_pile 1"}, tools = {"default:shovel_stone"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_bronze"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_steel"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_mese"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_diamond"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- SANDSTONE: Drops sandstone piles and drops more when using shovels, and further bonus with higher tier shovels.
nodeNames = {"sandstone", "desert_sandstone", "silver_sandstone"}
for i,v in ipairs(nodeNames) do 
	core.override_item("default:" .. v, {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 4"} }, -- applies to any tool
				{ items = {"ss:" .. v .. "_pile 1"}, tools = {"default:shovel_stone", "default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_steel", "default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_mese", "default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- SANDSTONE BRICKS: Same pattern as sandstone, but drops +2 more sandstone piles.
core.override_item("default:sandstonebrick", {
	drop = {
		items = {
			{ items = {"ss:sandstone_pile 6"} }, -- applies to any tool
			{ items = {"ss:sandstone_pile 2"}, tools = {"default:shovel_stone", "default:pick_stone"} },
			{ items = {"ss:sandstone_pile 3"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
			{ items = {"ss:sandstone_pile 3"}, tools = {"default:shovel_steel", "default:pick_steel"} },
			{ items = {"ss:sandstone_pile 4"}, tools = {"default:shovel_mese", "default:pick_mese"} },
			{ items = {"ss:sandstone_pile 4"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
			{ items = {"ss:sandstone_pile 4"}, tools = {"ss:sword_admin"} }
		}
	}
})
nodeNames = {"desert_sandstone", "silver_sandstone"}
for i,v in ipairs(nodeNames) do 
	core.override_item("default:" .. v .. "_brick", {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 6"} }, -- applies to any tool
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_stone", "default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_steel", "default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:shovel_mese", "default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- SANDSTONE BLOCKS: Same pattern as sandstone, but drops +2 more sandstone piles.
nodeNames = {"sandstone", "desert_sandstone", "silver_sandstone"}
for i,v in ipairs(nodeNames) do 
	core.override_item("default:" .. v .. "_block", {
		drop = {
			items = {
				{ items = {"ss:" .. v .. "_pile 6"} }, -- applies to any tool
				{ items = {"ss:" .. v .. "_pile 2"}, tools = {"default:shovel_stone", "default:pick_stone"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
				{ items = {"ss:" .. v .. "_pile 3"}, tools = {"default:shovel_steel", "default:pick_steel"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:shovel_mese", "default:pick_mese"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
				{ items = {"ss:" .. v .. "_pile 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end


-- CLARY
core.override_item("default:clay", {
	drop = {
		items = {
			{ items = {"ss:clay"} },
			{ items = {"ss:clay 1"}, tools = {"default:shovel_stone", "default:pick_stone"} },
			{ items = {"ss:clay 2"}, tools = {"default:shovel_bronze", "default:pick_bronze"} },
			{ items = {"ss:clay 2"}, tools = {"default:shovel_steel", "default:pick_steel"} },
			{ items = {"ss:clay 3"}, tools = {"default:shovel_mese", "default:pick_mese"} },
			{ items = {"ss:clay 3"}, tools = {"default:shovel_diamond", "default:pick_diamond"} },
			{ items = {"ss:clay 3"}, tools = {"ss:sword_admin"} }
		}
	}
})


-- LEAVES / BUSH LEAVES: Drops clumps of leaves and drops more when using axe or swords, and further bonus with higher tier axes and swords.
nodeNames = {"leaves", "jungleleaves", "acacia_leaves", "aspen_leaves", "bush_leaves", "acacia_bush_leaves", "blueberry_bush_leaves"}
for i,v in ipairs(nodeNames) do 
	core.override_item("default:" .. v, {
		drop = {
			items = {
				{ items = {"ss:leaves_clump 4"} },
				{ items = {"ss:stick"}, rarity = 5 },
				{ items = {"ss:leaves_clump 1"}, tools = {"default:axe_stone", "default:sword_stone"} },
				{ items = {"ss:leaves_clump 2"}, tools = {"default:axe_bronze", "default:sword_bronze"} },
				{ items = {"ss:leaves_clump 2"}, tools = {"default:axe_steel", "default:sword_steel"} },
				{ items = {"ss:leaves_clump 3"}, tools = {"default:axe_mese", "default:sword_mese"} },
				{ items = {"ss:leaves_clump 4"}, tools = {"default:axe_diamond", "default:sword_diamond"} },
				{ items = {"ss:leaves_clump 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end


-- PINE NEEDLES: Drops pine needles.
nodeNames = {"pine_needles", "pine_bush_needles"}
for i,v in ipairs(nodeNames) do 
	core.override_item("default:" .. v, { 
		drop = {
			items = {
				{ items = {"ss:pine_needles 4"} },
				{ items = {"ss:stick"}, rarity = 5 },
				{ items = {"ss:pine_needles 1"}, tools = {"default:axe_stone", "default:sword_stone"} },
				{ items = {"ss:pine_needles 2"}, tools = {"default:axe_bronze", "default:sword_bronze"} },
				{ items = {"ss:pine_needles 2"}, tools = {"default:axe_steel", "default:sword_steel"} },
				{ items = {"ss:pine_needles 3"}, tools = {"default:axe_mese", "default:sword_mese"} },
				{ items = {"ss:pine_needles 4"}, tools = {"default:axe_diamond", "default:sword_diamond"} },
				{ items = {"ss:pine_needles 4"}, tools = {"ss:sword_admin"} }
			}
		}
	})
end

-- 	SAPLINGS: Drops leaves and a stick.
nodeNames = {"sapling", "junglesapling", "emergent_jungle_sapling", "acacia_sapling", "aspen_sapling"}
for i,v in ipairs(nodeNames) do 
	core.override_item("default:" .. v, { 
		drop = {
			items = {
				{ items = {"ss:leaves_clump"} },
				{ items = {"ss:stick"} }
			}
		}
	})
end

-- PINE SAPLING
core.override_item("default:pine_sapling", {
	drop = {
		items = {
			{ items = {"ss:pine_needles"} },
			{ items = {"ss:stick"} }
		}
	}
})

-- BUSH SAPLINGS: Drops only leaves.
nodeNames = {"bush_sapling", "acacia_bush_sapling", "blueberry_bush_sapling"}
for i,v in ipairs(nodeNames) do 
	core.override_item("default:" .. v, {
		drop = "ss:leaves_clump"
	})
end

-- PINE BUSH SAPLING
core.override_item("default:pine_bush_sapling", {
	drop = "ss:pine_needles"
})

-- PAPYRUS SALKS
core.override_item("default:papyrus", {
	drop = {
		items = {
			{ items = {"ss:papyrus 2"} }, -- default base quantity
			{ items = {"ss:papyrus 1"}, tools = {"default:axe_stone"} },
			{ items = {"ss:papyrus 1"}, tools = {"default:axe_bronze"} },
			{ items = {"ss:papyrus 1"}, tools = {"default:axe_steel"} },
			{ items = {"ss:papyrus 2"}, tools = {"default:axe_mese"} },
			{ items = {"ss:papyrus 2"}, tools = {"ss:axe_diamond"} },
			{ items = {"ss:papyrus 2"}, tools = {"ss:sword_admin"} },
		}
	}
})


-- FLOWERS: Drops picked version of themselves. Drops the full flower node that's plantable if using a shovel.
nodeNames = {"rose", "tulip", "dandelion_yellow", "chrysanthemum_green", "geranium", "viola", "dandelion_white", "tulip_black"}
for i,v in ipairs(nodeNames) do 
	core.override_item("flowers:" .. v, {
		drop = {
			max_items = 1,
			items = {
				{ items = {"ss:flower_" .. v}, tool_groups = {"shovel"} },
				{ items = {"ss:flower_" .. v}, tools = {"ss:sword_admin"} },
				{ items = {"ss:flower_" .. v .. "_picked"} }
			}
		}
	})
end

-- MUSHROOMS: Drops picked version of themselves. Unlike flowers, does not have plantable version - needs spores/seeds to plant.
nodeNames = {"mushroom_brown", "mushroom_red"}
for i,v in ipairs(nodeNames) do 
	core.override_item("flowers:" .. v, {
		drop = "ss:" .. v
	})
end

-- WATERLILY: Modify to drop craftitem version of lily and not the node, as well as a chance for lily flower.
core.override_item("flowers:waterlily", {
	drop = {
		items = {
			{ items = {"ss:flower_waterlily"} },
			{ items = {"ss:flower_waterlily_flower"}, rarity = 2, }
		}
	},
})
core.override_item("flowers:waterlily_waving", {
	drop = {
		items = {
			{ items = {"ss:flower_waterlily"} },
			{ items = {"ss:flower_waterlily_flower"}, rarity = 2, }
		}
	},
})


-- CORAL: digging cyan, green, and pink coral drops its corresponding craftitem,
-- while digging brown, orange, and skeleton coral will drop skeleton coral.

core.override_item("default:coral_cyan", {
	drop = "ss:coral_cyan"
})
core.override_item("default:coral_green", {
	drop = "ss:coral_green"
})
core.override_item("default:coral_pink", {
	drop = "ss:coral_pink"
})
core.override_item("default:coral_brown", {
	drop = "ss:coral_skeleton"
})
core.override_item("default:coral_orange", {
	drop = "ss:coral_skeleton"
})
core.override_item("default:coral_skeleton", {
	drop = "ss:coral_skeleton"
})


-- KELP

core.override_item("default:sand_with_kelp", {
	drop = "ss:kelp"
})
>>>>>>> 7965987 (update to version 0.0.3)
