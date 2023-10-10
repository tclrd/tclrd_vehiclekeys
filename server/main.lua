local Keys = {}

function hasKey(tbl, key)
    return type(tbl[key]) ~= "nil" and rawget(tbl, key) ~= nil
end

-- -- Statebag version
-- function checkKeys(_vehEnt, _target)
--     local vehEnt = _vehEnt
--     local target = _target
--     if target == nil then return end
--     local vehState = Entity(vehEnt).state
--     if vehState.keys == nil then return false end
--     local vehKeys = vehState.keys
--     if hasKey(vehKeys, target) then return true end
--     return false
-- end

-- function setKeys(vehEnt, _target)
--     local vehicle = vehEnt
--     local target = _target
--     if target == nil then return end
--     local hasKeys = checkKeys(vehicle, target)
--     if hasKeys then return end
--     local vehKeys = Entity(vehEnt).state.keys
--     if vehKeys == nil then vehKeys = {} end
--     vehKeys[target] = true
--     Entity(vehEnt).state:set('keys', vehKeys, true)
-- end

-- Table versions
function wipeKeys(vehEnt)
    local vehicle = NetworkGetNetworkIdFromEntity(vehEnt)
    if Keys[vehicle] == nil then return end
    Keys[vehicle] = nil
end

function removeKeys(vehEnt, _target)
    local vehicle = NetworkGetNetworkIdFromEntity(vehEnt)
    local target = _target
    if target == nil then return end
    local vehKeys = Keys[vehicle]
    if vehKeys == nil then return end
    vehKeys['player:' .. target] = nil
    if vehKeys == {} then
        wipeKeys(vehEnt)
    else
        Keys[vehicle] = vehKeys
    end
end

function checkKeys(_vehEnt, _target)
    local vehNet = NetworkGetNetworkIdFromEntity(_vehEnt)
    local target = _target

    if Keys[vehNet] == nil then return false end

    local vehKeys = Keys[vehNet]
    if hasKey(vehKeys, 'player:' .. target) then return true end
    return false
end

function setKeys(vehEnt, _target)
    local vehicle = NetworkGetNetworkIdFromEntity(vehEnt)
    local target = _target

    local hasKeys = checkKeys(vehicle, target)
    if hasKeys then return end
    local vehKeys = Keys[vehicle]
    if vehKeys == nil then vehKeys = {} end
    vehKeys['player:' .. target] = true

    -- Entity(vehEnt).state:set('keys', vehKeys, true)

    Keys[vehicle] = vehKeys
end

lib.callback.register('vehiclekeys:setkeys', function(source, data)
    local vehEnt = NetworkGetEntityFromNetworkId(data.vehicle)
    local target = Ox.GetPlayer(source).charId
    print('setting keys')
    setKeys(vehEnt, target)
end)

lib.callback.register('vehiclekeys:checkkeys', function(source, data)
    local vehEnt = NetworkGetEntityFromNetworkId(data.vehicle)
    local target = Ox.GetPlayer(source).charId
    local keys = checkKeys(vehEnt, target)
    return keys
end)

lib.callback.register('vehiclekeys:setstate', function(source, data)
    local vehEnt = NetworkGetEntityFromNetworkId(data.vehicle)
    local vehState = Entity(vehEnt).state
    local state = data.state
    local value = data.value
    print(state, value)
    vehState:set('locked', data.state, true)
    return true
end)

RegisterNetEvent('vehiclekeys:enteringVehicle', function(vehNetId)
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
    local giverId = Ox.GetPlayer(_giver).charId
    local receiverId = Ox.GetPlayer(_receiver).charId
    if not checkKeys(vehicle, giverId) then
        return
    else
        setKeys(vehicle, receiverId)
        local message = 'You have been given keys to a vehicle'
        local style = 'success'
        TriggerClientEvent('ox_lib:notify', _receiver, {
            title = 'Vehicle Keys',
            message = message,
            type = style
        })
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
    local target = Ox.GetPlayer(args.target).charId
    setKeys(vehicle, target)
end)

---@param vehEnt number
---@param charId number
exports('getKeys', function(vehEnt, charId)
    return checkKeys(vehEnt, charId)
end)

---@param vehEnt number
---@param charId number
exports('setKeys', function(vehEnt, charId)
    setKeys(vehEnt, charId)
end)


exports('removeKeys', function(vehEnt, charId)
    removeKeys(vehEnt, charId)
end)

exports('wipeKeys', function(vehEnt)
    wipeKeys(vehEnt)
end)
