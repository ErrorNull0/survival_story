# SURVIVAL STORY

Developed by ErrorNull

for `Luanti 5.10.0+`

Survival Story is a game that incorporates survival mechanics inspired by games like 7 Days to Die, Project Zomboid, Don't Starve, and the RLCraft mod for Minecraft.

You spawn with nothing. Challenges become deadlier the farther out from spawn point you travel, to the point where they are near impossible to handle, guarding the next farthest region over the horizon. Be the player to survive the longest or explore the farthest into the distance.

There is also a unique story underlying the player's circumstance, hinting as to why they exist in this world, and why sleep and dreams are important.

Survival Story is very early in development and is planned to be a multi-year project. My goal is to create most features from scratch (and not rely on existing mods), so I can learn all aspects of the Luanti API in order to better optimize the game for multi-player. Any questions or comments let me know.

## Manual Install From .zip File
Upon extracting the zip file, the resulting `survival_story` folder should be placed in the `games` folder of main Luanti folder, like so:
	Luanti-5.10.0 > games > survival_story

## Changelog for v0.0.2
- pressing right mouse button while wielding a consumable item will temporarily display its remaining use count above the hotbar
- added custom drop items for clay, ice block, kelp, corals, cactus, and papyrus
- added item spawner admin tool
- added basic teleport admin tool
- cooldown hud image displays when performing actions like eating, drinking, and using items
- added item pickup and inventory action sound effects that are unique to each item type
- added custom swinging (hit miss) sound effects for all item types
- added more custom tool break sound effects
- ensured all items have custom pointing ranges
- added a Help tab with topics covering the custom game mechanics
- added an About tab

## Currnt Stat of Gameplay
There is currently not much "game" to the gameplay yet. This release is primarily to allow testing of the features currently implemented. Use the "Help" tab within the main inventory window to give you ideas on what features to try out.

Here are a few tips and things to keep in mind:

Start a new game with mapgen v7 with seed `666` or `777` which results in a good play area to test with.

Upon spawning into the world, the Player Setup window pops up. Customize your avatar and press Done when complete.

For keyboard input control, it is recommended to set **Aux1** to `Left SHIFT`, **Sneak** to `Left Ctrl`, and **Inventory** to `TAB`. 

You start with three admin tools in your inventory: the stats wand, item spawner, and teleporter. While wielding it, hold down the Aux1 key and press the primary action button to activate it. 

The stats wand allows you to manually manipulate any of your player stats - health, thirst, hunger, immunity, or santiy.

The item spawner allows you to spawn at your feet any of the custom made items in the game, as well as a few of the default items for testing.

The teleporter allows you to quickly teleport 100 meters ahead of you or toward either side.

## Credits
Thanks to everyone on the Luanti forum and Discord server for continued answers, guidance, and feedback. Thanks to all modders in the community for their creations, which provide inspiration and insight for some of the features in Survival Story. And of course, big thanks to Celeron55 for founding the amazing Luanti engine, and the work by the core developers in continually refining and updating Luanti for years to come.