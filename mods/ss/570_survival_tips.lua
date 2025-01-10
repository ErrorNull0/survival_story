print("- loading survival_tips.lua")

-- cache global variables for faster access
local SURVIVAL_TIPS = ss.SURVIVAL_TIPS

local fullpath_tips = minetest.get_modpath("ss") .. "/survival_tips.txt"
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