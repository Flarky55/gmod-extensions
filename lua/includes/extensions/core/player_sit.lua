local PLAYER = FindMetaTable( "Player" )

local META_ENTITY = FindMetaTable( "Entity" )
local META_CMoveData = FindMetaTable( "CMoveData" )

local GetNW2Bool, GetNW2Entity = META_ENTITY.GetNW2Bool, META_ENTITY.GetNW2Entity

local KEY_GROUND = "SitGround"
local KEY_ENTITY = "SitEntity"

if CLIENT then
    CreateClientConVar( "cl_allow_sit", 1, true, true, "Allow players to sit on you.", 0, 1 )
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
PLAYER.IsSittingOnPlayer = IsSittingOnPlayer

local function GetSittingPlayers( ply )
    -- array of players who sits on ply
end


local function RequestSittingOnGround( ply, state )
    ply:SetNW2Bool( KEY_GROUND, state )
end

local function RequestSittingOnEntity( ply, target, state )
    
end


hook.Add( "CalcMainActivity", "PlayerSit", function( ply, vel )
    if not IsSittingOnGround( ply ) then return end
    
    if vel:Length2DSqr() < 1 then
        return ACT_HL2MP_IDLE, ply:LookupSequence( "pose_ducking_02" )
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
    if IsSittingOnGround( ply ) then
        if not ( key == IN_JUMP ) then return end

        RequestSittingOnGround( ply, false )
    else
        if not ( key == IN_USE and ply:KeyDown( IN_WALK ) ) then return end

        RequestSittingOnGround( ply, true )
    end
end )