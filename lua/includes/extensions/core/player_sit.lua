local PLAYER = FindMetaTable( "Player" )

local META_ENTITY = FindMetaTable( "Entity" )
local META_CMoveData = FindMetaTable( "CMoveData" )

local GetNW2Bool, GetNW2Entity, GetTable = META_ENTITY.GetNW2Bool, META_ENTITY.GetNW2Entity, META_ENTITY.GetTable

local KEY_GROUND = "SitGround"
local KEY_ENTITY = "SitEntity"

local SEQUENCES_GROUND = { "pose_ducking_01", "pose_ducking_02", "sit_zen" }
for _, v in ipairs( SEQUENCES_GROUND ) do SEQUENCES_GROUND[v] = true end

if CLIENT then
    CreateClientConVar( "cl_sit_allow", 1, true, true, "Allow players to sit on you.", 0, 1 )
    local CVAR_SEQUENCE = CreateClientConVar( "cl_sit_sequence", "pose_ducking_02",  true, true, "Ground sit sequence" )

    cvars.AddChangeCallback( "cl_sit_sequence", function( name, old, new )
        if not SEQUENCES_GROUND[new] then
            CVAR_SEQUENCE:SetString( SEQUENCES_GROUND[1] )
        end
    end, "a" )
end


local function AddValidSitSequence( sequence )
    
end


local function IsSittingOnGround( ply )
    return GetNW2Bool( ply, KEY_GROUND )
end
PLAYER.IsSittingOnGround = IsSittingOnGround

local function IsSittingOnEntity( ply, target )
    if target == nil then
        return GetNW2Entity( ply, KEY_ENTITY ) ~= NULL
    end
    
    return GetNW2Entity( ply, KEY_ENTITY ) == target
end
PLAYER.IsSittingOnEntity = IsSittingOnEntity

local function IsSitting( ply )
    return IsSittingOnGround( ply ) or IsSittingOnEntity( ply )
end
PLAYER.IsSitting = IsSitting

local function GetSittingPlayers( ply )
    -- array of players who sits on ply
end


local function RequestSittingOnGround( ply, state )
    if IsFirstTimePredicted() then
        if state then
            ply.m_iSitSequence = ply:LookupSequence( SEQUENCES_GROUND[1] )
        else
            ply.m_iSitSequence = nil
        end
    end

    ply:SetNW2Bool( KEY_GROUND, state )
end

local function RequestSittingOnEntity( ply, target, tr )
    if IsFirstTimePredicted() then
        if IsValid( target ) then
            if target:IsPlayer() then

            else
                -- Create seat
                if SERVER then
                    local pos = tr.HitPos
                    local ang = tr.HitNormal:Angle()

                    local vehicle = ents.Create( "prop_vehicle_prisoner_pod" )
                    vehicle:SetModel( "models/nova/airboat_seat.mdl" )
                    vehicle:SetKeyValue( "vehiclescript", "scripts/vehicles/prisoner_pod.txt" )
                    vehicle:SetKeyValue( "limitview", "0" )
                    vehicle:Fire( "Lock" )
                    vehicle:SetPos( pos )
                    vehicle:SetAngles( ang )
                    vehicle:SetParent( target )
                    vehicle:Spawn()

                    ply.__veh = vehicle

                    NextThink( function()
                        if not IsValid( ply ) or not IsValid( vehicle ) then return end

                        -- ply:EnterVehicle( vehicle )
                    end )
                end
            end
        else
            if SERVER then
                local vehicle = ply.__veh
    
                vehicle:Remove()
            end
        end
    end

    ply:SetNW2Entity( KEY_ENTITY, target )
end

local RequestSitting; do
    local Trace = {}

    RequestSitting = function( ply, state )
        if state then
            if hook.Run( "CanPlayerSit", ply ) == false then return end

            local start     = ply:GetShootPos()
            Trace.start     = start
            Trace.endpos    = start + ply:GetAimVector() * 72 
            Trace.filter    = ply

            local tr = util.TraceLine( Trace )
            local target = tr.Entity

            if IsValid( target ) then
                RequestSittingOnEntity( ply, target, tr )
            else
                RequestSittingOnGround( ply, true )
            end 
        else
            if IsSittingOnGround( ply ) then 
                RequestSittingOnGround( ply, false )
            elseif IsSittingOnEntity( ply ) then
                RequestSittingOnEntity( ply, false )
            end
        end
    end
end


hook.Add( "CalcMainActivity", "PlayerSit", function( ply, vel )
    if not IsSittingOnGround( ply ) then return end
    
    if vel:Length2DSqr() < 1 then
        return ACT_HL2MP_IDLE, GetTable( ply ).m_iSitSequence
    end
end )

hook.Add( "StartCommand", "PlayerSit", function( ply, cmd )
    if not IsSittingOnGround( ply ) 
        or cmd:KeyDown( IN_DUCK )
    then return end

    cmd:AddKey( IN_DUCK )
    cmd:ClearMovement()
end )

hook.Add( "KeyPress", "PlayerSit", function( ply, key )
    if IsSitting( ply ) then
        if not ( key == IN_JUMP ) then return end

        RequestSitting( ply, false )
    else
        if not ( key == IN_USE and ply:KeyDown( IN_WALK ) ) then return end

        RequestSitting( ply, true )
    end
end )


if SERVER then
    concommand.Add( "sit", function( ply )
        RequestSitting( ply, not IsSitting( ply ) )
    end )
end