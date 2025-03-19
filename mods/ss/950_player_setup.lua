print("- loading player_setup.lua")

-- cache global functions for faster access
local table_concat = table.concat
local mt_serialize = core.serialize
local mt_show_formspec = core.show_formspec
local mt_after = core.after
local mt_get_gametime = core.get_gametime
local debug = ss.debug
local notify = ss.notify
local play_sound = ss.play_sound
local build_fs = ss.build_fs
local get_fs_player_avatar = ss.get_fs_player_avatar

local current_tab = ss.current_tab


local color_hex = {
	"#ff0000", "#ff4d00", "#ff9900", "#ffe500", "#ccff00", "#80ff00", "#33ff00",
	"#00ff1a", "#00ff66", "#00ffb2", "#00ffff", "#00b2ff", "#0066ff", "#001aff",
	"#3300ff", "#8000ff", "#cc00ff", "#ff00e5", "#ff00e5", "#ff004d"
}

local color_hsl = {
	{0,50,0}, {18,50,0}, {36,50,0}, {54,50,0}, {72,50,0}, {90,50,0}, {108,50,0}, 
	{126,50,0}, {144,50,0}, {162,50,0}, {180,50,0}, {198,50,0}, {216,50,0}, {234,50,0},
	{252,50,0}, {270,50,0}, {288,50,0}, {306,50,0}, {324,50,0}, {342,50,0}
}

local saturation_mod = {-50,-36,-21,-7,7,21,36,50}
local lightness_mod = {-75,-54,-32,-11,11,32,54,75}
local contrast_mod = {"0:0","12:0","24:0","36:0","48:0","60:0","72:0","86:0"}


local highlight_pos_color = {
	color1 = "4.55,0.66",
	color2 = "5.05,0.66",
	color3 = "5.55,0.66",
	color4 = "6.05,0.66",
	color5 = "6.55,0.66",
	color6 = "7.05,0.66",
	color7 = "7.55,0.66",
	color8 = "8.05,0.66",
	color9 = "8.55,0.66",
	color10 = "9.05,0.66",
	color11 = "4.55,1.25",
	color12 = "5.05,1.25",
	color13 = "5.55,1.25",
	color14 = "6.05,1.25",
	color15 = "6.55,1.25",
	color16 = "7.05,1.25",
	color17 = "7.55,1.25",
	color18 = "8.05,1.25",
	color19 = "8.55,1.25",
	color20 = "9.05,1.25"
}

local highlight_pos_sat = {
	saturation1 = "4.55,2.56",
	saturation2 = "5.05,2.56",
	saturation3 = "5.55,2.56",
	saturation4 = "6.05,2.56",
	saturation5 = "6.55,2.56",
	saturation6 = "7.05,2.56",
	saturation7 = "7.55,2.56",
	saturation8 = "8.05,2.56"
}

local highlight_pos_light = {
	lightness1 = "4.55,3.76",
	lightness2 = "5.05,3.76",
	lightness3 = "5.55,3.76",
	lightness4 = "6.05,3.76",
	lightness5 = "6.55,3.76",
	lightness6 = "7.05,3.76",
	lightness7 = "7.55,3.76",
	lightness8 = "8.05,3.76",
}

local highlight_pos_contrast = {
	contrast1 = "4.55,4.96",
	contrast2 = "5.05,4.96",
	contrast3 = "5.55,4.96",
	contrast4 = "6.05,4.96",
	contrast5 = "6.55,4.96",
	contrast6 = "7.05,4.96",
	contrast7 = "7.55,4.96",
	contrast8 = "8.05,4.96",
}

local highlight_pos_hair_type = {
	hair_type1 = "4.55,6.16",
	hair_type2 = "5.05,6.16",
	hair_type3 = "5.55,6.16",
	hair_type4 = "6.05,6.16",
	hair_type5 = "6.55,6.16",
	hair_type6 = "7.05,6.16",
	hair_type7 = "7.55,6.16",
	hair_type8 = "8.05,6.16",

	hair_type9 = "4.55,6.75",
	hair_type10 = "5.05,6.75",
	hair_type11 = "5.55,6.75"
}

-- the position of each body type swatch/box within the 'body type' tab of the
-- player setup window. this info is used to position the white box that highlights
-- the currently selected body type.
local body_swatch_pos = {
	body_type1 = "4.55,0.66",
	body_type2 = "5.05,0.66",
}


local flag1 = false
--- @param p_data table reference to table with data specific to this player
--- @return string formspec the formspec string representing the player setup window that
-- displays during a new game or upon respawning after death.
function ss.get_fs_setup_body(p_data)
	debug(flag1, "\nget_fs_setup_body()")

	debug(flag1, "  mesh: " .. p_data.avatar_mesh)
	debug(flag1, "  texture: " .. p_data.avatar_texture_base)
	debug(flag1, "  selected_type: " .. p_data.avatar_body_type_selected)

	local formspec = table_concat({
		"formspec_version[7]",
		"size[9.9,9.0,true]",
		"position[0.5,0.4]",
		"tabheader[0,0;player_setup_tabs;Body Type,Skin,Hair,Eyes,Underwear;1;true;true]",
		"box[0.0,0.0;4.25,9.0;#222222]",
		"model[0.2,0.25;4,8;player_avatar;", p_data.avatar_mesh, ";", p_data.avatar_texture_base, ";{0,200};false;true;2,2;0]",

		"hypertext[4.5,0.3;5,1;label_body_type;",
		"<style color=#AAAAAA size=15><b>Body Type</b></style>]",
		"box[", body_swatch_pos[p_data.avatar_body_type_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,0.7;0.4,0.5;[fill:1x1:#000000;body_type1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,0.7;0.4,0.5;[fill:1x1:#000000;body_type2;2;false;false;[fill:1x1:#222222]",

		"button_exit[5.4,7.7;3,1;btn_done;Done]"
	})

	debug(flag1, "get_fs_setup_body() end")
	return formspec
end
local get_fs_setup_body = ss.get_fs_setup_body


local flag2 = false
--- @param p_data table reference to table with data specific to this player
--- @return string formspec the formspec string representing the player setup window that
-- displays during a new game or upon respawning after death.
local function get_fs_setup_skin(p_data)
	debug(flag2, "\nget_fs_setup_skin()")
	debug(flag2, "  avatar_skin_color_selected: " .. p_data.avatar_skin_color_selected)
	debug(flag2, "  avatar_skin_saturation_selected: " .. p_data.avatar_skin_saturation_selected)
	debug(flag2, "  avatar_skin_lightness_selected: " .. p_data.avatar_skin_lightness_selected)
	debug(flag2, "  avatar_skin_contrast_selected: " .. p_data.avatar_skin_contrast_selected)

	local formspec = table_concat({
		"formspec_version[7]",
		"size[9.9,9.0,true]",
		"position[0.5,0.4]",
		"tabheader[0,0;player_setup_tabs;Body Type,Skin,Hair,Eyes,Underwear;2;true;true]",
		"box[0.0,0.0;4.25,9.0;#222222]",
		"model[0.2,0.25;4,8;player_avatar;", p_data.avatar_mesh, ";", p_data.avatar_texture_base, ";{0,200};false;true;2,2;0]",

		"hypertext[4.5,0.3;5,1;label_skin_color;",
		"<style color=#AAAAAA size=15><b>Skin Color</b></style>]",
		"box[", highlight_pos_color[p_data.avatar_skin_color_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,0.7;0.4,0.5;[fill:1x1:", color_hex[1], ";skin_color1;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.1,0.7;0.4,0.5;[fill:1x1:", color_hex[2], ";skin_color2;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.6,0.7;0.4,0.5;[fill:1x1:", color_hex[3], ";skin_color3;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.1,0.7;0.4,0.5;[fill:1x1:", color_hex[4], ";skin_color4;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.6,0.7;0.4,0.5;[fill:1x1:", color_hex[5], ";skin_color5;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.1,0.7;0.4,0.5;[fill:1x1:", color_hex[6], ";skin_color6;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.6,0.7;0.4,0.5;[fill:1x1:", color_hex[7], ";skin_color7;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.1,0.7;0.4,0.5;[fill:1x1:", color_hex[8], ";skin_color8;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.6,0.7;0.4,0.5;[fill:1x1:", color_hex[9], ";skin_color9;;false;false;[fill:1x1:#ffffff]",
		"image_button[9.1,0.7;0.4,0.5;[fill:1x1:", color_hex[10], ";skin_color10;;false;false;[fill:1x1:#ffffff]",
		"image_button[4.6,1.3;0.4,0.5;[fill:1x1:", color_hex[11], ";skin_color11;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.1,1.3;0.4,0.5;[fill:1x1:", color_hex[12], ";skin_color12;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.6,1.3;0.4,0.5;[fill:1x1:", color_hex[13], ";skin_color13;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.1,1.3;0.4,0.5;[fill:1x1:", color_hex[14], ";skin_color14;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.6,1.3;0.4,0.5;[fill:1x1:", color_hex[15], ";skin_color15;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.1,1.3;0.4,0.5;[fill:1x1:", color_hex[16], ";skin_color16;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.6,1.3;0.4,0.5;[fill:1x1:", color_hex[17], ";skin_color17;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.1,1.3;0.4,0.5;[fill:1x1:", color_hex[18], ";skin_color18;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.6,1.3;0.4,0.5;[fill:1x1:", color_hex[19], ";skin_color19;;false;false;[fill:1x1:#ffffff]",
		"image_button[9.1,1.3;0.4,0.5;[fill:1x1:", color_hex[20], ";skin_color20;;false;false;[fill:1x1:#ffffff]",

		"hypertext[4.5,2.2;5,1;label_skin_saturation;",
		"<style color=#AAAAAA size=15><b>Color Saturation</b></style>]",
		"box[", highlight_pos_sat[p_data.avatar_skin_saturation_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,2.6;0.4,0.5;[fill:1x1:#000000;skin_saturation1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,2.6;0.4,0.5;[fill:1x1:#000000;skin_saturation2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,2.6;0.4,0.5;[fill:1x1:#000000;skin_saturation3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,2.6;0.4,0.5;[fill:1x1:#000000;skin_saturation4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,2.6;0.4,0.5;[fill:1x1:#000000;skin_saturation5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,2.6;0.4,0.5;[fill:1x1:#000000;skin_saturation6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,2.6;0.4,0.5;[fill:1x1:#000000;skin_saturation7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,2.6;0.4,0.5;[fill:1x1:#000000;skin_saturation8;8;false;false;[fill:1x1:#222222]",

		"hypertext[4.5,3.4;5,1;label_skin_lightness;",
		"<style color=#AAAAAA size=15><b>Lightness Level</b></style>]",
		"box[", highlight_pos_light[p_data.avatar_skin_lightness_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,3.8;0.4,0.5;[fill:1x1:#000000;skin_lightness1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,3.8;0.4,0.5;[fill:1x1:#000000;skin_lightness2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,3.8;0.4,0.5;[fill:1x1:#000000;skin_lightness3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,3.8;0.4,0.5;[fill:1x1:#000000;skin_lightness4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,3.8;0.4,0.5;[fill:1x1:#000000;skin_lightness5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,3.8;0.4,0.5;[fill:1x1:#000000;skin_lightness6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,3.8;0.4,0.5;[fill:1x1:#000000;skin_lightness7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,3.8;0.4,0.5;[fill:1x1:#000000;skin_lightness8;8;false;false;[fill:1x1:#222222]",

		"hypertext[4.5,4.6;5,1;label_skin_contrast;",
		"<style color=#AAAAAA size=15><b>Contrast Detail</b></style>]",
		"box[", highlight_pos_contrast[p_data.avatar_skin_contrast_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,5.0;0.4,0.5;[fill:1x1:#000000;skin_contrast1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,5.0;0.4,0.5;[fill:1x1:#000000;skin_contrast2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,5.0;0.4,0.5;[fill:1x1:#000000;skin_contrast3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,5.0;0.4,0.5;[fill:1x1:#000000;skin_contrast4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,5.0;0.4,0.5;[fill:1x1:#000000;skin_contrast5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,5.0;0.4,0.5;[fill:1x1:#000000;skin_contrast6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,5.0;0.4,0.5;[fill:1x1:#000000;skin_contrast7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,5.0;0.4,0.5;[fill:1x1:#000000;skin_contrast8;8;false;false;[fill:1x1:#222222]",

		"button_exit[5.4,7.7;3,1;btn_done;Done]"
	})

	debug(flag2, "get_fs_setup_skin() end")
	return formspec
end


local flag3 = false
--- @param p_data table reference to table with data specific to this player
--- @return string formspec the formspec string representing the player setup window that
-- displays during a new game or upon respawning after death.
local function get_fs_setup_hair(p_data)
	debug(flag3, "\nget_fs_setup_hair()")

	debug(flag3, "  avatar_hair_color_selected: " .. p_data.avatar_hair_color_selected)
	debug(flag3, "  selected_contrast: " .. p_data.avatar_hair_contrast_selected)
	debug(flag3, "  selected_type: " .. p_data.avatar_hair_type_selected)

	local formspec = table_concat({
		"formspec_version[7]",
		"size[9.9,9.0,true]",
		"position[0.5,0.4]",
		"tabheader[0,0;player_setup_tabs;Body Type,Skin,Hair,Eyes,Underwear;3;true;true]",
		"box[0.0,0.0;4.25,9.0;#222222]",
		"model[0.2,0.25;4,8;player_avatar;", p_data.avatar_mesh, ";", p_data.avatar_texture_base, ";{0,235};false;true;2,2;0]",

		"hypertext[4.5,0.3;5,1;label_hair_color;",
		"<style color=#AAAAAA size=15><b>Hair Color</b></style>]",
		"box[", highlight_pos_color[p_data.avatar_hair_color_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,0.7;0.4,0.5;[fill:1x1:", color_hex[1], ";hair_color1;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.1,0.7;0.4,0.5;[fill:1x1:", color_hex[2], ";hair_color2;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.6,0.7;0.4,0.5;[fill:1x1:", color_hex[3], ";hair_color3;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.1,0.7;0.4,0.5;[fill:1x1:", color_hex[4], ";hair_color4;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.6,0.7;0.4,0.5;[fill:1x1:", color_hex[5], ";hair_color5;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.1,0.7;0.4,0.5;[fill:1x1:", color_hex[6], ";hair_color6;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.6,0.7;0.4,0.5;[fill:1x1:", color_hex[7], ";hair_color7;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.1,0.7;0.4,0.5;[fill:1x1:", color_hex[8], ";hair_color8;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.6,0.7;0.4,0.5;[fill:1x1:", color_hex[9], ";hair_color9;;false;false;[fill:1x1:#ffffff]",
		"image_button[9.1,0.7;0.4,0.5;[fill:1x1:", color_hex[10], ";hair_color10;;false;false;[fill:1x1:#ffffff]",
		"image_button[4.6,1.3;0.4,0.5;[fill:1x1:", color_hex[11], ";hair_color11;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.1,1.3;0.4,0.5;[fill:1x1:", color_hex[12], ";hair_color12;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.6,1.3;0.4,0.5;[fill:1x1:", color_hex[13], ";hair_color13;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.1,1.3;0.4,0.5;[fill:1x1:", color_hex[14], ";hair_color14;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.6,1.3;0.4,0.5;[fill:1x1:", color_hex[15], ";hair_color15;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.1,1.3;0.4,0.5;[fill:1x1:", color_hex[16], ";hair_color16;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.6,1.3;0.4,0.5;[fill:1x1:", color_hex[17], ";hair_color17;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.1,1.3;0.4,0.5;[fill:1x1:", color_hex[18], ";hair_color18;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.6,1.3;0.4,0.5;[fill:1x1:", color_hex[19], ";hair_color19;;false;false;[fill:1x1:#ffffff]",
		"image_button[9.1,1.3;0.4,0.5;[fill:1x1:", color_hex[20], ";hair_color20;;false;false;[fill:1x1:#ffffff]",

		"hypertext[4.5,2.2;5,1;label_hair_saturation;",
		"<style color=#AAAAAA size=15><b>Color Saturation</b></style>]",
		"box[", highlight_pos_sat[p_data.avatar_hair_saturation_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,2.6;0.4,0.5;[fill:1x1:#000000;hair_saturation1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,2.6;0.4,0.5;[fill:1x1:#000000;hair_saturation2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,2.6;0.4,0.5;[fill:1x1:#000000;hair_saturation3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,2.6;0.4,0.5;[fill:1x1:#000000;hair_saturation4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,2.6;0.4,0.5;[fill:1x1:#000000;hair_saturation5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,2.6;0.4,0.5;[fill:1x1:#000000;hair_saturation6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,2.6;0.4,0.5;[fill:1x1:#000000;hair_saturation7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,2.6;0.4,0.5;[fill:1x1:#000000;hair_saturation8;8;false;false;[fill:1x1:#222222]",

		"hypertext[4.5,3.4;5,1;label_hair_lightness;",
		"<style color=#AAAAAA size=15><b>Lightness Level</b></style>]",
		"box[", highlight_pos_light[p_data.avatar_hair_lightness_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,3.8;0.4,0.5;[fill:1x1:#000000;hair_lightness1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,3.8;0.4,0.5;[fill:1x1:#000000;hair_lightness2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,3.8;0.4,0.5;[fill:1x1:#000000;hair_lightness3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,3.8;0.4,0.5;[fill:1x1:#000000;hair_lightness4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,3.8;0.4,0.5;[fill:1x1:#000000;hair_lightness5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,3.8;0.4,0.5;[fill:1x1:#000000;hair_lightness6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,3.8;0.4,0.5;[fill:1x1:#000000;hair_lightness7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,3.8;0.4,0.5;[fill:1x1:#000000;hair_lightness8;8;false;false;[fill:1x1:#222222]",

		"hypertext[4.5,4.6;5,1;label_hair_contrast;",
		"<style color=#AAAAAA size=15><b>Contrast Detail</b></style>]",
		"box[", highlight_pos_contrast[p_data.avatar_hair_contrast_selected], ";0.50,0.6;#ffffff]",
		"image_button[4.6,5.0;0.4,0.5;[fill:1x1:#000000;hair_contrast1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,5.0;0.4,0.5;[fill:1x1:#000000;hair_contrast2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,5.0;0.4,0.5;[fill:1x1:#000000;hair_contrast3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,5.0;0.4,0.5;[fill:1x1:#000000;hair_contrast4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,5.0;0.4,0.5;[fill:1x1:#000000;hair_contrast5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,5.0;0.4,0.5;[fill:1x1:#000000;hair_contrast6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,5.0;0.4,0.5;[fill:1x1:#000000;hair_contrast7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,5.0;0.4,0.5;[fill:1x1:#000000;hair_contrast8;8;false;false;[fill:1x1:#222222]",

		"hypertext[4.5,5.8;5,1;label_hair_type;",
		"<style color=#AAAAAA size=15><b>Hair Type</b></style>]",
		"box[", highlight_pos_hair_type[p_data.avatar_hair_type_selected], ";0.50,0.6;#ffffff]",
		"image_button[4.6,6.2;0.4,0.5;[fill:1x1:#000000;hair_type1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,6.2;0.4,0.5;[fill:1x1:#000000;hair_type2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,6.2;0.4,0.5;[fill:1x1:#000000;hair_type3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,6.2;0.4,0.5;[fill:1x1:#000000;hair_type4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,6.2;0.4,0.5;[fill:1x1:#000000;hair_type5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,6.2;0.4,0.5;[fill:1x1:#000000;hair_type6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,6.2;0.4,0.5;[fill:1x1:#000000;hair_type7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,6.2;0.4,0.5;[fill:1x1:#000000;hair_type8;8;false;false;[fill:1x1:#222222]",

		"image_button[4.6,6.8;0.4,0.5;[fill:1x1:#000000;hair_type9;9;false;false;[fill:1x1:#222222]",
		"image_button[5.1,6.8;0.4,0.5;[fill:1x1:#000000;hair_type10;10;false;false;[fill:1x1:#222222]",
		"image_button[5.6,6.8;0.4,0.5;[fill:1x1:#000000;hair_type11;11;false;false;[fill:1x1:#222222]",

		"button_exit[5.4,7.7;3,1;btn_done;Done]"
	})

	debug(flag3, "get_fs_setup_hair() end")
	return formspec
end


local flag4 = false
--- @param p_data table reference to table with data specific to this player
--- @return string formspec the formspec string representing the player setup window that
-- displays during a new game or upon respawning after death.
local function get_fs_setup_eyes(p_data)
	debug(flag4, "\nget_fs_setup_eyes()")

	local formspec = table_concat({
		"formspec_version[7]",
		"size[9.9,9.0,true]",
		"position[0.5,0.4]",
		"tabheader[0,0;player_setup_tabs;Body Type,Skin,Hair,Eyes,Underwear;4;true;true]",
		"box[0.0,0.0;4.25,9.0;#222222]",
		"model[0.2,0.25;4,8;player_avatar;", p_data.avatar_mesh, ";", p_data.avatar_texture_base, ";{0,180};false;true;2,2;0]",

		"hypertext[4.5,0.3;5,1;label_eye_color;",
		"<style color=#AAAAAA size=15><b>Eye Color</b></style>]",
		"box[", highlight_pos_color[p_data.avatar_eye_color_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,0.7;0.4,0.5;[fill:1x1:", color_hex[1], ";eye_color1;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.1,0.7;0.4,0.5;[fill:1x1:", color_hex[2], ";eye_color2;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.6,0.7;0.4,0.5;[fill:1x1:", color_hex[3], ";eye_color3;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.1,0.7;0.4,0.5;[fill:1x1:", color_hex[4], ";eye_color4;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.6,0.7;0.4,0.5;[fill:1x1:", color_hex[5], ";eye_color5;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.1,0.7;0.4,0.5;[fill:1x1:", color_hex[6], ";eye_color6;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.6,0.7;0.4,0.5;[fill:1x1:", color_hex[7], ";eye_color7;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.1,0.7;0.4,0.5;[fill:1x1:", color_hex[8], ";eye_color8;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.6,0.7;0.4,0.5;[fill:1x1:", color_hex[9], ";eye_color9;;false;false;[fill:1x1:#ffffff]",
		"image_button[9.1,0.7;0.4,0.5;[fill:1x1:", color_hex[10], ";eye_color10;;false;false;[fill:1x1:#ffffff]",
		"image_button[4.6,1.3;0.4,0.5;[fill:1x1:", color_hex[11], ";eye_color11;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.1,1.3;0.4,0.5;[fill:1x1:", color_hex[12], ";eye_color12;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.6,1.3;0.4,0.5;[fill:1x1:", color_hex[13], ";eye_color13;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.1,1.3;0.4,0.5;[fill:1x1:", color_hex[14], ";eye_color14;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.6,1.3;0.4,0.5;[fill:1x1:", color_hex[15], ";eye_color15;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.1,1.3;0.4,0.5;[fill:1x1:", color_hex[16], ";eye_color16;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.6,1.3;0.4,0.5;[fill:1x1:", color_hex[17], ";eye_color17;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.1,1.3;0.4,0.5;[fill:1x1:", color_hex[18], ";eye_color18;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.6,1.3;0.4,0.5;[fill:1x1:", color_hex[19], ";eye_color19;;false;false;[fill:1x1:#ffffff]",
		"image_button[9.1,1.3;0.4,0.5;[fill:1x1:", color_hex[20], ";eye_color20;;false;false;[fill:1x1:#ffffff]",

		"hypertext[4.5,2.2;5,1;label_eye_saturation;",
		"<style color=#AAAAAA size=15><b>Color Saturation</b></style>]",
		"box[", highlight_pos_sat[p_data.avatar_eye_saturation_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,2.6;0.4,0.5;[fill:1x1:#000000;eye_saturation1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,2.6;0.4,0.5;[fill:1x1:#000000;eye_saturation2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,2.6;0.4,0.5;[fill:1x1:#000000;eye_saturation3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,2.6;0.4,0.5;[fill:1x1:#000000;eye_saturation4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,2.6;0.4,0.5;[fill:1x1:#000000;eye_saturation5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,2.6;0.4,0.5;[fill:1x1:#000000;eye_saturation6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,2.6;0.4,0.5;[fill:1x1:#000000;eye_saturation7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,2.6;0.4,0.5;[fill:1x1:#000000;eye_saturation8;8;false;false;[fill:1x1:#222222]",

		"hypertext[4.5,3.4;5,1;label_eye_lightness;",
		"<style color=#AAAAAA size=15><b>Lightness Level</b></style>]",
		"box[", highlight_pos_light[p_data.avatar_eye_lightness_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,3.8;0.4,0.5;[fill:1x1:#000000;eye_lightness1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,3.8;0.4,0.5;[fill:1x1:#000000;eye_lightness2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,3.8;0.4,0.5;[fill:1x1:#000000;eye_lightness3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,3.8;0.4,0.5;[fill:1x1:#000000;eye_lightness4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,3.8;0.4,0.5;[fill:1x1:#000000;eye_lightness5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,3.8;0.4,0.5;[fill:1x1:#000000;eye_lightness6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,3.8;0.4,0.5;[fill:1x1:#000000;eye_lightness7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,3.8;0.4,0.5;[fill:1x1:#000000;eye_lightness8;8;false;false;[fill:1x1:#222222]",

		"button_exit[5.4,7.7;3,1;btn_done;Done]"
	})

	debug(flag4, "get_fs_setup_eyes() end")
	return formspec
end


local flag5 = false
--- @param p_data table reference to table with data specific to this player
--- @return string formspec the formspec string representing the player setup window that
-- displays during a new game or upon respawning after death.
local function get_fs_setup_underwear(p_data)
	debug(flag5, "\nget_fs_setup_underwear()")
	debug(flag5, "  avatar_underwear_color_selected: " .. p_data.avatar_underwear_color_selected)
	debug(flag5, "  avatar_underwear_saturation_selected: " .. p_data.avatar_underwear_saturation_selected)
	debug(flag5, "  avatar_underwear_lightness_selected: " .. p_data.avatar_underwear_lightness_selected)
	debug(flag5, "  avatar_underwear_contrast_selected: " .. p_data.avatar_underwear_contrast_selected)

	local formspec = table_concat({
		"formspec_version[7]",
		"size[9.9,9.0,true]",
		"position[0.5,0.4]",
		"tabheader[0,0;player_setup_tabs;Body Type,Skin,Hair,Eyes,Underwear;5;true;true]",
		"box[0.0,0.0;4.25,9.0;#222222]",
		"model[0.2,0.25;4,8;player_avatar;", p_data.avatar_mesh, ";", p_data.avatar_texture_base, ";{0,200};false;true;2,2;0]",

		"hypertext[4.5,0.3;5,1;label_underwear_color;",
		"<style color=#AAAAAA size=15><b>Underwear Color</b></style>]",
		"box[", highlight_pos_color[p_data.avatar_underwear_color_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,0.7;0.4,0.5;[fill:1x1:", color_hex[1], ";underwear_color1;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.1,0.7;0.4,0.5;[fill:1x1:", color_hex[2], ";underwear_color2;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.6,0.7;0.4,0.5;[fill:1x1:", color_hex[3], ";underwear_color3;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.1,0.7;0.4,0.5;[fill:1x1:", color_hex[4], ";underwear_color4;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.6,0.7;0.4,0.5;[fill:1x1:", color_hex[5], ";underwear_color5;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.1,0.7;0.4,0.5;[fill:1x1:", color_hex[6], ";underwear_color6;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.6,0.7;0.4,0.5;[fill:1x1:", color_hex[7], ";underwear_color7;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.1,0.7;0.4,0.5;[fill:1x1:", color_hex[8], ";underwear_color8;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.6,0.7;0.4,0.5;[fill:1x1:", color_hex[9], ";underwear_color9;;false;false;[fill:1x1:#ffffff]",
		"image_button[9.1,0.7;0.4,0.5;[fill:1x1:", color_hex[10], ";underwear_color10;;false;false;[fill:1x1:#ffffff]",
		"image_button[4.6,1.3;0.4,0.5;[fill:1x1:", color_hex[11], ";underwear_color11;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.1,1.3;0.4,0.5;[fill:1x1:", color_hex[12], ";underwear_color12;;false;false;[fill:1x1:#ffffff]",
		"image_button[5.6,1.3;0.4,0.5;[fill:1x1:", color_hex[13], ";underwear_color13;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.1,1.3;0.4,0.5;[fill:1x1:", color_hex[14], ";underwear_color14;;false;false;[fill:1x1:#ffffff]",
		"image_button[6.6,1.3;0.4,0.5;[fill:1x1:", color_hex[15], ";underwear_color15;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.1,1.3;0.4,0.5;[fill:1x1:", color_hex[16], ";underwear_color16;;false;false;[fill:1x1:#ffffff]",
		"image_button[7.6,1.3;0.4,0.5;[fill:1x1:", color_hex[17], ";underwear_color17;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.1,1.3;0.4,0.5;[fill:1x1:", color_hex[18], ";underwear_color18;;false;false;[fill:1x1:#ffffff]",
		"image_button[8.6,1.3;0.4,0.5;[fill:1x1:", color_hex[19], ";underwear_color19;;false;false;[fill:1x1:#ffffff]",
		"image_button[9.1,1.3;0.4,0.5;[fill:1x1:", color_hex[20], ";underwear_color20;;false;false;[fill:1x1:#ffffff]",

		"hypertext[4.5,2.2;5,1;label_underwear_saturation;",
		"<style color=#AAAAAA size=15><b>Color Saturation</b></style>]",
		"box[", highlight_pos_sat[p_data.avatar_underwear_saturation_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,2.6;0.4,0.5;[fill:1x1:#000000;underwear_saturation1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,2.6;0.4,0.5;[fill:1x1:#000000;underwear_saturation2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,2.6;0.4,0.5;[fill:1x1:#000000;underwear_saturation3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,2.6;0.4,0.5;[fill:1x1:#000000;underwear_saturation4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,2.6;0.4,0.5;[fill:1x1:#000000;underwear_saturation5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,2.6;0.4,0.5;[fill:1x1:#000000;underwear_saturation6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,2.6;0.4,0.5;[fill:1x1:#000000;underwear_saturation7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,2.6;0.4,0.5;[fill:1x1:#000000;underwear_saturation8;8;false;false;[fill:1x1:#222222]",

		"hypertext[4.5,3.4;5,1;label_underwear_lightness;",
		"<style color=#AAAAAA size=15><b>Lightness Level</b></style>]",
		"box[", highlight_pos_light[p_data.avatar_underwear_lightness_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,3.8;0.4,0.5;[fill:1x1:#000000;underwear_lightness1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,3.8;0.4,0.5;[fill:1x1:#000000;underwear_lightness2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,3.8;0.4,0.5;[fill:1x1:#000000;underwear_lightness3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,3.8;0.4,0.5;[fill:1x1:#000000;underwear_lightness4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,3.8;0.4,0.5;[fill:1x1:#000000;underwear_lightness5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,3.8;0.4,0.5;[fill:1x1:#000000;underwear_lightness6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,3.8;0.4,0.5;[fill:1x1:#000000;underwear_lightness7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,3.8;0.4,0.5;[fill:1x1:#000000;underwear_lightness8;8;false;false;[fill:1x1:#222222]",

		"hypertext[4.5,4.6;5,1;label_underwear_contrast;",
		"<style color=#AAAAAA size=15><b>Contrast Detail</b></style>]",
		"box[", highlight_pos_contrast[p_data.avatar_underwear_contrast_selected], ";0.5,0.6;#ffffff]",
		"image_button[4.6,5.0;0.4,0.5;[fill:1x1:#000000;underwear_contrast1;1;false;false;[fill:1x1:#222222]",
		"image_button[5.1,5.0;0.4,0.5;[fill:1x1:#000000;underwear_contrast2;2;false;false;[fill:1x1:#222222]",
		"image_button[5.6,5.0;0.4,0.5;[fill:1x1:#000000;underwear_contrast3;3;false;false;[fill:1x1:#222222]",
		"image_button[6.1,5.0;0.4,0.5;[fill:1x1:#000000;underwear_contrast4;4;false;false;[fill:1x1:#222222]",
		"image_button[6.6,5.0;0.4,0.5;[fill:1x1:#000000;underwear_contrast5;5;false;false;[fill:1x1:#222222]",
		"image_button[7.1,5.0;0.4,0.5;[fill:1x1:#000000;underwear_contrast6;6;false;false;[fill:1x1:#222222]",
		"image_button[7.6,5.0;0.4,0.5;[fill:1x1:#000000;underwear_contrast7;7;false;false;[fill:1x1:#222222]",
		"image_button[8.1,5.0;0.4,0.5;[fill:1x1:#000000;underwear_contrast8;8;false;false;[fill:1x1:#222222]",

		"button_exit[5.4,7.7;3,1;btn_done;Done]"
	})

	debug(flag5, "get_fs_setup_underwear() end")
	return formspec
end


local flag6 = false
--- @param new_body_type number the new body type to pull the textures from
local function get_avatar_texture_base(p_data, new_body_type)
	debug(flag6, "\n  get_avatar_texture_base()")

	local mesh_texture
	local underwear_colorized, skin_colorized, hair_colorized, eyes_colorized

	-- get texture info from stored player data
	if new_body_type == 0 then
		debug(flag6, "    did not change body type")

		-- SKIN --
		skin_colorized = table_concat({ p_data.avatar_texture_skin,
		"^[contrast:",
		p_data.avatar_texture_skin_contrast,
		"^[colorizehsl:",
		p_data.avatar_texture_skin_hue, ":",
		p_data.avatar_texture_skin_sat + p_data.avatar_texture_skin_sat_mod, ":",
		p_data.avatar_texture_skin_light + p_data.avatar_texture_skin_light_mod,
		"^[mask:", p_data.avatar_texture_skin_mask })
		debug(flag6, "  avatar_texture_skin: " .. p_data.avatar_texture_skin)
		debug(flag6, "  avatar_texture_skin_mask: " .. p_data.avatar_texture_skin_mask)

		-- HAIR --
		hair_colorized = table_concat({p_data.avatar_texture_hair,
		"^[contrast:",
		p_data.avatar_texture_hair_contrast,
		"^[colorizehsl:",
		p_data.avatar_texture_hair_hue, ":",
		p_data.avatar_texture_hair_sat + p_data.avatar_texture_hair_sat_mod, ":",
		p_data.avatar_texture_hair_light + p_data.avatar_texture_hair_light_mod,
		"^[mask:", p_data.avatar_texture_hair_mask })
		debug(flag6, "  avatar_texture_hair: " .. p_data.avatar_texture_hair)
		debug(flag6, "  avatar_texture_hair_mask: " .. p_data.avatar_texture_hair_mask)

		-- EYES --
		eyes_colorized = table_concat({ p_data.avatar_texture_eye,
		"^[colorizehsl:",
		p_data.avatar_texture_eye_hue, ":",
		p_data.avatar_texture_eye_sat + p_data.avatar_texture_eye_sat_mod, ":",
		p_data.avatar_texture_eye_light + p_data.avatar_texture_eye_light_mod,
		"^[mask:", p_data.avatar_texture_eye })

		-- UNDERWEAR --
		underwear_colorized = table_concat({ p_data.avatar_texture_underwear,
		"^[contrast:",
		p_data.avatar_texture_underwear_contrast,
		"^[colorizehsl:",
		p_data.avatar_texture_underwear_hue, ":",
		p_data.avatar_texture_underwear_sat + p_data.avatar_texture_underwear_sat_mod, ":",
		p_data.avatar_texture_underwear_light + p_data.avatar_texture_underwear_light_mod,
		"^[mask:", p_data.avatar_texture_underwear_mask })
		debug(flag6, "  avatar_texture_underwear: " .. p_data.avatar_texture_underwear)
		debug(flag6, "  avatar_texture_underwear_mask: " .. p_data.avatar_texture_underwear_mask)

	-- get texture info based on the chosen body type, and update stored player data
	-- with the new constructed texture info
	else
		debug(flag6, "    changed body type")

		-- SKIN --
		debug(flag6, "    updating skin texture")
		skin_colorized =  table_concat({ p_data.avatar_texture_skin,
			"^[contrast:",
			p_data.avatar_texture_skin_contrast,
			"^[colorizehsl:",
			p_data.avatar_texture_skin_hue, ":",
			p_data.avatar_texture_skin_sat + p_data.avatar_texture_skin_sat_mod, ":",
			p_data.avatar_texture_skin_light + p_data.avatar_texture_skin_light_mod,
			"^[mask:", p_data.avatar_texture_skin_mask
		})
		debug(flag6, "  avatar_texture_skin: " .. p_data.avatar_texture_skin)
		debug(flag6, "  avatar_texture_skin_mask: " .. p_data.avatar_texture_skin_mask)

		-- HAIR --
		debug(flag6, "    updating hair texture")
		hair_colorized = table_concat({	p_data.avatar_texture_hair,
			"^[contrast:",
			p_data.avatar_texture_hair_contrast,
			"^[colorizehsl:",
			p_data.avatar_texture_hair_hue, ":",
			p_data.avatar_texture_hair_sat + p_data.avatar_texture_hair_sat_mod, ":",
			p_data.avatar_texture_hair_light + p_data.avatar_texture_hair_light_mod,
			"^[mask:" .. p_data.avatar_texture_hair_mask
		})

		-- EYES --
		debug(flag6, "    updating eyes texture")
		eyes_colorized = table_concat({ p_data.avatar_texture_eye,
			"^[colorizehsl:",
			p_data.avatar_texture_eye_hue, ":",
			p_data.avatar_texture_eye_sat + p_data.avatar_texture_eye_sat_mod, ":",
			p_data.avatar_texture_eye_light + p_data.avatar_texture_eye_light_mod,
			"^[mask:" .. p_data.avatar_texture_eye
		})

		-- UNDERWEAR --
		debug(flag6, "    updating underwear texture")
		underwear_colorized = table_concat({ p_data.avatar_texture_underwear,
			"^[contrast:",
			p_data.avatar_texture_underwear_contrast,
			"^[colorizehsl:",
			p_data.avatar_texture_underwear_hue, ":",
			p_data.avatar_texture_underwear_sat + p_data.avatar_texture_underwear_sat_mod, ":",
			p_data.avatar_texture_underwear_light + p_data.avatar_texture_underwear_light_mod,
			"^[mask:", p_data.avatar_texture_underwear_mask
		})
		debug(flag6, "  avatar_texture_underwear: " .. p_data.avatar_texture_underwear)
		debug(flag6, "  avatar_texture_underwear_mask: " .. p_data.avatar_texture_underwear_mask)

	end

	mesh_texture = table_concat({
		"(", skin_colorized, ")^(", p_data.avatar_texture_face, ")^(", eyes_colorized, ")^(", hair_colorized, ")^(", underwear_colorized, ")"
	})

	debug(flag6, "  get_avatar_texture_base() end")
	return mesh_texture
end


local flag7 = false
local function refresh_formspec(player, player_meta, player_name, p_data, active_fs_tab)
	debug(flag7, "\n  refresh_formspec()")

	-- re-display the player setup window based on which tab is active
	local player_setup_fs = ""
	if active_fs_tab == "body_type" then
		player_setup_fs = get_fs_setup_body(p_data)

	elseif active_fs_tab == "skin" then
		player_setup_fs = get_fs_setup_skin(p_data)

	elseif active_fs_tab == "hair" then
		player_setup_fs = get_fs_setup_hair(p_data)

	elseif active_fs_tab == "eye" then
		player_setup_fs = get_fs_setup_eyes(p_data)

	elseif active_fs_tab == "underwear" then
		player_setup_fs = get_fs_setup_underwear(p_data)

	else
		debug(flag7, "    ERROR - Unexpected 'active_fs_tab' value: " .. active_fs_tab)
	end

	mt_show_formspec(player_name, "ss:ui_player_setup", player_setup_fs)
	debug(flag7, "  refresh_formspec() end")
end


local flag28 = false
-- target: 'skin', 'hair', 'eye', 'underwear', 'body'
-- attribute: 'color', 'saturation', 'lightness', 'contrast', 'type'
-- attribute_data: a table
-- selected_attrib: 'color1', 'saturation3', 'lightness6', 'contrast8', etc
local function update_player(player, player_name, target, attribute, attribute_data, selected_attrib)
	debug(flag28, "  update_player()")
	debug(flag28, "  target: " .. target)
	debug(flag28, "  color_aspect: " .. attribute)
	debug(flag28, "  selected_attrib: " .. selected_attrib)
	debug(flag28, "  attribute_data: " .. dump(attribute_data))
	local p_data = ss.player_data[player_name]

	-- the sub-table name within p_data that holds the selected option string
	-- example: "avatar_skin_contrast_selected", "avatar_eye_color_selected", etc.
	local pdata_subt_selected = table_concat({ "avatar_", target, "_", attribute, "_selected" })
	debug(flag28, "  pdata_object: " .. pdata_subt_selected)

	if p_data[pdata_subt_selected] == selected_attrib then
		debug(flag28, selected_attrib .. " already selected. NO CHANGE.")

	else
		debug(flag28, "  clicked on DIFFERENT option.")

		local player_meta = player:get_meta()
		local update_body_type_flag = 0
		local base_texture

		-- the sub-table name within p_data that holds the value of the color property
		-- examples: "avatar_texture_underwear_contrast", "avatar_texture_skin_sat_mod", etc
		local pdata_subt_value

		if attribute == "saturation" then
			debug(flag28, "  updating " .. target .. " SATURATION")
			pdata_subt_value = "avatar_texture_" .. target .. "_sat_mod"
			player_meta:set_int(pdata_subt_value, attribute_data[1])

		elseif attribute == "lightness" then
			debug(flag28, "  updating " .. target .. " LIGHTNESS")
			pdata_subt_value = "avatar_texture_" .. target .. "_light_mod"
			player_meta:set_int(pdata_subt_value, attribute_data[1])

		elseif attribute == "contrast" then
			debug(flag28, "  updating " .. target .. " CONTRAST")
			pdata_subt_value = "avatar_texture_" .. target .. "_contrast"
			player_meta:set_string(pdata_subt_value, attribute_data[1])

		elseif attribute == "color" then
			debug(flag28, "  updating " .. target .. " COLOR")
			pdata_subt_value = "avatar_texture_" .. target .. "_hue"
			player_meta:set_int(pdata_subt_value, attribute_data[1])

			-- update additional data associated with 'color' attribute
			p_data["avatar_texture_" .. target .. "_sat"] = attribute_data[2]
			p_data["avatar_texture_" .. target .. "_light"] = attribute_data[3]
			player_meta:set_int("avatar_texture_" .. target .. "_sat", attribute_data[2])
			player_meta:set_int("avatar_texture_" .. target .. "_light", attribute_data[3])

		elseif attribute == "type" then
			if target == "hair" then
				debug(flag28, "  updating " .. target .. " TYPE")
				pdata_subt_value = "avatar_texture_" .. target .. "_type"
				player_meta:set_int(pdata_subt_value, attribute_data[1])

				-- update additional data associated with 'hair' type attribute
				local new_texuture = table_concat({ "ss_player_hair_", attribute_data[1], ".png" })
				local new_mask = table_concat({ "ss_player_hair_" .. attribute_data[1] .. "_mask.png" })
				debug(flag28, "  new_texuture: " .. new_texuture)
				debug(flag28, "  new_mask: " .. new_mask)
				p_data["avatar_texture_" .. target] = new_texuture
				p_data["avatar_texture_" .. target .. "_mask"] = new_mask
				player_meta:set_string("avatar_texture_" .. target, p_data["avatar_texture_" .. target])
				player_meta:set_string("avatar_texture_" .. target .. "_mask", p_data["avatar_texture_" .. target .. "_mask"])

			elseif target == "body" then
				debug(flag28, "  updating " .. target .. " TYPE")
				pdata_subt_value = target .. "_type"
				player_meta:set_int(pdata_subt_value, attribute_data[1])

				-- update additional data associated with 'body' type attribute
				p_data.avatar_mesh = BODY_TYPES[attribute_data[1]]
				player_meta:set_string("avatar_mesh", p_data.avatar_mesh)

				p_data.avatar_texture_skin = "ss_player_skin_" .. attribute_data[1] .. ".png"
				p_data.avatar_texture_skin_mask = "ss_player_skin_" .. attribute_data[1] .. "_mask.png"
				player_meta:set_string("avatar_texture_skin", p_data.avatar_texture_skin)
				player_meta:set_string("avatar_texture_skin_mask", p_data.avatar_texture_skin_mask)

				p_data.avatar_texture_underwear = "ss_player_underwear_" .. attribute_data[1] .. ".png"
				p_data.avatar_texture_underwear_mask = "ss_player_underwear_" .. attribute_data[1] .. "_mask.png"
				player_meta:set_string("avatar_texture_underwear", p_data.avatar_texture_underwear)
				player_meta:set_string("avatar_texture_underwear_mask", p_data.avatar_texture_underwear_mask)

				p_data.avatar_texture_eye = "ss_player_eyes_" .. attribute_data[1] .. ".png"
				player_meta:set_string("avatar_texture_eye", p_data.avatar_texture_eye)

				p_data.avatar_texture_face = "ss_player_face_" .. attribute_data[1] .. ".png"
				player_meta:set_string("avatar_texture_face", p_data.avatar_texture_face)

				update_body_type_flag = attribute_data[1]
				target = "body_type"

			else
				debug(flag28, "  ERROR - Unexpected 'target' value: " .. target)
			end

		else
			debug(flag28, "  ERROR - Unexpected 'attribute' value: " .. attribute)
		end

		p_data[pdata_subt_value] = attribute_data[1]
		base_texture = get_avatar_texture_base(p_data, update_body_type_flag)
		p_data.avatar_texture_base = base_texture

		player_meta:set_string("avatar_texture_base", base_texture)
		player:set_properties({ textures = {base_texture}, mesh = p_data.avatar_mesh })
		p_data[pdata_subt_selected] = selected_attrib
		player_meta:set_string(pdata_subt_selected, selected_attrib)

		refresh_formspec(player, player_meta, player_name, p_data, target)
		debug(flag28, "  base_texture: " .. base_texture)

	end

	debug(flag28, "  update_player() end")
end


local flag16 = false
core.register_on_joinplayer(function(player)
	debug(flag16, "\nregister_on_joinplayer() player_setup.lua")
	local player_name = player:get_player_name()
	local player_meta = player:get_meta()
	local p_data = ss.player_data[player_name]
	local player_status = p_data.player_status

	if player_status == 0 then
		debug(flag16, "  new player")

		-- construct final base texture file from the separate texture parts
		local avatar_texture_base = get_avatar_texture_base(p_data, 0)
		p_data.avatar_texture_base = avatar_texture_base
		player_meta:set_string("avatar_texture_base", avatar_texture_base)
		debug(flag16, "  avatar_texture_base: " .. dump(avatar_texture_base))

		-- show player setup screen
		p_data.active_tab = "player_setup"
		local formspec = get_fs_setup_body(p_data)
		mt_show_formspec(player_name, "ss:ui_player_setup", formspec)
		current_tab[player_name] = "body"

	elseif player_status == 1 then
		debug(flag16, "  existing player")
		p_data.avatar_texture_base = get_avatar_texture_base(p_data, 0)
		debug(flag16, "  avatar_texture_base: " .. p_data.avatar_texture_base)

	elseif player_status == 2 then
		debug(flag16, "  dead player")

	else
	end

	-- wait 1 second to allow engine to load player object before setting its properties
	mt_after(1, function()
		if not player:is_player() then
			debug(flag16, "  player no longer exists. function skipped.")
			return
		end
		player:set_properties({
			visual = "mesh",
			visual_size = {x = 1, y = 1},
			physical = false,
			mesh = p_data.avatar_mesh,
			textures = {p_data.avatar_texture_base}
		})
	end)

	debug(flag16, "register_on_joinplayer() end")
end)


local flag15 = false
core.register_on_player_receive_fields(function(player, formname, fields)
    debug(flag15, "\nregister_on_player_receive_fields() player_setup.lua")
	local player_name = player:get_player_name()
	local p_data = ss.player_data[player_name]
	--debug(flag15, "  fields: " .. dump(fields))

	debug(flag15, "  formname: " .. formname)
	debug(flag15, "  formspec_mode: " .. p_data.formspec_mode)
	debug(flag15, "  active_tab: " .. p_data.active_tab)

	if p_data.formspec_mode ~= "player_setup" then
        debug(flag15, "  interaction not from player setup formspec. NO FURTHER ACTION.")
        debug(flag15, "register_on_player_receive_fields() end " .. mt_get_gametime())
        return
    else
        debug(flag15, "  interaction from player setup formspec. inspecting fields..")
    end

	if fields.quit then
		if fields.btn_done then
			debug(flag15, "  exited via DONE button")

			-- update the left side avatar model display of player inventory formspec
			local fs = p_data.fs
			fs.left.player_avatar = get_fs_player_avatar(p_data.avatar_mesh, p_data.avatar_texture_base)
			local formspec = build_fs(fs)
			local player_meta = player:get_meta()
			player_meta:set_string("fs", mt_serialize(fs))
			player:set_inventory_formspec(formspec)

			p_data.formspec_mode = "main_formspec"
			p_data.active_tab = "main"
			current_tab[player_name] = nil
			debug(flag15, "  current_tab: " .. dump(current_tab))

		else
			debug(flag15, "  exited via ESC key or click outside of window")
			debug(flag15, "  current_tab: " .. dump(current_tab))
			local tab_name = current_tab[player_name]
			debug(flag15, "  tab_name: " .. tab_name)

			local formspec
			if tab_name == "body" then
				formspec = get_fs_setup_body(p_data)
				debug(flag15, "  showing body tab")
			elseif tab_name == "skin" then
				formspec = get_fs_setup_skin(p_data)
				debug(flag15, "  showing skin tab")
			elseif tab_name == "hair" then
				formspec = get_fs_setup_hair(p_data)
				debug(flag15, "  showing hair tab")
			elseif tab_name == "eyes" then
				formspec = get_fs_setup_eyes(p_data)
				debug(flag15, "  showing eyes tab")
			elseif tab_name == "underwear" then
				formspec = get_fs_setup_underwear(p_data)
				debug(flag15, "  showing underwear tab")
			else
				debug(flag15, "  ERROR: Unexpected 'tab_name' value: " .. tab_name)
				debug(flag15, "  showing Skin setup tab as default")
				formspec = get_fs_setup_skin(p_data)
			end
			mt_show_formspec(player_name, "ss:ui_player_setup", formspec)
			notify(player,"press DONE button when ready", 4, 0, 0.5, 3)
		end

	else
		play_sound("button", {player_name = player_name})
		local tab_name = current_tab[player_name]
		debug(flag15, "  source tab_name: " .. tab_name)

		if fields.player_setup_tabs == "1" then
			debug(flag15, "  chose setup tab 1 - Body Type")
			current_tab[player_name] = "body"
			local formspec = get_fs_setup_body(p_data)
			mt_show_formspec(player_name, "ss:ui_player_setup", formspec)

		elseif fields.player_setup_tabs == "2" then
			debug(flag15, "  chose setup tab 2 - Skin")
			current_tab[player_name] = "skin"
			local formspec = get_fs_setup_skin(p_data)
			mt_show_formspec(player_name, "ss:ui_player_setup", formspec)

		elseif fields.player_setup_tabs == "3" then
			debug(flag15, "  chose setup tab 3 - Hair")
			current_tab[player_name] = "hair"
			local formspec = get_fs_setup_hair(p_data)
			mt_show_formspec(player_name, "ss:ui_player_setup", formspec)

		elseif fields.player_setup_tabs == "4" then
			debug(flag15, "  chose setup tab 4 - Eyes")
			current_tab[player_name] = "eyes"
			local formspec = get_fs_setup_eyes(p_data)
			mt_show_formspec(player_name, "ss:ui_player_setup", formspec)

		elseif fields.player_setup_tabs == "5" then
			debug(flag15, "  chose setup tab 5 - Underwear")
			current_tab[player_name] = "underwear"
			local formspec = get_fs_setup_underwear(p_data)
			mt_show_formspec(player_name, "ss:ui_player_setup", formspec)

		elseif tab_name == "body" then
			-- BODY TYPES --
			if fields.body_type1 then
				update_player(player, player_name, "body", "type", {1}, "body_type1")
			elseif fields.body_type2 then
				update_player(player, player_name, "body", "type", {2}, "body_type2")

			else
				debug(flag15, "ERROR - Unexpected formspec interaction for 'body'")
			end

		elseif tab_name == "skin" then
			debug(flag15, "  interacted with a 'skin' element")

			-- SKIN COLOR --
			if fields.skin_color1 then
				update_player(player, player_name, "skin", "color", color_hsl[1], "color1")
			elseif fields.skin_color2 then
				update_player(player, player_name, "skin", "color", color_hsl[2], "color2")
			elseif fields.skin_color3 then
				update_player(player, player_name, "skin", "color", color_hsl[3], "color3")
			elseif fields.skin_color4 then
				update_player(player, player_name, "skin", "color", color_hsl[4], "color4")
			elseif fields.skin_color5 then
				update_player(player, player_name, "skin", "color", color_hsl[5], "color5")
			elseif fields.skin_color6 then
				update_player(player, player_name, "skin", "color", color_hsl[6], "color6")
			elseif fields.skin_color7 then
				update_player(player, player_name, "skin", "color", color_hsl[7], "color7")
			elseif fields.skin_color8 then
				update_player(player, player_name, "skin", "color", color_hsl[8], "color8")
			elseif fields.skin_color9 then
				update_player(player, player_name, "skin", "color", color_hsl[9], "color9")
			elseif fields.skin_color10 then
				update_player(player, player_name, "skin", "color", color_hsl[10], "color10")
			elseif fields.skin_color11 then
				update_player(player, player_name, "skin", "color", color_hsl[11], "color11")
			elseif fields.skin_color12 then
				update_player(player, player_name, "skin", "color", color_hsl[12], "color12")
			elseif fields.skin_color13 then
				update_player(player, player_name, "skin", "color", color_hsl[13], "color13")
			elseif fields.skin_color14 then
				update_player(player, player_name, "skin", "color", color_hsl[14], "color14")
			elseif fields.skin_color15 then
				update_player(player, player_name, "skin", "color", color_hsl[15], "color15")
			elseif fields.skin_color16 then
				update_player(player, player_name, "skin", "color", color_hsl[16], "color16")
			elseif fields.skin_color17 then
				update_player(player, player_name, "skin", "color", color_hsl[17], "color17")
			elseif fields.skin_color18 then
				update_player(player, player_name, "skin", "color", color_hsl[18], "color18")
			elseif fields.skin_color19 then
				update_player(player, player_name, "skin", "color", color_hsl[19], "color19")
			elseif fields.skin_color20 then
				update_player(player, player_name, "skin", "color", color_hsl[20], "color20")

			-- SKIN saturation --
			elseif fields.skin_saturation1 then
				update_player(player, player_name, "skin", "saturation", {saturation_mod[1]}, "saturation1")
			elseif fields.skin_saturation2 then
				update_player(player, player_name, "skin", "saturation", {saturation_mod[2]}, "saturation2")
			elseif fields.skin_saturation3 then
				update_player(player, player_name, "skin", "saturation", {saturation_mod[3]}, "saturation3")
			elseif fields.skin_saturation4 then
				update_player(player, player_name, "skin", "saturation", {saturation_mod[4]}, "saturation4")
			elseif fields.skin_saturation5 then
				update_player(player, player_name, "skin", "saturation", {saturation_mod[5]}, "saturation5")
			elseif fields.skin_saturation6 then
				update_player(player, player_name, "skin", "saturation", {saturation_mod[6]}, "saturation6")
			elseif fields.skin_saturation7 then
				update_player(player, player_name, "skin", "saturation", {saturation_mod[7]}, "saturation7")
			elseif fields.skin_saturation8 then
				update_player(player, player_name, "skin", "saturation", {saturation_mod[8]}, "saturation8")

			-- SKIN lightness --
			elseif fields.skin_lightness1 then
				update_player(player, player_name, "skin", "lightness", {lightness_mod[1]}, "lightness1")
			elseif fields.skin_lightness2 then
				update_player(player, player_name, "skin", "lightness", {lightness_mod[2]}, "lightness2")
			elseif fields.skin_lightness3 then
				update_player(player, player_name, "skin", "lightness", {lightness_mod[3]}, "lightness3")
			elseif fields.skin_lightness4 then
				update_player(player, player_name, "skin", "lightness", {lightness_mod[4]}, "lightness4")
			elseif fields.skin_lightness5 then
				update_player(player, player_name, "skin", "lightness", {lightness_mod[5]}, "lightness5")
			elseif fields.skin_lightness6 then
				update_player(player, player_name, "skin", "lightness", {lightness_mod[6]}, "lightness6")
			elseif fields.skin_lightness7 then
				update_player(player, player_name, "skin", "lightness", {lightness_mod[7]}, "lightness7")
			elseif fields.skin_lightness8 then
				update_player(player, player_name, "skin", "lightness", {lightness_mod[8]}, "lightness8")

			-- SKIN contrast --
			elseif fields.skin_contrast1 then
				update_player(player, player_name, "skin", "contrast", {contrast_mod[1]}, "contrast1")
			elseif fields.skin_contrast2 then
				update_player(player, player_name, "skin", "contrast", {contrast_mod[2]}, "contrast2")
			elseif fields.skin_contrast3 then
				update_player(player, player_name, "skin", "contrast", {contrast_mod[3]}, "contrast3")
			elseif fields.skin_contrast4 then
				update_player(player, player_name, "skin", "contrast", {contrast_mod[4]}, "contrast4")
			elseif fields.skin_contrast5 then
				update_player(player, player_name, "skin", "contrast", {contrast_mod[5]}, "contrast5")
			elseif fields.skin_contrast6 then
				update_player(player, player_name, "skin", "contrast", {contrast_mod[6]}, "contrast6")
			elseif fields.skin_contrast7 then
				update_player(player, player_name, "skin", "contrast", {contrast_mod[7]}, "contrast7")
			elseif fields.skin_contrast8 then
				update_player(player, player_name, "skin", "contrast", {contrast_mod[8]}, "contrast8")

			else
				debug(flag15, "ERROR - Unexpected formspec interaction for 'skin'")
			end

		elseif tab_name == "hair" then
			debug(flag15, "  interacted with a 'hair' element")

			-- HAIR COLOR --
			if fields.hair_color1 then
				update_player(player, player_name, "hair", "color", color_hsl[1], "color1")
			elseif fields.hair_color2 then
				update_player(player, player_name, "hair", "color", color_hsl[2], "color2")
			elseif fields.hair_color3 then
				update_player(player, player_name, "hair", "color", color_hsl[3], "color3")
			elseif fields.hair_color4 then
				update_player(player, player_name, "hair", "color", color_hsl[4], "color4")
			elseif fields.hair_color5 then
				update_player(player, player_name, "hair", "color", color_hsl[5], "color5")
			elseif fields.hair_color6 then
				update_player(player, player_name, "hair", "color", color_hsl[6], "color6")
			elseif fields.hair_color7 then
				update_player(player, player_name, "hair", "color", color_hsl[7], "color7")
			elseif fields.hair_color8 then
				update_player(player, player_name, "hair", "color", color_hsl[8], "color8")
			elseif fields.hair_color9 then
				update_player(player, player_name, "hair", "color", color_hsl[9], "color9")
			elseif fields.hair_color10 then
				update_player(player, player_name, "hair", "color", color_hsl[10], "color10")
			elseif fields.hair_color11 then
				update_player(player, player_name, "hair", "color", color_hsl[11], "color11")
			elseif fields.hair_color12 then
				update_player(player, player_name, "hair", "color", color_hsl[12], "color12")
			elseif fields.hair_color13 then
				update_player(player, player_name, "hair", "color", color_hsl[13], "color13")
			elseif fields.hair_color14 then
				update_player(player, player_name, "hair", "color", color_hsl[14], "color14")
			elseif fields.hair_color15 then
				update_player(player, player_name, "hair", "color", color_hsl[15], "color15")
			elseif fields.hair_color16 then
				update_player(player, player_name, "hair", "color", color_hsl[16], "color16")
			elseif fields.hair_color17 then
				update_player(player, player_name, "hair", "color", color_hsl[17], "color17")
			elseif fields.hair_color18 then
				update_player(player, player_name, "hair", "color", color_hsl[18], "color18")
			elseif fields.hair_color19 then
				update_player(player, player_name, "hair", "color", color_hsl[19], "color19")
			elseif fields.hair_color20 then
				update_player(player, player_name, "hair", "color", color_hsl[20], "color20")

				-- HAIR saturation --
			elseif fields.hair_saturation1 then
				update_player(player, player_name, "hair", "saturation", {saturation_mod[1]}, "saturation1")
			elseif fields.hair_saturation2 then
				update_player(player, player_name, "hair", "saturation", {saturation_mod[2]}, "saturation2")
			elseif fields.hair_saturation3 then
				update_player(player, player_name, "hair", "saturation", {saturation_mod[3]}, "saturation3")
			elseif fields.hair_saturation4 then
				update_player(player, player_name, "hair", "saturation", {saturation_mod[4]}, "saturation4")
			elseif fields.hair_saturation5 then
				update_player(player, player_name, "hair", "saturation", {saturation_mod[5]}, "saturation5")
			elseif fields.hair_saturation6 then
				update_player(player, player_name, "hair", "saturation", {saturation_mod[6]}, "saturation6")
			elseif fields.hair_saturation7 then
				update_player(player, player_name, "hair", "saturation", {saturation_mod[7]}, "saturation7")
			elseif fields.hair_saturation8 then
				update_player(player, player_name, "hair", "saturation", {saturation_mod[8]}, "saturation8")

			-- HAIR lightness --
			elseif fields.hair_lightness1 then
				update_player(player, player_name, "hair", "lightness", {lightness_mod[1]}, "lightness1")
			elseif fields.hair_lightness2 then
				update_player(player, player_name, "hair", "lightness", {lightness_mod[2]}, "lightness2")
			elseif fields.hair_lightness3 then
				update_player(player, player_name, "hair", "lightness", {lightness_mod[3]}, "lightness3")
			elseif fields.hair_lightness4 then
				update_player(player, player_name, "hair", "lightness", {lightness_mod[4]}, "lightness4")
			elseif fields.hair_lightness5 then
				update_player(player, player_name, "hair", "lightness", {lightness_mod[5]}, "lightness5")
			elseif fields.hair_lightness6 then
				update_player(player, player_name, "hair", "lightness", {lightness_mod[6]}, "lightness6")
			elseif fields.hair_lightness7 then
				update_player(player, player_name, "hair", "lightness", {lightness_mod[7]}, "lightness7")
			elseif fields.hair_lightness8 then
				update_player(player, player_name, "hair", "lightness", {lightness_mod[8]}, "lightness8")

			-- HAIR contrast --
			elseif fields.hair_contrast1 then
				update_player(player, player_name, "hair", "contrast", {contrast_mod[1]}, "contrast1")
			elseif fields.hair_contrast2 then
				update_player(player, player_name, "hair", "contrast", {contrast_mod[2]}, "contrast2")
			elseif fields.hair_contrast3 then
				update_player(player, player_name, "hair", "contrast", {contrast_mod[3]}, "contrast3")
			elseif fields.hair_contrast4 then
				update_player(player, player_name, "hair", "contrast", {contrast_mod[4]}, "contrast4")
			elseif fields.hair_contrast5 then
				update_player(player, player_name, "hair", "contrast", {contrast_mod[5]}, "contrast5")
			elseif fields.hair_contrast6 then
				update_player(player, player_name, "hair", "contrast", {contrast_mod[6]}, "contrast6")
			elseif fields.hair_contrast7 then
				update_player(player, player_name, "hair", "contrast", {contrast_mod[7]}, "contrast7")
			elseif fields.hair_contrast8 then
				update_player(player, player_name, "hair", "contrast", {contrast_mod[8]}, "contrast8")

			-- HAIR type --
			elseif fields.hair_type1 then
				update_player(player, player_name, "hair", "type", {1}, "hair_type1")
			elseif fields.hair_type2 then
				update_player(player, player_name, "hair", "type", {2}, "hair_type2")
			elseif fields.hair_type3 then
				update_player(player, player_name, "hair", "type", {3}, "hair_type3")
			elseif fields.hair_type4 then
				update_player(player, player_name, "hair", "type", {4}, "hair_type4")
			elseif fields.hair_type5 then
				update_player(player, player_name, "hair", "type", {5}, "hair_type5")
			elseif fields.hair_type6 then
				update_player(player, player_name, "hair", "type", {6}, "hair_type6")
			elseif fields.hair_type7 then
				update_player(player, player_name, "hair", "type", {7}, "hair_type7")
			elseif fields.hair_type8 then
				update_player(player, player_name, "hair", "type", {8}, "hair_type8")
			elseif fields.hair_type9 then
				update_player(player, player_name, "hair", "type", {9}, "hair_type9")
			elseif fields.hair_type10 then
				update_player(player, player_name, "hair", "type", {10}, "hair_type10")
			elseif fields.hair_type11 then
				update_player(player, player_name, "hair", "type", {11}, "hair_type11")

			else
				debug(flag15, "ERROR - Unexpected formspec interaction for 'hair'")
			end

		elseif tab_name == "eyes" then
			debug(flag15, "  interacted with a 'eyes' element")

			-- EYE COLOR ---
			if fields.eye_color1 then
				update_player(player, player_name, "eye", "color", color_hsl[1], "color1")
			elseif fields.eye_color2 then
				update_player(player, player_name, "eye", "color", color_hsl[2], "color2")
			elseif fields.eye_color3 then
				update_player(player, player_name, "eye", "color", color_hsl[3], "color3")
			elseif fields.eye_color4 then
				update_player(player, player_name, "eye", "color", color_hsl[4], "color4")
			elseif fields.eye_color5 then
				update_player(player, player_name, "eye", "color", color_hsl[5], "color5")
			elseif fields.eye_color6 then
				update_player(player, player_name, "eye", "color", color_hsl[6], "color6")
			elseif fields.eye_color7 then
				update_player(player, player_name, "eye", "color", color_hsl[7], "color7")
			elseif fields.eye_color8 then
				update_player(player, player_name, "eye", "color", color_hsl[8], "color8")
			elseif fields.eye_color9 then
				update_player(player, player_name, "eye", "color", color_hsl[9], "color9")
			elseif fields.eye_color10 then
				update_player(player, player_name, "eye", "color", color_hsl[10], "color10")
			elseif fields.eye_color11 then
				update_player(player, player_name, "eye", "color", color_hsl[11], "color11")
			elseif fields.eye_color12 then
				update_player(player, player_name, "eye", "color", color_hsl[12], "color12")
			elseif fields.eye_color13 then
				update_player(player, player_name, "eye", "color", color_hsl[13], "color13")
			elseif fields.eye_color14 then
				update_player(player, player_name, "eye", "color", color_hsl[14], "color14")
			elseif fields.eye_color15 then
				update_player(player, player_name, "eye", "color", color_hsl[15], "color15")
			elseif fields.eye_color16 then
				update_player(player, player_name, "eye", "color", color_hsl[16], "color16")
			elseif fields.eye_color17 then
				update_player(player, player_name, "eye", "color", color_hsl[17], "color17")
			elseif fields.eye_color18 then
				update_player(player, player_name, "eye", "color", color_hsl[18], "color18")
			elseif fields.eye_color19 then
				update_player(player, player_name, "eye", "color", color_hsl[19], "color19")
			elseif fields.eye_color20 then
				update_player(player, player_name, "eye", "color", color_hsl[20], "color20")

			-- EYE saturation --
			elseif fields.eye_saturation1 then
				update_player(player, player_name, "eye", "saturation", {saturation_mod[1]}, "saturation1")
			elseif fields.eye_saturation2 then
				update_player(player, player_name, "eye", "saturation", {saturation_mod[2]}, "saturation2")
			elseif fields.eye_saturation3 then
				update_player(player, player_name, "eye", "saturation", {saturation_mod[3]}, "saturation3")
			elseif fields.eye_saturation4 then
				update_player(player, player_name, "eye", "saturation", {saturation_mod[4]}, "saturation4")
			elseif fields.eye_saturation5 then
				update_player(player, player_name, "eye", "saturation", {saturation_mod[5]}, "saturation5")
			elseif fields.eye_saturation6 then
				update_player(player, player_name, "eye", "saturation", {saturation_mod[6]}, "saturation6")
			elseif fields.eye_saturation7 then
				update_player(player, player_name, "eye", "saturation", {saturation_mod[7]}, "saturation7")
			elseif fields.eye_saturation8 then
				update_player(player, player_name, "eye", "saturation", {saturation_mod[8]}, "saturation8")

			-- EYE lightness --
			elseif fields.eye_lightness1 then
				update_player(player, player_name, "eye", "lightness", {lightness_mod[1]}, "lightness1")
			elseif fields.eye_lightness2 then
				update_player(player, player_name, "eye", "lightness", {lightness_mod[2]}, "lightness2")
			elseif fields.eye_lightness3 then
				update_player(player, player_name, "eye", "lightness", {lightness_mod[3]}, "lightness3")
			elseif fields.eye_lightness4 then
				update_player(player, player_name, "eye", "lightness", {lightness_mod[4]}, "lightness4")
			elseif fields.eye_lightness5 then
				update_player(player, player_name, "eye", "lightness", {lightness_mod[5]}, "lightness5")
			elseif fields.eye_lightness6 then
				update_player(player, player_name, "eye", "lightness", {lightness_mod[6]}, "lightness6")
			elseif fields.eye_lightness7 then
				update_player(player, player_name, "eye", "lightness", {lightness_mod[7]}, "lightness7")
			elseif fields.eye_lightness8 then
				update_player(player, player_name, "eye", "lightness", {lightness_mod[8]}, "lightness8")

			else
				debug(flag15, "ERROR - Unexpected formspec interaction for 'eyes'")
			end

		elseif tab_name == "underwear" then
			debug(flag15, "  interacted with a 'underwear' element")

			-- UNDERWEAR COLOR --
			if fields.underwear_color1 then
				update_player(player, player_name, "underwear", "color", color_hsl[1], "color1")
			elseif fields.underwear_color2 then
				update_player(player, player_name, "underwear", "color", color_hsl[2], "color2")
			elseif fields.underwear_color3 then
				update_player(player, player_name, "underwear", "color", color_hsl[3], "color3")
			elseif fields.underwear_color4 then
				update_player(player, player_name, "underwear", "color", color_hsl[4], "color4")
			elseif fields.underwear_color5 then
				update_player(player, player_name, "underwear", "color", color_hsl[5], "color5")
			elseif fields.underwear_color6 then
				update_player(player, player_name, "underwear", "color", color_hsl[6], "color6")
			elseif fields.underwear_color7 then
				update_player(player, player_name, "underwear", "color", color_hsl[7], "color7")
			elseif fields.underwear_color8 then
				update_player(player, player_name, "underwear", "color", color_hsl[8], "color8")
			elseif fields.underwear_color9 then
				update_player(player, player_name, "underwear", "color", color_hsl[9], "color9")
			elseif fields.underwear_color10 then
				update_player(player, player_name, "underwear", "color", color_hsl[10], "color10")
			elseif fields.underwear_color11 then
				update_player(player, player_name, "underwear", "color", color_hsl[11], "color11")
			elseif fields.underwear_color12 then
				update_player(player, player_name, "underwear", "color", color_hsl[12], "color12")
			elseif fields.underwear_color13 then
				update_player(player, player_name, "underwear", "color", color_hsl[13], "color13")
			elseif fields.underwear_color14 then
				update_player(player, player_name, "underwear", "color", color_hsl[14], "color14")
			elseif fields.underwear_color15 then
				update_player(player, player_name, "underwear", "color", color_hsl[15], "color15")
			elseif fields.underwear_color16 then
				update_player(player, player_name, "underwear", "color", color_hsl[16], "color16")
			elseif fields.underwear_color17 then
				update_player(player, player_name, "underwear", "color", color_hsl[17], "color17")
			elseif fields.underwear_color18 then
				update_player(player, player_name, "underwear", "color", color_hsl[18], "color18")
			elseif fields.underwear_color19 then
				update_player(player, player_name, "underwear", "color", color_hsl[19], "color19")
			elseif fields.underwear_color20 then
				update_player(player, player_name, "underwear", "color", color_hsl[20], "color20")

			-- UNDERWEAR saturation --
			elseif fields.underwear_saturation1 then
				update_player(player, player_name, "underwear", "saturation", {saturation_mod[1]}, "saturation1")
			elseif fields.underwear_saturation2 then
				update_player(player, player_name, "underwear", "saturation", {saturation_mod[2]}, "saturation2")
			elseif fields.underwear_saturation3 then
				update_player(player, player_name, "underwear", "saturation", {saturation_mod[3]}, "saturation3")
			elseif fields.underwear_saturation4 then
				update_player(player, player_name, "underwear", "saturation", {saturation_mod[4]}, "saturation4")
			elseif fields.underwear_saturation5 then
				update_player(player, player_name, "underwear", "saturation", {saturation_mod[5]}, "saturation5")
			elseif fields.underwear_saturation6 then
				update_player(player, player_name, "underwear", "saturation", {saturation_mod[6]}, "saturation6")
			elseif fields.underwear_saturation7 then
				update_player(player, player_name, "underwear", "saturation", {saturation_mod[7]}, "saturation7")
			elseif fields.underwear_saturation8 then
				update_player(player, player_name, "underwear", "saturation", {saturation_mod[8]}, "saturation8")

			-- UNDERWEAR lightness --
			elseif fields.underwear_lightness1 then
				update_player(player, player_name, "underwear", "lightness", {lightness_mod[1]}, "lightness1")
			elseif fields.underwear_lightness2 then
				update_player(player, player_name, "underwear", "lightness", {lightness_mod[2]}, "lightness2")
			elseif fields.underwear_lightness3 then
				update_player(player, player_name, "underwear", "lightness", {lightness_mod[3]}, "lightness3")
			elseif fields.underwear_lightness4 then
				update_player(player, player_name, "underwear", "lightness", {lightness_mod[4]}, "lightness4")
			elseif fields.underwear_lightness5 then
				update_player(player, player_name, "underwear", "lightness", {lightness_mod[5]}, "lightness5")
			elseif fields.underwear_lightness6 then
				update_player(player, player_name, "underwear", "lightness", {lightness_mod[6]}, "lightness6")
			elseif fields.underwear_lightness7 then
				update_player(player, player_name, "underwear", "lightness", {lightness_mod[7]}, "lightness7")
			elseif fields.underwear_lightness8 then
				update_player(player, player_name, "underwear", "lightness", {lightness_mod[8]}, "lightness8")

			-- UNDERWEAR contrast --
			elseif fields.underwear_contrast1 then
				update_player(player, player_name, "underwear", "contrast", {contrast_mod[1]}, "contrast1")
			elseif fields.underwear_contrast2 then
				update_player(player, player_name, "underwear", "contrast", {contrast_mod[2]}, "contrast2")
			elseif fields.underwear_contrast3 then
				update_player(player, player_name, "underwear", "contrast", {contrast_mod[3]}, "contrast3")
			elseif fields.underwear_contrast4 then
				update_player(player, player_name, "underwear", "contrast", {contrast_mod[4]}, "contrast4")
			elseif fields.underwear_contrast5 then
				update_player(player, player_name, "underwear", "contrast", {contrast_mod[5]}, "contrast5")
			elseif fields.underwear_contrast6 then
				update_player(player, player_name, "underwear", "contrast", {contrast_mod[6]}, "contrast6")
			elseif fields.underwear_contrast7 then
				update_player(player, player_name, "underwear", "contrast", {contrast_mod[7]}, "contrast7")
			elseif fields.underwear_contrast8 then
				update_player(player, player_name, "underwear", "contrast", {contrast_mod[8]}, "contrast8")

			else
				debug(flag15, "ERROR - Unexpected formspec interaction for 'underwear'")
			end

		else
			debug(flag15, "ERROR - Unexpected 'tab_name' value: " .. tab_name)
		end

	end
    debug(flag15, "register_on_player_receive_fields() end " .. mt_get_gametime())
end)


local flag8 = false
core.register_on_respawnplayer(function(player)
    debug(flag8, "\nregister_on_respawnplayer() PLAYER SETUP")
	local player_name = player:get_player_name()
    local p_data = ss.player_data[player_name]
	local player_meta = player:get_meta()

	-- construct final base texture file from the separate texture parts
	local avatar_texture_base = get_avatar_texture_base(p_data, 0)
	p_data.avatar_texture_base = avatar_texture_base
	player_meta:set_string("avatar_texture_base", avatar_texture_base)
	debug(flag16, "  avatar_texture_base: " .. dump(avatar_texture_base))

	debug(flag8, "  display player setup window in 1 second..")
    current_tab[player_name] = "body"
	mt_after(1, function()
		if not player:is_player() then
			debug(flag8, "  player no longer exists. function skipped.")
			return
		end
		p_data.active_tab = "player_setup"
		local formspec = get_fs_setup_body(p_data)
		mt_show_formspec(player_name, "ss:ui_player_setup", formspec)
	end)

    debug(flag8, "register_on_respawnplayer() END")
end)
