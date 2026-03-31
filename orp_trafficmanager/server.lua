local allowedJobs = {
    police = true,
    safr = true,
    bcso = true,
    sasp = true,
}

local sharedZone = nil
local ZONE_DURATION_MS = 10 * 60 * 1000

local function getPlayerJob(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then
        return nil, false
    end

    local job = player.PlayerData and player.PlayerData.job
    if not job then
        return nil, false
    end

    local jobName = job.name
    local onDuty = job.onduty

    if onDuty == nil then
        onDuty = job.onDuty
    end

    return jobName, onDuty == true
end

local function hasAccess(src)
    local jobName, onDuty = getPlayerJob(src)

    if not jobName then return false end
    if not allowedJobs[jobName] then return false end
    if not onDuty then return false end

    return true
end

local function notify(src, description, notifType)
    TriggerClientEvent('trafficcontrol:client:notify', src, description, notifType)
end

local function validCoords(coords)
    return type(coords) == 'table'
        and type(coords.x) == 'number'
        and type(coords.y) == 'number'
        and type(coords.z) == 'number'
end

local function clampRadius(radius)
    radius = tonumber(radius) or 40.0
    radius = math.floor(radius + 0.5)

    if radius < 20 then radius = 20 end
    if radius > 100 then radius = 100 end

    return radius + 0.0
end

local function clearSharedZone(notifySource, reason)
    sharedZone = nil
    TriggerClientEvent('trafficcontrol:client:clearSharedZone', -1)

    if notifySource then
        if reason == 'expired' then
            notify(notifySource, 'Traffic control zone expired after 10 minutes.', 'inform')
        else
            notify(notifySource, 'Traffic resumed.', 'success')
        end
    end
end

local function startZoneExpireTimer(ownerSource)
    local thisZoneId = sharedZone and sharedZone.id
    if not thisZoneId then return end

    CreateThread(function()
        Wait(ZONE_DURATION_MS)

        if sharedZone and sharedZone.id == thisZoneId then
            TriggerClientEvent('trafficcontrol:client:notify', -1, 'Active scene expired after 10 minutes.', 'inform')
            clearSharedZone(ownerSource, 'expired')
        end
    end)
end

RegisterNetEvent('trafficcontrol:server:requestOpenMenu', function()
    local src = source

    if not hasAccess(src) then
        notify(src, 'You are not authorized to use traffic control.', 'error')
        return
    end

    TriggerClientEvent('trafficcontrol:client:openMenu', src, sharedZone)
end)

RegisterNetEvent('trafficcontrol:server:createZone', function(payload)
    local src = source

    if not hasAccess(src) then
        notify(src, 'You are not authorized to use traffic control.', 'error')
        return
    end

    if type(payload) ~= 'table' then
        notify(src, 'Invalid traffic zone data.', 'error')
        return
    end

    local coords = payload.coords
    local mode = payload.mode
    local radius = clampRadius(payload.radius)

    if not validCoords(coords) then
        notify(src, 'Invalid traffic zone coordinates.', 'error')
        return
    end

    local speed, blipColor, message

    if mode == 'stop' then
        speed = 0.0
        blipColor = 1
        message = 'Traffic stopped.'
    elseif mode == 'slow' then
        speed = 5.0
        blipColor = 5
        message = 'Traffic slowed.'
    else
        notify(src, 'Invalid traffic control mode.', 'error')
        return
    end

    if sharedZone and sharedZone.mode == mode and sharedZone.coords then
        local dx = sharedZone.coords.x - coords.x
        local dy = sharedZone.coords.y - coords.y
        local dz = sharedZone.coords.z - coords.z
        local distance = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))

        if distance <= 3.0 and sharedZone.radius == radius then
            notify(src, 'That traffic state is already active here.', 'inform')
            return
        end
    end

    local player = exports.qbx_core:GetPlayer(src)

    local characterName = 'Unknown'
    if player and player.PlayerData and player.PlayerData.charinfo then
        local char = player.PlayerData.charinfo
        characterName = ((char.firstname or '') .. ' ' .. (char.lastname or '')):gsub("^%s*(.-)%s*$", "%1")
        if characterName == '' then
            characterName = 'Unknown'
        end
    end

    sharedZone = {
        id = os.time() + math.random(1000, 9999),
        coords = coords,
        radius = radius,
        speed = speed,
        blipColor = blipColor,
        mode = mode,
        placedBy = characterName,
        expiresAt = os.time() + 600
    }

    TriggerClientEvent('trafficcontrol:client:applySharedZone', -1, sharedZone)
    notify(src, message, mode == 'stop' and 'error' or 'warning')

    startZoneExpireTimer(src)
end)

RegisterNetEvent('trafficcontrol:server:resumeTraffic', function()
    local src = source

    if not hasAccess(src) then
        notify(src, 'You are not authorized to use traffic control.', 'error')
        return
    end

    if not sharedZone then
        notify(src, 'There is no active traffic zone to remove.', 'inform')
        return
    end

    clearSharedZone(src, 'manual')
end)

AddEventHandler('playerJoining', function()
    local src = source

    if sharedZone then
        TriggerClientEvent('trafficcontrol:client:applySharedZone', src, sharedZone)
    end
end)