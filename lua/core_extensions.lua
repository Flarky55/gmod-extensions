if __core_extensions then return end
__core_extensions = true

AddCSLuaFile()

include( "includes/loader.lua" )


if SERVER then
    loader.List( "includes/modules", {
        
        "deferred.lua",
        "injector.lua",
        "map.lua",

    }, loader.REALM_CLIENT )
end

loader.List( "includes/extensions/core", {
    
    "globals.lua",

    "utf8.lua",
    "hook.lua",

    "cvars.lua",
    "file.lua",
    "game.lua",
    "table.lua",
    "math.lua",
    "net.lua",
    "net_messenger.lua",
    "util.lua",
    
    "cmovedata.lua",
    "entity_nw3.lua",
    "player.lua",
    
    "player_autojump.lua",
    "player_description.lua",
    "player_nick.lua",
    "player_oxygen.lua",
    "player_ragdoll.lua",
    "player_rush.lua",
    "player_stamina.lua",

}, loader.REALM_SHARED)

loader.Dir( "includes/extensions/core/server", loader.REALM_SERVER, nil, false )
loader.Dir( "includes/extensions/core/client", loader.REALM_CLIENT, nil, false )

loader.Dir( "includes/core",        loader.REALM_SHARED, nil, false )
loader.Dir( "includes/core/server", loader.REALM_SERVER, nil, false )
loader.Dir( "includes/core/client", loader.REALM_CLIENT, nil, false )

loader.Dir( "vgui/core", loader.REALM_CLIENT, nil, false )