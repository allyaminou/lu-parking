local QBCore = exports['qb-core']:GetCoreObject()

---@param source number
function GetCID(source)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local cid = xPlayer.PlayerData.citizenid
    return cid
end

---@param plate string
---@param status number
---@param buyout_price number
function UpdateStatus(plate, state, buyout_price)
    MySQL.Async.execute('UPDATE player_vehicles SET state = @state, buyout_price = @buyout_price WHERE plate = @plate', {
        ['@plate'] = plate,
        ['@state'] = state,
        ['@buyout_price'] = buyout_price,
    })
end

---@param plate string
---@param mods string
function UpdateVehMods(plate, mods)
    MySQL.Async.execute('UPDATE player_vehicles SET mods = @mods WHERE plate = @plate', {
        ['@plate'] = plate,
        ['@mods'] = json.encode(mods),
    })
end

---@param cid string
function GetVehImpoundData(cid)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = @citizenid AND state = @state', {
        ['@citizenid'] = cid,
        ['@state'] = 3
    })
    return result
end

---@param plate string
function GetVehicleData(plate)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE plate = @plate', {
        ['@plate'] = plate,
    })
    return result
end

---@param source number
---@param amount number
function moneycheck(source, amount)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    local hasmoney = xPlayer.Functions.RemoveMoney('cash', amount)
    if hasmoney then
        return true
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = "You don't have enough money!"
        })
        return false
    end
end

---@param plycid string
---@param plate string
function CheckIfOwner(plycid, plate)
    local result = MySQL.Sync.fetchAll('SELECT * FROM player_vehicles WHERE citizenid = @citizenid AND plate = @plate', {
        ['@citizenid'] = plycid,
        ['@plate'] = plate
    })
    if result[1] ~= nil then
        return true
    else
        return false
    end
end