Config = {}

--I have spawn coords for impound spawn point. -187.56, -1182.347, 23.044, 94.299 coords + heading
Config.Impound = {
    coords = vector3(-187.56, -1182.347, 23.044),
    heading = 94.299
}

Config.ImpoundUse = true
-- Set to false if you don't want to scripts impound.
--If it is off then when police impounds the vehicle it will remove it from parking and and set state 3 in player vehicle.

Config.ImpoundCharge = false -- Set to false if you don't want to charge for impound
