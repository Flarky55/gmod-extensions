local format = string.format
local Fetch = http.Fetch
local JSONToTable = util.JSONToTable

module( "steamapi", package.seeall )

    
local KEY = CreateConVar( "sv_api_steam", "", FCVAR_PROTECTED, "SteamAPI key" ):GetString()


ISteamUser = {}; do
    local URL = "https://api.steampowered.com/ISteamUser/%s/v%.4i/?key=%s"

    function ISteamUser.GetPlayerSummaries( steamids, onSuccess, onFailure )
        assert( KEY ~= "", "ConVar 'sv_api_steam' must not be empty." )

        assert( steamids,   "bad argument #1 ('steamids' must be provided)" )
        assert( onSuccess,  "bad argument #2 ('onSuccess' must be provided)" )

        onFailure = onFailure or ErrorNoHaltWithStack

        if istable( steamids ) then
            steamids = table.concat( steamids, "," )
        end

        Fetch( format( URL, "GetPlayerSummaries", 2, KEY ) .. "&steamids=" .. steamids, function( body, _, _, code )
            if code ~= 200 then
                onFailure( "HTTP " .. code )
                return
            end

            local result = JSONToTable( body )
            if not result then
                onFailure( "JSONToTable failed." )
                return
            end

            onSuccess( result.response.players )
        end, onFailure )
    end

    function ISteamUser.GetPlayerBans( steamids, onSuccess, onFailure )
        assert( KEY ~= "", "ConVar 'sv_api_steam' must not be empty." )

        assert( steamids,   "bad argument #1 ('steamids' must be provided)" )
        assert( onSuccess,  "bad argument #2 ('onSuccess' must be provided)" )

        onFailure = onFailure or ErrorNoHaltWithStack

        if istable( steamids ) then
            steamids = table.concat( steamids, "," )
        end

        Fetch( format( URL, "GetPlayerBans", 1, KEY ) .. "&steamids=" .. steamids, function( body, _, _, code )
            if code ~= 200 then
                onFailure( "HTTP " .. code )
                return
            end

            local result = JSONToTable( body )
            if not result then
                onFailure( "JSONToTable failed." )
                return
            end

            onSuccess( result.players )
        end, onFailure )
    end
end


ISteamNews = {}; do
    local URL = "http://api.steampowered.com/ISteamNews/GetNewsForApp/v0002/?appid=%s"

    function ISteamNews.GetNewsForApp( appid, onSuccess, onFailure, count )
        assert( appid,      "bad argument #1 ('appid' must be provided)" )
        assert( onSuccess,  "bad argument #2 ('onSuccess' must be provided)" )

        onFailure = onFailure or ErrorNoHaltWithStack

        local url = format( URL, appid )
        
        if count ~= nil then
            assert( isnumber( count ), "bad argument #4 (number expected)" )
            
            url = url .. "&count=" .. count
        end

        Fetch( url, function( body, _, _, code )
            if code ~= 200 then
                onFailure( "HTTP " .. code )
                return
            end

            local result = JSONToTable( body )
            if not result then
                onFailure( "JSONToTable failed." )
                return
            end

            onSuccess( result )
        end, onFailure )
    end
end