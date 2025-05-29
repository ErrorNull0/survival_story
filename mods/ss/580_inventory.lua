print("- loading inventory.lua")

-- cache global functions for faster access
local math_round = math.round
local math_floor = math.floor
local math_min = math.min
local math_random = math.random
local string_split = string.split
local string_sub = string.sub
local string_gsub = string.gsub
local string_upper = string.upper
local table_concat = table.concat
local table_insert = table.insert
local table_sort = table.sort
local mt_show_formspec = core.show_formspec
local mt_serialize = core.serialize
local mt_add_item = core.add_item
local debug = ss.debug
local notify = ss.notify
local play_sound = ss.play_sound
local build_fs = ss.build_fs
local get_itemstack_weight = ss.get_itemstack_weight
local get_fs_weight = ss.get_fs_weight
local get_fs_player_avatar = ss.get_fs_player_avatar
local get_fs_equip_slots = ss.get_fs_equip_slots
local get_fs_equipment_buffs = ss.get_fs_equipment_buffs
local get_fs_player_stats = ss.get_fs_player_stats
local update_meta_and_description = ss.update_meta_and_description
local update_stat = ss.update_stat
local do_stat_update_action = ss.do_stat_update_action
local update_clothes = ss.update_clothes
local update_armor = ss.update_armor

-- cache global variables for faster access
local INV_SIZE_START = ss.INV_SIZE_START
local INV_SIZE_MAX = ss.INV_SIZE_MAX
local INV_SIZE_MIN = ss.INV_SIZE_MIN
local SLOT_WEIGHT_MAX = ss.SLOT_WEIGHT_MAX
local X_OFFSET_RIGHT = ss.X_OFFSET_RIGHT
local SLOT_COLOR_BG = ss.SLOT_COLOR_BG
local SLOT_COLOR_HOVER = ss.SLOT_COLOR_HOVER
local SLOT_COLOR_BORDER = ss.SLOT_COLOR_BORDER
local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local ITEM_TOOLTIP = ss.ITEM_TOOLTIP
local NOTIFICATIONS = ss.NOTIFICATIONS
local NOTIFY_DURATION = ss.NOTIFY_DURATION
local GROUP_ITEMS = ss.GROUP_ITEMS
local RECIPES = ss.RECIPES
local RECIPE_INGREDIENTS = ss.RECIPE_INGREDIENTS
local COOK_THRESHOLD = ss.COOK_THRESHOLD
local ITEM_MAX_USES = ss.ITEM_MAX_USES
local WEAR_VALUE_MAX = ss.WEAR_VALUE_MAX
local BAG_NODE_NAMES_ALL = ss.BAG_NODE_NAMES_ALL
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local ITEM_VALUES = ss.ITEM_VALUES
local ITEM_BURN_TIMES = ss.ITEM_BURN_TIMES
local ITEM_HIT_DAMAGES = ss.ITEM_HIT_DAMAGES
local ITEM_HIT_TYPES = ss.ITEM_HIT_TYPES
local ITEM_HIT_COOLDOWNS = ss.ITEM_HIT_COOLDOWNS
local ITEM_POINTING_RANGES = ss.ITEM_POINTING_RANGES
local CLOTHING_NAMES = ss.CLOTHING_NAMES
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local CLOTHING_EYES = ss.CLOTHING_EYES
local CLOTHING_NECK = ss.CLOTHING_NECK
local CLOTHING_CHEST = ss.CLOTHING_CHEST
local CLOTHING_HANDS = ss.CLOTHING_HANDS
local CLOTHING_LEGS = ss.CLOTHING_LEGS
local CLOTHING_FEET = ss.CLOTHING_FEET
local ARMOR_NAMES = ss.ARMOR_NAMES
local ARMOR_COLORS = ss.ARMOR_COLORS
local ARMOR_CONTRASTS = ss.ARMOR_CONTRASTS
local EQUIPMENT_BUFFS = ss.EQUIPMENT_BUFFS
local ARMOR_HEAD = ss.ARMOR_HEAD
local ARMOR_FACE = ss.ARMOR_FACE
local ARMOR_CHEST = ss.ARMOR_CHEST
local ARMOR_ARMS = ss.ARMOR_ARMS
local ARMOR_LEGS = ss.ARMOR_LEGS
local ARMOR_FEET = ss.ARMOR_FEET
local player_data = ss.player_data


-- Represents items that would spill its contents if placed into the the player
-- inventory or external storage, like cups of water, bowls of soup, plates of food,
ss.SPILLABLE_ITEM_NAMES = {
    ["ss:cup_wood_water_murky"] = true,
    ["ss:cup_wood_water_boiled"] = true,
    ["ss:bowl_wood_water_murky"] = true,
    ["ss:bowl_wood_water_boiled"] = true,
    ["ss:jar_glass_lidless_water_murky"] = true,
    ["ss:jar_glass_lidless_water_boiled"] = true,
    ["ss:pot_iron_water_murky"] = true,
    ["ss:pot_iron_water_boiled"] = true
}
local SPILLABLE_ITEM_NAMES = ss.SPILLABLE_ITEM_NAMES

-- specifies how many extra inventory slots the bag item provides when equipped.
local BAG_SLOT_BONUS = {
    ["ss:bag_fiber_small"] = 1,
    ["ss:bag_fiber_medium"] = 2,
    ["ss:bag_fiber_large"] = 3,
    ["ss:bag_cloth_small"] = 2,
    ["ss:bag_cloth_medium"] = 3,
    ["ss:bag_cloth_large"] = 4
}


--- @return table
-- Returns a table of all elements relating to the 'setup' section of 'fs' table.
-- Curently includes size[], box[], and box[], which is the size of the overall formspec
-- ui, and the darkened background boxes for the left and right panel sections.
function ss.get_fs_setup()
    local fs_elements = {
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.4]",
        "style_type[list;spacing=0.1,0.1]",
        "box[0.0,0.0;5.7,10.5;#222222]", -- left pane bg color
        table_concat({"box[15.0,0.0;7.20,10.5;#222222]"}), -- right pane bg color
        "listcolors[",
			SLOT_COLOR_BG, ";",
			SLOT_COLOR_HOVER, ";",
			SLOT_COLOR_BORDER, ";",
			TOOLTIP_COLOR_BG, ";",
			TOOLTIP_COLOR_TEXT,
		"]"
    }
    return fs_elements
end


--- @return table
-- Returns a table of all elements relating to the left tab section of 'fs' table.
-- Curently includes only tabheader[] which define the Main and Tasks tabs.
function ss.get_fs_tabs_left()
    return { "tabheader[0,0;inv_tabs;Main,Equipment,Status,Skills,Bundle,Settings,?,*;1;true;true]" }
end
local get_fs_tabs_left = ss.get_fs_tabs_left


--- @return table
-- Returns a table of all elements relating to the item info slot in the 'fs' table.
-- Currently includes image[], list[], and tooltip[], elements, which are default to
-- a blank slot, with no item being shown.
function ss.get_fs_item_info_slot()
    return {
        table_concat({"image[13.7,0.2;1,1;ss_ui_iteminfo_slot.png;]"}),
        table_concat({"list[current_player;item_info_slot;13.7,0.2;1,1;]"}),
        table_concat({"tooltip[13.7,0.2;1,1;Item Info (drop item here)]"})
    }
end
local get_fs_item_info_slot = ss.get_fs_item_info_slot


local flag4 = false
--- @param player? ObjectRef the player object
--- @param item? ItemStack the item, used to access the custom 'ss_data' data
--- @return table fs_output the table containing all item info formspec elements
-- Builds the item info formspec elements and returns it as a standard indexed table.
-- Each element in the array is a specific formspec element for the item info display.
function ss.get_fs_item_info(player, item)
    debug(flag4, "  get_fs_item_info()")

    local fs_output = {}
    local fs_data = {}
    local fs_groups = {}

    -- show 'survival story' game title and version, 'survival tip' info, and item info slot hint text
    if not (player and item) then

        return {

            table_concat({"hypertext[6.0,0.7;7,1;survival_tip_title;",
            "<style color=#AAAAAA size=26><b>You are alone.</b></style>", "]"}),

            table_concat({"hypertext[6.0,1.5;8.7,1.3;survival_tip_text;",
            "<style color=#AAAAAA size=18><b>Push to survive another day,</b></style> ",
            "<style color=#777777 size=18>while exploring your surroundings and your limits.</style>", "]"}),
        }

    else
        -----------------------------------------------------------
        -- build item info icon, item name label and descriptors --
        -----------------------------------------------------------

        local item_name = item:get_name()

        -- data from tables loaded from item_data.txt
        local item_display_name = ss.ITEM_DISPLAY_NAME[item_name]
        local item_descriptor = ss.ITEM_DESCRIPTOR[item_name]
        local item_category = ss.ITEM_CATEGORY[item_name]
        local item_description_short = ss.ITEM_DESC_SHORT[item_name]
        local item_description_long = ss.ITEM_DESC_LONG[item_name]

        debug(flag4, "    item_name: " .. item_name)
        debug(flag4, "    item_display_name: " .. item_display_name)
        debug(flag4, "    item_category: " .. item_category)
        debug(flag4, "    item_description_short: " .. item_description_short)
        debug(flag4, "    item_description_long: " .. item_description_long)

        -- pre-initialize the item's weight. will be used for the 'weight' attribute
        local item_weight = ITEM_WEIGHTS[item_name]

        -- pre-initialize HIT ATTACK attribute data
        local item_hit_damage = ITEM_HIT_DAMAGES[item_name]
        local item_hit_range = ITEM_POINTING_RANGES[item_name]
        local item_hit_cooldown = ITEM_HIT_COOLDOWNS[item_name]
        local item_hit_type = ITEM_HIT_TYPES[item_name]
        local item_burn_time = ITEM_BURN_TIMES[item_name]
        local item_value = ITEM_VALUES[item_name]


        -- use custom icon colorization when dealing with clothing and armor,
        -- and use custom texture overlays when dealing with item bundles

        local item_image_element
        local str_tokens = string_split(item_name, "_")
        local item_type = str_tokens[1]
        if item_type == "ss:clothes" then
            debug(flag4, "    this is clothing")
            local item_meta = item:get_meta()
            local item_texture = item_meta:get_string("inventory_image")
            if item_texture == "" then
                debug(flag4, "    this was initiated by a recipe icon or a server command")
                local clothing_name = string_sub(item_name, 12)
                debug(flag4, "    clothing_name: " .. clothing_name)
                item_texture = table_concat({
                    "ss_clothes_", clothing_name, ".png",
                    "^[colorizehsl:", CLOTHING_COLORS[clothing_name][1],
                    "^[contrast:", CLOTHING_CONTRASTS[clothing_name][1],
                    "^[mask:ss_clothes_", clothing_name, "_mask.png"
                })
            end
            debug(flag4, "    item_texture: " .. item_texture)
            item_image_element = table_concat({
                "image[6.0,0.2;1,1;", item_texture, "]"
            })

        elseif item_type == "ss:armor" then
            debug(flag4, "    this is armor")
            local item_meta = item:get_meta()
            local item_texture = item_meta:get_string("inventory_image")
            if item_texture == "" then
                debug(flag4, "    this was initiated by a recipe icon or a server command")
                local armor_name = string_sub(item_name, 10)
                debug(flag4, "    armor_name: " .. armor_name)
                item_texture = table_concat({
                    "ss_armor_", armor_name, ".png",
                    "^[colorizehsl:", ARMOR_COLORS[armor_name][1],
                    "^[contrast:", ARMOR_CONTRASTS[armor_name][1],
                    "^[mask:ss_armor_", armor_name, "_mask.png"
                })
            end
            debug(flag4, "    item_texture: " .. item_texture)
            item_image_element = table_concat({
                "image[6.0,0.2;1,1;", item_texture, "]"
            })

        elseif item_name == "ss:item_bundle" then
            debug(flag4, "    this is an item bundle")
            local item_meta = item:get_meta()
            local item_texture = item_meta:get_string("inventory_image")
            debug(flag4, "    item_texture: " .. item_texture)
            item_image_element = table_concat({
                "image[6.0,0.2;1,1;", item_texture, "]"
            })
            local bundle_item_name = item_meta:get_string("bundle_item_name")
            local bundle_item_desc = ITEM_TOOLTIP[bundle_item_name]
            local bundle_item_count = item_meta:get_int("bundle_item_count")
            item_weight = item_meta:get_float("bundle_weight")
            item_burn_time = item_meta:get_int("bundle_burn_time")
            item_value = item_meta:get_int("bundle_value")
            item_category = table_concat({ bundle_item_desc, " x", bundle_item_count})
            item_hit_damage = item_meta:get_float("bundle_hit_damage")
            item_hit_range = item_meta:get_float("bundle_hit_range")
            item_hit_cooldown = item_meta:get_float("bundle_hit_cooldown")
            item_hit_type = item_meta:get_string("bundle_hit_type")
        else
            debug(flag4, "    not a clothing or armor item")
            item_image_element = table_concat({
                "item_image[6.0,0.2;1,1;", item_name, "]"
            })
        end

        local item_descriptor_element = ""
        if item_descriptor then
            item_descriptor_element = table_concat({
                "<style color=#CCCCCC size=18>(", item_descriptor, ")</style>"
            })
        end

        local item_category_element = ""
        if item_category then
            item_category_element = table_concat({
                "hypertext[7.1,0.7;6.0,1.0;iteminfo_item_subtext;",
                    "<style color=#888888 size=18>", item_category, "</style>]"
            })
        end

        item_description_long = item_description_long or "(missing from item_data.txt)"
        item_description_short = item_description_short or "(missing from item_data.txt)"

        fs_data = {
            table_concat({
                "box[6.0,0.2;1,1;#222222]",

                item_image_element,

                "tooltip[6.0,0.2;1,1;", item_description_long, ";#000000;#d0cd98]",

                "hypertext[7.1,0.2;6.0,2.0;iteminfo_description;",
                    "<style color=#EEEEEE size=18><b>", item_display_name, " </b></style>",
                    item_descriptor_element, "]",

                item_category_element,

                "hypertext[6.0,2.0;8.65,0.50;iteminfo_info;",
                "<style color=#AAAAAA size=18>", item_description_short, "</style>]",
            })
        }
        table_insert(fs_groups, fs_data)
        debug(flag4, "    built item info icon and name title")

        --------------------------------------------------
        -- build the main item info attributes and text --
        --------------------------------------------------

        fs_data = {}  -- clear out prior data in the table        

        -- track how many attributes are valid and actually have values and insert
        -- into 'attrib_data' table. each table element has three properties:
        -- element[1] = texture filename portion
        -- element[2] = tooltip text
        -- element[3] = actual attrib value
        local attrib_data = {}

        -- set the WEIGHT attribute data
        debug(flag4, "    item_weight: " .. item_weight)
        table_insert(attrib_data, {"weight", "item weight", item_weight})

        -- set BURN TIME attribute data. note: items with burn time of zero do not
        --exist in ITEM_BURN_TIMES, only itmes with burn times > zero
        if item_burn_time > 0 then
            debug(flag4, "    item_burn_time: " .. item_burn_time)
            local item_meta = item:get_meta()
            local cook_progress = item_meta:get_int("cook_progress")
            debug(flag4, "    cook_progress: " .. cook_progress)
            -- calculate burn time based on 'cook_progress' value if exists
            if cook_progress > 0 then
                debug(flag4, "    this is a 'heated' item")
                local cook_progress_remain = COOK_THRESHOLD - cook_progress
                debug(flag4, "    cook_progress_remain: " .. cook_progress_remain)
                local cook_progress_remain_ratio = cook_progress_remain / COOK_THRESHOLD
                debug(flag4, "    cook_progress_remain_ratio: " .. cook_progress_remain_ratio)
                item_burn_time = math_round(item_burn_time * cook_progress_remain_ratio)
                if item_burn_time == 0 then item_burn_time = 1 end
            end
            table_insert(attrib_data, {"burn_time", "burn time", item_burn_time})
        end

        local item_hit_data = table_concat({ "Attack\n",
            "\ndamage: ", item_hit_damage,
            "\nrange: ", item_hit_range,
            "\ncooldown: ", item_hit_cooldown,
            "\ntype: ", item_hit_type
        })
        table_insert(attrib_data, {"attack", item_hit_data, item_hit_damage})

        -- retrieve DAMAGE PROTECTION attribute data
        local equip_buff_data, item_damage_protection
        if EQUIPMENT_BUFFS[item_name] then
            local buffs_data = EQUIPMENT_BUFFS[item_name]
            item_damage_protection = buffs_data.damage
            equip_buff_data = table_concat({ "Protection\n",
                "\nphysical: ", item_damage_protection,
                "\ncold: ", buffs_data.cold,
                "\nheat: ", buffs_data.heat,
                "\nwetness: ", buffs_data.wetness,
                "\ndisease: ", buffs_data.disease,
                "\nradiation: ", buffs_data.radiation,
                "\nnoise: ", buffs_data.noise
            })
        elseif EQUIPMENT_BUFFS[item_name] then
            local buffs_data = EQUIPMENT_BUFFS[item_name]
            item_damage_protection = EQUIPMENT_BUFFS[item_name].damage
            equip_buff_data = table_concat({ "Protection\n",
                "\nphysical: ", item_damage_protection,
                "\ncold: ", buffs_data.cold,
                "\nheat: ", buffs_data.heat,
                "\nwetness: ", buffs_data.wetness,
                "\ndisease: ", buffs_data.disease,
                "\nradiation: ", buffs_data.radiation,
                "\nnoise: ", buffs_data.noise
            })
        else
            item_damage_protection = 0
        end
        debug(flag4, "    item_damage_protection: " .. item_damage_protection)

        -- check that clothing/armor slot to see if anything is equipped there
        -- ex: p_data.avatar_clothing_chest

        if item_damage_protection > 0 then
            table_insert(attrib_data, {"damage", equip_buff_data, item_damage_protection})
        end

        -- retrieve VALUE attribute data
        debug(flag4, "    item_value: " .. item_value)
        if item_value > 0 then
            table_insert(attrib_data, {"value", "item value", item_value})
        end

        -- defines the positional info of each slot of the item attributes area, which
        -- includes icon pos, tooltip pos, and the pos of the string/value
        local x_pos = 6.0
        local y_pos_icon = 1.3
        local y_pos_value = 1.4

        local attrib_pos = {
            [1] = {icon = x_pos + 0, value = x_pos + 0.5},
            [2] = {icon = x_pos + 1.5, value = x_pos + 2.0},
            [3] = {icon = x_pos + 3.0, value = x_pos + 3.5},
            [4] = {icon = x_pos + 4.5, value = x_pos + 5.0},
            [5] = {icon = x_pos + 6.0, value = x_pos + 6.5}
        }

        -- generate the formspec for five of the item attributes: item_weight,
        -- item_value, item_burn_time, item_damage, and item_cooldown
        local fs_image, fs_tooltip, fs_hypertext
        for i, data in ipairs(attrib_data) do

            fs_image = table_concat({"image[",
                attrib_pos[i].icon, ",", y_pos_icon, ";",
                "0.5,0.5;ss_ui_iteminfo_attrib_", data[1], ".png;]",
            })
            table_insert(fs_data, fs_image)

            fs_tooltip = table_concat({"tooltip[",
                attrib_pos[i].icon, ",", y_pos_icon, ";",
                "1.0,0.5;", data[2], "]",
            })
            table_insert(fs_data, fs_tooltip)

            fs_hypertext = table_concat({"hypertext[",
                attrib_pos[i].value, ",", y_pos_value, ";",
                "2,1;iteminfo_", data[1], ";",
                "<style color=#AAAAAA size=18>", data[3], "</style>]"})
            table_insert(fs_data, fs_hypertext)

        end

        table_insert(fs_groups, fs_data)

        -- combine all the iteminfo formspec parts
        for i, fs_group in ipairs(fs_groups) do
            for j, fs_element in ipairs(fs_group)do
                table_insert(fs_output, fs_element)
            end
        end

        --debug(flag4, "    fs: " .. dump(fs))
        debug(flag4, "  get_fs_item_info() end")

    end
    return fs_output
end
local get_fs_item_info = ss.get_fs_item_info


--- @return table
-- Returns a table of all elements relating to the main inventory grid in the 'fs' table.
-- Currently includes box[] and list[], which relates to the grid slots and the darkened
-- background slot effect for the hotbar.
function ss.get_fs_inventory_grid()
    local fs_output = {}
    for i = 0, 7 do
        table_insert(fs_output, table_concat({
            "box[", 6.0 + i + (i * 0.1), ",2.70;1,1;#000000]"
        }))
    end
    table_insert(fs_output, table_concat({
        "list[current_player;main;6.0,2.7;8,1;]",
        "list[current_player;main;6.0,3.8;8,6;8]"
    }))
    return fs_output
end
local get_fs_inventory_grid = ss.get_fs_inventory_grid


local flag14 = false
--- @return table fs_output Returns a table of all elements relating to center bottom
--- bag slot in the 'fs' table. Currently includes image[] and tooltip[], which
--- constructs the bag slots.
function ss.get_fs_bag_slots(player_inv, player_name)
    debug(flag14, "\nget_fs_bag_slots")
    local fs_output = {}
    local bag_item
    local x_pos = 10.4
    local x_increment = 1.1

    for bag_slot_index = 1, 3 do
        bag_item = player_inv:get_stack("bag_slots", bag_slot_index)
        if bag_item:is_empty() then
            debug(flag14, "  slot " .. bag_slot_index .. " empty. showing bg image and tooltip.")
            table_insert(fs_output, table_concat({
                "image[", x_pos + (x_increment * bag_slot_index), ",9.3;1,1;ss_ui_bag_slot.png]",
                "tooltip[", x_pos + (x_increment * bag_slot_index), ",9.3;1,1;Empty Bag Slot]"
            }))
        else
            debug(flag14, "  slot " .. bag_slot_index .. " occupied. showing green condition color.")
            local item_meta = bag_item:get_meta()
            local condition = item_meta:get_float("condition")
            debug(flag14, "  condition: " .. condition)
            if condition == 0 then
                debug(flag14, "  this is an unused storage bag. condition intialized to: " .. WEAR_VALUE_MAX)
                condition = WEAR_VALUE_MAX
            end
            local condition_ratio = condition / WEAR_VALUE_MAX
            debug(flag14, "  condition_ratio: " .. condition_ratio)
            local bar_height = 1 * condition_ratio
            local bar_yoffset = 1 - bar_height
            local bar_ypos = 9.3 + bar_yoffset
            table_insert(fs_output, table_concat({
                "image[", x_pos + (x_increment * bag_slot_index), ",", bar_ypos, ";1,", bar_height,
                    ";[fill:1x1:", player_data[player_name].ui_green, "]"
            }))
        end
    end

    table_insert(fs_output, table_concat({
        "list[current_player;bag_slots;", 11.5, ",9.3;3,1]"
    }))

    debug(flag14, "  fs_output: " .. dump(fs_output))
    debug(flag14, "get_fs_bag_slots() end")
    return fs_output
end
local get_fs_bag_slots = ss.get_fs_bag_slots


--- @param mode string the crafting mode being used to craft the recipe item
--- @return table fs_output Returns a table of all elements relating to the title area
--- on the crafting pane. The crafting title has a different image depeing on the
--- 'craft_mode' which currently can be "hand", "campfire", "grill", "stove", "oven",
--- and "microwave".
function ss.get_fs_craft_title(mode, category)
    local fs_output = {
        table_concat({"hypertext[15.3,0.2;7,0.6;craft_method;",
        "<b><style color=#777777 size=18>", mode:gsub("^%l", string_upper), " Crafting \u{21FE} </style>",
        "<style color=#CCCCCC size=18>", string_upper(category), "</style></b>]"})
    }
    return fs_output
end
local get_fs_craft_title = ss.get_fs_craft_title


local flag6 = false
--- @return table fs_output Returns a table of all elements relating to the crafting
--- category buttons of the 'fs' table. Currently includes style[], image[] and
--- tooltip[], which create the buttons.
function ss.get_fs_craft_categories(recipe_category)
    debug(flag6, "\nget_fs_craft_categories()")
    debug(flag6, "  recipe_category: " .. recipe_category)
    local x_offset = 15.3
    local y_pos = 0.7
    local xy_size = 0.7
    local x_increment = 0.75
    local png_num

    local recipe_categories = { "tools", "resources", "food", "medical", "clothing",
        "armor", "weapons",  "building", "other" }
    local fs_data = {}
    for i, category in ipairs(recipe_categories) do
        if recipe_category == category then
            png_num = "2"
        else
            png_num = "1"
        end
        local new_data = {
            table_concat({"tooltip[enCraftcategory_", category, ";", category, "]"}),
            table_concat({"style[enCraftcategory_", category, ":hovered;fgimg=ss_ui_craft_category_", category, "2.png]"}),
            table_concat({"image_button[", x_offset + (x_increment * (i - 1)), ",", y_pos, ";", xy_size, ",", xy_size,
            ";ss_ui_craft_category_", category, png_num, ".png;enCraftcategory_", category, ";]"})
        }
        table_insert(fs_data, new_data)
    end

    local fs_output = {}
    for i, fs_group in ipairs(fs_data) do
        for j, fs_element in ipairs(fs_group) do
            table_insert(fs_output, fs_element)
        end
    end
    debug(flag6, "  fs_output: " .. dump(fs_output))
    debug(flag6, "\nget_fs_craft_categories() end")
    return fs_output
end
local get_fs_craft_categories = ss.get_fs_craft_categories


--- @param item_name string the item_name of the item stack, like "default: dirt"
--- @return table fs_output Returns a table of all elements relating to the icon that is
--- displayed on the recipe item being crafted on the crafting pane.
function ss.get_fs_craft_item_icon(item_name)
    local x_pos = X_OFFSET_RIGHT - 0.9
    local fs_output = {
        table_concat({"item_image[", x_pos, ",1.6;1.3,1.3;", item_name, "]"})
    }
    return fs_output
end
local get_fs_craft_item_icon = ss.get_fs_craft_item_icon


--- @param recipe_id string recipe that this craft button is acting upon
--- @param craft_count number quantity of this recipe that can still be crafted
--- @return table fs_output table of all elements relating to the craft button in the
--- 'fs' table. Currently includes style[], image_button[], and hypertext[], which
--- pertains to the specific recipe item being crafted. If 'craft_out' is zero, returns
--- a non-clickable craft button that represents non-craftable recipe.
function ss.get_fs_craft_button(recipe_id, craft_count)
    local fs_output = {}
    local y_pos = 3.5
    if craft_count > 0 then
        fs_output = {
            "style[enCraftbutton_", recipe_id, ":hovered;fgimg=ss_ui_button_craft_hammer2.png]",
            "image_button[20.3,", y_pos, ";1.6,1.1;",
            "ss_ui_button_craft_hammer1.png;enCraftbutton_", recipe_id, ";;false;true;",
            "ss_ui_button_craft_hammer3.png]",
            "hypertext[", 20.4, ",", y_pos + 1.22, ";2.0,0.5;craft_quantity;",
                "<style color=#999999 size=18>avail <b>", craft_count, "</b></style>",
            "]"
        }
    else
        fs_output = {
            "image[20.3,", y_pos, ";1.6,1.1;", "ss_ui_button_craft_hammer0.png;]",
            "hypertext[", 20.4, ",", y_pos + 1.22, ";2,0.5;craft_quantity;",
                "<style color=#999999 size=18>avail <b>", craft_count, "</b></style>",
            "]"
        }
    end
    return fs_output
end
local get_fs_craft_button = ss.get_fs_craft_button


--- @param player_inv InvRef the player inventory
--- @param list_name string the inventory list name, like "main"
--- @param item_name string the item name with format like "default:dirt"
--- @return number total_count the quantity of 'item_name' contained in 'player_inv'
local function get_item_count(player_inv, list_name, item_name)
    local total_count = 0
    local inv_size = player_inv:get_size(list_name)
    for i = 1, inv_size do
        local item = player_inv:get_stack(list_name, i)
        if item:get_name() == item_name then
            total_count = total_count + item:get_count()
        end
    end
    return total_count
end


local flag13 = false
--- @param player_inv InvRef the player inventory
--- @param recipe_id string the recipe id from which the ingredient data is pulled
--- @return table | nil ingredients_data Returns a table with two sub tables indexed as 
--- 'available' and 'missing', which contains any available and/or missing ingredients
--- for the 'recipe_id'. Takes into account any ingredients that are group items and uses
--- the items specific to those groups to search against the player inventory. Returns
--- 'nil' if 'recipe_id' is not a valid recipe.
local function get_recipe_ingredients(player_inv, recipe_id)
    debug(flag13, "    get_recipe_ingredients()")
    -- Exit early if recipe doesn't exist
    --if not recipe_id then return nil end
    --if not player_inv then return nil end

    local recipe = RECIPES[recipe_id]

    -- Initialize crafting_ingredients for the recipe
    RECIPE_INGREDIENTS[recipe_id] = {}

    local ingredients_data = { available = {}, missing = {} }

    -- Loop through recipe ingredients
    for _, item_string in ipairs(recipe.ingredients) do
        local item_string_tokens = string_split(item_string, " ")
        local item_name = item_string_tokens[1]
        local required_count = tonumber(item_string_tokens[2]) or 1  -- Default to 1 if not specified

        debug(flag13, "    item_name: " .. item_name)

        -- Handle item groups
        if item_name:find("group:") then
            debug(flag13, "      part of a group")
            local group_name = item_name:match("group:(.*)")
            debug(flag13, "      group_name: " .. group_name)
            local items_in_group = GROUP_ITEMS[group_name]
            local remaining_count = required_count

            for _, group_item in ipairs(items_in_group) do
                local available_count = get_item_count(player_inv, "main", group_item)
                if available_count > 0 then
                    local use_count = math_min(remaining_count, available_count)
                    local itemstack = ItemStack(table_concat({ group_item, " ", use_count }) )
                    table_insert(ingredients_data.available, itemstack)
                    table_insert(RECIPE_INGREDIENTS[recipe_id], itemstack)
                    remaining_count = remaining_count - use_count
                end
                if remaining_count <= 0 then break end
            end
            if remaining_count > 0 then
                table_insert(ingredients_data.missing, ItemStack(table_concat({"group:", group_name, " ", remaining_count})))
            end

        -- Handle regular items
        else
            debug(flag13, "      not part of a group")
            local available_count = get_item_count(player_inv, "main", item_name)
            local itemstack

            if available_count >= required_count then
                itemstack = ItemStack(item_name .. " " .. required_count)
            else
                if available_count > 0 then
                    itemstack = ItemStack(item_name .. " " .. available_count)
                end
                table_insert(ingredients_data.missing, ItemStack(item_name .. " " .. (required_count - available_count)))
            end

            if itemstack then
                table_insert(ingredients_data.available, itemstack)
                table_insert(RECIPE_INGREDIENTS[recipe_id], itemstack)
            end
        end
    end

    debug(flag13, "    get_recipe_ingredients() END")
    return ingredients_data
end


--- @param ingredients table contains a table of items (ItemStacks)
--- @param craftable boolean if the recipe that these ingredients beloing to is craftable
--- @param x_pos number x offset of the icons and header elements for the ingredients
--- @param y_pos number y offset of the icons and header elements for the ingredients
--- @return string x_offset x offset for the next ingredient icon in the ingred box
--- @return string formspec string containing all elements relating to all ingredients
--- that are either 'available' or 'missing'. Includes that section header as well.
local function get_fs_ingredient(player_name, ingredients, craftable, x_pos, y_pos)
    --print("    get_fs_ingredient()")
    local tooltip_bgcolor
    local formspec_groups = {}

    -- construct the 'availalbe' or 'missing' header
    local availability_text, text_color
    local p_data = player_data[player_name]
    if craftable then
        tooltip_bgcolor = p_data.ui_green
        availability_text = "available"
        text_color = p_data.ui_green
    else
        tooltip_bgcolor = p_data.ui_red
        availability_text = "missing"
        text_color = p_data.ui_red
    end
    local new_data = {
        --"image[", x_pos + 0.6, ",", y_pos + 0.2, ";", header_width, ",0.3;", header_text, ";]"
        "hypertext[",
            x_pos + 0.7, ",", y_pos + 0.2, ";4,1;availability_text;",
            "<style color=", text_color, " size=16><b>", availability_text , "</b></style>",
        "]"
    }
    table_insert(formspec_groups, new_data)

    local x_offset

    -- construct the ingredient icons
    for i, ingredient in ipairs(ingredients) do
        local ingredient_name = ingredient:get_name()
        local ingredient_name_tokens = string_split(ingredient_name, ":")
        local ingredient_description
        if ingredient_name_tokens[1] == "group" then
            --print("      ** this is a GROUP item **")
            ingredient_name = "ss:" .. string_gsub(ingredient_name, ":", "_")
            ingredient_description = "any " .. ITEM_TOOLTIP[ingredient_name]
        else
            --print("      this is a normal item")
            ingredient_description = ITEM_TOOLTIP[ingredient_name]
        end
        local ingredient_count = ingredient:get_count()
        local element_name = ingredient_name
        local xy_size = 0.75
        x_offset = tostring(x_pos + ( i * 0.8 ))
        new_data = {
            "style[enRecipeIngredient_", element_name, ";bgcolor=", tooltip_bgcolor, "]",
            "item_image_button[", x_offset, ",", y_pos + 0.65, ";", xy_size, ",", xy_size, ";",
            ingredient_name, ";", "enRecipeIngredient_", element_name, ";]",
            "tooltip[enRecipeIngredient_", element_name, ";",
            ingredient_description, " x", ingredient_count, ";", tooltip_bgcolor, ";white]",
            "label[", x_offset + 0.5, ",", (y_pos + 1.3), ";", ingredient_count, "]"
        }
        table_insert(formspec_groups, new_data)
    end

    -- combine all the formspec parts
    local combined_parts = {}
    for i, formspec_group in ipairs(formspec_groups) do
        for j, formspec_part in ipairs(formspec_group)do
            table_insert(combined_parts, formspec_part)
        end
    end

    local formspec = table_concat(combined_parts)
    --print("    get_fs_ingredient() end")
    return formspec, x_offset
end


--- @param item? ItemStack the item for which the ingredients box will show ingredients for
--- @param player_inv? InvRef simply passed into function get_recipe_ingredients()
--- @param recipe_id? string simply passed into function get_recipe_ingredients()
--- @return table fs_output a table containing formspec elements to show ingredients box
-- If function is called without arguements, then it will return formspec elements that
-- show a blanked out ingredient box featuring no items.
function ss.get_fs_ingred_box(player_name, item, player_inv, recipe_id)
    --print("  get_fs_ingred_box()")

    local fs_groups = {}
    local y_pos = 2.8

    if not (item and player_inv and recipe_id) then

        local text = "<style color=#555555 size=18><b>(select a recipe item)</b></style>]"
        local new_data = {
            table_concat({"hypertext[15.3,", y_pos - 0.2, ";8,1;ingredients_box_header;", text}),
            table_concat({"box[", X_OFFSET_RIGHT - 0.90, ",", y_pos + 0.70, ";4.80,1.55;#000000]"})
        }
        table_insert(fs_groups, new_data)

    else
        -- create the main header line that's above the ingredients box
        local recipe = RECIPES[recipe_id]
        local subname_element = ""
        if recipe.subname then
            subname_element = table_concat({
                "<style color=#999999 size=16>(", recipe.subname, ")</style>"
            })
        end
        local new_data = {
            table_concat({
                "hypertext[", 15.3, ",", y_pos + 0.2, ";8,0.5;ingredients_box_header;",
                    "<style color=#999999 size=18><b>", recipe.name, " </b></style>",
                    subname_element,
                "]"
            }),
            table_concat({"box[", X_OFFSET_RIGHT - 0.9, ",", y_pos + 0.70, ";4.80,1.55;#000000]"})
        }
        table_insert(fs_groups, new_data)

        -- construct the actual icons for 'available' and 'missing' recipe ingredients
        local ingredients = get_recipe_ingredients(player_inv, recipe_id)
        --print("    ingredients: " .. dump(ingredients))
        y_pos = y_pos + 0.62
        new_data = {}
        if ingredients then
            --print("    Recipe ingredients are valid.")
            local x_pos = X_OFFSET_RIGHT - 1.4
            if #ingredients.available == 0 and #ingredients.missing == 0 then
                --print("    Recipe has no listed ingredients.")

            elseif #ingredients.available == 0 then
                --print("    Recipe has no AVAIL ingredients")
                local missing_ingredients = ingredients.missing
                local x_offset
                new_data[1], x_offset = get_fs_ingredient(player_name, missing_ingredients, false, x_pos, y_pos)

            elseif #ingredients.missing == 0 then
                --print("    Recipe has no MISSING ingredient:")
                local available_ingredients = ingredients.available
                local x_offset
                new_data[1], x_offset = get_fs_ingredient(player_name, available_ingredients, true, x_pos, y_pos)

            else
                --print("    Recipe has BOTH Avail and Missing ingredients")
                local missing_ingredients = ingredients.missing
                local new_x_pos = ""
                new_data[1], new_x_pos = get_fs_ingredient(player_name, missing_ingredients, false, x_pos, y_pos)

                local available_ingredients = ingredients.available
                x_pos = tonumber(new_x_pos) + 0.60
                local x_offset
                new_data[2], x_offset = get_fs_ingredient(player_name, available_ingredients, true, x_pos, y_pos)

            end
            table_insert(fs_groups, new_data)

        else
            --print("    ERROR. Recipe ingredients table is NIL.")
        end

    end

    local fs_output = {}
    for i, formspec_group in ipairs(fs_groups) do
        for j, formspec_part in ipairs(formspec_group)do
            table_insert(fs_output, formspec_part)
        end
    end

    --print("  get_fs_ingred_box() end")
    return fs_output

end
local get_fs_ingred_box = ss.get_fs_ingred_box


--- @param player_inv InvRef the player inventory
--- @param recipe_category string filter the recipe icons based on this category
--- @return table craftable_data table where each element is a table of recipe data that
--- include: recipe_id, item_icon, item_label, craftable_tag, craftable, and tooltip.
--- Each recipe data is craftable or not, based on items present in player's inventory.
local function get_recipe_icon_data(player_name, player_inv, recipe_category)
    --print("      get_recipe_icon_data()")
    local craftable_data = {}

    -- for each recipe defined in recipes.lua
	for recipe_id, recipe in pairs(RECIPES) do

        local category_matched = false
        for i, category in ipairs(recipe.categories) do
            if category == recipe_category then
                category_matched = true
                --print("  recipe category (" .. category .. ") MATCHES button category (" .. recipe_category .. ")")
            else
                --print("  recipe category (" .. category .. ") does NOT match button category (" .. recipe_category .. ")")
            end
        end

        local data = {}
        if category_matched then

            --print("        recipe_id: " .. recipe_id)
            data.recipe_id = recipe_id
            data.item_icon = recipe.icon
            data.item_icon2 = recipe.icon2
            if recipe.subname then
                data.tooltip = recipe.name .. " (" .. recipe.subname .. ")"
            else
                data.tooltip = recipe.name
            end

            -- pending implementation
            local output_count = #recipe.output
            if output_count > 1 then
                data.item_label = ""
            else
                data.item_label = ""
            end

            -- go through each ingredient in the recipe and determine if it is available
            -- or missing from the player inventory
            local ingredients = get_recipe_ingredients(player_inv, recipe_id)
            if ingredients then  -- Check if ingredients is not nil
                --print("  Ingredients table is valid!")
                if #ingredients.missing == 0 then
                    data.craftable = true
                    data.craftable_tag = "X"
                    data.background_color = player_data[player_name].ui_green
                    --print("        ** craftable **")
                else
                    data.craftable = false
                    data.craftable_tag = ""
                    data.background_color = player_data[player_name].ui_red
                    --print("        missing ingredients")
                end
            else
                --print("  Error: ingredients table NIL. Using dummy data default:dirt...")
                ingredients = {
                    available = { ItemStack({name="default:dirt", count=1}) },
                    missing = { ItemStack({name="default:dirt", count=1}) }
                }
            end

            table_insert(craftable_data, data)

        else
            --print("  Recipe and button category (" .. recipe_category .. ") do NOT match. SKIPPING from recipe grid.)")
        end
	end

    --print("      get_recipe_icon_data() end")
    return craftable_data
end


--- @param player_inv InvRef the player inventory
--- @param recipe_category string filter the recipe icons based on this category
--- @return table craftable_data formspec ui elements necessary to display the quick
--- crafting style grid.
function ss.get_fs_crafting_grid(player_name, player_inv, recipe_category)
    --print("    get_fs_crafting_grid()")
    --print("      recipe_category: " .. recipe_category)

    local formspec_groups = {}
    local new_data = {}
    local combined_parts = {}

    -- retrieve needed data to construct the formspec icon/slot for each recipe item in
    -- the crafting grid: recipe_id, item_icon, craftable_tag, etc
    local craftable_data = get_recipe_icon_data(player_name, player_inv, recipe_category)
    local craftable_data_count = #craftable_data
    --print("    craftable_data_count: " .. craftable_data_count)

    if craftable_data_count > 0 then
        -- sort the the table so that all craftable recipes are first and non craftables after,
        -- and then also sorted by recipe_id
        table_sort(craftable_data, function(a, b)
            if a.craftable == b.craftable then
                return a.recipe_id < b.recipe_id
            else
                return a.craftable
            end
        end)

        local columns_per_row = 6
        local recipe_icons_total_rows = math_floor((#craftable_data - 1)/ columns_per_row) + 1
        local scrollcontainer_visible_rows_max = 6

        -- value that was manually calculated. must be added to 'max_scroll_value' for
        -- every extra row beyond the 'scrollcontainer_visible_rows_max' value
        local ROW_SIZE_FACTOR = 26.5

        -- the number of recipe icon rows that is hidden below the scrollcontainer bounds
        -- because it exceeds the visible rows max, thus requiring player to use scrollbar
        -- to scroll further down to view those hidden rows. 
        local hidden_rows_count_for_scrolling = recipe_icons_total_rows - scrollcontainer_visible_rows_max
        if hidden_rows_count_for_scrolling < 0 then hidden_rows_count_for_scrolling = 0 end

        -- the total height of the scrollcontainer including any added height from scrolling
        -- to view entire grid
        local max_scroll_value = hidden_rows_count_for_scrolling * ROW_SIZE_FACTOR

        -- scroll_container customization options
        new_data = {
            table_concat({"scrollbaroptions[min=0;max=", max_scroll_value, ";smallstep=10;largestep=100;thumbsize=10;arrows=show]"})
        }
        table_insert(formspec_groups, new_data)

        -- add the vertical scrollbar if number of rows of recipe icons exceed are certain
        -- row count maximum 'scrollcontainer_visible_rows_max'
        if recipe_icons_total_rows > scrollcontainer_visible_rows_max then
            new_data = { "scrollbar[21.6,5.3;0.3,5.0;vertical;enScrollbar_crafting;0]" }
            table_insert(formspec_groups, new_data)
        end

        -- add scroll_container where all the recipe icons will reside. if more icons than
        -- can be shown in the scroll_container, the vertical scrollbar will appear.
        new_data = {
            table_concat({"scroll_container[15.4,5.3;7.75,5.0;enScrollbar_crafting;vertical;", 0.05, "]"})
        }
        table_insert(formspec_groups, new_data)

        -- construct the actual recipe item icon with it's associated properties which
        -- include: icon image, craftable color indicator, etc
        for i, item_craft_data in ipairs(craftable_data) do

            -- calculate x and y position of item_image_button[] and image[] elements
            local x_spos = tostring((i - 1) % 6)
            local y_spos = tostring(math_floor((i - 1) / 6))

            local item_icon = item_craft_data.item_icon
            if item_craft_data.item_icon2 then item_icon = item_craft_data.item_icon2 end

            local recipe_id = item_craft_data.recipe_id
            local craftable_tag = item_craft_data.craftable_tag
            local item_label = item_craft_data.item_label
            local item_bg_color = item_craft_data.background_color
            local tooltip_text = item_craft_data.tooltip

            --print("      recipe_id: " ..  recipe_id)
            --print("      item_icon: " ..  item_icon)

            -- set highlight color of the recipe item icon to a dark green if it's craftable
            -- or dark red if it's not craftable.

            new_data = {
                table_concat({
                    "style[enRecipe", craftable_tag, "_", recipe_id, ";bgcolor=", item_bg_color, "]",
                    "item_image_button[", x_spos, ",", y_spos, ";1,1;", item_icon, ";",
                        "enRecipe", craftable_tag, "_", recipe_id, ";", item_label, "]",
                    "tooltip[", "enRecipe", craftable_tag, "_", recipe_id, ";",
                        tooltip_text, ";", item_bg_color, ";white]"
                })
            }
            table_insert(formspec_groups, new_data)
        end

        -- add final final delimeter elements to the formspec
        table_insert(formspec_groups, {"scroll_container_end[]"})

        -- combine all the formspec parts
        for i, formspec_group in ipairs(formspec_groups) do
            for j, formspec_part in ipairs(formspec_group)do
                table_insert(combined_parts, formspec_part)
            end
        end

    else
        combined_parts = {
            "hypertext[", X_OFFSET_RIGHT - 0.60, ",6.0;8,3;crafting_grid_text;",
                "<style color=#000000 size=18><b>",
                    "No HAND crafting recipes known\n",
                    "for ", string_upper(recipe_category), " category.",
                "</b></style>]"
        }
    end

    --print("  combined_parts:" .. dump(combined_parts))
    --print("    get_fs_crafting_grid() end")
	return combined_parts
end
local get_fs_crafting_grid = ss.get_fs_crafting_grid


local flag20 = false
--- @param player_inv InvRef the player inventory
--- @param recipe_id string the recipe id from which the ingredient data is pulled
--- @return number craftable_count how many times the recipe item can be crafted based
-- on the player's inventory content 'player_inv'. Also handles group items.
function ss.get_craftable_count(player_inv, recipe_id)
    debug(flag20, "\nget_craftable_count()")
    local recipe_ingredients = get_recipe_ingredients(player_inv, recipe_id)
    local craftable_count = 0
    if recipe_ingredients then
        local avail_recipe_ingredients = recipe_ingredients.available

        if #recipe_ingredients.missing == 0 then
            debug(flag20, "  available ingredients exists.")
            local craftable_counts = {}
            debug(flag20, "  recipe_ingredients: " .. dump(avail_recipe_ingredients))

            for _, ingredient in ipairs(avail_recipe_ingredients) do
                local item_name = ingredient:get_name()
                local item_count = ingredient:get_count()
                debug(flag20, "  item_name: " .. item_name)
                debug(flag20, "    item_count: " .. item_count)

                -- Get the available count from player's inventory
                local available_count = get_item_count(player_inv, "main", item_name)
                debug(flag20, "    available_count: " .. available_count)

                local max_craftable_with_this_ingredient = math_floor(available_count / item_count)
                table_insert(craftable_counts, max_craftable_with_this_ingredient)
            end

            craftable_count = math_min(unpack(craftable_counts))
        else
            debug(flag20, "  no available ingredients exists.")
        end
    else
        debug(flag20, "  recipe doesn't exist for recipe_id: " .. recipe_id)
    end

    debug(flag20, "  craftable_count: " .. craftable_count)
    debug(flag20, "get_craftable_count() end")
    return craftable_count
end
local get_craftable_count = ss.get_craftable_count


local flag10 = false
--- @param player ObjectRef the player object
--- @param amount number how many inventory slots to add or remove
-- Changes the main inventory list 'size' by the 'amount' value. The new size is kept
-- within the allowable min and max slot amounts. Any items that was in any removed
-- slots are moved to an empty slot or dropped to the ground if inventory is full.
local function set_inventory_size(player, p_data, amount)
    debug(flag10, "set_inventory_size()")
    local player_meta = player:get_meta()
    local player_inv = player:get_inventory()
    local leftover_items_weight_total = 0
    local inv_size = player_inv:get_size("main")
    debug(flag10, "  current inv_size: " .. inv_size)
    local new_inv_size = inv_size + amount
    debug(flag10, "  requested inv_size: " .. new_inv_size)

    if new_inv_size > INV_SIZE_MAX then
        debug(flag10, "  " .. new_inv_size .. " > Max of " .. INV_SIZE_MAX .. ". Using size " .. INV_SIZE_MAX .. ".")

        if player_inv:set_size("main", INV_SIZE_MAX) then
            inv_size = player_inv:get_size("main")
            debug(flag10, "  Successfully set inv size to: " .. inv_size)
        else debug(flag10, "  Error increasing inv size by: " .. amount) end

        local existing_credit = p_data.slot_bonus_credit
        local new_credit = new_inv_size - INV_SIZE_MAX
        local updated_credit = existing_credit + new_credit
        p_data.slot_bonus_credit = updated_credit
        player_meta:set_int("slot_bonus_credit", updated_credit)
        debug(flag10, "  existing_credit(" .. existing_credit .. ") + new_credit(" .. new_credit .. ") = " .. updated_credit)
        new_inv_size = INV_SIZE_MAX
        debug(flag10, "  updated slot_bonus_credit: " .. updated_credit)

    elseif new_inv_size < INV_SIZE_MIN then
        debug(flag10, "  " .. new_inv_size .. " < " .. INV_SIZE_MIN .. ". Using size " .. INV_SIZE_MIN .. ".")
        new_inv_size = INV_SIZE_MIN
    else
        -- removing slots
        if amount < 0 then

            local items_were_dropped = false
            for i=1, -amount do
                debug(flag10, "  Removing slot #" .. inv_size .. "...")
                local item = player_inv:get_stack("main", inv_size)
                local item_name = item:get_name()
                player_inv:set_size("main", inv_size - 1)
                if item_name then
                    if item_name == "" then
                        debug(flag10, "    Removed an empty slot.")
                    else
                        debug(flag10, "    item: " .. item_name)
                        local leftover_item = player_inv:add_item("main", item)
                        local leftover_item_name = leftover_item:get_name()
                        if leftover_item_name == "" then
                            debug(flag10, "    Item successfully relocated to another empty slot.")
                        else
                            debug(flag10, "    Inventory full. Dropped item to ground.")
                            mt_add_item(player:get_pos(), leftover_item)
                            items_were_dropped = true

                            local leftover_item_weight = get_itemstack_weight(leftover_item)
                            leftover_items_weight_total = leftover_items_weight_total + leftover_item_weight
                        end
                    end
                else debug(flag10, "  ERROR - Unexpected 'item_name' value: NIL") end
                inv_size = player_inv:get_size("main")
            end
            if items_were_dropped then
                notify(player, "inventory", "Items dropped due to reduced inventory space.", NOTIFY_DURATION, 0.5, 0, 2)
                debug(flag10, "    Items dropped. total weight: " .. leftover_items_weight_total)
            end

        -- adding slots
        elseif amount > 0 then
            if player_inv:set_size("main", new_inv_size) then
                inv_size = player_inv:get_size("main")
                debug(flag10, "  Successfully increased inv size to: " .. inv_size)
            else debug(flag10, "  Error increasing inv size by: " .. amount) end
        -- unexpected condition
        else debug(flag10, "  Unexpected AMOUNT value: " .. amount) end
    end

    debug(flag10, "set_inventory_size() end")
    return leftover_items_weight_total
end






local flag12 = false
--- @param player ObjectRef the player object
--- @param fs table the table containing subtables of formspec elements
function ss.update_inventory_weight_max(player, fs)
	debug(flag12, "  update_inventory_weight_max()")
    local player_meta = player:get_meta()

    local max_weight = player_meta:get_float("weight_max")
    debug(flag12, "    curr max_weight: " .. max_weight)

    local player_inv = player:get_inventory()
    local inv_size = player_inv:get_size("main")
    debug(flag12, "    updating weight max based on main inventory slot count: " .. inv_size)
    local p_data = player_data[player:get_player_name()]
    local new_max_weight = inv_size * p_data.weight_max_per_slot
    debug(flag12, "    new_max_weight: " .. new_max_weight)

    -- update HUD vertical stat bars.
    local update_data = {"normal", "weight", new_max_weight, 1, 1, "max", "set", true}
    update_stat(player, p_data, player_meta, update_data)

    -- update formspec weight section
	fs.center.weight = get_fs_weight(player)

	debug(flag12, "  update_inventory_weight_max() END")
end
local update_inventory_weight_max = ss.update_inventory_weight_max


--- @param player_meta MetaDataRef used to access the meta data 'slot_bonus_credit'
--- @param bag_slot_bonus number the number of extra inventory slots the bag provides
--- @return number slot_count_to_remove how many inventory slots from "main" inventory
--- list to remove. Accounts for any "slot_bonus_credit" the player has due to equipping
--- enough bags to exceed the max allowable inv size for "main".
local function get_slot_count_to_remove(player_meta, p_data, bag_slot_bonus)
    print("get_slot_count_to_remove()")
    local slot_bonus_credit = p_data.slot_bonus_credit
    local slot_count_to_remove = slot_bonus_credit - bag_slot_bonus
    print("  slot_bonus_credit(" .. slot_bonus_credit ..
        ") - bag_slot_bonus(" .. bag_slot_bonus ..
        ") = slot_count_to_remove(" .. slot_count_to_remove .. ")")

    if slot_count_to_remove < 0 then
        slot_count_to_remove = -slot_count_to_remove
        p_data.slot_bonus_credit = 0
        player_meta:set_int("slot_bonus_credit", 0)
        print("  Used up all bonus credits and still remain " .. slot_count_to_remove .. " slot to remove.")

    elseif slot_count_to_remove > 0 then
        p_data.slot_bonus_credit = slot_count_to_remove
        player_meta:set_int("slot_bonus_credit", slot_count_to_remove)
        print("  " .. slot_count_to_remove .. " bonus credits remain. No actual slots to remove.")
        slot_count_to_remove = 0

    else
        slot_count_to_remove = 0
        p_data.slot_bonus_credit = 0
        player_meta:set_int("slot_bonus_credit", 0)
        print("  Slots to remove used up exactly the amount of bonus credits. No actual slots to remove.")
    end

    print("get_slot_count_to_remove() end")
    return slot_count_to_remove
end


local flag19 = false
--- @param player ObjectRef the player object
--- @param item ItemStack the item from which the item info will be shown
--- @param p_data table reference to table with data specific to this player
--- @param action string the context which can be 'move', 'put', or 'recipe'
--- @return boolean refresh_inventory_ui whether or not the formspec relating to the
--- display of the item info details will be refreshed
local function show_item_info(player, item, p_data, action)
    debug(flag19, "  show_item_info()")
    local refresh_inventory_ui = false
    local player_meta = player:get_meta()
    local fs = p_data.fs
    local prev_item_name = p_data.prev_iteminfo_item
    local item_name = item:get_name()
    debug(flag19, "    item_name: " .. item_name)
    debug(flag19, "    prev_item_name: " .. prev_item_name)

    -- when the player takes an item from main inventory and places onto item info slot
    if action == "move" then
        local prev_item_recipe = RECIPES[prev_item_name]
        local prev_recipe_name = ""
        if prev_item_recipe then
            debug(flag19, "    prev item was a recipe_id!")
            prev_recipe_name = prev_item_recipe.icon
        end

        if item_name == prev_item_name then
            debug(flag19, "    prev item was also from INVENTORY and is SAME")
            if item_name == "ss:item_bundle" then
                debug(flag19, "    this is an item bundle. always refresh..")
                fs.center.item_info = get_fs_item_info(player, item)
                refresh_inventory_ui = true
            else
                debug(flag19, "    not an item bundle.")
            end

        elseif item_name == prev_recipe_name then
            debug(flag19, "    prev item was a RECIPE icon and is SAME. no action.")

        else
            debug(flag19, "    curr and prev items are DIFFERENT. updating item info...")
            fs.center.item_info = get_fs_item_info(player, item)
            refresh_inventory_ui = true
        end

    -- when player clicks on an item from the recipes grid, and the previous recipe item
    -- was different, then refresh the item info display
    elseif action == "recipe" then
        debug(flag19, "    Item info slot item is DIFFERENT! Refreshing item info panel...")
        fs.center.item_info = get_fs_item_info(player, item)
        refresh_inventory_ui = true

    else
        debug(flag19, "    Unexpected action: " .. action)
    end

    p_data.prev_iteminfo_item = item_name
    player_meta:set_string("prev_iteminfo_item", item_name)
    debug(flag19, "  show_item_info() end")
    return refresh_inventory_ui
end


local flag11 = false
-- update the formspec elements relating to the crafting ingredients box, crafting
-- button, and crafting grid. this function is typically called after there is a
-- change in the contents of the player's inventory, like when items are dropped,
-- picked up, moved to or from a campfire or storage containers, etc
function ss.update_crafting_ingred_and_grid(player_name, player_inv, p_data, fs)
    debug(flag11, "  update_crafting_ingred_and_grid()")
    local recipe_id = p_data.prev_recipe_id
    local recipe = RECIPES[recipe_id]
    debug(flag11, "    recipe_id: " .. recipe_id)

    -- update ingredients box and crafting button
    fs.right.ingredients_box = ss.get_fs_ingred_box(player_name, ItemStack(recipe.icon), player_inv, recipe_id)
    local crafting_count = ss.get_craftable_count(player_inv, recipe_id)
    fs.right.craft_button = ss.get_fs_craft_button(recipe_id, crafting_count)
    debug(flag11, "    crafting_count: " .. crafting_count)

    -- update crafting grid
    fs.right.craft_grid = ss.get_fs_crafting_grid(player_name, player_inv, p_data.recipe_category)
    debug(flag11, "  update_crafting_ingred_and_grid() END")
end
local update_crafting_ingred_and_grid = ss.update_crafting_ingred_and_grid




local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() inventory.lua")
    local player_name = player:get_player_name()
	local player_meta = player:get_meta()
    local p_data = player_data[player_name]
    local player_status = p_data.player_status
    local metadata

    metadata = player_meta:get_int("weight_max_per_slot")
    p_data.weight_max_per_slot = (metadata ~= 0 and metadata) or SLOT_WEIGHT_MAX

    -- stores the latest category tab that was clicked on the crafting pane
    metadata = player_meta:get_string("recipe_category")
    p_data.recipe_category = (metadata ~= "" and metadata) or "tools"

    -- stores an item_name or recipe_id of the item that was last shown in the item
    -- info slot. used to prevent unneeeded item info panel refresh if the item to
    -- be shown is the same as the previously shown item.
    p_data.prev_iteminfo_item = player_meta:get_string("prev_iteminfo_item")

    -- stores the recipe_id of the latest recipe item that was clicked on from the
    -- crafting grid.
    p_data.prev_recipe_id = player_meta:get_string("prev_recipe_id")

    -- stores how many inv slots beyond the slot max the player is credited due
    -- to equipped bags. needed for proper restore of inv slots as bags are added
    -- or removed from the bag slots. used in function get_slot_count_to_remove()
    p_data.slot_bonus_credit = player_meta:get_int("slot_bonus_credit")

    -- how much xp gained for crafting an item. this value is multiplied by the
    -- number of outputs if the crafting recipe results in multiple items.
    metadata = player_meta:get_float("experience_gain_crafting")
    p_data.experience_gain_crafting = (metadata ~= 0 and metadata) or 0.5


	if player_status == 0 then
		debug(flag1, "  new player")
        local player_inv = player:get_inventory()

        debug(flag1, "initializing inventory formspec...")
        debug(flag1, "INV_SIZE_START: " .. INV_SIZE_START)
        player_inv:set_size("main", INV_SIZE_START)
        player_inv:set_size("clothing_slot_eyes", 1)
        player_inv:set_size("clothing_slot_neck", 1)
        player_inv:set_size("clothing_slot_chest", 1)
        player_inv:set_size("clothing_slot_hands", 1)
        player_inv:set_size("clothing_slot_legs", 1)
        player_inv:set_size("clothing_slot_feet", 1)
        player_inv:set_size("armor_slot_head", 1)
        player_inv:set_size("armor_slot_face", 1)
        player_inv:set_size("armor_slot_chest", 1)
        player_inv:set_size("armor_slot_arms", 1)
        player_inv:set_size("armor_slot_legs", 1)
        player_inv:set_size("armor_slot_feet", 1)
        player_inv:set_size("item_info_slot", 1)
        player_inv:set_size("bag_slots", 3)


        -- initialize data that relates to having the stone axe as the default
        -- selected crafting recipe item
        local recipe_id = "tool_axe_stone"
        local recipe = RECIPES[recipe_id]
        local item_name = recipe.icon
        local crafting_count = get_craftable_count(player_inv, recipe_id)
        p_data.prev_recipe_id = recipe_id
        player_meta:set_string("prev_recipe_id", recipe_id)


        -- initialize the formspec 'fs' table with default elements which are grouped
        -- in a way for easier modular modificationthis table represents the full player
        -- inventory ui formspec and all elements within are combined (via table.concat)
        -- before sending to screen via show_formspec(). this table is serialized and
        -- saved into the player meta string 'fs' and is recalled when needed for
        -- modification and display via show_formspec(). thus, the formspec generated from
        -- get_inventory_formspec() is no longer used.
        local new_fs = {
            setup = ss.get_fs_setup(),
            left = {
                stats =             get_fs_player_stats(player_name),
                left_tabs =         get_fs_tabs_left(),
                player_avatar =     get_fs_player_avatar(p_data.avatar_mesh, p_data.avatar_texture_base),
                equipment_slots =   get_fs_equip_slots(p_data),
                equipment_stats =   get_fs_equipment_buffs(player_name)
            },
            center = {
                item_info_slot =    get_fs_item_info_slot(),
                item_info =         get_fs_item_info(player, ItemStack(item_name)),
                inventory_grid =    get_fs_inventory_grid(),
                bag_slots =         get_fs_bag_slots(player_inv, player_name),
                weight =            get_fs_weight(player)
            },
            right = {
                craft_title =       get_fs_craft_title("hand", "tools"),
                craft_categories =  get_fs_craft_categories("tools"),
                craft_item_icon =   get_fs_craft_item_icon(item_name),
                craft_button =      get_fs_craft_button(recipe_id, crafting_count),
                ingredients_box =   get_fs_ingred_box(player_name, ItemStack(item_name), player_inv, recipe_id),
                craft_grid =        get_fs_crafting_grid(player_name, player_inv, "tools")
            }
        }
        player_data[player_name].fs = new_fs
        player_meta:set_string("fs", mt_serialize(new_fs))
        player:set_inventory_formspec(build_fs(new_fs))
        debug(flag1, "  fs table initialized and saved")


	elseif player_status == 1 then
		debug(flag1, "  existing player")

        -- restore player invnetory fromspec from metadata and apply to the game
        --p_data.fs = core.deserialize(player_meta:get_string("fs"))
        local saved_fs = core.deserialize(player_meta:get_string("fs"))
        if saved_fs then
            player_data[player_name].fs = saved_fs
            player:set_inventory_formspec(build_fs(saved_fs))
        else
            debug(flag1, "  ERROR - 'saved_fs' is NIL")
        end

	elseif player_status == 2 then
        debug(flag1, "  dead player")

    else
        debug(flag1, "  ERROR - Unexpected 'player_status' value: " .. player_status)
    end

	debug(flag1, "\nregister_on_joinplayer() END")
end)


local flag2 = false
core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    debug(flag2, "\nregister_allow_player_inventory_action() inventory.lua")

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    debug(flag2, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag2, "  active_tab: " .. p_data.active_tab)

    if p_data.formspec_mode ~= "main_formspec" then
		debug(flag2, "  interaction not from main formspec. NO FURTHER ACTION.")
		debug(flag2, "register_allow_player_inventory_action() END " .. core.get_gametime())
		return
	elseif p_data.active_tab ~= "main" then
        debug(flag2, "  interaction from main formspec, but not MAIN tab. NO FURTHER ACTION.")
        debug(flag2, "register_allow_player_inventory_action() END " .. core.get_gametime())
		return
    end

    --debug(flag2, "  inventory_info: " .. dump(inventory_info))

    local refresh_inventory_ui = false
    local player_meta = player:get_meta()
    local fs = p_data.fs
    local quantity_allowed

    if action == "move" then
        debug(flag2, "  action: MOVE")
        local to_list = inventory_info.to_list
        local to_index = inventory_info.to_index
        local to_item = inventory:get_stack(to_list, to_index)

        local from_list = inventory_info.from_list
        local from_index = inventory_info.from_index
        local item = inventory:get_stack(from_list, from_index)
        local item_name = item:get_name()

        local item_count = item:get_count()
        quantity_allowed = item_count

        debug(flag2, "  itemstack: " .. item_name .. " " .. item_count)
        debug(flag2, "  to_list: " .. to_list)

        if to_list == "item_info_slot" then
            debug(flag2, "  to item_info_slot")
            play_sound("item_move", {item_name = item_name, player_name = player_name})

            refresh_inventory_ui = show_item_info(player, item, p_data, "move")
            quantity_allowed = 0

        -- clothing slots
        elseif to_list == "clothing_slot_eyes" then
            debug(flag2, "  to clothing_slot_eyes")
            if CLOTHING_EYES[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not an eye accessory", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "clothing_slot_neck" then
            debug(flag2, "  to clothing_slot_neck")
            if CLOTHING_NECK[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not a neck accessory", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "clothing_slot_chest" then
            debug(flag2, "  to clothing_slot_chest")
            if CLOTHING_CHEST[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not clothing for upper body", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "clothing_slot_hands" then
            debug(flag2, "  to clothing_slot_hands")
            if CLOTHING_HANDS[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not wearable on hands", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "clothing_slot_legs" then
            debug(flag2, "  to clothing_slot_legs")
            if CLOTHING_LEGS[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not clothing for lower body", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "clothing_slot_feet" then
            debug(flag2, "  to clothing_slot_feet")
            if CLOTHING_FEET[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not proper foot support", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        -- armor slots

        elseif to_list == "armor_slot_head" then
            debug(flag2, "  to armor_slot_head")
            if ARMOR_HEAD[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not head armor", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "armor_slot_face" then
            debug(flag2, "  to armor_slot_face")
            if ARMOR_FACE[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not face protection", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "armor_slot_chest" then
            debug(flag2, "  to armor_slot_chest")
            if ARMOR_CHEST[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not chest armor", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "armor_slot_arms" then
            debug(flag2, "  to armor_slot_arms")
            if ARMOR_ARMS[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not arm protection", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "armor_slot_legs" then
            debug(flag2, "  to armor_slot_legs")
            if ARMOR_LEGS[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not leg protection", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "armor_slot_feet" then
            debug(flag2, "  to armor_slot_feet")
            if ARMOR_FEET[item_name] then
                quantity_allowed = 1
            else
                notify(player, "inventory", "Not feet protection", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "bag_slots" then
            debug(flag2, "  Attempt to move item to bag slot")

            if BAG_NODE_NAMES_ALL[item_name] then
                debug(flag2, "  item is a bag")

                if to_item:is_empty() then
                    debug(flag2, "  target slot empty")

                    if item_count > 1 then
                        debug(flag2, "  only 1 quantity allowed")
                        notify(player, "inventory", "only 1 bag per slot allowed", NOTIFY_DURATION, 0.5, 0, 2)
                        quantity_allowed = 1
                    end

                else
                    debug(flag2, "  target slot has a bag")
                    notify(player, "inventory", "only 1 bag per slot allowed", NOTIFY_DURATION, 0.5, 0, 2)
                    quantity_allowed = 0
                end

            else
                debug(flag2, "  item is not a bag. move disallowed.")
                notify(player, "inventory", "Only bags can be equipped", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0
            end

        elseif to_list == "main" then
            debug(flag2, "  Moved any item to another slot within main inventory: Allowed")
            if SPILLABLE_ITEM_NAMES[item_name] then
                debug(flag2, "  this is a filled cup!")
                if to_index > 8 then
                    debug(flag2, "  cannot be placed in main inventory")
                    notify(player, "inventory", NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
                    quantity_allowed = 0
                end
            end

        else
            debug(flag2, "ERROR - Unexpected 'to_list' value: " .. to_list)
            notify(player, "inventory", "Item cannot be used there", NOTIFY_DURATION, 0.5, 0, 2)
            quantity_allowed = 0
        end

    elseif action == "take" then
        debug(flag2, "  Taking item from inventory always allowed")
        local item = inventory_info.stack
        quantity_allowed = item:get_count()

    else
        debug(flag2, "  Unexpected action: " .. action)

    end

    if refresh_inventory_ui then
        debug(flag2, "  ** UI Refreshed! ** by register_allow_player_inventory_action()")

        -- note: this is necessary to allow item info slot to update when chest/storage formospec
        -- is active. when default crafting formspec is active, item info slot will still update
        -- without this code
        player_meta:set_string("fs", mt_serialize(fs))
        local formspec = build_fs(fs)
        player:set_inventory_formspec(formspec)
        mt_show_formspec(player_name, "ss:ui_main", formspec)

    else
        debug(flag2, "  UI not refreshed.")
    end

    --debug(flag2,("fs: " .. dump(fs))
    debug(flag2, "  quantity_allowed: " .. quantity_allowed)
    debug(flag2,"register_allow_player_inventory_action() end " .. core.get_gametime() .. "***\n")
    return quantity_allowed

end)


local flag8 = false
core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    debug(flag8, "\nregister_on_player_inventory_action() inventory.lua")

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    debug(flag8, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag8, "  active_tab: " .. p_data.active_tab)

    if p_data.formspec_mode ~= "main_formspec" then
		debug(flag8, "  interaction not from main formspec. NO FURTHER ACTION.")
		debug(flag8, "register_allow_player_inventory_action() end " .. core.get_gametime())
		return
	elseif p_data.active_tab ~= "main" then
        debug(flag8, "  interaction from main formspec, but not MAIN tab. NO FURTHER ACTION.")
        debug(flag8, "register_allow_player_inventory_action() END " .. core.get_gametime())
		return
    end

    local player_meta = player:get_meta()
    local fs = player_data[player_name].fs

    --debug(flag8, "  initial inventory_info: " .. dump(inventory_info))

    if action == "move" then

        local to_list = inventory_info.to_list
        local to_index = inventory_info.to_index
        local from_list = inventory_info.from_list
        local from_index = inventory_info.from_index
        local item = inventory:get_stack(to_list, to_index)
        local item_name = item:get_name()

        debug(flag8, "  MOVED")
        debug(flag8, "  initial slot_bonus_credit: " .. p_data.slot_bonus_credit)
        play_sound("item_move", {item_name = item_name, player_name = player_name})

        if from_list == "main" then

            if to_list == "bag_slots" then

                -- update inv slot count and max inventory weight
                local slot_change_amount = BAG_SLOT_BONUS[item_name]
                debug(flag8, "  slot_up_amount: " .. slot_change_amount)
                set_inventory_size(player, p_data, slot_change_amount)
                update_inventory_weight_max(player, fs)

                -- refresh bag slots to to show green condition indicator
                fs.center.bag_slots = get_fs_bag_slots(player:get_inventory(), player_name)

                -- refresh formspec display
                player_meta:set_string("fs", mt_serialize(fs))
                local formspec = build_fs(fs)
                player:set_inventory_formspec(formspec)
                mt_show_formspec(player_name, "ss:ui_main", formspec)

            elseif to_list == "clothing_slot_chest" then
                debug(flag8, "  equipping clothing onto chest slot.. " .. item_name)
                update_clothes(player, item, to_list, 1)

            elseif to_list == "clothing_slot_legs" then
                debug(flag8, "  equipping clothing onto legs slot.. " .. item_name)
                update_clothes(player, item, to_list, 1)

            elseif to_list == "clothing_slot_feet" then
                debug(flag8, "  equipping clothing onto feet slot.. " .. item_name)
                update_clothes(player, item, to_list, 1)

            elseif to_list == "clothing_slot_neck" then
                debug(flag8, "  equipping clothing onto neck slot.. " .. item_name)
                update_clothes(player, item, to_list, 1)

            elseif to_list == "clothing_slot_hands" then
                debug(flag8, "  equipping clothing onto hands slot.. " .. item_name)
                update_clothes(player, item, to_list, 1)

            elseif to_list == "clothing_slot_eyes" then
                debug(flag8, "  equipping clothing onto eyes slot.. " .. item_name)
                update_clothes(player, item, to_list, 1)

            elseif to_list == "armor_slot_head" then
                debug(flag8, "  equipping armor onto head slot.. " .. item_name)
                update_armor(player, item, to_list, 1)

            elseif to_list == "armor_slot_face" then
                debug(flag8, "  equipping armor onto face slot.. " .. item_name)
                update_armor(player, item, to_list, 1)

            elseif to_list == "armor_slot_chest" then
                debug(flag8, "  equipping armor onto chest slot.. " .. item_name)
                update_armor(player, item, to_list, 1)

            elseif to_list == "armor_slot_arms" then
                debug(flag8, "  equipping armor onto arms slot.. " .. item_name)
                update_armor(player, item, to_list, 1)

            elseif to_list == "armor_slot_legs" then
                debug(flag8, "  equipping armor onto legs slot.. " .. item_name)
                update_armor(player, item, to_list, 1)

            elseif to_list == "armor_slot_feet" then
                debug(flag8, "  equipping armor onto feet slot.. " .. item_name)
                update_armor(player, item, to_list, 1)

            else
                debug(flag8, "  Unimplemented action: " .. from_list .. " >> " .. to_list)
            end

        elseif from_list == "bag_slots" then
            debug(flag8, "  moving bag out of bag slot")

            if to_list == "main" then
                debug(flag8, "  .. and placing it in main inventory")

                -- reduce inv slot count and max inventory weight
                local dropped_items_weight = 0
                local slot_change_amount = ss.BAG_SLOT_BONUS[item_name]
                debug(flag8, "  slot_change_amount: " .. slot_change_amount)
                dropped_items_weight = set_inventory_size(player, p_data,
                    -get_slot_count_to_remove(player_meta, p_data, slot_change_amount)
                )
                update_inventory_weight_max(player, fs)
                debug(flag8, "  dropped weight: " .. dropped_items_weight)

                -- refresh formspec to have bag slots show dark green highlight
                fs.center.bag_slots = get_fs_bag_slots(player:get_inventory(), player_name)
                player_meta:set_string("fs", mt_serialize(fs))
                local formspec = build_fs(fs)
                player:set_inventory_formspec(formspec)
                mt_show_formspec(player_name, "ss:ui_main", formspec)

            elseif to_list == "bag_slots" then
                debug(flag8, "  .. and placing into a different bag slot")

                -- refresh formspec to have bag slots show dark green highlightight
                fs.center.bag_slots = get_fs_bag_slots(player:get_inventory(), player_name)
                player_meta:set_string("fs", mt_serialize(fs))
                local formspec = build_fs(fs)
                player:set_inventory_formspec(formspec)
                mt_show_formspec(player_name, "ss:ui_main", formspec)

            else
                debug(flag8, "  this should not occur due to register_allow_player_inventory_action()")
            end

        elseif from_list == "clothing_slot_chest" then
            debug(flag8, "  unequipping clothing from chest slot.. " .. item_name)
            update_clothes(player, item, from_list, 0)

        elseif from_list == "clothing_slot_legs" then
            debug(flag8, "  unequipping clothing from legs slot.. " .. item_name)
            update_clothes(player, item, from_list, 0)

        elseif from_list == "clothing_slot_feet" then
            debug(flag8, "  unequipping clothing from feet slot.. " .. item_name)
            update_clothes(player, item, from_list, 0)

        elseif from_list == "clothing_slot_neck" then
            debug(flag8, "  unequipping clothing from neck slot.. " .. item_name)
            update_clothes(player, item, from_list, 0)

        elseif from_list == "clothing_slot_hands" then
            debug(flag8, "  unequipping clothing from hands slot.. " .. item_name)
            update_clothes(player, item, from_list, 0)

        elseif from_list == "clothing_slot_eyes" then
            debug(flag8, "  unequipping clothing from eyes slot.. " .. item_name)
            update_clothes(player, item, from_list, 0)

        elseif from_list == "armor_slot_head" then
            debug(flag8, "  unequipping armor from head slot.. " .. item_name)
            update_armor(player, item, from_list, 0)

        elseif from_list == "armor_slot_face" then
            debug(flag8, "  unequipping armor from face slot.. " .. item_name)
            update_armor(player, item, from_list, 0)

        elseif from_list == "armor_slot_chest" then
            debug(flag8, "  unequipping armor from chest slot.. " .. item_name)
            update_armor(player, item, from_list, 0)

        elseif from_list == "armor_slot_arms" then
            debug(flag8, "  unequipping armor from arms slot.. " .. item_name)
            update_armor(player, item, from_list, 0)

        elseif from_list == "armor_slot_legs" then
            debug(flag8, "  unequipping armor from legs slot.. " .. item_name)
            update_armor(player, item, from_list, 0)

        elseif from_list == "armor_slot_feet" then
            debug(flag8, "  unequipping armor from feet slot.. " .. item_name)
            update_armor(player, item, from_list, 0)

        else
            debug(flag8, "  Unimplemented action: " .. from_list .. " >> " .. to_list)
        end

    elseif action == "take" then
        local listname = inventory_info.listname
        local item = inventory_info.stack
        local item_name = item:get_name()
        local weight

        debug(flag8, "  REMOVED")

        if listname == "bag_slots" then
            -- update inv slot count and max inventory weight
            local dropped_items_weight = 0
            local slot_change_amount = ss.BAG_SLOT_BONUS[item_name]
            debug(flag8, "  slot_change_amount: " .. slot_change_amount)
            dropped_items_weight = set_inventory_size(player, p_data,
                -get_slot_count_to_remove(player_meta, p_data, slot_change_amount)
            )
            update_inventory_weight_max(player, fs)

            -- refresh bag slots to replace bg image with dark green highlight
            fs.center.bag_slots = get_fs_bag_slots(player:get_inventory(), player_name)

            debug(flag8, "  dropped weight: " .. dropped_items_weight)
            weight = get_itemstack_weight(item) + dropped_items_weight
            debug(flag8, "  total weight with dropped bag: " .. weight)

        elseif listname == "clothing_slot_chest" then
            debug(flag8, "  unequipping clothing from chest slot.. " .. item_name)
            update_clothes(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "clothing_slot_legs" then
            debug(flag8, "  unequipping clothing from legs slot.. " .. item_name)
            update_clothes(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "clothing_slot_feet" then
            debug(flag8, "  unequipping clothing from feet slot.. " .. item_name)
            update_clothes(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "clothing_slot_neck" then
            debug(flag8, "  unequipping clothing from neck slot.. " .. item_name)
            update_clothes(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "clothing_slot_hands" then
            debug(flag8, "  unequipping clothing from hands slot.. " .. item_name)
            update_clothes(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "clothing_slot_eyes" then
            debug(flag8, "  unequipping clothing from eyes slot.. " .. item_name)
            update_clothes(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "armor_slot_head" then
            debug(flag8, "  unequipping armor from head slot.. " .. item_name)
            update_armor(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "armor_slot_face" then
            debug(flag8, "  unequipping armor from face slot.. " .. item_name)
            update_armor(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "armor_slot_chest" then
            debug(flag8, "  unequipping armor from chest slot.. " .. item_name)
            update_armor(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "armor_slot_arms" then
            debug(flag8, "  unequipping armor from arms slot.. " .. item_name)
            update_armor(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "armor_slot_legs" then
            debug(flag8, "  unequipping armor from legs slot.. " .. item_name)
            update_armor(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "armor_slot_feet" then
            debug(flag8, "  unequipping armor from feet slot.. " .. item_name)
            update_armor(player, item, listname, 0)
            weight = get_itemstack_weight(item)

        elseif listname == "main" then
            debug(flag8, "  formspec_mode: " .. p_data.formspec_mode)
            weight = get_itemstack_weight(item)

            -- item removed while crafting/recipe pane was in view
            if p_data.formspec_mode == "main_formspec" then
                debug(flag8, "  Removed item while in main formspec")
                update_crafting_ingred_and_grid(player_name, inventory, p_data, fs)

            elseif p_data.formspec_mode == "storage" then
                debug(flag8, "  Removed item while in storage chest")

            else
                debug(flag8, "  Unexpected formspec_mode: " .. p_data.formspec_mode)
            end

        else print ("Unexpected listname: " .. listname) end

        play_sound("item_move", {item_name = item_name, player_name = player_name})

        -- update weight statbar hud and weight formspec to reflect removal of item
        do_stat_update_action(player, p_data, player_meta, "normal", "weight", -weight, "curr", "add", true)

        fs.center.weight = get_fs_weight(player)
        debug(flag8, "  ** UI Refreshed! ** by register_player_inventory_action()")
        player_meta:set_string("fs", mt_serialize(fs))
        local formspec = build_fs(fs)
        player:set_inventory_formspec(formspec)
        mt_show_formspec(player_name, "ss:ui_main", formspec)

    else
        debug(flag8, "  UNEXPECTED ACTION: " .. action)

    end

    debug(flag8, "register_on_player_inventory_action() end " .. core.get_gametime())
end)






local flag3 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag3, "\nregister_on_player_receive_fields() INVENTORY.lua")
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    local fs = player_data[player_name].fs
    debug(flag3, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag3, "  active_tab: " .. p_data.active_tab)

    if fields.inv_tabs == "1" then
        debug(flag3, "  clicked on 'MAIN' tab!")
        p_data.active_tab = "main"
        mt_show_formspec(player_name, "ss:ui_main", build_fs(fs))
        play_sound("button", {player_name = player_name})

        debug(flag3, "register_on_player_receive_fields() end " .. core.get_gametime())
        return

    else
        debug(flag3, "  did not click on 'MAIN' tab")

        if p_data.formspec_mode ~= "main_formspec" then
            debug(flag3, "  interaction not from main formspec. NO FURTHER ACTION.")
            debug(flag3, "register_on_player_receive_fields() END " .. core.get_gametime())
            return
        elseif p_data.active_tab ~= "main" then
            debug(flag3, "  interaction from main formspec, but not MAIN tab. NO FURTHER ACTION.")
            debug(flag3, "register_allow_player_inventory_action() END " .. core.get_gametime())
            return
        elseif fields.inv_tabs == "2"
            or fields.inv_tabs == "3"
            or fields.inv_tabs == "4"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6"
            or fields.inv_tabs == "7"
            or fields.inv_tabs == "8" then
            debug(flag3, "  clicked on a tab that was not MAIN. NO FURTHER ACTION.")
            debug(flag3, "register_allow_player_inventory_action() END " .. core.get_gametime())
            return
        elseif fields.quit then
            debug(flag3, "  exited formspec. NO FURTHER ACTION.")
            p_data.active_tab = "main"
            debug(flag3, "register_allow_player_inventory_action() END " .. core.get_gametime())
            return
        else
            debug(flag3, "  clicked on a MAIN formspec element")
        end

    end

    local refresh_inventory_ui = false
    local player_meta = player:get_meta()
    local player_inv = player:get_inventory()

    -- play the button click sound
    play_sound("button", {player_name = player_name})

    -- if there are multiple fiels in the 'fields' table, discard the fields
    -- relating to the crafting vertical scrollbar (if present) and only take
    -- the remaining field relating to any other 'ss:ui_main' elements.
    local field_name
    for key, value in pairs(fields) do
        if key == "enScrollbar_crafting" then
            field_name = key
        else
            field_name = key
            break
        end
    end
    --debug(flag3, "  field_name: " .. field_name)

    local field_tokens = string_split(field_name, "_")
    local field_type = field_tokens[1]
    local recipe_id = table_concat(field_tokens, "_", 2)

    if field_type == "equipbuff" then
        debug(flag3, "  clicked on an Equipbuff button. skip.")

    elseif field_type == "enCraftcategory" then
        debug(flag3, "  Clicked on a crafting Category!")
        debug(flag3, "  field_type: " .. field_name)
        debug(flag3, "   curr recipe_category: " ..  p_data.recipe_category)

        local recipe_category = field_tokens[2]
        debug(flag3, "   clicked recipe_category: " ..  recipe_category)

        if recipe_category == p_data.recipe_category then
            debug(flag3, "  clicked on same category. no action taken.")

        else
            debug(flag3, "  clicked on different category!")
            fs.right.craft_title = get_fs_craft_title("hand", recipe_category)
            fs.right.craft_categories = get_fs_craft_categories(recipe_category)
            fs.right.craft_grid = get_fs_crafting_grid(player_name, player_inv, recipe_category)
            debug(flag3, "  recipe_category: " .. recipe_category)
            p_data.recipe_category = recipe_category
            player_data[player_name].recipe_category = recipe_category
            player_meta:set_string("recipe_category", recipe_category)
            refresh_inventory_ui = true

        end

    elseif field_type == "enRecipeX" then
        debug(flag3, "  Clicked on a CRAFTABLE recipe")

        local recipe = RECIPES[recipe_id]
        local prev_recipe_id = p_data.prev_recipe_id
        debug(flag3, "  recipe_id: " .. recipe_id)
        debug(flag3, "  prev_recipe_id: " .. prev_recipe_id)

        local item_name = recipe.icon
        debug(flag3, "  item_name: " .. item_name)
        debug(flag3, "  prev_iteminfo_item: " .. p_data.prev_iteminfo_item)

        -- determine whether to refresh craft button, craft icon, and indredients box
        if recipe_id == prev_recipe_id then
            debug(flag3, "  Clicked on SAME recipe icon as before. Crafting UI elements not refreshed.")
        else
            debug(flag3, "  Clicked on DIFFERENT recipe icon as before. Refreshing crafting UI elements...")
            local crafting_count = ss.get_craftable_count(player_inv, recipe_id)
            fs.right.craft_button = ss.get_fs_craft_button(recipe_id, crafting_count)
            fs.right.craft_item_icon = get_fs_craft_item_icon(item_name)
            fs.right.ingredients_box = get_fs_ingred_box(player_name, ItemStack(item_name), player_inv, recipe_id)
            p_data.prev_recipe_id = recipe_id
            player_meta:set_string("prev_recipe_id", recipe_id)
            refresh_inventory_ui = true
        end

        -- determine whether to refresh item info
        if item_name == p_data.prev_iteminfo_item then
            debug(flag3, "  Item info slot item is SAME as before! no change to item info panel.")
        else
            debug(flag3, "  Item info slot item is DIFFERENT! Refreshing item info panel...")
            refresh_inventory_ui = show_item_info(player, ItemStack(recipe.icon), p_data, "recipe")
        end

    elseif field_type == "enRecipe" then
        debug(flag3, "  Clicked on a NON-craftable recipe: "  .. recipe_id)

        local recipe = RECIPES[recipe_id]
        local prev_recipe_id = p_data.prev_recipe_id
        debug(flag3, "  recipe_id: " .. recipe_id)
        debug(flag3, "  prev_recipe_id: " .. prev_recipe_id)

        local item_name = recipe.icon
        debug(flag3, "  item_name: " .. item_name)
        debug(flag3, "  prev_iteminfo_item: " .. p_data.prev_iteminfo_item)

        -- determine whether to refresh craft button, craft icon, and indredients box
        if recipe_id == prev_recipe_id then
            debug(flag3, "  Clicked on SAME recipe icon as before. Crafting UI elements not refreshed.")
        else
            debug(flag3, "  Clicked on DIFFERENT recipe icon as before. Refreshing crafting UI elements...")
            fs.right.craft_item_icon = get_fs_craft_item_icon(item_name)
            fs.right.craft_button = ss.get_fs_craft_button(recipe_id, 0)
            fs.right.ingredients_box = get_fs_ingred_box(player_name, ItemStack(item_name), player_inv, recipe_id)
            p_data.prev_recipe_id = recipe_id
            player_meta:set_string("prev_recipe_id", recipe_id)
            refresh_inventory_ui = true
        end

        -- determine whether to refresh item info
        if item_name == p_data.prev_iteminfo_item then
            debug(flag3, "  Item info slot item is SAME as before! no change to item info panel.")
        else
            debug(flag3, "  Item info slot item is DIFFERENT! Refreshing item info panel...")
            refresh_inventory_ui = show_item_info(player, ItemStack(item_name), p_data, "recipe")
        end

    -- clicked on Craft button from item info panel
    elseif field_type == "enCraftbutton" then
        debug(flag3, "  ** Clicked on CRAFT button! **")

        debug(flag3, "  recipe_id: " .. recipe_id)
        local recipe = RECIPES[recipe_id]

        local ingredients = RECIPE_INGREDIENTS[recipe_id]
        debug(flag3, "  crafting_ingredients: " .. dump(ingredients))
        debug(flag3, "  output: " .. dump(recipe.output))

        local ingred_weight_total = 0
        for _, ingredient in ipairs(ingredients) do
            -- calculate weight of ingredients
            local ingred_weight = get_itemstack_weight(ingredient)
            ingred_weight_total = ingred_weight_total + ingred_weight

            -- remove recipe ingredients from player inventory
            debug(flag3, "  Removing from inventory: " .. ingredient:get_name())
            player_inv:remove_item("main", ingredient)
        end

        -- calculate new weight of player inv after removing all ingredients
        local inventory_weight = player_meta:get_float("weight_current")
        debug(flag3, "  All ingredients removed...")
        debug(flag3, "  Prior inv weight: " .. inventory_weight)
        inventory_weight = inventory_weight - ingred_weight_total
        debug(flag3, "  New inv weight: " .. inventory_weight)

        -- add crafting output item(s) into player inventory
        local inv_too_heavy = false
        local inv_space_full = false
        debug(flag3, "  Preparing output items...")
        for _, output in ipairs(recipe.output) do
            local item = ItemStack(output)
            local item_name = item:get_name()

            -- initialize 'remaining_uses' property if this is a consumable item
            local remaining_uses = ITEM_MAX_USES[item_name]
            if remaining_uses then
                debug(flag3, "  this is a consumable item")
                local item_meta = item:get_meta()
                update_meta_and_description(item_meta, item_name, {"remaining_uses"}, {remaining_uses})
                debug(flag3, "  remaining_uses set to: " .. remaining_uses)

            elseif CLOTHING_NAMES[item_name] then
                debug(flag3, "  this is a clothing item")
                local item_meta = item:get_meta()
                local clothes_type = CLOTHING_NAMES[item_name]
                local clothing_color = CLOTHING_COLORS[clothes_type][1]
                local clothing_contrast = CLOTHING_CONTRASTS[clothes_type][1]
                local clothing_image = table_concat({
                    "ss_clothes_", clothes_type, ".png",
                    "^[colorizehsl:", clothing_color,
                    "^[contrast:", clothing_contrast,
                    "^[mask:ss_clothes_", clothes_type, "_mask.png"
                })
                item_meta:set_string("color", clothing_color)
                item_meta:set_string("contrast", clothing_contrast)
                item_meta:set_string("inventory_image", clothing_image)

            elseif ARMOR_NAMES[item_name] then
                debug(flag3, "  this is an armor item")
                local item_meta = item:get_meta()
                local armor_type = ARMOR_NAMES[item_name]
                local armor_color = ARMOR_COLORS[armor_type][1]
                local armor_contrast = ARMOR_CONTRASTS[armor_type][1]
                local armor_image = table_concat({
                    "ss_armor_", armor_type, ".png",
                    "^[colorizehsl:", armor_color,
                    "^[contrast:", armor_contrast,
                    "^[mask:ss_armor_", armor_type, "_mask.png"
                })
                item_meta:set_string("color", armor_color)
                item_meta:set_string("contrast", armor_contrast)
                item_meta:set_string("inventory_image", armor_image)
            end

            if player_inv:room_for_item("main", item) then
                -- handle items not yet updated with 'weight' data
                local item_weight = ss.ITEM_WEIGHTS[item_name]
                local itemstack_weight = get_itemstack_weight(item)
                local inv_weight_max = player_meta:get_float("weight_max")
                local new_inv_weight = inventory_weight + itemstack_weight

                debug(flag3, "  item_weight: " .. item_weight)
                debug(flag3, "  itemstack_weight: " .. itemstack_weight)
                debug(flag3, "  new_inv_weight: " .. new_inv_weight)

                if new_inv_weight > inv_weight_max then
                    debug(flag3, "  Inv too heavy.")
                    mt_add_item(player:get_pos(), item)
                    inv_too_heavy = true
                else
                    debug(flag3, "  Adding to inv: " .. item:get_name() .. " " .. item:get_count())
                    player_inv:add_item("main", item)
                    debug(flag3, "  Weight of itemstack successfully added: " .. itemstack_weight)
                    inventory_weight = inventory_weight + itemstack_weight
                end

            else
                debug(flag3, "  No space for item.")
                mt_add_item(player:get_pos(), item)
                inv_space_full = true
            end

            debug(flag3, "  Saving updated inv weight...")
            player_meta:set_float("weight_current", inventory_weight)

        end

        if inv_too_heavy then
            notify(player, "inventory", "crafted item dropped - too heavy", NOTIFY_DURATION, 0.5, 0, 3)
        elseif inv_space_full then
            notify(player, "inventory", "Crafted item dropped - no inventory space", NOTIFY_DURATION, 0.5, 0, 3)
        end

        debug(flag3, "  updating weight formspec to: " .. inventory_weight)
        fs.center.weight = get_fs_weight(player)

        debug(flag3, "  Updating crafting grid...")
        fs.right.ingredients_box = get_fs_ingred_box(player_name, ItemStack(recipe.icon), player_inv, recipe_id)
        fs.right.craft_grid = get_fs_crafting_grid(player_name, player_inv, p_data.recipe_category)

        debug(flag3, "  updating experience...")
        local ingredient_count = #ingredients
        debug(flag3, "  Ingredients count: " .. ingredient_count)

        local experience_gain_crafting = p_data.experience_gain_crafting * p_data.experience_rec_mod_fast_learner
        debug(flag3, "  experience_gain_crafting: " .. experience_gain_crafting)
        local experience_gained = ingredient_count * experience_gain_crafting
        debug(flag3, "  Experience gained: " .. experience_gained)
        do_stat_update_action(player, p_data, player_meta, "normal", "experience", experience_gained, "curr", "add", true)


        -- cycle through the recipe ingredients to see if player inv contains enough
        -- items to craft the same recipe item again.
        local craftable_again = true
        debug(flag3, "  *** Checking inventory if enough ingredients to craft again...")
        for i, ingredient in ipairs(ingredients) do
            debug(flag3, "  - checking ingredient: " .. ingredient:get_name() .. " " .. ingredient:get_count() )
            if player_inv:contains_item("main", ingredient) then
                debug(flag3, "  - ** FOUND! **")
            else
                debug(flag3, "  - Not found.")
                craftable_again = false
            end
        end

        if craftable_again then
            debug(flag3, "  recipe is craftable again")
            local crafting_count = ss.get_craftable_count(player_inv, recipe_id)
            fs.right.craft_button = ss.get_fs_craft_button(recipe_id, crafting_count)

        else
            debug(flag3, "  recipe is no longer craftable")
            debug(flag3, "  update crafting button to reflect if craftable with alternate group ingredients")
            local crafting_count = ss.get_craftable_count(player_inv, recipe_id)
            fs.right.craft_button = ss.get_fs_craft_button(recipe_id, crafting_count)
        end

        refresh_inventory_ui = true

    elseif field_type == "enRecipeIngredient" then
        debug(flag3, "  clicked on recipe ingredient.")

        local item_name = recipe_id
        debug(flag3, "  item_name: " .. item_name)
        debug(flag3, "  prev_iteminfo_item: " .. p_data.prev_iteminfo_item)

        if item_name == p_data.prev_iteminfo_item then
            debug(flag3, "  curr and prev items are SAME. no action.")
        else
            debug(flag3, "  curr and prev items are DIFFERNET. updating UI...")
            refresh_inventory_ui = show_item_info(player, ItemStack(item_name), p_data, "recipe")
        end


    else debug(flag3, "  Unimplemented field_type: " .. field_type) end


    if refresh_inventory_ui then
        debug(flag3, "  ** UI Refreshed! ** by register_on_player_receive_fields()")

        local formspec = build_fs(fs)
        player:set_inventory_formspec(build_fs(fs))
        player_meta:set_string("fs", mt_serialize(fs))
        mt_show_formspec(player_name, "ss:ui_main", formspec)
    else
        debug(flag3, "  UI not refreshed.")
    end

    debug(flag3, "register_on_player_receive_fields() end " .. core.get_gametime())
end)



local list_names_to_drop = {
    "main",
    "bag_slots",
    "armor_slot_head",
    "armor_slot_face",
    "armor_slot_chest",
    "armor_slot_arms",
    "armor_slot_legs",
    "armor_slot_feet",
    "clothing_slot_eyes",
    "clothing_slot_neck",
    "clothing_slot_chest",
    "clothing_slot_hands",
    "clothing_slot_legs",
    "clothing_slot_feet"
}

local flag5 = false
core.register_on_dieplayer(function(player)
    debug(flag5, "\nregister_on_dieplayer() INVENTORY")
    local player_inv = player:get_inventory()
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]

    debug(flag5, "  dropping all items from player inventory..")
    local pos = player:get_pos()
    for i = 1, #list_names_to_drop do
        local list_name = list_names_to_drop[i]
        --debug(flag5, "  list_name: " .. list_name)
        local slot_items = player_inv:get_list(list_name)
        if #slot_items > 0 then
            --debug(flag5, "  list contains items..")
            for j = 1, #slot_items do
                local slot_item = slot_items[j]
                if not slot_item:is_empty() then
                    --debug(flag5, "    slot_item: " .. slot_item:get_name())
                    mt_add_item({
                        x = pos.x + math_random(-2, 2)/10,
                        y = pos.y,
                        z = pos.z + math_random(-2, 2)/10},
                        slot_item
                    )
                end
            end
            --debug(flag5, "  all list items dropped")
            player_inv:set_list(list_name, {})
        else
            --debug(flag5, "  list empty. skipped.")
        end
    end
    p_data.formspec_mode = "main_formspec"
    p_data.active_tab = "main"

    debug(flag5, "register_on_dieplayer() END")
end)


local flag7 = false
core.register_on_respawnplayer(function(player)
    debug(flag7, "\nregister_on_respawnplayer() INVENTORY")
    local player_meta = player:get_meta()
    local player_inv = player:get_inventory()
    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]

    p_data.weight_max_per_slot = SLOT_WEIGHT_MAX
    player_meta:set_int("weight_max_per_slot", p_data.weight_max_per_slot)

    p_data.recipe_category = "tools"
    player_meta:set_string("recipe_category", p_data.recipe_category)

    p_data.prev_iteminfo_item = ""
    player_meta:set_string("prev_iteminfo_item", p_data.prev_iteminfo_item)

    p_data.prev_recipe_id = ""
    player_meta:set_string("prev_recipe_id", p_data.prev_recipe_id)

    p_data.slot_bonus_credit = 0
    player_meta:set_int("slot_bonus_credit", p_data.slot_bonus_credit)

    p_data.experience_gain_crafting = 0.5
	player_meta:set_float("experience_gain_crafting", p_data.experience_gain_crafting)

    debug(flag7, "  reset inventory slot count, size, and weight max..")
    player_inv:set_size("main", INV_SIZE_START)
    debug(flag7, "    INV_SIZE_START: " .. INV_SIZE_START)

    debug(flag7, "  reset selected item info and recipe item to be the stone axe")
    local recipe_id = "tool_axe_stone"
    local recipe = RECIPES[recipe_id]
    local item_name = recipe.icon
    local crafting_count = ss.get_craftable_count(player_inv, recipe_id)
    p_data.prev_recipe_id = recipe_id
    player_meta:set_string("prev_recipe_id", recipe_id)

    debug(flag7, "  reset player inventory left, center, and right panes..")
    local new_fs = {
        setup = ss.get_fs_setup(),
        left = {
            stats =             ss.get_fs_player_stats(player_name),
            left_tabs =         ss.get_fs_tabs_left(),
            player_avatar =     ss.get_fs_player_avatar(p_data.avatar_mesh, p_data.avatar_texture_base),
            equipment_slots =   ss.get_fs_equip_slots(p_data),
            equipment_stats =   ss.get_fs_equipment_buffs(player_name),
        },
        center = {
            item_info_slot =    ss.get_fs_item_info_slot(),
            item_info =         ss.get_fs_item_info(player, ItemStack(item_name)),
            inventory_grid =    ss.get_fs_inventory_grid(),
            bag_slots =         ss.get_fs_bag_slots(player_inv, player_name),
            weight =            ss.get_fs_weight(player)
        },
        right = {
            craft_categories =  ss.get_fs_craft_categories("tools"),
            craft_title =       ss.get_fs_craft_title("hands", "tools"),
            craft_item_icon =   ss.get_fs_craft_item_icon(item_name),
            craft_button =      ss.get_fs_craft_button(recipe_id, crafting_count),
            ingredients_box =   ss.get_fs_ingred_box(player_name, ItemStack(item_name), player_inv, recipe_id),
            craft_grid =        ss.get_fs_crafting_grid(player_name, player_inv, "tools")
        }
    }
    player_data[player_name].fs = new_fs
    player_meta:set_string("fs", mt_serialize(new_fs))
    player:set_inventory_formspec(build_fs(new_fs))

    debug(flag7, "register_on_respawnplayer() END")
end)