
--You can change here your way to unlock a vehicle. The event gives out the plate of the vehicle id.

RegisterNetEvent('lu-parking:client:giveKeys')
AddEventHandler('lu-parking:client:giveKeys', function(plate)
    TriggerEvent("vehiclekeys:client:SetOwner", plate)
end)

RegisterCommand("park", function(source, args, raw)
    TriggerEvent('parking:client:ParkVehicle')
end)


RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(1000)
    TriggerEvent('parking:client:requestiveh')
end)

local bones = {'seat_dside_f', 'seat_pside_f'}

CreateThread(function()
    exports['qb-target']:AddTargetBone(bones, {
        options = {
            ["UnPark Vehicle"] = {
                icon = "fas fa-square-parking",
                label = "Unpark Vehicle",
                action = function(entity)
                    TriggerEvent('parking:client:togunpark', entity)
                end,
                distance = 1.3
            },
        }
    })
    if Config.ImpoundUse then
        exports['qb-target']:AddTargetBone(bones, {
            options = {
                ["Impound Vehicle"] = {
                    icon = "fas fa-truck-tow",
                    label = "Impound Vehicle",
                    action = function(entity)
                        TriggerEvent('parking:client:impoundvehicle', entity)
                    end,
                    job = 'police',
                    distance = 1.3
                }
            }
        })
    end
    if Config.ImpoundCharge then
        local entity = 'prop_cuff_keys_01'
        exports['qb-target']:AddTargetModel(entity, {
            options = {
                {
                    num = 1,
                    type = "client",
                    event = "parking:client:openimpound",
                    icon = 'fas fa-car',
                    label = 'Open Impound List',
                }
            },
            distance = 2.5,
        })
    end
end)



