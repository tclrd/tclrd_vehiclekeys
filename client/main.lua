local Keys = {}

lib.onCache('seat', function(value)
    -- SetPedConfigFlag(cache.ped, 429, true)
    if value == false then -- Check for false = exiting vehicle
        -- Exiting vehicle, checking engine state
        local prevVeh = GetVehiclePedIsIn(cache.ped, true)
        if Entity(prevVeh).state.engine then
            SetVehicleEngineOn(prevVeh, true, true, true)
        end
    end
end)

-- function toggleEngine()
--     -- guard clause for vehicle checking
--     if not cache.vehicle or cache.seat ~= -1 then return end
--     -- ped is in vehicle -> continuing
--     local vehicle = cache.vehicle
--     local vehState = Entity(vehicle).state
--     local hasKeys = lib.callback.await('vehiclekeys:checkkeys', false,
--         { vehicle = VehToNet(cache.vehicle) }) -- returns bool
--     if vehState.engine == nil then vehState:set('engine', GetIsVehicleEngineRunning(vehicle), true) end
--     local engineStatus = GetIsVehicleEngineRunning(cache.vehicle)
--     if not engineStatus then
--         if not hasKeys then
--             lib.notify({ description = 'No keys', type = 'error' })
--         else
--             if GetVehicleFuelLevel(vehicle) > 0 then
--                 vehState:set('engine', true, true)
--             else
--                 lib.notify({ description = 'Low fuel', type = 'error' })
--             end
--         end
--     else
--         vehState:set('engine', false, true)
--     end
-- end


---Applys audio and visual effects to the vehicle lock toggle
---@param vehicle number
function Keys:LockingEffect(vehicle)
    print('locking effect')
    if not vehicle then return end
    local state = Entity(vehicle).state.locked

    local sound = 'lock'
    if state == false then sound = 'unlock' end

    lib.requestAnimDict("anim@mp_player_intmenu@key_fob@")
    print('sound', sound)
lib.waitFor(function()
    return RequestScriptAudioBank('audiodirectory/custom_sounds', false)
end, 'soundbank not loaded', 1000)

    local soundId = GetSoundId()
    PlaySoundFromEntity(
        soundId,
        sound,
        vehicle,
        'lock_soundset',
        false,
        false
    )

    ReleaseSoundId(soundId)
    if state == false then
        -- car is unlocked
        SetVehicleLights(vehicle, 2)
        Wait(250)
        SetVehicleLights(vehicle, 0)
        Wait(200)
    else
        SetVehicleLights(vehicle, 2)
        Wait(250)
        SetVehicleLights(vehicle, 1)
        Wait(200)
        SetVehicleLights(vehicle, 0)
        Wait(300)
    end
    if cache.vehicle then SetVehicleLights(cache.vehicle, 0) end
    ReleaseNamedScriptAudioBank('audiodirectory/custom_sounds')
end

RegisterNetEvent('vehicle_keys:lockingEffect', function(vehNet)
    if vehNet == nil then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehNet)
    if vehicle == nil then return end
    Keys:LockingEffect(vehicle)
end)

function Keys:ToggleLock()
    if not lib.callback.await('vehicle_keys:setLockedState', false, cache.seat) then return end
    print('Keys:ToggleLock() - passed await')
    if cache.vehicle then return end

    TaskPlayAnim(cache.ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false, false)
    Wait(1000)
    StopAnimTask(cache.ped, "anim@mp_player_intmenu@key_fob@", 'fob_click', 1.0)
end

lib.addKeybind({
    name = 'toggledoorlocks',
    description = 'Toggle Vehicle Locks',
    defaultKey = 'U',
    onPressed = function(self)
        Keys:ToggleLock()
    end
})

exports('lockpick', function(data, slot)
    -- Player is attempting to use the item.
    local vehicle = cache.vehicle or lib.getClosestVehicle(GetEntityCoords(cache.ped), 3, true)
    -- TODO: CHECK LOCKPICK TYPE IN ITEM METADATA TO MINIMIZE ITEMS/REPETITION
    -- TODO: CHECK VEHICLE CLASS FOR DIFFICULTY MODIFIER ON LOCKPICKING AND EVENTUAL LOCKPICKING TYPES
    local vehState = Entity(vehicle).state
    -- LOCKPICKING LOGIC
    -- IF NOT PEDISINVEHICLE
    if not cache.vehicle then
        local animDict = "mini@safe_cracking"
        local anim = "idle_base"
        lib.requestAnimDict(animDict)
        TaskPlayAnim(
            cache.ped,
            animDict,
            anim,
            8.0,
            8.0,
            30000,
            16,
            1,
            0,
            0,
            0
        )
        if lib.skillCheck({ areaSize = 15, speedMultiplier = Config.Timers.HotwireSpeed }) then -- LOCKPICK DOORS
            vehState:set('locked', false, true)                                                 -- update locked state
            SetVehicleDoorsLocked(vehicle, 1)                                                   -- unlock vehicle
            lib.notify({ description = 'You lockpicked the door', type = 'success' })
            StopAnimTask(cache.ped, animDict, anim, 4.0)
        else
            lib.notify({ description = 'You failed lockpicking', type = 'error' })
            StopAnimTask(cache.ped, animDict, anim, 4.0)
            -- math.random 50/50 chance
            -- damage lockpick X%
            -- math.random 10% chance
            -- alert PD
        end
    else -- ELSE (IN VEHICLE)
        -- hotwiring
        local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
        local anim = "machinic_loop_mechandplayer"
        lib.requestAnimDict(animDict)
        TaskPlayAnim(
            cache.ped,
            animDict,
            anim,
            8.0,
            8.0,
            30000,
            16,
            1,
            0,
            0,
            0
        )
        StartVehicleAlarm(vehicle)
        SetVehicleAlarmTimeLeft(cache.vehicle, 10000)
        if lib.skillCheck({ areaSize = 15, speedMultiplier = Config.Timers.HotwireSpeed }) then -- HOTWIRE IGNITION
            -- setKeys(cache.vehicle, cache.serverId)
            lib.callback('vehiclekeys:setkeys', false, function()
                lib.notify({ description = 'You hotwired the vehicle', type = 'success' })
                StopAnimTask(cache.ped, animDict, anim, 4.0)
                Wait(2000)
                SetVehicleAlarm(cache.vehicle, false)
            end, { target = cache.serverId, vehicle = VehToNet(cache.vehicle) })
        else
            lib.notify({ description = 'You failed hotwiring', type = 'error' })
            StopAnimTask(cache.ped, animDict, anim, 4.0)
            Wait(Config.Timers.HotwireCD * 1000) --convert seconds into milliseconds
            -- math.random 50/50 chance
            -- damage lockpick X%
            -- math.random 10% chance
            -- alert PD
        end
    end
end)

AddStateBagChangeHandler('locked', nil, function(bagName, key, value, _unused, replicated)
    -- if replicated then return end
    if replicated == true then return end
    local vehicle = 0

    lib.waitFor(function()
        Wait(1)
        vehicle = GetEntityFromStateBagName(bagName)
        return DoesEntityExist(vehicle)
    end, 'entity does not exist', 1000)

    if GetVehicleDoorLockStatus(vehicle) == 2 and value == true then return end
    if GetVehicleDoorLockStatus(vehicle) == 1 and value == false then return end

    lib.waitFor(function()
        Wait(1)
        return NetworkGetEntityOwner(vehicle) == cache.playerId
    end, nil, 1000)

    if not NetworkGetEntityOwner(vehicle) == cache.playerId then return end

    if value then
        SetVehicleDoorsLocked(vehicle, 2)
    else
        CreateThread(function()
            while GetVehiclePedIsEntering(cache.ped) == vehicle do Wait(10) end
            SetVehicleDoorsLocked(vehicle, 1)
        end)
    end
end)

-- AddStateBagChangeHandler('engine', nil, function(bagName, key, value, _unused, replicated)
--     if not replicated then return end
--     local vehicle = GetEntityFromStateBagName(bagName)

--     if not DoesEntityExist(vehicle) then return end

--     local engineRunning = GetIsVehicleEngineRunning(vehicle) == 1
--     if engineRunning == value then return end
--     SetVehicleEngineOn(vehicle, value, false, true)
-- end)
