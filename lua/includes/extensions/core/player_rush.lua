local PLAYER = FindMetaTable( "Player" )

local META_ENTITY = FindMetaTable( "Entity" )

local SetNW2Bool, GetNW2Bool = META_ENTITY.SetNW2Bool, META_ENTITY.GetNW2Bool
local Alive, GetMoveType, WaterLevel, GetTable, OnGround = META_ENTITY.Alive, META_ENTITY.GetMoveType, META_ENTITY.WaterLevel, META_ENTITY.GetTable, META_ENTITY.OnGround
local Crouching = PLAYER.Crouching
local SharedRandomInt = util.SharedRandomInt
local hook_Run = hook.Run
local IsFirstTimePredicted = IsFirstTimePredicted

local KEY = "Rush"

local SEQUENCES_RUN = { 
    "run_all_02",
    "run_all_panicked_01", "run_all_panicked_02", "run_all_panicked_03",
    "run_all_protected",
}

local SEQUENCES_STAND = {

}

local function SharedRadomIntRush( m, n )
    return SharedRandomInt( "Rush", m, n )
end


local function IsRushing( ply )
    return GetNW2Bool( ply, KEY, false )
end
PLAYER.IsRushing = IsRushing

local function CanRush( ply )
    return Alive( ply )
        and GetMoveType( ply ) == MOVETYPE_WALK
        and OnGround( ply )
        and not Crouching( ply )
        and WaterLevel( ply ) < 2
        and hook_Run( "CanPlayerRush", ply ) ~= false
end

local function StartRush( ply )
    SetNW2Bool( ply, KEY, true )

    if IsFirstTimePredicted() then
        local plyTbl = GetTable( ply )

        -- stand sequence
        plyTbl.m_iRushSequence = ply:LookupSequence(
            table.RandomSeq( SEQUENCES_RUN, SharedRadomIntRush )
        ) 
    end
end

local function StopRush( ply )
    SetNW2Bool( ply, KEY, false )
    
    if IsFirstTimePredicted() then
        local plyTbl = GetTable( ply )
        
        plyTbl.m_iRushSequence = nil
        plyTbl.m_bRushForward = nil
    end
end


hook.Add( "KeyDoublePress", "Rush", function( ply, key )
    if IsRushing( ply ) then return end
    
    if key == IN_SPEED and CanRush( ply ) then
        StartRush( ply )
    end 
end )

hook.Add( "Move", "Rush", function( ply, mv )
    if not IsRushing( ply ) then return end

    if mv:KeyReleased( IN_SPEED ) or not CanRush( ply ) then
        StopRush( ply )
        return
    end

    local plyTbl = GetTable( ply )

    local m_bRushForward = mv:KeyDown( IN_FORWARD )

    if m_bRushForward then
        -- `SetMaxSpeed` must be set manually in "Move" hook
        --  https://wiki.facepunch.com/gmod/CMoveData:SetMaxClientSpeed#description
        local speed = mv:GetMaxClientSpeed() * 1.5
        mv:SetMaxClientSpeed( speed )
        mv:SetMaxSpeed( speed )

        mv:SetSideSpeed( mv:GetSideSpeed() * 0.2 )
    end

    plyTbl.m_bRushForward = m_bRushForward
end )

hook.Add( "CalcMainActivity", "Rush", function( ply, vel )
    if not IsRushing( ply ) then return end
    
    local plyTbl = GetTable( ply )

    if plyTbl.m_bRushForward then
        return ACT_RUN, plyTbl.m_iRushSequence
    end
end )

hook.Add( "StartCommand", "Rush", function( ply, cmd )
    if not IsRushing( ply ) then return end

    local plyTbl = GetTable( ply )
    
    if plyTbl.m_bRushForward then
        cmd:RemoveKey( IN_ATTACK )
    end
end )

if SERVER then
    
    -- hook.Add( "PlayerConsumeStamina", "Rush", function( ply )
    --     if IsRushing( ply ) then return 2 end
    -- end )

else

    hook.AddOnLocalPlayer( "AdjustMouseSensivity", "Rush", function( lply, defaultSensivity )
        if not IsRushing( lply ) then return end

        if GetTable( lply ).m_bRushForward then
            return 0.3
        end
    end )

end