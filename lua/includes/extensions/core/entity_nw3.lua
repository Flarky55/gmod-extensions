--[[ Inspired: https://github.com/Pika-Software/nw3-vars
    This and "messenger.lua" have rough and MVP implementation as along with them I want to focus on Network Object System 
    
    But the idea is to keep NW vars as simple and fast as possible. Network Objects seems too complicated for the NW variables purpose
--]]

local ENTITY = FindMetaTable( "Entity" )

local messenger = net.Messenger( "NW3" )


local function InitNW3( ent )
    return messenger:CreateSync( ent )
end

local function RemoveNW3( ent )
    messenger:RemoveSync( ent )
end


function ENTITY:GetNW3Var( key, fallback )
    local sync = InitNW3( self )

    return sync:Get( key, fallback )
end

function ENTITY:SetNW3Var( key, value )
    local sync = InitNW3( self )

    sync:Set( key, value )
end

function ENTITY:SetNW3VarProxy( key, callback )
    local sync = InitNW3( self )
    
    sync:SetCallback( key, function( value )
        callback( self, value )
    end )
end


if SERVER then
    -- (?) is network actually unreliable here
    hook.Add( "PlayerInitialSpawn", "NW3", function( ply )
        for _, sync in pairs( messenger.Syncs ) do
            sync:Sync( ply )
        end
    end )
else
    hook.Add( "NetworkEntityCreated", "NW3", function( ent )
        InitNW3( ent )
    end )
end

hook.Add( "EntityRemoved", "NW3", function( ent, fullUpdate )
    if fullUpdate then return end

    RemoveNW3( ent ) 
end )