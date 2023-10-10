-- Table to store distant strikers to prevent issues with more than one horizon walker using distant strike at once.
distantStrikers = {}
-- Character information for the individual distant strikers.
distantStriker = { preCastX = nil, preCastY = nil, preCastZ = nil, currentTarget = nil, targetList = {}, targetCount = 0, distantStrikeCharges = 0 }

function distantStriker:new(char)
    char = char or {}
    setmetatable(char, self)
    self.__index = self
    return char
end

function distantStrikerInfo(GUID)
    local entity = tostring(Ext.Entity.Get(tostring(GUID)))
    if (distantStrikers[entity] == nil) then
        distantStrikers[entity] = distantStriker:new()
    end
    return distantStrikers[entity]
end

-- Add distant strikers on turn start to gather their info.
-- This should also create a new 'distantStrikerInfo' instance every turn so that info does not carry over turns.
Ext.Osiris.RegisterListener("TurnStarted", 1, "before", function (character)
    if (isTrue(Osi.HasPassive(character, "DistantStrike") == 1)) then
        distantStrikerInfo(character)
    end
end)

Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function (combatGUID)
    for k, v in pairs(distantStrikers) do
        -- Wipe distant strikers at end of combat
        distantStrikers[k] = nil
    end
end)

Ext.Osiris.RegisterListener("UsingSpell", 5, "before", function (character, spell, spellType, spellElement, storyActionID)
    if (spell == "Teleportation_DistantStrike") then
        -- Set the caster's pre cast positions in case of inability to execute / specified failure.
        local x, y, z = Osi.GetPosition(tostring(character))
        local char = distantStrikerInfo(character)
        char.preCastX = x
        char.preCastY = y
        char.preCastZ = z
    end
end)

Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function(target, status, source, _)
    if (status == "DISTANT_STRIKE_TARGET") then
        -- attach the target to the source (distant striker)
        local char = distantStrikerInfo(source)
        char.currentTarget = target
    end
end)

-- Handles the attacking
-- TODO: Maybe put a handler here that saves the characters last action points/extra distant strike status?
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", function(character, spell, spellType, spellElement, storyActionID)

    if (spell == "Teleportation_DistantStrike") then
        local char = distantStrikerInfo(character)
        if (char.currentTarget == nil) then
            TeleportBack(character)
        else
            local target = char.currentTarget
            local rangeToTarget = Osi.GetDistanceTo(character, target)
            local isInMeleeRange = rangeToTarget <= 2.5 -- TODO: Replace this 19 with character's melee weapon range when it is gettable
            local hasRangedWeapon = isTrue(Osi.HasRangedWeaponEquipped(character, "Mainhand"))
            local hasMeleeWeapon = isTrue(Osi.HasMeleeWeaponEquipped(character, "Mainhand"))
            if (rangeToTarget > 19) then -- TODO: Replace this 19 with character's ranged weapon range when it is gettable
                TeleportBack(character)
                ClearDistantStrikeTarget(target)
            else
                if (hasRangedWeapon) then
                    if (isInMeleeRange and hasMeleeWeapon) then
                        -- TODO: Make reaction here and ask user if they want to use ranged
                        makeDistantStrikeAttack("Melee", character, target)
                    else
                        makeDistantStrikeAttack("Ranged", character, target)
                    end
                else
                    if (isInMeleeRange and hasMeleeWeapon) then
                        makeDistantStrikeAttack("Melee", character, target)
                    else
                        TeleportBack(character)
                    end
                end
            end
            Osi.RemoveStatus(target, "DISTANT_STRIKE_TARGET", target)
        end
        char.currentTarget = nil
        char.preCastX = nil
        char.preCastY = nil
        char.preCastZ = nil
    end

    refreshDistantStrike(character)

end)

function makeDistantStrikeAttack(MeleeOrRanged, attacker, target)

    local isExtra = isTrue(Osi.HasAppliedStatus(attacker, "EXTRA_DISTANT_STRIKE_READY"))

    if isExtra then
        addStatus(attacker, "EXTRA_DISTANT_STRIKE_BLOCK_EXTRA_ATTACK", false)
        local char = distantStrikerInfo(attacker)
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

    if isExtra then
        Osi.RemoveStatus(attacker, "BLOCK_EXTRA_ATTACK_EXTRA_DISTANT_STRIKE", attacker)
        Osi.RemoveStatus(attacker, "EXTRA_DISTANT_STRIKE_READY", attacker)
    end

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
        addStatus(character, "EXTRA_DISTANT_STRIKE_READY", false)
    else
        Osi.RemoveStatus(character, "EXTRA_DISTANT_STRIKE_READY", character)
    end
end

function TeleportBack(character)
    local char = distantStrikerInfo(character)
    Osi.TeleportToPosition(character, char.preCastX, char.preCastY, char.preCastZ, "Out of attack range or invalid target.", 0, 0, 0, 0, 1)
    -- TODO: Make this restore action cost or extra attack resource / whatever.
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