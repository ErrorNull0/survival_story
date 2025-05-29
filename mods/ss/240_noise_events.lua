print("- loading noise_events.lua")

-- cache global functions for faster access
local debug = ss.debug
local start_try_noise = ss.start_try_noise


local NOISE_EVENT_NODES = {
    ["default:dirt_with_grass"] = "plants",
    ["default:dirt_with_grass_footsteps"] = "plants",
    ["default:dirt_with_dry_grass"] = "plants",
    ["default:leaves"] = "plants",
    ["default:jungleleaves"] = "plants",
    ["default:pine_needles"] = "plants",
    ["default:acacia_leaves"] = "plants",
    ["default:aspen_leaves"] = "plants",
    ["default:papyrus"] = "plants",
    ["default:junglegrass"] = "plants",
    ["default:grass_1"] = "plants",
    ["default:grass_2"] = "plants",
    ["default:grass_3"] = "plants",
    ["default:grass_4"] = "plants",
    ["default:grass_5"] = "plants",
    ["default:dry_grass_1"] = "plants",
    ["default:dry_grass_2"] = "plants",
    ["default:dry_grass_3"] = "plants",
    ["default:dry_grass_4"] = "plants",
    ["default:dry_grass_5"] = "plants",
    ["default:fern_1"] = "plants",
    ["default:fern_2"] = "plants",
    ["default:fern_3"] = "plants",
    ["default:marram_grass_1"] = "plants",
    ["default:marram_grass_2"] = "plants",
    ["default:marram_grass_3"] = "plants",
    ["default:bush_leaves"] = "plants",
    ["default:acacia_bush_leaves"] = "plants",
    ["default:pine_bush_needles"] = "plants",
    ["default:blueberry_bush_leaves"] = "plants",
    ["flowers:rose"] = "plants",
    ["flowers:tulip"] = "plants",
    ["flowers:dandelion_yellow"] = "plants",
    ["flowers:chrysanthemum_green"] = "plants",
    ["flowers:geranium"] = "plants",
    ["flowers:viola"] = "plants",
    ["flowers:dandelion_white"] = "plants",
    ["flowers:tulip_black"] = "plants",

    ["default:dirt"] = "dust",
    ["default:dry_dirt"] = "dust",
    ["default:dry_dirt_with_dry_grass"] = "dust",
    ["default:dirt_with_snow"] = "dust",
    ["default:dirt_with_rainforest_litter"] = "dust",
    ["default:permafrost_with_stones"] = "dust",
    ["default:sand"] = "dust",
}


local flag1 = false
-- overriding all plant nodes to run start_try_noise() when dug
for node_name, noise_type in pairs(NOISE_EVENT_NODES) do
    debug(flag1, "## overriding node: " .. node_name)
    local original_after_dig_node = core.registered_nodes[node_name].after_dig_node
    core.override_item(node_name, {
        after_dig_node = function(pos, oldnode, oldmetadata, digger)
            --debug(flag1, "\nafter_dig_node() for " .. node_name)
            if original_after_dig_node then
                --debug(flag1, " executing original code..")
                original_after_dig_node(pos, oldnode, oldmetadata, digger)
            end
            start_try_noise(digger, digger:get_meta(), noise_type)
            debug(flag1, "after_dig_node() END")
        end
    })

end