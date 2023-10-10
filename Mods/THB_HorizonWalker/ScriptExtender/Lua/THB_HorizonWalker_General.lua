-- Comment/Uncomment below for debugging listeners...
--[[
-- StatusAppliedListener
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", function (character, status, caster, _) print("Status applied: " .. status .. " to: " .. character) end)
-- StatusRemovedListener
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", function (character, status, caster, _) print("Status removed: " .. status .. " from: " .. character) end)
-- StatusTagSetListener
Ext.Osiris.RegisterListener("StatusTagSet", 5, "after", function (character, tag, sourceOwner, source2, _) print("Status tag set: " .. tag .. " to: " .. character) end)
-- StatusTagClearedListener
Ext.Osiris.RegisterListener("StatusTagCleared", 5, "after", function (character, tag, sourceOwner, source2, _) print("Status tag cleared: " .. tag .. " from: " .. character) end)
Ext.Osiris.RegisterListener("TagCleared", 2, "after", function(target, tag) print("STATUS TAG CLEARED 2: " .. target, tag) end)
Ext.Osiris.RegisterListener("TagSet", 2, "after", function(target, tag) print("STATUS TAG SET 2: " .. target, tag) end)
Ext.Osiris.RegisterListener("CharacterTagEvent", 3, "after", function(character, tag, event) print("CHARACTER TAG EVENT: " .. character, tag, event) end)

--Attacked
Ext.Osiris.RegisterListener("AttackedBy", 7, "after", function(defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionID) attacker = attackerOwner target = defender end)

-- Generate some target dummies to test things.
-- get player pos
px, py, pz = Osi.GetPosition(GetHostCharacter())
-- bulette - "0ea356fc-7a6f-4c60-8017-86349e2777ab"
for i = 1, 4 do px = px + 2 py = py + 2 Osi.CreateAt("0ea356fc-7a6f-4c60-8017-86349e2777ab", px, py, pz, 0, 0, "Spawned Bulette") end
-- Apply haste
Osi.ApplyStatus(GetHostCharacter(), "HASTE", 1, 1, GetHostCharacter())

--]]