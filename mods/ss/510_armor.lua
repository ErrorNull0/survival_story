print("- loading armor.lua")

-- cache global functions for faster access
local table_concat = table.concat
local table_insert = table.insert
local string_gsub = string.gsub
local string_sub = string.sub
local mt_serialize = core.serialize
local mt_get_gametime = core.get_gametime
local mt_show_formspec = core.show_formspec
local mt_after = core.after
local play_sound = ss.play_sound
local debug = ss.debug
local ss_round = ss.round
local lerp = ss.lerp
local after_player_check = ss.after_player_check
local get_fs_player_avatar = ss.get_fs_player_avatar
local get_fs_equipment_buffs = ss.get_fs_equipment_buffs
local get_fs_equip_slots = ss.get_fs_equip_slots
local build_fs = ss.build_fs

local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local ARMOR_COLORS = ss.ARMOR_COLORS
local ARMOR_CONTRASTS = ss.ARMOR_CONTRASTS
local EQUIPMENT_BUFFS = ss.EQUIPMENT_BUFFS
local LEG_INJURY_MODIFIERS = ss.LEG_INJURY_MODIFIERS
local player_data = ss.player_data


-- each 'ARMOR_<body part>' table below contains all items that are allowed to
-- be equipped into that corresponding body part slot
ss.ARMOR_HEAD = {
    ["ss:armor_head_cloth_2"] = true,
    ["ss:armor_head_wood_1"] = true,
    ["ss:armor_head_leather_1"] = true,
    ["ss:armor_head_leather_2"] = true
}
ss.ARMOR_FACE = {
    ["ss:armor_face_cloth_1"] = true,
    ["ss:armor_face_cloth_2"] = true
}
ss.ARMOR_CHEST = {
    ["ss:armor_chest_wood_1"] = true,
    ["ss:armor_chest_leather_1"] = true
}
ss.ARMOR_ARMS = {
    ["ss:armor_arms_wood_1"] = true,
    ["ss:armor_arms_leather_1"] = true
}
ss.ARMOR_LEGS = {
    ["ss:armor_legs_wood_1"] = true,
    ["ss:armor_legs_leather_1"] = true
}
ss.ARMOR_FEET = {
    ["ss:armor_feet_fiber_1"] = true,
    ["ss:armor_feet_fiber_2"] = true,
    ["ss:armor_feet_cloth_2"] = true,
    ["ss:armor_feet_leather_1"] = true
}


-- any feet armor like shoes or boots that could cover over long leg clothing go here.
-- this allows the foot armor to use an alternate mask to hide upper part of the feet armor.
local SHOES = {
    ["ss:armor_feet_cloth_2"] = true,
    ["ss:armor_feet_fiber_2"] = true,
    ["ss:armor_feet_leather_1"] = true
}

local flag4 = false
--- @param body_part string body part for the armor: head, face, chest, arms, legs
--- @param slot_name string the armor slot being inspected
--- @param texture_name string the texture name of the armor, including texture modifiers
--- @param p_data table reference to table with data specific to this player
--- @param player_meta MetaDataRef used to access various player meta data
--- @return string | nil new_texture_name the new texture name based on the armor and
-- the armor slot being inspected. returns 'nil' if the armor item does'not belong to
-- this slot and the slot is empty.
local function get_texture_string(body_part, slot_name, texture_name, p_data, player_meta)
    debug(flag4, "  get_texture_string()")
    debug(flag4, "    body_part: " .. body_part)
    debug(flag4, "    slot_name: " .. slot_name)
    debug(flag4, "    texture_name: " .. texture_name)

    local slot_to_check = "armor_slot_" .. body_part
    local pdata_subtable = "avatar_armor_" .. body_part
    debug(flag4, "    slot_to_check: " .. slot_to_check)
    debug(flag4, "    pdata_subtable: " .. pdata_subtable)

    local new_texture_name
    if slot_name == slot_to_check then
        p_data[pdata_subtable] = texture_name
        player_meta:set_string(pdata_subtable, texture_name)
        new_texture_name = texture_name
    else
        debug(flag4, "    armor item not for this slot.")
        if p_data[pdata_subtable] ~= "" then
            debug(flag4, "    slot currently has an item. returning that texture name..")
            new_texture_name = p_data[pdata_subtable]
        end
    end
    debug(flag4, "  get_texture_string() end")

    return new_texture_name
end


local flag5 = false
local function update_armor_buffs(player_name, player_meta, p_data, fs, item_name, action)
    debug(flag5, "  update_armor_buffs()")
    debug(flag5, "    item_name: " .. item_name)
    debug(flag5, "    action: " .. action)

    -- in this state, there is assuemd no item equipped in the armor slot. the values for
    -- 'p_data.equip_buff_xxxxx' = <whatever existing equip buff values from other equip slots>.
    -- thus the equip buff values of 'item_name' just need to be added to p_data.equip_buff_xxxxx.
    if action == "add" then
        debug(flag5, "  adding to existing equipment buffs..")
        p_data.equip_buff_damage = p_data.equip_buff_damage + EQUIPMENT_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold + EQUIPMENT_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat + EQUIPMENT_BUFFS[item_name].heat
        p_data.equip_buff_sun = p_data.equip_buff_sun + EQUIPMENT_BUFFS[item_name].sun
        p_data.equip_buff_water = p_data.equip_buff_water + EQUIPMENT_BUFFS[item_name].water
        p_data.equip_buff_wetness = p_data.equip_buff_wetness + EQUIPMENT_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease + EQUIPMENT_BUFFS[item_name].disease
        p_data.equip_buff_electrical = p_data.equip_buff_electrical + EQUIPMENT_BUFFS[item_name].electrical
        p_data.equip_buff_radiation = p_data.equip_buff_radiation + EQUIPMENT_BUFFS[item_name].radiation
        p_data.equip_buff_gas = p_data.equip_buff_gas + EQUIPMENT_BUFFS[item_name].gas
        p_data.equip_buff_noise = p_data.equip_buff_noise + EQUIPMENT_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight + ITEM_WEIGHTS[item_name], 2)

        -- save item name in case this ADD action is actually just first part of a SWAP (refer below)
        p_data.swapped_in_equip_name = item_name
        debug(flag5, "  p_data.swapped_in_equip_name: " .. p_data.swapped_in_equip_name)

    -- in this state, there is assuemd to be the 'undesired' equipped item still in the armor slot.
    -- where 'p_data.equip_buff_xxxxx' = <whatever existing equip buff value> + <undesired equipped item>.
    -- the equip buff values of the undesired 'item_name' need be removed from p_data.equip_buff_xxxxx.
    -- resulting in 'p_data.equip_buff_xxxxx' = <whatever existing equip buff value>.
    elseif action == "remove" then 
        debug(flag5, "  removing from existing equipment buffs totals..")
        p_data.equip_buff_damage = p_data.equip_buff_damage - EQUIPMENT_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold - EQUIPMENT_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat - EQUIPMENT_BUFFS[item_name].heat
        p_data.equip_buff_sun = p_data.equip_buff_sun - EQUIPMENT_BUFFS[item_name].sun
        p_data.equip_buff_water = p_data.equip_buff_water - EQUIPMENT_BUFFS[item_name].water
        p_data.equip_buff_wetness = p_data.equip_buff_wetness - EQUIPMENT_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease - EQUIPMENT_BUFFS[item_name].disease
        p_data.equip_buff_electrical = p_data.equip_buff_electrical - EQUIPMENT_BUFFS[item_name].electrical
        p_data.equip_buff_radiation = p_data.equip_buff_radiation - EQUIPMENT_BUFFS[item_name].radiation
        p_data.equip_buff_gas = p_data.equip_buff_gas - EQUIPMENT_BUFFS[item_name].gas
        p_data.equip_buff_noise = p_data.equip_buff_noise - EQUIPMENT_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[item_name], 2)


    -- during swaps, the desired equipment was already equipped during the prior 'add' step.
    -- so the below code block finished off the remaining execution, which is removing the
    -- undesired equip buff values from the equip buff value totals. here, the values for
    -- 'p_data.equip_buff_xxxxx' currently represent:
    -- <whatever existing equip buff value> + <undesired equipped item> + <desired equipped item>.
    -- note the undesired equip buff value still need be removed from the buff value totals.
    elseif action == "swap" then
        debug(flag5, "  swap requested.")

        -- the desired armor item that was equipped during the 'add' action
        local swapped_in_item_name = p_data.swapped_in_equip_name
        debug(flag5, "  swapped_in_item_name: " .. swapped_in_item_name)

        debug(flag5, "  ensuring 'prev' buff value totals reflect the item that was initially swapped in..")
        -- p_data.equip_buff_damage_xxxx_prev = <whatever existing equip buff value> + <undesired equipped item>
        p_data.equip_buff_damage_prev = p_data.equip_buff_damage - EQUIPMENT_BUFFS[swapped_in_item_name].damage
        p_data.equip_buff_cold_prev = p_data.equip_buff_cold - EQUIPMENT_BUFFS[swapped_in_item_name].cold
        p_data.equip_buff_heat_prev = p_data.equip_buff_heat - EQUIPMENT_BUFFS[swapped_in_item_name].heat
        p_data.equip_buff_sun_prev = p_data.equip_buff_sun - EQUIPMENT_BUFFS[swapped_in_item_name].sun
        p_data.equip_buff_water_prev = p_data.equip_buff_water - EQUIPMENT_BUFFS[swapped_in_item_name].water
        p_data.equip_buff_wetness_prev = p_data.equip_buff_wetness - EQUIPMENT_BUFFS[swapped_in_item_name].wetness
        p_data.equip_buff_disease_prev = p_data.equip_buff_disease - EQUIPMENT_BUFFS[swapped_in_item_name].disease
        p_data.equip_buff_electrical_prev = p_data.equip_buff_electrical - EQUIPMENT_BUFFS[swapped_in_item_name].electrical
        p_data.equip_buff_radiation_prev = p_data.equip_buff_radiation - EQUIPMENT_BUFFS[swapped_in_item_name].radiation
        p_data.equip_buff_gas_prev = p_data.equip_buff_gas - EQUIPMENT_BUFFS[swapped_in_item_name].gas
        p_data.equip_buff_noise_prev = p_data.equip_buff_noise - EQUIPMENT_BUFFS[swapped_in_item_name].noise
        p_data.equip_buff_weight_prev = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[swapped_in_item_name], 2)

        -- remove the undesired item's equip buff values from the equip buff totals, which leaves
        -- the buff totals to rerpesent: <whatever existing equip buff value> + <desired equipped item>
        debug(flag5, "  removing from existing equipment buffs totals..")
        p_data.equip_buff_damage = p_data.equip_buff_damage - EQUIPMENT_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold - EQUIPMENT_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat - EQUIPMENT_BUFFS[item_name].heat
        p_data.equip_buff_sun = p_data.equip_buff_sun - EQUIPMENT_BUFFS[item_name].sun
        p_data.equip_buff_water = p_data.equip_buff_water - EQUIPMENT_BUFFS[item_name].water
        p_data.equip_buff_wetness = p_data.equip_buff_wetness - EQUIPMENT_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease - EQUIPMENT_BUFFS[item_name].disease
        p_data.equip_buff_electrical = p_data.equip_buff_electrical - EQUIPMENT_BUFFS[item_name].electrical
        p_data.equip_buff_radiation = p_data.equip_buff_radiation - EQUIPMENT_BUFFS[item_name].radiation
        p_data.equip_buff_gas = p_data.equip_buff_gas - EQUIPMENT_BUFFS[item_name].gas
        p_data.equip_buff_noise = p_data.equip_buff_noise - EQUIPMENT_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[item_name], 2)

        -- at this point 'p_data.equip_buff_xxxx_prev' represents the buff value total
        -- with the undesired clothing equipped. And, 'p_data.equip_buff_xxxx' rerpesents
        -- the buff value total with only the desired clothing equipped.

    else
        debug(flag5, "  ERROR: Unexpected value for 'action': " .. action)
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

     debug(flag5, "  update_armor_buffs() end")
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
--- @param item ItemStack the armor that is being equipped or unequipped
--- @param slot_name string an armor slot: armor_slot_head, armor_slot_chest, etc
--- @param action number whether the armor is being equipped '1' or unequipped '0'
function ss.update_armor(player, item, slot_name, action)
	debug(flag2, "update_armor()")
    local player_name = player:get_player_name()
    local player_meta = player:get_meta()
    local item_name = item:get_name()
    local p_data = ss.player_data[player_name]
    debug(flag2, "  curr avatar_texture_base: " .. p_data.avatar_texture_base)
    debug(flag2, "  curr avatar_texture_armor: " .. p_data.avatar_texture_armor)

    debug(flag2, "  curr avatar_armor_head: " .. p_data.avatar_armor_head)
    debug(flag2, "  curr avatar_armor_face: " .. p_data.avatar_armor_face)
    debug(flag2, "  curr avatar_armor_chest: " .. p_data.avatar_armor_chest)
    debug(flag2, "  curr avatar_armor_arms: " .. p_data.avatar_armor_arms)
    debug(flag2, "  curr avatar_armor_legs: " .. p_data.avatar_armor_legs)
    debug(flag2, "  curr avatar_armor_feet: " .. p_data.avatar_armor_feet)
    debug(flag2, "  slot_name: " .. slot_name)

    -- chest armor includes a body_type identifier because the chest/torso meshes are
    -- different between player model type 1 and 2, thus the textures are differentiated
    local body_type_string = ""
    if slot_name == "armor_slot_chest" then
        body_type_string = "_" .. p_data.body_type
    end

    local item_meta = item:get_meta()
    local texture_color = item_meta:get_string("color")
    local texture_contrast = item_meta:get_string("contrast")
    debug(flag2, "  texture_color: " .. texture_color)
    debug(flag2, "  texture_contrast: " .. texture_contrast)

    local armor_type_string = string_gsub(item_name, "ss:armor_", "", 1)
    debug(flag2, "  armor_type_string: " .. armor_type_string)

    local texture_file_name = "ss_player_armor_" .. armor_type_string
    debug(flag2, "  texture_file_name: " .. texture_file_name)

    local fs = p_data.fs
    local new_avatar_texture

    if action == 1 then
        debug(flag2, "  applying armor texture..")
        debug(flag2, "  retrieved color: " .. texture_color)

        -- update the equipment buff values that are displayed on the bottom left
        -- area of the main inventory formspec
        update_armor_buffs(player_name, player_meta, p_data, fs, item_name, "add")

        local subtable_name = "equipped_armor_" .. string_sub(slot_name, 12)
        debug(flag2, "  subtable_name: " .. subtable_name)

        local equipped_armor_data = item_name .. " " .. item_meta:get_string("inventory_image")
        p_data[subtable_name] = equipped_armor_data
        debug(flag2, "  p_data." .. subtable_name .. ": " .. equipped_armor_data)

        -- save to player metadata
        player_meta:set_string(subtable_name, equipped_armor_data)

        -- use alternate mask file if upper portion of foot armor needs to be covered
        -- over by currently equipped long legs clothing (like pants)
        local mask_string = "_mask.png"
        if SHOES[item_name] then
            debug(flag2, "  these are shoes! checking legs clothing..")

            p_data.foot_armor_texture = texture_file_name
            player_meta:set_string("foot_armor_texture", texture_file_name)
            debug(flag2, "  p_data.leg_clothing_texture: " .. p_data.leg_clothing_texture)

            if p_data.leg_clothing_texture == "" then
                debug(flag2, "  no leg clothing equipped.")
            else
                debug(flag2, "  leg clothing equipped!")
                mask_string = "_mask2.png"
            end
        else
            debug(flag2, "  this is not shoes")
        end

        -- generate armor texture string with the color from item meta data
        local item_texture_string = table_concat({
            texture_file_name, body_type_string, ".png",
            "^[colorizehsl:", texture_color,
            "^[contrast:", texture_contrast,
            "^[mask:ss_player_armor_", armor_type_string, body_type_string, mask_string
        })
        debug(flag2, "  inv_image: " .. item_texture_string)
        item_meta:set_string("inventory_image", item_texture_string)

        -- add parenthesis to the texture string so it can be better combined with other
        -- armor texture strings for the final 'texture' property applied onto player model
        local texture_name = table_concat({ "(", item_texture_string, ")" })
        debug(flag2, "  texture_name: " .. texture_name)

        -- retrieve the texture string from any equipped item from each armor slot and
        -- store into a table to compile the final 'texture' property applied onto player
        -- model. if the armor slot is empty, no texture string is retrieved.
        local all_armor_textures = {}
        for _,body_part in ipairs({"head", "face", "chest", "arms", "legs", "feet"}) do
            table_insert(all_armor_textures, get_texture_string(body_part, slot_name, texture_name, p_data, player_meta))
            debug(flag2, "  p_data.avatar_armor_" .. body_part .. ": " .. p_data["avatar_armor_" .. body_part])
        end
        debug(flag2, "  armor_textures: " .. dump(all_armor_textures))

        -- combine all the armor textures into the final texture string in the format
        -- required for player:set_properties() function
        local combined_armor_textures = table_concat(all_armor_textures, "^")
        p_data.avatar_texture_armor = combined_armor_textures
        player_meta:set_string("avatar_texture_armor", combined_armor_textures)
        debug(flag2, "  p_data.avatar_texture_armor: " .. combined_armor_textures)

        if slot_name == "armor_slot_feet" then
            debug(flag2, "  equiping to feet slot: " .. item_name)
            local modifier_value = LEG_INJURY_MODIFIERS[item_name]
            debug(flag2, "  leg_injury_mod_foot_armor: " .. modifier_value)
            p_data.leg_injury_mod_foot_armor = modifier_value
            player_meta:set_float("leg_injury_mod_foot_armor", modifier_value)
        else
            debug(flag2, "  equiping armor into slot other than feet")
        end

        -- generate the final texture string to be applied to the player model, which is
        -- the base skin texture + combined clothing textures + combined armor textures
        debug(flag2, "  p_data.vatar_texture_base: " .. p_data.avatar_texture_base)
        debug(flag2, "  p_data.avatar_texture_clothes: " .. p_data.avatar_texture_clothes)
        new_avatar_texture = table_concat({ 
            p_data.avatar_texture_base, "^",
            p_data.avatar_texture_clothes, "^",
            combined_armor_textures
        })

        p_data.equipment_count = p_data.equipment_count + 1
        p_data.wetness_drain_mod_equip = lerp(1, 0.3, p_data.equipment_count/12)

    else
        debug(flag2, "  removing armor for " .. slot_name)

        -- use alternate mask file if upper portion of foot armor needs to be covered
        -- over by currently equipped long legs clothing (like pants)
        local mask_string = "_mask.png"
        if SHOES[item_name] then
            debug(flag2, "  these are shoes! checking legs clothing..")
            if p_data.leg_clothing_texture == "" then
                debug(flag2, "  no leg clothing equipped.")
            else
                debug(flag2, "  leg clothing equipped!")
                mask_string = "_mask2.png"
            end
        else
            debug(flag2, "  this is not shoes")
        end

        local texture_name = table_concat({ "(",
            texture_file_name, body_type_string, ".png",
            "^[colorizehsl:", texture_color,
            "^[contrast:", texture_contrast,
            "^[mask:ss_player_armor_", armor_type_string, body_type_string, mask_string,
            ")"
        })

        debug(flag2, "  target texture_name: " .. texture_name)

        if slot_name == "armor_slot_head" then
            debug(flag2, "  curr avatar_armor_head: " .. p_data.avatar_armor_head)
            if texture_name ~= p_data.avatar_armor_head then
                debug(flag2, "  Armor swap was done - new armor is already equipped. No armor removed.")
                update_armor_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_armor() end")
                return
            end
            p_data.avatar_armor_head = ""
            player_meta:set_string("avatar_armor_head", "")
            debug(flag2, "  new avatar_armor_head: " .. p_data.avatar_armor_head)
            p_data.equipped_armor_head = ""
            player_meta:set_string("equipped_armor_head", "")

        elseif slot_name == "armor_slot_face" then
            debug(flag2, "  curr avatar_armor_face: " .. p_data.avatar_armor_face)
            if texture_name ~= p_data.avatar_armor_face then
                debug(flag2, "  Armor swap was done - new armor is already equipped. No armor removed.")
                update_armor_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_armor() end")
                return
            end
            p_data.avatar_armor_face = ""
            player_meta:set_string("avatar_armor_face", "")
            debug(flag2, "  new avatar_armor_face: " .. p_data.avatar_armor_face)
            p_data.equipped_armor_face = ""
            player_meta:set_string("equipped_armor_face", "")

        elseif slot_name == "armor_slot_chest" then
            debug(flag2, "  curr avatar_armor_chest: " .. p_data.avatar_armor_chest)
            if texture_name ~= p_data.avatar_armor_chest then
                debug(flag2, "  Armor swap was done - new armor is already equipped. No armor removed.")
                update_armor_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_armor() end")
                return
            end
            p_data.avatar_armor_chest = ""
            player_meta:set_string("avatar_armor_chest", "")
            debug(flag2, "  new avatar_armor_chest: " .. p_data.avatar_armor_chest)
            p_data.equipped_armor_chest = ""
            player_meta:set_string("equipped_armor_chest", "")

        elseif slot_name == "armor_slot_arms" then
            debug(flag2, "  curr avatar_armor_arms: " .. p_data.avatar_armor_arms)
            if texture_name ~= p_data.avatar_armor_arms then
                debug(flag2, "  Armor swap was done - new armor is already equipped. No armor removed.")
                update_armor_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_armor() end")
                return
            end
            p_data.avatar_armor_arms = ""
            player_meta:set_string("avatar_armor_arms", "")
            debug(flag2, "  new avatar_armor_arms: " .. p_data.avatar_armor_arms)
            p_data.equipped_armor_arms = ""
            player_meta:set_string("equipped_armor_arms", "")

        elseif slot_name == "armor_slot_legs" then
            debug(flag2, "  curr avatar_armor_legs: " .. p_data.avatar_armor_legs)
            if texture_name ~= p_data.avatar_armor_legs then
                debug(flag2, "  Armor swap was done - new armor is already equipped. No armor removed.")
                update_armor_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_armor() end")
                return
            end
            p_data.avatar_armor_legs = ""
            player_meta:set_string("avatar_armor_legs", "")
            debug(flag2, "  new avatar_armor_legs: " .. p_data.avatar_armor_legs)
            p_data.equipped_armor_legs = ""
            player_meta:set_string("equipped_armor_legs", "")

        elseif slot_name == "armor_slot_feet" then
            debug(flag2, "  curr avatar_armor_feet: " .. p_data.avatar_armor_feet)
            if texture_name ~= p_data.avatar_armor_feet then
                debug(flag2, "  Armor swap was done - new armor is already equipped. No armor removed.")
                update_armor_buffs(player_name, player_meta, p_data, fs, item_name, "swap")
                refresh_formspec(player, player_meta, player_name, fs)
                debug(flag2, "update_armor() end")
                return
            end
            p_data.avatar_armor_feet = ""
            player_meta:set_string("avatar_armor_feet", "")
            debug(flag2, "  new avatar_armor_feet: " .. p_data.avatar_armor_feet)
            p_data.equipped_armor_feet = ""
            player_meta:set_string("equipped_armor_feet", "")
            p_data.foot_armor_texture = ""
            player_meta:set_string("foot_armor_texture", "")
            p_data.leg_injury_mod_foot_armor = 1
            player_meta:set_float("leg_injury_mod_foot_armor", 1)

        else
            debug(flag2, "  ERROR - Unknown slot_name: " .. slot_name)
            debug(flag2, "  No armor was removed.")
        end

        update_armor_buffs(player_name, player_meta, p_data, fs, item_name, "remove")

        debug(flag2, "  p_data.avatar_armor_head: " .. p_data.avatar_armor_head)
        debug(flag2, "  p_data.avatar_armor_face: " .. p_data.avatar_armor_face)
        debug(flag2, "  p_data.avatar_armor_chest: " .. p_data.avatar_armor_chest)
        debug(flag2, "  p_data.avatar_armor_arms: " .. p_data.avatar_armor_arms)
        debug(flag2, "  p_data.avatar_armor_legs: " .. p_data.avatar_armor_legs)
        debug(flag2, "  p_data.avatar_armor_feet: " .. p_data.avatar_armor_feet)

        -- compile table with the armor texture string for each body part and sorted in
        -- correct layering order
        local armor_table = {}
        if p_data.avatar_armor_face ~= "" then
            table_insert(armor_table, p_data.avatar_armor_face)
        end
        if p_data.avatar_armor_head ~= "" then
            table_insert(armor_table, p_data.avatar_armor_head)
        end
        if p_data.avatar_armor_chest ~= "" then
            table_insert(armor_table, p_data.avatar_armor_chest)
        end
        if p_data.avatar_armor_arms ~= "" then
            table_insert(armor_table, p_data.avatar_armor_arms)
        end
        if p_data.avatar_armor_legs ~= "" then
            table_insert(armor_table, p_data.avatar_armor_legs)
        end
        if p_data.avatar_armor_feet ~= "" then
            table_insert(armor_table, p_data.avatar_armor_feet)
        end
        debug(flag2, "  armor_table: " .. dump(armor_table))

        if #armor_table > 0 then
            debug(flag2, "  other equipped armor remain..")
            local combined_armor_textures = table_concat(armor_table, "^")
            debug(flag2, "  avatar_texture_armor: " .. combined_armor_textures)
            p_data.avatar_texture_armor = combined_armor_textures
            player_meta:set_string("avatar_texture_armor", combined_armor_textures)
            debug(flag2, "  avatar_texture_base: " .. p_data.avatar_texture_base)

            if p_data.avatar_texture_clothes == "" then
                debug(flag2, "  no clothing is equipped..")
                new_avatar_texture = table_concat({
                    p_data.avatar_texture_base, "^",
                    combined_armor_textures
                })
            else
                debug(flag2, "  clothing is also equipped..")
                new_avatar_texture = table_concat({
                    p_data.avatar_texture_base, "^",
                    p_data.avatar_texture_clothes, "^",
                    combined_armor_textures
                })
            end


        -- if no armor remain in any of the armor slots, simply set avatar
        -- texture same as base avatar texture.
        else
            debug(flag2, "  no more armor equipped..")
            p_data.avatar_texture_armor = ""
            player_meta:set_string("avatar_texture_armor", "")

            if p_data.avatar_texture_clothes == "" then
                debug(flag2, "  no clothing equipped either..")
                new_avatar_texture = p_data.avatar_texture_base
            else
                debug(flag2, "  existing clothing is equipped")
                new_avatar_texture = table_concat({
                    p_data.avatar_texture_base, "^",
                    p_data.avatar_texture_clothes
                })

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

    -- play sound effect for equip/unequip of armor item
    play_sound("item_move", {item_name = item_name, player_name = player_name})
    debug(flag2, "### PLAYED SOUND ###")

	debug(flag2, "update_armor() end")
end


local armor_data = {
    ["ss:armor_feet_fiber_1"] = "feet_fiber_1",
    ["ss:armor_feet_fiber_2"] = "feet_fiber_2",

    ["ss:armor_head_cloth_2"] = "head_cloth_2",
    ["ss:armor_face_cloth_1"] = "face_cloth_1",
    ["ss:armor_face_cloth_2"] = "face_cloth_2",
    ["ss:armor_feet_cloth_2"] = "feet_cloth_2",

    ["ss:armor_head_wood_1"] = "head_wood_1",
    ["ss:armor_chest_wood_1"] = "chest_wood_1",
    ["ss:armor_arms_wood_1"] = "arms_wood_1",
    ["ss:armor_legs_wood_1"] = "legs_wood_1",

    ["ss:armor_head_leather_1"] = "head_leather_1",
    ["ss:armor_head_leather_2"] = "head_leather_2",
    ["ss:armor_chest_leather_1"] = "chest_leather_1",
    ["ss:armor_arms_leather_1"] = "arms_leather_1",
    ["ss:armor_legs_leather_1"] = "legs_leather_1",
    ["ss:armor_feet_leather_1"] = "feet_leather_1",
}

local next_color_index = 1

-- allow random color change of clothing item upon right click
for armor_name, armor_type in pairs(armor_data) do
    core.override_item(armor_name, {
        on_secondary_use = function(itemstack, placer, pointed_thing)
            print("### curr color index: " .. next_color_index)
            print("### armor_type: " .. armor_type)

            local item_meta = itemstack:get_meta()
            local inventory_image = item_meta:get_string("inventory_image")
            print("### current inventory_image: " .. inventory_image)

            local color_count = #ARMOR_COLORS[armor_type]
            print("### color_count: " .. color_count)

            if next_color_index < color_count then
                next_color_index =  next_color_index + 1
            else
                next_color_index = 1
            end
            print("### next_color_index: " .. next_color_index)

            local next_color = ARMOR_COLORS[armor_type][next_color_index]
            local next_contrast = ARMOR_CONTRASTS[armor_type][next_color_index]
            local icon_texture_name = table_concat({
                "ss_armor_", armor_type, ".png",
                "^[colorizehsl:", next_color,
                "^[contrast:", next_contrast,
                "^[mask:ss_armor_", armor_type, "_mask.png"
            })
            item_meta:set_string("inventory_image", icon_texture_name)
            item_meta:set_string("color", next_color)
            item_meta:set_string("contrast", next_contrast)
            print("### new inventory_image: " .. icon_texture_name)
            if next_color_index == color_count then
                next_color_index = 0
            end
            return itemstack
        end
    })
end


local flag15 = false
core.register_on_joinplayer(function(player)
    debug(flag15, "\nregister_on_joinplayer() ARMOR")
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]

    -- new player game
    if p_data.player_status == 0 then
        debug(flag15, "NEW PLAYER")

    -- existing player
    elseif p_data.player_status == 1 then
        debug(flag15, "EXISTING PLAYER")

        debug(flag15, "  p_data.avatar_texture_base: " .. p_data.avatar_texture_base)
        debug(flag15, "  p_data.avatar_texture_clothes: " .. p_data.avatar_texture_clothes)
        debug(flag15, "  p_data.avatar_texture_armor: " .. p_data.avatar_texture_armor)

        -- load any existing clothing and armor.
        local avatar_texture
        if p_data.avatar_texture_clothes == "" then
            debug(flag15, "  no clothing data. no clothes to equip.")
            if p_data.avatar_texture_armor == "" then
                debug(flag15, "  no armor data. no armor to equip.")
            else
                debug(flag15, "  armor data exists. adding armor model..")
                avatar_texture = table_concat({
                    p_data.avatar_texture_base,"^",
                    p_data.avatar_texture_armor
                })
                debug(flag15, "  avatar_texture: " .. avatar_texture)
                mt_after(0.1, function()
                    after_player_check(player)
                    player:set_properties({ textures = {avatar_texture} })
                end)
            end
        else
            debug(flag15, "  clothing data found. adding clothes to model..")
            if p_data.avatar_texture_armor == "" then
                debug(flag15, "  no armor data. no armor to equip.")
                avatar_texture = table_concat({
                    p_data.avatar_texture_base,"^",
                    p_data.avatar_texture_clothes
                })
                debug(flag15, "  avatar_texture: " .. avatar_texture)
            else
                debug(flag15, "  armor data also exists. adding armor model..")
                avatar_texture = table_concat({
                    p_data.avatar_texture_base,"^",
                    p_data.avatar_texture_clothes,"^",
                    p_data.avatar_texture_armor
                })
                debug(flag15, "  avatar_texture: " .. avatar_texture)
            end
            mt_after(0.1, function()
                after_player_check(player)
                player:set_properties({ textures = {avatar_texture} })
            end)
        end

    elseif p_data.player_status == 2 then
        debug(flag15, "DEAD PLAYER. Skipping clothing and armor.")
    else
        debug(flag15, "ERROR - Unexpected 'player_status' value: " .. p_data.player_status)
    end

    debug(flag15, "register_on_joinplayer() end " .. mt_get_gametime())
end)