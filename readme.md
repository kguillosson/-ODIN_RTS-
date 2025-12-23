# Odin RTS

This repo is dedicated to the creation of an RTS coded in ODIN and using raylib for graphics.

The (ambitious) objective is a platoon scale tactics game where you fight against an invader from beyond the stars with good old combined arms warfare principles


## Current State of the Project:

- We can select units on the map either by clicking on them or using a selection box.
- We can task units with a variety of things :
  - all units can be tasked with movement, with a way to order them along a segment
  - simple blokes can be made to go into a vic
  - vics can be made to unload their contents
  - all units can be made to look towards something (the cursor, used to debug stuff)


## Short Term Goals: 

- Make it possible to give several orders to a unit that will be obeyed sequentially (ex: get a vic to go somewhere and drop off it's contents)
- Have a good long think about the structure of my data and do some cleanup
- Make vics not work if they don't have a driver
- Make weapons (like crewed stuff) that reuse some of the vic code

## Long term Goals:

- Find a way to store read only data outside of my code, might use JSON, or learn how to parse a text file in ODIN and make a crappy config file format
- Add enemies
- Make an elevation system used to compute LOS / affect mvt speed
- Make terrains that affect things like LOS / mvt speed
- Missions

## Experimental status:

- This branch is experimental, currently it's used to rebuild the data structures away from a collection fo arrays for each datatype, to a split between an array containing common data (pos, angle, type...) and extra arrays for specific things, like occupancy of vics...



 If you want to try this, I recommend installing ODIN  (https://odin-lang.org/), navigating to the folder where you've cloned this repo and running the command "odin run ."

 Many thanks to the ODIN language and Raylib Authors for the seamless developpement experience
