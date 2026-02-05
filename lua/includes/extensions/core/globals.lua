local META_PLAYER = FindMetaTable( "Player" )
local META_WEAPON = FindMetaTable( "Weapon" )


function isplayer( any )
    return getmetatable( any ) == META_PLAYER
end

function isweapon( any )
    return getmetatable( any ) == META_WEAPON
end

if SERVER then
   function SafeRemoveMapCreatedEntity( id )
        local e = ents.GetMapCreatedEntity( id )
        if not IsValid( e ) then return false end
        
        e:Remove()

        return true
    end 
end


--[[
        Persisted Table
        https://github.com/conred-gmod/stp_libcore/blob/dev/lua/stp/core/hotreload_sh.lua
--]]
do
    __persistdata = __persistdata or {}

    local function UnlockPersistData()
        __persistdata_unlocked = true

        local HOOK_NAME = "PersistTableLock"
        
        hook.Add( "Tick", HOOK_NAME, function()
            __persistdata_unlocked = false
            hook.Remove( "Tick", HOOK_NAME )
        end )
    end

    UnlockPersistData()

    hook.Add( "OnReloaded", "PersistTableUnlock", UnlockPersistData )


    function PersistedTable( name, default )
        if __persistdata[name] == nil then
            assert( __persistdata_unlocked, "Function called in wrong time (not before first game tick)" )
            
            __persistdata[name] = default
            
            return default
        end

        return __persistdata[name]
    end
end

--[[
        Player Bound Table
--]]
do
    local UserID = META_PLAYER.UserID


    local mt_table = {}

    function mt_table:__index( k )
        assert( isplayer( k ), "Key must be a Player" )

        return rawget( self, UserID( k ) )
    end

    function mt_table:__newindex( k, v )
        assert( isplayer( k ), "Key must be a Player" )

        rawset( self, UserID( k ), v )
    end


    local Instances = PersistedTable( "PlayerBoundTable", {} )

    -- (?) More reliable than "EntityRemoved" hook
    gameevent.Listen( "player_disconnect" )
    hook.Add( "player_disconnect", "PlayerBoundTable", function( data )
        local userid = data.userid

        for _, instance in pairs( Instances ) do
            rawset( instance, userid, nil )
        end
    end ) 


    function PlayerBoundTable( name )
        if Instances[name] == nil then 
            Instances[name] = setmetatable( {}, mt_table )
        end

        return Instances[name]
    end
end

--[[
        Mutable Number
--]]
do
    local function add( mut, n )
        mut.value = mut.value + n
        return mut
    end

    local function sub( mut, n )
        mut.value = mut.value - n
        return mut
    end

    local function mul( mut, n )
        mut.value = mut.value * n
        return mut
    end

    local function div( mut, n )
        mut.value = mut.value / n
        return mut
    end

    local function eval( a, b, fn )
        if isnumber( a ) then
            return fn( b, a )
        end

        if isnumber( b ) then
            return fn( a, b )
        end

        -- TODO: change error
        error( "number expected" )
    end


    local mt = {}

    function mt:__tostring()
        return "MutableNumber(" .. self.value .. ")"
    end

    function mt.__add(a, b)
        return eval( a, b, add )
    end

    function mt.__sub(a, b)
        return eval( a, b, sub )
    end
    
    function mt.__mul(a, b)
        return eval( a, b, mul )
    end

    function mt.__div(a, b)
        return eval( a, b, div )
    end


    function MutableNumber( value )
        return setmetatable( { value = value or 0 }, mt )
    end
end

--[[
        Global Table
--]]
do
    if sfs == nil then sfs = include( "sfs.lua" ) end

    local GlobalTables = PersistedTable( "GlobalTables", {} )

    if SERVER then
        util.AddNetworkString( "SendGlobalTables" )
        util.AddNetworkString( "SetGlobalTable" )


        function SetGlobalTable( key, tbl )
            GlobalTables[key] = tbl

            local encoded = sfs.encode( { key, tbl } )

            net.Start( "SetGlobalTable" )
                net.WriteData( encoded )
            net.Broadcast()
        end

        hook.Add( "PlayerInitialSpawn", "GlobalTables", function( ply )
            local encoded = sfs.encode( GlobalTables )
            
            net.Start( "SendGlobalTables" )
                net.WriteData( encoded )
            net.Send( ply )
        end )
    else
        net.Receive( "SendGlobalTables", function( len )
            local data = net.ReadData( len / 8 )
            local decoded = sfs.decode( data )

            GlobalTables = decoded
        end )

        net.Receive( "SetGlobalTable", function( len )
            local data = net.ReadData( len / 8 )
            local decoded = sfs.decode( data )

            local key, tbl = decoded[1], decoded[2]

            GlobalTables[key] = tbl
        end )
    end

    function GetGlobalTable( key )
        return GlobalTables[key]
    end
end


if SERVER then
    require( "schedule" )

    -- TODO: throttle by player
    local UpdatePlayerModel = schedule.throttle( function( ply )
        player_manager.RunClass( ply, "SetModel" )

        ply:SetupHands()
    end, 1 )

    local FUNCS = {
        ["cl_playermodel"]      = UpdatePlayerModel,
        ["cl_playerbodygroups"] = UpdatePlayerModel,
        ["cl_playerskin"]       = UpdatePlayerModel,
        -- https://github.com/Facepunch/garrysmod/blob/191339e123edf359d298652ad64cf2cb82c7158f/garrysmod/gamemodes/sandbox/gamemode/player_class/player_sandbox.lua#L106-L107
        ["cl_playercolor"] = function( ply )
            local value = ply:GetInfo( "cl_playercolor" )
            ply:SetPlayerColor( Vector( value ) )
        end,
        -- https://github.com/Facepunch/garrysmod/blob/191339e123edf359d298652ad64cf2cb82c7158f/garrysmod/gamemodes/sandbox/gamemode/player_class/player_sandbox.lua#L109-L113
        ["cl_weaponcolor"] = function( ply )
            local value = Vector( ply:GetInfo( "cl_weaponcolor" ) )
            if value:Length() < 0.001 then
                value = Vector( 0.001, 0.001, 0.001 )
            end
            ply:SetWeaponColor( value )
        end
    }


    util.AddNetworkString( "RequestLocalPlayerUpdate" )
    
    net.Receive( "RequestLocalPlayerUpdate", function( len, ply )
        if not ply:Alive() then return end

        local name = net.ReadString()

        local func = FUNCS[name]
        if func == nil then return end

        func( ply )
    end )
else
    local function Callback( name )
        net.Start( "RequestLocalPlayerUpdate" )
            net.WriteString( name )
        net.SendToServer()
    end

    for _, name in ipairs( { "cl_playermodel", "cl_playerbodygroups", "cl_playerskin", "cl_playercolor", "cl_weaponcolor" } ) do
        cvars.AddChangeCallback( name, Callback, "LocalPlayerUpdate" )
    end
end


if CLIENT then
    local GetTimeoutInfo = GetTimeoutInfo

    local g_timingOut = false
    
    hook.Add( "Tick", "TimeoutInfoChanged", function()
        local timingOut, lastPingReceivedTime = GetTimeoutInfo()
    
        if g_timingOut ~= timingOut then
            g_timingOut = timingOut
            hook.Run( "TimeoutInfoChanged", timingOut, lastPingReceivedTime )
        end
    end )
end


if CLIENT then
    -- https://github.com/Pika-Software/glua-patches/blob/e1114959dbf167dd90251b18039bece25bd05170/lua/glua-patches/client-server.lua#L365-L392
    local ENTITY_IsValid = FindMetaTable( "Entity" ).IsValid

    local LocalPlayer = _G.LocalPlayer
    local NULL = _G.NULL

    local player_entity = nil

    rawset( _G, "LocalPlayer", function()
        if player_entity == nil then
            local entity = LocalPlayer()
            if entity ~= nil and ENTITY_IsValid( entity ) then
                rawset( _G, "LocalPlayer", function()
                    return entity
                end )

                player_entity = entity
                return entity
            end

            return NULL
        end

        return player_entity
    end )
end