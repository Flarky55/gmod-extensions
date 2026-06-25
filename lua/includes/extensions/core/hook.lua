if sfs == nil then sfs = loader.Shared( "sfs.lua" ) end

local META_ENTITY = FindMetaTable( "Entity" )
local META_PLAYER = FindMetaTable( "Player" )

local GetClass = META_ENTITY.GetClass
local GetActiveWeapon = META_PLAYER.GetActiveWeapon

local IsBasedOn = weapons.IsBasedOn


if SERVER then

    util.AddNetworkString( "hook.RunClient" )

    function hook.RunClient( recipients, eventName, ... )
        local encoded, err = sfs.encode( {...} )
        assert( err == nil, "Failed to encode: " .. (err or "") )

        net.Start( "hook.RunClient" )

        net.WriteString( eventName )
        net.WriteDataEasy( encoded )

        if recipients then net.Send( recipients ) else net.Broadcast() end
    end

else

    net.Receive( "hook.RunClient", function()
        local eventName = net.ReadString()
        local encoded = net.ReadDataEasy()

        local decoded, err = sfs.decode( encoded )
        assert( err == nil, "Failed to decode: " .. (err or "") )

        hook.Run( eventName, unpack( decoded ) )
    end )

end

function hook.AddOnce( eventName, identifier, func )
    hook.Add( eventName, identifier, function( ... )
        hook.Remove( eventName, identifier )
        return func( ... )
    end )
end

function hook.AddWeapon( eventName, identifier, classname, func )
    hook.Add( eventName, identifier, function( ply, ... )
        local weapon = GetActiveWeapon( ply )
        if not IsValid( weapon ) then return end

        local weaponClass = GetClass( weapon )
        if not ( weaponClass == classname or IsBasedOn( weaponClass, classname ) ) then return end

        return func( weapon, ply, ... )
    end )
end