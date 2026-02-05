local MAPCATEGORY_DEFAULT = "Sandbox"

local MAPTAG_DEFAULT = { Name = "Default", Color = Color( 0, 255, 0 ) }

local CATEGORIES = {
    ["gm"] = MAPCATEGORY_DEFAULT
}

local function GetMapCategory( map )
    local prefix = string.match( map, "%w+[^_]" )

    return CATEGORIES[prefix] or CATEGORIES[map] or MAPCATEGORY_DEFAULT
end

local function GetMapTags( map )
    return list.GetEntry( "MapTags", map )
end


list.Set( "MapTags", "gm_construct", { MAPTAG_DEFAULT } )
list.Set( "MapTags", "gm_flatgrass", { MAPTAG_DEFAULT } )
