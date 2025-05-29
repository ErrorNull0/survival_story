print("- loading survival_tips.lua")

--[[ table that holds all survival tips that are displayed in the game, from the
player inventory UI formspec. Example:
{
    {"Drink Water", "Drink water or you will die."},
    {"Eat Food", "Eat food or you will die."},
    {"Craft Tools", "Craft tools to make it easter to survive."}
}
--]]
local SURVIVAL_TIPS = {}


local fullpath_tips = core.get_modpath("ss") .. "/survival_tips.txt"
local file_tips = io.open(fullpath_tips, "r")
if not file_tips then
	print("Could not open file: " .. fullpath_tips)
	return
end

local tip_title = ""
local tip_text = ""
local toggle = true -- Toggle between reading tip_title and tip_text

for line in file_tips:lines() do
	if line:match("^%s*$") then  -- Skip empty lines
		goto continue
	end
	if toggle then
		tip_title = line
	else
		tip_text = line
		table.insert(SURVIVAL_TIPS, {tip_title, tip_text})
	end
	toggle = not toggle
	::continue::
end
file_tips:close()