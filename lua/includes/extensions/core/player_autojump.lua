local PLAYER = FindMetaTable( "Player" )

local META_ENTITY       = FindMetaTable( "Entity" )
local META_CMoveData    = FindMetaTable( "CMoveData" )

local GetInfoNum, GetRunSpeed = PLAYER.GetInfoNum, PLAYER.GetRunSpeed
local Alive, GetMoveType, WaterLevel, IsOnGround = META_ENTITY.Alive, META_ENTITY.GetMoveType, META_ENTITY.WaterLevel, META_ENTITY.IsOnGround
local KeyDown, KeyWasDown, RemoveKey, SetMaxClientSpeed, SetMaxSpeed = META_CMoveData.KeyDown, META_CMoveData.KeyWasDown, META_CMoveData.RemoveKey, META_CMoveData.SetMaxClientSpeed, META_CMoveData.SetMaxSpeed
local hook_Run = hook.Run

local NAME_CVAR = "cl_autojump" 

if CLIENT then
    CreateClientConVar( NAME_CVAR, 1, true, true, nil, 0, 1 )
end


local function CanAutoJump( ply )
    return GetInfoNum( ply, NAME_CVAR, 1 ) == 1 -- GetInfoNum looks very expensive
        and Alive( ply )
        and GetMoveType( ply ) == MOVETYPE_WALK
        and WaterLevel( ply ) < 2
        and hook_Run( "CanPlayerAutoJump", ply ) ~= false
end

-- To do it more properly, we should use "StartCommand" hook and remove IN_JUMP there

-- It is necessary to use exactly "Move" hook as here we can adjust player's max speed
--  When player starts crouching, it loses its speed somewhere in the Source Engine, but here we overrides it
hook.Add( "Move", "AutoJump", function( ply, mv )
    if KeyDown( mv, IN_JUMP ) then
        if not CanAutoJump( ply ) then return end

        -- `SetMaxSpeed` must be set manually in "Move" hook
        --  https://wiki.facepunch.com/gmod/CMoveData:SetMaxClientSpeed#description
        local speed = GetRunSpeed( ply )
        SetMaxClientSpeed( mv, speed )
        SetMaxSpeed( mv, speed )

        if KeyWasDown( mv, IN_JUMP ) and IsOnGround( ply ) then
            RemoveKey( mv, IN_JUMP )
        end
    end
end )