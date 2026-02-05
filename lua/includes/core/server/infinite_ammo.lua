local CVAR_ENABLED = CreateConVar( "sbox_infinite_ammo", 1, bit.bor( FCVAR_ARCHIVE, FCVAR_NOTIFY ), "Infinite ammo.", 0, 1 )


local function SetAmmo( ply, weapon, ammoID )
    if ammoID == -1 then return end
    
    if hook.Run( "InfiniteAmmo", ply, weapon, ammoID ) then return end

    ply:SetAmmo( 999, ammoID )
end

local function WeaponEquip( weapon, owner )
    SetAmmo( owner, weapon, weapon:GetPrimaryAmmoType() )
    SetAmmo( owner, weapon, weapon:GetSecondaryAmmoType() )
end


local function Enable()
    hook.Add( "WeaponEquip", "sbox_infinite_ammo", WeaponEquip )
end

local function Disable()
    hook.Remove( "WeaponEquip", "sbox_infinite_ammo" )
end


if CVAR_ENABLED:GetBool() then
    Enable()
end

cvars.AddChangeCallback( CVAR_ENABLED:GetName(), function( _, _, value )
    if tobool( value ) then
        Enable()
    else
        Disable()
    end
end )