local random = math.random


function table.RandomSeq( tbl, fnRandom )
    fnRandom = fnRandom or random
    
    return tbl[random( 1, #tbl )]
end

-- function table.map( tbl, fn )

-- end