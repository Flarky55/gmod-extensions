local band, bnot = bit.band, bit.bnot

local CMoveData = FindMetaTable( "CMoveData" )


function CMoveData:RemoveKey( keys )
    self:SetButtons( band( self:GetButtons(), bnot( keys ) ) )
end