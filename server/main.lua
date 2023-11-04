---@diagnostic disable: undefined-doc-name
local Keys = {}
Keys.List = {}

---@param tbl table
---@param key string
function Keys:HasKey(tbl, key)
    return type(tbl[key]) ~= "nil" and rawget(tbl, key) ~= nil
end

---@param vehNet number
function Keys:InitLocks(vehNet)
    if not vehNet then return end

    local vehicle = NetworkGetEntityFromNetworkId(vehNet)
    local vehState = Entity(vehicle).state

    if vehState.locked == nil then
        vehState:set('locked', true)
    end
end

---@param vehNet number
---@param state boolean
function Keys:SetLocks(vehNet, state)
    local vehicle = NetworkGetEntityFromNetworkId(vehNet)
    local vehState = Entity(vehicle).state

    vehState.locked = state
end

---@param vehNet number
---@param target charId
---@param wipe? boolean
function Keys:RemoveKeys(vehNet, target, wipe)
    if vehNet == nil or (target == nil and not wipe) then
        error('Keys:RemoveKeys: vehNet or target missing', 1)
        return
    end

    local keys = self.List[vehNet]
    if keys == nil then return end

    if wipe == nil then keys['player:' .. target] = nil end

    if wipe or keys == {} then keys = nil end
end

---@param vehNet number
---@param target number
function Keys:CheckKeys(vehNet, target)
    if self.List[vehNet] == nil then return false end

    local keys = self.List[vehNet]
    local authd = self:HasKey(keys, 'player:' .. target)

    if authd then return true end
    return false
end

---@param vehNet number
---@param target number
function Keys:SetKeys(vehNet, target)
    if not vehNet or not target then return end

    local authd = self:CheckKeys(vehNet, target)
    if authd then return end

    local keys = Keys.List[vehNet]
    if keys == nil then keys = {} end
    keys['player:' .. target] = true

    -- Entity(vehEnt).state:set('keys', vehKeys, true)
    Keys.List[vehNet] = keys
end

---@param vehNet number
function Keys:LockPick(vehNet)
    if not vehNet then return end
    local vehEnt = NetworkGetEntityFromNetworkId(vehNet)
    local vehState = Entity(vehEnt).state

    if vehState.locked == nil then vehState.locked = true end

    -- lockpick door
    --if callback some skillchecks (start car alarm) then
end

lib.callback.register('vehicle_keys:setLockedState', function(source, seat)
    if seat == nil then
        error('vehicle_keys:setLockedState: seat missing', 1)
        return false
    end

    local player = Ox.GetPlayer(source)
    if not player then return false end

    local vehNet = lib.callback.await('vehicle_keys:getClosestVehicle', source, player.getCoords())
    if not vehNet then
        TriggerClientEvent('ox_lib:notify', source, {
            id = 'vehicle_keys:notfound',
            description = "Cannot find vehicle",
            type = 'error'
        })
        return false
    end


    local authd = false
    if seat ~= false and seat <= 0 then
        authd = true
    end
    if seat == false then
        authd = Keys:CheckKeys(vehNet, player.charId)
    end

    if not authd then
        if seat ~= false and seat > 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                id = 'vehicle_keys:cantreach',
                description = "Cannot reach locks",
                type = 'error'
            })
            return false
        end
        TriggerClientEvent('ox_lib:notify', source, {
            id = 'vehicle_keys:nokeys',
            description = "You need keys to unlock this vehicle",
            type = 'inform'
        })
        return false
    end

    local vehEnt = NetworkGetEntityFromNetworkId(vehNet)
    local vehState = Entity(vehEnt).state
    vehState:set('locked', not vehState.locked, true)

    CreateThread(function()
        Wait(250)
        local owner = NetworkGetEntityOwner(vehEnt)
        TriggerClientEvent('vehicle_keys:lockingEffect', owner, vehNet)
    end)

    return true
end)

RegisterNetEvent('vehicle_keys:enteringVehicle', function(vehNetId)
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

function Keys:GiveKeys(giver, receiver, vehNet)
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

lib.addCommand({ 'givekeys', 'gk' }, {
    help = 'Give keys to a vehicle to another player',
    params = {
        { name = 'target', help = 'The target player id', type = 'number', optional = false }
    }
}, function(source, args, raw)
    local vehNet = lib.callback.await('vehicle_keys:getNearestVehicle', source)
    Keys:GiveKeys(source, args.target, vehNet)
end)

lib.addCommand('setKeys', {
    help = 'Set keys for a vehicle',
    params = {
        { name = 'target', help = 'The target player id', type = 'number', optional = false }
    },
    restricted = 'group.admin',
}, function(source, args, raw)
    local target = Ox.GetPlayer(args.target)
    if target == nil then
        error('player ' .. args.target .. 'not found', 1)
        return
    end
    local vehNet = lib.callback.await('vehicle_keys:getClosestVehicle', source, target.getCoords())

    Keys:SetKeys(vehNet, target.charId)
end)

---@param vehNet number
---@param target charId
exports('getKeys', function(vehNet, target)
    return Keys:CheckKeys(vehNet, target)
end)

---@param vehNet number
---@param charId number
exports('setKeys', function(vehNet, charId)
    return Keys:SetKeys(vehNet, charId)
end)

---@param vehNet number
---@param charId number
exports('removeKeys', function(vehNet, charId)
    return Keys:RemoveKeys(vehNet, charId, false)
end)

---@param vehNet number
---@param charId number
exports('wipeKeys', function(vehNet)
    return Keys:RemoveKeys(vehNet, nil, true)
end)
