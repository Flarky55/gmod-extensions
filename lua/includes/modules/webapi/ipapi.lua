local Fetch = http.Fetch
local JSONToTable = util.JSONToTable

module( "webapi.ipapi", package.seeall )


URL = "http://ip-api.com/json/"


function GetAll( ip, onSuccess, onFailure )
    assert( ip,         "bad argument #1 ('ip' must be provided)" )
    assert( onSuccess,  "bad argument #2 ('onSuccess' must be provided)" )

    onFailure = onFailure or ErrorNoHaltWithStack

    Fetch( URL .. ip, function( body, _, _, code )
        if code ~= 200 then
            onFailure( "HTTP " .. code )
            return
        end

        local result = JSONToTable( body )
        if not result then
            onFailure( "JSONToTable failed." )
            return
        end
        
        if result.status ~= "success" then
            onFailure( result.message )
            return
        end
        
        onSuccess( result )
    end, onFailure )
end