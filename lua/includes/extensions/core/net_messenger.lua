-- Inspired: https://github.com/Pika-Software/net-messager

if SERVER then
    AddCSLuaFile( "sfs.lua" )
end

sfs = sfs or include( "sfs.lua" )


local ACTION_SYNC   = 0
local ACTION_REMOVE = 1

local Actions = {
    [ACTION_SYNC] = function( messenger, id )
        local sync = messenger:GetSync( id )
        if sync == nil then return end

        local length = net.ReadUInt( 16 )
        local encoded = net.ReadData( length )

        local data = sfs.decode( encoded )

        sync:Set( data[1], data[2] )
    end,
    [ACTION_REMOVE] = function( messenger, id )
        local sync = messenger:GetSync( id )
        if sync == nil then return end

        messenger:RemoveSync( id )
    end
}


local SYNC = {}
SYNC.__index = SYNC

function SYNC:Get( key, default )
    return self.Data[key] or default
end

function SYNC:Set( key, value )
    self.Data[key] = value

    if SERVER then
        self:Send( key, value )
    end

    local callback = self.Callbacks[key]
    if callback ~= nil then
        callback( value )
    end
end

function SYNC:SetCallback( key, callback )
    self.Callbacks[key] = callback
end

if SERVER then
    function SYNC:Send( key, value, ply )
        local encoded = sfs.encode( { key, value } )

        self.Messenger:Start()
            net.WriteUInt( ACTION_SYNC, 2 )
            net.WriteType( self.Id )
            
            net.WriteUInt( #encoded, 16 )
            net.WriteData( encoded )
        self.Messenger:Send( ply )
    end

    function SYNC:Sync( ply )
        for k, v in pairs( self.Data ) do
            self:Send( k, v, ply )
        end
    end
end


local MESSENGER = {}
MESSENGER.__index = MESSENGER

if SERVER then
    function MESSENGER:Start()
        net.Start( self.NetworkString )
    end

    function MESSENGER:Send( recipients )
        if recipients == nil then
            net.Broadcast()
            return
        end

        net.Send( recipients )
    end
end

function MESSENGER:GetSync( identifier )
    return self.Syncs[identifier]
end

function MESSENGER:CreateSync( identifier )
    local sync = self:GetSync( identifier )
    if sync ~= nil then return sync end

    sync = setmetatable( {
        Id = identifier,
        Messenger = self,

        Data = {},
        Callbacks = {},
    }, SYNC )

    self.Syncs[identifier] = sync

    return sync
end

function MESSENGER:RemoveSync( identifier )
    local sync = self:GetSync( identifier )
    if sync == nil then return end

    if SERVER then
        self:Start()
            net.WriteUInt( ACTION_REMOVE, 2 )
            net.WriteType( sync.Id )
        self:Send()
    end

    self.Syncs[identifier] = nil
end


function net.Messenger( name )
    local instance = setmetatable( {
        NetworkString = name,

        Syncs = {},
    }, MESSENGER )

    if SERVER then
        util.AddNetworkString( name )
    else
        net.Receive( name, function()
            local actionId = net.ReadUInt( 2 )
            local action = Actions[actionId]
            if action == nil then return end

            action( instance, net.ReadType() )
        end )
    end

    return instance
end