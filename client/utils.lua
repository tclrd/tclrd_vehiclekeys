local Entering = {}
Entering.Listening = false

function Entering:StateValidator(vehicle)
    local vehState = Entity(vehicle).state
    if vehState?.locked == nil then
        TriggerServerEvent('vehicle_keys:enteringVehicle', VehToNet(vehicle))
    end
end

function Entering:CheckEntering()
    local vehicle = GetVehiclePedIsEntering(cache.ped)
    if vehicle == 0 then return end
    self:StateValidator(vehicle)
end

function Entering:Listener()
    CreateThread(function()
        while self.Listening do
            Wait(250)
            self:CheckEntering()
        end
    end)
end

AddEventHandler('ox:playerLoaded', function(data)
    Entering.Listening = true
    Entering:Listener()
end)

AddEventHandler('ox:playerLogout', function(source, userid, charid)
    Entering.Listening = false
end)

---@param coords vector3
lib.callback.register('vehicle_keys:getClosestVehicle', function(coords, maxDistance, includePlayerVehicle)
    if coords == nil then return false end
    local closestVehicle = lib.getClosestVehicle(coords, maxDistance or 5.0, includePlayerVehicle or true)
    if closestVehicle == nil then return false end
    local vehNet = VehToNet(closestVehicle)
    return vehNet
end)

lib.callback.register('vehicle_keys:getClosestPlayer', function(coords, maxDistance)
    local playerId = lib.getClosestPlayer(coords, maxDistance, false)
    if playerId == nil then return nil end
    return GetPlayerServerId(playerId)
end)
