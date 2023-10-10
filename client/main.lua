-- # States in use:
-- Entity(vehicle).state.keys : {} table of CPlayer.charId as string values
-- Entity(vehicle).state.engine : type == bool
-- Entity(vehicle).state.locked : type == bool

lib.callback.register('vehiclekeys:getNearestVehicle', function()
    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 4, true)
    return VehToNet(vehicle)
end)

lib.callback.register('vehiclekeys:getNearestVehicles', function()
    local vehicles = lib.getNearbyVehicles(coords, maxDistance, includePlayerVehicle)
    return
end)

lib.onCache('seat', function(value)
    if value == false then -- Check for false = exiting vehicle
        -- Exiting vehicle, checking engine state
        local prevVeh = GetVehiclePedIsIn(cache.ped, true)
        if Entity(prevVeh).state.engine then
            SetVehicleEngineOn(prevVeh, true, true, true)
        end
    end
    if value ~= -1 then
        return -- not driver, do nothing
    else
        -- is driver -> block default behavior if no keys
        local vehState = Entity(cache.vehicle).state
        local hasKeys = lib.callback.await('vehiclekeys:checkkeys', false,
            { vehicle = cache.vehicle, target = cache.serverId }) -- returns bool
        if GetIsVehicleEngineRunning(cache.vehicle) then return end
        CreateThread(function(vehicle)
            while GetVehiclePedIsIn(cache.ped) ~= 0 do
                if value ~= -1 then break end
                Wait(0)
                if not GetIsVehicleEngineRunning(cache.vehicle) then
                    if vehState?.engine == nil or vehState.engine == false then
                        SetVehicleEngineOn(cache.vehicle, false, true, true)
                    end
                    lib.disableControls:Add(71) -- # Block Accelerate (71) https://docs.fivem.net/docs/game-references/controls/
                    lib.disableControls()
                end
            end
        end)
    end
end)

function toggleEngine()
    -- guard clause for vehicle checking
    if not cache.vehicle or cache.seat ~= -1 then return end
    -- ped is in vehicle -> continuing
    local vehicle = GetVehiclePedIsIn(cache.ped)
    local vehState = Entity(vehicle).state
    local hasKeys = lib.callback.await('vehiclekeys:checkkeys', false,
        { vehicle = VehToNet(cache.vehicle) }) -- returns bool
    if vehState.engine == nil then vehState:set('engine', GetIsVehicleEngineRunning(vehicle), true) end
    local engineStatus = GetIsVehicleEngineRunning(cache.vehicle)
    if not engineStatus then
        if not hasKeys then
            lib.notify({ description = 'No keys', type = 'error' })
        else
            if GetVehicleFuelLevel(vehicle) > 0 then
                vehState:set('engine', true, true)
            else
                lib.notify({ description = 'Low fuel', type = 'error' })
            end
        end
    else
        vehState:set('engine', false, true)
    end
end

lib.addKeybind({
    name = 'toggleengine',
    description = 'Toggle vehicle engine',
    defaultKey = 'K',
    onPressed = function(self)
        toggleEngine()
    end,
    onReleased = function(self)
    end,
})


---Applys audio and visual effects to the vehicle lock toggle
---@param _state boolean
---@param _vehNet number
function lockingEffect(_state, vehicle)
    lib.requestAnimDict("anim@mp_player_intmenu@key_fob@")
    local state = _state or false

    local sound = 'lock'
    if state == false then sound = 'unlock' end
    while not RequestScriptAudioBank('audiodirectory/custom_sounds', false) do Wait(0) end
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
    if state then
        -- car is unlocked
        SetVehicleLights(vehicle, 2)
        Wait(250)
        SetVehicleLights(vehicle, 1)
        Wait(200)
    else
        SetVehicleLights(vehicle, 2)
        Wait(250)
        SetVehicleLights(vehicle, 1)
        Wait(200)
        SetVehicleLights(vehicle, 0)
        Wait(300)
    end
    ReleaseNamedScriptAudioBank('audiodirectory/custom_sounds')
end

function toggleLock()
    local vehicle = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5, true)
    local vehState = Entity(vehicle)?.state
    local vehNet = NetworkGetNetworkIdFromEntity(vehicle)
    if NetworkGetEntityOwner(vehicle) == -1 then NetworkRequestControlOfEntity(vehicle) end
    local haskeys = lib.callback.await('vehiclekeys:checkkeys', false, { vehicle = vehNet }) -- returns bool
    print('has keys', haskeys)
    if cache.seat == -1 or cache.seat == 0 or haskeys then
        local state = nil
        if vehState.locked == nil then
            -- vehState:set('locked', true, true)
            state = true
        elseif vehState.locked == true then
            -- vehState:set('locked', false, true)
            state = false
        else
            -- vehState:set('locked', true, true)
            state = true
        end
        lib.callback.await('vehiclekeys:setstate', false, { vehicle = vehNet, state = state, value = vehState.locked })
        if not cache.vehicle then
            TaskPlayAnim(cache.ped, 'anim@mp_player_intmenu@key_fob@', 'fob_click', 3.0, 3.0, -1, 49, 0, false, false,
                false)
            Wait(1000)
        end

        StopAnimTask(cache.ped, "anim@mp_player_intmenu@key_fob@", 'fob_click', 1.0)
    else
        if not cache.vehicle then
            lib.notify({ description = 'You need keys to unlock the vehicle', type = 'inform' })
            return
        end
        if cache.seat ~= -1 or cache.seat ~= 0 then
            lib.notify({ description = "Can't reach locks", type = 'inform' })
            return
        end
    end
end

lib.addKeybind({
    name = 'toggledoorlocks',
    description = 'Toggle car doorlocks',
    defaultKey = 'U',
    onPressed = function(self)
        toggleLock()
    end,
    onReleased = function(self)
    end,
})

exports('lockpick', function(data, slot)
    -- Player is attempting to use the item.
    local playerPed = cache.ped
    local vehicle = cache.vehicle or lib.getClosestVehicle(GetEntityCoords(cache.ped), 3, true)
    local hasKeys = lib.callback.await('vehiclekeys:checkkeys', false,
        { vehicle = cache.vehicle, target = cache.serverId }) -- returns bool
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
    local vehicle = GetEntityFromStateBagName(bagName)
    -- if GetVehicleDoorLockStatus(vehicle) == 2 and value == true then return end
    -- if GetVehicleDoorLockStatus(vehicle) == 1 and value == false then return end

    if NetworkGetEntityOwner(vehicle) == cache.playerId then
        if value == true then
            SetVehicleDoorsLocked(vehicle, 2)
        else
            SetVehicleDoorsLocked(vehicle, 1)
        end
    end

    lockingEffect(value, vehicle)
end)

AddStateBagChangeHandler('engine', nil, function(bagName, key, value, _unused, replicated)
    if not replicated then return end
    local vehicle = GetEntityFromStateBagName(bagName)

    if not DoesEntityExist(vehicle) then return end

    local engineRunning = GetIsVehicleEngineRunning(vehicle) == 1
    if engineRunning == value then return end
    SetVehicleEngineOn(vehicle, value, false, true)
end)
