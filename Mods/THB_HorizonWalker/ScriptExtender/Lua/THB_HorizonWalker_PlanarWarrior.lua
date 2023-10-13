-- Planar Warrior Attack
planarWarriorEvt = Ext.Events.DealDamage:Subscribe(function(e)
    local caster = e.Caster.Uuid.EntityUuid
    local target = e.Target.Uuid.EntityUuid
    if (isTrue(Osi.HasAppliedStatus(caster, "PLANAR_WARRIORS_MARK_OWNER"))
            and isTrue(Osi.HasAppliedStatus(target, "PLANAR_WARRIORS_MARK")))
    then
        e.Functor.WeaponDamageType = "None"
        e.Functor.DamageType = "Force"
    end
end)