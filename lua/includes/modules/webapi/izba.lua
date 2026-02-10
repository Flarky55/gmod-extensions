local Fetch = http.Fetch
local JSONToTable = util.JSONToTable

module( "webapi.izba", package.seeall )


URL = "http://izbushechka.su/api/"


function GetPlayer( steamid64, onSuccess, onFailure )
    assert( steamid64,  "bad argument #1 ('steamid64' must be provided)" )
    assert( onSuccess,  "bad argument #2 ('onSuccess' must be provided)" )

    onFailure = onFailure or ErrorNoHaltWithStack

    Fetch( URL .. "player?s=" .. steamid64, function( body, _, _, code )
        if code ~= 200 then
            onFailure( "HTTP " .. code )
            return
        end
        
        local result = JSONToTable( body )
        if not result then
            onFailure( "JSONToTable failed" )
            return
        end

        onSuccess( result )
    end, onFailure )
end