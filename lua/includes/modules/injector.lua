-- TODO: inject multiple functions
module( "injector", package.seeall )


-- weak keys mode let garbage collector remove previously injected functions
__original = setmetatable( {}, { __mode = "k" } )


function get_original( fnWrapper )
    return __original[fnWrapper]
end

function inject_unsafe( fnSource, fnInjected )
    if fnSource == nil then return fnInjected end

    return function( ... )
        fnInjected( ... )
        return fnSource( ... )
    end
end

function inject( fnSource, fnInjected )
    fnSource = get_original( fnSource ) or fnSource

    local wrapper = inject_unsafe( fnSource, fnInjected )

    __original[wrapper] = fnSource

    return wrapper
end

function replace( fnSource, fnInjected )
    fnSource = get_original( fnSource ) or fnSource

    local wrapper = function( ... )
        return fnInjected( fnSource, ... )
    end

    __original[wrapper] = fnSource

    return wrapper
end