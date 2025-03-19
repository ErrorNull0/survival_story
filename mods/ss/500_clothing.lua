<<<<<<< HEAD
print("- loading clothing.lua")

-- cache global functions for faster access
local table_concat = table.concat
local table_insert = table.insert
local string_gsub = string.gsub
local mt_serialize = minetest.serialize
local mt_show_formspec = minetest.show_formspec
local play_item_sound = ss.play_item_sound
local debug = ss.debug
local ss_round = ss.round
local get_fs_player_avatar = ss.get_fs_player_avatar
local get_fs_equipment_buffs = ss.get_fs_equipment_buffs
local get_fs_equip_slots = ss.get_fs_equip_slots
local build_fs = ss.build_fs

local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local CLOTHING_BUFFS = ss.CLOTHING_BUFFS


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
--- @param p_data table the main player_data table
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

        p_data.equip_buff_damage = p_data.equip_buff_damage + CLOTHING_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold + CLOTHING_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat + CLOTHING_BUFFS[item_name].heat
        p_data.equip_buff_wetness = p_data.equip_buff_wetness + CLOTHING_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease + CLOTHING_BUFFS[item_name].disease
        p_data.equip_buff_radiation = p_data.equip_buff_radiation + CLOTHING_BUFFS[item_name].radiation
        p_data.equip_buff_noise = p_data.equip_buff_noise + CLOTHING_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight + ITEM_WEIGHTS[item_name], 2)

        -- save item name in case this ADD action is actually just first part of a SWAP (refer below)
        p_data.swapped_in_equip_name = item_name
        debug(flag6, "  p_data.swapped_in_equip_name: " .. p_data.swapped_in_equip_name)


    -- in this state, there is assuemd to be the 'undesired' equipped item still in the clothing slot.
    -- where 'p_data.equip_buff_xxxxx' = <whatever existing equip buff value> + <undesired equipped item>.
    -- the equip buff values of the undesired 'item_name' need be removed from p_data.equip_buff_xxxxx.
    -- resulting in 'p_data.equip_buff_xxxxx' = <whatever existing equip buff value>.
    elseif action == "remove" then
        debug(flag6, "  removing from existing equipment buffs totals..")
        p_data.equip_buff_damage = p_data.equip_buff_damage - CLOTHING_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold - CLOTHING_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat - CLOTHING_BUFFS[item_name].heat
        p_data.equip_buff_wetness = p_data.equip_buff_wetness - CLOTHING_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease - CLOTHING_BUFFS[item_name].disease
        p_data.equip_buff_radiation = p_data.equip_buff_radiation - CLOTHING_BUFFS[item_name].radiation
        p_data.equip_buff_noise = p_data.equip_buff_noise - CLOTHING_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[item_name], 2)


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
        p_data.equip_buff_damage_prev = p_data.equip_buff_damage - CLOTHING_BUFFS[swapped_in_item_name].damage
        p_data.equip_buff_cold_prev = p_data.equip_buff_cold - CLOTHING_BUFFS[swapped_in_item_name].cold
        p_data.equip_buff_heat_prev = p_data.equip_buff_heat - CLOTHING_BUFFS[swapped_in_item_name].heat
        p_data.equip_buff_wetness_prev = p_data.equip_buff_wetness - CLOTHING_BUFFS[swapped_in_item_name].wetness
        p_data.equip_buff_disease_prev = p_data.equip_buff_disease - CLOTHING_BUFFS[swapped_in_item_name].disease
        p_data.equip_buff_radiation_prev = p_data.equip_buff_radiation - CLOTHING_BUFFS[swapped_in_item_name].radiation
        p_data.equip_buff_noise_prev = p_data.equip_buff_noise - CLOTHING_BUFFS[swapped_in_item_name].noise
        p_data.equip_buff_weight_prev = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[swapped_in_item_name], 2)

        -- remove the undesired item's equip buff values from the equip buff totals, which leaves
        -- the buff totals to rerpesent: <whatever existing equip buff value> + <desired equipped item>
        debug(flag6, "  removing from existing equipment buffs totals..")
        p_data.equip_buff_damage = p_data.equip_buff_damage - CLOTHING_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold - CLOTHING_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat - CLOTHING_BUFFS[item_name].heat
        p_data.equip_buff_wetness = p_data.equip_buff_wetness - CLOTHING_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease - CLOTHING_BUFFS[item_name].disease
        p_data.equip_buff_radiation = p_data.equip_buff_radiation - CLOTHING_BUFFS[item_name].radiation
        p_data.equip_buff_noise = p_data.equip_buff_noise - CLOTHING_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[item_name], 2)

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
    player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
    player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
    player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
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

        -- update the equipment buff values on the formspec
        update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "add")

        local slot_type = string_gsub(slot_name, "clothing_slot_", "")
        debug(flag2, "  slot_type: " .. slot_type)

        local subtable_name = "equipped_clothing_" .. slot_type
        debug(flag2, "  subtable_name: " .. subtable_name)

        local buff_types = {}

        local buff_data = CLOTHING_BUFFS[item_name]
        debug(flag2, "  buff_data: " .. dump(buff_data))

        if buff_data.damage > 0 then
            local buff_string = "damage=" .. buff_data.damage
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.cold > 0 then
            local buff_string = "cold=" .. buff_data.cold
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.heat > 0 then
            local buff_string = "heat=" .. buff_data.heat
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.wetness > 0 then
            local buff_string = "wetness=" .. buff_data.wetness
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.disease > 0 then
            local buff_string = "disease=" .. buff_data.disease
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.radiation > 0 then
            local buff_string = "radiation=" .. buff_data.radiation
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.noise > 0 then
            local buff_string = "noise=" .. buff_data.noise
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if ITEM_WEIGHTS[item_name] > 0 then
            local buff_string = "weight=" .. ITEM_WEIGHTS[item_name]
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end

        debug(flag2, "  buff_types: " .. dump(buff_types))
        local buff_types_string = table_concat(buff_types, ",")
        debug(flag2, "  buff_types: " .. buff_types_string)

        local equipped_clothing_data = item_name .. " " .. item_meta:get_string("inventory_image") .. " " .. buff_types_string
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
        else
            debug(flag2, "  equiping clothing item into non-legs slot..")
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
                debug(flag2, "update_clothes() end")
                return
            end
            p_data.avatar_clothing_hands = ""
            player_meta:set_string("avatar_clothing_hands", "")
            debug(flag2, "  new avatar_clothing_hands: " .. p_data.avatar_clothing_hands)
            p_data.equipped_clothing_hands = ""
            player_meta:set_string("equipped_clothing_hands", "")

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
    play_item_sound("item_move", {item_name = item_name, player_name = player_name})
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
    minetest.override_item(item_name, {
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
=======
print("- loading clothing.lua")

-- cache global functions for faster access
local table_concat = table.concat
local table_insert = table.insert
local string_gsub = string.gsub
local mt_serialize = core.serialize
local mt_show_formspec = core.show_formspec
local play_sound = ss.play_sound
local debug = ss.debug
local ss_round = ss.round
local get_fs_player_avatar = ss.get_fs_player_avatar
local get_fs_equipment_buffs = ss.get_fs_equipment_buffs
local get_fs_equip_slots = ss.get_fs_equip_slots
local build_fs = ss.build_fs

local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local CLOTHING_BUFFS = ss.CLOTHING_BUFFS


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

        p_data.equip_buff_damage = p_data.equip_buff_damage + CLOTHING_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold + CLOTHING_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat + CLOTHING_BUFFS[item_name].heat
        p_data.equip_buff_wetness = p_data.equip_buff_wetness + CLOTHING_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease + CLOTHING_BUFFS[item_name].disease
        p_data.equip_buff_radiation = p_data.equip_buff_radiation + CLOTHING_BUFFS[item_name].radiation
        p_data.equip_buff_noise = p_data.equip_buff_noise + CLOTHING_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight + ITEM_WEIGHTS[item_name], 2)

        -- save item name in case this ADD action is actually just first part of a SWAP (refer below)
        p_data.swapped_in_equip_name = item_name
        debug(flag6, "  p_data.swapped_in_equip_name: " .. p_data.swapped_in_equip_name)


    -- in this state, there is assuemd to be the 'undesired' equipped item still in the clothing slot.
    -- where 'p_data.equip_buff_xxxxx' = <whatever existing equip buff value> + <undesired equipped item>.
    -- the equip buff values of the undesired 'item_name' need be removed from p_data.equip_buff_xxxxx.
    -- resulting in 'p_data.equip_buff_xxxxx' = <whatever existing equip buff value>.
    elseif action == "remove" then
        debug(flag6, "  removing from existing equipment buffs totals..")
        p_data.equip_buff_damage = p_data.equip_buff_damage - CLOTHING_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold - CLOTHING_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat - CLOTHING_BUFFS[item_name].heat
        p_data.equip_buff_wetness = p_data.equip_buff_wetness - CLOTHING_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease - CLOTHING_BUFFS[item_name].disease
        p_data.equip_buff_radiation = p_data.equip_buff_radiation - CLOTHING_BUFFS[item_name].radiation
        p_data.equip_buff_noise = p_data.equip_buff_noise - CLOTHING_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[item_name], 2)


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
        p_data.equip_buff_damage_prev = p_data.equip_buff_damage - CLOTHING_BUFFS[swapped_in_item_name].damage
        p_data.equip_buff_cold_prev = p_data.equip_buff_cold - CLOTHING_BUFFS[swapped_in_item_name].cold
        p_data.equip_buff_heat_prev = p_data.equip_buff_heat - CLOTHING_BUFFS[swapped_in_item_name].heat
        p_data.equip_buff_wetness_prev = p_data.equip_buff_wetness - CLOTHING_BUFFS[swapped_in_item_name].wetness
        p_data.equip_buff_disease_prev = p_data.equip_buff_disease - CLOTHING_BUFFS[swapped_in_item_name].disease
        p_data.equip_buff_radiation_prev = p_data.equip_buff_radiation - CLOTHING_BUFFS[swapped_in_item_name].radiation
        p_data.equip_buff_noise_prev = p_data.equip_buff_noise - CLOTHING_BUFFS[swapped_in_item_name].noise
        p_data.equip_buff_weight_prev = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[swapped_in_item_name], 2)

        -- remove the undesired item's equip buff values from the equip buff totals, which leaves
        -- the buff totals to rerpesent: <whatever existing equip buff value> + <desired equipped item>
        debug(flag6, "  removing from existing equipment buffs totals..")
        p_data.equip_buff_damage = p_data.equip_buff_damage - CLOTHING_BUFFS[item_name].damage
        p_data.equip_buff_cold = p_data.equip_buff_cold - CLOTHING_BUFFS[item_name].cold
        p_data.equip_buff_heat = p_data.equip_buff_heat - CLOTHING_BUFFS[item_name].heat
        p_data.equip_buff_wetness = p_data.equip_buff_wetness - CLOTHING_BUFFS[item_name].wetness
        p_data.equip_buff_disease = p_data.equip_buff_disease - CLOTHING_BUFFS[item_name].disease
        p_data.equip_buff_radiation = p_data.equip_buff_radiation - CLOTHING_BUFFS[item_name].radiation
        p_data.equip_buff_noise = p_data.equip_buff_noise - CLOTHING_BUFFS[item_name].noise
        p_data.equip_buff_weight = ss_round(p_data.equip_buff_weight - ITEM_WEIGHTS[item_name], 2)

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
    player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
    player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
    player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
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

        -- update the equipment buff values on the formspec
        update_clothing_buffs(player_name, player_meta, p_data, fs, item_name, "add")

        local slot_type = string_gsub(slot_name, "clothing_slot_", "")
        debug(flag2, "  slot_type: " .. slot_type)

        local subtable_name = "equipped_clothing_" .. slot_type
        debug(flag2, "  subtable_name: " .. subtable_name)

        local buff_types = {}

        local buff_data = CLOTHING_BUFFS[item_name]
        debug(flag2, "  buff_data: " .. dump(buff_data))

        if buff_data.damage > 0 then
            local buff_string = "damage=" .. buff_data.damage
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.cold > 0 then
            local buff_string = "cold=" .. buff_data.cold
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.heat > 0 then
            local buff_string = "heat=" .. buff_data.heat
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.wetness > 0 then
            local buff_string = "wetness=" .. buff_data.wetness
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.disease > 0 then
            local buff_string = "disease=" .. buff_data.disease
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.radiation > 0 then
            local buff_string = "radiation=" .. buff_data.radiation
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if buff_data.noise > 0 then
            local buff_string = "noise=" .. buff_data.noise
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end
        if ITEM_WEIGHTS[item_name] > 0 then
            local buff_string = "weight=" .. ITEM_WEIGHTS[item_name]
            debug(flag2, "  buff_string: " .. buff_string)
            table_insert(buff_types, buff_string)
        end

        debug(flag2, "  buff_types: " .. dump(buff_types))
        local buff_types_string = table_concat(buff_types, ",")
        debug(flag2, "  buff_types: " .. buff_types_string)

        local equipped_clothing_data = item_name .. " " .. item_meta:get_string("inventory_image") .. " " .. buff_types_string
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
        else
            debug(flag2, "  equiping clothing item into non-legs slot..")
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
                debug(flag2, "update_clothes() end")
                return
            end
            p_data.avatar_clothing_hands = ""
            player_meta:set_string("avatar_clothing_hands", "")
            debug(flag2, "  new avatar_clothing_hands: " .. p_data.avatar_clothing_hands)
            p_data.equipped_clothing_hands = ""
            player_meta:set_string("equipped_clothing_hands", "")

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
>>>>>>> 7965987 (update to version 0.0.3)
