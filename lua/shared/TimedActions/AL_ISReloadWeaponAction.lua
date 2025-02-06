require "TimedActions/ISReloadWeaponAction"

old_attackHook = ISReloadWeaponAction.attackHook

Hook.Attack.Remove(ISReloadWeaponAction.attackHook)

ISReloadWeaponAction.attackHook = function(character, chargeDelta, weapon)
	if weapon:hasTag("Archery") and not character:isDoShove() then
		ISTimedActionQueue.clear(character)
		if character:isAttackStarted() then return; end
		if instanceof(character, "IsoPlayer") and not character:isAuthorizeMeleeAction() then
			return;
		end
		if weapon:isRanged() and not character:isDoShove() then
			if ISReloadWeaponAction.canShoot(weapon) then
				character:playSound(weapon:getSwingSound());
				local radius = weapon:getSoundRadius() * getSandboxOptions():getOptionByName("FirearmNoiseMultiplier"):getValue();
				if not character:isOutside() then
					radius = radius * 0.5
				end
				character:addWorldSoundUnlessInvisible(radius, weapon:getSoundVolume(), true);
				--character:startMuzzleFlash()
				character:DoAttack(0);
			else
				character:DoAttack(0);
				character:setRangedWeaponEmpty(true);
			end
		end
		return
	else
		return old_attackHook(character, chargeDelta, weapon)
	end
end

Hook.Attack.Add(ISReloadWeaponAction.attackHook)