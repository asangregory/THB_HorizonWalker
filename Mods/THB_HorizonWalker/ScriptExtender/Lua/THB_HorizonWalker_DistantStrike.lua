-- Table to store distant strikers to prevent issues with more than one horizon walker using distant strike at once.
distantStrikers = {}
-- Character information for the individual distant strikers.
distantStriker = { targetList = {} }

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
        local char = distantStrikerInfo(character)
        char.targetList = {}
    end
end)

Ext.Osiris.RegisterListener("CombatEnded", 1, "after", function (combatGUID)
    for k, v in pairs(distantStrikers) do
        -- Wipe distant strikers at end of combat
        distantStrikers[k] = nil
    end
end)

Ext.Osiris.RegisterListener("AttackedBy", 7, "before", function(target, attacker, attacker2, damageType, damageAmount, damageCause, storyActionID)

    if (isTrue(Osi.HasAppliedStatus(attacker, "EXTRA_DISTANT_STRIKE_READY"))) then
        local char = distantStrikerInfo(attacker)

        table.insert(char.targetList, tostring(target))

        if (table.maxn(char.targetList) == 2 and char.targetList[1] ~= char.targetList[2])
                or (table.maxn(char.targetList) == 4 and char.targetList[3] ~= char.targetList[4])
                or (table.maxn(char.targetList) == 6 and char.targetList[5] ~= char.targetList[6]) then
            addStatus(attacker, "DISTANT_STRIKE_STEP_EXTRA", false)
        end

        Osi.CanCastSpellOnEnemyInSameCombat(character, spellID)

    end

end)

Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function(target, status, source, _)

    if (status == "DISTANT_STRIKE_STEP_EXTRA") then
        addStatus(target, "EXTRA_ATTACK", false)
    end

end)

function isTrue(intOrBool)
    if (intOrBool == 1) then return true end
    if (intOrBool == 0) then return false end
    if (intOrBool) then return true else return false end
end