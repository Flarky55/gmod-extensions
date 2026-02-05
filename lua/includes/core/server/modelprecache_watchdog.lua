require( "injector" )

local LIMIT     = 8192 -- https://wiki.facepunch.com/gmod/util.PrecacheModel#description
local RESERVE   = 512
local THRESHOLD = LIMIT - RESERVE

local Watchdog = PersistedTable( "ModelPrecacheWatchdog", { 
    Storage = {}, Count = 0, Reached = false
} )
local Storage = Watchdog.Storage


local function IsThresholdReached()
    return Watchdog.Count >= THRESHOLD
end

local function StoreModel( mdl )
    if Storage[mdl] then return end
    
    Storage[mdl] = true
    Watchdog.Count = Watchdog.Count + 1
end


util.PrecacheModel = injector.inject( util.PrecacheModel, StoreModel )


local hookfunc = function()
    if Watchdog.Reached then return false end

    if IsThresholdReached() then
        Watchdog.Reached = true
        hook.Run( "ModelPrecacheThresholdReached" )

        return false
    end
end

-- "PlayerSpawnObject" includes props, effects and ragdolls
for _, hookname in ipairs( { "PlayerSpawnObject", "PlayerSpawnNPC", "PlayerSpawnSENT", "PlayerSpawnSWEP", "PlayerSpawnVehicle" } ) do
    hook.Add( hookname, "ModelPrecacheWatchdog", hookfunc, PRE_HOOK_RETURN )
end