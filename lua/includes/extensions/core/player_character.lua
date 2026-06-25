-- TODO: weighted random sound selection

local META_PLAYER = FindMetaTable( "Player" )
local META_ENTITY = FindMetaTable( "Entity" )
local META_CTakeDamageInfo = FindMetaTable( "CTakeDamageInfo" )

local IsSprinting, GetInfoNum = META_PLAYER.IsSprinting, META_PLAYER.GetInfoNum
local ENTITY_EmitSound, EntIndex = META_ENTITY.EmitSound, META_ENTITY.EntIndex
local IsDamageType = META_CTakeDamageInfo.IsDamageType

local SharedRandom = util.SharedRandom

local EmitSound = EmitSound


local CVAR_SOUND_ENABLED = CreateConVar( "sv_character_sound", 1 )

local NAME_SOUND_ENABLED    = "cl_character_sound"
local NAME_SOUND_FOOTSTEPS  = "cl_character_sound_footsteps"
local NAME_SOUND_DEATH      = "cl_character_sound_death"
local NAME_SOUND_DAMAGE     = "cl_character_sound_damage"
local NAME_SOUND_KILL       = "cl_character_sound_kill"

if CLIENT then
    CreateClientConVar( NAME_SOUND_ENABLED,     1, nil, true, "Enable character sounds",            0, 1 )
    CreateClientConVar( NAME_SOUND_FOOTSTEPS,   1, nil, true, "Enable character footestep sounds",  0, 1 )
    CreateClientConVar( NAME_SOUND_DEATH,       1, nil, true, "Enable character death sounds",      0, 1 )
    CreateClientConVar( NAME_SOUND_DAMAGE,      1, nil, true, "Enable character damage sounds",     0, 1 )
	CreateClientConVar( NAME_SOUND_KILL,        1, nil, true, "Enable character kill sounds",       0, 1 )
end


local function SharedRadomIntFootsteps()
    return SharedRandom( "Footsteps", 0, 1 )
end


local SoundsFootstep, SoundsDeath, SoundsDamage, SoundsKill = {}, {}, {}, {}

local function AddValidFootstepSounds( name, entry )
    SoundsFootstep[name] = entry
end
player_manager.AddValidFootstepSounds = AddValidFootstepSounds

local function AddValidDeathSound( name, entry )
    SoundsDeath[name] = SoundsDeath[name] or {}

    table.insert( SoundsDeath[name], entry )
end
player_manager.AddValidDeathSound = AddValidDeathSound

local function AddValidDamageSound( name, entry )
    SoundsDamage[name] = SoundsDamage[name] or {}

    table.insert( SoundsDamage[name], entry )
end
player_manager.AddValidDamageSound = AddValidDamageSound

local function AddValidKillSound( name, entry )
    SoundsKill[name] = SoundsKill[name] or {}

    table.insert( SoundsKill[name], entry )
end
player_manager.AddValidKillSound = AddValidKillSound


-- TODO: not working on CLIENT
hook.Add( "PlayerModelChanged", "PlayerCharacter", function( ply, cl_playermodel )
    if GetInfoNum( ply, NAME_SOUND_ENABLED, 1 ) == 0 then return end

    ply.m_tCharacter_Footstep = SoundsFootstep[cl_playermodel]

    if SERVER then
        ply.m_tCharacter_Death  = SoundsDeath[cl_playermodel]
        ply.m_tCharacter_Damage = SoundsDamage[cl_playermodel]
        ply.m_tCharacter_Kill   = SoundsKill[cl_playermodel]
    end
end )


hook.Add( "PlayerFootstep", "PlayerCharacter", function( ply, pos, foot, _, volume, _ )
    if GetInfoNum( ply, NAME_SOUND_FOOTSTEPS, 1 ) ~= 1 then return end

    local sounds = ply.m_tCharacter_Footstep
    if sounds == nil then return end

    sounds = IsSprinting( ply ) and sounds.SPRINT or sounds.DEFAULT or sounds

    if sounds.Chance ~= nil and not math.Chance( sounds.Chance, SharedRadomIntFootsteps ) then return end

    -- Use `EmitSound` instead of `ENTITY:EmitSound` as here we can set volume, which will be overriden by the sound script if use `ENTITY:EmitSound`
    --  https://wiki.facepunch.com/gmod/Entity:EmitSound#description
    EmitSound( sounds[foot + 1], pos, EntIndex( ply ), nil, volume * 0.4, nil, nil, nil, nil, nil )

    return true
end )

if SERVER then
    hook.Add( "PlayerDeathSound", "PlayerCharacter", function( ply )
        if GetInfoNum( ply, NAME_SOUND_DEATH, 1 ) ~= 1 then return end

        local sounds = ply.m_tCharacter_Death
        if sounds == nil then return end

        local entry = table.RandomSeq( sounds )

        ENTITY_EmitSound( ply, entry )

        return true
    end )

    hook.Add( "PostEntityTakeDamage", "PlayerCharacter", function( ent, dmgInfo )
        if isplayer( ent ) then
            if GetInfoNum( ent, NAME_SOUND_DAMAGE, 1 ) ~= 1 then return end

            local sounds = ent.m_tCharacter_Damage
            if sounds == nil then return end

            local entry = table.RandomSeq( sounds )
            if entry.Chance ~= nil and not math.Chance( entry.Chance )
                or not IsDamageType( dmgInfo, entry.DamageType )
                or safecall( entry.IsAvailable, ent ) == false
            then return end

            ENTITY_EmitSound( ent, entry.Sound )

            safecall( entry.OnPlayed, ent )
        end
    end )

    local function EmitKillSound( ply )
        if GetInfoNum( ply, NAME_SOUND_KILL, 1 ) ~= 1 then return end

        local sounds = ply.m_tCharacter_Kill
        if sounds == nil then return end

        local entry = table.RandomSeq( sounds )
        if entry.Chance ~= nil and not math.Chance( entry.Chance ) then return end

        ENTITY_EmitSound( ply, entry.Sound )
    end

    hook.Add( "OnNPCKilled", "PlayerCharacter", function( _, attacker, _ )
        if isplayer( attacker ) then
            EmitKillSound( attacker )
        end
    end )

    hook.Add( "PlayerDeath", "PlayerCharacter", function( victim, _, attacker )
        if victim == attacker then return end

        if isplayer( attacker ) then
            EmitKillSound( attacker )
        end
    end )
end


local DMG_COMMON = bit.bor( DMG_GENERIC, DMG_SLASH, DMG_BULLET, DMG_SHOCK )

--[[
        MetroPolice
--]]
local POLICE_FOOTSTEP = {
    DEFAULT = { "NPC_MetroPolice.FootstepLeft", "NPC_MetroPolice.FootstepRight" },
    SPRINT  = {
        "NPC_MetroPolice.RunFootstepLeft", "NPC_MetroPolice.RunFootstepRight",
        Chance = 0.66
    }
}
local POLICE_DAMAGE_COMMON = {
    Sound = "NPC_MetroPolice.Pain",
    DamageType = DMG_COMMON,
    Chance = 0.3,
}
local POLICE_DAMAGE_BURN = {
    Sound = "NPC_MetroPolice.OnFireScream",
    DamageType = DMG_BURN,
    IsAvailable = function( ply )
        -- last damage taken by fire was not so long ago
        return (ply.m_fNextPlay or 0) < CurTime()
    end,
    OnPlayed = function( ply )
        ply.m_fNextPlay = CurTime() + 3
    end,
}
local POLICE_KILL = {
    { Sound = "NPC_MetroPolice.takedown", Chance = 0.3 },
    { Sound = "NPC_MetroPolice.onecontained", Chance = 0.6 },
    { Sound = "NPC_MetroPolice.Cupcop.Chuckle", Chance = 0.6 },
    { Sound = "NPC_MetroPolice.Cupcop.GoAway.Failure", Chance = 0.6 }
}

AddValidFootstepSounds( "police", POLICE_FOOTSTEP )
AddValidDeathSound( "police", "NPC_MetroPolice.Die" )
AddValidDamageSound( "police", POLICE_DAMAGE_COMMON )
AddValidDamageSound( "police", POLICE_DAMAGE_BURN )
for _, entry in ipairs( POLICE_KILL ) do AddValidKillSound( "police", entry ) end

AddValidFootstepSounds( "policefem", POLICE_FOOTSTEP )
AddValidDeathSound( "policefem", "NPC_MetroPolice.Die" )
AddValidDamageSound( "policefem", POLICE_DAMAGE_COMMON )
AddValidDamageSound( "policefem", POLICE_DAMAGE_BURN )
for _, entry in ipairs( POLICE_KILL ) do AddValidKillSound( "police", entry ) end


--[[
        Combine
--]]
local COMBINE_FOOTSTEP = {
    DEFAULT = { "NPC_CombineS.FootstepLeft", "NPC_CombineS.FootstepRight" },
    SPRINT  = {
        "NPC_CombineS.RunFootstepLeft", "NPC_CombineS.RunFootstepRight",
        Chance = 0.66
    }
}
local COMBINE_DAMAGE_COMMON = {
    Sound = "NPC_CombineS.Pain",
    DamageType = DMG_COMMON,
    Chance = 0.3,
}
local COMBINE_KILL = {
    { Sound = "npc/combine_soldier/vo/contained.wav", Chance = 0.6 },
}

sound.Add( {
    name = "NPC_CombineS.Pain",
    sound = { "npc/combine_soldier/pain1.wav", "npc/combine_soldier/pain2.wav", "npc/combine_soldier/pain3.wav" }
} )

AddValidFootstepSounds( "combine", COMBINE_FOOTSTEP )
AddValidDeathSound( "combine", "NPC_CombineS.DissolveScream" )
AddValidDamageSound( "combine", COMBINE_DAMAGE_COMMON )
for _, entry in ipairs( COMBINE_KILL ) do AddValidKillSound( "combine", entry ) end

AddValidFootstepSounds( "combineelite", COMBINE_FOOTSTEP )
AddValidDeathSound( "combineelite", "NPC_CombineS.DissolveScream" )
AddValidDamageSound( "combineelite", COMBINE_DAMAGE_COMMON )
for _, entry in ipairs( COMBINE_KILL ) do AddValidKillSound( "combineelite", entry ) end

AddValidFootstepSounds( "combineprison", COMBINE_FOOTSTEP )
AddValidDeathSound( "combineprison", "NPC_CombineS.DissolveScream" )
AddValidDamageSound( "combineprison", COMBINE_DAMAGE_COMMON )
for _, entry in ipairs( COMBINE_KILL ) do AddValidKillSound( "combineprison", entry ) end


--[[
        Citizens
--]]
local CITIZEN_FOOTSTEP = {
    DEFAULT = { "NPC_Citizen.FootstepLeft", "NPC_Citizen.FootstepRight" },
    SPRINT  = {
        "NPC_Citizen.RunFootstepLeft", "NPC_Citizen.RunFootstepRight",
        Chance = 0.33
    }
}
local CITIZEN_DAMAGE = {}; do
    for i, sound in ipairs( {
        "npc_citizen.pain01", "npc_citizen.pain02", "npc_citizen.pain03", "npc_citizen.pain04", "npc_citizen.pain05", "npc_citizen.pain06", "npc_citizen.pain07", "npc_citizen.pain08", "npc_citizen.pain09"
    } ) do
        CITIZEN_DAMAGE[i] = { Sound = sound, DamageType = DMG_COMMON, Chance = 0.3 }
    end
end
local CITIZEN_KILL = {}; do
    for i, sound in ipairs( {
        "npc_citizen.gotone01", "npc_citizen.gotone02"
    } ) do
        CITIZEN_KILL[i] = { Sound = sound, DamageType = DMG_COMMON, Chance = 0.3 }
    end
end

for i = 1, 12 do
    local modelname = string.format( "female%.2i", i )

    AddValidFootstepSounds( modelname, CITIZEN_FOOTSTEP )
    AddValidDeathSound( modelname, "npc_citizen.die" )
    for _, entry in ipairs( CITIZEN_DAMAGE ) do AddValidDamageSound( modelname, entry ) end
    for _, entry in ipairs( CITIZEN_KILL ) do AddValidKillSound( modelname, entry ) end
end

for i = 1, 18 do
    local modelname = string.format( "male%.2i", i )

    AddValidFootstepSounds( modelname, CITIZEN_FOOTSTEP )
    AddValidDeathSound( modelname, "npc_citizen.die" )
    for _, entry in ipairs( CITIZEN_DAMAGE ) do AddValidDamageSound( modelname, entry ) end
    for _, entry in ipairs( CITIZEN_KILL ) do AddValidKillSound( modelname, entry ) end
end

for i = 1, 15 do
    local modelname = string.format( "medic%.2i", i )

    AddValidFootstepSounds( modelname, CITIZEN_FOOTSTEP )
    AddValidDeathSound( modelname, "npc_citizen.die" )
    for _, entry in ipairs( CITIZEN_DAMAGE ) do AddValidDamageSound( modelname, entry ) end
    for _, entry in ipairs( CITIZEN_KILL ) do AddValidKillSound( modelname, entry ) end
end

for i = 1, 4 do
    local modelname = string.format( "refugee%.2i", i )

    AddValidFootstepSounds( modelname, CITIZEN_FOOTSTEP )
    AddValidDeathSound( modelname, "npc_citizen.die" )
    for _, entry in ipairs( CITIZEN_DAMAGE ) do AddValidDamageSound( modelname, entry ) end
    for _, entry in ipairs( CITIZEN_KILL ) do AddValidKillSound( modelname, entry ) end
end


--[[
        Alyx
--]]
local ALYX_DAMAGE = {}; do
    for i, sound in ipairs( {
        "npc_alyx.uggh01", "npc_alyx.uggh02", "npc_alyx.gasp02", "npc_alyx.gasp03", "npc_alyx.hurt04", "npc_alyx.hurt05", "npc_alyx.hurt06", "npc_alyx.hurt08", "npc_barney.ba_pain09", "npc_barney.ba_pain10"
    } ) do
        ALYX_DAMAGE[i] = { Sound = sound, DamageType = DMG_COMMON, Chance = 0.3 }
    end
end

AddValidFootstepSounds( "alyx", {
    DEFAULT = { "NPC_Alyx.FootstepLeft",    "NPC_Alyx.FootstepRight" },
    SPRINT  = { "NPC_Alyx.RunFootstepLeft", "NPC_Alyx.RunFootstepRight" }
} )
AddValidDeathSound( "alyx", "npc_alyx.die" )
for _, entry in ipairs( ALYX_DAMAGE ) do AddValidDamageSound( "alyx", entry ) end
AddValidKillSound( "alyx", { Sound = "npc_alyx.brutal02", Chance = 0.3 } )


--[[
        Barney
--]]
local BARNEY_DAMAGE = {}; do
    for i = 1, 10 do
        local soundname = string.format( "npc_barney.ba_pain%.2i", i )

        BARNEY_DAMAGE[i] = { Sound = soundname, DamageType = DMG_COMMON, Chance = 0.3 }
    end
end
local BARNEY_KILL = {}; do
    for i = 1, 4 do
        local soundname = string.format( "npc_barney.ba_laugh%.2i", i )

        BARNEY_KILL[i] = { Sound = soundname, Chance = 0.3 }
    end
end

AddValidFootstepSounds( "barney", {
    DEFAULT = { "NPC_Barney.FootstepLeft", "NPC_Barney.FootstepRight" },
    SPRINT  = {
        "NPC_Barney.RunFootstepLeft", "NPC_Barney.RunFootstepRight",
        Chance = 0.66
    }
} )
AddValidDeathSound( "barney", "npc_barney.die" )
for _, entry in ipairs( BARNEY_DAMAGE ) do AddValidDamageSound( "barney", entry ) end
for _, entry in ipairs( BARNEY_KILL ) do AddValidKillSound( "barney", entry ) end
AddValidKillSound( "barney", { Sound = "npc_barney.ba_gotone", Chance = 0.3 } )


--[[
        Eli
--]]
AddValidFootstepSounds( "eli", {
    DEFAULT = { "NPC_Eli.FootstepLeft",     "NPC_Eli.FootstepRight" },
    SPRINT  = { "NPC_Eli.RunFootstepLeft",  "NPC_Eli.RunFootstepRight" }
} )


--[[
        Father Grigori
--]]
local MONK_DAMAGE = {}; do
    for i = 1, 12 do
        local soundname = string.format( "ravenholm.monk_pain%.2i", i )

        MONK_DAMAGE[i] = { Sound = soundname, DamageType = DMG_COMMON, Chance = 0.3 }
    end
end
local MONK_KILL = {}; do
    for i = 1, 12 do
        local soundname = string.format( "ravenholm.monk_kill%.2i", i )

        table.insert( MONK_KILL, { Sound = soundname, Chance = 0.6 } )
    end

    for i = 1, 4 do
        local soundname = string.format( "ravenholm.madlaugh%.2i", i )

        table.insert( MONK_KILL, { Sound = soundname, Chance = 0.3 } )
    end
end

AddValidDeathSound( "monk", "ravenholm.monk_death07" )
for _, entry in ipairs( MONK_DAMAGE ) do AddValidDamageSound( "monk", entry ) end
for _, entry in ipairs( MONK_KILL ) do AddValidKillSound( "monk", entry ) end


--[[
        Zombie
--]]
AddValidFootstepSounds( "zombie", { "Zombie.FootstepLeft", "Zombie.FootstepRight" } )
AddValidDeathSound( "zombie", "Zombie.Die" )
AddValidDamageSound( "zombie", { Sound = "Zombie.Pain", DamageType = DMG_COMMON, Chance = 0.3 } )

AddValidFootstepSounds( "zombiefast", {
    DEFAULT = { "NPC_FastZombie.FootstepLeft",  "NPC_FastZombie.FootstepRight" },
    SPRINT  = { "NPC_FastZombie.GallopLeft",    "NPC_FastZombie.GallopRight" }
} )
AddValidDeathSound( "zombiefast", "NPC_FastZombie.Die" )

AddValidFootstepSounds( "zombine", { "Zombine.ScuffLeft", "Zombine.ScuffRight" } )
AddValidDeathSound( "zombine", "Zombine.Die" )