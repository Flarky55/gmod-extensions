local ENTITY = FindMetaTable( "Entity" )

local GetAttachment, LookupAttachment = ENTITY.GetAttachment, ENTITY.LookupAttachment
local AnimRestartGesture = ENTITY.AnimRestartGesture

local BITS_GESTURE_SLOT = 3
local BITS_ACTIVITY     = 11


function ENTITY:GetLookupAttachment( attachmentName )
    local id = LookupAttachment( self, attachmentName )
    if id <= 0 then return nil end

    return GetAttachment( self, id )
end

if SERVER then

    util.AddNetworkString( "AnimRestartGestureNetworked" )

    function ENTITY:AnimRestartGestureNetworked( slot, activity, autokill, recipients )
        net.Start( "AnimRestartGestureNetworked" )

        net.WriteEntity( self )
        net.WriteUInt( slot, BITS_GESTURE_SLOT )
        net.WriteUInt( activity, BITS_ACTIVITY )
        net.WriteBool( autokill )

        if recipients ~= nil then
            net.Send( recipients )
        else
            net.SendPVS( self:GetPos() )
        end
	end

else

    ENTITY.AnimRestartGestureNetworked = AnimRestartGesture

    net.Receive( "AnimRestartGestureNetworked", function()
        local e = net.ReadEntity()
        if not IsValid( e ) then
            ErrorNoHalt( "Attempt to call AnimRestartGesture on invalid entity!", "\n" )
            return
        end

        local slot = net.ReadUInt( BITS_GESTURE_SLOT )
        local activity = net.ReadUInt( BITS_GESTURE_SLOT )
        local autokill = net.ReadBool()

        AnimRestartGesture( e, slot, activity, autokill )
    end )

end