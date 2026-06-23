local Round = math.Round
local SharedRandom = util.SharedRandom

local match, Explode, Trim = string.match, string.Explode, string.Trim


function util.SharedRandomInt( ... )
    return Round( SharedRandom( ... ) )
end

local PATTERN_PROPERTY = "(.-)=(.-)$"

function util.ParseProperties( content, fn )
    local lines = Explode( "\n", content )

    for i = 1, #lines do
        local key, value = match( Trim( lines[i] ), PATTERN_PROPERTY )

        if key and value then
            fn( key, value )
        end
    end
end