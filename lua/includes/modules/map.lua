local function map(tbl)
    local instance, mt = newproxy(), {MetaName = "map"}
    debug.setmetatable(instance, mt)

    local list, keys, positions, len = {}, {}, {}, 0
    local methods = {}

    function mt:__len()
        return len
    end

    function mt:__tostring()
        return string.format("map: %p", self)
    end

    function mt:__index(k)
        return methods[k] or list[k]
    end

    function mt:__newindex(k, v)
        if v == nil then
            if list[k] == nil then return end

            list[k] = nil

            local lastkey = keys[len]
            local pos = positions[k]

            keys[pos] = lastkey
            keys[len] = nil

            positions[lastkey] = pos
            positions[k] = nil

            len = len - 1

            return
        end

        if list[k] == nil then
            len = len + 1

            keys[len] = k
            positions[k] = len

            list[k] = v
        else
            list[k] = v
        end
    end

    methods.ipairs = function()
        local i = 0
        local key

        return function()
            i = i + 1
            key = keys[i]

            if key == nil then return nil end

            return i, list[key]
        end
    end

    
    if tbl ~= nil then
        for k, v in pairs(tbl) do
            instance[k] = v
        end 
    end


    return instance
end

_G.map = map