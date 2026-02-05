local META_PLAYER = FindMetaTable( "Player" )
local EngineNick, UserID, SteamID = META_PLAYER.EngineNick, META_PLAYER.UserID, META_PLAYER.SteamID

local date = os.date
local ServerLog, MsgC = ServerLog, MsgC


function ServerLog_FormatPlayerString( nick, userid, steamid )
    return "\"" .. nick .. "<" .. userid .. "><" .. steamid .. ">\""
end

function ServerLog_FormatPlayer( ply )
    return ServerLog_FormatPlayerString( EngineNick( ply ), UserID( ply ), SteamID( ply ) )
end


local function Log( str, ignoreFile )
    MsgC( date( "L %x - %X" ), color_white, " " .. str .. "\n" )

    if not ignoreFile then
        ServerLog( str .. "\n" )
    end
end


local function Initialize()
    for hookName, log in pairs( list.GetForEdit( "ServerLogs" ) ) do
        hook.Add( hookName, "ServerLog", function( ... )
            local str, ignoreFile = log( Log, ... )
            if str == nil then return end

            Log( str, ignoreFile )
        end, PRE_HOOK )
    end
end

Initialize()

hook.AddOnce( "Initialize", "ServerLogs", Initialize )