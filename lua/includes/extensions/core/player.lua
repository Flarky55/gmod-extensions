local PLAYER = FindMetaTable( "Player" )

local CurTime = CurTime


if SERVER then
    function PLAYER:SpawnReliable()
        self:ExitVehicle()

        self:Spawn()
    end
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