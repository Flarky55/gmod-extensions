function cvars.CallbackValue( callback )
    return function( _, _, value )
        callback( value )
    end
end