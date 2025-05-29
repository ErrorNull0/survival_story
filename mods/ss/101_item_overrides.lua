print("- loading item_overrides.lua")

-- cache global functions and tables for faster access
local debug = ss.debug
local notify = ss.notify

local ITEM_MAX_USES = ss.ITEM_MAX_USES


local function custom_on_secondary_use(itemstack, user, pointed_thing)
    local item_meta = itemstack:get_meta()
    local remaining_uses = item_meta:get_int("remaining_uses")
	local text = "remaining uses  " .. core.get_color_escape_sequence("yellow") .. remaining_uses
    notify(user, "remaining_uses", text, 1, 0.5, 0, 2)
end



local flag1 = false
debug(flag1, "OVERRIDING on_secondary_use() for consumable items..")
for consumable_item in pairs(ITEM_MAX_USES) do
	debug(flag1, "  consumable_item: " .. consumable_item)
	core.override_item(consumable_item, {
        on_secondary_use = custom_on_secondary_use
    })
end


-- An invisible item for use by ss:wield_item entity from 'wield_item.lua' when
-- player not wielding anything.
core.override_item("ss:transparent_item", {
    wield_scale = {x = 1, y = 1, z = 1}
})


core.override_item("ss:item_bundle", {
    stack_max = 1
})