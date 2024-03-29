# tclrd-vehiclekeys

# WIP THIS IS NOT READY FOR PRODUCTION USE

### TODO: 
Add config for lockpicking settings
Add config for giving player keys on lockpick/hotwire success
Refactor lockpicking function for readibility
Replace PlayCustomSounds dependency with native audio for lock sounds and maybe add ignition sounds
Replace locked state with lockStatus state to match ox_core naming convention using 0 = unlocked and 1 = locked

## Vehicle Lock System for ox_core

🔑 Vehicle locking and lockpicking for ox_core. 🚗

## Dependencies
- [ox-core](https://github.com/overextended/ox_core)
- [ox-lib](https://github.com/overextended/ox_lib)

## Features

- Vehicle door locking
- Vehicle ignition locking
- Lockpicking doors
- Hotwiring ignition
- Give keys to other players
- Keys managed by entity statebag
- 0.00ms idle

![resmon screenshot](https://i.imgur.com/SoW0hal.png)

## Installation

Download the latest [release](https://github.com/tclrd/tclrd_vehiclekeys/releases) and place in your `resources` directory.
Add the script to your server.cfg

```
start tclrd-vehiclekeys
```

## Configuration

View `config.lua` to change the default settings.

TODO

## Commands

Player commands:

`/givekeys [playerId]` - Give keys to another player

Admin commands:

`/setKeys [playerId]` - Set keys for a player

`/checkKeys [playerId]` - Check keys for a player

## Server Exports

### setKeys
Set keys for provided chahrId to a vehicle
```lua
---@param vehicleEntity number
---@param charId number
exports.tclrd_vehiclekeys:setKeys(vehicleEntity, charId)
```

### getKeys
Check if provided charId has keys to a vehicle
```lua
---@param vehicleEntity number
---@param charId number
exports.tclrd_vehiclekeys:getKeys(vehicleEntity, charId)
```
### removeKeys
Remove keys for provided charId from a vehicle, wipes if no keys remain after removal

```lua
---@param vehicleEntity number
---@param charId number
exports.tclrd_vehiclekeys:removeKeys(vehicleEntity, charId)
```
### wipeKeys
Wipe keys for a provided vehicle

```lua
---@param vehicleEntity number
exports.tclrd_vehiclekeys:wipeKeys(vehicleEntity)
```
## Client Exports

### lockpick
lockpicks nearest vehicle to player

Recommend usage is adding to ox_inventory item lockpick:
```lua
['lockpick'] = {
    label = 'Lockpick',
    weight = 160,
    client = {
        export = 'tclrd_vehiclekeys.lockpick',
    }
},
```
Or used standalone:
```lua
exports.tclrd_vehiclekeys:lockpick()
```

## License

[![GPLv3 License](https://img.shields.io/badge/License-GPL%20v3-yellow.svg)](https://opensource.org/licenses/)
