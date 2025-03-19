# SURVIVAL STORY

Developed by ErrorNull

for `Luanti 5.11.0+`

Survival Story is a game that incorporates survival mechanics inspired by games like 7 Days to Die, Project Zomboid, Don't Starve, and the RLCraft mod for Minecraft.

You spawn with nothing. Challenges become deadlier the farther out from spawn point you travel, to the point where they are near impossible to handle, guarding the next farthest region over the horizon. Be the player to survive the longest or explore the farthest into the distance.

There is also a unique story underlying the player's circumstance, hinting as to why they exist in this world, and why sleep and dreams are important.

Survival Story is very early in development and is planned to be a multi-year project. My goal is to create most features from scratch (and not rely on existing mods), so I can learn all aspects of the Luanti API in order to better optimize the game for multi-player. Any questions or comments let me know.

## Manual Install From .zip File
Upon extracting the zip file, the resulting `survival_story` folder should be placed in the `games` folder of the main Luanti folder, like so:

`Luanti-5.10.0` > `games` > `survival_story`

## Changelog for v0.0.3
- Added stat bars for Hygiene, Comfort, Sanity, and Happiness
- Added ability to show or hide any stat bar (do so from Settings tab)
- Added core functionality for Status Effects
- Added core functionality for Biome Climate
- Added Radiative temperature sources
- Added basic water temperature mechanics
- Status effects can be triggered by low stats
- Status effects can be triggered by climate conditions
- Added Status tab stat values, status effects, and thermal status
- added Weather wand and Debug wand admin tools
- added cook result description on all cookable items
- added text colorization to some text notifications and tooltips
- updated Help tab relating to latest features
- updated code to reference 'Luanti' instead of Minetest
- improved code that modifies player stats when items are used/consumed
- improved code organization and interaction across lua files
- fixed crafting recipe grid not updating when items dropped while viewing campfire or storage bag
- fixed some item interaction while using the Bundle tab
- fixed sound effects voiced by player avatar stacking/overlapping
- fixed entity object used as player's wield item not removing when player dies

## Current State of Gameplay
There is currently not much "game" to the gameplay yet. This release is primarily to allow testing of the features currently implemented. **View the "Help" tab within the main inventory window to give you ideas on what features to try out.**

Here are a few tips and things to keep in mind:

Create a new map with `mapgen v7` with seed `666` or `777` which results in a good play area to test with.

This game was designed for screen resolution of at least `1600` **pixel width** and `1080` **pixel height**. This is to accommodate the custom inventory window.

Upon spawning into the world, the Player Setup window pops up. Customize your avatar and press Done when complete.

For keyboard input control, it is recommended to set **Aux1** to `Left SHIFT`, **Sneak** to `Left Ctrl`, and **Inventory** to `TAB`. 

For testing purposes, you start with four admin tools in your inventory: the `stats wand`, `item spawner`, `weather wand`, and `teleporter`. While wielding an admin tool, hold down the Aux1 key and press the primary action button to activate it. 

The `stats wand` allows you to manually manipulate any of your player stats - health, thirst, hunger, alertness, hygiene, comfort, immunity, sanity, happiness, breath, stamina, experience, and weight.

The `item spawner` allows you to spawn at your feet any of the custom made items in the game, as well as a few of the default items for testing.

The `weather spawner` allows you temporarily modify the value ranges for air temperature, humidity, and wind of the current biome you are in. The biome's current air temperature and humidity will respond to your changes right away. In contrast, the current wind speed is updated every 10 - 60 seconds. Any changes are lost after game restart.

The `teleporter` allows you to quickly teleport 100 meters ahead of you or toward either side.

## Credits
Thanks to everyone on the Luanti forum and Discord server for continued answers, guidance, and feedback.

Thanks to all modders in the community for their creations, which provide inspiration and insight for some of the features in Survival Story.

And of course, big thanks to Celeron55 for founding the amazing Luanti engine, and the work by the core developers in continually refining and updating Luanti for years to come.