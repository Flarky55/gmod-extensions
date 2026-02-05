module( "schedule", package.seeall )


local function GenerateTimer(prefix)
    local trace = debug.getinfo(2, "Sln")
    return prefix .. "/" .. util.CRC(debug.traceback()) .. " / " .. trace.short_src .. ":" .. trace.currentline
end

-- delays call, if previous delayed rm old delay
function debounce( fn, timeout )
    local timerName = GenerateTimer("debounce")

    return function( ... )
        local args = {...}

        timer.Create(timerName, timeout, 1, function()
            fn(unpack(args))
        end)
    end
end

-- if previous call was recent, delay call
function throttle( fn, timeout )
    local timerName = GenerateTimer("throttle")
    local lastCall

    return function( ... )
        local prevCall = lastCall
        lastCall = SysTime()

        local delta = prevCall and lastCall - prevCall

        if delta and delta <= timeout then
            local args = {...}

            timer.Create(timerName, timeout - delta, 1, function()
                fn(unpack(args))
            end)
        else
            fn(...)
        end
    end
end