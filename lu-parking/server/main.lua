local vehicle_table = {} -- Table to store all the vehicles data
RegisterNetEvent("parking:server:savevehprop")
AddEventHandler("parking:server:savevehprop", function(vehicleid, vehicle, properties, location)
    local src = source
    if vehicle ~= nil and properties ~= nil and location ~= nil then
        local plycid = GetCID(src)
        --local result = CheckIfOwner(plycid, properties.plate)

        --if result then
            --If the vehicle is found in the database, update the vehicle's hash and info
            MySQL.insert('INSERT INTO parking (citizenid, vehicle, hash, info, plate, position) VALUES (@citizenid, @vehicle, @hash, @info, @plate, @position)', {
                ['@citizenid'] = plycid,
                ['@vehicle'] = vehicle,
                ['@hash'] = properties.model,
                ['@info'] = json.encode(properties),
                ['@plate'] = properties.plate,
                ['@position'] = json.encode(location)
            })
            UpdateVehMods(properties.plate, properties)
            TriggerClientEvent("parking:client:parkveh", src, vehicleid, properties.model, location, properties)
        --else
        --    TriggerClientEvent('ox_lib:notify', src, {
        --        type = 'error',
        --        description = "This is not your vehicle!"
        --    })
        --end
    else
        print("Something went wrong")
    end

end)

RegisterNetEvent("parking:server:impoundveh")
AddEventHandler("parking:server:impoundveh", function(entity, plate, buyout_price)
    local src = source
    local result = MySQL.Sync.fetchAll('SELECT * FROM parking WHERE plate = @plate', {
        ['@plate'] = plate
    })
    if result[1] ~= nil then
        MySQL.Async.execute('DELETE FROM parking WHERE plate = @plate', {
            ['@plate'] = plate
        })
        Wait(500)
        TriggerEvent('parking:server:requestvehicles')
        TriggerClientEvent("parking:client:impoundveh", -1, entity)
        UpdateStatus(plate, 3, buyout_price)
    else
        UpdateStatus(plate, 3, buyout_price)
        TriggerClientEvent("parking:client:impoundveh", -1, entity)
    end
end)

RegisterNetEvent('parking:server:impoundbuyout')
AddEventHandler('parking:server:impoundbuyout', function(plate)
    local src = source
    local vehicle = GetVehicleData(plate)
    if Config.ImpoundCharge then
        local hasmoney = moneycheck(src, vehicle[1].buyout_price)
        if hasmoney then
            UpdateStatus(plate, 1, 0)
            TriggerClientEvent('parking:client:impoundspawnveh', src, vehicle)
        end
    else
        UpdateStatus(plate, 1, 0)
        TriggerClientEvent('parking:client:impoundspawnveh', src, vehicle)
    end
end)

RegisterNetEvent("parking:server:unparkveh")
AddEventHandler("parking:server:unparkveh", function(entity, plate)
    local src = source
    local cid = GetCID(src)
    local result = MySQL.Sync.fetchAll('SELECT * FROM parking WHERE citizenid = @citizenid AND plate = @plate', {
        ['@citizenid'] = cid,
        ['@plate'] = plate
    })
    if result[1] ~= nil then
        MySQL.Async.execute('DELETE FROM parking WHERE citizenid = @citizenid AND plate = @plate', {
            ['@citizenid'] = cid,
            ['@plate'] = plate
        })
        Wait(500)
        TriggerEvent('parking:server:requestvehicles')
        TriggerClientEvent("parking:client:unparkveh", src, entity, plate)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = "This is not your vehicle!"
        })
    end
end)

RegisterNetEvent("parking:server:requestvehicles")
AddEventHandler("parking:server:requestvehicles", function()
    local result = MySQL.Sync.fetchAll('SELECT * FROM parking')
    if result[1] ~= nil then
        for k, v in pairs(result) do
            local vehicle = {
                id = v.id,
                citizenid = v.citizenid,
                vehicle = v.vehicle,
                hash = v.hash,
                info = json.decode(v.info),
                plate = v.plate,
                position = json.decode(v.position)
            }
            table.insert(vehicle_table, vehicle)
        end
    end
    TriggerClientEvent("parking:client:sendvehicles", -1, vehicle_table)
    vehicle_table = {}
end)



lib.callback.register('parking:server:requestvehs', function(source)
    local cid = GetCID(source)
    local vehicles = {}
    local result = GetVehImpoundData(cid)
    if result[1] ~= nil then
        for k, v in pairs(result) do
            local vehs = {
                id = v.id,
                citizenid = v.citizenid,
                vehicle = v.vehicle,
                state = v.state,
                plate = v.plate,
                buyout_price = v.buyout_price,
            }
            table.insert(vehicles, vehs)
        end
    end
    return vehicles
end)


function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end

end