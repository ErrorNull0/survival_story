<<<<<<< HEAD
print("- loading decorations.lua")

-- small chance to spawn small stones on any dirt with grass, dirt, or stone blocks
minetest.register_decoration({
    deco_type = "simple",
    decoration = "ss:stone",
    place_on = {
        "default:dirt_with_grass",
        "default:dirt",
        "default:stone",
        "default:dirt_with_dry_grass",
        "default:dirt_with_rainforest_litter",
        "default:dirt_with_coniferous_litter",
        "default:dry_dirt",
        "default:dry_dirt_with_dry_grass",
        "default:permafrost",
        "default:permafrost_with_stones",
        "default:permafrost_with_moss"
    },
    fill_ratio = 0.004,
    y_min = -31000,
    y_max = 31000,
})

-- spawn a bit more small stones next to stone blocks like cliff faces
minetest.register_decoration({
    deco_type = "simple",
    decoration = "ss:stone",
    place_on = {
        "default:dirt_with_grass",
        "default:dirt",
        "default:stone",
        "default:dirt_with_dry_grass",
        "default:dirt_with_rainforest_litter",
        "default:dirt_with_coniferous_litter",
        "default:dry_dirt",
        "default:dry_dirt_with_dry_grass",
        "default:permafrost",
        "default:permafrost_with_stones",
        "default:permafrost_with_moss"
    },
    spawn_by = "default:stone",
    num_spawn_by = 1,
    fill_ratio = 0.10,
    y_min = -31000,
    y_max = 31000,
})

-- small chance to spawn sticks next to any tree
minetest.register_decoration({
    deco_type = "simple",
    decoration = "ss:stick",
    place_on = {"default:dirt_with_grass"},
    spawn_by = "group:tree",
    num_spawn_by = 1,
    fill_ratio = 0.05,
    param2 = 0,
    param2_max = 3,
    y_min = -31000,
    y_max = 31000
=======
print("- loading decorations.lua")

-- small chance to spawn small stones on any dirt with grass, dirt, or stone blocks
core.register_decoration({
    deco_type = "simple",
    decoration = "ss:stone",
    place_on = {
        "default:dirt_with_grass",
        "default:dirt",
        "default:stone",
        "default:dirt_with_dry_grass",
        "default:dirt_with_rainforest_litter",
        "default:dirt_with_coniferous_litter",
        "default:dry_dirt",
        "default:dry_dirt_with_dry_grass",
        "default:permafrost",
        "default:permafrost_with_stones",
        "default:permafrost_with_moss"
    },
    fill_ratio = 0.004,
    y_min = -31000,
    y_max = 31000,
})

-- spawn a bit more small stones next to stone blocks like cliff faces
core.register_decoration({
    deco_type = "simple",
    decoration = "ss:stone",
    place_on = {
        "default:dirt_with_grass",
        "default:dirt",
        "default:stone",
        "default:dirt_with_dry_grass",
        "default:dirt_with_rainforest_litter",
        "default:dirt_with_coniferous_litter",
        "default:dry_dirt",
        "default:dry_dirt_with_dry_grass",
        "default:permafrost",
        "default:permafrost_with_stones",
        "default:permafrost_with_moss"
    },
    spawn_by = "default:stone",
    num_spawn_by = 1,
    fill_ratio = 0.10,
    y_min = -31000,
    y_max = 31000,
})

-- small chance to spawn sticks next to any tree
core.register_decoration({
    deco_type = "simple",
    decoration = "ss:stick",
    place_on = {"default:dirt_with_grass"},
    spawn_by = "group:tree",
    num_spawn_by = 1,
    fill_ratio = 0.05,
    param2 = 0,
    param2_max = 3,
    y_min = -31000,
    y_max = 31000
>>>>>>> 7965987 (update to version 0.0.3)
})