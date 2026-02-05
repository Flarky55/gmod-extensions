local PLAYER = FindMetaTable( "Player" )

local META_ENTITY = FindMetaTable( "Entity" )

local SetNW2Int, GetNW2Int, Alive, GetMoveType, WaterLevel = META_ENTITY.SetNW2Int, META_ENTITY.GetNW2Int, META_ENTITY.Alive, META_ENTITY.GetMoveType, META_ENTITY.WaterLevel
local max, min = math.max, math.min
local hook_Run = hook.Run

local KEY       = "Oxygen"
local KEY_MAX   = "MaxOxygen"

local DEFAULT = 100
local RESTORE = 2


local function Oxygen( ply )
    return GetNW2Int( ply, KEY, DEFAULT )
end
PLAYER.Oxygen = Oxygen

local function GetMaxOxygen( ply )
    return GetNW2Int( ply, KEY_MAX, DEFAULT )
end
PLAYER.GetMaxOxygen = GetMaxOxygen

if SERVER then
    local function SetOxygen( ply, n )
        SetNW2Int( ply, KEY, n )
    end
    PLAYER.SetOxygen = SetOxygen

    local function SetMaxOxygen( ply, n )
        SetNW2Int( ply, KEY_MAX, n )
    end
    PLAYER.SetMaxOxygen = SetMaxOxygen

    
    local Rates = PlayerBoundTable( "Oxygen" )

    local function ProcessPlayer( ply )
        if not Alive( ply )
            or GetMoveType( ply ) ~= MOVETYPE_WALK
        then return end

        local oxygen = Oxygen( ply )
 
        local rate = Rates[ply]
        if rate == nil then
            rate = MutableNumber()
            Rates[ply] = rate
        else
            rate.value = 0
        end

        local cancel = hook_Run( "PlayerConsumeOxygen", ply, rate )
        local value = rate.value

        if cancel == nil and value ~= 0 then
            SetOxygen( ply, max( oxygen - value, 0 ) )
        else
            SetOxygen( ply, min( oxygen + RESTORE, GetMaxOxygen( ply ) ) )
        end
    end

    local function TakeDrownDamage( ply )
        local world = game.GetWorld()

        local dmgInfo = DamageInfo()
        dmgInfo:SetDamage( 2 )
        dmgInfo:SetDamageType( DMG_DROWN )
        dmgInfo:SetAttacker( world )
        dmgInfo:SetInflictor( world )

        ply:TakeDamageInfo( dmgInfo )
    end

    timer.Create( "Oxygen", 0.5, 0, function()
        for i, ply in player.Iterator() do
            ProcessPlayer( ply )

            if Oxygen( ply ) == 0 then
                TakeDrownDamage( ply )
            end
        end
    end )


    hook.Add( "PlayerConsumeOxygen", "Oxygen", function( ply, rate )
        if WaterLevel( ply ) == 3 then
            rate = rate + 1
        end
    end )
end