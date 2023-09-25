# tclrd-vehiclekeys

# WIP THIS IS NOT READY FOR PRODUCTION USE

## Vehicle Lock System for ox_core

🔑 Vehicle locking and lockpicking for ox_core. 🚗

## Dependencies
- [ox-core](https://github.com/overextended/ox_core)
- [ox-lib](https://github.com/overextended/ox_lib)
- [baseevents](https://github.com/citizenfx/cfx-server-data/tree/master/resources/%5Bsystem%5D/baseevents)

## Features

- Vehicle door locking
- Vehicle ignition locking
- Lockpicking doors
- Hotwiring ignition
- Give keys to other players
- Keys managed by entity statebag
- 0.00ms idle


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

TODO
`/givekeys [playerId]` - Give keys to another player

## Exports

TODO

### lockpick
lockpicks nearest vehicle to player

Recommend usage is adding to ox_inventory item lockpick:
```lua
['lockpick'] = {
    label = 'Lockpick',
    weight = 160,
    client = {
        export = 'tclrd_vehiclekeys:lockpick',
    }
},
```
Or used standalone:
```lua
---@param status boolean
exports['tclrd-vehiclekeys']:lockpick()
```

## License

[![GPLv3 License](https://img.shields.io/badge/License-GPL%20v3-yellow.svg)](https://opensource.org/licenses/)
