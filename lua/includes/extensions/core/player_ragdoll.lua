--[[
    NW2 variables are fucking up

    https://github.com/Facepunch/garrysmod-issues/issues/5455
    https://github.com/RaphaelIT7/gmod-holylib?tab=readme-ov-file#nw2

    This bug happens under the following scenario:

    An new entity spawns the first time / no entity of it's class was created before.
    Then on this new entity - a NW2Var is set with it's creation.
--]]

local PLAYER = FindMetaTable( "Player" )
local ENTITY = FindMetaTable( "Entity" )

local GetNW3Var = ENTITY.GetNW3Var

local KEY_PLAYER_RAGDOLL = "Ragdoll"
local KEY_RAGDOLL_PLAYER    = "Player" 
local KEY_RAGDOLL_COLOR     = "Color"


local function GetNetRagdollEntity( ply )
    return GetNW3Var( ply, KEY_PLAYER_RAGDOLL )
end
PLAYER.GetNetRagdollEntity = GetNetRagdollEntity

local function IsRagdolled( ply )
    return IsValid( GetNetRagdollEntity( ply ) )
end
PLAYER.IsRagdolled = IsRagdolled

local function IsNetworkedRagdoll( ent )

end

if SERVER then
    local function PlayerRagdollRemoved( ent )
        -- hook.Run( "PlayerRagdollRemoved", ent )
    end

    local function CreateNetworkedRagdoll( ply, position, velocity )
        local ragdoll = ents.Create( "prop_ragdoll" )
        if not IsValid( ragdoll ) then return end

        local model, skinIndex, color = ply:GetModel(), ply:GetSkin(), ply:GetPlayerColor()
        local subModelIds = ""; do
            for id = 0, ply:GetNumBodyGroups() do
                subModelIds = subModelIds .. ply:GetBodygroup( id )
            end
        end

        ragdoll:SetPos( position )
        ragdoll:SetModel( model )
        ragdoll:SetSkin( skinIndex )
        ragdoll:SetBodyGroups( subModelIds )
        ragdoll:SetNW3Var( KEY_RAGDOLL_COLOR, color )
        ragdoll:SetNW3Var( KEY_RAGDOLL_PLAYER, ply )

        ragdoll:AddEFlags( EFL_KEEP_ON_RECREATE_ENTITIES )

        ragdoll:Spawn()
        ragdoll:Activate()

        return ragdoll
    end


    local function UnRagdoll( ply )
        if not IsRagdolled( ply ) then return end

        local ragdoll = GetNetRagdollEntity( ply )

        ply:SetNW3Var( KEY_PLAYER_RAGDOLL, nil )
    end
    PLAYER.UnRagdoll = UnRagdoll

    local function Ragdoll( ply )
        if IsRagdolled( ply ) then return end

        local ragdoll = CreateNetworkedRagdoll( ply, ply:GetPos(), ply:GetVelocity() )
        if not IsValid( ragdoll ) then return end

        ply:SetNW3Var( KEY_PLAYER_RAGDOLL, ragdoll )
    end
    PLAYER.Ragdoll = Ragdoll
end


hook.Add( "EntityNetworkedVarChanged", "PlayerNetworkedRagdoll", function( ent, name, oldValue, newValue )
    local fullUpdate = oldValue == nil

    if name == KEY_RAGDOLL_COLOR then

        ent.GetPlayerColor = function() return newValue end

    elseif name == KEY_RAGDOLL_PLAYER then

    end
end )


if SERVER then
    concommand.Add( "ragdoll", function( ply )
        if hook.Run( "CanPlayerRagdoll", ply ) == false then return end

        if IsRagdolled( ply ) then
            ply:UnRagdoll()
        else
            ply:Ragdoll()
        end
    end )
end