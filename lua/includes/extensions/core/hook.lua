if sfs == nil then sfs = loader.Shared( "sfs.lua" ) end

if SERVER then

    util.AddNetworkString( "hook.RunClient" )

    function hook.RunClient( recipients, eventName, ... )
        local encoded, err = sfs.encode( {...} )
        assert( err, "Failed to encode: " .. err )

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
        assert( err, "Failed to decode: " .. err )

        hook.Run( eventName, unpack( decoded ) )
    end )

end

function hook.AddOnce( eventName, identifier, func )
    hook.Add( eventName, identifier, function( ... )
        hook.Remove( eventName, identifier )
        return func( ... )
    end )
end