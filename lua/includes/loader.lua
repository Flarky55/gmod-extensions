-- Using `module` makes impossilbe to hot-load included files
if loader ~= nil then return end

AddCSLuaFile()


local match, gmatch, format, GetFileFromFilename = string.match, string.gmatch, string.format, string.GetFileFromFilename
local sort = table.sort
local Find = file.Find
local include, AddCSLuaFile = include, AddCSLuaFile


local loader = {}
_G.loader = loader


local REALM_SERVER = 0; loader.REALM_SERVER = REALM_SERVER
local REALM_CLIENT = 1; loader.REALM_CLIENT = REALM_CLIENT
local REALM_SHARED = 2; loader.REALM_SHARED = REALM_SHARED

loader.Server = SERVER and include      or function() end
loader.Client = SERVER and AddCSLuaFile or include
loader.Shared = function( filepath )
    if SERVER then AddCSLuaFile( filepath ) end
    return include( filepath )
end

local FUNCTIONS_INCLUDE = {
    [REALM_SERVER] = loader.Server,
    [REALM_CLIENT] = loader.Client,
    [REALM_SHARED] = loader.Shared
}


local GetRealmFromFilename; do
    local PATTERNS = { "^(%a+)_", "_(%a)%.lua$" }

    local REALMS = {
        ["sv"] = REALM_SERVER,
        ["cl"] = REALM_CLIENT,
        ["sh"] = REALM_SHARED
    }

    GetRealmFromFilename = function( filename )
        for i = 1, #PATTERNS do         
            local substring = match( filename, PATTERNS[i] )
            if substring == nil then continue end

            local realm = REALMS[substring]
            
            if realm ~= nil then
                return realm
            end
        end

        return nil
    end
end

local function GetIncludeFromFilename( filename )
    local realm = GetRealmFromFilename( filename )
    if realm == nil then return nil end
        
    return FUNCTIONS_INCLUDE[realm], realm
end


local function File_Internal( filepath, callback, fnInclude )
    if callback ~= nil then
        callback( filepath, realm, fnInclude( filepath ) )
    else
        return fnInclude( filepath )
    end
end

local function Dir_Internal( root, fnFile, callback, recursive, order, ... )
    recursive = recursive ~= false

    root = root .. "/"

    local files, dirs = Find( root .. "*", "LUA" )

    if order ~= nil then
        sort( files, function( a, b )
            local a_order, b_order = order[a], order[b]

            if a_order ~= nil or b_order ~= nil then
                return (a_order or 0) > (b_order or 0)
            end

            return a < b
        end )
    end
    
    for i = 1, #files do
        fnFile( root .. files[i], callback, ... )
    end

    if recursive then
        for i = 1, #dirs do
            Dir_Internal( root .. dirs[i], fnFile, callback, recursive, order, ... )
        end
    end
end


--[[
        Auto functions
--]]
local function AutoFile( filepath, callback )
    local filename = GetFileFromFilename( filepath )

    local func, realm = GetIncludeFromFilename( filename )
    if func == nil then return nil end

    return File_Internal( filepath, callback, func )
end
loader.AutoFile = AutoFile

local function AutoDir( root, callback, recursive, order )
    Dir_Internal( root, AutoFile, callback, recursive, order )
end
loader.AutoDir = AutoDir

local function AutoList( root, paths, callback )
    root = root .. "/"

    for i = 1, #paths do
        AutoFile( root .. paths[i], callback )
    end
end
loader.AutoList = AutoList

--[[
        Manual functions
--]]
local function Dir( root, realm, callback, recursive, order )
    assert( realm ~= nil, "bad argument #2 ('realm' is required!)" )

    local func = FUNCTIONS_INCLUDE[realm]
    assert( func ~= nil, format( "bad argument #2 (unknown realm: %i)", realm ) )

    Dir_Internal( root, File_Internal, callback, recursive, order, func )
end
loader.Dir = Dir

local function List( root, paths, realm, callback )
    assert( realm ~= nil, "bad argument #3 ('realm' is required!)" )

    local func = FUNCTIONS_INCLUDE[realm]
    assert( func ~= nil, format( "bad argument #3 (unknown realm: %i)", realm ) )
    
    root = root .. "/"

    for i = 1, #paths do
        local filepath = root .. paths[i]

        File_Internal( filepath, callback, func )
    end
end
loader.List = List