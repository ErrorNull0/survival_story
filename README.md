# SURVIVAL STORY

Developed by ErrorNull

for `Luanti 5.11.0+`

Survival Story is a game that incorporates survival mechanics inspired by games like 7 Days to Die, Project Zomboid, Don't Starve, and the RLCraft mod for Minecraft.

You spawn with nothing. Challenges become deadlier the farther out from spawn point you travel, to the point where they are near impossible to handle, guarding the next farthest region over the horizon. Be the player to survive the longest or explore the farthest into the distance.

There is also a unique story underlying the player's circumstance, hinting as to why they exist in this world, and why sleep and dreams are important.

Survival Story is very early in development and is planned to be a multi-year project. My goal is to create most features from scratch (and not rely on existing mods), so I can learn all aspects of the Luanti API in order to better optimize the game for multi-player. Any questions or comments let me know.

## Manual Install From .zip File
Upon extracting the zip file, the resulting `survival_story` folder should be placed in the `games` folder of the main Luanti folder, like so:

`Luanti-5.11.0` > `games` > `survival_story`

## Changelog for v0.0.4
- reduced resource requirements for string and a few other recipes
- added ability from Settings tab to disable pop-up notifications by group type
- added 'baseline value' mechanism
- added visual marker on most stat bars to show the baseline value
- thermal status section in Status tab now displays all factors that impact 'feels like' temperature
- added ability for clothing and armor to offset 'feels like' temperature when on dry land or in water
- added 'water temperature' equipment buff that offsets water temperature based on equipped clothing/armor
- added 'sun protection' equipment buff that offsets solar radiation based on equipped clothing/armor
- added 'electrical' equipment buff that offsets electrical damage based on equipped clothing/armor
- added 'gas' equipment buff that offsets toxic gas damage based on equipped clothing/armor
- added illness mechanism that triggers status effects with 'cold', 'flu', and 'pneumonia' severities
- added sneezing and coughing effects that are occasionally triggered when ill
- trigger illness from external factors like cold weather and lack of sleep (low alertness)
- added poison mechanism that triggers status effects with 'stomach ache', 'nausea', and 'dysentery' severities
- added vomiting effects that are occasionally triggered when poisoned
- trigger poisoning from consuming raw or bad food or drinking unclean water
- added leg condition mechanism that triggers status effects with 'sprained', and 'broken' severities
- trigger leg injuries from running and jumping from high places
- added hand condition mechanism that triggers status effects with 'sore', 'sprained', and 'broken'
- trigger hand injuries from swinging heavy tools and punching hard objects with bare hands
- added ability to splint or cast leg injuries for faster recovery
- added ability to 'crawl' up 1 meter blocks if jumping is severely hindered due to injury, exhaustion, or carrying weight
- ensured that wearing hand or foot protection like socks, shoes, and gloves**,** reduces those injuries
- added wetness (skin moisture) mechanism that is activated by standing or submersion in water
- alertness is increased when standing or submerged in water
- added tooltips that describe negative impacts from status effects when hovering over their names in the Status tab
- added Skills tab allowing use of earned skill points to improve player abilities including stat maximums, stat restore rates, stat drain rates, resistance to injury and illness, walking, running, and jumping
- added more info display to debug wand
- updated stats wand to modify the new stats like legs, hands, illness, poison, and wetness
- more code refactoring and better code organization
- lots of updates to Help tab

## Current State of Gameplay
There is currently not much "game" to the gameplay yet. This release is primarily to test newly implemented features. **View the "Help" tab within the main inventory window to get ideas on what features to try out.**

Here are a few tips and things to keep in mind:

Create a new map with `mapgen v7` with seed `666` or `777`, which results in a good play area to test with.

This game was designed for a screen resolution of at least `1600` **pixels width** and `1080` **pixels height**. This is to accommodate the custom inventory window.

Upon spawning into the world, the Player Setup window pops up. Customize your avatar and press Done when complete.

For keyboard input control, it is recommended to set **Aux1** to `Left SHIFT`, **Sneak** to `Left Ctrl`, and **Inventory** to `TAB`. 

For testing purposes, you start with four admin tools in your inventory: the `stats wand`, `item spawner`, `weather wand`, and `teleporter`. While wielding an admin tool, hold down the Aux1 key and press the primary action button to activate it. 

The `stats wand` allows you to manually manipulate any of your player stats including: health, thirst, hunger, alertness, hygiene, comfort, immunity, sanity, happiness, hands, legs, breath, stamina, experience, weight, illness, and poison. TIP: Use the stats wand to give yourself experience to quickly gain skill points to test the Skills upgrading feature.

The `item spawner` allows you to spawn at your feet any of the custom made items in the game, as well as a few of the default items for testing.

The `weather wand` allows you to temporarily modify the value ranges for air temperature, humidity, and wind of the current biome you are in. The biome's current air temperature and humidity will respond to your changes right away. In contrast, the current wind speed is updated every 10 - 60 seconds. Any changes are lost after a game restart.

The `teleporter` allows you to quickly teleport 100 meters ahead of you or toward either side.

## Credits
Thanks to everyone on the Luanti forum and Discord server for continued answers, guidance, and feedback.

Thanks to all modders in the community for their creations, which provide inspiration and insight for some of the features in Survival Story.

And of course, big thanks to Celeron55 for founding the amazing Luanti engine, and to the core developers for their work in continually refining and updating Luanti for years to come.