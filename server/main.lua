function has_key(tbl, key)
    return type(tbl[key]) ~= "nil" and rawget(tbl, key) ~= nil
end

function checkKeys(_vehEnt, _target)
    local vehEnt = _vehEnt
    local target = _target
    local vehState = Entity(vehEnt).state
    if vehState.keys == nil then return false end
    local vehKeys = vehState.keys
    if has_key(vehKeys, target) then return true end
    return false
end

function setKeys(vehEnt, _target)
    local vehicle = vehEnt
    local target = _target
    local hasKeys = checkKeys(vehicle, target)
    if hasKeys then return end
    local vehKeys = Entity(vehEnt).state.keys
    if vehKeys == nil then vehKeys = {} end
    vehKeys[target] = true
    Entity(vehEnt).state:set('keys', vehKeys, true)
end

lib.callback.register('vehiclekeys:checkkeys', function(source, data)
    local vehEnt = NetworkGetEntityFromNetworkId(data.vehicle)
    local target = Ox.GetPlayer(source).charid
    return checkKeys(vehEnt, target)
end)

lib.callback.register('vehiclekeys:identifier', function()
    return Ox.GetPlayer(source).charid
end)

RegisterNetEvent('baseevents:enteringVehicle', function(vehicleId, seatIndex, vehicleDisplayName, vehNetId)
    local playerId = source
    local vehicle = NetworkGetEntityFromNetworkId(vehNetId)
    local vehState = Entity(vehicle).state
    if vehState.locked == nil then
        SetVehicleDoorsLocked(vehicle, 2)
        vehState:set('locked', true)
    elseif vehState.locked == false then
        SetVehicleDoorsLocked(vehicle, 1)
    else
        SetVehicleDoorsLocked(vehicle, 2)
    end
end)

local function giveKeys(_giver, _receiver, _vehNet)
    local vehicle = NetworkGetEntityFromNetworkId(_vehNet)
    if not Ox.GetPlayer(_receiver) then
        TriggerClientEvent('vehiclekeys:notify', _giver, 'Player not found', 'error')
        return
    end
    local giverId = Ox.GetPlayer(_giver).charid
    local receiverId = Ox.GetPlayer(_receiver).charid
    local hasKeys = checkKeys(vehicle, giverId)
    if not checkKeys(vehicle, giverId) then
        return
    else
        setKeys(vehicle, receiverId)
        local message = 'You have been given keys to a vehicle'
        local style = 'success'
        TriggerClientEvent('vehiclekeys:notify', _receiver, message, style)
    end
end

lib.addCommand('givekeys', {
    help = 'Give keys to a vehicle to another player',
    params = {
        { name = 'target', help = 'The target player id', type = 'number', optional = false }
    }
}, function(source, args, raw)
    local vehNet = lib.callback.await('vehiclekeys:getNearestVehicle', source)
    giveKeys(source, args.target, vehNet)
end)

lib.addCommand('setKeys', {
    help = 'Set keys for a vehicle',
    params = {
        { name = 'target', help = 'The target player id', type = 'number', optional = false }
    },
    restricted = 'group.admin',
}, function(source, args, raw)
    local vehNet = lib.callback.await('vehiclekeys:getNearestVehicle', source)
    local vehicle = NetworkGetEntityFromNetworkId(vehNet)
    local target = Ox.GetPlayer(args.target).charid
    setKeys(vehicle, target)
end)

exports('getKeys', function(vehEnt, target)
    return checkKeys(vehEnt, target)
end)

exports('setKeys', function(vehEnt, target)
    setKeys(vehEnt, target)
end)
