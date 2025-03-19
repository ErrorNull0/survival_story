print("- loading bundle.lua")

-- cache global functions for faster access
local math_random = math.random
local string_sub = string.sub
local table_concat = table.concat
local mt_serialize = core.serialize
local mt_show_formspec = core.show_formspec
local mt_get_gametime = core.get_gametime
local mt_after = core.after
local mt_add_item = core.add_item
local debug = ss.debug
local round = ss.round
local notify = ss.notify
local play_sound = ss.play_sound
local build_fs = ss.build_fs
local get_itemstack_weight = ss.get_itemstack_weight
local get_fs_weight = ss.get_fs_weight
local update_stat = ss.update_stat
local get_item_burn_time = ss.get_item_burn_time

-- cache global variables for faster access
local SLOT_COLOR_BG = ss.SLOT_COLOR_BG
local SLOT_COLOR_HOVER = ss.SLOT_COLOR_HOVER
local SLOT_COLOR_BORDER = ss.SLOT_COLOR_BORDER
local TOOLTIP_COLOR_BG = ss.TOOLTIP_COLOR_BG
local TOOLTIP_COLOR_TEXT = ss.TOOLTIP_COLOR_TEXT
local CRAFTITEM_ICON = ss.CRAFTITEM_ICON
local ITEM_TOOLTIP = ss.ITEM_TOOLTIP
local NOTIFY_DURATION = ss.NOTIFY_DURATION
local NOTIFICATIONS = ss.NOTIFICATIONS
local SPILLABLE_ITEM_NAMES = ss.SPILLABLE_ITEM_NAMES
local STACK_MAX_COUNTS = ss.STACK_MAX_COUNTS
local ITEM_WEIGHTS = ss.ITEM_WEIGHTS
local ITEM_VALUES = ss.ITEM_VALUES
local ITEM_HIT_DAMAGES = ss.ITEM_HIT_DAMAGES
local ITEM_POINTING_RANGES = ss.ITEM_POINTING_RANGES
local ITEM_HIT_COOLDOWNS = ss.ITEM_HIT_COOLDOWNS
local HIT_COOLDOWN_MAX = ss.HIT_COOLDOWN_MAX
local player_data = ss.player_data


local flag6 = false
local function reset_bundle_grid(player, p_data)
    debug(flag6, "  reset_bundle_grid() bundle.lua")
    local player_inv = player:get_inventory()
    local bundle_grid_slots = player_inv:get_list("bundle_grid")
    --debug(flag6, "    bundle_grid_slots: " .. dump(bundle_grid_slots))
    local item = bundle_grid_slots[1]
    local stack_max = STACK_MAX_COUNTS[item:get_name()]
    if stack_max > 60 then stack_max = 60 end

    debug(flag6, "    checking bundle grid slots...")
    local dropped_item_count = 0
    for i = 1, stack_max do
        local bundle_item = bundle_grid_slots[i]
        if not bundle_item:is_empty() then
            debug(flag6, "      slot #" .. i .. " item name: " .. bundle_item:get_name())
            if player_inv:room_for_item("main", bundle_item) then
                player_inv:add_item("main", bundle_item)
                debug(flag6, "      moved back to main inv OK")
            else
                debug(flag6, "      no space in main inv. dropping to ground..")
                mt_add_item(player:get_pos(), bundle_item)
                dropped_item_count = dropped_item_count + 1
            end
            player_inv:set_stack("bundle_grid", i, ItemStack(""))
        end
    end
    if dropped_item_count > 0 then
        notify(player, dropped_item_count .. " items from bundle attempt dropped to the ground", 4, 0.5, 0, 2)
    else
        notify(player, "Items from bundle attempt returned to invenory", 4, 0.5, 0, 2)
    end

    p_data.bundle_status = "inactive"
    p_data.bundle_item_count = 0
    p_data.bundle_item_name = ""
    debug(flag6, "  reset_bundle_grid() END")
end


local flag7 = false
local function reset_bundle_slot(player)
    debug(flag7, "  reset_bundle_slot() bundle.lua")
    local player_inv = player:get_inventory()
    if player_inv:is_empty("bundle_slot") then
        debug(flag7, "    no item in bundle slot. NO FURTHER ACTION.")
    else
        debug(flag7, "    item in bundle slot. removing item..")
        local bundle_item = player_inv:get_stack("bundle_slot", 1)
        if player_inv:room_for_item("main", bundle_item) then
            debug(flag7, "    item bundle returned to main inv")
            player_inv:add_item("main", bundle_item)
        else
            debug(flag7, "    no space in main inv")
            mt_add_item(player:get_pos(), bundle_item)
            notify(player, "Item bundle dropped to the ground", NOTIFY_DURATION, 0.5, 0, 2)
        end
        player_inv:set_stack("bundle_slot", 1, ItemStack(""))
    end
    debug(flag7, "  reset_bundle_slot() END")
end


local flag8 = false
local function cancel_view_bundle(player, p_data)
    debug(flag8, "  cancel_view_bundle() bundle.lua")
        local player_inv = player:get_inventory()

        -- remove all items from bundle grid
        player_inv:set_list("bundle_grid", {})

        -- take bundle item that was still in the bundle slot and place back
        -- into the main invenory
        local bundle_item = player_inv:get_stack("bundle_slot", 1)
        if player_inv:room_for_item("main", bundle_item) then
            player_inv:add_item("main", bundle_item)
            notify(player, "Item bundle returned to inventory", 3, 0.5, 0, 2)
        else
            debug(flag8, "      no space in main inv")
            mt_add_item(player:get_pos(), bundle_item)
            notify(player, "Item bundle dropped to the ground", 3, 0.5, 0, 2)
        end

        -- remove the bundle item from the bundle slot
        player_inv:set_stack("bundle_slot", 1, ItemStack(""))

        -- reset bundle status and properties
        p_data.bundle_status = "inactive"
        p_data.bundle_item_count = 0
        p_data.bundle_item_name = ""

    debug(flag8, "  cancel_view_bundle() END")
end


local flag5 = false
local function get_fs_tab_bundle(player_inv, p_data, player_meta, item_name)
    debug(flag5, "  get_fs_tab_bundle() bundle.lua")
    local x_pos = 0.5

    local bundle_status = p_data.bundle_status
    debug(flag5, "    action: " .. bundle_status)
    local bundle_slot_elements
    local bundle_item_count_elements = ""
    local clear_button_element = ""
    local save_button_element = ""
    if bundle_status == "inactive" then
        debug(flag5, "    initial display of bundle formspec")

        -- remove item from the the leftside bundle slot
        bundle_slot_elements = table_concat({
            "box[", x_pos, ",1.2;1,1;#000000]",
            "list[current_player;bundle_slot;", x_pos, ",1.2;1,1]",
            "tooltip[", x_pos, ",1.2;1,1;Item bundle slot]",
            "button[2.2,1.2;2.6,1;bundle_open;Open Bundle]"
        })
        save_button_element = "button[10.6,1.2;2.7,1;bundle_save;Save Bundle]"

        player_inv:set_size("bundle_grid", 1)

    elseif bundle_status == "creating_new" then
        debug(flag5, "    starting item bundle process")
        local stack_max = STACK_MAX_COUNTS[item_name]
        if stack_max > 60 then stack_max = 60 end

        local bundle_slot_icon_element
        if p_data.bundle_item_image == "" then
            bundle_slot_icon_element = table_concat({
                "item_image[", x_pos, ",0.9;1.5,1.5;", item_name, "]"
            })
        else
            debug(flag5, "    this item has custom colorization metadata")
            debug(flag5, "      bundle_item_image: " .. p_data.bundle_item_image)
            bundle_slot_icon_element = table_concat({
                "image[", x_pos, ",0.9;1.5,1.5;", p_data.bundle_item_image, ";]"
            })
        end

        -- set the leftside bundle slot to an item image that reflects the
        -- item placed into the rightside bundle grid slot
        bundle_slot_elements = table_concat({
            "box[", x_pos, ",0.9;1.5,1.5;#000000]",
            bundle_slot_icon_element,
            "hypertext[", x_pos + 1.0, ",2.0;1,1;bundle_item_count;",
                "<b><style color=#BBBBBB size=18>x", p_data.bundle_item_count, "</style>]",

            "hypertext[", x_pos + 1.8, ",1.2;4,1;bundle_text_creating;",
                "<b><style color=#888888 size=16><b>* Creating bundle *</b></style>]",
            "hypertext[", x_pos + 1.9, ",1.8;7,1.5;bundle_item_description;",
                "<b><style color=#BBBBBB size=20><b>", ITEM_TOOLTIP[item_name], "</b></style>]"
        })

        bundle_item_count_elements = table_concat({
            "hypertext[10.6,9.65;4.0,2;bundle_item_count;<b>",
                "<style color=#666666 size=16> bundle size: </style>",
                "<style color=#999999 size=16> ", p_data.bundle_item_count, "</style>",
                "<style color=#666666 size=16> / ", stack_max, "</style>",
            "</b>]"
        })

        save_button_element = "button[10.6,1.2;2.7,1;bundle_save;Save Bundle]"
        clear_button_element = "button[13.9,1.2;2.7,1;bundle_clear;Cancel Bundle]"

        -- set the number of bundle grid slots to the item's stack count max
        player_inv:set_size("bundle_grid", stack_max)

    elseif bundle_status == "update_existing" then
        debug(flag5, "    updating existing bundle")

        -- remove the item from the bundle slot. this action was not done during
        -- 'view_bundle' status, so that the item can be recalled and put back
        -- into main inv if player exits the window
        player_inv:set_stack("bundle_slot", 1, ItemStack(""))

        local stack_max = STACK_MAX_COUNTS[item_name]
        if stack_max > 60 then stack_max = 60 end

        -- construct bundle slot icon image
        local bundle_slot_icon_element
        if p_data.bundle_item_image == "" then
            bundle_slot_icon_element = table_concat({
                "item_image[", x_pos, ",0.9;1.5,1.5;", item_name, "]"
            })
        else
            debug(flag5, "    this item has custom colorization metadata")
            bundle_slot_icon_element = table_concat({
                "image[", x_pos, ",0.9;1.5,1.5;", p_data.bundle_item_image, ";]"
            })
        end

        -- construct all other elements relating to the bundle icon like the bundle
        -- stack count, bundle status, and the primary item's name
        bundle_slot_elements = table_concat({
            "box[", x_pos, ",0.9;1.5,1.5;#000000]",
            bundle_slot_icon_element,
            "hypertext[", x_pos + 1.0, ",2.0;1,1;bundle_item_count;",
                "<b><style color=#BBBBBB size=18>x", p_data.bundle_item_count, "</style>]",
            "hypertext[", x_pos + 1.8, ",1.2;4,1;bundle_text_creating;",
                "<b><style color=#888888 size=16><b>* Updating bundle *</b></style>]",
            "hypertext[", x_pos + 1.9, ",1.8;7,1.5;bundle_item_description;",
                "<b><style color=#BBBBBB size=20><b>", ITEM_TOOLTIP[item_name], "</b></style>]"
        })

        -- construct the bundle count display
        bundle_item_count_elements = table_concat({
            "hypertext[10.6,9.65;4.0,2;bundle_item_count;<b>",
                "<style color=#666666 size=16> bundle size: </style>",
                "<style color=#999999 size=16> ", p_data.bundle_item_count, "</style>",
                "<style color=#666666 size=16> / ", stack_max, "</style>",
            "</b>]"
        })

        save_button_element = "button[10.6,1.2;2.7,1;bundle_save;Save Bundle]"
        clear_button_element = "button[13.9,1.2;2.7,1;bundle_clear;Take All]"

        -- set the number of bundle grid slots to the item's stack count max
        player_inv:set_size("bundle_grid", stack_max)

    elseif bundle_status == "view_bundle" then
        debug(flag5, "    dislay existing item bundle contents")

        local bundle_item = player_inv:get_stack("bundle_slot", 1)
        local bundle_item_meta = bundle_item:get_meta()
        local bundle_item_name = bundle_item_meta:get_string("bundle_item_name")
        local bundle_item_count = bundle_item_meta:get_int("bundle_item_count")

        -- initialize the number of bundle grid slots
        local stack_max = STACK_MAX_COUNTS[bundle_item_name]
        if stack_max > 60 then stack_max = 60 end
        player_inv:set_size("bundle_grid", stack_max)

        -- retrieve all bundled items and place them into the bundle grid
        local bundle_keys = bundle_item_meta:get_keys()
        debug(flag5, "    bundle_keys: " .. dump(bundle_keys))
        for i, bundle_key in ipairs(bundle_keys) do
            debug(flag5, "    bundle_key: " .. bundle_key)
            if string_sub(bundle_key, 1, 12) == "bundle_item_" then
                debug(flag5, "      this might be a bundle item")
                local bundle_index = tonumber(string_sub(bundle_key, 13))
                if bundle_index then
                    debug(flag5, "      is a bundle item")
                    local itemstring = bundle_item_meta:get_string(bundle_key)
                    debug(flag5, "      itemstring: " .. itemstring)
                    local item = ItemStack(itemstring)
                    player_inv:set_stack("bundle_grid", bundle_index, item)
                else
                    debug(flag5, "      not a bundle item")
                end
            else
                debug(flag5, "      not a bundle item")
            end
        end
        debug(flag5, "    bundle_grid list: " .. dump(player_inv:get_list("bundle_grid")))

        -- remove the item from the bundle slot
        --player_inv:set_stack("bundle_slot", 1, ItemStack(""))

        local primary_item = player_inv:get_stack("bundle_grid", 1)
        local primary_item_meta = primary_item:get_meta()
        local primary_item_icon = primary_item_meta:get_string("inventory_image")

        -- construct bundle slot icon image
        local bundle_slot_icon_element
        if primary_item_icon == "" then
            debug(flag5, "    no custom colorization metadata")
            bundle_slot_icon_element = table_concat({
                "item_image[", x_pos, ",0.9;1.5,1.5;", primary_item:get_name(), "]"
            })
        else
            debug(flag5, "    custom colorization metadata exists")
            bundle_slot_icon_element = table_concat({
                "image[", x_pos, ",0.9;1.5,1.5;", primary_item_icon, ";]"
            })
        end

        -- construct all other elements relating to the bundle icon like the bundle
        -- stack count, bundle status, and the primary item's name
        bundle_slot_elements = table_concat({
            "box[", x_pos, ",0.9;1.5,1.5;#000000]",
            bundle_slot_icon_element,
            "hypertext[", x_pos + 1.0, ",2.0;1,1;bundle_item_count;",
                "<b><style color=#BBBBBB size=18>x", bundle_item_count, "</style>]",
            "hypertext[", x_pos + 1.8, ",1.2;4,1;bundle_text_creating;",
                "<b><style color=#888888 size=16><b>* Viewing bundle *</b></style>]",
            "hypertext[", x_pos + 1.9, ",1.8;7,1.5;bundle_item_description;",
                "<b><style color=#BBBBBB size=20><b>", ITEM_TOOLTIP[bundle_item_name], "</b></style>]"
        })

        -- construct the bundle count display
        bundle_item_count_elements = table_concat({
            "hypertext[10.6,9.65;4.0,2;bundle_item_count;<b>",
                "<style color=#666666 size=16> bundle size: </style>",
                "<style color=#999999 size=16> ", bundle_item_count, "</style>",
                "<style color=#666666 size=16> / ", stack_max, "</style>",
            "</b>]"
        })

        save_button_element = "button[10.6,1.2;2.7,1;bundle_close;Close Bundle]"
        clear_button_element = "button[13.9,1.2;2.7,1;bundle_clear;Take All]"

        p_data.bundle_status = "view_bundle"
        p_data.bundle_item_count = bundle_item_count
        p_data.bundle_item_name = bundle_item_name
        p_data.bundle_item_image = primary_item_icon

    else
        debug(flag5, "    ERROR - Unexpected 'bundle_status' value: " .. bundle_status)
    end

    local curr_weight = player_meta:get_float("weight_current")
    local max_weight = player_meta:get_float("weight_max")

    debug(flag5, "    curr_weight: " .. curr_weight)
    debug(flag5, "    max_weight: " .. max_weight)
    curr_weight = round(curr_weight, 2)

    local fs_elements = table_concat({
        "formspec_version[7]",
        "size[22.2,10.5,true]",
        "position[0.5,0.4]",
        "style_type[list;spacing=0.1,0.1]",
        "listcolors[",
            SLOT_COLOR_BG, ";",
            SLOT_COLOR_HOVER, ";",
            SLOT_COLOR_BORDER, ";",
            TOOLTIP_COLOR_BG, ";",
            TOOLTIP_COLOR_TEXT,
        "]",

        "tabheader[0,0;inv_tabs;Main,Status,Skills,Bundle,Settings,?,*;4;true;true]",
        "hypertext[0.2,0.2;4,1.5;bundle_title;",
        "<style color=#AAAAAA size=16><b>BUNDLE</b></style>]",

        -- bundle slot (to view a bundle)
        bundle_slot_elements,

        -- player inventory grid
        "box[", x_pos + 0 + (0 * 0.1), ",2.7;1,1;#000000]",
        "box[", x_pos + 1 + (1 * 0.1), ",2.7;1,1;#000000]",
        "box[", x_pos + 2 + (2 * 0.1), ",2.7;1,1;#000000]",
        "box[", x_pos + 3 + (3 * 0.1), ",2.7;1,1;#000000]",
        "box[", x_pos + 4 + (4 * 0.1), ",2.7;1,1;#000000]",
        "box[", x_pos + 5 + (5 * 0.1), ",2.7;1,1;#000000]",
        "box[", x_pos + 6 + (6 * 0.1), ",2.7;1,1;#000000]",
        "box[", x_pos + 7 + (7 * 0.1), ",2.7;1,1;#000000]",
        "list[current_player;main;", x_pos, ",2.7;8,1;]",
        "list[current_player;main;", x_pos, ",3.8;8,6;8]",

        -- inventory weight elements
        "image[", x_pos, ",9.45;0.6,0.6;ss_ui_iteminfo_attrib_weight.png;]",
        "hypertext[", x_pos + 0.8, ",9.65;4.0,2;inventory_weight;<b>",
            "<style color=#999999 size=16>", curr_weight, "</style>",
            "<style color=#666666 size=16> / ", max_weight, "</style>",
        "</b>]",
        "tooltip[", x_pos, ",9.4;1.8,0.5;inventory weight (current / max)]",

        -- right pane darker bg
        "box[9.9,0.0;12.3,10.5;#222222]",

        save_button_element,
        clear_button_element,

        -- bundle items grid
        "box[10.6,2.7;1,1;#000000]",
        "list[current_player;bundle_grid;10.6,2.7;10,10]",

        "tooltip[10.6,2.7;1,1;Add items here]",
        "listring[current_player;bundle_grid]",
		"listring[current_player;main]",
        bundle_item_count_elements
    })

    debug(flag5, "  get_fs_tab_bundle() END")
    return fs_elements
end


local flag2 = false
core.register_on_joinplayer(function(player)
	debug(flag2, "\nregister_on_joinplayer() bundle.lua")
    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
    local player_inv = player:get_inventory()

    player_inv:set_size("bundle_slot", 1)
    player_inv:set_size("bundle_grid", 1)

    -- whether an item bundle is currently in progress of being created.
    -- values can be 'inactive' or 'creating_new'
    p_data.bundle_status = "inactive"
    debug(flag2, "  p_data.bundle_status: " .. p_data.bundle_status)

    -- how many items are currently in the item bundle
    p_data.bundle_item_count = 0

    -- the item name of the main/primary item that represents the bundle
    p_data.bundle_item_name = ""

    -- the inventory image of the main/primary item. this is used to show the custom
    -- colorization of items like clothing and armor
    p_data.bundle_item_image = ""

	debug(flag2, "\nregister_on_joinplayer() END " .. mt_get_gametime())
end)




local flag3 = false
core.register_allow_player_inventory_action(function(player, action, inventory, inventory_info)
    debug(flag3, "\nregister_allow_player_inventory_action() bundle.lua")

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    debug(flag3, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag3, "  active_tab: " .. p_data.active_tab)

    if p_data.formspec_mode ~= "main_formspec" then
		debug(flag3, "  interaction not from bundle tab. NO FURTHER ACTION.")
		debug(flag3, "register_allow_player_inventory_action() end " .. mt_get_gametime())
		return
	elseif p_data.active_tab ~= "bundle" then
        debug(flag3, "  interaction from main formspec, but not BUNDLE tab. NO FURTHER ACTION.")
        debug(flag3, "register_allow_player_inventory_action() END " .. mt_get_gametime())
		return
    end

    local quantity_allowed

    if action == "move" then
        debug(flag3, "  action MOVE")
        local to_list = inventory_info.to_list
        local to_index = inventory_info.to_index
        local to_item = inventory:get_stack(to_list, to_index)

        local from_list = inventory_info.from_list
        local from_index = inventory_info.from_index
        local item = inventory:get_stack(from_list, from_index)
        local item_name = item:get_name()

        local item_count = item:get_count()
        quantity_allowed = item_count

        debug(flag3, "  itemstack: " .. item_name .. " " .. item_count)

        if from_list == "main" then
            debug(flag3, "  from Main inventory")

            if to_list == "main" then
                debug(flag3, "  to Main inventory")
                if SPILLABLE_ITEM_NAMES[item_name] then
                    debug(flag3, "  this is item has spillable contents")
                    if to_index > 8 then
                        debug(flag3, "  spillable item cannot be placed in main inventory")
                        notify(player, NOTIFICATIONS.pickup_liquid_fail, NOTIFY_DURATION, 0, 0.5, 3)
                        quantity_allowed = 0
                    else
                        debug(flag3, "  spillable item moved within hotbar. allowed")
                    end
                else
                    debug(flag3, "  this is not a spillable item. allowed.")
                end

            elseif to_list == "bundle_grid" then
                debug(flag3, "  to Bundle Grid")

                if p_data.bundle_item_count > 0 then
                    debug(flag3, "  bundle creation already began")

                    if to_index > 1 then
                        debug(flag3, "  moving to non-primary slot..")

                        debug(flag3, "  item_name: " .. item_name)
                        debug(flag3, "  p_data.bundle_item_name: " .. p_data.bundle_item_name)
                        if item_name == p_data.bundle_item_name then
                            debug(flag3, "  item is the same type as primary item")
                            if to_item:is_empty() then
                                debug(flag3, "  target slot empty. allowed.")
                                quantity_allowed = 1
                            else
                                debug(flag3, "  target slot occupied.")
                                notify(player, "Cannot swap - find empty slot", NOTIFY_DURATION, 0, 0.5, 3)
                                quantity_allowed = 0
                            end
                        else
                            debug(flag3, "  item is NOT same type as primary item. not allowed")
                            notify(player, "Only same item types can be bundled", NOTIFY_DURATION, 0, 0.5, 3)
                            quantity_allowed = 0
                        end

                    else
                        debug(flag3, "  moving to primary slot. not allowed.")
                        notify(player, "Primary slot already occupied", NOTIFY_DURATION, 0, 0.5, 3)
                        quantity_allowed = 0
                    end

                else
                    debug(flag3, "  bundle not started")
                    if SPILLABLE_ITEM_NAMES[item_name] then
                        debug(flag3, "  item is spillable. not allowed.")
                        notify(player, "Spillable items cannot be bundled", NOTIFY_DURATION, 0, 0.5, 3)
                        quantity_allowed = 0
                    elseif item_name == "ss:item_bundle" then
                        debug(flag3, "  item bundles not allowed.")
                        notify(player, "Item bundles cannot be bundled further", NOTIFY_DURATION, 0, 0.5, 3)
                        quantity_allowed = 0
                    else
                        debug(flag3, "  item is not spillable. allowed.")
                        quantity_allowed = 1
                    end
                end


            elseif to_list == "bundle_slot" then
                debug(flag3, "  to Bundle Slot")
                play_sound("button", {player_name = player_name})

                if item_name == "ss:item_bundle" then
                    debug(flag3, "  an item bundle")

                else
                    debug(flag3, "  not an item bundle")
                    quantity_allowed = 0
                    notify(player, "Item must be a bundle", NOTIFY_DURATION, 0, 0.5, 3)
                end

            else
                debug(flag3, "  ERROR - Unexpected 'to_list' value: " .. to_list)
            end

        elseif from_list == "bundle_grid" then
            debug(flag3, "  from Bundle grid")

            if to_list == "bundle_grid" then
                debug(flag3, "  to Bundle grid")
                if from_index > 1 then
                    debug(flag3, "  from non-primary bundle slot")
                    if to_index > 1 then
                        debug(flag3, "  to non-primary slot..")
                        if to_item:is_empty() then
                            debug(flag3, "  slot empty. allowed.")
                            quantity_allowed = 1
                        else
                            debug(flag3, "  slot not empty")
                            notify(player, "Cannot swap - find empty slot", NOTIFY_DURATION, 0, 0.5, 3)
                            quantity_allowed = 0
                        end
                    else
                        debug(flag3, "  to primary slot..")
                        if item:equals(to_item) then
                            quantity_allowed = 0
                            notify(player, "Cannot swap with primary item", NOTIFY_DURATION, 0, 0.5, 3)
                        else
                            quantity_allowed = 1
                        end
                    end
                else
                    debug(flag3, "  from primary bundle slot")
                    if to_index > 1 then
                        debug(flag3, "  to non-primary slot")
                        if to_item:is_empty() then
                            debug(flag3, "  slot is empty. not allowed")
                            notify(player, "Primary bundle item cannot be moved there", NOTIFY_DURATION, 0, 0.5, 3)
                            quantity_allowed = 0
                        else
                            debug(flag3, "  slot is not empty. swapping item from primary slot with another item.")
                            if item:equals(to_item) then
                                quantity_allowed = 0
                                notify(player, "Cannot swap with primary item", NOTIFY_DURATION, 0, 0.5, 3)
                            else
                                quantity_allowed = 1
                            end
                        end
                    end
                end

            elseif to_list == "main" then
                debug(flag3, "  to Main inventory")
                if from_index > 1 then
                    debug(flag3, "  removing non-primary bundle item. always allowed")
                else
                    debug(flag3, "  removing primary bundle item..")
                    debug(flag3, "  p_data.bundle_item_count: " .. p_data.bundle_item_count)
                    if p_data.bundle_item_count > 1 then
                        debug(flag3, "  Cannot remove primary bundle item while other bundle items remain.")
                        notify(player, "Remove other bundle items first.", NOTIFY_DURATION, 0, 0.5, 3)
                        quantity_allowed = 0
                    else
                        debug(flag3, "  allowed")
                    end
                end

            else debug(flag3, "  ERROR - Unexpected 'to_list' value: " .. to_list) end

        elseif from_list == "bundle_slot" then
            debug(flag3, "  from Bundle slot")

            if to_list == "main" then
                debug(flag3, "  to Main inventory. allowed.")

            elseif to_list == "bundle_grid" then
                debug(flag3, "  to Bundle grid. not allowed.")
                notify(player, "Item bundles cannot be bundled further", NOTIFY_DURATION, 0, 0.5, 3)
                quantity_allowed = 0

            else debug(flag3, "  ERROR - Unexpected 'to_list' value: " .. to_list) end

        else debug(flag3, "  Error - Unexpected 'from_list' value: " .. from_list) end


    elseif action == "take" then
        debug(flag3, "  action REMOVE")
        local listname = inventory_info.listname
        local item = inventory_info.stack
        local from_index = inventory_info.index
        local item_name = item:get_name()
        local item_count = item:get_count()
        quantity_allowed = item_count

        if listname == "bundle_grid" then
            debug(flag3, "  from bundle grid")
            if from_index > 1 then
                debug(flag3, "  from non-primary slot. always allowed.")

            else
                debug(flag3, "  from primary slot #1")
                debug(flag3, "  p_data.bundle_item_count: " .. p_data.bundle_item_count)
                if p_data.bundle_item_count > 1 then
                    debug(flag3, "  Cannot remove primary bundle item while other bundle items remain.")
                    notify(player, "Cannot drop primary item while others remain", NOTIFY_DURATION, 0, 0.5, 3)
                    quantity_allowed = 0
                else
                    debug(flag3, "  allowed since no other bundle items exist")
                end
            end

        elseif listname == "main" then
            debug(flag3, "  from main inventory")

        else
            debug(flag3, "  ERROR - Unexpected 'listname' value: " .. listname)
        end


    else
        debug(flag3, "  Unexpected action: " .. action)
    end

    debug(flag3, "  quantity_allowed: " .. quantity_allowed)
    debug(flag3,"register_allow_player_inventory_action() END " .. mt_get_gametime())
    return quantity_allowed
end)




local flag4 = false
core.register_on_player_inventory_action(function(player, action, inventory, inventory_info)
    debug(flag4, "\nregister_on_player_inventory_action() bundle.lua")

    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    debug(flag4, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag4, "  active_tab: " .. p_data.active_tab)

    if p_data.formspec_mode ~= "main_formspec" then
		debug(flag4, "  interaction not from main formspec. NO FURTHER ACTION.")
		debug(flag4, "register_on_player_inventory_action() end " .. mt_get_gametime())
		return
	elseif p_data.active_tab ~= "bundle" then
        debug(flag4, "  interaction from main formspec, but not BUNDLE tab. NO FURTHER ACTION.")
        debug(flag4, "register_on_player_inventory_action() END " .. mt_get_gametime())
		return
    end

    local fs = player_data[player_name].fs

    debug(flag4, "  proceeding with main action..")

    if action == "move" then
        debug(flag4, "  MOVING item..")
        local to_list = inventory_info.to_list
        local to_index = inventory_info.to_index
        local from_list = inventory_info.from_list
        local from_index = inventory_info.from_index
        local item = inventory:get_stack(to_list, to_index)
        local item_name = item:get_name()
        play_sound("item_move", {item_name = item_name, player_name = player_name})

        if from_list == "main" then
            debug(flag4, "  from Main inventory")

            if to_list == "main" then
                debug(flag4, "  to Main inventory. NO FURTHER ACTIONs.")

            elseif to_list == "bundle_slot" then
                debug(flag4, "  to Bundle slot. awaiting player to click 'open bundle' button..")

            elseif to_list == "bundle_grid" then
                debug(flag4, "  to Bundle Grid")

                local formspec
                if to_index > 1 then
                    debug(flag4, "  into non-primary slot")
                    local bundle_status =  p_data.bundle_status
                    if bundle_status == "view_bundle" or bundle_status == "update_existing" then
                        p_data.bundle_status = "update_existing"
                    else
                        p_data.bundle_status = "creating_new"
                    end
                    p_data.bundle_item_count = p_data.bundle_item_count + 1
                    local primary_item = inventory:get_stack("bundle_grid", 1)
                    formspec = get_fs_tab_bundle(inventory, p_data, player:get_meta(), primary_item:get_name())
                else
                    debug(flag4, "  into primary slot")

                    -- remove any item from the bundle slot
                    reset_bundle_slot(player)

                    local item_meta = item:get_meta()
                    p_data.bundle_status = "creating_new"
                    p_data.bundle_item_count = 1
                    p_data.bundle_item_name = item_name
                    p_data.bundle_item_image = item_meta:get_string("inventory_image")
                    formspec = get_fs_tab_bundle(inventory, p_data, player:get_meta(), item_name)
                end
                mt_show_formspec(player_name, "ss:ui_bundle", formspec)

            else
                debug(flag4, "  Unimplemented action: " .. from_list .. " >> " .. to_list)
            end

        elseif from_list == "bundle_grid" then
            debug(flag4, "  from Bundle grid")

            if to_list == "bundle_grid" then
                debug(flag4, "  to Bundle grid")

                if to_index > 1 then
                    debug(flag4, "  into non primary bundle slot")
                    if p_data.bundle_status == "view_bundle" then
                        p_data.bundle_status = "update_existing"
                        local primary_item = inventory:get_stack("bundle_grid", 1)
                        local formspec = get_fs_tab_bundle(inventory, p_data, player:get_meta(), primary_item:get_name())
                        mt_show_formspec(player_name, "ss:ui_bundle", formspec)
                    end

                else
                    debug(flag4, "  into primary bundle slot")

                    -- at this point, 'bundle_status' cannot be 'inactive' and can
                    -- only be 'creating_new', 'view_bundle', or 'update_existing'
                    if p_data.bundle_status == "view_bundle" then
                        p_data.bundle_status = "update_existing"
                    end
                    local item_meta = item:get_meta()
                    p_data.bundle_item_image = item_meta:get_string("inventory_image")
                    local formspec = get_fs_tab_bundle(inventory, p_data, player:get_meta(), item:get_name())
                    mt_show_formspec(player_name, "ss:ui_bundle", formspec)
                end

            elseif to_list == "main" then
                debug(flag4, "  to Main inventory")

                if from_index > 1 then
                    debug(flag4, "  from non-primary bundle grid slot")
                    p_data.bundle_item_count = p_data.bundle_item_count - 1
                    local bundle_status = p_data.bundle_status
                    if bundle_status == "view_bundle" or bundle_status == "update_existing" then
                        p_data.bundle_status = "update_existing"
                    else
                        p_data.bundle_status = "creating_new"
                    end
                    debug(flag4, "  p_data.bundle_status: " .. p_data.bundle_status)
                    local primary_item = inventory:get_stack("bundle_grid", 1)
                    local formspec = get_fs_tab_bundle(inventory, p_data, player:get_meta(), primary_item:get_name())
                    mt_show_formspec(player_name, "ss:ui_bundle", formspec)

                else
                    debug(flag4, "  from primary bundle grid slot")
                    local from_item = inventory:get_stack(from_list, from_index)
                    if from_item:is_empty() then
                        debug(flag4, "  from slot is empty")
                        debug(flag4, "  resetting bundle formspec..")
                        p_data.bundle_status = "inactive"
                        p_data.bundle_item_count = 0
                        p_data.bundle_item_name = ""
                        local formspec = get_fs_tab_bundle(inventory, p_data, player:get_meta())
                        mt_show_formspec(player_name, "ss:ui_bundle", formspec)

                    else
                        -- item from main inv was swapped with item in bundle grid slot
                        -- do not reset the leftside bundle slot element
                        debug(flag4, "  from slot has an item!")
                    end
                end
            end
        else
            debug(flag4, "  Unimplemented action from from_list: " .. from_list)
        end

    elseif action == "take" then
        local listname = inventory_info.listname
        local item = inventory_info.stack
        local from_index = inventory_info.index
        local weight = get_itemstack_weight(item)
        local player_meta = player:get_meta()

        debug(flag4, "  REMOVED")

        -- update weight statbar hud. this also updates weight metadata.
        local update_data = {"normal", "weight", -weight, 1, 1, "curr", "add", true}
        update_stat(player, p_data, player_meta, update_data)

        local formspec
        if listname == "bundle_grid" then
            debug(flag3, "  from bundle grid")
            if from_index > 1 then
                debug(flag3, "  from bundle grid non primary slot")
                local bundle_status = p_data.bundle_status
                if bundle_status == "view_bundle" or bundle_status == "update_existing" then
                    p_data.bundle_status = "update_existing"
                else
                    p_data.bundle_status = "creating_new"
                end
                p_data.bundle_item_count = p_data.bundle_item_count - 1
                local primary_item = inventory:get_stack("bundle_grid", 1)
                formspec = get_fs_tab_bundle(inventory, p_data, player_meta, primary_item:get_name())
            else
                -- register_allow_player_inventory_action() ensures that this executes
                -- only if no other bundle items exists
                debug(flag3, "  from bundle grid primary slot #1")
                p_data.bundle_status = "inactive"
                p_data.bundle_item_count = 0
                p_data.bundle_item_name = ""
                formspec = get_fs_tab_bundle(inventory, p_data, player_meta)
            end

        elseif listname == "bundle_slot" then
            debug(flag3, "  from bundle slot")
            formspec = get_fs_tab_bundle(inventory, p_data, player_meta)

        elseif listname == "main" then
            debug(flag3, "  from main inventory")
            local bundle_status = p_data.bundle_status
            if bundle_status == "inactive" then
                debug(flag3, "  no bundle was active")
                formspec = get_fs_tab_bundle(inventory, p_data, player_meta)
            else
                debug(flag3, "  bundle was in progress")
                if bundle_status == "view_bundle" then
                    p_data.bundle_status = "update_existing"
                end
                local primary_item = inventory:get_stack("bundle_grid", 1)
                formspec = get_fs_tab_bundle(inventory, p_data, player_meta, primary_item:get_name())
            end

        else
            debug(flag3, "  ERROR - Unexpected 'listname' value: " .. listname)
        end

        play_sound("item_move", {item_name = item:get_name(), player_name = player_name})

        -- update/refresh bundle formspec
        mt_show_formspec(player_name, "ss:ui_bundle", formspec)

        -- update weight formspec shown in Main tab
        fs.center.weight = get_fs_weight(player)
        player_meta:set_string("fs", mt_serialize(fs))
        player:set_inventory_formspec(build_fs(fs))

    else
        debug(flag4, "  Unimplemented action: " .. action)
    end

    debug(flag4, "register_on_player_inventory_action() END " .. mt_get_gametime())
end)



local flag1 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag1, "\nregister_on_player_receive_fields() BUNDLE.lua")
	--debug(flag1, "  fields: " .. dump(fields))

    local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
    debug(flag1, "  formspec_mode: " .. p_data.formspec_mode)
    debug(flag1, "  active_tab: " .. p_data.active_tab)
    debug(flag1, "  formname: " .. formname)

    -- occurs when clicking on the BUNDLE tab while previously from a different tab.
    if fields.inv_tabs == "4" then
        debug(flag1, "  clicked on 'BUNDLE' tab!")
        play_sound("button", {player_name = player_name})
        p_data.active_tab = "bundle"
        p_data.bundle_status = "inactive"
        p_data.bundle_item_count = 0
        local formspec = get_fs_tab_bundle(player:get_inventory(), p_data, player:get_meta())
        mt_show_formspec(player_name, "ss:ui_bundle", formspec)
        debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
        return

    else
        debug(flag1, "  did not click on BUNDLE tab")

        -- occurs when interacting with any formspec element that is not part of
        -- the main player inventory or its tabs
        if p_data.formspec_mode ~= "main_formspec" then
            debug(flag1, "  interaction not from main formspec. NO FURTHER ACTION.")
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        -- occurs while viewing BUNDLE tab, then clicking on another tab aside from
        -- Main tab. this code does not trigger if Main tab was clicked, since it is
        -- handle by inventory.lua, which is loaded before the lua files of other tabs
        elseif p_data.active_tab ~= "bundle" then
            debug(flag1, "  interaction from main formspec, but not BUNDLE tab.")

            if formname ~= "ss:ui_bundle" then
                debug(flag1, "  clicked on formspec element not from bundle tab. NO FURTHER ACTION.")
                debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
                return
            end

            local bundle_status = p_data.bundle_status
            debug(flag1, "  bundle_status: " .. bundle_status)
            if bundle_status == "inactive" then
                debug(flag1, "  bundle action inactive. checking bundle slot..")
                reset_bundle_slot(player)
            elseif bundle_status == "view_bundle" then
                debug(flag1, "  was viewing a bundle. resetting item slots..")
                cancel_view_bundle(player, p_data)
                --notify(player, "Bundle closed", NOTIFY_DURATION, 0.5, 0, 2)
                mt_after(0.25, function()
                    play_sound("bundle_close", {player_name = player_name})
                end)
            else
                debug(flag1, "  was updating or creating a bundle. resetting item slots..")
                reset_bundle_grid(player, p_data)
                --notify(player, "Bundle items placed into inventory", NOTIFY_DURATION, 0.5, 0, 2)
                mt_after(0.25, function()
                    play_sound("bundle_cancel", {player_name = player_name})
                end)
            end
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        -- occurs while viewing BUNDLE tab, then clicking on Main tab. code does
        -- not trigger if clicked on other tabs since the Main tab is managed by
        -- nventory.lua and is loaded before the lua files of other tabs
        elseif fields.inv_tabs == "1"
            or fields.inv_tabs == "2"
            or fields.inv_tabs == "3"
            or fields.inv_tabs == "5"
            or fields.inv_tabs == "6"
            or fields.inv_tabs == "7" then
            debug(flag1, "  clicked away from BUNDLE tab and onto MAIN tab")
            local bundle_status = p_data.bundle_status
            debug(flag1, "  bundle_status: " .. bundle_status)
            if bundle_status == "inactive" then
                debug(flag1, "  bundle action inactive. checking bundle slot..")
                reset_bundle_slot(player)
            elseif bundle_status == "view_bundle" then
                debug(flag1, "  was viewing a bundle. resetting item slots..")
                cancel_view_bundle(player, p_data)
                --notify(player, "Bundle closed", NOTIFY_DURATION, 0.5, 0, 2)
                mt_after(0.25, function()
                    play_sound("bundle_close", {player_name = player_name})
                end)
            else
                debug(flag1, "  was updating or creating a bundle. resetting item slots..")
                reset_bundle_grid(player, p_data)
                --notify(player, "Bundle items placed into inventory", NOTIFY_DURATION, 0.5, 0, 2)
                mt_after(0.25, function()
                    play_sound("bundle_cancel", {player_name = player_name})
                end)
            end
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        -- occurs when exiting the formspec window by pressing ESC key, or by clicking
        -- outside the formspec window boundary
        elseif fields.quit then
            debug(flag1, "  exiting formspec..")
            local bundle_status = p_data.bundle_status
            debug(flag1, "  bundle_status: " .. bundle_status)
            if bundle_status == "inactive" then
                debug(flag1, "  bundle action inactive. checking bundle slot..")
                reset_bundle_slot(player)
            elseif bundle_status == "view_bundle" then
                debug(flag1, "  was viewing a bundle. resetting item slots..")
                cancel_view_bundle(player, p_data)
                --notify(player, "Bundle closed", NOTIFY_DURATION, 0.5, 0, 2)
                mt_after(0.25, function()
                    play_sound("bundle_close", {player_name = player_name})
                end)
            else
                debug(flag1, "  was updating or creating a bundle. resetting item slots..")
                reset_bundle_grid(player, p_data)
                --notify(player, "Bundle items placed into inventory", NOTIFY_DURATION, 0.5, 0, 2)
                mt_after(0.25, function()
                    play_sound("bundle_cancel", {player_name = player_name})
                end)
            end

            p_data.active_tab = "main"
            debug(flag1, "register_on_player_receive_fields() END " .. mt_get_gametime())
            return

        elseif fields.bundle_open then
            debug(flag1, "  clicked on OPEN Bundle button")
            play_sound("button", {player_name = player_name})
            local player_inv = player:get_inventory()
            if player_inv:is_empty("bundle_slot") then
                notify(player, "Place bundled item into item bundle slot", 4, 0, 0.5, 3)
            else
                play_sound("bundle_open", {player_name = player_name})
                p_data.bundle_status = "view_bundle"
                local formspec = get_fs_tab_bundle(player:get_inventory(), p_data, player:get_meta())
                mt_show_formspec(player_name, "ss:ui_bundle", formspec)
            end

        elseif fields.bundle_save then
            debug(flag1, "  clicked on SAVE button")
            play_sound("button", {player_name = player_name})
            local bundle_item_count = p_data.bundle_item_count
            if bundle_item_count > 1 then
                debug(flag1, "  creating bundle..")
                local bundle_item = ItemStack("ss:item_bundle")
                local player_inv = player:get_inventory()
                local player_meta = player:get_meta()

                -- set bundle count
                local bundle_item_meta = bundle_item:get_meta()
                bundle_item_meta:set_int("bundle_item_count", bundle_item_count)
                debug(flag1, "  bundle_item_count: " .. bundle_item_count)

                -- set bundle item name
                local primary_item = player_inv:get_stack("bundle_grid", 1)
                local primary_item_name = primary_item:get_name()
                bundle_item_meta:set_string("bundle_item_name", primary_item_name)

                -- set bundle weight
                local bundle_weight = bundle_item_count * ITEM_WEIGHTS[primary_item_name]
                bundle_item_meta:set_float("bundle_weight", bundle_weight)
                debug(flag1, "  bundle_weight: " .. bundle_weight)

                -- set bundle value
                local bundle_value = bundle_item_count * ITEM_VALUES[primary_item_name]
                bundle_item_meta:set_int("bundle_value", bundle_value)
                debug(flag1, "  bundle_value: " .. bundle_value)

                -- set bundle attack hit damage value.
                local bundle_hit_damage = ITEM_HIT_DAMAGES[primary_item_name] / 2
                bundle_item_meta:set_float("bundle_hit_damage", bundle_hit_damage)
                debug(flag1, "  bundle_hit_damage: " .. bundle_hit_damage)

                -- set bundle attack hit range value.
                local bundle_hit_range = ITEM_POINTING_RANGES[primary_item_name]
                bundle_item_meta:set_float("bundle_hit_range", bundle_hit_range)
                debug(flag1, "  bundle_hit_range: " .. bundle_hit_range)

                -- set bundle attack hit cooldown value.
                local item_hit_cooldown = ITEM_HIT_COOLDOWNS[primary_item_name]
                local cooldown_modifier = item_hit_cooldown * bundle_item_count * 0.10
                local bundle_hit_cooldown = round(item_hit_cooldown + cooldown_modifier, 1)
                if bundle_hit_cooldown > HIT_COOLDOWN_MAX then
                    bundle_hit_cooldown = HIT_COOLDOWN_MAX
                end
                bundle_item_meta:set_float("bundle_hit_cooldown", bundle_hit_cooldown)
                debug(flag1, "  bundle_hit_cooldown: " .. bundle_hit_cooldown)

                -- set bundle attack hit type value. will always be 'blunt'
                local bundle_hit_type = "blunt"
                bundle_item_meta:set_string("bundle_hit_type", bundle_hit_type)
                debug(flag1, "  bundle_hit_type: " .. bundle_hit_type)

                -- serialize data of each bundle slot item and save it into the
                -- bundle item's metadata
                debug(flag1, "    transfer all grid item data into bundle item metadata..")
                local bundle_grid_slots = player_inv:get_list("bundle_grid")
                --debug(flag1, "    bundle_grid_slots: " .. dump(bundle_grid_slots))
                local stack_max = STACK_MAX_COUNTS[primary_item_name]
                if stack_max > 60 then stack_max = 60 end
                local bundle_burn_time = 0
                for i = 1, stack_max do
                    debug(flag1, "    slot #" .. i)
                    local item = bundle_grid_slots[i]
                    if item:is_empty() then
                        --debug(flag1, "      empty")
                    else
                        local item_burn_time = get_item_burn_time(item)
                        debug(flag1, "      item_burn_time: " .. item_burn_time)
                        bundle_burn_time = bundle_burn_time + item_burn_time
                        local item_string = item:to_string()
                        debug(flag1, "      item_string: " .. item_string)
                        bundle_item_meta:set_string("bundle_item_" .. i, item_string)
                        player_inv:set_stack("bundle_grid", i, ItemStack(""))
                        debug(flag1, "      saved into primary item's metadata")
                    end
                end

                -- set bundle fuel burn time
                bundle_item_meta:set_int("bundle_burn_time", bundle_burn_time)
                debug(flag1, "    bundle_burn_time: " .. bundle_burn_time)

                -- update bundle item's tooltip description
                local tooltip = table_concat({ "* BUNDLE *\n",
                    ITEM_TOOLTIP[primary_item_name], " x", bundle_item_count, "\n",
                    "bundle weight: ", bundle_weight
                })
                debug(flag1, "  tooltip: " .. tooltip)
                bundle_item_meta:set_string("description", tooltip)

                -- update bundle item's inventory icon
                local bundle_icon_image = ""
                if p_data.bundle_item_image == "" then
                    debug(flag1, "  item has no custom colorization")
                    bundle_icon_image = CRAFTITEM_ICON[primary_item_name]
                else
                    debug(flag1, "  item has custom colorization")
                    bundle_icon_image = p_data.bundle_item_image
                end
                debug(flag1, "  bundle_icon_image: " .. bundle_icon_image)
                bundle_icon_image = bundle_icon_image .. "^ss_item_bundle.png"
                bundle_item_meta:set_string("inventory_image", bundle_icon_image)

                -- and new bundle item to main inventory
                if player_inv:room_for_item("main", bundle_item) then
                    player_inv:add_item("main", bundle_item)
                    debug(flag1, "  new bundle item added to inventory")

                -- no space in inv. drop new bundle item to the ground.
                else
                    mt_add_item(player:get_pos(), bundle_item)

                    -- reduce inventory weight based on the bundle item's weight
                    local update_data = {"normal", "weight", -bundle_weight, 1, 1, "curr", "add", true}
                    update_stat(player, p_data, player_meta, update_data)

                    -- update weight formspec for Main tab
                    local fs = player_data[player_name].fs
                    fs.center.weight = get_fs_weight(player)
                    player_meta:set_string("fs", mt_serialize(fs))
                    player:set_inventory_formspec(build_fs(fs))

                    notify(player, "New bundle item dropped to ground.", NOTIFY_DURATION, 0.8, 0, 2)
                    notify(player, "No inventory space", NOTIFY_DURATION, 0, 0.4, 3)
                end

                play_sound("bundle_close", {player_name = player_name})

                -- remove primary item from bundle grid slot #1
                player_inv:set_stack("bundle_grid", 1, ItemStack(""))

                -- reset bundle slot and refresh bundle formspec
                p_data.bundle_status = "inactive"
                p_data.bundle_item_count = 0
                p_data.bundle_item_name = ""
                local formspec = get_fs_tab_bundle(player_inv, p_data, player_meta)
                mt_show_formspec(player_name, "ss:ui_bundle", formspec)

            else
                debug(flag1, "  not enough items. NO FURTHER ACTION.")
                play_sound("button", {player_name = player_name})
                notify(player, "Bundle needs 1 more item", NOTIFY_DURATION, 0, 0.5, 3)
            end

        elseif fields.bundle_close then
            debug(flag1, "  clicked on CLOSE button")
            play_sound("button", {player_name = player_name})
            play_sound("bundle_close", {player_name = player_name})
            local player_inv = player:get_inventory()

            -- remove all items from bundle grid
            player_inv:set_list("bundle_grid", {})

            -- reset bundle status and properties
            p_data.bundle_status = "inactive"
            p_data.bundle_item_count = 0
            p_data.bundle_item_name = ""

            -- refresh formspec
            local formspec = get_fs_tab_bundle(player_inv, p_data, player:get_meta())
            mt_show_formspec(player_name, "ss:ui_bundle", formspec)

        elseif fields.bundle_clear then
            debug(flag1, "  clicked on CLEAR button")
            play_sound("button", {player_name = player_name})
            play_sound("bundle_cancel", {player_name = player_name})

            local player_inv = player:get_inventory()
            if p_data.bundle_status == "view_bundle" then
                -- remove the item from the bundle slot. this action was not done
                -- during 'view_bundle' status, so that the item can be recalled
                -- and put back into main inv if player exits the window
                player_inv:set_stack("bundle_slot", 1, ItemStack(""))
            end

            -- move all items in the bundle grid back into the main inventory
            reset_bundle_grid(player, p_data)
            local formspec = get_fs_tab_bundle(player_inv, p_data, player:get_meta())
            mt_show_formspec(player_name, "ss:ui_bundle", formspec)

        else
            debug(flag1, "  * unimplemented interaction *")
        end

    end

    debug(flag1, "register_on_player_receive_fields() END "  .. mt_get_gametime())
end)


local flag9 = false
core.register_on_dieplayer(function(player)
    debug(flag9, "\nregister_on_dieplayer() BUNDLE")
    local player_name = player:get_player_name()
    local p_data = player_data[player_name]
    local player_inv = player:get_inventory()

    debug(flag9, "  resetting bundle tab")
    local bundle_status = p_data.bundle_status
    debug(flag9, "  bundle_status: " .. bundle_status)
    if bundle_status == "inactive" then
        if not player_inv:is_empty("bundle_slot") then
            debug(flag9, "  item bundle found in bundle slot. dropping to ground..")
            local bundle_item = player_inv:get_stack("bundle_slot", 1)
            mt_add_item(player:get_pos(), bundle_item)
            player_inv:set_list("bundle_slot", {})
            -- reducing inventory weight will already be handled further below
        end
    else
        -- bundle status is creating_new, update_existing, or view_bundle
        debug(flag9, "  dropping all items from bundle grid..")
        local pos = player:get_pos()
        local bundle_grid_items = player_inv:get_list("bundle_grid")
        for i = 1, #bundle_grid_items do
            local slot_item = bundle_grid_items[i]
            if not slot_item:is_empty() then
                debug(flag9, "    slot_item: " .. slot_item:get_name())
                mt_add_item({
                    x = pos.x + math_random(-2, 2)/10,
                    y = pos.y,
                    z = pos.z + math_random(-2, 2)/10},
                    slot_item
                )
            end
        end
        player_inv:set_list("bundle_grid", {})
        player_inv:set_list("bundle_slot", {})
    end

    debug(flag9, "register_on_dieplayer() END")
end)



--[[
When creating a new bundle, its stack max count is referenced from the table
'STACK_MAX_COUNTS'. the values in the table are pre-calculated at mod runtime
by taking the constant 'SLOT_WEIGHT_MAX' (which is currently 100) and divded by
the item's weight. item's with miniscule weights could have a max count that
results in over 99, in which case it is capped to 99.
--]]