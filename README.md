# ConstructionHorse
An Azerothcore-based GM helper addon for building things with game objects

# Description of Workflow
There is a "working list" of objects that is kept so that one is able to still flash other objects if needed
1. Use `ConstructionHorse.flash_nearby()` to flash nearby gameobjects
2. `ConstructionHorse.select.attach()` to change the working list to contain only the flashed nearby objects.
3.   i)`ConstructionHorse.select.prev()` to move backwards in the list, flashing the previously selected object 
    ii)`ConstructionHorse.select.next()` to move forwards in the list, flashing the next selected object
   iii)`ConstructionHorse.selection:flash()` to flash the current object in the list
    iv)`ConstructionHorse.selection:delete()` to delete the current object in the list
