local function DropWeapon( ply )
    if not IsValid( ply ) then return end

    local weapon = ply:GetActiveWeapon()
    if not IsValid( weapon ) or weapon.IsDroppable == false then return end

    ply:DropWeapon( weapon )

    weapon:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
end

concommand.Add( "drop_weapon", DropWeapon )