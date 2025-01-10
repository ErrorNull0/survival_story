print("- loading init.lua")

dofile(minetest.get_modpath("ss") .. "/001_global_variables.lua")
dofile(minetest.get_modpath("ss") .. "/002_global_vars_init.lua")
dofile(minetest.get_modpath("ss") .. "/003_global_functions.lua")
dofile(minetest.get_modpath("ss") .. "/010_api_overrides.lua")

dofile(minetest.get_modpath("ss") .. "/101_item_overrides.lua")
dofile(minetest.get_modpath("ss") .. "/102_tool_overrides.lua")
dofile(minetest.get_modpath("ss") .. "/103_node_overrides.lua")
dofile(minetest.get_modpath("ss") .. "/131_node_drop_overrides.lua")
dofile(minetest.get_modpath("ss") .. "/132_node_group_overrides.lua")
dofile(minetest.get_modpath("ss") .. "/150_decorations.lua")
dofile(minetest.get_modpath("ss") .. "/190_global_tables.lua")

dofile(minetest.get_modpath("ss") .. "/200_notifications.lua")
dofile(minetest.get_modpath("ss") .. "/210_wield_item.lua")
dofile(minetest.get_modpath("ss") .. "/240_noise_events.lua")

dofile(minetest.get_modpath("ss") .. "/300_recipes.lua")
dofile(minetest.get_modpath("ss") .. "/330_item_consumption.lua")
dofile(minetest.get_modpath("ss") .. "/350_itemdrop_bag.lua")

dofile(minetest.get_modpath("ss") .. "/400_storage_containers.lua")
dofile(minetest.get_modpath("ss") .. "/401_food_containers.lua")
dofile(minetest.get_modpath("ss") .. "/410_cooking_stations.lua")

dofile(minetest.get_modpath("ss") .. "/500_clothing.lua")
dofile(minetest.get_modpath("ss") .. "/510_armor.lua")
dofile(minetest.get_modpath("ss") .. "/520_equipment_buffs.lua")
dofile(minetest.get_modpath("ss") .. "/550_timekeeping.lua")
dofile(minetest.get_modpath("ss") .. "/570_survival_tips.lua")

dofile(minetest.get_modpath("ss") .. "/600_inventory.lua")
dofile(minetest.get_modpath("ss") .. "/602_bundle.lua")
dofile(minetest.get_modpath("ss") .. "/650_skills.lua")
dofile(minetest.get_modpath("ss") .. "/660_settings.lua")
dofile(minetest.get_modpath("ss") .. "/690_help.lua")
dofile(minetest.get_modpath("ss") .. "/691_about.lua")

dofile(minetest.get_modpath("ss") .. "/700_stats.lua")
dofile(minetest.get_modpath("ss") .. "/720_player_anim.lua")

-- work on this later
--dofile(minetest.get_modpath("ss") .. "/800_mobs.lua")

dofile(minetest.get_modpath("ss") .. "/950_player_setup.lua")
dofile(minetest.get_modpath("ss") .. "/970_player_death.lua")
dofile(minetest.get_modpath("ss") .. "/980_other_callbacks.lua")
dofile(minetest.get_modpath("ss") .. "/985_admin_items.lua")
dofile(minetest.get_modpath("ss") .. "/990_startup_items.lua")

dofile(minetest.get_modpath("ss") .. "/999_execute_last.lua")


