local getinfo = debug.getinfo
local match, GetPathFromFilename = string.match, string.GetPathFromFilename
local Find, Write, Open, CreateDir = file.Find, file.Write, file.Open, file.CreateDir


function file.CurrentDir()
    return match( getinfo( 2, "S" ).short_src, "/lua/(.+/)" )
end

function file.Iterator( root, path )
    local files, dirs = Find( root, path )
    local files_count = #files

    local root_path = GetPathFromFilename( root )

    local i = 1
    local v
    
    return function()
        if i > files_count then
            v = dirs[i - files_count]
        else
            v = files[i]
        end

        if v == nil then return nil end

        i = i + 1

        return root_path .. v, v
    end
end

function file.WriteEnsureDir( fileName, content )
    local success = Write( fileName, content )
    if not success then
        CreateDir( GetPathFromFilename( fileName ) )

        success = Write( fileName, content )
    end
    
    return success
end

function file.OpenEnsureDir( fileName, fileMode, gamePath )
    local f = Open( fileName, fileMode, gamePath )
    if not f then
        CreateDir( GetPathFromFilename( fileName ) )

        f = Open( fileName, fileMode, gamePath )
    end

    return f
end