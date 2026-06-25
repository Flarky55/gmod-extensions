local ENTITY = FindMetaTable( "Entity" )

local GetAttachment, LookupAttachment = ENTITY.GetAttachment, ENTITY.LookupAttachment


function ENTITY:FindAttachment( attachmentName )
    local id = LookupAttachment( self, attachmentName )
    if id <= 0 then return nil end

    return GetAttachment( self, id )
end