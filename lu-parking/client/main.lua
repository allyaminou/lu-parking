local porperties = {}
local playerPosition = GetEntityCoords(PlayerPedId()) -- Get the actual player position
local vehicle_table = {} -- Table to store all the vehicles data
local vehiclesInRange = {} -- Table to store all the vehicles in range
local stop = false -- Variable to stop the loop


-- Events --

RegisterNetEvent('parking:client:ParkVehicle')
AddEventHandler('parking:client:ParkVehicle', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId())
    if vehicle ~= 0 then
        parkvehicle(vehicle)
    else
        lib.notify({
            id = 'some_identifier',
            title = 'You are not in a vehicle',
            position = 'top-right',
            style = {
                backgroundColor = '#141517',
                color = '#C1C2C5',
                ['.description'] = {
                    color = '#909296'
                }
            },
            icon = 'ban',
            iconColor = '#C53030'
        })
    end
end)

RegisterNetEvent("parking:client:parkveh")
AddEventHandler("parking:client:parkveh", function(vehicle, model, location, properties)
    local coords = location.coords
    DeleteEntity(vehicle) -- delete vehicle
    Citizen.Wait(1000)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Citizen.Wait(0)
        end
    end
    local new_veh = CreateVehicle(model, coords.x, coords.y, coords.z, location.heading, true, true)
    SetVehicleOnGroundProperly(new_veh)
    lib.setVehicleProperties(new_veh, properties) -- set properties
    SetVehicleNumberPlateText(new_veh, properties.plate) -- set plate
    SetVehicleEngineHealth(new_veh, properties.engineHealth) -- set engine health
    SetVehicleBodyHealth(new_veh, properties.bodyHealth) -- set body health
    SetVehicleFuelLevel(new_veh, properties.fuelLevel) -- set fuel level
    FreezeEntityPosition(new_veh, true) -- freeze vehicle
    SetEntityInvincible(new_veh, true) -- make vehicle invincible
    SetVehicleDoorsLocked(new_veh, 3) -- lock vehicle
    SetEntityAsMissionEntity(new_veh, true, true)
    SetVehicleOnGroundProperly(new_veh)
    SetModelAsNoLongerNeeded(model)
    lib.notify({
        title = 'Parked successfully',
        type = 'success'
    })

    -- Add the vehicle to the vehiclesInRange list
    vehiclesInRange[properties.plate] = {
        model = model,
        entity = new_veh,
        plate = properties.plate,
    }

    requestVehicles()
end)


RegisterNetEvent("parking:client:unparkveh")
AddEventHandler("parking:client:unparkveh", function(entity, plate)
   FreezeEntityPosition(entity, false) -- unfreeze vehicle
    SetEntityInvincible(entity, false) -- make vehicle vincible
    SetVehicleDoorsLocked(entity, 1) -- unlock vehicle
    TriggerEvent("lu-parking:client:giveKeys", plate, entity)
    lib.notify({
        title = 'Unparked successfully',
        type = 'success'
    })

    for plate, vehicleData in pairs(vehiclesInRange) do
        if vehicleData.entity == entity then
            vehiclesInRange[plate] = nil
            break
        end
    end
    --Remove the vehicle data from vehicle_table
    for i, v in pairs(vehicle_table) do
        if v.plate == plate then
            table.remove(vehicle_table, i)
            break
        end
    end
end)

RegisterNetEvent('parking:client:togunpark')
AddEventHandler('parking:client:togunpark', function(entity)
    local plate = GetVehicleNumberPlateText(entity)
    TriggerServerEvent("parking:server:unparkveh", entity, plate)
    stop = true
end)

RegisterNetEvent('parking:client:sendvehicles')
AddEventHandler('parking:client:sendvehicles', function(vehicles)
    vehicle_table = {}
    vehicle_table = vehicles
    stop = false
end)

RegisterNetEvent('parking:client:impoundvehicle')
AddEventHandler('parking:client:impoundvehicle', function(entity)
    local plate = GetVehicleNumberPlateText(entity)
    local price = 0
    if Config.ImpoundCharge == true then
        local input = lib.inputDialog('Set Impound Price', {'Impound price'})
        if not input then return end
        price = input[1]
    end
    if lib.progressCircle({
        duration = 5000,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
        },
        anim = {
            dict = 'amb@code_human_wander_clipboard@male@idle_a',
            clip = 'idle_a'
        },
    }) then TriggerServerEvent("parking:server:impoundveh", entity, plate, price) else print("you canceled") end
end)

RegisterNetEvent('parking:client:impoundveh')
AddEventHandler('parking:client:impoundveh', function(entity)
    if entity ~= nil then
        DeleteEntity(entity)
    end
end)

RegisterNetEvent('parking:client:openimpound')
AddEventHandler('parking:client:openimpound', function()
    local vehicles = lib.callback.await('parking:server:requestvehs', false)
    local elements = {}
    for i, v in pairs(vehicles) do
        if v.vehicle ~= nil then
            if Config.ImpoundCharge == true then
                table.insert(elements, {
                    title = 'Plate: [' .. v.plate .. '] Vehicle name: ' .. v.vehicle,
                    description = 'Buyout Price: ' .. v.buyout_price .. '$',
                    icon = 'check',
                    event = 'parking:client:impoundbuyout',
                    args = {
                        plate = v.plate
                    }
                })
            else
                table.insert(elements, {
                    title = 'Plate: [' .. v.plate .. '] Vehicle name: ' .. v.vehicle,
                    description = 'Get your vehicle back',
                    icon = 'check',
                    event = 'parking:client:impoundbuyout',
                    args = {
                        plate = v.plate,
                    }
                })
            end
        else
            print("vehicle is nil")
        end
    end

    lib.registerContext({
        id = 'impound',
        title = 'Vehciel Impound',
        options = elements
    })
    lib.showContext('impound')


end)

RegisterNetEvent('parking:client:impoundbuyout')
AddEventHandler('parking:client:impoundbuyout', function(args)
    TriggerServerEvent("parking:server:impoundbuyout", args.plate)
end)

RegisterNetEvent('parking:client:impoundspawnveh')
AddEventHandler('parking:client:impoundspawnveh', function(vehicle)
    Wait(1000)
    local model = tonumber(vehicle[1].hash)
    local properties = json.decode(vehicle[1].mods)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    local new_veh = CreateVehicle(model, -189.974, -1182.516, 23.044, 84.227, true, false)
    SetVehicleOnGroundProperly(new_veh)
    Wait(500)
    lib.setVehicleProperties(new_veh, properties) -- set properties
    SetVehicleNumberPlateText(new_veh, vehicle[1].plate) -- set plate
    SetVehicleEngineHealth(new_veh, properties.engineHealth) -- set engine health
    SetVehicleBodyHealth(new_veh, properties.bodyHealth) -- set body health
    SetVehicleFuelLevel(new_veh, properties.fuelLevel) -- set fuel level
    TriggerEvent('lu-parking:client:giveKeys', vehicle[1].plate)

end)

RegisterNetEvent('parking:client:requestiveh')
AddEventHandler('parking:client:requestiveh', function()
    requestVehicles()

end)

-- Events End --
-- Functions --

function requestVehicles()
    TriggerServerEvent("parking:server:requestvehicles")
end

function parkvehicle(vehicle)
    local properties = lib.getVehicleProperties(vehicle)
    local coords = GetEntityCoords(vehicle)
    local heading = GetEntityHeading(vehicle)
    local model = GetEntityModel(vehicle)
    local vehname = GetDisplayNameFromVehicleModel(model)
    local location = {
        coords = coords,
        heading = heading
    }
    GetOutOfVeh()
    Citizen.Wait(1000)
    TriggerServerEvent("parking:server:savevehprop", vehicle, vehname, properties, location)

end

--create function that will let player exit vehicle
function GetOutOfVeh()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= nil then
        TaskLeaveVehicle(ped, vehicle, 0)
    end
end

function spawnVehiclesInRange()
    local plypos = GetEntityCoords(PlayerPedId())
    local newVehiclesInRange = {}
    for _, v in pairs(vehicle_table) do
        local coords = v.position.coords
        local distance = GetDistanceBetweenCoords(plypos.x, plypos.y, plypos.z, coords.x, coords.y, coords.z, true)
--
        if distance < 100 then
            if not vehiclesInRange[v.plate] then
                vehiclesInRange[v.plate] = {
                    model = v.vehicle,
                    entity = nil,
                    plate = v.plate
                }
            end
            if not vehiclesInRange[v.plate].entity and not vehiclesInRange[v.plate].plate or not DoesEntityExist(vehiclesInRange[v.plate].entity) then
                createvehicle(coords, v)
    --
            end
        else
            if vehiclesInRange[v.plate] and DoesEntityExist(vehiclesInRange[v.plate].entity) then
                DeleteEntity(vehiclesInRange[v.plate].entity)
            end
        end
    --
        newVehiclesInRange[v.plate] = vehiclesInRange[v.plate]
    end
--
    vehiclesInRange = newVehiclesInRange
end

function createvehicle(coords, v)

    local model = joaat(v.vehicle)
    lib.requestModel(v.vehicle, 100)
    local new_veh = CreateVehicle(model, coords.x, coords.y, coords.z, v.position.heading, true, true)
    Wait(400)
    SetVehicleOnGroundProperly(new_veh)
    lib.setVehicleProperties(new_veh, v.info) -- set properties
    SetVehicleNumberPlateText(new_veh, v.info.plate) -- set plate
    SetVehicleEngineHealth(new_veh, v.info.engineHealth) -- set engine health
    SetVehicleBodyHealth(new_veh, v.info.bodyHealth) -- set body health
    SetVehicleFuelLevel(new_veh, v.info.fuelLevel) -- set fuel level
    FreezeEntityPosition(new_veh, true) -- freeze vehicle
    SetEntityInvincible(new_veh, true) -- make vehicle invincible
    SetVehicleDoorsLocked(new_veh, 3) -- lock vehicle
    SetEntityAsMissionEntity(new_veh, true, true)
    SetVehicleOnGroundProperly(new_veh)
    SetModelAsNoLongerNeeded(model)
    Wait(300)
    vehiclesInRange[v.plate].entity = new_veh
end

-- Functions End --
-- Debug --

function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end



-- Debug End --
-- Threads --

-- Call the function every 4 seconds
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000) -- Wait for 4 seconds
        if not stop then
            spawnVehiclesInRange()
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        for _, v in pairs(vehiclesInRange) do
            DeleteEntity(v.entity)
        end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        requestVehicles()
    end
end)

