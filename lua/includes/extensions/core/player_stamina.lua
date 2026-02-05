require( "injector" )

local PLAYER = FindMetaTable( "Player" )

local META_ENTITY = FindMetaTable( "Entity" )

local SetNW2Int, GetNW2Int, SetNW2Float, GetNW2Float, SetNW2Bool, GetNW2Bool = META_ENTITY.SetNW2Int, META_ENTITY.GetNW2Int, META_ENTITY.SetNW2Float, META_ENTITY.GetNW2Float, META_ENTITY.SetNW2Bool, META_ENTITY.GetNW2Bool 
local Alive, GetMoveType = META_ENTITY.Alive, META_ENTITY.GetMoveType
local IsSprinting = PLAYER.IsSprinting
local max, min = math.max, math.min
local hook_Run = hook.Run
local FrameTime, CurTime = FrameTime, CurTime

local KEY               = "Stamina"
local KEY_MAX           = "MaxStamina"
local KEY_NEXT_RESTORE  = "NextStaminaRestore"
local KEY_ENABLED       = "StaminaEnabled"

-- local CVAR_ENABLED          = CreateConVar( "sv_stamina", 1, FCVAR_REPLICATED, "Enables stamina" )
local CVAR_RESTORE_DEFAULT = CreateConVar( "sv_stamina_restore", 2.0, FCVAR_REPLICATED, "Stamina restore default value", 0.0 )
local CVAR_RESTORE_TIMEOUT = CreateConVar( "sv_stamina_restore_timeout", 3.0, FCVAR_REPLICATED, "Stamina restore timeout", 0.0 )

local RESTORE_DEFAULT; do
    local setup = function( value )
        RESTORE_DEFAULT = tonumber( value )
    end

    setup( CVAR_RESTORE_DEFAULT:GetFloat() )
    cvars.AddChangeCallback( CVAR_RESTORE_DEFAULT:GetName(), cvars.CallbackValue( setup ) )
end

local RESTORE_TIMEOUT; do
    local setup = function( value )
        RESTORE_TIMEOUT = tonumber( value )
    end

    setup( CVAR_RESTORE_TIMEOUT:GetFloat() )
    cvars.AddChangeCallback( CVAR_RESTORE_TIMEOUT:GetName(), cvars.CallbackValue( setup ) )
end


local function Install( fnGet, fnSet, valueMax, valueStart )

    PLAYER.Stamina = fnGet
    PLAYER.SetStamina = fnSet

    local function GetMaxStamina( ply )
        return GetNW2Int( ply, KEY_MAX, valueMax )
    end
    PLAYER.GetMaxStamina = GetMaxStamina

    if SERVER then
        local function SetMaxStamina( ply, n )
            SetNW2Int( ply, KEY_MAX, n )
        end
        PLAYER.SetMaxStamina = SetMaxStamina

        local function EnableStamina( ply, enable )
            SetNW2Bool( ply, KEY_ENABLED, enable )
        end
        PLAYER.EnableStamina = EnableStamina
    end

    local function ConsumeStamina( ply, n )
        fnSet( ply, max( fnGet( ply ) - n, 0) )
    end
    PLAYER.ConsumeStamina = ConsumeStamina

    local function RestoreStamina( ply, n )
        fnSet( ply, min( fnGet( ply ) + n, GetMaxStamina( ply ) ) )
    end
    PLAYER.RestoreStamina = RestoreStamina

    local function IsStaminaEnabled( ply )
        return GetNW2Bool( ply, KEY_ENABLED, true )
    end
    PLAYER.IsStaminaEnabled = IsStaminaEnabled

    local function GetStaminaNextRestore( ply )
        return GetNW2Float( ply, KEY_NEXT_RESTORE, 0 )
    end

    local function SetStaminaNextRestore( ply, time )
        SetNW2Float( ply, KEY_NEXT_RESTORE, CurTime() + time )
    end


    local Rates = PlayerBoundTable( "Stamina" )

    --[[    UNUSED 
    --      Because of prediction errors, but perhaps it can still be used with a compromise
    local function Think()
        for _, ply in player.Iterator() do
            local rate = Rates[ply]
            if rate == nil then
                rate = { consume = MutableNumber(), restore = MutableNumber() }
                Rates[ply] = rate
            else
                rate.consume.value = 0
                rate.restore.value = 0
            end

            rate.consume._cancelled = hook_Run( "PlayerConsumeStamina", ply, rate.consume )
            rate.consume._cancelled = hook_Run( "PlayerRestoreStamina", ply, rate.restore )
        end
    end

    local function ProcessPlayer( ply )
        local stamina = fnGet( ply )

        local rate = Rates[ply]
        if rate == nil then return end

        local consume, restore = rate.consume, rate.restore

        if consume._cancelled == nil and consume.value ~= 0 then
            fnSet( ply, max( stamina - consume.value * FrameTime(), 0 ) )
        elseif restore._cancelled == nil and restore.value ~= 0 then
            fnSet( ply, min( stamina + restore.value * FrameTime(), GetMaxStamina( ply ) ) )
        end
    end
    --]]

    local function ProcessPlayer( ply )
        if not IsStaminaEnabled( ply )
            or not Alive( ply )
            or GetMoveType( ply ) ~= MOVETYPE_WALK
        then return end

        local stamina = fnGet( ply )
        local consume, restore

        local rate = Rates[ply]
        if rate == nil then
            consume, restore = MutableNumber(), MutableNumber()

            Rates[ply] = { consume = consume, restore = restore }
        else
            consume, restore = rate.consume, rate.restore
        end

        consume.value = 0
        restore.value = RESTORE_DEFAULT

        local cancel = hook_Run( "PlayerConsumeStamina", ply, consume )
        local value = consume.value

        if cancel == nil and value ~= 0 then
            fnSet( ply, max( stamina - value * FrameTime(), 0 ) )

            SetStaminaNextRestore( ply, RESTORE_TIMEOUT )
        elseif GetStaminaNextRestore( ply ) < CurTime() then
            local cancel = hook_Run( "PlayerRestoreStamina", ply, restore )
            local value = restore.value

            if cancel == nil and value ~= 0 then
                fnSet( ply, min( stamina + value * FrameTime(), GetMaxStamina( ply ) ) )
            end
        end
    end

    hook.Add( "FinishMove", "Stamina", ProcessPlayer )

    hook.Add( "SetupMove", "Stamina", function( ply, mv )
        local stamina = fnGet( ply )

        if stamina <= 30 then
            -- Slow down
        end
    end )

    player_manager.OnPlayerSpawn = injector.inject_unsafe( player_manager.OnPlayerSpawn, function( ply, transition )
        if not transition then
            fnSet( ply, valueStart )
        end
    end )


    hook.Add( "PlayerConsumeStamina", "Stamina", function( ply, rate )
        if IsSprinting( ply ) then
            rate = rate + 2
        end
    end )

    hook.Add( "OnPlayerJump", "Stamina", function( ply )
        ConsumeStamina( ply, 10 )
    end )

end


-- Using DTVars seems to be the only reliable way for prediction support
function InstallPlayerStamina( playerClass )

    playerClass.SetupDataTables = injector.inject_unsafe( playerClass.SetupDataTables, function( self )
        local var = self.Player:DTVar( "Float", KEY )
        local index, GetFunc, SetFunc = var.index, var.GetFunc, var.SetFunc 

        Install(
            function( ply )
                return GetFunc( ply, index )
            end,
            function( ply, value )
                SetFunc( ply, index, value )
            end,
            self.MaxStamina,
            self.StartStamina
        )
    end )

end