local max, Clamp = math.max, math.Clamp
local huge = math.huge

local FrameTime = FrameTime


function math.IsInRange( n, min, max )
    return n >= min and n <= max
end

-- https://github.com/Unity-Technologies/UnityCsReference/blob/b74c77b3efb29caae156d4639ee79e8302228448/Runtime/Export/Math/Mathf.cs#L272-L303
function math.SmoothDamp( current, target, currentVelocity, smoothTime, maxSpeed, deltaTime )
    maxSpeed = maxSpeed or huge
    deltaTime = deltaTime or FrameTime()

    smoothTime = max( 0.0001, smoothTime )
    local omega = 2.0 / smoothTime

    local x = omega * deltaTime
    local exp = 1.0 / ( 1.0 + x + 0.48 * x * x + 0.235 * x * x * x )
    local change = current - target
    local originalTo = target

    local maxChange = maxSpeed * smoothTime
    change = Clamp( change, -maxChange, maxChange )
    target = current - change

    local temp = ( currentVelocity + omega * change ) * deltaTime
    local originalVelocity = currentVelocity
    currentVelocity = ( currentVelocity - omega * temp ) * exp
    local output = target + ( change + temp ) * exp

    if (originalTo - current > 0.0) == (output > originalTo) then
        output = originalTo
        currentVelocity = deltaTime ~= 0 and (output - originalTo) / deltaTime or originalVelocity
    end

    return output, currentVelocity
end