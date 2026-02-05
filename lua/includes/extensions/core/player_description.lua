local PLAYER = FindMetaTable( "Player" )
local ENTITY = FindMetaTable( "Entity" )

local GetNW3Var = ENTITY.GetNW3Var

local KEY = "Description"

local Descriptions = {}


local function AddValidDescription( id, name )
    Descriptions[id] = { name = name }
end
player_manager.AddValidDescription = AddValidDescription

local function AllValidDescriptions()
    return Descriptions
end
player_manager.AllValidDescriptions = AllValidDescriptions


local function GetDescription( ply, id )
    return GetNW3Var( KEY .. id )
end
PLAYER.GetDescription = GetDescription

if SERVER then    
    local function SetDescription( ply, id, text )
        ply:SetNW3Var( KEY .. id, text )
    end
    PLAYER.SetDescription = SetDescription
    

    util.AddNetworkString( "SetLocalPlayerDescription" )
    
    net.Receive( "SetLocalPlayerDescription", function( _, ply )
        local id = net.ReadString()
        if Descriptions[id] == nil then return end

        local text = net.ReadString()

        SetDescription( ply, id, text )
    end )
else
    local function GetLocalPlayerDescription( id )
        return cookie.GetString( KEY .. id )
    end

    local function SetLocalPlayerDescription( id, text )
        cookie.Set( KEY .. id )

        net.Start( "SetLocalPlayerDescription" )
            net.WriteString( id )
            net.WriteString( text )
        net.SendToServer()
    end
end