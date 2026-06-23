local PLAYER = FindMetaTable( "Player" )

local META_ENTITY = FindMetaTable( "Entity" )

local AnimRestartGesture = PLAYER.AnimRestartGesture

local SetLayerDuration = META_ENTITY.SetLayerDuration

local CurTime = CurTime

local BITS_GESTURE_SLOT = 3
local BITS_ACTIVITY     = 11


if SERVER then
    function PLAYER:SpawnReliable()
        self:ExitVehicle()

        self:Spawn()
    end


    util.AddNetworkString( "AnimRestartGestureNetworked" )

    function PLAYER:AnimRestartGestureNetworked( slot, activity, autokill, recipients )
        if recipients == nil then
            recipients = RecipientFilter()
            recipients:AddPVS( self:GetPos() )
            recipients:RemovePlayer( self )
        end

        net.Start( "AnimRestartGestureNetworked" )
            net.WritePlayer( self )
            net.WriteUInt( slot, BITS_GESTURE_SLOT )
            net.WriteUInt( activity, BITS_ACTIVITY )
            net.WriteBool( autokill )
        net.Send( recipients )
	end
else
    PLAYER.AnimRestartGestureNetworked = AnimRestartGesture

    net.Receive( "AnimRestartGestureNetworked", function()
        local ply = net.ReadPlayer()
        if not IsValid( ply ) then
            ErrorNoHalt( "Attempt to call AnimRestartGesture on invalid player!", "\n" )
            return
        end

        local slot = net.ReadUInt( BITS_GESTURE_SLOT )
        local activity = net.ReadUInt( BITS_GESTURE_SLOT )
        local autokill = net.ReadBool()

        AnimRestartGesture( ply, slot, activity, autokill )
    end )
end


function PLAYER:AnimRestartGestureDuration( slot, activity, autokill, duration )
    AnimRestartGesture( self, slot, activity, autokill )
    SetLayerDuration( self, slot, duration )
end


local Cache = PlayerBoundTable( "KeyDoublePress" )

hook.Add( "KeyPress", "PlayerExtension", function( ply, key )
    local data = Cache[ply]
    if data == nil then
        data = {}
        Cache[ply] = data
    end

    local keyData = data[key]
    if keyData == nil then
        keyData = {}
        data[key] = keyData
    end

    if keyData.lastTime and (CurTime() - keyData.lastTime) <= 0.3 then
        keyData.lastTime = nil

        hook.Run( "KeyDoublePress", ply, key )
    else
        keyData.lastTime = CurTime()
    end
end )
