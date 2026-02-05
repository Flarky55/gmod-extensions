local PLAYER = FindMetaTable( "Player" )

local GetNW2String = FindMetaTable( "Entity" ).GetNW2String

local KEY_FAKE          = "FakeNick"
local KEY_PERSISTENT    = "PersistentNick"


local EngineNick = PLAYER.EngineNick or PLAYER.Nick
PLAYER.EngineNick = EngineNick

local function Nick( ply )
    return GetNW2String( ply, KEY_FAKE, EngineNick( ply ) )
end
PLAYER.Nick     = Nick
PLAYER.Name     = Nick
PLAYER.GetName  = Nick

if SERVER then
    local function GetStoredPersistentNick( steamid )
        return util.GetPData( steamid, KEY_PERSISTENT )
    end
    player_manager.GetStoredPersistentNick = GetPersistentNick


    local function SetFakeNick( ply, nick )
        ply:SetNW2String( KEY_FAKE, nick )
    end
    PLAYER.SetFakeNick = SetFakeNick

    local function PersistentNick( ply )
        return ply:GetPData( KEY_PERSISTENT )
    end
    PLAYER.PersistentNick = PersistentNick

    local function SetPersistentNick( ply, nick )
        if nick == nil then
            ply:RemovePData( KEY_PERSISTENT )
        else
            ply:SetPData( KEY_PERSISTENT, nick )
        end
    end
    PLAYER.SetPersistentNick = SetPersistentNick


    hook.Add( "PlayerInitialSpawn", "PersistentNick", function( ply )
        local nick = PersistentNick( ply )
        if nick == nil then return end

        SetFakeNick( ply, nick ) 
    end )
end