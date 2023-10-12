-- Table to store distant strikers to prevent issues with more than one horizon walker using distant strike at once.
distantStrikers = {}
-- Character information for the individual distant strikers.
distantStriker = { charGUID = nil, preCastX = nil, preCastY = nil, preCastZ = nil, preCastActionPoints = 0, preCastExtraAttack = false, preCastDistantStrikeCharges = 0, currentTarget = nil, awaitingAttack = false, targetList = {}, targetCount = 0, distantStrikeCharges = 0 }

function distantStriker:new(char)
    char = char or {}
    setmetatable(char, self)
    self.__index = self
    return char
end

function resetDistantStriker(distantStriker)
    distantStriker.preCastX = nil
    distantStriker.preCastY = nil
    distantStriker.preCastZ = nil
    distantStriker.preCastActionPoints = 0
    distantStriker.preCastExtraAttack = false
    distantStriker.preCastDistantStrikeCharges = 0
    distantStriker.currentTarget = nil
    distantStriker.awaitingAttack = false
    distantStriker.targetList = {}
    distantStriker.targetCount = 0
    distantStriker.distantStrikeCharges = 0
end

function distantStrikerInfo(GUID)
    local entity = tostring(Ext.Entity.Get(tostring(GUID)))
    if (distantStrikers[entity] == nil) then
        distantStrikers[entity] = distantStriker:new()
        distantStrikers[entity].charGUID = GUID
    end
    return distantStrikers[entity]
end

function isDistantStriker(GUID)
    local entity = tostring(Ext.Entity.Get(tostring(GUID)))
    return distantStrikers[entity] ~= nil or isTrue(Osi.HasPassive(GUID, "DistantStrike") == 1)
end

-- Add distant strikers on turn start to gather their info.
-- This should also create a new 'distantStrikerInfo' instance every turn so that info does not carry over turns.
Ext.Osiris.RegisterListener("TurnStarted", 1, "before", function (character)
    if (isTrue(Osi.HasPassive(character, "DistantStrike") == 1)) then
        local char = distantStrikerInfo(character)
        resetDistantStriker(char)
    end
end)

Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function (combatGUID)
    for k, v in pairs(distantStrikers) do
        -- Wipe distant strikers at end of combat
        distantStrikers[k] = nil
    end
end)

Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function (character, spell, spellType, spellElement, storyActionID)
    if (isTrue(Osi.HasPassive(character, "DistantStrike") == 1)) then
        local char = distantStrikerInfo(character)
        if (spell == "Teleportation_DistantStrikeRanged" or spell == "Teleportation_DistantStrikeMelee") then
            -- Set the caster's pre cast positions in case of inability to execute / specified failure.
            local x, y, z = Osi.GetPosition(tostring(character))
            char.preCastX = x
            char.preCastY = y
            char.preCastZ = z
            char.preCastActionPoints = getActionPointCount(character)
            char.preCastExtraAttack = hasAnyExtraAttack(character)
            char.preCastDistantStrikeCharges = char.distantStrikeCharges
        end
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(target, status, caster, _)
    if (status == "DISTANT_STRIKE_TARGET") then
        -- attach the target to the source (distant striker)
        local char = distantStrikerInfo(caster)
        char.currentTarget = target
    end
end)

Ext.Osiris.RegisterListener("CastedSpell", 5, "after", function(character, spell, spellType, spellElement, storyActionID)
    if (isDistantStriker(character)) then
        local char = distantStrikerInfo(character)
        if (spell == "Teleportation_DistantStrikeRanged") then
            if (char.currentTarget == nil) then
                teleportBack(character)
            else
                if (isTrue(Osi.HasRangedWeaponEquipped(character, "Mainhand"))) then
                    makeDistantStrikeAttack("Ranged", character, char.currentTarget)
                else
                    teleportBack(character)
                end
                Osi.RemoveStatus(char.currentTarget, "DISTANT_STRIKE_TARGET", char.currentTarget)
            end
        elseif (spell == "Teleportation_DistantStrikeMelee") then
            if (char.currentTarget == nil) then
                teleportBack(character)
            else
                if (isTrue(Osi.HasMeleeWeaponEquipped(character, "Mainhand"))) then
                    makeDistantStrikeAttack("Melee", character, char.currentTarget)
                else
                    teleportBack(character)
                end
                Osi.RemoveStatus(char.currentTarget, "DISTANT_STRIKE_TARGET", char.currentTarget)
            end
        elseif (char.awaitingAttack and spell == "Target_MainHandAttack" or spell == "Projectile_MainHandAttack") then
            Osi.TimerCancel(tostring(character))
            char.awaitingAttack = false
            char.currentTarget = nil
            Osi.RemoveStatus(character, "MOVEMENT_BLOCK", character)
            Osi.RemoveStatus(character, "DISTANT_STRIKE_EXTRA", character)
            Osi.RemoveStatus(character, "EXTRA_ATTACK_BLOCK", character)
        end
        refreshDistantStrike(character)
    end
end)

Ext.Osiris.RegisterListener("TimerFinished", 1, "after", function (event)
    for k, v in pairs(distantStrikers) do
        local character = tostring(distantStrikers[k].charGUID)
        if (character == event) then
            local char = distantStrikers[k]
            teleportBack(character)
            Osi.RemoveStatus(character, "MOVEMENT_BLOCK", character)
            Osi.RemoveStatus(character, "DISTANT_STRIKE_EXTRA", character)
            Osi.RemoveStatus(character, "EXTRA_ATTACK_BLOCK", character)
            char.awaitingAttack = false
        end
    end
end)

function makeDistantStrikeAttack(MeleeOrRanged, attacker, target)
    local char = distantStrikerInfo(attacker)
    local isExtra = isTrue(Osi.HasAppliedStatus(attacker, "DISTANT_STRIKE_EXTRA"))
    if isExtra then
        addStatus(attacker, "EXTRA_ATTACK_BLOCK")
        char.distantStrikeCharges = char.distantStrikeCharges - 1
    end
    if MeleeOrRanged == "Melee" or MeleeOrRanged == "melee" or MeleeOrRanged == "MELEE" then
        Osi.UseSpell(attacker, "Target_MainHandAttack", target)
        if not isExtra then addDistantStrikeTarget(attacker, target) end
    elseif MeleeOrRanged == "Ranged" or MeleeOrRanged == "ranged" or MeleeOrRanged == "RANGED" then
        Osi.UseSpell(attacker, "Projectile_MainHandAttack", target)
        if not isExtra then addDistantStrikeTarget(attacker, target) end
    else
        error("Must be passed (melee/Melee/MELEE) or (ranged/Ranged/RANGED). Case sensitive.", 1)
    end
    -- This is to prevent attacker from walking to make an attack.
    addStatus(attacker, "MOVEMENT_BLOCK")
    char.awaitingAttack = true
    Osi.TimerLaunch(tostring(attacker), 8000)
end

function addDistantStrikeTarget(attacker, target)
    local char = distantStrikerInfo(attacker)
    if (char.targetList[tostring(target)] ~= true) then
        char.targetList[tostring(target)] = true -- Add target to attacker's attacked targets
        char.targetCount = char.targetCount + 1
    end
    if (char.targetCount == 2 or char.targetCount == 4 or char.targetCount == 6) then
        char.distantStrikeCharges = char.distantStrikeCharges + 1
    end
end

function refreshDistantStrike(character)
    local char = distantStrikerInfo(character)
    if (char.distantStrikeCharges > 0 and not canAttack(character)) then
        addStatus(character, "DISTANT_STRIKE_EXTRA")
    else
        Osi.RemoveStatus(character, "DISTANT_STRIKE_EXTRA", character)
    end
end

function teleportBack(character)
    local char = distantStrikerInfo(character)
    local postCastActionPoints = getActionPointCount(character)
    local hasAnyExtraAttack = hasAnyExtraAttack(character)
    if (postCastActionPoints ~= char.preCastActionPoints) then
        Osi.AddActionPoints(character, char.preCastActionPoints - postCastActionPoints)
    end
    if (hasAnyExtraAttack ~= char.preCastExtraAttack) then
        if char.preCastExtraAttack == true then
            addStatus(character, "EXTRA_ATTACK")
        else
            Osi.RemoveStatus(character, "EXTRA_ATTACK", character) -- Theoretically this should basically never be called.
        end
    end
    if (char.distantStrikeCharges ~= char.preCastDistantStrikeCharges) then
        char.distantStrikeCharges = char.preCastDistantStrikeCharges
    end
    local x = char.preCastX
    local y = char.preCastY
    local z = char.preCastZ
    Osi.TeleportToPosition(character, x, y, z, "Out of attack range or invalid target.", 0, 0, 0, 0, 1)
    char.preCastX = nil
    char.preCastY = nil
    char.preCastZ = nil
end

extraAttackStatuses = {
    "EXTRA_ATTACK",
    "EXTRA_ATTACK_2",
    "EXTRA_ATTACK_WAR_MAGIC",
    "EXTRA_ATTACK_WAR_PRIEST",
    "MAG_MARTIAL_EXERTION",
    "WILDSTRIKE_EXTRA_ATTACK",
    "WILDSTRIKE_2_EXTRA_ATTACK",
    "STALKERS_FLURRY",
    "EXTRA_ATTACK_THIRSTING_BLADE",
    "COMMANDERS_STRIKE_D10",
    "COMMANDERS_STRIKE_D8"
}

function canAttack(character)
    return hasAnyExtraAttack(character) or getActionPointCount(character) ~= 0.0
end

function getActionPointCount(character)
    return Osi.GetActionResourceValuePersonal(character, "ActionPoint", 0)
end

function hasAnyExtraAttack(character)
    for k, v in ipairs(extraAttackStatuses) do
        if (isTrue(Osi.HasAppliedStatus(character, v))) then
            return true
        end
    end
    return false
end

function addStatus(target, status, allowStacking, duration, force, source)
    allowStacking = allowStacking or true
    duration = duration or 1
    force = force or 1
    source = source or target
    if (allowStacking) then
        Osi.ApplyStatus(target, status, duration, force, source)
    else
        if (not isTrue(Osi.HasAppliedStatus(target, tostring(status)))) then
            Osi.ApplyStatus(target, status, duration, force, source)
        end
    end
end

function isTrue(intOrBool)
    if (intOrBool == 1) then return true end
    if (intOrBool == 0) then return false end
    if (intOrBool) then return true else return false end
end