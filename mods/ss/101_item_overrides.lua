print("- loading item_overrides.lua")

-- cache global functions and tables for faster access
local debug = ss.debug
local notify = ss.notify

local ITEM_MAX_USES = ss.ITEM_MAX_USES
local mt_registered_nodes = minetest.registered_nodes


--[[ override the pointing range of all items recently defined in ITEM_POINTING_RANGES
table above to be more realistic based on length of each item. note: ITEM_POINTING_RANGES
table includes all items in the game that can be interacted with inside the player
inventory, like craft items, tools, and nodes like plants, gappy nodes, BUT NOT
solid dirt, wood, stone type nodes, since in survival story, player will never have
them in their inventory. those items (especially nodes) that were not included in
ITEM_POINTING_RANGES table simply get a non-functional range of 0.1 assigned.
local flag3 = false
for item_name_ in pairs(mt_registered_nodes) do
	debug(flag3, "  itme_name: " .. item_name_)
	local pointing_range_ = 0.1
	if item_name_ == "" then
		pointing_range_ = 1.4  -- fists
	else
		if ss.ITEM_POINTING_RANGES[item_name_] then
			pointing_range_ = ss.ITEM_POINTING_RANGES[item_name_]
		end
	end
	minetest.override_item(item_name_, {range = pointing_range_})
	debug(flag3, "    new pointing_range_: " .. pointing_range_)
end
--]]

local function custom_on_secondary_use(itemstack, user, pointed_thing)
    local item_meta = itemstack:get_meta()
    local remaining_uses = item_meta:get_int("remaining_uses")
	local text = "remaining uses " .. minetest.get_color_escape_sequence("yellow") .. remaining_uses
    notify(user, text, 2, "message_box_2")
end



local flag1 = false
debug(flag1, "OVERRIDING on_secondary_use() for consumable items..")
for consumable_item in pairs(ITEM_MAX_USES) do
	debug(flag1, "  consumable_item: " .. consumable_item)
	minetest.override_item(consumable_item, {
        on_secondary_use = custom_on_secondary_use
    })
end


-- An invisible item for use by ss:wield_item entity from 'wield_item.lua' when
-- player not wielding anything.
minetest.override_item("ss:transparent_item", {
    wield_scale = {x = 1, y = 1, z = 1}
})


minetest.override_item("ss:item_bundle", {
    stack_max = 1
})