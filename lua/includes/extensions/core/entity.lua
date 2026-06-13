local ENTITY = FindMetaTable("Entity")

local GetAttachment, LookupAttachment = ENTITY.GetAttachment, ENTITY.LookupAttachment


function ENTITY:GetLookupAttachment(attachmentName)
    local id = LookupAttachment(self, attachmentName)
    if id <= 0 then return nil end

    return GetAttachment(self, id)
end
