local Round = math.Round
local SharedRandom = util.SharedRandom

 
function util.SharedRandomInt( ... )
    return Round( SharedRandom( ... ) )
end