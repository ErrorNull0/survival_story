print("- loading clothing.lua")

-- cache global functions for faster access
local table_concat = table.concat
local table_insert = table.insert
local string_gsub = string.gsub
local string_split = string.split
local string_sub = string.sub
local mt_get_modpath = core.get_modpath
local mt_get_gametime = core.get_gametime
local mt_serialize = core.serialize
local mt_show_formspec = core.show_formspec
local debug = ss.debug
local round = ss.round
local lerp = ss.lerp
local play_sound = ss.play_sound
local get_fs_player_avatar = ss.get_fs_player_avatar
local get_fs_equipment_buffs = ss.get_fs_equipment_buffs
local get_fs_equip_slots = ss.get_fs_equip_slots
local build_fs = ss.build_fs

local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local HAND_INJURY_MODIFIERS = ss.HAND_INJURY_MODIFIERS
local LEG_INJURY_MODIFIERS = ss.LEG_INJURY_MODIFIERS
local player_data = ss.player_data


-- each 'CLOTHING_<body part>' table below contains all items that are allowed to
-- be equipped into that corresponding body part slot
ss.CLOTHING_EYES = {
    ["ss:clothes_sunglasses"] = true,
    ["ss:clothes_glasses"] = true
}
ss.CLOTHING_NECK = {
    ["ss:clothes_scarf"] = true,
    ["ss:clothes_necklace"] = true
}
ss.CLOTHING_CHEST = {
    ["ss:clothes_shirt_fiber"] = true,
    ["ss:clothes_tshirt"] = true,
}
ss.CLOTHING_HANDS = {
    ["ss:clothes_gloves_fiber"] = true,
    ["ss:clothes_gloves_leather"] = true,
    ["ss:clothes_gloves_fingerless"] = true
}
ss.CLOTHING_LEGS = {
    ["ss:clothes_pants_fiber"] = true,
    ["ss:clothes_pants"] = true,
    ["ss:clothes_shorts"] = true
}
ss.CLOTHING_FEET = {
    ["ss:clothes_socks"] = true
}

--[[ shortened versions of the clothing and armor names, which is often used as keys
to index tables containing clothing and armor colorization data. table format:
ss.CLOTHING_NAMES = {
    ["ss:clothes_tshirt"] = "tshirt",
    ["ss:clothes_pants"] = "pants"
}
ss.ARMOR_NAMES = {
    ["ss:armor_feet_fiber_1"] = "feet_fiber_1",
    ["ss:armor_legs_wood_1"] = "legs_wood_1"
} --]]
ss.CLOTHING_NAMES = {}
ss.ARMOR_NAMES = {}

--[[ protective buffs for clothing and armor. higher values provide better protection
against the listed physical and environmental effects. negative numbers make that effect
worse. shirts and pants tend to offer the most protection. 'sun' protection is typically
the highest value of 'cold' or 'heat', but may also be higher just due to total body
coverage. items that make 'heat' worse has negative values that is half of 'cold' value,
rounding up. table format:
ss.EQUIPMENT_BUFFS = {
    ["ss:clothes_tshirt"] = {damage = 3, cold = 5, heat = 0, sun = 5, water = 0.3, wetness = 2, disease = 1, electrical = 2, radiation = 0, gas = 0, noise = 1},
    ["ss:clothes_pants"] = {damage = 3, cold = 5, heat = -3, sun = 5, water = 0.4, wetness = 3, disease = 1, electrical = 3, radiation = 0, gas = 0, noise = 2},
    ["ss:armor_feet_fiber_1"] = {damage = 1, cold = 1, heat = 1, sun = 0, water = 0.1, wetness = 1, disease = 1, electrical = 1, radiation = 0, gas = 0, noise = 5},
    ["ss:armor_head_wood_1"] = {damage = 6, cold = 1, heat = 1, sun = 1, water = 0.0, wetness = 3, disease = 2, electrical = 3, radiation = 0, gas = 0, noise = 4},
} --]]
ss.EQUIPMENT_BUFFS = {}

local file_path = mt_get_modpath("ss") .. "/equipment_buffs.txt"
local file = io.open(file_path, "r")
if not file then
    print("### Could not open file: " .. file_path)
    return
end
local current_equipment_name = nil
for line in file:lines() do
    line = line:match("^%s*(.-)%s*$") -- trim whitespace

    if line ~= "" and not line:match("^#") then
        if not line:find(":") then
            -- Invalid line format, skip
        elseif not line:find(",") then
            -- Assume it's the item ID line
            current_equipment_name = line
        elseif current_equipment_name then
            -- Parse buff line
            local buff_table = {}
            for pair in line:gmatch("[^,]+") do
                local key, val = pair:match("%s*(%w+)%s*:%s*(-?[%d%.]+)%s*")
                if key and val then
                    buff_table[key] = tonumber(val)
                end
            end
            ss.EQUIPMENT_BUFFS[current_equipment_name] = buff_table
            local tokens = string_split(current_equipment_name, "_")
            local equipment_type = tokens[1]
            if equipment_type == "ss:clothes" then
                ss.CLOTHING_NAMES[current_equipment_name] = string_sub(current_equipment_name, 12)
            elseif equipment_type == "ss:armor" then
                ss.ARMOR_NAMES[current_equipment_name] = string_sub(current_equipment_name, 10)
            else
                print("### ERROR - Unexpected 'equipment_type' value: " .. equipment_type)
            end
            current_equipment_name = nil
        end
    end
end
file:close()
local EQUIPMENT_BUFFS = ss.EQUIPMENT_BUFFS

-- any leg clothing like pants that could cover over feet armor (eg. shoes, boots) go here.
-- this ensures the foot armor to use an alternate mask to hide the upper part of the feet armor.
local PANTS = {
    ["ss:clothes_pants"] = true
}


local flag5 = false
-- if any long leg clothing was removed, check to see if any foot armor is currently equipped.
-- if so, change the foot armor mask so it reveals the upper portion of the foot armor.
local function update_foot_armor(item_name, p_data, player_meta, texture_file_name)
    debug(flag5, "  update_foot_armor()")

    if PANTS[item_name] then
        debug(flag5, "  item was pants! checking foot armor..")

        -- clear the texture filename of the leg clothing. this is referenced by
        -- armor.lua when a leg armor is equipped.
        p_data.leg_clothing_texture = texture_file_name
        player_meta:set_string("leg_clothing_texture", texture_file_name)

        local foot_armor_texture = p_data.foot_armor_texture
        debug(flag5, "  feet_armor_name: " .. foot_armor_texture)
        if foot_armor_texture == "" then
            debug(flag5, "  no foot armor equipped.")

        else
            debug(flag5, "  foot armor equipped!")
            debug(flag5, "  curr avatar_texture_armor: " .. p_data.avatar_texture_armor)

            local new_armor_texture, new_feet_texture
            if texture_file_name == "" then
                debug(flag5, "  removing pants..")
                new_armor_texture = string_gsub(
                    p_data.avatar_texture_armor,
                    foot_armor_texture .. "_mask2",
                    foot_armor_texture .. "_mask"
                )
                new_feet_texture = string_gsub(p_data.avatar_armor_feet, "_mask2", "_mask")
            else
                debug(flag5, "  equipping pants..")
                new_armor_texture = string_gsub(
                    p_data.avatar_texture_armor,
                    foot_armor_texture .. "_mask",
                    foot_armor_texture .. "_mask2"
                )
                new_feet_texture = string_gsub(p_data.avatar_armor_feet, "_mask", "_mask2")
            end

            debug(flag5, "  final avatar_texture_armor: " .. new_armor_texture)
            debug(flag5, "  final avatar_armor_feet: " .. new_feet_texture)
            p_data.avatar_texture_armor = new_armor_texture
            p_data.avatar_armor_feet = new_feet_texture
            player_meta:set_string("avatar_texture_armor", new_armor_texture)
            player_meta:set_string("avatar_armor_feet", new_feet_texture)
        end
        debug(flag5, "  p_data.leg_clothing_texture: " .. p_data.leg_clothing_texture)

    else
        debug(flag5, "  item was not pants.")

        if p_data.leg_clothing_texture == "" then
            debug(flag5, "  no leg clothing is equipped. no action")
        else
            debug(flag5, "  leg clothing (not pants) is equipped. checking foot armor...")

            p_data.leg_clothing_texture = ""
            player_meta:set_string("leg_clothing_texture", "")

            local foot_armor_texture = p_data.foot_armor_texture
            debug(flag5, "  feet_armor_name: " .. foot_armor_texture)
            if foot_armor_texture == "" then
                debug(flag5, "  no foot armor equipped. do nothing.")

            else
                debug(flag5, "  foot armor equipped!")
                local new_armor_texture, new_feet_texture
                debug(flag5, "  restoring foot armor mask..")
                new_armor_texture = string_gsub(
                    p_data.avatar_texture_armor,
                    foot_armor_texture .. "_mask2",
                    foot_armor_texture .. "_mask"
                )
                new_feet_texture = string_gsub(p_data.avatar_armor_feet, "_mask2", "_mask")
                p_data.avatar_texture_armor = new_armor_texture
                p_data.avatar_armor_feet = new_feet_texture
                player_meta:set_string("avatar_texture_armor", new_armor_texture)
                player_meta:set_string("avatar_armor_feet", new_feet_texture)
            end

        end
    end

    debug(flag5, "  update_foot_armor() end")
end



local flag4 = false
--- @param body_part string body part for the clothing: eyes, feet, legs, hands, chest, neck
--- @param slot_name string the clothing slot being inspected
--- @param texture_name string the texture name of the clothing, including texture modifiers
--- @param p_data table reference to table with data specific to this player
--- @param player_meta MetaDataRef used to access various player meta data
--- @return string | nil new_texture_name the new texture name based on the clothing and
-- the clothing slot being inspected. returns 'nil' if the clothing item doesn't belong to
-- this slot and the slot is empty.
local function get_texture_string(body_part, slot_name, texture_name, p_data, player_meta)
    debug(flag4, "  get_texture_string()")
    debug(flag4, "    body_part: " .. body_part)
    debug(flag4, "    slot_name: " .. slot_name)
    debug(flag4, "    texture_name: " .. texture_name)

    local slot_to_check = "clothing_slot_" .. body_part
    local pdata_subtable = "avatar_clothing_" .. body_part
    debug(flag4, "    slot_to_check: " .. slot_to_check)
    debug(flag4, "    pdata_subtable: " .. pdata_subtable)

    local new_texture_name
    if slot_name == slot_to_check then
        p_data[pdata_subtable] = texture_name
        player_meta:set_string(pdata_subtable, texture_name)
        new_texture_name = texture_name
    else
        debug(flag4, "    clothing item not for this slot.")
        if p_data[pdata_subtable] ~= "" then
            debug(flag4, "    slot currently has an item. returning that texture name..")
            new_texture_name = p_data[pdata_subtable]
        end
    end
    debug(flag4, "  get_texture_string() end")

    return new_texture_name
end


local flag6 = false
local function update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, action)
    debug(flag6, "update_clothing_buffs()")
    debug(flag5, "    item_name: " .. item_name)
    debug(flag5, "    action: " .. action)

    -- in this state, there is assuemd no item equipped in the clothing slot. the values for
    -- 'p_data.equip_buff_xxxxx' = <whatever existing equip buff values from other equip slots>.
    -- thus the equip buff values of 'item_name' just need to be added to p_data.equip_buff_xxxxx.
    if action == "add" then
        debug(flag6, "  adding to existing equipment buffs..")
        p_data.equip_buff_damage = p_data.equip_buff_damage + EQUIPMENT_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold + EQUIPMENT_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat + EQUIPMENT_BUFFS[item_name].heat
        p_data.equip_buff_sun = p_data.equip_buff_sun + EQUIPMENT_BUFFS[item_name].sun
        p_data.equip_buff_water = round(p_data.equip_buff_water + EQUIPMENT_BUFFS[item_name].water, 1)
        p_data.equip_buff_wetness = p_data.equip_buff_wetness + EQUIPMENT_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease + EQUIPMENT_BUFFS[item_name].disease
        p_data.equip_buff_electrical = p_data.equip_buff_electrical + EQUIPMENT_BUFFS[item_name].electrical
        p_data.equip_buff_radiation = p_data.equip_buff_radiation + EQUIPMENT_BUFFS[item_name].radiation
        p_data.equip_buff_gas = p_data.equip_buff_gas + EQUIPMENT_BUFFS[item_name].gas
        p_data.equip_buff_noise = p_data.equip_buff_noise + EQUIPMENT_BUFFS[item_name].noise
        p_data.equip_buff_weight = round(p_data.equip_buff_weight + ITEM_WEIGHTS[item_name], 2)

        -- save item name in case this ADD action is actually just first part of a SWAP (refer below)
        p_data.swapped_in_equip_name = item_name
        debug(flag6, "  p_data.swapped_in_equip_name: " .. p_data.swapped_in_equip_name)


    -- in this state, there is assuemd to be the 'undesired' equipped item still in the clothing slot.
    -- where 'p_data.equip_buff_xxxxx' = <whatever existing equip buff value> + <undesired equipped item>.
    -- the equip buff values of the undesired 'item_name' need be removed from p_data.equip_buff_xxxxx.
    -- resulting in 'p_data.equip_buff_xxxxx' = <whatever existing equip buff value>.
    elseif action == "remove" then
        debug(flag6, "  removing from existing equipment buffs totals..")
        p_data.equip_buff_damage = p_data.equip_buff_damage - EQUIPMENT_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold - EQUIPMENT_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat - EQUIPMENT_BUFFS[item_name].heat
        p_data.equip_buff_sun = p_data.equip_buff_sun - EQUIPMENT_BUFFS[item_name].sun
        p_data.equip_buff_water = round(p_data.equip_buff_water - EQUIPMENT_BUFFS[item_name].water, 1)
        p_data.equip_buff_wetness = p_data.equip_buff_wetness - EQUIPMENT_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease - EQUIPMENT_BUFFS[item_name].disease
        p_data.equip_buff_electrical = p_data.equip_buff_electrical - EQUIPMENT_BUFFS[item_name].electrical
        p_data.equip_buff_radiation = p_data.equip_buff_radiation - EQUIPMENT_BUFFS[item_name].radiation
        p_data.equip_buff_gas = p_data.equip_buff_gas - EQUIPMENT_BUFFS[item_name].gas
        p_data.equip_buff_noise = p_data.equip_buff_noise - EQUIPMENT_BUFFS[item_name].noise
        p_data.equip_buff_weight = round(p_data.equip_buff_weight - ITEM_WEIGHTS[item_name], 2)


    -- during swaps, the desired equipment was already equipped during the prior 'add' step.
    -- so the below code block finished off the remaining execution, which is removing the
    -- undesired equip buff values from the equip buff value totals. here, the values for
    -- 'p_data.equip_buff_xxxxx' currently represent:
    -- <whatever existing equip buff value> + <undesired equipped item> + <desired equipped item>.
    -- note the undesired equip buff value still need be removed from the buff value totals.
    elseif action == "swap" then
        debug(flag6, "  swap requested.")

        -- the desired clothing item that was equipped during the 'add' action
        local swapped_in_item_name = p_data.swapped_in_equip_name
        debug(flag6, "  swapped_in_item_name: " .. swapped_in_item_name)

        debug(flag6, "  ensuring 'prev' buff value totals reflect the item that was initially swapped in..")
        -- p_data.equip_buff_damage_xxxx_prev = <whatever existing equip buff value> + <undesired equipped item>
        p_data.equip_buff_damage_prev = p_data.equip_buff_damage - EQUIPMENT_BUFFS[swapped_in_item_name].damage
        p_data.equip_buff_cold_prev = p_data.equip_buff_cold - EQUIPMENT_BUFFS[swapped_in_item_name].cold
        p_data.equip_buff_heat_prev = p_data.equip_buff_heat - EQUIPMENT_BUFFS[swapped_in_item_name].heat
        p_data.equip_buff_sun_prev = p_data.equip_buff_sun - EQUIPMENT_BUFFS[swapped_in_item_name].sun
        p_data.equip_buff_water_prev = round(p_data.equip_buff_water - EQUIPMENT_BUFFS[swapped_in_item_name].water, 1)
        p_data.equip_buff_wetness_prev = p_data.equip_buff_wetness - EQUIPMENT_BUFFS[swapped_in_item_name].wetness
        p_data.equip_buff_disease_prev = p_data.equip_buff_disease - EQUIPMENT_BUFFS[swapped_in_item_name].disease
        p_data.equip_buff_electrical_prev = p_data.equip_buff_electrical - EQUIPMENT_BUFFS[swapped_in_item_name].electrical
        p_data.equip_buff_radiation_prev = p_data.equip_buff_radiation - EQUIPMENT_BUFFS[swapped_in_item_name].radiation
        p_data.equip_buff_gas_prev = p_data.equip_buff_gas - EQUIPMENT_BUFFS[swapped_in_item_name].gas
        p_data.equip_buff_noise_prev = p_data.equip_buff_noise - EQUIPMENT_BUFFS[swapped_in_item_name].noise
        p_data.equip_buff_weight_prev = round(p_data.equip_buff_weight - ITEM_WEIGHTS[swapped_in_item_name], 2)

        -- remove the undesired item's equip buff values from the equip buff totals, which leaves
        -- the buff totals to rerpesent: <whatever existing equip buff value> + <desired equipped item>
        debug(flag6, "  removing from existing equipment buffs totals..")
        p_data.equip_buff_damage = p_data.equip_buff_damage - EQUIPMENT_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold - EQUIPMENT_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat - EQUIPMENT_BUFFS[item_name].heat
        p_data.equip_buff_sun = p_data.equip_buff_sun - EQUIPMENT_BUFFS[item_name].sun
        p_data.equip_buff_water = round(p_data.equip_buff_water - EQUIPMENT_BUFFS[item_name].water, 1)
        p_data.equip_buff_wetness = p_data.equip_buff_wetness - EQUIPMENT_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease - EQUIPMENT_BUFFS[item_name].disease
        p_data.equip_buff_electrical = p_data.equip_buff_electrical - EQUIPMENT_BUFFS[item_name].electrical
        p_data.equip_buff_radiation = p_data.equip_buff_radiation - EQUIPMENT_BUFFS[item_name].radiation
        p_data.equip_buff_gas = p_data.equip_buff_gas - EQUIPMENT_BUFFS[item_name].gas
        p_data.equip_buff_noise = p_data.equip_buff_noise - EQUIPMENT_BUFFS[item_name].noise
        p_data.equip_buff_weight = round(p_data.equip_buff_weight - ITEM_WEIGHTS[item_name], 2)

        -- at this point 'p_data.equip_buff_xxxx_prev' represents the buff value total
        -- with the undesired clothing equipped. And, 'p_data.equip_buff_xxxx' rerpesents
        -- the buff value total with only the desired clothing equipped.

    else
        debug(flag6, "  ERROR: Unexpected value for 'action': " .. action)

    end

     -- save the updated equipment buff values into the player metadata
    player_meta:set_float("equip_buff_damage", p_data.equip_buff_damage)
    player_meta:set_float("equip_buff_cold", p_data.equip_buff_cold)
    player_meta:set_float("equip_buff_heat", p_data.equip_buff_heat)
    player_meta:set_float("equip_buff_sun", p_data.equip_buff_sun)
    player_meta:set_float("equip_buff_water", p_data.equip_buff_water)
    player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
    player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
    player_meta:set_float("equip_buff_electrical", p_data.equip_buff_electrical)
    player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
    player_meta:set_float("equip_buff_gas", p_data.equip_buff_gas)
    player_meta:set_float("equip_buff_noise", p_data.equip_buff_noise)
    player_meta:set_float("equip_buff_weight", p_data.equip_buff_weight)

    -- update player equipment stats (buffs) on formspec
    fs.left.equipment_stats = get_fs_equipment_buffs(player_name)

    -- when exiting from the main player formspec, this triggers the colorization
    -- reset of the equipment buff icon values
    p_data.equipbuffs_changed = true

    debug(flag6, "update_clothing_buffs() end")
end


local function refresh_formspec(player, player_meta, player_name, fs)
    local formspec = build_fs(fs)
    player_meta:set_string("fs", mt_serialize(fs))
    player:set_inventory_formspec(formspec)
    mt_show_formspec(player_name, "ss:ui_main", formspec)
end


--[[
p_data.avatar_texture_base = textures for skin, face, eyes, hair, and underwear
p_data.avatar_texture_clothes = textures for clothing slots: eyes, neck, chest, hands, legs, feet
p_data.avatar_texture_armor = textures for armor slots: head, face, eyes, neck, hands, feet
--]]

local flag2 = false
--- @param player ObjectRef the player object
--- @param item ItemStack the clothing that is being equipped or unequipped
--- @param slot_name string a clothing slot: clothing_slot_chest, clothing_slot_legs, etc
--- @param action number whether the clothing is being equipped '1' or unequipped '0'
function ss.update_clothes(player, item, slot_name, action)
	debug(flag2, "update_clothes()")
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local item_name = item:get_name()
    local p_data = ss.player_data[player_name]
    debug(flag2, "  curr avatar_texture_base: " .. p_data.avatar_texture_base)
    debug(flag2, "  curr avatar_texture_clothes: " .. p_data.avatar_texture_clothes)
    debug(flag2, "  curr avatar_clothing_chest: " .. p_data.avatar_clothing_chest)
    debug(flag2, "  curr avatar_clothing_legs: " .. p_data.avatar_clothing_legs)
    debug(flag2, "  curr avatar_clothing_feet: " .. p_data.avatar_clothing_feet)
    debug(flag2, "  curr avatar_clothing_neck: " .. p_data.avatar_clothing_neck)
    debug(flag2, "  curr avatar_clothing_hands: " .. p_data.avatar_clothing_hands)
    debug(flag2, "  curr avatar_clothing_eyes: " .. p_data.avatar_clothing_eyes)
    debug(flag2, "  slot_name: " .. slot_name)

    -- chest clothing includes a body_type identifier because the chest/torso meshes are
    -- different between player model type 1 and 2, thus the textures are differentiated
    local body_type_string = ""
    if slot_name == "clothing_slot_chest" then
        body_type_string = "_" .. p_data.body_type
    end

    local item_meta = item:get_meta()
    local texture_color = item_meta:get_string("color")
    local texture_contrast = item_meta:get_string("contrast")
    debug(flag2, "  texture_color: " .. texture_color)
    debug(flag2, "  texture_contrast: " .. texture_contrast)

    local clothing_type_string = string_gsub(item_name, "ss:clothes_", "", 1)
    debug(flag2, "  clothing_type_string: " .. clothing_type_string)

    local texture_file_name = "ss_player_clothes_" .. clothing_type_string
    debug(flag2, "  texture_file_name: " .. texture_file_name)

    local fs = p_data.fs
    local new_avatar_texture

    if action == 1 then
        debug(flag2, "  applying clothing texture..")
        debug(flag2, "  retrieved color: " .. texture_color)

        -- update the equipment buff values that are displayed on the bottom left
        -- area of the main inventory formspec
        update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "add")

        local subtable_name = "equipped_clothing_" .. string_sub(slot_name, 15)
        debug(flag2, "  subtable_name: " .. subtable_name)

        local equipped_clothing_data = item_name .. " " .. item_meta:get_string("inventory_image")
        p_data[subtable_name] = equipped_clothing_data
        debug(flag2, "  p_data." .. subtable_name .. ": " .. equipped_clothing_data)

        -- save to player metadata
        player_meta:set_string(subtable_name, equipped_clothing_data)

        -- generate clothing texture string with the color from item meta data
        local item_texture_string = table_concat({
            texture_file_name, body_type_string, ".png",
            "^[colorizehsl:", texture_color,
            "^[contrast:", texture_contrast,
            "^[mask:ss_player_clothes_", clothing_type_string, body_type_string, "_mask.png"
        })
        debug(flag2, "  item_texture_string: " .. item_texture_string)
        item_meta:set_string("inventory_image", item_texture_string)

        -- add parenthesis to the texture string so it can be better combined with other
        -- clothing texture strings for the final 'texture' property applied onto player model
        local texture_name = table_concat({ "(", item_texture_string, ")" })
        debug(flag2, "  texture_name: " .. texture_name)

        -- retrieve the texture string from any equipped item from each clothing slot and
        -- store into a table to compile the final 'texture' property applied onto player
        -- model. if the clothing slot is empty, no texture string is retrieved.
        local all_clothing_textures = {}
        for _,body_part in ipairs({"eyes", "feet", "legs", "hands", "chest", "neck"}) do
            table_insert(all_clothing_textures, get_texture_string(body_part, slot_name, texture_name, p_data, player_meta))
            debug(flag2, "  p_data.avatar_clothing_" .. body_part .. ": " .. p_data["avatar_clothing_" .. body_part])
        end
        debug(flag2, "  clothing_textures: " .. dump(all_clothing_textures))

        -- combine all the clothing textures into the final texture string in the format
        -- required for player:set_properties() function
        local combined_clothing_textures = table_concat(all_clothing_textures, "^")
        p_data.avatar_texture_clothes = combined_clothing_textures
        player_meta:set_string("avatar_texture_clothes", combined_clothing_textures)
        debug(flag2, "  p_data.avatar_texture_clothes: " .. combined_clothing_textures)

        if slot_name == "clothing_slot_legs" then
            debug(flag2, "  equiping clothing item into legs slot..")
            update_foot_armor(item_name, p_data, player_meta, texture_file_name)

        elseif slot_name == "clothing_slot_feet" then
            debug(flag2, "  equiping to feet slot: " .. item_name)
            local modifier_value = LEG_INJURY_MODIFIERS[item_name]
            debug(flag2, "  leg_injury_mod_foot_clothing: " .. modifier_value)
            p_data.leg_injury_mod_foot_clothing = modifier_value
            player_meta:set_float("leg_injury_mod_foot_clothing", modifier_value)

        elseif slot_name == "clothing_slot_hands" then
            debug(flag2, "  equiping to hands slot: " .. item_name)
            local modifier_value = HAND_INJURY_MODIFIERS[item_name]
            debug(flag2, "  hand_injury_mod_glove: " .. modifier_value)
            p_data.hand_injury_mod_glove = modifier_value
            player_meta:set_float("hand_injury_mod_glove", modifier_value)

        else
            debug(flag2, "  equiping clothing into slot other than hands, legs, or feet")
        end

        -- generate the final texture string to be applied to the player model, which is
        -- the base skin texture + combined clothing textures + combined armor textures
        debug(flag2, "  p_data.vatar_texture_base: " .. p_data.avatar_texture_base)
        debug(flag2, "  p_data.avatar_texture_armor: " .. p_data.avatar_texture_armor)
        new_avatar_texture = table_concat({
            p_data.avatar_texture_base, "^",
            combined_clothing_textures, "^",
            p_data.avatar_texture_armor
        })

        p_data.equipment_count = p_data.equipment_count + 1
        p_data.wetness_drain_mod_equip = lerp(1, 0.3, p_data.equipment_count/12)

    else
        debug(flag2, "  removing clothing for " .. slot_name)

        -- generate clothing texture string with the color from item meta data
        local texture_name
        debug(flag2, "  texture_color: " .. texture_color)
        texture_name = table_concat({
            "(", texture_file_name, body_type_string, ".png",
            "^[colorizehsl:", texture_color,
            "^[contrast:", texture_contrast,
            "^[mask:ss_player_clothes_", clothing_type_string, body_type_string, "_mask.png)"
        })
        debug(flag2, "  target texture_name: " .. texture_name)

        if slot_name == "clothing_slot_chest" then
            debug(flag2, "  curr avatar_clothing_chest: " .. p_data.avatar_clothing_chest)
            if texture_name ~= p_data.avatar_clothing_chest then
                debug(flag2, "  Clothing swap was done - new clothing is already equipped. No clothing removed.")
                update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_clothes() end")
                return
            end
            p_data.avatar_clothing_chest = ""
            player_meta:set_string("avatar_clothing_chest", "")
            debug(flag2, "  new avatar_clothing_chest: " .. p_data.avatar_clothing_chest)
            p_data.equipped_clothing_chest = ""
            player_meta:set_string("equipped_clothing_chest", "")

        elseif slot_name == "clothing_slot_legs" then
            debug(flag2, "  curr avatar_clothing_legs: " .. p_data.avatar_clothing_legs)
            if texture_name ~= p_data.avatar_clothing_legs then
                debug(flag2, "  Clothing swap was done - new clothing is already equipped. No clothing removed.")
                update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_clothes() end")
                return
            end
            p_data.avatar_clothing_legs = ""
            player_meta:set_string("avatar_clothing_legs", "")
            debug(flag2, "  new avatar_clothing_legs: " .. p_data.avatar_clothing_legs)
            p_data.equipped_clothing_legs = ""
            player_meta:set_string("equipped_clothing_legs", "")
            p_data.leg_clothing_texture = ""
            player_meta:set_string("leg_clothing_texture", "")

        elseif slot_name == "clothing_slot_feet" then
            debug(flag2, "  curr avatar_clothing_feet: " .. p_data.avatar_clothing_feet)
            if texture_name ~= p_data.avatar_clothing_feet then
                debug(flag2, "  Clothing swap was done - new clothing is already equipped. No clothing removed.")
                update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_clothes() end")
                return
            end
            p_data.avatar_clothing_feet = ""
            player_meta:set_string("avatar_clothing_feet", "")
            debug(flag2, "  new avatar_clothing_feet: " .. p_data.avatar_clothing_feet)
            p_data.equipped_clothing_feet = ""
            player_meta:set_string("equipped_clothing_feet", "")
            p_data.leg_injury_mod_foot_clothing = 1
            player_meta:set_float("leg_injury_mod_foot_clothing", 1)

        elseif slot_name == "clothing_slot_neck" then
            debug(flag2, "  curr avatar_clothing_neck: " .. p_data.avatar_clothing_neck)
            if texture_name ~= p_data.avatar_clothing_neck then
                debug(flag2, "  Clothing swap was done - new clothing is already equipped. No clothing removed.")
                update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_clothes() end")
                return
            end
            p_data.avatar_clothing_neck = ""
            player_meta:set_string("avatar_clothing_neck", "")
            debug(flag2, "  new avatar_clothing_neck: " .. p_data.avatar_clothing_neck)
            p_data.equipped_clothing_neck = ""
            player_meta:set_string("equipped_clothing_neck", "")

        elseif slot_name == "clothing_slot_hands" then
            debug(flag2, "  curr avatar_clothing_hands: " .. p_data.avatar_clothing_hands)
            if texture_name ~= p_data.avatar_clothing_hands then
                debug(flag2, "  Clothing swap was done - new clothing is already equipped. No clothing removed.")
                update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "  item_name: " .. item_name)
                debug(flag2, "update_clothes() end")
                return
            end
            p_data.avatar_clothing_hands = ""
            player_meta:set_string("avatar_clothing_hands", "")
            debug(flag2, "  new avatar_clothing_hands: " .. p_data.avatar_clothing_hands)
            p_data.equipped_clothing_hands = ""
            player_meta:set_string("equipped_clothing_hands", "")
            p_data.hand_injury_mod_glove = 1
            player_meta:set_float("hand_injury_mod_glove", 1)

        elseif slot_name == "clothing_slot_eyes" then
            debug(flag2, "  curr avatar_clothing_eyes: " .. p_data.avatar_clothing_eyes)
            if texture_name ~= p_data.avatar_clothing_eyes then
                debug(flag2, "  Clothing swap was done - new clothing is already equipped. No clothing removed.")
                update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_clothes() end")
                return
            end
            p_data.avatar_clothing_eyes = ""
            player_meta:set_string("avatar_clothing_eyes", "")
            debug(flag2, "  new avatar_clothing_eyes: " .. p_data.avatar_clothing_eyes)
            p_data.equipped_clothing_eyes = ""
            player_meta:set_string("equipped_clothing_eyes", "")

        else
            debug(flag2, "  ERROR - Unknown slot_name: " .. slot_name)
            debug(flag2, "  No clothing was removed.")
        end

        update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "remove")

        debug(flag2, "  p_data.avatar_clothing_chest: " .. p_data.avatar_clothing_chest)
        debug(flag2, "  p_data.avatar_clothing_legs: " .. p_data.avatar_clothing_legs)
        debug(flag2, "  p_data.avatar_clothing_feet: " .. p_data.avatar_clothing_feet)
        debug(flag2, "  p_data.avatar_clothing_neck: " .. p_data.avatar_clothing_neck)
        debug(flag2, "  p_data.avatar_clothing_hands: " .. p_data.avatar_clothing_hands)
        debug(flag2, "  p_data.avatar_clothing_eyes: " .. p_data.avatar_clothing_eyes)

        -- compile table with the clothing texture string for each body part and sorted in
        -- correct layering order
        local clothing_table = {}
        if p_data.avatar_clothing_feet ~= "" then
            table_insert(clothing_table, p_data.avatar_clothing_feet)
        end
        if p_data.avatar_clothing_legs ~= "" then
            table_insert(clothing_table, p_data.avatar_clothing_legs)
        end
        if p_data.avatar_clothing_hands ~= "" then
            table_insert(clothing_table, p_data.avatar_clothing_hands)
        end
        if p_data.avatar_clothing_chest ~= "" then
            table_insert(clothing_table, p_data.avatar_clothing_chest)
        end
        if p_data.avatar_clothing_neck ~= "" then
            table_insert(clothing_table, p_data.avatar_clothing_neck)
        end
        if p_data.avatar_clothing_eyes ~= "" then
            table_insert(clothing_table, p_data.avatar_clothing_eyes)
        end
        debug(flag2, "  clothing_table: " .. dump(clothing_table))

        if #clothing_table > 0 then
            debug(flag2, "  other equipped clothing remain..")
            local combined_clothing_textures = table_concat(clothing_table, "^")
            debug(flag2, "  avatar_texture_clothes: " .. combined_clothing_textures)
            p_data.avatar_texture_clothes = combined_clothing_textures
            player_meta:set_string("avatar_texture_clothes", combined_clothing_textures)
            debug(flag2, "  avatar_texture_base: " .. p_data.avatar_texture_base)

            if p_data.avatar_texture_armor == "" then
                debug(flag2, "  no armor is equipped..")
                new_avatar_texture = table_concat({
                    p_data.avatar_texture_base, "^",
                    combined_clothing_textures
                })
            else
                debug(flag2, "  armor is also equipped..")
                if slot_name == "clothing_slot_legs" then
                    debug(flag2, "  removed clothing from legs slot. checking foot armor..")
                    update_foot_armor(item_name, p_data, player_meta, "")
                else
                    debug(flag2, "  removed clothing from non-legs slot.")
                end
                new_avatar_texture = table_concat({
                    p_data.avatar_texture_base, "^",
                    combined_clothing_textures, "^",
                    p_data.avatar_texture_armor
                })
            end

        -- if no clothes remain in any of the clothing slots, simply set avatar
        -- texture same as base avatar texture.
        else
            debug(flag2, "  no more clothing equipped..")
            p_data.avatar_texture_clothes = ""
            player_meta:set_string("avatar_texture_clothes", "")

            if p_data.avatar_texture_armor == "" then
                debug(flag2, "  no armor equipped either..")
                new_avatar_texture = p_data.avatar_texture_base
            else
                debug(flag2, "  existing armor is equipped")
                update_foot_armor(item_name, p_data, player_meta, "")
                new_avatar_texture = p_data.avatar_texture_base .. "^" .. p_data.avatar_texture_armor
            end
        end

        p_data.equipment_count = p_data.equipment_count - 1
        p_data.wetness_drain_mod_equip = lerp(1, 0.3, p_data.equipment_count/12)
    end

    debug(flag2, "  new_avatar_texture: " .. new_avatar_texture)

    -- apply the combined skin, clothing, and armor textures onto the player model
    player:set_properties({ textures = {new_avatar_texture} })

    -- update player equipment slots on formspec (hide or show the slot bg image)
    fs.left.equipment_slots = get_fs_equip_slots(p_data)

    -- update clothing + armor on player model avatar on formspec
    fs.left.player_avatar = get_fs_player_avatar(p_data.avatar_mesh, new_avatar_texture)

    refresh_formspec(player, player_meta, player_name, fs)

    -- play sound effect for equip/unequip of clothing item
    play_sound("item_move", {item_name = item_name, player_name = player_name})
    debug(flag2, "### PLAYED SOUND ###")

	debug(flag2, "update_clothes() end")
end



local clothing_data = {
    ["ss:clothes_shirt_fiber"] = "shirt_fiber",
    ["ss:clothes_pants_fiber"] = "pants_fiber",
    ["ss:clothes_necklace"] = "necklace",
    ["ss:clothes_tshirt"] = "tshirt",
    ["ss:clothes_gloves_fiber"] = "gloves_fiber",
    ["ss:clothes_gloves_leather"] = "gloves_leather",
    ["ss:clothes_gloves_fingerless"] = "gloves_fingerless",
    ["ss:clothes_pants"] = "pants",
    ["ss:clothes_shorts"] = "shorts",
    ["ss:clothes_socks"] = "socks",
    ["ss:clothes_scarf"] = "scarf",
    ["ss:clothes_glasses"] = "glasses",
    ["ss:clothes_sunglasses"] = "sunglasses"
}

local next_color_index = 1

-- allow random color change of clothing item upon right click
for item_name, clothing_type in pairs(clothing_data) do
    core.override_item(item_name, {
        on_secondary_use = function(itemstack, placer, pointed_thing)
            print("### curr color index: " .. next_color_index)
            print("### clothing_type: " .. clothing_type)

            local item_meta = itemstack:get_meta()
            local inventory_image = item_meta:get_string("inventory_image")
            print("### current inventory_image: " .. inventory_image)

            local color_count = #CLOTHING_COLORS[clothing_type]
            print("### color_count: " .. color_count)

            if next_color_index < color_count then
                next_color_index =  next_color_index + 1
            else
                next_color_index = 1
            end
            print("### next_color_index: " .. next_color_index)

            local next_color = CLOTHING_COLORS[clothing_type][next_color_index]
            local next_contrast = CLOTHING_CONTRASTS[clothing_type][next_color_index]
            local icon_texture_name = table_concat({
                "ss_clothes_", clothing_type, ".png",
                "^[colorizehsl:", next_color,
                "^[contrast:", next_contrast,
                "^[mask:ss_clothes_", clothing_type, "_mask.png"
            })
            item_meta:set_string("inventory_image", icon_texture_name)
            item_meta:set_string("color", next_color)
            item_meta:set_string("contrast", next_contrast)
            print("### new inventory_image: " .. icon_texture_name)
            return itemstack
        end
    })
end


local flag15 = false
core.register_on_joinplayer(function(player)
    debug(flag15, "\nregister_on_joinplayer() CLOTHING")
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local p_data = player_data[player_name]

    -- the base texture that is the combination of all textures for skin, face,
    -- eyes, hair, and underwear that is inialized in playe_setup.lua
    p_data.avatar_texture_base = player_meta:get_string("avatar_texture_base")

    -- *** refer to armor.lua register_on_joinplayer() which defines the code for
    -- loading currently equipped clothing ***

    -- texture filenames for each clothing
    p_data.avatar_clothing_eyes = player_meta:get_string("avatar_clothing_eyes")
    p_data.avatar_clothing_neck = player_meta:get_string("avatar_clothing_neck")
    p_data.avatar_clothing_chest = player_meta:get_string("avatar_clothing_chest")
    p_data.avatar_clothing_hands = player_meta:get_string("avatar_clothing_hands")
    p_data.avatar_clothing_legs = player_meta:get_string("avatar_clothing_legs")
    p_data.avatar_clothing_feet = player_meta:get_string("avatar_clothing_feet")

    -- contains the above clothing textures combined
    p_data.avatar_texture_clothes = player_meta:get_string("avatar_texture_clothes")

    -- 'pants' is any long leg coverings like pants that might overlap with feet
    -- coverings like sneakers and boots. this flag allows hiding of upper part
    -- of the shoe covering underneath the pants clothing. this way it doesn't
    -- look like pants are being tucked into the shoes.
    p_data.leg_clothing_texture = player_meta:get_string("leg_clothing_texture")

    -- hold data relating to the clothing that is currently equipped in that slot.
    -- empty string denotes no clothing equipped on that slot. Example: 
    -- "ss:clothes_tshirt ss_clothes_tshirt.png damage=2,cold=3,heat=1,wetness=1,disease=0,noise=7,weight=3.4"
    p_data.equipped_clothing_eyes = player_meta:get_string("equipped_clothing_eyes")
    p_data.equipped_clothing_neck = player_meta:get_string("equipped_clothing_neck")
    p_data.equipped_clothing_chest = player_meta:get_string("equipped_clothing_chest")
    p_data.equipped_clothing_hands = player_meta:get_string("equipped_clothing_hands")
    p_data.equipped_clothing_legs = player_meta:get_string("equipped_clothing_legs")
    p_data.equipped_clothing_feet = player_meta:get_string("equipped_clothing_feet")

    -- *** refer to armor.lua register_on_joinplayer() which defines the code for
    -- loading currently equipped armor ***

    -- armor texture data for player model
    p_data.avatar_armor_head = player_meta:get_string("avatar_armor_head")
    p_data.avatar_armor_face = player_meta:get_string("avatar_armor_face")
    p_data.avatar_armor_chest = player_meta:get_string("avatar_armor_chest")
    p_data.avatar_armor_arms = player_meta:get_string("avatar_armor_arms")
    p_data.avatar_armor_legs = player_meta:get_string("avatar_armor_legs")
    p_data.avatar_armor_feet = player_meta:get_string("avatar_armor_feet")
    p_data.avatar_texture_armor = player_meta:get_string("avatar_texture_armor")
    p_data.foot_armor_texture = player_meta:get_string("foot_armor_texture")

    -- contains the above clothing textures combined
    p_data.avatar_texture_armor = player_meta:get_string("avatar_texture_armor")

    -- 'shoes' is any foot covering that might overlap with long leg-coverings
    -- like pants, like sneakers, boots, etc. this flag allows hiding of upper
    -- part of the shoe covering underneath the pants clothing. this way it doesn't
    -- look like pants are being tucked into the shoes.
    p_data.foot_armor_texture = player_meta:get_string("foot_armor_texture")

    -- hold data relating to the armor that is currently equipped in that slot.
    -- empty string denotes no armor equipped on that slot. Example: 
    -- "ss:clothes_tshirt ss_clothes_tshirt.png damage=2,cold=3,heat=1,wetness=1,disease=0,noise=7,weight=3.4"
    p_data.equipped_armor_head = player_meta:get_string("equipped_armor_head")
    p_data.equipped_armor_face = player_meta:get_string("equipped_armor_face")
    p_data.equipped_armor_chest = player_meta:get_string("equipped_armor_chest")
    p_data.equipped_armor_arms = player_meta:get_string("equipped_armor_arms")
    p_data.equipped_armor_legs = player_meta:get_string("equipped_armor_legs")
    p_data.equipped_armor_feet = player_meta:get_string("equipped_armor_feet")








    -- count how many of the clothing and armor slots total have items equipped.
    -- used for calculation of 'p_data.wetness_drain_mod_equip' in weather.lua.
    p_data.equipment_count = 0
    local player_inv = player:get_inventory()
    for i, slot_name in ipairs({
        "clothing_slot_eyes", "clothing_slot_neck", "clothing_slot_chest",
        "clothing_slot_hands", "clothing_slot_legs", "clothing_slot_feet",
        "armor_slot_head", "armor_slot_face", "armor_slot_chest",
        "armor_slot_arms", "armor_slot_legs", "armor_slot_feet"}) do
        if not player_inv:is_empty(slot_name) then
            p_data.equipment_count = p_data.equipment_count + 1
        end
    end

    -- modifier against the wetness drain rate due to equipped clothing and armor
    p_data.wetness_drain_mod_equip = lerp(1, 0.5, p_data.equipment_count/12)

    debug(flag15, "register_on_joinplayer() end " .. mt_get_gametime())
end)



local flag3 = false
core.register_on_dieplayer(function(player)
    debug(flag3, "\nregister_on_dieplayer() GLOBAL VARS INIT")
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    local player_meta = player:get_meta()

    debug(flag3, "  resetting player model to default base textures..")
    player:set_properties({ textures = {p_data.avatar_texture_base} })
    debug(flag3, "  p_data.avatar_texture_base: " .. p_data.avatar_texture_base)

    debug(flag3, "  resetting all player clothing and armor pieces to empty")
    p_data.avatar_clothing_eyes = ""
    player_meta:set_string("avatar_clothing_eyes", p_data.avatar_clothing_eyes)
    p_data.avatar_clothing_neck = ""
    player_meta:set_string("avatar_clothing_neck", p_data.avatar_clothing_neck)
    p_data.avatar_clothing_chest = ""
    player_meta:set_string("avatar_clothing_chest", p_data.avatar_clothing_chest)
    p_data.avatar_clothing_hands = ""
    player_meta:set_string("avatar_clothing_hands", p_data.avatar_clothing_hands)
    p_data.avatar_clothing_legs = ""
    player_meta:set_string("avatar_clothing_legs", p_data.avatar_clothing_legs)
    p_data.avatar_clothing_feet = ""
    player_meta:set_string("avatar_clothing_feet", p_data.avatar_clothing_feet)

    p_data.avatar_texture_clothes = ""
    player_meta:set_string("avatar_texture_clothes", p_data.avatar_texture_clothes)
    p_data.leg_clothing_texture = ""
    player_meta:set_string("leg_clothing_texture", p_data.leg_clothing_texture)

    p_data.equipped_clothing_eyes = ""
    player_meta:set_string("equipped_clothing_eyes", p_data.equipped_clothing_eyes)
    p_data.equipped_clothing_neck = ""
    player_meta:set_string("equipped_clothing_neck", p_data.equipped_clothing_neck)
    p_data.equipped_clothing_chest = ""
    player_meta:set_string("equipped_clothing_chest", p_data.equipped_clothing_chest)
    p_data.equipped_clothing_hands = ""
    player_meta:set_string("equipped_clothing_hands", p_data.equipped_clothing_hands)
    p_data.equipped_clothing_legs = ""
    player_meta:set_string("equipped_clothing_legs", p_data.equipped_clothing_legs)
    p_data.equipped_clothing_feet = ""
    player_meta:set_string("equipped_clothing_feet", p_data.equipped_clothing_feet)

    p_data.avatar_armor_head = ""
    player_meta:set_string("avatar_armor_head", p_data.avatar_armor_head)
    p_data.avatar_armor_face = ""
    player_meta:set_string("avatar_armor_face", p_data.avatar_armor_face)
    p_data.avatar_armor_chest = ""
    player_meta:set_string("avatar_armor_chest", p_data.avatar_armor_chest)
    p_data.avatar_armor_arms = ""
    player_meta:set_string("avatar_armor_arms", p_data.avatar_armor_arms)
    p_data.avatar_armor_legs = ""
    player_meta:set_string("avatar_armor_legs", p_data.avatar_armor_legs)
    p_data.avatar_armor_feet = ""
    player_meta:set_string("avatar_armor_feet", p_data.avatar_armor_feet)

    p_data.avatar_texture_armor = ""
    player_meta:set_string("avatar_texture_armor", p_data.avatar_texture_armor)
    p_data.foot_armor_texture = ""
    player_meta:set_string("foot_armor_texture", p_data.foot_armor_texture)

    p_data.equipped_armor_head = ""
    player_meta:set_string("equipped_armor_head", p_data.equipped_armor_head)
    p_data.equipped_armor_face = ""
    player_meta:set_string("equipped_armor_face", p_data.equipped_armor_face)
    p_data.equipped_armor_chest = ""
    player_meta:set_string("equipped_armor_chest", p_data.equipped_armor_chest)
    p_data.equipped_armor_arms = ""
    player_meta:set_string("equipped_armor_arms", p_data.equipped_armor_arms)
    p_data.equipped_armor_legs = ""
    player_meta:set_string("equipped_armor_legs", p_data.equipped_armor_legs)
    p_data.equipped_armor_feet = ""
    player_meta:set_string("equipped_armor_feet", p_data.equipped_armor_feet)

    	-- reset the values shown in the equip buffs box
	p_data.equip_buff_damage = 0
    player_meta:set_float("equip_buff_damage", p_data.equip_buff_damage)
    p_data.equip_buff_cold = 0
    player_meta:set_float("equip_buff_cold", p_data.equip_buff_cold)
    p_data.equip_buff_heat = 0
    player_meta:set_float("equip_buff_heat", p_data.equip_buff_heat)
    p_data.equip_buff_sun = 0
    player_meta:set_float("equip_buff_sun", p_data.equip_buff_sun)
    p_data.equip_buff_water = 0
    player_meta:set_float("equip_buff_water", p_data.equip_buff_water)
    p_data.equip_buff_wetness = 0
    player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
    p_data.equip_buff_disease = 0
    player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
    p_data.equip_buff_electrical = 0
    player_meta:set_float("equip_buff_electrical", p_data.equip_buff_electrical)
    p_data.equip_buff_radiation = 0
    player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
    p_data.equip_buff_gas = 0
    player_meta:set_float("equip_buff_gas", p_data.equip_buff_gas)
    p_data.equip_buff_noise = 0
    player_meta:set_float("equip_buff_noise", p_data.equip_buff_noise)
    p_data.equip_buff_weight = 0
    player_meta:set_float("equip_buff_weight", p_data.equip_buff_weight)

	-- these helper values are not persistent between game restarts,
	-- so no need for corresponding player metadata.
    debug(flag3, "  resetting all equipbuff values to zero")
	p_data.equip_buff_damage_prev = 0
	p_data.equip_buff_cold_prev = 0
	p_data.equip_buff_heat_prev = 0
    p_data.equip_buff_sun_prev = 0
    p_data.equip_buff_water_prev = 0
	p_data.equip_buff_wetness_prev = 0
	p_data.equip_buff_disease_prev = 0
	p_data.equip_buff_electrical_prev = 0
    p_data.equip_buff_radiation_prev = 0
    p_data.equip_buff_gas_prev = 0
	p_data.equip_buff_noise_prev = 0
	p_data.equip_buff_weight_prev = 0

    debug(flag3, "register_on_dieplayer() END")
end)


local flag7 = false
core.register_on_respawnplayer(function(player)
    debug(flag7, "\nregister_on_respawnplayer() CLOTHING")
	local player_meta = player:get_meta()
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

    -- ### not restting player avatar skin, hair, eyes, underwear, and face preferences
    -- ### not restting player avatar base texture
    -- p_data.avatar_texture_base

	debug(flag7, "register_on_respawnplayer() END")
end)