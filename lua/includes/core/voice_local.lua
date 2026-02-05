if CLIENT then
    
    local CVAR_DISTANCE = CreateClientConVar( "voice_distance", 300, nil, true, "Distance of your voice chat", 150, 1000 )

else

    local GetInfoNum = FindMetaTable( "Player" ).GetInfoNum
    local GetPos = FindMetaTable( "Entity" ).GetPos
    local DistToSqr = FindMetaTable( "Vector" ).DistToSqr

    local CVAR_ENABLED = CreateConVar( "voice_local", 1 )


    -- TODO: place it into Think with PLAYER:IsSpeaking
    local function CanHear( listener, speaker )
        return DistToSqr( GetPos( listener ), GetPos( speaker ) ) < GetInfoNum( speaker, "voice_distance", 300 ) ^ 2
    end


    local function PlayerCanHearPlayersVoice( listener, speaker )
        return CanHear( listener, speaker ), true
    end


    local function Enable()
        hook.Add( "PlayerCanHearPlayersVoice", "voice_local", PlayerCanHearPlayersVoice )
    end

    local function Disable()
        hook.Remove( "PlayerCanHearPlayersVoice", "voice_local" )
    end


    if CVAR_ENABLED:GetBool() then
        Enable()
    end

    cvars.AddChangeCallback( CVAR_ENABLED:GetName(), function(_, _, value)
        if tobool( value ) then
            Enable()
        else
            Disable()
        end
    end )
    
end