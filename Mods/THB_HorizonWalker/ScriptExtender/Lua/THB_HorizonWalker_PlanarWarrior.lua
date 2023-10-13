-- Planar Warrior Attack
--[[
Ext.Osiris.RegisterListener("AttackedBy", 7, "before", function (defender, attackerOwner, attacker2, damageType, damageAmount, damageCause, storyActionId)
    -- TODO:Logic to convert attack damage type to force
end)
Ext.Osiris.RegisterListener("AttackedBy", 7, "before", function (defender, attacker, attacker2, damageType, damageAmount, damageCause, storyActionId) print("defender: ", defender) print("defender hitpoints before: " .. Osi.GetHitPoints(defender)) print("attacker: ", attacker) print("attacker2: ", attacker2) print("damageType: ", damageType) print("damageAmount: ", damageAmount) print("damageCause: ", damageCause) print("storyActionId: ", storyActionId) GetHitPoints(defender) end)
Ext.Osiris.RegisterListener("AttackedBy", 7, "after", function (defender, attacker, attacker2, damageType, damageAmount, damageCause, storyActionId) print("defender hitpoints after: " .. Osi.GetHitPoints(defender)) end)
--]]

UsingSpell listener
Catch when using a spell

CastedSpell Listener

Ext.Events.DealDamage:Subscribe(function(e)
    e.Functor.WeaponDamageType = "None"
    e.Functor.DamageType = "Force"
    -- this actually seems to work
end)