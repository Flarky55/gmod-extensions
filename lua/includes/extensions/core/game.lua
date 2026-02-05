if SERVER then
    local maps = {}

    for _, filename in file.Iterator( "maps/*.bsp", "GAME" ) do
        maps[#maps + 1] = filename:sub( 1, -5 )
    end

    SetGlobalTable( "Maps", maps )
    
    -- SetGlobal2Int( "MapChangeCount", game.GetMapChangeCount() )
end


function game.GetMaps()
    return GetGlobalTable( "Maps" )
end

-- if CLIENT then
--     function game.GetMapChangeCount()
--         return GetGlobal2Int( "MapChangeCount" )
--     end
-- end