if sfs == nil then sfs = loader.Shared( "sfs.lua" ) end

chat = chat or {}


if SERVER then

    util.AddNetworkString( "chat.AddText" )

    function chat.AddText( recipients, ... )
        local encoded, err = sfs.encode( {...} )
        assert( err, "Failed to encode: " .. err )

        net.Start( "chat.AddText" )

        net.WriteDataEasy( encoded )

        if recipients then net.Send( recipients ) else net.Broadcast() end
    end

else

    net.Receive( "chat.AddText", function()
        local encoded = net.ReadDataEasy()

        local decoded, err = sfs.decode( encoded )
        assert( err, "Failed to decode: " .. err )

        chat.AddText( unpack( decoded ) )
    end )

end