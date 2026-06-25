local PLAYER = FindMetaTable( "Player" )

local META_ENTITY = FindMetaTable( "Entity" )
local META_CMoveData = FindMetaTable( "CMoveData" )

local GetNW2Bool, GetNW2Entity, GetTable = META_ENTITY.GetNW2Bool, META_ENTITY.GetNW2Entity, META_ENTITY.GetTable

local KEY_GROUND = "SitGround"
local KEY_ENTITY = "SitEntity"

local SequencesGround, SequencesEntity = {}, {}

local NAME_ALLOW, DEFAULT_ALLOW = "cl_sit_allow", 1

local DEFAULT_SEQUENCE_GROUND, DEFAULT_SEQUENCE_ENTITY = "pose_ducking_02", "sit"

if CLIENT then
    CreateClientConVar( NAME_ALLOW, DEFAULT_ALLOW, true, true, "Allow players to sit on you.", 0, 1 )
    local CVAR_SEQUENCE_GROUND = CreateClientConVar( "cl_sit_ground_sequence", DEFAULT_SEQUENCE_GROUND, true, true, "Ground sit sequence" )
    local CVAR_SEUQNECE_ENTITY = CreateClientConVar( "cl_sit_entity_sequence", DEFAULT_SEQUENCE_ENTITY, true, true, "Entity sit sequence" )

    cvars.AddChangeCallback( CVAR_SEQUENCE_GROUND:GetName(), function( name, old, new )
        if not SequencesGround[new] then
            CVAR_SEQUENCE_GROUND:SetString( old )
            return
        end
    end, "validation" )
end


local function AddValidSitGroundSequence( name )
    if SequencesGround[name] then return end

    table.insert( SequencesGround, name )
    SequencesGround[name] = true
end
player_manager.AddValidSitGroundSequence = AddValidSitGroundSequence

local function AddValidSitEntitySequence( name )
    if SequencesEntity[name] then return end

    table.insert( SequencesEntity, name )
    SequencesEntity[name] = true
end
player_manager.AddValidSitEntitySequence = AddValidSitEntitySequence

local function AllValidSitGroundSequences()
    return SequencesGround
end
player_manager.AllValidSitGroundSequences = AllValidSitGroundSequences

local function AllValidSitEntitySequences()
    return SequencesEntity
end
player_manager.AllValidSitEntitySequences = AllValidSitEntitySequences


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
PLAYER.GetSittingPlayers = GetSittingPlayers


local function RequestSittingOnGround( ply, state )
    if state then
        local name = ply:GetNW2String( "", DEFAULT_GROUND_SEQUENCE )

        ply.m_iSitSequence = ply:LookupSequence( name )
    else
        ply.m_iSitSequence = nil
    end

    ply:SetNW2Bool( KEY_GROUND, state )
end

local function RequestSittingOnEntity( ply, target, tr )
    if IsValid( target ) then
        if target:IsPlayer() then

        else
            if SERVER then
                local pos = tr.HitPos
                local ang = tr.HitNormal:Angle()

                ang:RotateAroundAxis( ang:Right(), -90 )

                local vehicle = ents.Create( "prop_vehicle_prisoner_pod" )
                assert( IsValid( vehicle ), "PlayerSit: failed to create vehicle entity!" )

                vehicle:SetKeyValue( "vehiclescript",   "scripts/vehicles/prisoner_pod.txt" )
                vehicle:SetKeyValue( "VehicleLocked",   "1" )
                vehicle:SetKeyValue( "limitview",       "0" )
                vehicle:SetModel( "models/nova/airboat_seat.mdl" )
                vehicle:SetPos( pos )
                vehicle:SetAngles( ang )
                vehicle:SetParent( target )

                vehicle:Spawn()
                -- assert( IsValid( vehicle ), "PlayerSit: failed to spawn vehicle entity!" )

                vehicle:SetMoveType( MOVETYPE_NONE )
                vehicle:SetCollisionGroup( COLLISION_GROUP_WORLD )
                vehicle:SetNotSolid( true )
                vehicle:SetNoDraw( true )

                ply.m_eSitVehicle = vehicle

                NextThink( function()
                    if not IsValid( ply ) or not IsValid( vehicle ) then return end

                    ply:EnterVehicle( vehicle )
                end )

                if target:IsNPC() then
                    target:AddEntityRelationship( ply, D_NU, 99 )

                    -- TODO: reset when exit
                end
            end
        end
    else
        if SERVER then
            local vehicle = ply.m_eSitVehicle

            if IsValid( vehicle ) then
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
    if IsSittingOnGround( ply ) then
        if vel:Length2DSqr() < 1 then
            return ACT_HL2MP_IDLE, GetTable( ply ).m_iSitSequence
        end
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
    if not IsFirstTimePredicted() then return end

    if IsSitting( ply ) then
        if not ( key == IN_USE and ply:KeyDown( IN_WALK ) ) then return end

        RequestSitting( ply, false )
    else
        if not ( key == IN_USE and ply:KeyDown( IN_WALK ) ) then return end

        RequestSitting( ply, true )
    end
end )

if SERVER then
    -- vehicle:Fire("Lock") doesn't seem to work properly and still let player exit vehicle
    hook.Add( "CanExitVehicle", "PlayerSit", function( veh, ply )
        -- if veh == ply.m_eSitVehicle then return false end
    end )
end


-- if SERVER then
    concommand.Add( "sit", function( ply )
        RequestSitting( ply, not IsSitting( ply ) )
    end )
-- end


AddValidSitGroundSequence( DEFAULT_SEQUENCE_GROUND )
AddValidSitGroundSequence( "pose_ducking_01" )
AddValidSitGroundSequence( "sit_zen" )

AddValidSitEntitySequence( DEFAULT_SEQUENCE_ENTITY )