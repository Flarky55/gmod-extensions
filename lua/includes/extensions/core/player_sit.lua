local PLAYER = FindMetaTable( "Player" )

local META_ENTITY = FindMetaTable( "Entity" )

local GetNw2Bool, GetNW2Entity = META_ENTITY.GetNW2Bool, META_ENTITY.GetNW2Entity

local KEY_GROUND = "SitGround"
local KEY_ENTITY = "SitEntity"

if CLIENT then
    CreateClientConVar( "cl_allow_sit", 1, true, true, "Allow players to sit on you.", 0, 1 )
end


local function IsSittingOnGround( ply )
    return GetNW2Bool( ply, KEY )
end
PLAYER.IsSittingOnGround = IsSittingOnGround

local function IsSittingOnEntity( ply, target )
    if target == nil then
        return GetNW2Entity( ply, KEY_ENTITY ) ~= NULL
    end
    
    return GetNW2Entity( ply, KEY_ENTITY ) == target
end
PLAYER.IsSittingOnPlayer = IsSittingOnPlayer

local function GetSittingPlayers( ply )
    -- array of players who sits on ply
end

if SERVER then
    local function RequestSittingOnGround( ply, state )
        ply:SetNW2Bool( KEY, state )
    end

    local function RequestSittingOnEntity( ply, target, state )

    end


    -- concommand.Add( "" )
end


hook.Add( "CalcMainActivity", "GroundSit", function( ply, vel )
    if not IsSittingOnGround( ply ) then return end
    
    if vel:Length2DSqr() < 1 then
        return ACT_HL2MP_IDLE, ply:LookupSequence( "pose_ducking_02" )
    end
end )

hook.Add( "StartCommand", "GroundSit", function( ply, cmd )
    if not IsSittinOnGround( ply ) then return end

    if cmd:KeyDown( IN_DUCK ) then
        return
    end

    cmd:ClearMovement()
end )