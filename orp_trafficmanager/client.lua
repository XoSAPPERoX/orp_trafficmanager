local activeSpeedZone = nil
local activeBlip = nil
local uiOpen = false

local function notify(messageType, description)
    local notifType = 'inform'

    if messageType == 'success' then
        notifType = 'success'
    elseif messageType == 'error' then
        notifType = 'error'
    elseif messageType == 'warning' then
        notifType = 'warning'
    end

    lib.notify({
        title = 'Traffic Control',
        description = description,
        type = notifType,
        position = 'top-right',
        duration = 4000
    })
end

local function setUiVisible(state, zoneData)
    uiOpen = state
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'setVisible',
        visible = state,
        zone = zoneData or false
    })
end

local function clearTrafficZone()
    if activeSpeedZone then
        RemoveSpeedZone(activeSpeedZone)
        activeSpeedZone = nil
    end

    if activeBlip then
        RemoveBlip(activeBlip)
        activeBlip = nil
    end
end

local function applySharedZone(zone)
    clearTrafficZone()

    if not zone or not zone.coords then return end

    activeBlip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
    SetBlipAlpha(activeBlip, 80)
    SetBlipColour(activeBlip, zone.blipColor)

    activeSpeedZone = AddSpeedZoneForCoord(
        zone.coords.x,
        zone.coords.y,
        zone.coords.z,
        zone.radius,
        zone.speed,
        false
    )
end

RegisterCommand('traffic', function()
    TriggerServerEvent('trafficcontrol:server:requestOpenMenu')
end, false)

RegisterKeyMapping('traffic', 'Open Traffic Control Menu', 'keyboard', 'F10')

RegisterNetEvent('trafficcontrol:client:openMenu', function(zoneData)
    setUiVisible(true, zoneData)
end)

RegisterNetEvent('trafficcontrol:client:notify', function(description, notifType)
    notify(notifType, description)
end)

RegisterNetEvent('trafficcontrol:client:applySharedZone', function(zone)
    applySharedZone(zone)
end)

RegisterNetEvent('trafficcontrol:client:clearSharedZone', function()
    clearTrafficZone()
end)

RegisterNUICallback('close', function(_, cb)
    setUiVisible(false)
    cb('ok')
end)

RegisterNUICallback('createZone', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())

    TriggerServerEvent('trafficcontrol:server:createZone', {
        mode = data.mode,
        radius = data.radius,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        }
    })

    cb('ok')
end)

RegisterNUICallback('resumeTraffic', function(_, cb)
    TriggerServerEvent('trafficcontrol:server:resumeTraffic')
    cb('ok')
end)

CreateThread(function()
    AddSpeedZoneForCoord(236.2, 6565.1, 31.5, 40.0, 20.0, false)
    AddSpeedZoneForCoord(161.2, 6544.5, 31.8, 40.0, 10.0, false)
end)

CreateThread(function()
    while true do
        if uiOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 322, true)
        end

        Wait(0)
    end
end)