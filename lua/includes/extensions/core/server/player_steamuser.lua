require( "webapi/steam" )

local PLAYER = FindMetaTable( "Player" )


hook.Add( "PlayerInitialSpawn", "SteamUser", function( ply )
    local SteamUser = { Summary = {} }
    ply.SteamUser = SteamUser

    webapi.steam.ISteamUser.GetPlayerSummaries( ply:SteamID64(), function( result )
        if not IsValid( ply ) then return end

        SteamUser.Summary = result

        hook.Run( "PlayerSteamUserFetched", ply, SteamUser )
    end )
end )