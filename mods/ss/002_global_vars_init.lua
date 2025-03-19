<<<<<<< HEAD
print("- loading global_vars_init.lua ")

-- This is where some of the global variables from global_variables.lua are initialized

local math_floor = math.floor
local string_split = string.split
local string_sub = string.sub
local table_insert = table.insert
local table_concat = table.concat
local mt_wrap_text = minetest.wrap_text
local mt_deserialize = minetest.deserialize
local mt_get_modpath = minetest.get_modpath
local mt_register_craftitem = minetest.register_craftitem
local mt_register_tool = minetest.register_tool
local mt_register_node = minetest.register_node

-- cache global variables for faster access
local SLOT_WEIGHT_MAX = ss.SLOT_WEIGHT_MAX
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local ARMOR_COLORS = ss.ARMOR_COLORS
local ARMOR_CONTRASTS = ss.ARMOR_CONTRASTS
local POINTING_RANGE_DEFAULT = ss.POINTING_RANGE_DEFAULT
local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids
local job_handles = ss.job_handles
local stat_buffs = ss.stat_buffs
local item_use_cooldowns = ss.item_use_cooldowns
local texture_colors = ss.texture_colors
local texture_saturations = ss.texture_saturations
local texture_lightnesses = ss.texture_lightnesses
local texture_contrasts = ss.texture_contrasts


-- Helper function to print text to console for debugging and testing.
--- @param flag boolean whether to actually print the text to console
--- @param text string the text to be printed to the console
local function debug(flag, text)
	if flag then print(text) end
end


local flag1 = false
minetest.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() global_variables_init.lua")
    local player_meta = player:get_meta()
    local player_status = player_meta:get_int("player_status")
    local player_name = player:get_player_name()

    -- #########################################################
    -- #### initialize global tables indexed by player name ####
    -- #########################################################

    player_hud_ids[player_name] = {}
    job_handles[player_name] = {}
    stat_buffs[player_name] = {}
    item_use_cooldowns[player_name] = {}

    -- #############################################################
    -- #### initialize ss.player_data and any matching metadata ####
    -- #############################################################

    player_data[player_name] = {}
    local p_data = player_data[player_name]

    p_data.active_tab = "main"

    -- the base walk speed and jump height for the player
    p_data.speed_walk_current = 1
    p_data.jump_height_current = 1

    -- the various multipliers that can modify player's walk speed
    p_data.speed_buff_crouch = 1
    p_data.speed_buff_run = 1
    p_data.speed_buff_exhaustion = 1
    p_data.speed_buff_weight = 1

    -- the various multipliers that can modify player's jump height
    p_data.jump_buff_crouch = 1
    p_data.jump_buff_run = 1
    p_data.jump_buff_exhaustion = 1
    p_data.jump_buff_weight = 1

    -- default multipliers against walking speed when doing these actions
    p_data.speed_buff_crouch_default = 0.25
    p_data.speed_buff_run_default = 1.5
    p_data.speed_buff_exhaustion_default = 0.5

    -- default multipliers against jump height when doing these actions
    p_data.jump_buff_crouch_default = 0.0
    p_data.jump_buff_run_default = 1.20
    p_data.jump_buff_exhaustion_default = 0.5

    -- the units of stamina gain/loss for that action
    p_data.stamina_gain_stand = 2.0
    p_data.stamina_gain_walk = 1.0
    p_data.stamina_loss_jump = 3.0
    p_data.stamina_loss_walk_jump = 4.0
    p_data.stamina_loss_walk_jump_mine = 5.0
    p_data.stamina_loss_run = 1.5
    p_data.stamina_loss_run_jump = 6.0
    p_data.stamina_loss_crouch = 0.125
    p_data.stamina_loss_crouch_walk = 0.25
    p_data.stamina_loss_crouch_run = 1.4
    p_data.stamina_loss_crouch_jump = 3.0
    p_data.stamina_loss_crouch_walk_jump = 4.0
    p_data.stamina_loss_crouch_run_jump = 6.0

    p_data.stamina_gain_sit_cave = 2.0
    p_data.stamina_loss_sit_cave_mine = 4.0

    -- inventory index of where the wield item was placed when in cave_it state
    p_data.wield_item_index = 0

    -- the percentage of the wielded weapon's weight that is used as stamina loss
    -- vlue while swinging it
    p_data.stamina_loss_factor_mining = 0.5

    p_data.stamina_full = true
    p_data.exhausted = false

    -- when stamina is being used up, the below stats will also be reduced based
    -- on these factors. for example, thirst_loss_factor_stamina = 0.03 means that
    -- 3% of the statmina loss value is deducted from the thirst stat.
    p_data.hunger_loss_factor_stamina = 0.01
    p_data.thirst_loss_factor_stamina = 0.03
    p_data.sanity_loss_factor_stamina = 0.005

    -- how much to amplify the above three stats loss when player is exhausted.
    -- value of 1 is no change, 1.5 is 50% amplification. this value dynamically
    -- changes during gameplay.
    p_data.exhaustion_factor = 3.0

    p_data.immunity_loss_factor_exhaustion = 0.1


    if player_status == 0 then
        debug(flag1, "  new player")

        p_data.weight_max_per_slot = SLOT_WEIGHT_MAX
        player_meta:set_int("weight_max_per_slot", p_data.weight_max_per_slot)

        -- stores an item_name or recipe_id of the item that was last shown in the item
        -- info slot. used to prevent unneeeded item info panel refresh if the item to
        -- be shown is the same as the previously shown item.
        p_data.prev_iteminfo_item = ""
        player_meta:set_string("prev_iteminfo_item", p_data.prev_iteminfo_item)

        -- stores the latest category tab that was clicked on the crafting pane
        p_data.recipe_category = "tools"
        player_meta:set_string("recipe_category", p_data.recipe_category)

        -- stores the recipe_id of the latest recipe item that was clicked on from the
        -- crafting grid. when chest is opened, all ingredient box fromspec elements are
        -- deleted. when normal crafting pane is displayed again, prev_recipe_id helps
        -- rebuild the ingredient box again with this recipe item.
        p_data.prev_recipe_id = ""
        player_meta:set_string("prev_recipe_id", p_data.prev_recipe_id)

        -- holds the formspec type last interacted with to help callback functions
        -- '*_on_receive_fields()' and '*_player_inventory_action()' take the correct
        -- action. Examples: main_formspec, storage, campfire, itemdrop_bag, etc.
        -- 'player_setup' is the intial value since the player setup formspec is
        -- the the first formspec to show when starting a new game or respawning.
        -- this data is not persistent between game restarts, since formspec_mode
        -- will then default to 'main_formspec'.
        p_data.formspec_mode = "player_setup"

        -- stores how many inv slots beyond the slot max the player is credited due
        -- to equipped bags. needed for proper restore of inv slots as bags are added
        -- or removed from the bag slots. used in function get_slot_count_to_remove()
        p_data.slot_bonus_credit = 0
        player_meta:set_int("slot_bonus_credit", p_data.slot_bonus_credit)

        -- the percentage chance of triggering that noise condition. for exampe, a value
        -- of 25 for 'noise_chance_sneeze' is a "25% chance of sneezing" when the noise
        -- check is activted. current noise checks occur during the following scenarios:
        -- eating/drinking food, and digging up plant type nodes.
        p_data.noise_chance_choke = 10
        player_meta:set_float("noise_chance_choke", p_data.noise_chance_choke)
        p_data.noise_chance_sneeze_plants = 10
        player_meta:set_float("noise_chance_sneeze_plants", p_data.noise_chance_sneeze_plants)
        p_data.noise_chance_sneeze_dust = 10
        player_meta:set_float("noise_chance_sneeze_dust", p_data.noise_chance_sneeze_dust)
        p_data.noise_chance_hickups = 30
        player_meta:set_float("noise_chance_hickups", p_data.noise_chance_hickups)

        -- avatar mesh file
        p_data.avatar_mesh = "ss_player_model_1.b3d"
		player_meta:set_string("avatar_mesh", p_data.avatar_mesh)

		-- avatar BODY TYPE properties
		p_data.body_type = 1
		player_meta:set_int("body_type", p_data.body_type)
		p_data.avatar_body_type_selected = "body_type1"
		player_meta:set_string("avatar_body_type_selected", p_data.avatar_body_type_selected)

		-- avatar SKIN properties
        p_data.avatar_texture_skin = "ss_player_skin_1.png"
		player_meta:set_string("avatar_texture_skin", p_data.avatar_texture_skin)
		p_data.avatar_texture_skin_mask = "ss_player_skin_1_mask.png"
		player_meta:set_string("avatar_texture_skin_mask", p_data.avatar_texture_skin_mask)
		p_data.avatar_texture_skin_hue = texture_colors[2][2]
		player_meta:set_int("avatar_texture_skin_hue", p_data.avatar_texture_skin_hue)
		p_data.avatar_texture_skin_sat = texture_colors[2][3]
		player_meta:set_int("avatar_texture_skin_sat", p_data.avatar_texture_skin_sat)
		p_data.avatar_texture_skin_light = texture_colors[2][4]
		player_meta:set_int("avatar_texture_skin_light", p_data.avatar_texture_skin_light)
		p_data.avatar_texture_skin_sat_mod = texture_saturations[8]
		player_meta:set_int("avatar_texture_skin_sat_mod", p_data.avatar_texture_skin_sat_mod)
		p_data.avatar_texture_skin_light_mod = texture_lightnesses[8]
		player_meta:set_int("avatar_texture_skin_light_mod", p_data.avatar_texture_skin_light_mod)
		p_data.avatar_texture_skin_contrast = texture_contrasts[5]
		player_meta:set_string("avatar_texture_skin_contrast", p_data.avatar_texture_skin_contrast)

        -- avatar selected SKIN properties
		p_data.avatar_skin_color_selected = "color2"
		player_meta:set_string("avatar_skin_color_selected", p_data.avatar_skin_color_selected)
		p_data.avatar_skin_saturation_selected = "saturation8"
		player_meta:set_string("avatar_skin_saturation_selected", p_data.avatar_skin_saturation_selected)
		p_data.avatar_skin_lightness_selected = "lightness8"
		player_meta:set_string("avatar_skin_lightness_selected", p_data.avatar_skin_lightness_selected)
		p_data.avatar_skin_contrast_selected = "contrast5"
		player_meta:set_string("avatar_skin_contrast_selected", p_data.avatar_skin_contrast_selected)

		-- avatar HAIR properties
		p_data.avatar_texture_hair = "ss_player_hair_1.png"
		player_meta:set_string("avatar_texture_hair", p_data.avatar_texture_hair)
		p_data.avatar_texture_hair_mask = "ss_player_hair_1_mask.png"
		player_meta:set_string("avatar_texture_hair_mask", p_data.avatar_texture_hair_mask)
		p_data.avatar_texture_hair_hue = texture_colors[3][2]
		player_meta:set_int("avatar_texture_hair_hue", p_data.avatar_texture_hair_hue)
		p_data.avatar_texture_hair_sat = texture_colors[3][3]
		player_meta:set_int("avatar_texture_hair_sat", p_data.avatar_texture_hair_sat)
		p_data.avatar_texture_hair_light = texture_colors[3][4]
		player_meta:set_int("avatar_texture_hair_light", p_data.avatar_texture_hair_light)
		p_data.avatar_texture_hair_sat_mod = texture_saturations[6]
		player_meta:set_int("avatar_texture_hair_sat_mod", p_data.avatar_texture_hair_sat_mod)
		p_data.avatar_texture_hair_light_mod = texture_lightnesses[2]
		player_meta:set_int("avatar_texture_hair_light_mod", p_data.avatar_texture_hair_light_mod)
		p_data.avatar_texture_hair_contrast = texture_contrasts[1]
		player_meta:set_string("avatar_texture_hair_contrast", p_data.avatar_texture_hair_contrast)

        -- avatar selected HAIR properties
		p_data.avatar_hair_color_selected = "color3"
		player_meta:set_string("avatar_hair_color_selected", p_data.avatar_hair_color_selected)
		p_data.avatar_hair_saturation_selected = "saturation6"
		player_meta:set_string("avatar_hair_saturation_selected", p_data.avatar_hair_saturation_selected)
		p_data.avatar_hair_lightness_selected = "lightness2"
		player_meta:set_string("avatar_hair_lightness_selected", p_data.avatar_hair_lightness_selected)
		p_data.avatar_hair_contrast_selected = "contrast1"
		player_meta:set_string("avatar_hair_contrast_selected", p_data.avatar_hair_contrast_selected)
		p_data.avatar_hair_type_selected = "hair_type1"
		player_meta:set_string("avatar_hair_type_selected", p_data.avatar_hair_type_selected)

		-- avatar EYES properties
		p_data.avatar_texture_eye = "ss_player_eyes_1.png"
		player_meta:set_string("avatar_texture_eye", p_data.avatar_texture_eye)
		p_data.avatar_texture_eye_hue = texture_colors[2][2]
		player_meta:set_int("avatar_texture_eye_hue", p_data.avatar_texture_eye_hue)
		p_data.avatar_texture_eye_sat = texture_colors[2][3]
		player_meta:set_int("avatar_texture_eye_sat", p_data.avatar_texture_eye_sat)
		p_data.avatar_texture_eye_light = texture_colors[2][4]
		player_meta:set_int("avatar_texture_eye_light", p_data.avatar_texture_eye_light)
		p_data.avatar_texture_eye_sat_mod = texture_saturations[4]
		player_meta:set_int("avatar_texture_eye_sat_mod", p_data.avatar_texture_eye_sat_mod)
		p_data.avatar_texture_eye_light_mod = texture_lightnesses[4]
		player_meta:set_int("avatar_texture_eye_light_mod", p_data.avatar_texture_eye_light_mod)

        -- avatar selected EYES properties
		p_data.avatar_eye_color_selected = "color2"
		player_meta:set_string("avatar_eye_color_selected", p_data.avatar_eye_color_selected)
		p_data.avatar_eye_saturation_selected = "saturation4"
		player_meta:set_string("avatar_eye_saturation_selected", p_data.avatar_eye_saturation_selected)
		p_data.avatar_eye_lightness_selected = "lightness4"
		player_meta:set_string("avatar_eye_lightness_selected", p_data.avatar_eye_lightness_selected)

		-- avatar UNDERWEAR properties
		p_data.avatar_texture_underwear = "ss_player_underwear_1.png"
		player_meta:set_string("avatar_texture_underwear", p_data.avatar_texture_underwear)
        p_data.avatar_texture_underwear_mask = "ss_player_underwear_1_mask.png"
		player_meta:set_string("avatar_texture_underwear_mask", p_data.avatar_texture_underwear_mask)
		p_data.avatar_texture_underwear_hue = texture_colors[12][2]
		player_meta:set_int("avatar_texture_underwear_hue", p_data.avatar_texture_underwear_hue)
		p_data.avatar_texture_underwear_sat = texture_colors[12][3]
		player_meta:set_int("avatar_texture_underwear_sat", p_data.avatar_texture_underwear_sat)
		p_data.avatar_texture_underwear_light = texture_colors[12][4]
		player_meta:set_int("avatar_texture_underwear_light", p_data.avatar_texture_underwear_light)
		p_data.avatar_texture_underwear_sat_mod = texture_saturations[3]
		player_meta:set_int("avatar_texture_underwear_sat_mod", p_data.avatar_texture_underwear_sat_mod)
		p_data.avatar_texture_underwear_light_mod = texture_lightnesses[5]
		player_meta:set_int("avatar_texture_underwear_light_mod", p_data.avatar_texture_underwear_light_mod)
		p_data.avatar_texture_underwear_contrast = texture_contrasts[1]
		player_meta:set_string("avatar_texture_underwear_contrast", p_data.avatar_texture_underwear_contrast)

        -- avatar selected UNDERWEAR properties
		p_data.avatar_underwear_color_selected = "color12"
		player_meta:set_string("avatar_underwear_color_selected", p_data.avatar_underwear_color_selected)
		p_data.avatar_underwear_saturation_selected = "saturation3"
		player_meta:set_string("avatar_underwear_saturation_selected", p_data.avatar_underwear_saturation_selected)
		p_data.avatar_underwear_lightness_selected = "lightness5"
		player_meta:set_string("avatar_underwear_lightness_selected", p_data.avatar_underwear_lightness_selected)
		p_data.avatar_underwear_contrast_selected = "contrast1"
		player_meta:set_string("avatar_underwear_contrast_selected", p_data.avatar_underwear_contrast_selected)

		-- avatar FACE properties
		p_data.avatar_texture_face = "ss_player_face_1.png"
		player_meta:set_string("avatar_texture_face", p_data.avatar_texture_face )

        -- the base texture that is the combination of all the above separate textures
        -- initialized in playe_setup.lua
        p_data.avatar_texture_base = "" 
		player_meta:set_string("avatar_texture_base", p_data.avatar_texture_base)

        -- texture filenames for each clothing
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

        -- contains the above clothing textures combined
        p_data.avatar_texture_clothes = ""
        player_meta:set_string("avatar_texture_clothes", p_data.avatar_texture_clothes)

        -- 'pants' is any long leg coverings like pants that might overlap with feet
        -- coverings like sneakers and boots. this flag allows hiding of upper part
        -- of the shoe covering underneath the pants clothing. this way it doesn't
        -- look like pants are being tucked into the shoes.
        p_data.leg_clothing_texture = ""
        player_meta:set_string("leg_clothing_texture", p_data.leg_clothing_texture)

        -- hold data relating to the clothing that is currently equipped in that slot.
        -- empty string denotes no clothing equipped on that slot. Example: 
        -- "ss:clothes_tshirt ss_clothes_tshirt.png damage=2,cold=3,heat=1,wetness=1,disease=0,noise=7,weight=3.4"
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

        -- texture filenames for each armor category
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

        -- contains the above clothing textures combined
        p_data.avatar_texture_armor = ""
        player_meta:set_string("avatar_texture_armor", p_data.avatar_texture_armor)

        -- 'shoes' is any foot covering that might overlap with long leg-coverings
        -- like pants, like sneakers, boots, etc. this flag allows hiding of upper
        -- part of the shoe covering underneath the pants clothing. this way it doesn't
        -- look like pants are being tucked into the shoes.
        p_data.foot_armor_texture = ""
        player_meta:set_string("foot_armor_texture", p_data.foot_armor_texture)

        -- hold data relating to the armor that is currently equipped in that slot.
        -- empty string denotes no armor equipped on that slot. Example: 
        -- "ss:clothes_tshirt ss_clothes_tshirt.png damage=2,cold=3,heat=1,wetness=1,disease=0,noise=7,weight=3.4"
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

        -- these represent the buffs and their values that players get for wearing
        -- equipment like clothing and armor. these values can directly impact player
        -- stats or player status effects during gameplay.
        p_data.equip_buff_damage = 0
        player_meta:set_float("equip_buff_damage", p_data.equip_buff_damage)
        p_data.equip_buff_cold = 0
        player_meta:set_float("equip_buff_cold", p_data.equip_buff_cold)
        p_data.equip_buff_heat = 0
        player_meta:set_float("equip_buff_heat", p_data.equip_buff_heat)
        p_data.equip_buff_wetness = 0
        player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
        p_data.equip_buff_disease = 0
        player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
        p_data.equip_buff_radiation = 0
        player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
        p_data.equip_buff_noise = 0
        player_meta:set_float("equip_buff_noise", p_data.equip_buff_noise)
        p_data.equip_buff_weight = 0
        player_meta:set_float("equip_buff_weight", p_data.equip_buff_weight)

        -- used by ss.get_fs_equipment_buffs() to determine visual coloring of the
        -- equipment buff icons and the red/green coloring of the buff values. not
        -- persistent between game restarts, so no need for corresponding metadata.
        p_data.equip_buff_damage_prev = 0
        p_data.equip_buff_cold_prev = 0
        p_data.equip_buff_heat_prev = 0
        p_data.equip_buff_wetness_prev = 0
        p_data.equip_buff_disease_prev = 0
        p_data.equip_buff_radiation_prev = 0
        p_data.equip_buff_noise_prev = 0
        p_data.equip_buff_weight_prev = 0

		-- whether or not player is viewing the equipment buff details window
		p_data.viewing_equipbuff_window = false

        -- tracks if the breath bar is currently shown on-screen. not saved in player
        -- metadata since this is for hud tracking and will always be false at start
        p_data.is_breathbar_shown = false

		-- the amount of breath that is depleted/restored at each interval
        p_data.breath_deplete_rate = 8
		player_meta:set_float("breath_deplete_rate",p_data.breath_deplete_rate)
        p_data.breath_restore_rate = 16
		player_meta:set_float("breath_restore_rate", p_data.breath_restore_rate)

        -- the amount of stamina that is reduced for those action at each interval
        p_data.stamina_restore_idle = 2.0
		player_meta:set_float("stamina_restore_idle", p_data.stamina_restore_idle)
        p_data.stamina_restore_walk = 0.5
		player_meta:set_float("stamina_restore_walk", p_data.stamina_restore_walk)
        p_data.stamina_deplete_sprint = 2.5
		player_meta:set_float("stamina_deplete_sprint", p_data.stamina_deplete_sprint)
        p_data.stamina_deplete_jump = 8.0
		player_meta:set_float("stamina_deplete_jump", p_data.stamina_deplete_jump)

        -- the percentage of the wielded item's weight used as the stamina depletion value
        -- 0.5 = 50% of the item's weight is the value depleted from stamina
        p_data.wield_item_stamina_factor = 1.0
		player_meta:set_float("wield_item_stamina_factor", p_data.wield_item_stamina_factor)

        -- the percentage of the total stamina depletion that is applied as depletion value
        -- for the below stats when swinging that itme. example: while player is swinging,
        -- 1% of the stamina depletion from swinging, is then removed from hunger stat.
        p_data.swing_deplete_factor_hunger = 0.01
		player_meta:set_float("swing_deplete_factor_hunger", p_data.swing_deplete_factor_hunger)
        p_data.swing_deplete_factor_thirst = 0.03
		player_meta:set_float("swing_deplete_factor_thirst", p_data.swing_deplete_factor_thirst)
        p_data.swing_deplete_factor_sanity = 0.005
		player_meta:set_float("swing_deplete_factor_sanity", p_data.swing_deplete_factor_sanity)

        -- time in seconds player must waits between hand strikes to avoid missing or
        -- lowered hit damage. all other weapons their cooldown times defined in file
        -- attack_cooldown.txt. hands cannot since it does not have an in-game name.
        p_data.fists_cooldown_time = 1.0
		player_meta:set_float("fists_cooldown_time", p_data.fists_cooldown_time)

        -- the amount of HP the player's fists can inflict. all other weapons their
        -- attack damage values defined in file attack_damage.txt. hands cannot since
        -- it does not have an in-game name.
        p_data.fists_attack_damage = 1.5
		player_meta:set_float("fists_attack_damage", p_data.fists_attack_damage)

		-- ** pending implementation (not currently used) **
        -- items usable as weapons have a cooldown time defined in attack_cooldown.txt.
        -- each item also belongs to a weapon group defined in attack_groups.txt. the
        -- below buffs add (if pos) or subtract (if neg) to the base cooldown times.
        -- these buff values can change with player skill progression, injuries, etc.
        p_data.cooldown_buff_fists = 0.1
		player_meta:set_float("cooldown_buff_fists", p_data.cooldown_buff_fists)
        p_data.cooldown_buff_blunt = 0.1
		player_meta:set_float("cooldown_buff_blunt", p_data.cooldown_buff_blunt)
        p_data.cooldown_buff_blade = 0.1
		player_meta:set_float("cooldown_buff_blade",p_data.cooldown_buff_blade)
        p_data.cooldown_buff_spear = 0.1
		player_meta:set_float("cooldown_buff_spear", p_data.cooldown_buff_spear)
        p_data.cooldown_buff_mining = 0.1
		player_meta:set_float("cooldown_buff_mining", p_data.cooldown_buff_mining)

        -- adds on top of the above 'swing deplete factors' when player is exhausted
        p_data.exhaustion_swing_buff_hunger = 0.01
		player_meta:set_float("exhaustion_swing_buff_hunger", p_data.exhaustion_swing_buff_hunger)
        p_data.exhaustion_swing_buff_thirst = 0.03
		player_meta:set_float("exhaustion_swing_buff_thirst", p_data.exhaustion_swing_buff_thirst)
        p_data.exhaustion_swing_buff_sanity = 0.005
        player_meta:set_float("exhaustion_swing_buff_sanity", p_data.exhaustion_swing_buff_sanity)

        -- the percentage of immunity that is depeleted whenever health is depleted.
        -- example: 0.5 = 50% = if 10 HP is lost, then 5 stamina is also lost.
        p_data.immunity_depletion_factor_health = 0.5
		player_meta:set_float("immunity_depletion_factor_health", p_data.immunity_depletion_factor_health)

        -- the percentage of stamina drain for that action, to be depleted from immunity.
        -- example: when player is jumping while exhausted, 10% of the stamina depleted
        -- due to this action will also be removed from stamina.
        p_data.exhausted_immunity_drain_jump = 0.05
		player_meta:set_float("exhausted_immunity_drain_jump", p_data.exhausted_immunity_drain_jump)
        p_data.exhausted_immunity_drain_swing = 0.05
		player_meta:set_float("exhausted_immunity_drain_swing", p_data.exhausted_immunity_drain_swing)
        p_data.exhausted_immunity_drain_sprint = 0.05
        player_meta:set_float("exhausted_immunity_drain_sprint", p_data.exhausted_immunity_drain_sprint)

        -- when using items that alter a player stat, it often alters the stat slowly
        -- over time and not immdiately. below values are how many seconds between each
        -- interval the stat is altered by 1 value. example: if a bandage heals 5 hp,
        -- then the hp recovery will happen at 1 hp every 1 second. if usage_delay_health
        -- is 2.5, then 1 hp will recover every 2.5 seconds until 5 hp has beeen restored.
        p_data.usage_delay_health = 1.0
		player_meta:set_float("usage_delay_health", p_data.usage_delay_health)
        p_data.usage_delay_hunger = 1.0
		player_meta:set_float("usage_delay_hunger", p_data.usage_delay_hunger)
        p_data.usage_delay_thirst = 1.0
		player_meta:set_float("usage_delay_thirst", p_data.usage_delay_thirst)
        p_data.usage_delay_immunity = 1.0
		player_meta:set_float("usage_delay_immunity", p_data.usage_delay_immunity)
        p_data.usage_delay_sanity = 1.0
		player_meta:set_float("usage_delay_sanity", p_data.usage_delay_sanity)
        p_data.usage_delay_breath = 1.0
		player_meta:set_float("usage_delay_breath", p_data.usage_delay_breath)
        p_data.usage_delay_weight = 1.0
		player_meta:set_float("usage_delay_weight", p_data.usage_delay_weight)
        p_data.usage_delay_experience = 1.0
		player_meta:set_float("usage_delay_experience", p_data.usage_delay_experience)
        p_data.usage_delay_stamina = 1.0
        player_meta:set_float("usage_delay_stamina", p_data.usage_delay_stamina)

		-- when a stat is fully depleted, health is repeatedly depleted at a certain interval.
        -- the values below are time intervals in seconds between each health depletion.
        p_data.hp_drain_delay_hunger = 10
		player_meta:set_float("hp_drain_delay_hunger", p_data.hp_drain_delay_hunger)
        p_data.hp_drain_delay_thirst = 5
		player_meta:set_float("hp_drain_delay_thirst", p_data.hp_drain_delay_thirst)
        p_data.hp_drain_delay_immunity = 15
		player_meta:set_float("hp_drain_delay_immunity", p_data.hp_drain_delay_immunity)
        p_data.hp_drain_delay_sanity = 30
		player_meta:set_float("hp_drain_delay_sanity", p_data.hp_drain_delay_sanity)
        p_data.hp_drain_delay_breath = 1
        player_meta:set_float("hp_drain_delay_breath", p_data.hp_drain_delay_breath)

        -- how much health is depleted during each health drain interval above
        p_data.hp_drain_amount_hunger = 1
		player_meta:set_float("hp_drain_amount_hunger", p_data.hp_drain_amount_hunger)
        p_data.hp_drain_amount_thirst = 1
		player_meta:set_float("hp_drain_amount_thirst", p_data.hp_drain_amount_thirst)
        p_data.hp_drain_amount_immunity = 1
		player_meta:set_float("hp_drain_amount_immunity", p_data.hp_drain_amount_immunity)
        p_data.hp_drain_amount_sanity = 1
		player_meta:set_float("hp_drain_amount_sanity", p_data.hp_drain_amount_sanity)
        p_data.hp_drain_amount_breath = 5
        player_meta:set_float("hp_drain_amount_breath", p_data.hp_drain_amount_breath)

		-- how much experience gained from digging anything. currently a flat value, but
        -- will later be dynamically calculated based on player skills and node type
        p_data.experience_gain_digging = 0.5
		player_meta:set_float("experience_gain_digging", p_data.experience_gain_digging)

        -- how much xp gained for crafting an item. this value is multiplied by the
        -- number of outputs if the crafting recipe results in multiple items.
        p_data.experience_gain_crafting = 0.5
		player_meta:set_float("experience_gain_crafting", p_data.experience_gain_crafting)

        -- how much xp gained for crafting an item. this value is multiplied by the
        -- number of outputs if the crafting recipe results in multiple items.
        p_data.experience_gain_cooking = 0.5
		player_meta:set_float("experience_gain_cooking", p_data.experience_gain_cooking)

        -- default movement speed and jump height
        p_data.speed_walk = 1.0
        player_meta:set_float("speed_walk", p_data.speed_walk)
		p_data.height_jump = 1.0
        player_meta:set_float("height_jump", p_data.height_jump)

        -- amount of increase to the speed and jump height when sprinting
        p_data.speed_buff_sprint = 0.5
        player_meta:set_float("speed_buff_sprint", p_data.speed_buff_sprint)
		p_data.jump_buff_sprint = 0.2
        player_meta:set_float("jump_buff_sprint", p_data.jump_buff_sprint)

        -- amount of decrease in speed and jump height based on various levels of
        -- inventory weight encumberance. this value changes dynamically during gameplay
		-- based on changes to the inventory weight. 
		-- speed_buff_weight standard range: 0 to 0.8
        -- jump_buff_weight standard range: 0 to 0.1
        p_data.speed_buff_weight = 1
		player_meta:set_float("speed_buff_weight", p_data.speed_buff_weight)
        p_data.jump_buff_weight = 1
		player_meta:set_float("jump_buff_weight", p_data.jump_buff_weight)

        -- values 1 to 5 indicating the player's current inventory weight category.
		-- 0 initial new start value. update_stat_bar() will update to correct value.
        -- 1 is less than 25% of max weight
        -- 2 is between 25% - 50% of max weight
        -- 3 is between 50% - 75% of max weight
        -- 4 is between 75% - 90% of max weight
        -- 5 is between 90% - 100% of max weight (player is heavily encumbered)
        p_data.weight_tier = 0
		player_meta:set_int("weight_tier", p_data.weight_tier)

        -- amount of decrease in speed and jump height when player is exhausted due to
        -- low stamina
        p_data.speed_buff_exhausted = 0.5
		player_meta:set_float("speed_buff_exhausted", p_data.speed_buff_exhausted)
        p_data.jump_buff_exhausted = 0.2
		player_meta:set_float("jump_buff_exhausted", p_data.jump_buff_exhausted)

        -- tracks if player is currently sprinting or exhausted. 1 = true, = 0 false
        p_data.player_sprinting = 0
		player_meta:set_int("player_sprinting", p_data.player_sprinting)

        -- player's current experience level and player's initial skill points
        p_data.player_level = 1
		player_meta:set_int("player_level", p_data.player_level)
        p_data.player_skill_points = 0
		player_meta:set_int("player_skill_points", p_data.player_skill_points)

        -- the amount of stamina drained when using a fire drill to start a campfire
        p_data.stamina_loss_fire_drill = 20
        player_meta:set_int("stamina_loss_fire_drill", p_data.stamina_loss_fire_drill)

        -- the success rate to start a flame using a the fire starter tool. for example,
        -- the value of 0.50 = 50% success rate, 1.00 = 100% success rate.
        p_data.fire_drill_success_rate = 0.50
        player_meta:set_float("fire_drill_success_rate", p_data.fire_drill_success_rate)
        p_data.match_book_success_rate = 0.80
        player_meta:set_float("match_book_success_rate", p_data.match_book_success_rate)

        -- used for green highlight color for text, recipe icons, tooltips and wear
        p_data.ui_green = "#008000"
        player_meta:set_string("ui_green", p_data.ui_green)

        -- used for orange highlight color for cooking progress
        p_data.ui_orange = "#c63d00"
        player_meta:set_string("ui_orange", p_data.ui_orange)

        -- used for red highlight color for text, recipe icons, and tooltips
        p_data.ui_red = "#800000"
        player_meta:set_string("ui_red", p_data.ui_red)

        -- the currently selected color options (formspec element name)
        p_data.ui_green_selected = "ui_green_opt1"
        player_meta:set_string("ui_green_selected", p_data.ui_green_selected)
        p_data.ui_orange_selected = "ui_orange_opt1"
        player_meta:set_string("ui_orange_selected", p_data.ui_orange_selected)
        p_data.ui_red_selected = "ui_red_opt1"
        player_meta:set_string("ui_red_selected", p_data.ui_red_selected)

        -- the last selected topic and subtopic from the '?' help tab
        p_data.help_topic = ""
        player_meta:set_string("help_topic", p_data.help_topic)
        p_data.help_subtopic = ""
        player_meta:set_string("help_subtopic", p_data.help_subtopic)



    elseif player_status == 1 then
        debug(flag1, "  existing player")

        p_data.weight_max_per_slot = player_meta:get_string("weight_max_per_slot")
        p_data.prev_iteminfo_item = player_meta:get_string("prev_iteminfo_item")
        p_data.recipe_category = player_meta:get_string("recipe_category")
        p_data.prev_recipe_id = player_meta:get_string("prev_recipe_id")
        p_data.slot_bonus_credit = player_meta:get_int("slot_bonus_credit")
        p_data.noise_chance_choke = player_meta:get_float("noise_chance_choke")
        p_data.noise_chance_sneeze_plants = player_meta:get_float("noise_chance_sneeze_plants")
        p_data.noise_chance_sneeze_dust = player_meta:get_float("noise_chance_sneeze_dust")
        p_data.noise_chance_hickups = player_meta:get_float("noise_chance_hickups")
        p_data.formspec_mode = "main_formspec" -- defaults to 'main_formspec' upon rejoining

        -- avatar mesh file
        p_data.avatar_mesh = player_meta:get_string("avatar_mesh")

		-- avatar BODY TYPE properties
		p_data.body_type = player_meta:get_int("body_type")
		p_data.avatar_body_type_selected = player_meta:get_string("avatar_body_type_selected")

		-- avatar SKIN properties
        p_data.avatar_texture_skin = player_meta:get_string("avatar_texture_skin")
		p_data.avatar_texture_skin_mask = player_meta:get_string("avatar_texture_skin_mask")
		p_data.avatar_texture_skin_hue = player_meta:get_int("avatar_texture_skin_hue")
		p_data.avatar_texture_skin_sat = player_meta:get_int("avatar_texture_skin_sat")
		p_data.avatar_texture_skin_light = player_meta:get_int("avatar_texture_skin_light")
		p_data.avatar_texture_skin_sat_mod = player_meta:get_int("avatar_texture_skin_sat_mod")
		p_data.avatar_texture_skin_light_mod = player_meta:get_int("avatar_texture_skin_light_mod")
		p_data.avatar_texture_skin_contrast = player_meta:get_string("avatar_texture_skin_contrast")
		p_data.avatar_skin_color_selected = player_meta:get_string("avatar_skin_color_selected")
		p_data.avatar_skin_saturation_selected = player_meta:get_string("avatar_skin_saturation_selected")
        p_data.avatar_skin_lightness_selected = player_meta:get_string("avatar_skin_lightness_selected")
		p_data.avatar_skin_contrast_selected = player_meta:get_string("avatar_skin_contrast_selected")

		-- avatar HAIR properties
		p_data.avatar_texture_hair = player_meta:get_string("avatar_texture_hair")
		p_data.avatar_texture_hair_mask = player_meta:get_string("avatar_texture_hair_mask")
		p_data.avatar_texture_hair_hue = player_meta:get_int("avatar_texture_hair_hue")
		p_data.avatar_texture_hair_sat = player_meta:get_int("avatar_texture_hair_sat")
		p_data.avatar_texture_hair_light = player_meta:get_int("avatar_texture_hair_light")
		p_data.avatar_texture_hair_sat_mod = player_meta:get_int("avatar_texture_hair_sat_mod")
		p_data.avatar_texture_hair_light_mod = player_meta:get_int("avatar_texture_hair_light_mod")
		p_data.avatar_texture_hair_contrast = player_meta:get_string("avatar_texture_hair_contrast")
		p_data.avatar_hair_color_selected = player_meta:get_string("avatar_hair_color_selected")
		p_data.avatar_hair_saturation_selected = player_meta:get_string("avatar_hair_saturation_selected")
        p_data.avatar_hair_lightness_selected = player_meta:get_string("avatar_hair_lightness_selected")
		p_data.avatar_hair_contrast_selected = player_meta:get_string("avatar_hair_contrast_selected")
		p_data.avatar_hair_type_selected = player_meta:get_string("avatar_hair_type_selected")

		-- avatar EYES properties
		p_data.avatar_texture_eye = player_meta:get_string("avatar_texture_eye")
		p_data.avatar_texture_eye_hue = player_meta:get_int("avatar_texture_eye_hue")
		p_data.avatar_texture_eye_sat = player_meta:get_int("avatar_texture_eye_sat")
		p_data.avatar_texture_eye_light = player_meta:get_int("avatar_texture_eye_light")
		p_data.avatar_texture_eye_sat_mod = player_meta:get_int("avatar_texture_eye_sat_mod")
		p_data.avatar_texture_eye_light_mod = player_meta:get_int("avatar_texture_eye_light_mod")
		p_data.avatar_eye_color_selected = player_meta:get_string("avatar_eye_color_selected")
        p_data.avatar_eye_saturation_selected = player_meta:get_string("avatar_eye_saturation_selected")
        p_data.avatar_eye_lightness_selected = player_meta:get_string("avatar_eye_lightness_selected")

		-- avatar UNDERWEAR properties
        p_data.avatar_texture_underwear = player_meta:get_string("avatar_texture_underwear")
        p_data.avatar_texture_underwear_mask = player_meta:get_string("avatar_texture_underwear_mask")
		p_data.avatar_texture_underwear_hue = player_meta:get_int("avatar_texture_underwear_hue")
		p_data.avatar_texture_underwear_sat = player_meta:get_int("avatar_texture_underwear_sat")
		p_data.avatar_texture_underwear_light = player_meta:get_int("avatar_texture_underwear_light")
		p_data.avatar_texture_underwear_sat_mod = player_meta:get_int("avatar_texture_underwear_sat_mod")
		p_data.avatar_texture_underwear_light_mod = player_meta:get_int("avatar_texture_underwear_light_mod")
		p_data.avatar_texture_underwear_contrast = player_meta:get_string("avatar_texture_underwear_contrast")
		p_data.avatar_underwear_color_selected = player_meta:get_string("avatar_underwear_color_selected")
		p_data.avatar_underwear_saturation_selected = player_meta:get_string("avatar_underwear_saturation_selected")
        p_data.avatar_underwear_lightness_selected = player_meta:get_string("avatar_underwear_lightness_selected")
		p_data.avatar_underwear_contrast_selected = player_meta:get_string("avatar_underwear_contrast_selected")

        -- avatar FACE properties
		p_data.avatar_texture_face = player_meta:get_string("avatar_texture_face")

        -- the base texture that is the combination of all the above separate textures
        p_data.avatar_texture_base = player_meta:get_string("avatar_texture_base")

        -- *** refer to init.lua register_on_joinplayer() which defines the code for
        -- loading currently equipped clothing ***
        p_data.avatar_clothing_eyes = player_meta:get_string("avatar_clothing_eyes")
        p_data.avatar_clothing_neck = player_meta:get_string("avatar_clothing_neck")
        p_data.avatar_clothing_chest = player_meta:get_string("avatar_clothing_chest")
        p_data.avatar_clothing_hands = player_meta:get_string("avatar_clothing_hands")
        p_data.avatar_clothing_legs = player_meta:get_string("avatar_clothing_legs")
        p_data.avatar_clothing_feet = player_meta:get_string("avatar_clothing_feet")
        p_data.avatar_texture_clothes = player_meta:get_string("avatar_texture_clothes")
        p_data.leg_clothing_texture = player_meta:get_string("leg_clothing_texture")
        p_data.equipped_clothing_eyes = player_meta:get_string("equipped_clothing_eyes")
        p_data.equipped_clothing_neck = player_meta:get_string("equipped_clothing_neck")
        p_data.equipped_clothing_chest = player_meta:get_string("equipped_clothing_chest")
        p_data.equipped_clothing_hands = player_meta:get_string("equipped_clothing_hands")
        p_data.equipped_clothing_legs = player_meta:get_string("equipped_clothing_legs")
        p_data.equipped_clothing_feet = player_meta:get_string("equipped_clothing_feet")

        -- *** refer to init.lua register_on_joinplayer() which defines the code for
        -- loading currently equipped armor ***
        p_data.avatar_armor_head = player_meta:get_string("avatar_armor_head")
        p_data.avatar_armor_face = player_meta:get_string("avatar_armor_face")
        p_data.avatar_armor_chest = player_meta:get_string("avatar_armor_chest")
        p_data.avatar_armor_arms = player_meta:get_string("avatar_armor_arms")
        p_data.avatar_armor_legs = player_meta:get_string("avatar_armor_legs")
        p_data.avatar_armor_feet = player_meta:get_string("avatar_armor_feet")
        p_data.avatar_texture_armor = player_meta:get_string("avatar_texture_armor")
        p_data.foot_armor_texture = player_meta:get_string("foot_armor_texture")
        p_data.equipped_armor_head = player_meta:get_string("equipped_armor_head")
        p_data.equipped_armor_face = player_meta:get_string("equipped_armor_face")
        p_data.equipped_armor_chest = player_meta:get_string("equipped_armor_chest")
        p_data.equipped_armor_arms = player_meta:get_string("equipped_armor_arms")
        p_data.equipped_armor_legs = player_meta:get_string("equipped_armor_legs")
        p_data.equipped_armor_feet = player_meta:get_string("equipped_armor_feet")

        p_data.equip_buff_damage = player_meta:get_float("equip_buff_damage")
        p_data.equip_buff_cold = player_meta:get_float("equip_buff_cold")
        p_data.equip_buff_heat = player_meta:get_float("equip_buff_heat")
        p_data.equip_buff_wetness = player_meta:get_float("equip_buff_wetness")
        p_data.equip_buff_disease = player_meta:get_float("equip_buff_disease")
        p_data.equip_buff_radiation = player_meta:get_float("equip_buff_radiation")
        p_data.equip_buff_noise = player_meta:get_float("equip_buff_noise")
        p_data.equip_buff_weight = player_meta:get_float("equip_buff_weight")
        p_data.equip_buff_damage_prev = p_data.equip_buff_damage
        p_data.equip_buff_cold_prev = p_data.equip_buff_cold
        p_data.equip_buff_heat_prev = p_data.equip_buff_heat
        p_data.equip_buff_wetness_prev = p_data.equip_buff_wetness
        p_data.equip_buff_disease_prev = p_data.equip_buff_disease
        p_data.equip_buff_radiation_prev = p_data.equip_buff_radiation
        p_data.equip_buff_noise_prev = p_data.equip_buff_noise
        p_data.equip_buff_weight_prev = p_data.equip_buff_weight
		p_data.viewing_equipbuff_window = false

        -- player stats
		p_data.breath_deplete_rate = player_meta:get_float("breath_deplete_rate")
        p_data.breath_restore_rate = player_meta:get_float("breath_restore_rate")
        p_data.stamina_restore_idle = player_meta:get_float("stamina_restore_idle")
        p_data.stamina_restore_walk = player_meta:get_float("stamina_restore_walk")
        p_data.stamina_deplete_sprint = player_meta:get_float("stamina_deplete_sprint")
        p_data.stamina_deplete_jump = player_meta:get_float("stamina_deplete_jump")
        p_data.wield_item_stamina_factor = player_meta:get_float("wield_item_stamina_factor")
        p_data.swing_deplete_factor_hunger = player_meta:get_float("swing_deplete_factor_hunger")
        p_data.swing_deplete_factor_thirst = player_meta:get_float("swing_deplete_factor_thirst")
        p_data.swing_deplete_factor_sanity = player_meta:get_float("swing_deplete_factor_sanity")
        p_data.fists_cooldown_time = player_meta:get_float("fists_cooldown_time")
        p_data.fists_attack_damage = player_meta:get_float("fists_attack_damage")
        p_data.cooldown_buff_fists = player_meta:get_float("cooldown_buff_fists")
        p_data.cooldown_buff_blunt = player_meta:get_float("cooldown_buff_blunt")
        p_data.cooldown_buff_blade = player_meta:get_float("cooldown_buff_blade")
        p_data.cooldown_buff_spear = player_meta:get_float("cooldown_buff_spear")
        p_data.cooldown_buff_mining = player_meta:get_float("cooldown_buff_mining")
        p_data.exhaustion_swing_buff_hunger = player_meta:get_float("exhaustion_swing_buff_hunger")
        p_data.exhaustion_swing_buff_thirst = player_meta:get_float("exhaustion_swing_buff_thirst")
        p_data.exhaustion_swing_buff_sanity = player_meta:get_float("exhaustion_swing_buff_sanity")
        p_data.immunity_depletion_factor_health = player_meta:get_float("immunity_depletion_factor_health")
        p_data.exhausted_immunity_drain_jump = player_meta:get_float("exhausted_immunity_drain_jump")
        p_data.exhausted_immunity_drain_swing = player_meta:get_float("exhausted_immunity_drain_swing")
        p_data.exhausted_immunity_drain_sprint = player_meta:get_float("exhausted_immunity_drain_sprint")
        p_data.usage_delay_health = player_meta:get_float("usage_delay_health")
        p_data.usage_delay_hunger = player_meta:get_float("usage_delay_hunger")
        p_data.usage_delay_thirst = player_meta:get_float("usage_delay_thirst")
        p_data.usage_delay_immunity = player_meta:get_float("usage_delay_immunity")
        p_data.usage_delay_sanity = player_meta:get_float("usage_delay_sanity")
        p_data.usage_delay_breath = player_meta:get_float("usage_delay_breath")
        p_data.usage_delay_weight = player_meta:get_float("usage_delay_weight")
        p_data.usage_delay_experience = player_meta:get_float("usage_delay_experience")
        p_data.usage_delay_stamina = player_meta:get_float("usage_delay_stamina")
        p_data.hp_drain_delay_hunger = player_meta:get_float("hp_drain_delay_hunger")
        p_data.hp_drain_delay_thirst = player_meta:get_float("hp_drain_delay_thirst")
        p_data.hp_drain_delay_immunity = player_meta:get_float("hp_drain_delay_immunity")
        p_data.hp_drain_delay_santiy = player_meta:get_float("hp_drain_delay_santiy")
        p_data.hp_drain_delay_breath = player_meta:get_float("hp_drain_delay_breath")
        p_data.hp_drain_amount_hunger = player_meta:get_float("hp_drain_amount_hunger")
        p_data.hp_drain_amount_thirst = player_meta:get_float("hp_drain_amount_thirst")
        p_data.hp_drain_amount_immunity = player_meta:get_float("hp_drain_amount_immunity")
        p_data.hp_drain_amount_sanity = player_meta:get_float("hp_drain_amount_sanity")
        p_data.hp_drain_amount_breath = player_meta:get_float("hp_drain_amount_breath")
		p_data.experience_gain_digging = player_meta:get_float("experience_gain_digging")
        p_data.experience_gain_crafting = player_meta:get_float("experience_gain_crafting")
        p_data.experience_gain_cooking = player_meta:get_float("experience_gain_cooking")
        p_data.speed_walk = player_meta:get_float("speed_walk")
        p_data.height_jump = player_meta:get_float("height_jump")
        p_data.speed_buff_sprint = player_meta:get_float("speed_buff_sprint")
        p_data.jump_buff_sprint = player_meta:get_float("jump_buff_sprint")
        p_data.speed_buff_weight = player_meta:get_float("speed_buff_weight")
        p_data.jump_buff_weight = player_meta:get_float("jump_buff_weight")
        p_data.weight_tier = player_meta:get_float("weight_tier")
        p_data.speed_buff_exhausted = player_meta:get_float("speed_buff_exhausted")
        p_data.jump_buff_exhausted = player_meta:get_float("jump_buff_exhausted")
        p_data.player_sprinting = player_meta:get_int("player_sprinting")
        p_data.player_level = player_meta:get_int("player_level")
        p_data.player_skill_points = player_meta:get_int("player_skill_points")

        -- campfire related properties
		p_data.stamina_loss_fire_drill = player_meta:get_int("stamina_loss_fire_drill")
		p_data.fire_drill_success_rate = player_meta:get_float("fire_drill_success_rate")
		p_data.match_book_success_rate = player_meta:get_float("match_book_success_rate")

        -- green, orange and red highlight color for text, recipe icons, icon bg status, tooltips and wear
        p_data.ui_green = player_meta:get_string("ui_green")
        p_data.ui_orange = player_meta:get_string("ui_orange")
        p_data.ui_red = player_meta:get_string("ui_red")
        p_data.ui_green_selected = player_meta:get_string("ui_green_selected")
        p_data.ui_orange_selected = player_meta:get_string("ui_orange_selected")
        p_data.ui_red_selected = player_meta:get_string("ui_red_selected")

        -- the last selected topic and subtopic from the '?' help tab
        p_data.help_topic = player_meta:get_string("help_topic")
        p_data.help_subtopic = player_meta:get_string("help_subtopic")

        debug(flag1, "restoring stat buffs table..")
        local stat_buffs_string = player_meta:get_string("stat_buffs")
        stat_buffs[player_name] = mt_deserialize(stat_buffs_string)

    else
        debug(flag1, "  ERROR - Unexpected 'player_status' value: " .. player_status)
    end

    debug(flag1, "register_on_joinplayer() END")
end)


-- #### re-initialize ss.player_data and any match metadata when player respawns

local flag5 = false
minetest.register_on_respawnplayer(function(player)
    debug(flag5, "\nregister_on_respawnplayer() global_variables_init.lua")
	local player_meta = player:get_meta()
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

    debug(flag5, "  reset player data to default values..")

    p_data.weight_max_per_slot = SLOT_WEIGHT_MAX
    player_meta:set_int("weight_max_per_slot", p_data.weight_max_per_slot)
    p_data.prev_iteminfo_item = ""
    player_meta:set_string("prev_iteminfo_item", p_data.prev_iteminfo_item)
    p_data.recipe_category = "tools"
    player_meta:set_string("recipe_category", p_data.recipe_category)
    p_data.prev_recipe_id = ""
    player_meta:set_string("prev_recipe_id", p_data.prev_recipe_id)
    p_data.formspec_mode = "player_setup" -- player starts new character
    p_data.slot_bonus_credit = 0
    player_meta:set_int("slot_bonus_credit", p_data.slot_bonus_credit)
    p_data.noise_chance_choke = 10
    player_meta:set_float("noise_chance_choke", p_data.noise_chance_choke)
    p_data.noise_chance_sneeze_plants = 10
    player_meta:set_float("noise_chance_sneeze_plants", p_data.noise_chance_sneeze_plants)
    p_data.noise_chance_sneeze_dust = 10
    player_meta:set_float("noise_chance_sneeze_dust", p_data.noise_chance_sneeze_dust)
    p_data.noise_chance_hickups = 30
    player_meta:set_float("noise_chance_hickups", p_data.noise_chance_hickups)

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
    p_data.avatar_texture_clothes = ""
    player_meta:set_string("avatar_texture_clothes", p_data.avatar_texture_clothes)
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
    p_data.equip_buff_wetness = 0
    player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
    p_data.equip_buff_disease = 0
    player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
    p_data.equip_buff_radiation = 0
    player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
    p_data.equip_buff_noise = 0
    player_meta:set_float("equip_buff_noise", p_data.equip_buff_noise)
    p_data.equip_buff_weight = 0
    player_meta:set_float("equip_buff_weight", p_data.equip_buff_weight)

	-- these helper values are not persistent between game restarts,
	-- so no need for corresponding player metadata.
	p_data.equip_buff_damage_prev = 0
	p_data.equip_buff_cold_prev = 0
	p_data.equip_buff_heat_prev = 0
	p_data.equip_buff_wetness_prev = 0
	p_data.equip_buff_disease_prev = 0
	p_data.equip_buff_radiation_prev = 0
	p_data.equip_buff_noise_prev = 0
	p_data.equip_buff_weight_prev = 0
	p_data.viewing_equipbuff_window = false

    -- player stats
	p_data.is_breathbar_shown = false
    p_data.breath_deplete_rate = 8
	player_meta:set_float("breath_deplete_rate", 5)
    p_data.breath_restore_rate = 16
	player_meta:set_float("breath_restore_rate", 10)
    p_data.stamina_restore_idle = 2.0
	player_meta:set_float("stamina_restore_idle", 2.0)
	p_data.stamina_restore_walk = 0.5
	player_meta:set_float("stamina_restore_walk", 0.5)
    p_data.stamina_deplete_sprint = 2.5
	player_meta:set_float("stamina_deplete_sprint", 2.5)
    p_data.stamina_deplete_jump = 8.0
	player_meta:set_float("stamina_deplete_jump", 8.0)
    p_data.wield_item_stamina_factor = 0.5
	player_meta:set_float("wield_item_stamina_factor", 0.5)
    p_data.swing_deplete_factor_hunger = 0.01
	player_meta:set_float("swing_deplete_factor_hunger", 0.01)
    p_data.swing_deplete_factor_thirst = 0.03
	player_meta:set_float("swing_deplete_factor_thirst", 0.03)
    p_data.swing_deplete_factor_sanity = 0.005
	player_meta:set_float("swing_deplete_factor_sanity", 0.005)
    p_data.fists_cooldown_time = 1.0
	player_meta:set_float("fists_cooldown_time", 1.0)
    p_data.fists_attack_damage = 1.5
	player_meta:set_float("fists_attack_damage", 1.5)
    p_data.cooldown_buff_fists = 0.1
	player_meta:set_float("cooldown_buff_fists", 0.1)
    p_data.cooldown_buff_blunt = 0.1
	player_meta:set_float("cooldown_buff_blunt", 0.1)
    p_data.cooldown_buff_blade = 0.1
	player_meta:set_float("cooldown_buff_blade", 0.1)
    p_data.cooldown_buff_spear = 0.1
	player_meta:set_float("cooldown_buff_spear", 0.1)
    p_data.cooldown_buff_mining = 0.1
	player_meta:set_float("cooldown_buff_mining", 0.1)
    p_data.exhaustion_swing_buff_hunger = 0.01
	player_meta:set_float("exhaustion_swing_buff_hunger", 0.01)
    p_data.exhaustion_swing_buff_thirst = 0.03
	player_meta:set_float("exhaustion_swing_buff_thirst", 0.03)
    p_data.exhaustion_swing_buff_sanity = 0.005
	player_meta:set_float("exhaustion_swing_buff_sanity", 0.005)
    p_data.immunity_depletion_factor_health = 0.5
	player_meta:set_float("immunity_depletion_factor_health", 0.5)
    p_data.exhausted_immunity_drain_jump = 0.05
	player_meta:set_float("exhausted_immunity_drain_jump", 0.05)
    p_data.exhausted_immunity_drain_swing = 0.05
	player_meta:set_float("exhausted_immunity_drain_swing", 0.05)
    p_data.exhausted_immunity_drain_sprint = 0.05
	player_meta:set_float("exhausted_immunity_drain_sprint", 0.05)
    p_data.usage_delay_health = 1.0
	player_meta:set_float("usage_delay_health", 1.0)
    p_data.usage_delay_hunger = 1.0
	player_meta:set_float("usage_delay_hunger", 1.0)
    p_data.usage_delay_thirst = 1.0
	player_meta:set_float("usage_delay_thirst", 1.0)
    p_data.usage_delay_immunity = 1.0
	player_meta:set_float("usage_delay_immunity", 1.0)
    p_data.usage_delay_sanity = 1.0
	player_meta:set_float("usage_delay_sanity", 1.0)
    p_data.usage_delay_breath = 1.0
	player_meta:set_float("usage_delay_breath", 1.0)
    p_data.usage_delay_weight = 1.0
	player_meta:set_float("usage_delay_weight", 1.0)
    p_data.usage_delay_experience = 1.0
	player_meta:set_float("usage_delay_experience", 1.0)
    p_data.usage_delay_stamina = 1.0
	player_meta:set_float("usage_delay_stamina", 1.0)
    p_data.hp_drain_delay_hunger = 10
	player_meta:set_float("hp_drain_delay_hunger", 10)
    p_data.hp_drain_delay_thirst = 5
	player_meta:set_float("hp_drain_delay_thirst", 5)
    p_data.hp_drain_delay_immunity = 15
	player_meta:set_float("hp_drain_delay_immunity", 15)
    p_data.hp_drain_delay_sanity = 15
	player_meta:set_float("hp_drain_delay_sanity", 15)
    p_data.hp_drain_delay_breath = 1
	player_meta:set_float("hp_drain_delay_breath", 1)
    p_data.hp_drain_amount_hunger = 1
	player_meta:set_float("hp_drain_amount_hunger", 1)
    p_data.hp_drain_amount_thirst = 1
	player_meta:set_float("hp_drain_amount_thirst", 1)
    p_data.hp_drain_amount_immunity = 1
	player_meta:set_float("hp_drain_amount_immunity", 1)
    p_data.hp_drain_amount_sanity = 1
	player_meta:set_float("hp_drain_amount_sanity", 1)
    p_data.hp_drain_amount_breath = 5
	player_meta:set_float("hp_drain_amount_breath", 5)
    p_data.experience_gain_digging = 0.5
	player_meta:set_float("experience_gain_digging", 0.5)
    p_data.experience_gain_crafting = 0.5
	player_meta:set_float("experience_gain_crafting", 0.5)
    p_data.experience_gain_cooking = 0.5
	player_meta:set_float("experience_gain_cooking", 0.5)
    p_data.speed_walk = 1.0
	player_meta:set_float("speed_walk", 1.0)
    p_data.height_jump = 1.0
	player_meta:set_float("height_jump", 1.0)
    p_data.speed_buff_sprint = 0.5
	player_meta:set_float("speed_buff_sprint", 0.5)
    p_data.jump_buff_sprint = 0.2
	player_meta:set_float("jump_buff_sprint", 0.2)
    p_data.speed_buff_weight = 1
	player_meta:set_float("speed_buff_weight", 1)
    p_data.jump_buff_weight = 1
	player_meta:set_float("jump_buff_weight", 1)
    p_data.weight_tier = 0
	player_meta:set_int("weight_tier", 0)
    p_data.speed_buff_exhausted = 0.5
	player_meta:set_float("speed_buff_exhausted", 0.5)
    p_data.jump_buff_exhausted = 0.2
	player_meta:set_float("jump_buff_exhausted", 0.2)
    p_data.player_sprinting = 0
	player_meta:set_int("player_sprinting", 0)
    p_data.player_level = 1
	player_meta:set_int("player_level", 1)
    p_data.player_skill_points = 0
    player_meta:set_int("player_skill_points", 0)

    -- campfire related properties
	p_data.stamina_loss_fire_drill = 20
	player_meta:set_int("stamina_loss_fire_drill", p_data.stamina_loss_fire_drill)
	p_data.fire_drill_success_rate = 0.50
	player_meta:set_float("fire_drill_success_rate", p_data.fire_drill_success_rate)
	p_data.match_book_success_rate = 0.80
	player_meta:set_float("match_book_success_rate", p_data.match_book_success_rate)

    -- the last selected topic and subtopic from the '?' help tab
    p_data.help_topic = ""
    player_meta:set_string("help_topic", p_data.help_topic)
    p_data.help_subtopic = ""
    player_meta:set_string("help_subtopic", p_data.help_subtopic)

    -- reset global tables that were indexed by this player
    stat_buffs[player_name] = {}
    job_handles[player_name] = {}
    item_use_cooldowns[player_name] = {}

	debug(flag5, "register_on_respawnplayer() END")
end)


-- only executes on a dedicated server. otherwise the game shuts down immediately
-- for single player games
local flag7 = false
minetest.register_on_leaveplayer(function(player, timed_out)
    debug(flag7, "\nregister_on_leaveplayer() global_vars_init.lua")
    local player_name = player:get_player_name()
    debug(flag7, "  cancelling any active buffs...")
    if job_handles[player_name] then
        for buff_id, job in pairs(job_handles[player_name]) do
            job:cancel()
            job_handles[player_name][buff_id] = nil
            debug(flag7, "  ** " .. buff_id ..  " cancelled **")
        end
    end
    debug(flag7, "register_on_leaveplayer() END")
end)



-- #### initializing tables: ITEM_DISPLAY_NAME, ITEM_DESCRIPTOR, ITEM_TOOLTIP,
-- ITEM_CATEGORY, ITEM_DESC_SHORT, ITEM_DESC_LONG

local flag2 = false
debug(flag2, "importing data from item_data.txt ..")
local file_path = mt_get_modpath("ss") .. "/item_data.txt"
local file = io.open(file_path, "r")
if not file then
	debug(flag2, "  Could not open file: " .. file_path)
	return
end

local dataline_1_read = false
local dataline_2_read = false
local dataline_3_read = false
local dataline_4_read = false
local dataline_5_read = false
local item_name, texture_inv
local display_name, descriptor, type, category, group
local inv_sound, miss_sound, hit_sound, consume_sound, break_sound
local weight, fuel_burn_time, cook_time, value, hit_damage, hit_cooldown_time, hit_type, pointing_range
local item_tooltip
local description_short

for line in file:lines() do
    debug(flag2, "  line: " .. line)
	-- Trim whitespace from the line
	line = line:match("^%s*(.-)%s*$")
	-- Skip blank lines and lines that start with '#'
    if line == "" then
        debug(flag2, "    blank line")
        dataline_1_read = false
        dataline_2_read = false
        dataline_3_read = false
        dataline_4_read = false
        dataline_5_read = false
    elseif line:sub(1, 1) == "#" then
        debug(flag2, "    comment line")
        dataline_1_read = false
        dataline_2_read = false
        dataline_3_read = false
        dataline_4_read = false
        dataline_5_read = false
    else
        debug(flag2, "    valid data line")
        if dataline_1_read then
            if dataline_2_read then
                if dataline_3_read then
                    if dataline_4_read then
                        if dataline_5_read then
                            debug(flag2, "    found data line 6")

                            display_name = display_name or "(no display name)"
                            ss.ITEM_DISPLAY_NAME[item_name] = display_name

                            if descriptor == "" then
                                item_tooltip = display_name
                            else
                                ss.ITEM_DESCRIPTOR[item_name] = descriptor
                                item_tooltip = display_name .. " (" .. descriptor .. ")"
                            end
                            ss.ITEM_TOOLTIP[item_name] = item_tooltip

                            ss.ITEM_CATEGORY[item_name] = category

                            if group ~= "" then
                                debug(flag2, "    group: " .. group)
                                if ss.GROUP_ITEMS[group] == nil then
                                    ss.GROUP_ITEMS[group] = {}
                                end
                                table_insert(ss.GROUP_ITEMS[group], item_name)
                                ss.ITEM_GROUPS[item_name] = group
                            end

                            if inv_sound ~= "" then
                                ss.ITEM_SOUNDS_INV[item_name] = inv_sound
                            end

                            if miss_sound ~= "" then
                                ss.ITEM_SOUNDS_MISS[item_name] = miss_sound
                            end

                            if hit_sound ~= "" then
                                ss.ITEM_SOUNDS_HIT[item_name] = inv_sound
                            end
                            if consume_sound ~= "" then
                                ss.ITEM_SOUNDS_USE[item_name] = consume_sound
                            end
                            if break_sound ~= "" then
                                ss.ITEM_SOUNDS_BREAK[item_name] = break_sound
                            end

                            local final_weight = tonumber(weight)
                            ss.ITEM_WEIGHTS[item_name] = final_weight

                            local max_count = math_floor(ss.SLOT_WEIGHT_MAX / final_weight)
                            if max_count > 99 then max_count = 99 end
                            ss.STACK_MAX_COUNTS[item_name] = max_count

                            ss.ITEM_BURN_TIMES[item_name] = tonumber(fuel_burn_time)

                            cook_time = tonumber(cook_time)
                            if cook_time > 0 then
                                ss.ITEM_HEAT_RATES[item_name] = math_floor(ss.COOK_THRESHOLD / cook_time)
                            else
                                ss.ITEM_HEAT_RATES[item_name] = 0
                            end
                            ss.ITEM_VALUES[item_name] = tonumber(value)
                            ss.ITEM_HIT_DAMAGES[item_name] = tonumber(hit_damage)
                            ss.ITEM_HIT_COOLDOWNS[item_name] = tonumber(hit_cooldown_time)
                            ss.ITEM_HIT_TYPES[item_name] = hit_type

                            if pointing_range == "" then
                                ss.ITEM_POINTING_RANGES[item_name] = POINTING_RANGE_DEFAULT
                                pointing_range = POINTING_RANGE_DEFAULT
                            else
                                ss.ITEM_POINTING_RANGES[item_name] = tonumber(pointing_range)
                                pointing_range = tonumber(pointing_range)
                            end

                            ss.ITEM_DESC_SHORT[item_name] = description_short
                            ss.ITEM_DESC_LONG[item_name] = mt_wrap_text(line, 70)

                            local name_tokens = string_split(item_name, ":", true)
                            local type_tokens = string_split(type, ":")

                            if name_tokens[1] == "default" then
                                debug(flag2, "    this is a 'default' mod item. no need to register it.")
                            elseif name_tokens[1] == "stairs" then
                                debug(flag2, "    this is a 'stairs' mod item. no need to register it.")
                            elseif name_tokens[1] == "flowers" then
                                debug(flag2, "    this is a 'flowers' mod item. no need to register it.")
                            elseif name_tokens[1] == "farming" then
                                debug(flag2, "    this is a 'farming' mod item. no need to register it.")

                            elseif type_tokens[1] == "clothes" then
                                debug(flag2, "    this is clothing that can be colored")
                                local clothing_name = string_sub(item_name, 12)
                                debug(flag2, "    clothing_name: " .. clothing_name)
                                texture_inv = table_concat({
                                    "ss_clothes_", clothing_name, ".png",
                                    "^[colorizehsl:", CLOTHING_COLORS[clothing_name][1],
                                    "^[contrast:", CLOTHING_CONTRASTS[clothing_name][1],
                                    "^[mask:ss_clothes_", clothing_name, "_mask.png"
                                })
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            elseif type_tokens[1] == "armor" then
                                debug(flag2, "    this is armor that can be colored")
                                local armor_name = string_sub(item_name, 10)
                                debug(flag2, "    armor_name: " .. armor_name)
                                texture_inv = table_concat({
                                    "ss_armor_", armor_name, ".png",
                                    "^[colorizehsl:", ARMOR_COLORS[armor_name][1],
                                    "^[contrast:", ARMOR_CONTRASTS[armor_name][1],
                                    "^[mask:ss_armor_", armor_name, "_mask.png"
                                })
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            elseif type_tokens[1] == "craftitem" then
                                debug(flag2, "    this is a craftitem")
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv .. ".png",
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            -- only applies to 'ss:' tools
                            elseif type_tokens[1] == "tool" then
                                debug(flag2, "    this is a tool")
                                mt_register_tool(item_name, {
                                        description = item_tooltip,
                                        inventory_image = texture_inv .. ".png",
                                        range = pointing_range,
                                        sound = {
                                            punch_use_air = miss_sound
                                        }
                                    })

                            -- only applies to 'ss:' nodes
                            elseif type_tokens[1] == "node" then
                                debug(flag2, "    this is a node")

                                local node_type = type_tokens[2]
                                debug(flag2, "    node_type: " .. node_type)

                                local walkable
                                local buildable_to

                                if node_type == "solid" then
                                    walkable = true
                                    buildable_to = false
                                elseif node_type == "solid_variable" then
                                    walkable = true
                                    buildable_to = true
                                elseif node_type == "nonsolid_dig" then
                                    walkable = false
                                    buildable_to = true
                                elseif node_type == "nonsolid_nodig" then
                                    walkable = false
                                    buildable_to = false
                                elseif node_type == "gappy_dig" then
                                    walkable = true
                                    buildable_to = true
                                elseif node_type == "gappy_nodig" then
                                    walkable = true
                                    buildable_to = false
                                else
                                    debug(flag2, "    ERROR - Unexpected 'node_type' value: " .. node_type)
                                end

                                local node_def = {
                                    description = item_tooltip,
                                    inventory_image = texture_inv .. ".png",
                                    walkable = walkable,
                                    buildable_to = buildable_to,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                }
                                mt_register_node(item_name, node_def)
                                debug(flag2, "    node_def: " .. dump(node_def))

                            else
                                debug(flag2, "    ERROR - Unexpected 'type' value: " .. type)
                            end

                            dataline_1_read = false
                            dataline_2_read = false
                            dataline_3_read = false
                            dataline_4_read = false
                            dataline_5_read = false
                        else
                            debug(flag2, "    found data line 5")
                            description_short = line
                            dataline_5_read = true
                        end
                    else
                        debug(flag2, "    found data line 4")
                        local tokens = string_split(line, ",", true)
                        debug(flag2, "    dataline_tokens: " .. dump(tokens))
                        weight = tokens[1]
                        fuel_burn_time = tokens[2]
                        cook_time = tokens[3]
                        value = tokens[4]
                        hit_damage = tokens[5]
                        hit_cooldown_time = tokens[6]
                        hit_type = tokens[7]
                        pointing_range = tokens[8]
                        dataline_4_read = true
                    end
                else
                    debug(flag2, "    found data line 3")
                    local tokens = string_split(line, ",", true)
                    debug(flag2, "    dataline_tokens: " .. dump(tokens))
                    inv_sound = tokens[1]
                    miss_sound = tokens[2]
                    hit_sound = tokens[3]
                    consume_sound = tokens[4]
                    break_sound = tokens[5]
                    dataline_3_read = true
                end
            else
                debug(flag2, "    found data line 2")
                local tokens = string_split(line, ",", true)
                debug(flag2, "    dataline_tokens: " .. dump(tokens))
                display_name = tokens[1]
                descriptor = tokens[2]
                type = tokens[3]
                category = tokens[4]
                group = tokens[5]
                dataline_2_read = true
            end
        else
            debug(flag2, "      found data line 1")
            local tokens = string_split(line, ",", true)
            debug(flag2, "    tokens: " .. dump(tokens))
            item_name = tokens[1]
            texture_inv = tokens[2]
            dataline_1_read = true
        end
    end
end
file:close()
local flag2b = true
--debug(flag2b, "  ITEM_DISPLAY_NAME[]: " .. dump(ss.ITEM_DISPLAY_NAME))
--debug(flag2b, "  ITEM_DESCRIPTOR[]: " .. dump(ss.ITEM_DESCRIPTOR))
--debug(flag2b, "  ITEM_TOOLTIP[]: " .. dump(ss.ITEM_TOOLTIP))
--debug(flag2b, "  ITEM_CATEGORY[]: " .. dump(ss.ITEM_CATEGORY))
--debug(flag2b, "  ITEM_GROUPS: " .. dump(ss.ITEM_GROUPS))
--debug(flag2b, "  GROUP_ITEMS: " .. dump(ss.GROUP_ITEMS))
--debug(flag2b, "  ITEM_SOUNDS_INV[]: " .. dump(ss.ITEM_SOUNDS_INV))
--debug(flag2b, "  ITEM_SOUNDS_MISS[]: " .. dump(ss.ITEM_SOUNDS_MISS))
--debug(flag2b, "  ITEM_SOUNDS_HIT[]: " .. dump(ss.ITEM_SOUNDS_HIT))
--debug(flag2b, "  ITEM_SOUNDS_USE[]: " .. dump(ss.ITEM_SOUNDS_USE))
--debug(flag2b, "  ITEM_SOUNDS_BREAK[]: " .. dump(ss.ITEM_SOUNDS_BREAK))
--debug(flag2b, "  ITEM_WEIGHTS[]: " .. dump(ss.ITEM_WEIGHTS))
--debug(flag2b, "  STACK_MAX_COUNTS: " .. dump(ss.STACK_MAX_COUNTS))
--debug(flag2b, "  ITEM_BURN_TIMES[]: " .. dump(ss.ITEM_BURN_TIMES))
--debug(flag2b, "  ITEM_HEAT_RATES[]: " .. dump(ss.ITEM_HEAT_RATES))
--debug(flag2b, "  ITEM_VALUES[]: " .. dump(ss.ITEM_VALUES))
--debug(flag2b, "  ITEM_HIT_DAMAGES[]: " .. dump(ss.ITEM_HIT_DAMAGES))
--debug(flag2b, "  ITEM_HIT_COOLDOWNS[]: " .. dump(ss.ITEM_HIT_COOLDOWNS))
--debug(flag2b, "  ITEM_HIT_TYPES[]: " .. dump(ss.ITEM_HIT_TYPES))
--debug(flag2b, "  ITEM_POINTING_RANGES[]: " .. dump(ss.ITEM_POINTING_RANGES))
--debug(flag2b, "  ITEM_DESC_SHORT[]: " .. dump(ss.ITEM_DESC_SHORT))
--debug(flag2b, "  ITEM_DESC_LONG[]: " .. dump(ss.ITEM_DESC_LONG))



-- #### initialize ss.NODE_DROPS_FLATTENED

local flag4 = false
debug(flag4, "populating FLATTENED_NODE_DROPS table..")
file_path = mt_get_modpath("ss") .. "/node_drops_flattened.txt"
file = io.open(file_path, "r")
if not file then
	debug(flag4, "  Could not open file: " .. file_path)
	return
end
for line in file:lines() do
	-- Trim whitespace from the line
	line = line:match("^%s*(.-)%s*$")
	-- Skip blank lines and lines that start with '#'
	if line ~= "" and line:sub(1, 1) ~= "#" then
		local line_tokens = string_split(line)
		local item_name_ = line_tokens[1]
		debug(flag4, "  item_name_: " .. item_name_)
		local item_drop
		if line_tokens[2] then
			item_drop = ItemStack(line_tokens[2])
		else
			item_drop = ItemStack("")
		end
		ss.NODE_DROPS_FLATTENED[item_name_] = ItemStack(item_drop)
	end
end
file:close()
debug(flag4, "  NODE_DROPS_FLATTENED[]: " .. dump(ss.NODE_DROPS_FLATTENED))


=======
print("- loading global_vars_init.lua ")

-- This is where some of the global variables from global_variables.lua are initialized

local math_floor = math.floor
local string_split = string.split
local string_sub = string.sub
local table_insert = table.insert
local table_concat = table.concat
local mt_wrap_text = core.wrap_text
local mt_serialize = core.serialize
local mt_deserialize = core.deserialize
local mt_get_modpath = core.get_modpath
local mt_register_craftitem = core.register_craftitem
local mt_register_tool = core.register_tool
local mt_register_node = core.register_node

-- cache global variables for faster access
local SLOT_WEIGHT_MAX = ss.SLOT_WEIGHT_MAX
local CLOTHING_COLORS = ss.CLOTHING_COLORS
local CLOTHING_CONTRASTS = ss.CLOTHING_CONTRASTS
local ARMOR_COLORS = ss.ARMOR_COLORS
local ARMOR_CONTRASTS = ss.ARMOR_CONTRASTS
local POINTING_RANGE_DEFAULT = ss.POINTING_RANGE_DEFAULT
local player_data = ss.player_data
local player_hud_ids = ss.player_hud_ids
local job_handles = ss.job_handles
local is_cooldown_active = ss.is_cooldown_active
local texture_colors = ss.texture_colors
local texture_saturations = ss.texture_saturations
local texture_lightnesses = ss.texture_lightnesses
local texture_contrasts = ss.texture_contrasts


-- Helper function to print text to console for debugging and testing.
--- @param flag boolean whether to actually print the text to console
--- @param text string the text to be printed to the console
local function debug(flag, text)
	if flag then print(text) end
end


local flag1 = false
core.register_on_joinplayer(function(player)
	debug(flag1, "\nregister_on_joinplayer() global_variables_init.lua")
    local player_meta = player:get_meta()
    local player_status = player_meta:get_int("player_status")
    local player_name = player:get_player_name()

    -- #########################################################
    -- #### initialize global tables indexed by player name ####
    -- #########################################################

    player_hud_ids[player_name] = {}
    job_handles[player_name] = {}
    is_cooldown_active[player_name] = {}

    -- #############################################################
    -- #### initialize ss.player_data and any matching metadata ####
    -- #############################################################

    player_data[player_name] = {}
    local p_data = player_data[player_name]
    p_data.player_status = player_status

    -- which of the tabs within the main inventory window that is being viewed.
    -- the default is "main" whenever the inventory window is closed.
    p_data.active_tab = "main"

    -- the player's current animation, which is mainly controlled by player_anim.lua.
    -- possible animation states are defined by 'animms' of the lua file. player
    -- spawns in as crouching by default, then stands if nothing overhead.
    p_data.current_anim_state = "crouch"

    -- the base walk speed and jump height for the player
    p_data.speed_walk_current = 1
    p_data.jump_height_current = 1

    -- the various multipliers that can modify player's walk speed
    p_data.speed_buff_crouch = 1
    p_data.speed_buff_run = 1
    p_data.speed_buff_exhaustion = 1

    -- the various multipliers that can modify player's jump height
    p_data.jump_buff_crouch = 1
    p_data.jump_buff_run = 1
    p_data.jump_buff_exhaustion = 1
    p_data.jump_buff_weight = 1

    -- default multipliers against walking speed when doing these actions
    p_data.speed_buff_crouch_default = 0.25
    p_data.speed_buff_run_default = 1.5

    -- default multipliers against jump height when doing these actions
    p_data.jump_buff_crouch_default = 0.0
    p_data.jump_buff_run_default = 1.20

    -- whether or not player is viewing the equipment buff details window
    p_data.viewing_equipbuff_window = false

    -- indicates if a player vocal sound effect (coughing, grunting, exhaling, etc)
    -- is currently playing due to a stat effect or other player action. this helps
    -- prevent other vocal sound effects from playing until the current one is done.
    p_data.player_vocalizing = false


    if player_status == 0 then
        debug(flag1, "  new player")

        -- holds the HUD display info for each statbar. 'hud_pos' determines which
        -- horiztal position index the statbar appears, 1 starting at the left side.
        -- 'active' determines if the statbar is actually displayed on screen. both
        -- of these properties are configurable by the player from the Settings tab.
        
        p_data.statbar_settings = { -- for testing purposes            
            health = {hud_pos = 9, active = true},
            thirst = {hud_pos = 8, active = true},
            hunger = {hud_pos = 7, active = true},
            alertness = {hud_pos = 6, active = true},
            hygiene = {hud_pos = 5, active = true},
            comfort = {hud_pos = 4, active = true},
            immunity = {hud_pos = 3, active = true},
            sanity = {hud_pos = 2, active = true},
            happiness = {hud_pos = 1, active = true}
        }
        
        --[[
        p_data.statbar_settings = {
            hunger = {hud_pos = 1, active = true},
            thirst = {hud_pos = 2, active = true},
            health = {hud_pos = 3, active = true},
            immunity = {hud_pos = 4, active = false},
            alertness = {hud_pos = 5, active = false},
            sanity = {hud_pos = 6, active = false},
            hygiene = {hud_pos = 7, active = false},
            comfort = {hud_pos = 8, active = false},
            happiness = {hud_pos = 9, active = false}
        }
        --]]
        player_meta:set_string("statbar_settings", mt_serialize(p_data.statbar_settings))

        -- the opacity of the background box displayed behind the vertical statbars
        -- and status effect images. values can be 5 options, modifiable from the
        -- Settings tab: "00" = 0%, "40" = 25%, "80" = 50%, "C0" = 75%, "FF" = 100%.
        p_data.stats_bg_opacity = "80"
        player_meta:set_string("stats_bg_opacity", p_data.stats_bg_opacity)

        p_data.weight_max_per_slot = SLOT_WEIGHT_MAX
        player_meta:set_int("weight_max_per_slot", p_data.weight_max_per_slot)

        -- stores an item_name or recipe_id of the item that was last shown in the item
        -- info slot. used to prevent unneeeded item info panel refresh if the item to
        -- be shown is the same as the previously shown item.
        p_data.prev_iteminfo_item = ""
        player_meta:set_string("prev_iteminfo_item", p_data.prev_iteminfo_item)

        -- stores the latest category tab that was clicked on the crafting pane
        p_data.recipe_category = "tools"
        player_meta:set_string("recipe_category", p_data.recipe_category)

        -- stores the recipe_id of the latest recipe item that was clicked on from the
        -- crafting grid.
        p_data.prev_recipe_id = ""
        player_meta:set_string("prev_recipe_id", p_data.prev_recipe_id)

        -- holds the formspec type last interacted with to help callback functions
        -- '*_on_receive_fields()' and '*_player_inventory_action()' take the correct
        -- action. Examples: main_formspec, storage, campfire, itemdrop_bag, etc.
        -- 'player_setup' is the intial value since the player setup formspec is
        -- the the first formspec to show when starting a new game or respawning.
        -- this data is not persistent between game restarts, since formspec_mode
        -- will then default to 'main_formspec'.
        p_data.formspec_mode = "player_setup"

        -- stores how many inv slots beyond the slot max the player is credited due
        -- to equipped bags. needed for proper restore of inv slots as bags are added
        -- or removed from the bag slots. used in function get_slot_count_to_remove()
        p_data.slot_bonus_credit = 0
        player_meta:set_int("slot_bonus_credit", p_data.slot_bonus_credit)

        -- the percentage chance of triggering that noise condition. for exampe, a value
        -- of 25 for 'noise_chance_sneeze' is a "25% chance of sneezing" when the noise
        -- check is activted. current noise checks occur during the following scenarios:
        -- eating/drinking food, and digging up plant type nodes.
        p_data.noise_chance_choke = 10
        player_meta:set_float("noise_chance_choke", p_data.noise_chance_choke)
        p_data.noise_chance_sneeze_plants = 10
        player_meta:set_float("noise_chance_sneeze_plants", p_data.noise_chance_sneeze_plants)
        p_data.noise_chance_sneeze_dust = 10
        player_meta:set_float("noise_chance_sneeze_dust", p_data.noise_chance_sneeze_dust)
        p_data.noise_chance_hickups = 30
        player_meta:set_float("noise_chance_hickups", p_data.noise_chance_hickups)

        -- avatar mesh file
        p_data.avatar_mesh = "ss_player_model_1.b3d"
		player_meta:set_string("avatar_mesh", p_data.avatar_mesh)

		-- avatar BODY TYPE properties
		p_data.body_type = 1
		player_meta:set_int("body_type", p_data.body_type)
		p_data.avatar_body_type_selected = "body_type1"
		player_meta:set_string("avatar_body_type_selected", p_data.avatar_body_type_selected)

		-- avatar SKIN properties
        p_data.avatar_texture_skin = "ss_player_skin_1.png"
		player_meta:set_string("avatar_texture_skin", p_data.avatar_texture_skin)
		p_data.avatar_texture_skin_mask = "ss_player_skin_1_mask.png"
		player_meta:set_string("avatar_texture_skin_mask", p_data.avatar_texture_skin_mask)
		p_data.avatar_texture_skin_hue = texture_colors[2][2]
		player_meta:set_int("avatar_texture_skin_hue", p_data.avatar_texture_skin_hue)
		p_data.avatar_texture_skin_sat = texture_colors[2][3]
		player_meta:set_int("avatar_texture_skin_sat", p_data.avatar_texture_skin_sat)
		p_data.avatar_texture_skin_light = texture_colors[2][4]
		player_meta:set_int("avatar_texture_skin_light", p_data.avatar_texture_skin_light)
		p_data.avatar_texture_skin_sat_mod = texture_saturations[8]
		player_meta:set_int("avatar_texture_skin_sat_mod", p_data.avatar_texture_skin_sat_mod)
		p_data.avatar_texture_skin_light_mod = texture_lightnesses[8]
		player_meta:set_int("avatar_texture_skin_light_mod", p_data.avatar_texture_skin_light_mod)
		p_data.avatar_texture_skin_contrast = texture_contrasts[5]
		player_meta:set_string("avatar_texture_skin_contrast", p_data.avatar_texture_skin_contrast)

        -- avatar selected SKIN properties
		p_data.avatar_skin_color_selected = "color2"
		player_meta:set_string("avatar_skin_color_selected", p_data.avatar_skin_color_selected)
		p_data.avatar_skin_saturation_selected = "saturation8"
		player_meta:set_string("avatar_skin_saturation_selected", p_data.avatar_skin_saturation_selected)
		p_data.avatar_skin_lightness_selected = "lightness8"
		player_meta:set_string("avatar_skin_lightness_selected", p_data.avatar_skin_lightness_selected)
		p_data.avatar_skin_contrast_selected = "contrast5"
		player_meta:set_string("avatar_skin_contrast_selected", p_data.avatar_skin_contrast_selected)

		-- avatar HAIR properties
		p_data.avatar_texture_hair = "ss_player_hair_1.png"
		player_meta:set_string("avatar_texture_hair", p_data.avatar_texture_hair)
		p_data.avatar_texture_hair_mask = "ss_player_hair_1_mask.png"
		player_meta:set_string("avatar_texture_hair_mask", p_data.avatar_texture_hair_mask)
		p_data.avatar_texture_hair_hue = texture_colors[3][2]
		player_meta:set_int("avatar_texture_hair_hue", p_data.avatar_texture_hair_hue)
		p_data.avatar_texture_hair_sat = texture_colors[3][3]
		player_meta:set_int("avatar_texture_hair_sat", p_data.avatar_texture_hair_sat)
		p_data.avatar_texture_hair_light = texture_colors[3][4]
		player_meta:set_int("avatar_texture_hair_light", p_data.avatar_texture_hair_light)
		p_data.avatar_texture_hair_sat_mod = texture_saturations[6]
		player_meta:set_int("avatar_texture_hair_sat_mod", p_data.avatar_texture_hair_sat_mod)
		p_data.avatar_texture_hair_light_mod = texture_lightnesses[2]
		player_meta:set_int("avatar_texture_hair_light_mod", p_data.avatar_texture_hair_light_mod)
		p_data.avatar_texture_hair_contrast = texture_contrasts[1]
		player_meta:set_string("avatar_texture_hair_contrast", p_data.avatar_texture_hair_contrast)

        -- avatar selected HAIR properties
		p_data.avatar_hair_color_selected = "color3"
		player_meta:set_string("avatar_hair_color_selected", p_data.avatar_hair_color_selected)
		p_data.avatar_hair_saturation_selected = "saturation6"
		player_meta:set_string("avatar_hair_saturation_selected", p_data.avatar_hair_saturation_selected)
		p_data.avatar_hair_lightness_selected = "lightness2"
		player_meta:set_string("avatar_hair_lightness_selected", p_data.avatar_hair_lightness_selected)
		p_data.avatar_hair_contrast_selected = "contrast1"
		player_meta:set_string("avatar_hair_contrast_selected", p_data.avatar_hair_contrast_selected)
		p_data.avatar_hair_type_selected = "hair_type1"
		player_meta:set_string("avatar_hair_type_selected", p_data.avatar_hair_type_selected)

		-- avatar EYES properties
		p_data.avatar_texture_eye = "ss_player_eyes_1.png"
		player_meta:set_string("avatar_texture_eye", p_data.avatar_texture_eye)
		p_data.avatar_texture_eye_hue = texture_colors[2][2]
		player_meta:set_int("avatar_texture_eye_hue", p_data.avatar_texture_eye_hue)
		p_data.avatar_texture_eye_sat = texture_colors[2][3]
		player_meta:set_int("avatar_texture_eye_sat", p_data.avatar_texture_eye_sat)
		p_data.avatar_texture_eye_light = texture_colors[2][4]
		player_meta:set_int("avatar_texture_eye_light", p_data.avatar_texture_eye_light)
		p_data.avatar_texture_eye_sat_mod = texture_saturations[4]
		player_meta:set_int("avatar_texture_eye_sat_mod", p_data.avatar_texture_eye_sat_mod)
		p_data.avatar_texture_eye_light_mod = texture_lightnesses[4]
		player_meta:set_int("avatar_texture_eye_light_mod", p_data.avatar_texture_eye_light_mod)

        -- avatar selected EYES properties
		p_data.avatar_eye_color_selected = "color2"
		player_meta:set_string("avatar_eye_color_selected", p_data.avatar_eye_color_selected)
		p_data.avatar_eye_saturation_selected = "saturation4"
		player_meta:set_string("avatar_eye_saturation_selected", p_data.avatar_eye_saturation_selected)
		p_data.avatar_eye_lightness_selected = "lightness4"
		player_meta:set_string("avatar_eye_lightness_selected", p_data.avatar_eye_lightness_selected)

		-- avatar UNDERWEAR properties
		p_data.avatar_texture_underwear = "ss_player_underwear_1.png"
		player_meta:set_string("avatar_texture_underwear", p_data.avatar_texture_underwear)
        p_data.avatar_texture_underwear_mask = "ss_player_underwear_1_mask.png"
		player_meta:set_string("avatar_texture_underwear_mask", p_data.avatar_texture_underwear_mask)
		p_data.avatar_texture_underwear_hue = texture_colors[12][2]
		player_meta:set_int("avatar_texture_underwear_hue", p_data.avatar_texture_underwear_hue)
		p_data.avatar_texture_underwear_sat = texture_colors[12][3]
		player_meta:set_int("avatar_texture_underwear_sat", p_data.avatar_texture_underwear_sat)
		p_data.avatar_texture_underwear_light = texture_colors[12][4]
		player_meta:set_int("avatar_texture_underwear_light", p_data.avatar_texture_underwear_light)
		p_data.avatar_texture_underwear_sat_mod = texture_saturations[3]
		player_meta:set_int("avatar_texture_underwear_sat_mod", p_data.avatar_texture_underwear_sat_mod)
		p_data.avatar_texture_underwear_light_mod = texture_lightnesses[5]
		player_meta:set_int("avatar_texture_underwear_light_mod", p_data.avatar_texture_underwear_light_mod)
		p_data.avatar_texture_underwear_contrast = texture_contrasts[1]
		player_meta:set_string("avatar_texture_underwear_contrast", p_data.avatar_texture_underwear_contrast)

        -- avatar selected UNDERWEAR properties
		p_data.avatar_underwear_color_selected = "color12"
		player_meta:set_string("avatar_underwear_color_selected", p_data.avatar_underwear_color_selected)
		p_data.avatar_underwear_saturation_selected = "saturation3"
		player_meta:set_string("avatar_underwear_saturation_selected", p_data.avatar_underwear_saturation_selected)
		p_data.avatar_underwear_lightness_selected = "lightness5"
		player_meta:set_string("avatar_underwear_lightness_selected", p_data.avatar_underwear_lightness_selected)
		p_data.avatar_underwear_contrast_selected = "contrast1"
		player_meta:set_string("avatar_underwear_contrast_selected", p_data.avatar_underwear_contrast_selected)

		-- avatar FACE properties
		p_data.avatar_texture_face = "ss_player_face_1.png"
		player_meta:set_string("avatar_texture_face", p_data.avatar_texture_face )

        -- the base texture that is the combination of all the above separate textures
        -- initialized in playe_setup.lua
        p_data.avatar_texture_base = ""
		player_meta:set_string("avatar_texture_base", p_data.avatar_texture_base)

        -- texture filenames for each clothing
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

        -- contains the above clothing textures combined
        p_data.avatar_texture_clothes = ""
        player_meta:set_string("avatar_texture_clothes", p_data.avatar_texture_clothes)

        -- 'pants' is any long leg coverings like pants that might overlap with feet
        -- coverings like sneakers and boots. this flag allows hiding of upper part
        -- of the shoe covering underneath the pants clothing. this way it doesn't
        -- look like pants are being tucked into the shoes.
        p_data.leg_clothing_texture = ""
        player_meta:set_string("leg_clothing_texture", p_data.leg_clothing_texture)

        -- hold data relating to the clothing that is currently equipped in that slot.
        -- empty string denotes no clothing equipped on that slot. Example: 
        -- "ss:clothes_tshirt ss_clothes_tshirt.png damage=2,cold=3,heat=1,wetness=1,disease=0,noise=7,weight=3.4"
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

        -- texture filenames for each armor category
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

        -- contains the above clothing textures combined
        p_data.avatar_texture_armor = ""
        player_meta:set_string("avatar_texture_armor", p_data.avatar_texture_armor)

        -- 'shoes' is any foot covering that might overlap with long leg-coverings
        -- like pants, like sneakers, boots, etc. this flag allows hiding of upper
        -- part of the shoe covering underneath the pants clothing. this way it doesn't
        -- look like pants are being tucked into the shoes.
        p_data.foot_armor_texture = ""
        player_meta:set_string("foot_armor_texture", p_data.foot_armor_texture)

        -- hold data relating to the armor that is currently equipped in that slot.
        -- empty string denotes no armor equipped on that slot. Example: 
        -- "ss:clothes_tshirt ss_clothes_tshirt.png damage=2,cold=3,heat=1,wetness=1,disease=0,noise=7,weight=3.4"
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

        -- these represent the buffs and their values that players get for wearing
        -- equipment like clothing and armor. these values can directly impact player
        -- stats or player status effects during gameplay.
        p_data.equip_buff_damage = 0
        player_meta:set_float("equip_buff_damage", p_data.equip_buff_damage)
        p_data.equip_buff_cold = 0
        player_meta:set_float("equip_buff_cold", p_data.equip_buff_cold)
        p_data.equip_buff_heat = 0
        player_meta:set_float("equip_buff_heat", p_data.equip_buff_heat)
        p_data.equip_buff_wetness = 0
        player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
        p_data.equip_buff_disease = 0
        player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
        p_data.equip_buff_radiation = 0
        player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
        p_data.equip_buff_noise = 0
        player_meta:set_float("equip_buff_noise", p_data.equip_buff_noise)
        p_data.equip_buff_weight = 0
        player_meta:set_float("equip_buff_weight", p_data.equip_buff_weight)

        -- used by ss.get_fs_equipment_buffs() to determine visual coloring of the
        -- equipment buff icons and the red/green coloring of the buff values. not
        -- persistent between game restarts, so no need for corresponding metadata.
        p_data.equip_buff_damage_prev = 0
        p_data.equip_buff_cold_prev = 0
        p_data.equip_buff_heat_prev = 0
        p_data.equip_buff_wetness_prev = 0
        p_data.equip_buff_disease_prev = 0
        p_data.equip_buff_radiation_prev = 0
        p_data.equip_buff_noise_prev = 0
        p_data.equip_buff_weight_prev = 0

        -- time in seconds player must waits between hand strikes to avoid missing or
        -- lowered hit damage. all other weapons their cooldown times defined in file
        -- attack_cooldown.txt. hands cannot since it does not have an in-game name.
        p_data.fists_cooldown_time = 1.0
		player_meta:set_float("fists_cooldown_time", p_data.fists_cooldown_time)

        -- the amount of HP the player's fists can inflict. all other weapons their
        -- attack damage values defined in file attack_damage.txt. hands cannot since
        -- it does not have an in-game name.
        p_data.fists_attack_damage = 1.5
		player_meta:set_float("fists_attack_damage", p_data.fists_attack_damage)

		-- ** pending implementation (not currently used) **
        -- items usable as weapons have a cooldown time defined in attack_cooldown.txt.
        -- each item also belongs to a weapon group defined in attack_groups.txt. the
        -- below buffs add (if pos) or subtract (if neg) to the base cooldown times.
        -- these buff values can change with player skill progression, injuries, etc.
        p_data.cooldown_buff_fists = 0.1
		player_meta:set_float("cooldown_buff_fists", p_data.cooldown_buff_fists)
        p_data.cooldown_buff_blunt = 0.1
		player_meta:set_float("cooldown_buff_blunt", p_data.cooldown_buff_blunt)
        p_data.cooldown_buff_blade = 0.1
		player_meta:set_float("cooldown_buff_blade",p_data.cooldown_buff_blade)
        p_data.cooldown_buff_spear = 0.1
		player_meta:set_float("cooldown_buff_spear", p_data.cooldown_buff_spear)
        p_data.cooldown_buff_mining = 0.1
		player_meta:set_float("cooldown_buff_mining", p_data.cooldown_buff_mining)

        -- how much xp gained for crafting an item. this value is multiplied by the
        -- number of outputs if the crafting recipe results in multiple items.
        p_data.experience_gain_crafting = 0.5
		player_meta:set_float("experience_gain_crafting", p_data.experience_gain_crafting)

        -- how much xp gained for crafting an item. this value is multiplied by the
        -- number of outputs if the crafting recipe results in multiple items.
        p_data.experience_gain_cooking = 0.5
		player_meta:set_float("experience_gain_cooking", p_data.experience_gain_cooking)

        -- default movement speed and jump height
        p_data.speed_walk = 1.0
        player_meta:set_float("speed_walk", p_data.speed_walk)
		p_data.height_jump = 1.0
        player_meta:set_float("height_jump", p_data.height_jump)

        -- amount of decrease in speed and jump height based on various levels of
        -- inventory weight encumbrance. this value changes dynamically during gameplay
		-- based on changes to the inventory weight. 
		-- speed_buff_weight standard range: 0 to 0.8
        -- jump_buff_weight standard range: 0 to 0.1
        p_data.speed_buff_weight = 1
		player_meta:set_float("speed_buff_weight", p_data.speed_buff_weight)
        p_data.jump_buff_weight = 1
		player_meta:set_float("jump_buff_weight", p_data.jump_buff_weight)

        -- player's current experience level and player's initial skill points
        p_data.player_level = 1
		player_meta:set_int("player_level", p_data.player_level)
        p_data.player_skill_points = 0
		player_meta:set_int("player_skill_points", p_data.player_skill_points)

        -- the success rate to start a flame using a the fire starter tool. for example,
        -- the value of 0.50 = 50% success rate, 1.00 = 100% success rate.
        p_data.fire_drill_success_rate = 0.50
        player_meta:set_float("fire_drill_success_rate", p_data.fire_drill_success_rate)
        p_data.match_book_success_rate = 0.80
        player_meta:set_float("match_book_success_rate", p_data.match_book_success_rate)

        -- used for green highlight color for text, recipe icons, tooltips and wear
        p_data.ui_green = "#008000"
        player_meta:set_string("ui_green", p_data.ui_green)

        -- used for orange highlight color for cooking progress
        p_data.ui_orange = "#c63d00"
        player_meta:set_string("ui_orange", p_data.ui_orange)

        -- used for red highlight color for text, recipe icons, and tooltips
        p_data.ui_red = "#800000"
        player_meta:set_string("ui_red", p_data.ui_red)

        -- the currently selected color options (formspec element name)
        p_data.ui_green_selected = "ui_green_opt1"
        player_meta:set_string("ui_green_selected", p_data.ui_green_selected)
        p_data.ui_orange_selected = "ui_orange_opt1"
        player_meta:set_string("ui_orange_selected", p_data.ui_orange_selected)
        p_data.ui_red_selected = "ui_red_opt1"
        player_meta:set_string("ui_red_selected", p_data.ui_red_selected)

        -- the last selected topic and subtopic from the '?' help tab
        p_data.help_topic = ""
        player_meta:set_string("help_topic", p_data.help_topic)
        p_data.help_subtopic = ""
        player_meta:set_string("help_subtopic", p_data.help_subtopic)

    else
        debug(flag1, "  existing player (or joined game while dead)")
        p_data.statbar_settings = mt_deserialize(player_meta:get_string("statbar_settings"))
        p_data.stats_bg_opacity = player_meta:get_string("stats_bg_opacity")

        p_data.weight_max_per_slot = player_meta:get_string("weight_max_per_slot")
        p_data.prev_iteminfo_item = player_meta:get_string("prev_iteminfo_item")
        p_data.recipe_category = player_meta:get_string("recipe_category")
        p_data.prev_recipe_id = player_meta:get_string("prev_recipe_id")
        p_data.slot_bonus_credit = player_meta:get_int("slot_bonus_credit")
        p_data.noise_chance_choke = player_meta:get_float("noise_chance_choke")
        p_data.noise_chance_sneeze_plants = player_meta:get_float("noise_chance_sneeze_plants")
        p_data.noise_chance_sneeze_dust = player_meta:get_float("noise_chance_sneeze_dust")
        p_data.noise_chance_hickups = player_meta:get_float("noise_chance_hickups")
        p_data.formspec_mode = "main_formspec" -- defaults to 'main_formspec' upon rejoining

        -- avatar mesh file
        p_data.avatar_mesh = player_meta:get_string("avatar_mesh")

		-- avatar BODY TYPE properties
		p_data.body_type = player_meta:get_int("body_type")
		p_data.avatar_body_type_selected = player_meta:get_string("avatar_body_type_selected")

		-- avatar SKIN properties
        p_data.avatar_texture_skin = player_meta:get_string("avatar_texture_skin")
		p_data.avatar_texture_skin_mask = player_meta:get_string("avatar_texture_skin_mask")
		p_data.avatar_texture_skin_hue = player_meta:get_int("avatar_texture_skin_hue")
		p_data.avatar_texture_skin_sat = player_meta:get_int("avatar_texture_skin_sat")
		p_data.avatar_texture_skin_light = player_meta:get_int("avatar_texture_skin_light")
		p_data.avatar_texture_skin_sat_mod = player_meta:get_int("avatar_texture_skin_sat_mod")
		p_data.avatar_texture_skin_light_mod = player_meta:get_int("avatar_texture_skin_light_mod")
		p_data.avatar_texture_skin_contrast = player_meta:get_string("avatar_texture_skin_contrast")
		p_data.avatar_skin_color_selected = player_meta:get_string("avatar_skin_color_selected")
		p_data.avatar_skin_saturation_selected = player_meta:get_string("avatar_skin_saturation_selected")
        p_data.avatar_skin_lightness_selected = player_meta:get_string("avatar_skin_lightness_selected")
		p_data.avatar_skin_contrast_selected = player_meta:get_string("avatar_skin_contrast_selected")

		-- avatar HAIR properties
		p_data.avatar_texture_hair = player_meta:get_string("avatar_texture_hair")
		p_data.avatar_texture_hair_mask = player_meta:get_string("avatar_texture_hair_mask")
		p_data.avatar_texture_hair_hue = player_meta:get_int("avatar_texture_hair_hue")
		p_data.avatar_texture_hair_sat = player_meta:get_int("avatar_texture_hair_sat")
		p_data.avatar_texture_hair_light = player_meta:get_int("avatar_texture_hair_light")
		p_data.avatar_texture_hair_sat_mod = player_meta:get_int("avatar_texture_hair_sat_mod")
		p_data.avatar_texture_hair_light_mod = player_meta:get_int("avatar_texture_hair_light_mod")
		p_data.avatar_texture_hair_contrast = player_meta:get_string("avatar_texture_hair_contrast")
		p_data.avatar_hair_color_selected = player_meta:get_string("avatar_hair_color_selected")
		p_data.avatar_hair_saturation_selected = player_meta:get_string("avatar_hair_saturation_selected")
        p_data.avatar_hair_lightness_selected = player_meta:get_string("avatar_hair_lightness_selected")
		p_data.avatar_hair_contrast_selected = player_meta:get_string("avatar_hair_contrast_selected")
		p_data.avatar_hair_type_selected = player_meta:get_string("avatar_hair_type_selected")

		-- avatar EYES properties
		p_data.avatar_texture_eye = player_meta:get_string("avatar_texture_eye")
		p_data.avatar_texture_eye_hue = player_meta:get_int("avatar_texture_eye_hue")
		p_data.avatar_texture_eye_sat = player_meta:get_int("avatar_texture_eye_sat")
		p_data.avatar_texture_eye_light = player_meta:get_int("avatar_texture_eye_light")
		p_data.avatar_texture_eye_sat_mod = player_meta:get_int("avatar_texture_eye_sat_mod")
		p_data.avatar_texture_eye_light_mod = player_meta:get_int("avatar_texture_eye_light_mod")
		p_data.avatar_eye_color_selected = player_meta:get_string("avatar_eye_color_selected")
        p_data.avatar_eye_saturation_selected = player_meta:get_string("avatar_eye_saturation_selected")
        p_data.avatar_eye_lightness_selected = player_meta:get_string("avatar_eye_lightness_selected")

		-- avatar UNDERWEAR properties
        p_data.avatar_texture_underwear = player_meta:get_string("avatar_texture_underwear")
        p_data.avatar_texture_underwear_mask = player_meta:get_string("avatar_texture_underwear_mask")
		p_data.avatar_texture_underwear_hue = player_meta:get_int("avatar_texture_underwear_hue")
		p_data.avatar_texture_underwear_sat = player_meta:get_int("avatar_texture_underwear_sat")
		p_data.avatar_texture_underwear_light = player_meta:get_int("avatar_texture_underwear_light")
		p_data.avatar_texture_underwear_sat_mod = player_meta:get_int("avatar_texture_underwear_sat_mod")
		p_data.avatar_texture_underwear_light_mod = player_meta:get_int("avatar_texture_underwear_light_mod")
		p_data.avatar_texture_underwear_contrast = player_meta:get_string("avatar_texture_underwear_contrast")
		p_data.avatar_underwear_color_selected = player_meta:get_string("avatar_underwear_color_selected")
		p_data.avatar_underwear_saturation_selected = player_meta:get_string("avatar_underwear_saturation_selected")
        p_data.avatar_underwear_lightness_selected = player_meta:get_string("avatar_underwear_lightness_selected")
		p_data.avatar_underwear_contrast_selected = player_meta:get_string("avatar_underwear_contrast_selected")

        -- avatar FACE properties
		p_data.avatar_texture_face = player_meta:get_string("avatar_texture_face")

        -- the base texture that is the combination of all the above separate textures
        p_data.avatar_texture_base = player_meta:get_string("avatar_texture_base")

        -- *** refer to armor.lua register_on_joinplayer() which defines the code for
        -- loading currently equipped clothing ***
        p_data.avatar_clothing_eyes = player_meta:get_string("avatar_clothing_eyes")
        p_data.avatar_clothing_neck = player_meta:get_string("avatar_clothing_neck")
        p_data.avatar_clothing_chest = player_meta:get_string("avatar_clothing_chest")
        p_data.avatar_clothing_hands = player_meta:get_string("avatar_clothing_hands")
        p_data.avatar_clothing_legs = player_meta:get_string("avatar_clothing_legs")
        p_data.avatar_clothing_feet = player_meta:get_string("avatar_clothing_feet")
        p_data.avatar_texture_clothes = player_meta:get_string("avatar_texture_clothes")
        p_data.leg_clothing_texture = player_meta:get_string("leg_clothing_texture")
        p_data.equipped_clothing_eyes = player_meta:get_string("equipped_clothing_eyes")
        p_data.equipped_clothing_neck = player_meta:get_string("equipped_clothing_neck")
        p_data.equipped_clothing_chest = player_meta:get_string("equipped_clothing_chest")
        p_data.equipped_clothing_hands = player_meta:get_string("equipped_clothing_hands")
        p_data.equipped_clothing_legs = player_meta:get_string("equipped_clothing_legs")
        p_data.equipped_clothing_feet = player_meta:get_string("equipped_clothing_feet")

        -- *** refer to armor.lua register_on_joinplayer() which defines the code for
        -- loading currently equipped armor ***
        p_data.avatar_armor_head = player_meta:get_string("avatar_armor_head")
        p_data.avatar_armor_face = player_meta:get_string("avatar_armor_face")
        p_data.avatar_armor_chest = player_meta:get_string("avatar_armor_chest")
        p_data.avatar_armor_arms = player_meta:get_string("avatar_armor_arms")
        p_data.avatar_armor_legs = player_meta:get_string("avatar_armor_legs")
        p_data.avatar_armor_feet = player_meta:get_string("avatar_armor_feet")
        p_data.avatar_texture_armor = player_meta:get_string("avatar_texture_armor")
        p_data.foot_armor_texture = player_meta:get_string("foot_armor_texture")
        p_data.equipped_armor_head = player_meta:get_string("equipped_armor_head")
        p_data.equipped_armor_face = player_meta:get_string("equipped_armor_face")
        p_data.equipped_armor_chest = player_meta:get_string("equipped_armor_chest")
        p_data.equipped_armor_arms = player_meta:get_string("equipped_armor_arms")
        p_data.equipped_armor_legs = player_meta:get_string("equipped_armor_legs")
        p_data.equipped_armor_feet = player_meta:get_string("equipped_armor_feet")

        p_data.equip_buff_damage = player_meta:get_float("equip_buff_damage")
        p_data.equip_buff_cold = player_meta:get_float("equip_buff_cold")
        p_data.equip_buff_heat = player_meta:get_float("equip_buff_heat")
        p_data.equip_buff_wetness = player_meta:get_float("equip_buff_wetness")
        p_data.equip_buff_disease = player_meta:get_float("equip_buff_disease")
        p_data.equip_buff_radiation = player_meta:get_float("equip_buff_radiation")
        p_data.equip_buff_noise = player_meta:get_float("equip_buff_noise")
        p_data.equip_buff_weight = player_meta:get_float("equip_buff_weight")
        p_data.equip_buff_damage_prev = p_data.equip_buff_damage
        p_data.equip_buff_cold_prev = p_data.equip_buff_cold
        p_data.equip_buff_heat_prev = p_data.equip_buff_heat
        p_data.equip_buff_wetness_prev = p_data.equip_buff_wetness
        p_data.equip_buff_disease_prev = p_data.equip_buff_disease
        p_data.equip_buff_radiation_prev = p_data.equip_buff_radiation
        p_data.equip_buff_noise_prev = p_data.equip_buff_noise
        p_data.equip_buff_weight_prev = p_data.equip_buff_weight

        -- player stats
        p_data.fists_cooldown_time = player_meta:get_float("fists_cooldown_time")
        p_data.fists_attack_damage = player_meta:get_float("fists_attack_damage")
        p_data.cooldown_buff_fists = player_meta:get_float("cooldown_buff_fists")
        p_data.cooldown_buff_blunt = player_meta:get_float("cooldown_buff_blunt")
        p_data.cooldown_buff_blade = player_meta:get_float("cooldown_buff_blade")
        p_data.cooldown_buff_spear = player_meta:get_float("cooldown_buff_spear")
        p_data.cooldown_buff_mining = player_meta:get_float("cooldown_buff_mining")
        p_data.experience_gain_crafting = player_meta:get_float("experience_gain_crafting")
        p_data.experience_gain_cooking = player_meta:get_float("experience_gain_cooking")
        p_data.speed_walk = player_meta:get_float("speed_walk")
        p_data.height_jump = player_meta:get_float("height_jump")
        p_data.speed_buff_weight = player_meta:get_float("speed_buff_weight")
        p_data.jump_buff_weight = player_meta:get_float("jump_buff_weight")
        p_data.player_level = player_meta:get_int("player_level")
        p_data.player_skill_points = player_meta:get_int("player_skill_points")

        -- campfire related properties
		p_data.fire_drill_success_rate = player_meta:get_float("fire_drill_success_rate")
		p_data.match_book_success_rate = player_meta:get_float("match_book_success_rate")

        -- green, orange and red highlight color for text, recipe icons, icon bg status, tooltips and wear
        p_data.ui_green = player_meta:get_string("ui_green")
        p_data.ui_orange = player_meta:get_string("ui_orange")
        p_data.ui_red = player_meta:get_string("ui_red")
        p_data.ui_green_selected = player_meta:get_string("ui_green_selected")
        p_data.ui_orange_selected = player_meta:get_string("ui_orange_selected")
        p_data.ui_red_selected = player_meta:get_string("ui_red_selected")

        -- the last selected topic and subtopic from the '?' help tab
        p_data.help_topic = player_meta:get_string("help_topic")
        p_data.help_subtopic = player_meta:get_string("help_subtopic")

    end

    debug(flag1, "register_on_joinplayer() END")
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

    p_data.avatar_texture_clothes = ""
    player_meta:set_string("avatar_texture_clothes", p_data.avatar_texture_clothes)
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
    p_data.equip_buff_wetness = 0
    player_meta:set_float("equip_buff_wetness", p_data.equip_buff_wetness)
    p_data.equip_buff_disease = 0
    player_meta:set_float("equip_buff_disease", p_data.equip_buff_disease)
    p_data.equip_buff_radiation = 0
    player_meta:set_float("equip_buff_radiation", p_data.equip_buff_radiation)
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
	p_data.equip_buff_wetness_prev = 0
	p_data.equip_buff_disease_prev = 0
	p_data.equip_buff_radiation_prev = 0
	p_data.equip_buff_noise_prev = 0
	p_data.equip_buff_weight_prev = 0
	p_data.viewing_equipbuff_window = false

    debug(flag3, "register_on_dieplayer() END")
end)



-- Note: the respawnplayer() code is mostly a mirroring of the joinplayer() code
-- except for the parts relating to if plyer_status == 1. code relating to if
-- player_status == 2 is also incorporated where it does not already overlap with
-- player_status == 0
local flag5 = false
core.register_on_respawnplayer(function(player)
    debug(flag5, "\nregister_on_respawnplayer() global_variables_init.lua")
	local player_meta = player:get_meta()
	local player_name = player:get_player_name()
	local p_data = player_data[player_name]

    debug(flag5, "  reset movement and jump physics")
    p_data.speed_walk_current = 1
    p_data.jump_height_current = 1

    debug(flag5, "  reset speed buffs")
    p_data.speed_buff_crouch = 1
    p_data.speed_buff_run = 1
    p_data.speed_buff_exhaustion = 1
    p_data.speed_buff_crouch_default = 0.25
    p_data.speed_buff_run_default = 1.5

    debug(flag5, "  reset jump buffs")
    p_data.jump_buff_crouch = 1
    p_data.jump_buff_run = 1
    p_data.jump_buff_exhaustion = 1
    p_data.jump_buff_weight = 1
    p_data.jump_buff_crouch_default = 0.0
    p_data.jump_buff_run_default = 1.20

    debug(flag5, "  reset active tab and anim state")
    p_data.active_tab = "main"
    p_data.current_anim_state = "crouch"

    debug(flag5, "  reset equipbuff viewing flag and player vocalizing flag")
    p_data.viewing_equipbuff_window = false
    p_data.player_vocalizing = false

    -- ### not restting statbar preferences
    -- p_data.statbar_settings = {}
    -- p_data.stats_bg_opacity = "80"

    debug(flag5, "  reset player inventory properties")
    p_data.formspec_mode = "player_setup" -- player starts new character
    p_data.weight_max_per_slot = SLOT_WEIGHT_MAX
    player_meta:set_int("weight_max_per_slot", p_data.weight_max_per_slot)
    p_data.prev_iteminfo_item = ""
    player_meta:set_string("prev_iteminfo_item", p_data.prev_iteminfo_item)
    p_data.recipe_category = "tools"
    player_meta:set_string("recipe_category", p_data.recipe_category)
    p_data.prev_recipe_id = ""
    player_meta:set_string("prev_recipe_id", p_data.prev_recipe_id)
    p_data.slot_bonus_credit = 0
    player_meta:set_int("slot_bonus_credit", p_data.slot_bonus_credit)

    debug(flag5, "  reset noise events chances")
    p_data.noise_chance_choke = 10
    player_meta:set_float("noise_chance_choke", p_data.noise_chance_choke)
    p_data.noise_chance_sneeze_plants = 10
    player_meta:set_float("noise_chance_sneeze_plants", p_data.noise_chance_sneeze_plants)
    p_data.noise_chance_sneeze_dust = 10
    player_meta:set_float("noise_chance_sneeze_dust", p_data.noise_chance_sneeze_dust)
    p_data.noise_chance_hickups = 30
    player_meta:set_float("noise_chance_hickups", p_data.noise_chance_hickups)

    -- ### not restting player avatar mesh and body type preferences
    -- p_data.avatar_mesh = "ss_player_model_1.b3d"
    -- p_data.body_type = 1
    -- p_data.avatar_body_type_selected = "body_type1"

    -- ### not restting player avatar skin, hair, eyes, underwear, and face preferences

    -- ### not restting player avatar base texture
    -- p_data.avatar_texture_base

    debug(flag5, "  reset cooldown durations")
    p_data.fists_cooldown_time = 1.0
	player_meta:set_float("fists_cooldown_time", 1.0)
    p_data.fists_attack_damage = 1.5
	player_meta:set_float("fists_attack_damage", 1.5)
    p_data.cooldown_buff_fists = 0.1
	player_meta:set_float("cooldown_buff_fists", 0.1)
    p_data.cooldown_buff_blunt = 0.1
	player_meta:set_float("cooldown_buff_blunt", 0.1)
    p_data.cooldown_buff_blade = 0.1
	player_meta:set_float("cooldown_buff_blade", 0.1)
    p_data.cooldown_buff_spear = 0.1
	player_meta:set_float("cooldown_buff_spear", 0.1)
    p_data.cooldown_buff_mining = 0.1
	player_meta:set_float("cooldown_buff_mining", 0.1)

    debug(flag5, "  reset crafting and cooking xp gain rates")
    p_data.experience_gain_crafting = 0.5
	player_meta:set_float("experience_gain_crafting", 0.5)
    p_data.experience_gain_cooking = 0.5
	player_meta:set_float("experience_gain_cooking", 0.5)

    debug(flag5, "  reset player level and skill points")
    p_data.player_level = 1
	player_meta:set_int("player_level", 1)
    p_data.player_skill_points = 0
    player_meta:set_int("player_skill_points", 0)

    debug(flag5, "  reset 'current' movement and jump physics")
    p_data.speed_walk = 1.0
	player_meta:set_float("speed_walk", 1.0)
    p_data.height_jump = 1.0
	player_meta:set_float("height_jump", 1.0)

    debug(flag5, "  reset weight buffs on movement and jumping")
    p_data.speed_buff_weight = 1
	player_meta:set_float("speed_buff_weight", 1)
    p_data.jump_buff_weight = 1
	player_meta:set_float("jump_buff_weight", 1)

    debug(flag5, "  reset fire starter tools success rates")
	p_data.fire_drill_success_rate = 0.50
	player_meta:set_float("fire_drill_success_rate", p_data.fire_drill_success_rate)
	p_data.match_book_success_rate = 0.80
	player_meta:set_float("match_book_success_rate", p_data.match_book_success_rate)

    -- ### not resetting UI highlight color preferences

    -- ### not resetting Help tab selected topic and subtopic
    --p_data.help_topic = ""
    --p_data.help_subtopic = ""

    debug(flag5, "  reset job_handles and is_cooldown_active global tables")
    job_handles[player_name] = {}
    is_cooldown_active[player_name] = {}

	debug(flag5, "register_on_respawnplayer() END")
end)



-- #### initializing tables: ITEM_DISPLAY_NAME, ITEM_DESCRIPTOR, ITEM_TOOLTIP,
-- ITEM_CATEGORY, ITEM_DESC_SHORT, ITEM_DESC_LONG

local flag2 = false
debug(flag2, "importing data from item_data.txt ..")
local file_path = mt_get_modpath("ss") .. "/item_data.txt"
local file = io.open(file_path, "r")
if not file then
	debug(flag2, "  Could not open file: " .. file_path)
	return
end

local dataline_1_read = false
local dataline_2_read = false
local dataline_3_read = false
local dataline_4_read = false
local dataline_5_read = false
local item_name, texture_inv
local display_name, descriptor, type, category, group
local inv_sound, miss_sound, hit_sound, consume_sound, break_sound
local weight, fuel_burn_time, cook_time, value, hit_damage, hit_cooldown_time, hit_type, pointing_range
local item_tooltip
local description_short

for line in file:lines() do
    debug(flag2, "  line: " .. line)
	-- Trim whitespace from the line
	line = line:match("^%s*(.-)%s*$")
	-- Skip blank lines and lines that start with '#'
    if line == "" then
        debug(flag2, "    blank line")
        dataline_1_read = false
        dataline_2_read = false
        dataline_3_read = false
        dataline_4_read = false
        dataline_5_read = false
    elseif line:sub(1, 1) == "#" then
        debug(flag2, "    comment line")
        dataline_1_read = false
        dataline_2_read = false
        dataline_3_read = false
        dataline_4_read = false
        dataline_5_read = false
    else
        debug(flag2, "    valid data line")
        if dataline_1_read then
            if dataline_2_read then
                if dataline_3_read then
                    if dataline_4_read then
                        if dataline_5_read then
                            debug(flag2, "    found data line 6")

                            display_name = display_name or "(no display name)"
                            ss.ITEM_DISPLAY_NAME[item_name] = display_name

                            if descriptor == "" then
                                item_tooltip = display_name
                            else
                                ss.ITEM_DESCRIPTOR[item_name] = descriptor
                                item_tooltip = display_name .. " (" .. descriptor .. ")"
                            end
                            ss.ITEM_TOOLTIP[item_name] = item_tooltip

                            ss.ITEM_CATEGORY[item_name] = category

                            if group ~= "" then
                                debug(flag2, "    group: " .. group)
                                if ss.GROUP_ITEMS[group] == nil then
                                    ss.GROUP_ITEMS[group] = {}
                                end
                                table_insert(ss.GROUP_ITEMS[group], item_name)
                                ss.ITEM_GROUPS[item_name] = group
                            end

                            if inv_sound ~= "" then
                                ss.ITEM_SOUNDS_INV[item_name] = inv_sound
                            end

                            if miss_sound ~= "" then
                                ss.ITEM_SOUNDS_MISS[item_name] = miss_sound
                            end

                            if hit_sound ~= "" then
                                ss.ITEM_SOUNDS_HIT[item_name] = inv_sound
                            end
                            if consume_sound ~= "" then
                                ss.ITEM_SOUNDS_USE[item_name] = consume_sound
                            end
                            if break_sound ~= "" then
                                ss.ITEM_SOUNDS_BREAK[item_name] = break_sound
                            end

                            local final_weight = tonumber(weight)
                            ss.ITEM_WEIGHTS[item_name] = final_weight

                            local max_count = math_floor(ss.SLOT_WEIGHT_MAX / final_weight)
                            if max_count > 99 then max_count = 99 end
                            ss.STACK_MAX_COUNTS[item_name] = max_count

                            ss.ITEM_BURN_TIMES[item_name] = tonumber(fuel_burn_time)

                            cook_time = tonumber(cook_time)
                            if cook_time > 0 then
                                ss.ITEM_HEAT_RATES[item_name] = math_floor(ss.COOK_THRESHOLD / cook_time)
                            else
                                ss.ITEM_HEAT_RATES[item_name] = 0
                            end
                            ss.ITEM_VALUES[item_name] = tonumber(value)
                            ss.ITEM_HIT_DAMAGES[item_name] = tonumber(hit_damage)
                            ss.ITEM_HIT_COOLDOWNS[item_name] = tonumber(hit_cooldown_time)
                            ss.ITEM_HIT_TYPES[item_name] = hit_type

                            if pointing_range == "" then
                                ss.ITEM_POINTING_RANGES[item_name] = POINTING_RANGE_DEFAULT
                                pointing_range = POINTING_RANGE_DEFAULT
                            else
                                ss.ITEM_POINTING_RANGES[item_name] = tonumber(pointing_range)
                                pointing_range = tonumber(pointing_range)
                            end

                            ss.ITEM_DESC_SHORT[item_name] = description_short
                            ss.ITEM_DESC_LONG[item_name] = mt_wrap_text(line, 70)

                            local name_tokens = string_split(item_name, ":", true)
                            local type_tokens = string_split(type, ":")

                            if name_tokens[1] == "default" then
                                debug(flag2, "    this is a 'default' mod item. no need to register it.")
                            elseif name_tokens[1] == "stairs" then
                                debug(flag2, "    this is a 'stairs' mod item. no need to register it.")
                            elseif name_tokens[1] == "flowers" then
                                debug(flag2, "    this is a 'flowers' mod item. no need to register it.")
                            elseif name_tokens[1] == "farming" then
                                debug(flag2, "    this is a 'farming' mod item. no need to register it.")

                            elseif type_tokens[1] == "clothes" then
                                debug(flag2, "    this is clothing that can be colored")
                                local clothing_name = string_sub(item_name, 12)
                                debug(flag2, "    clothing_name: " .. clothing_name)
                                texture_inv = table_concat({
                                    "ss_clothes_", clothing_name, ".png",
                                    "^[colorizehsl:", CLOTHING_COLORS[clothing_name][1],
                                    "^[contrast:", CLOTHING_CONTRASTS[clothing_name][1],
                                    "^[mask:ss_clothes_", clothing_name, "_mask.png"
                                })
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            elseif type_tokens[1] == "armor" then
                                debug(flag2, "    this is armor that can be colored")
                                local armor_name = string_sub(item_name, 10)
                                debug(flag2, "    armor_name: " .. armor_name)
                                texture_inv = table_concat({
                                    "ss_armor_", armor_name, ".png",
                                    "^[colorizehsl:", ARMOR_COLORS[armor_name][1],
                                    "^[contrast:", ARMOR_CONTRASTS[armor_name][1],
                                    "^[mask:ss_armor_", armor_name, "_mask.png"
                                })
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            elseif type_tokens[1] == "craftitem" then
                                debug(flag2, "    this is a craftitem")
                                mt_register_craftitem(item_name, {
                                    description = item_tooltip,
                                    inventory_image = texture_inv .. ".png",
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                })

                            -- only applies to 'ss:' tools
                            elseif type_tokens[1] == "tool" then
                                debug(flag2, "    this is a tool")
                                mt_register_tool(item_name, {
                                        description = item_tooltip,
                                        inventory_image = texture_inv .. ".png",
                                        range = pointing_range,
                                        sound = {
                                            punch_use_air = miss_sound
                                        }
                                    })

                            -- only applies to 'ss:' nodes
                            elseif type_tokens[1] == "node" then
                                debug(flag2, "    this is a node")

                                local node_type = type_tokens[2]
                                debug(flag2, "    node_type: " .. node_type)

                                local walkable
                                local buildable_to

                                if node_type == "solid" then
                                    walkable = true
                                    buildable_to = false
                                elseif node_type == "solid_variable" then
                                    walkable = true
                                    buildable_to = true
                                elseif node_type == "nonsolid_dig" then
                                    walkable = false
                                    buildable_to = true
                                elseif node_type == "nonsolid_nodig" then
                                    walkable = false
                                    buildable_to = false
                                elseif node_type == "gappy_dig" then
                                    walkable = true
                                    buildable_to = true
                                elseif node_type == "gappy_nodig" then
                                    walkable = true
                                    buildable_to = false
                                else
                                    debug(flag2, "    ERROR - Unexpected 'node_type' value: " .. node_type)
                                end

                                local node_def = {
                                    description = item_tooltip,
                                    inventory_image = texture_inv .. ".png",
                                    walkable = walkable,
                                    buildable_to = buildable_to,
                                    range = pointing_range,
                                    sound = {
                                        punch_use_air = miss_sound
                                    }
                                }
                                mt_register_node(item_name, node_def)
                                debug(flag2, "    node_def: " .. dump(node_def))

                            else
                                debug(flag2, "    ERROR - Unexpected 'type' value: " .. type)
                            end

                            dataline_1_read = false
                            dataline_2_read = false
                            dataline_3_read = false
                            dataline_4_read = false
                            dataline_5_read = false
                        else
                            debug(flag2, "    found data line 5")
                            description_short = line
                            dataline_5_read = true
                        end
                    else
                        debug(flag2, "    found data line 4")
                        local tokens = string_split(line, ",", true)
                        debug(flag2, "    dataline_tokens: " .. dump(tokens))
                        weight = tokens[1]
                        fuel_burn_time = tokens[2]
                        cook_time = tokens[3]
                        value = tokens[4]
                        hit_damage = tokens[5]
                        hit_cooldown_time = tokens[6]
                        hit_type = tokens[7]
                        pointing_range = tokens[8]
                        dataline_4_read = true
                    end
                else
                    debug(flag2, "    found data line 3")
                    local tokens = string_split(line, ",", true)
                    debug(flag2, "    dataline_tokens: " .. dump(tokens))
                    inv_sound = tokens[1]
                    miss_sound = tokens[2]
                    hit_sound = tokens[3]
                    consume_sound = tokens[4]
                    break_sound = tokens[5]
                    dataline_3_read = true
                end
            else
                debug(flag2, "    found data line 2")
                local tokens = string_split(line, ",", true)
                debug(flag2, "    dataline_tokens: " .. dump(tokens))
                display_name = tokens[1]
                descriptor = tokens[2]
                type = tokens[3]
                category = tokens[4]
                group = tokens[5]
                dataline_2_read = true
            end
        else
            debug(flag2, "      found data line 1")
            local tokens = string_split(line, ",", true)
            debug(flag2, "    tokens: " .. dump(tokens))
            item_name = tokens[1]
            texture_inv = tokens[2]
            dataline_1_read = true
        end
    end
end
file:close()
local flag2b = true
--debug(flag2b, "  ITEM_DISPLAY_NAME[]: " .. dump(ss.ITEM_DISPLAY_NAME))
--debug(flag2b, "  ITEM_DESCRIPTOR[]: " .. dump(ss.ITEM_DESCRIPTOR))
--debug(flag2b, "  ITEM_TOOLTIP[]: " .. dump(ss.ITEM_TOOLTIP))
--debug(flag2b, "  ITEM_CATEGORY[]: " .. dump(ss.ITEM_CATEGORY))
--debug(flag2b, "  ITEM_GROUPS: " .. dump(ss.ITEM_GROUPS))
--debug(flag2b, "  GROUP_ITEMS: " .. dump(ss.GROUP_ITEMS))
--debug(flag2b, "  ITEM_SOUNDS_INV[]: " .. dump(ss.ITEM_SOUNDS_INV))
--debug(flag2b, "  ITEM_SOUNDS_MISS[]: " .. dump(ss.ITEM_SOUNDS_MISS))
--debug(flag2b, "  ITEM_SOUNDS_HIT[]: " .. dump(ss.ITEM_SOUNDS_HIT))
--debug(flag2b, "  ITEM_SOUNDS_USE[]: " .. dump(ss.ITEM_SOUNDS_USE))
--debug(flag2b, "  ITEM_SOUNDS_BREAK[]: " .. dump(ss.ITEM_SOUNDS_BREAK))
--debug(flag2b, "  ITEM_WEIGHTS[]: " .. dump(ss.ITEM_WEIGHTS))
--debug(flag2b, "  STACK_MAX_COUNTS: " .. dump(ss.STACK_MAX_COUNTS))
--debug(flag2b, "  ITEM_BURN_TIMES[]: " .. dump(ss.ITEM_BURN_TIMES))
--debug(flag2b, "  ITEM_HEAT_RATES[]: " .. dump(ss.ITEM_HEAT_RATES))
--debug(flag2b, "  ITEM_VALUES[]: " .. dump(ss.ITEM_VALUES))
--debug(flag2b, "  ITEM_HIT_DAMAGES[]: " .. dump(ss.ITEM_HIT_DAMAGES))
--debug(flag2b, "  ITEM_HIT_COOLDOWNS[]: " .. dump(ss.ITEM_HIT_COOLDOWNS))
--debug(flag2b, "  ITEM_HIT_TYPES[]: " .. dump(ss.ITEM_HIT_TYPES))
--debug(flag2b, "  ITEM_POINTING_RANGES[]: " .. dump(ss.ITEM_POINTING_RANGES))
--debug(flag2b, "  ITEM_DESC_SHORT[]: " .. dump(ss.ITEM_DESC_SHORT))
--debug(flag2b, "  ITEM_DESC_LONG[]: " .. dump(ss.ITEM_DESC_LONG))



-- #### initialize ss.NODE_DROPS_FLATTENED

local flag4 = false
debug(flag4, "populating FLATTENED_NODE_DROPS table..")
file_path = mt_get_modpath("ss") .. "/node_drops_flattened.txt"
file = io.open(file_path, "r")
if not file then
	debug(flag4, "  Could not open file: " .. file_path)
	return
end
for line in file:lines() do
	-- Trim whitespace from the line
	line = line:match("^%s*(.-)%s*$")
	-- Skip blank lines and lines that start with '#'
	if line ~= "" and line:sub(1, 1) ~= "#" then
		local line_tokens = string_split(line)
		local item_name_ = line_tokens[1]
		debug(flag4, "  item_name_: " .. item_name_)
		local item_drop
		if line_tokens[2] then
			item_drop = ItemStack(line_tokens[2])
		else
			item_drop = ItemStack("")
		end
		ss.NODE_DROPS_FLATTENED[item_name_] = ItemStack(item_drop)
	end
end
file:close()
debug(flag4, "  NODE_DROPS_FLATTENED[]: " .. dump(ss.NODE_DROPS_FLATTENED))


>>>>>>> 7965987 (update to version 0.0.3)
