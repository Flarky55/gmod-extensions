if CLIENT then
    require( "hookextras" ) -- Outfitter

    function hook.AddOnLocalPlayer( eventName, identifier, func )    
        util.OnLocalPlayer( function()
            local lply = LocalPlayer()

            hook.Add( eventName, identifier, function( ... )
                return func( lply, ... )
            end )
        end )
    end    
end

function hook.AddOnce( eventName, identifier, func )
    hook.Add( eventName, identifier, function( ... )
        hook.Remove( eventName, identifier )
        return func( ... )
    end )
end