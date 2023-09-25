# tclrd-vehiclekeys

# WIP THIS IS NOT READY FOR PRODUCTION USE

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
Set keys for a vehicle
```lua
---@param vehicleEntity number
---@param charId number
exports.tclrd_vehiclekeys:setKeys(vehicleEntity, charId)
```

### getKeys
Get keys for a vehicle
```lua
---@param vehicleEntity number
---@param charId number
exports.tclrd_vehiclekeys:getKeys(vehicleEntity, charId)
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
